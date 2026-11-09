"""Enterprise contracts. Financial integration remains in database/08 and isolated QA."""
import json
from datetime import date
from unittest.mock import patch
from django.test import SimpleTestCase, RequestFactory
from django.core import signing
from core.pagination import page_query
from core.dashboard_services import PeriodForm, load_dashboard
from comercial.pos_services import checkout_token, submit_sale

class EnterpriseTests(SimpleTestCase):
    @patch('core.pagination.execute_query',side_effect=[{'total':43},[]])
    def test_pagination_escapes_search_and_whitelists_sort(self, query):
        request=RequestFactory().get('/',{'q':"x%_[",'sort':'ID]; DROP TABLE X;--','direction':'desc','page':'999','size':'10'})
        _,page=page_query(request,'SELECT ID,Nombre FROM dbo.Cliente',['ID','Nombre'],'ID')
        sql,params=query.call_args.args
        self.assertNotIn('DROP',sql)
        self.assertIn('ORDER BY [ID] DESC',sql)
        self.assertEqual(params,['%x~%~_~[%']*2+[40,10])
        self.assertEqual(page['page'],5)

    @patch('core.pagination.execute_query',side_effect=[{'total':0},[]])
    def test_pagination_invalid_limits_and_stable_ties(self, query):
        _,page=page_query(RequestFactory().get('/',{'size':'bad','sort':'Nombre','page':'-2'}),'SELECT ID,Nombre FROM t',['ID','Nombre'],'ID')
        self.assertIn('ORDER BY [Nombre] ASC, [ID] ASC',query.call_args.args[0])
        self.assertEqual(page['page'],1);self.assertEqual(page['size'],25)

    @patch('core.dashboard_services.repo.sales_metrics')
    def test_dashboard_does_not_read_finances_without_permission(self, query):
        self.assertFalse(load_dashboard({},date.today(),date.today())['financial'])
        query.assert_not_called()

    def test_period_is_ordered_and_bounded(self):
        self.assertFalse(PeriodForm({'desde':'2026-02-01','hasta':'2026-01-01'}).is_valid())
        self.assertFalse(PeriodForm({'desde':'2024-01-01','hasta':'2026-01-01'}).is_valid())
        self.assertIn('value="2026-01-02"',str(PeriodForm(initial={'desde':date(2026,1,2)})['desde']))

    @patch('comercial.pos_services.repo.emit_once')
    def test_token_is_bound_to_user(self, emit):
        with self.assertRaisesMessage(ValueError,'otra sesión'):
            submit_sale(2,checkout_token(1),1,'[]','[]')
        emit.assert_not_called()

    @patch('comercial.pos_services.repo.emit_once')
    def test_unsigned_token_cannot_emit(self, emit):
        for token in ['', 'invalid']:
            with self.assertRaises(ValueError): submit_sale(1,token,1,'[]','[]')
        emit.assert_not_called()

    @patch('comercial.pos_services.signing.loads',side_effect=signing.SignatureExpired())
    @patch('comercial.pos_services.repo.emit_once')
    def test_expired_token_cannot_emit(self, emit, loads):
        with self.assertRaises(ValueError): submit_sale(1,'expired',1,'[]','[]')
        emit.assert_not_called()

    @patch('comercial.pos_services.repo.emit_once')
    def test_same_payload_uses_same_lock_and_fingerprint(self, emit):
        token=checkout_token(1)
        submit_sale(1,token,3,'[{"cantidad":1,"varianteId":2}]','[]')
        first=emit.call_args.args
        submit_sale(1,token,3,'[ {"varianteId":2, "cantidad":1} ]','[]')
        self.assertEqual(first[:3],emit.call_args.args[:3])
        submit_sale(1,token,4,'[{"cantidad":1,"varianteId":2}]','[]')
        self.assertNotEqual(first[2],emit.call_args.args[2])

    @patch('core.pagination.execute_query',side_effect=[{'total':0},[]])
    def test_date_filter_includes_whole_last_day(self, query):
        page_query(RequestFactory().get('/',{'desde':'2026-11-04','hasta':'2026-11-04'}),'SELECT ID,Fecha FROM t',['ID','Fecha'],'ID',date_column='Fecha')
        self.assertEqual(query.call_args.args[1][:2],[date(2026,11,4),date(2026,11,5)])

    @patch('core.pagination.execute_query',side_effect=[{'total':0},[]])
    def test_out_of_range_date_is_an_error_with_valid_parameters(self, query):
        _,page=page_query(RequestFactory().get('/',{'hasta':'9999-12-31'}),'SELECT ID,Fecha FROM t',['ID','Fecha'],'ID',date_column='Fecha')
        self.assertTrue(page['error'])
        self.assertEqual(query.call_args.args[1],[0,25])
        self.assertIn('1=0',query.call_args.args[0])
