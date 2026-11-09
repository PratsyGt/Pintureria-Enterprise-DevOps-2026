import csv
from datetime import date
from django.shortcuts import render
from django.http import HttpResponse
from django.db import DatabaseError
from core.permissions import permission_required
from .services import ReporteForm,generar
from .pdf import crear_pdf

@permission_required('reportes')
def index(request):
    defaults={'tipo':'ventas','desde':date.today().replace(day=1),'hasta':date.today()}
    form=ReporteForm(request.GET if request.GET else None,initial=defaults)
    tablas=[];titulo='Centro de reportes'
    if request.GET and form.is_valid():
        try:
            titulo,tablas=generar(form.cleaned_data)
            periodo=f"Consulta: {form.cleaned_data.get('desde') or 'Actual'} a {form.cleaned_data.get('hasta') or 'Actual'} · Generado: {date.today()}"
            if request.GET.get('formato')=='csv':
                response=HttpResponse(content_type='text/csv; charset=utf-8')
                response['Content-Disposition']='attachment; filename="reporte-pintureria.csv"'
                response.write('\ufeff')
                writer=csv.writer(response)
                def safe(value):
                    text='' if value is None else str(value)
                    return "'"+text if isinstance(value,str) and text.lstrip().startswith(('=','+','-','@')) else text
                for table in tablas:
                    writer.writerow([safe(table['titulo'])]);writer.writerow([safe(v) for v in table['headers']])
                    writer.writerows([[safe(v) for v in row] for row in table['rows']]);writer.writerow([])
                return response
            if request.GET.get('formato')=='pdf':
                response=HttpResponse(crear_pdf(titulo,tablas,periodo),content_type='application/pdf')
                response['Content-Disposition']='inline; filename="reporte-pintureria.pdf"'
                return response
        except ValueError as exc: form.add_error(None,str(exc))
        except DatabaseError: form.add_error(None,'No se pudo consultar SQL Server. Verifique la conexión y los scripts 06 y 07.')
    params=request.GET.copy();params['formato']='csv';csv_query=params.urlencode();params['formato']='pdf'
    return render(request,'reportes/index.html',{'form':form,'tablas':tablas,'titulo':titulo,'pdf_query':params.urlencode(),'csv_query':csv_query})
