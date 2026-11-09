"""Contract tests without SQL Server; database calls are explicitly mocked."""
import json
from io import BytesIO
from pathlib import Path
from unittest.mock import patch
from django.test import SimpleTestCase,RequestFactory
from django.contrib.messages.storage.fallback import FallbackStorage
from django.template.loader import get_template,render_to_string
from django.utils.crypto import salted_hmac
from catalogos.forms import ClienteForm,ProveedorForm,CategoriaForm,MarcaForm
from catalogos import views as catalogs
from comercial.views import validate_lines,validate_payments
from core.permissions import user_permissions,DEFAULTS
from reportes.services import ReporteForm,generar
from reportes.pdf import crear_pdf
from seguridad.forms import UsuarioForm

def request(method='get',data=None):
    req=getattr(RequestFactory(),method)('/',data or {})
    req.session={'usuario_id':1}
    req._messages=FallbackStorage(req)
    return req

class CatalogTests(SimpleTestCase):
    def test_creation_fields_have_no_identity_or_active(self):
        for cls in (ClienteForm,ProveedorForm,CategoriaForm,MarcaForm):
            self.assertNotIn('activo',cls().fields)
            self.assertFalse(any(k.endswith('_id') for k in cls().fields))

    @patch('core.permissions.user_permissions',return_value={'clientes':{'editar':True}})
    @patch('catalogos.services.guardar')
    def test_forged_id_cannot_edit_during_create(self,save,perms):
        response=catalogs.catalogo_nuevo(request('post',{'cliente_id':'900','tipo_cliente':'PARTICULAR','nombre':'Ana','activo':'0'}),'clientes')
        self.assertEqual(response.status_code,302)
        data=save.call_args.args[1]
        self.assertIsNone(data['cliente_id']);self.assertTrue(data['activo'])

    @patch('core.permissions.user_permissions',return_value={'clientes':{'editar':True}})
    @patch('catalogos.services.obtener',return_value={'ClienteID':7,'Activo':False})
    @patch('catalogos.services.guardar')
    def test_edit_uses_url_identity_and_preserves_state(self,save,get,perms):
        catalogs.catalogo_editar(request('post',{'cliente_id':800,'tipo_cliente':'EMPRESA','nombre':'Empresa','activo':'1'}),'clientes',7)
        data=save.call_args.args[1];self.assertEqual(data['cliente_id'],7);self.assertFalse(data['activo'])

    @patch('core.permissions.user_permissions',return_value={'clientes':{'editar':True}})
    @patch('catalogos.services.cambiar_estado')
    def test_get_cannot_change_state(self,change,perms):
        response=catalogs.catalogo_estado(request(),'clientes',7,0)
        self.assertEqual(response.status_code,405);change.assert_not_called()

class ValidationTests(SimpleTestCase):
    def test_valid_lines(self):
        raw=json.dumps([{'varianteId':1,'cantidad':'2.125','descuento':'1.00'}])
        self.assertEqual(validate_lines(raw,'factura'),raw)

    def test_duplicate_lines_rejected(self):
        row={'varianteId':1,'cantidad':1,'descuento':0}
        with self.assertRaises(ValueError):validate_lines(json.dumps([row,row]),'factura')

    def test_invalid_quantities_rejected(self):
        for val in ['NaN','Infinity','0','-1','0.0001']:
            with self.subTest(val=val),self.assertRaises(ValueError):validate_lines(json.dumps([{'varianteId':1,'cantidad':val,'descuento':0}]),'factura')

    def test_boolean_identity_rejected(self):
        with self.assertRaises(ValueError):validate_lines(json.dumps([{'varianteId':True,'cantidad':1,'descuento':0}]),'factura')

    def test_fractional_location_rejected(self):
        with self.assertRaises(ValueError):validate_lines(json.dumps([{'ordenCompraDetalleId':1,'cantidad':1,'costo':0,'ubicacionId':1.5}]),'recepcion')

    def test_invalid_payments_rejected(self):
        for amount in ['NaN','-1',0,'1.001']:
            with self.subTest(amount=amount),self.assertRaises(ValueError):validate_payments(json.dumps([{'medioPagoId':1,'monto':amount}]))

    def test_multiple_payments_accepted(self):
        raw=json.dumps([{'medioPagoId':1,'monto':'25.25'},{'medioPagoId':2,'monto':'10.00'}])
        self.assertEqual(validate_payments(raw),raw)

    def test_new_user_requires_password_even_with_forged_id(self):
        form=UsuarioForm({'usuario_id':3,'nombre_usuario':'a','nombres':'A','apellidos':'B','rol_id':'1'},roles=[{'RolID':1,'Nombre':'GERENTE'}])
        self.assertFalse(form.is_valid());self.assertIn('clave',form.errors)

    def test_digitador_cannot_bill_by_default(self):
        self.assertNotIn('facturas',DEFAULTS['DIGITADOR'])
        self.assertNotIn('anulaciones',DEFAULTS['DIGITADOR'])

    def test_report_date_order(self):
        form=ReporteForm({'tipo':'ventas','desde':'2026-11-02','hasta':'2026-11-01'})
        self.assertFalse(form.is_valid())

    def test_invoice_report_requires_number(self):
        self.assertFalse(ReporteForm({'tipo':'factura'}).is_valid())

    def test_stock_report_needs_no_dates(self):
        self.assertTrue(ReporteForm({'tipo':'inventario'}).is_valid())

class ReportTests(SimpleTestCase):
    @patch('reportes.repositories.consultar',return_value=[{'SKU':'P-1','Existencias':0}])
    def test_report_uses_repository_values(self,query):
        title,tables=generar({'tipo':'sin_stock'})
        self.assertEqual(tables[0]['rows'],[['P-1',0]])
        query.assert_called_once_with('sin_stock',None,None)

    @patch('reportes.repositories.factura',return_value=(None,[],[]))
    def test_invoice_not_found(self,query):
        with self.assertRaises(ValueError):generar({'tipo':'factura','numero':'missing'})

    def test_pdf_paginates_and_escapes_user_content(self):
        from pypdf import PdfReader
        result=crear_pdf('Prueba técnica',[{'titulo':'Detalle','headers':['Producto','Monto'],'rows':[['<script> & Pintura',str(i)] for i in range(150)]}],'Datos de prueba, sin conexión SQL')
        reader=PdfReader(BytesIO(result))
        self.assertGreater(len(reader.pages),1)
        self.assertIn('<script> & Pintura',reader.pages[0].extract_text())
        self.assertIn('149',reader.pages[-1].extract_text())

class TemplateTests(SimpleTestCase):
    def test_all_templates_compile(self):
        root=Path(__file__).resolve().parents[1]/'templates'
        for file in root.rglob('*.html'):
            with self.subTest(file=file.name):get_template(str(file.relative_to(root)).replace('\\','/'))

    def test_catalog_actions_render_as_post(self):
        html=render_to_string('catalogos/list.html',{'tipo':'clientes','meta':{'titulo':'Clientes','headers':['ID','Estado']},'puede_editar':True,'table_rows':[{'pk':3,'activo':True,'values':[3,True]}]})
        self.assertIn('method="post"',html)
        self.assertIn('/catalogos/clientes/3/estado/0/',html)

    def test_quote_invoice_link_is_well_formed(self):
        html=render_to_string('comercial/cotizaciones.html',{'permisos':{'facturas':{'editar':True}},'rows':[{'CotizacionID':8,'Estado':'CONFIRMADA','Total':20}]})
        self.assertIn('href="/comercial/facturas/nueva/?cotizacion=8"',html)

class SecurityTests(SimpleTestCase):
    def test_csrf_blocks_state_change_without_token(self):
        from django.test import Client
        response=Client(enforce_csrf_checks=True).post('/catalogos/clientes/1/estado/0/')
        self.assertEqual(response.status_code,403)

    def test_logout_requires_post(self):
        self.assertEqual(self.client.get('/seguridad/logout/').status_code,405)
        self.assertEqual(self.client.post('/seguridad/logout/').status_code,302)

    @patch('seguridad.services.autenticar')
    def test_login_creates_fingerprint_and_logout_clears_session(self,authenticate):
        authenticate.return_value={'UsuarioID':3,'NombreUsuario':'test','Rol':'CAJERO','Nombres':'Usuario','Apellidos':'Prueba','PasswordHash':'pbkdf2_test'}
        response=self.client.post('/seguridad/login/',{'usuario':'test','clave':'test-password'})
        self.assertEqual(response.status_code,302)
        self.assertEqual(self.client.session['usuario_id'],3)
        self.assertIn('auth_fingerprint',self.client.session)
        self.client.post('/seguridad/logout/')
        self.assertNotIn('usuario_id',self.client.session)

    @patch('core.permissions.execute_query',return_value={'Activo':False})
    def test_disabled_account_session_is_revoked(self,query):
        from django.contrib.sessions.backends.signed_cookies import SessionStore
        req=request();req.session=SessionStore();req.session['usuario_id']=1
        self.assertEqual(user_permissions(req),{})
        self.assertNotIn('usuario_id',req.session)

    @patch('core.permissions.execute_query',return_value={'Activo':True,'Rol':'GERENTE','PasswordHash':'changed'})
    def test_password_change_revokes_previous_session(self,query):
        from django.contrib.sessions.backends.signed_cookies import SessionStore
        req=request();req.session=SessionStore();req.session['usuario_id']=1
        req.session['auth_fingerprint']='old-fingerprint'
        self.assertEqual(user_permissions(req),{})
        self.assertNotIn('usuario_id',req.session)

    @patch('core.permissions.user_permissions',return_value={'clientes':{'ver':True,'editar':False}})
    @patch('catalogos.services.guardar')
    def test_read_only_permission_cannot_create(self,save,perms):
        response=catalogs.catalogo_nuevo(request('post',{'tipo_cliente':'PARTICULAR','nombre':'Ana'}),tipo='clientes')
        self.assertEqual(response.status_code,302)
        save.assert_not_called()
