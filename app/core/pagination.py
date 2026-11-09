"""SQL Server pagination. SQL/column names are supplied only by trusted repositories."""
from math import ceil
from datetime import date,timedelta
from .db import execute_query

def page_query(request,source,columns,pk,params=None,state_column=None,states=(),default_sort=None,date_column=None):
    def integer(value,default,low,high):
        try:return max(low,min(high,int(value)))
        except (TypeError,ValueError):return default
    size=integer(request.GET.get('size'),25,10,100)
    page=integer(request.GET.get('page'),1,1,1000000)
    sort=request.GET.get('sort',default_sort or pk)
    if sort not in columns:sort=pk
    direction='DESC' if request.GET.get('direction')=='desc' else 'ASC'
    q=request.GET.get('q','').strip()[:100]
    values=list(params or []);clauses=[]
    record = request.GET.get('registro')
    if record is not None:
        # Dashboard links to one row in modules without a detail page.
        clauses.append(f'[{pk}]=%s')
        valid = record.isascii() and record.isdecimal() and len(record) <= 10
        values.append(int(record) if valid and int(record) <= 2147483647 else -1)
    if q:
        escaped=q.replace('~','~~').replace('%','~%').replace('_','~_').replace('[','~[')
        clauses.append('('+' OR '.join(f"CAST([{c}] AS NVARCHAR(500)) LIKE %s ESCAPE '~'" for c in columns)+')')
        values += ['%'+escaped+'%']*len(columns)
    state=request.GET.get('estado','')
    if state_column and state in {str(s[0]) for s in states}:
        clauses.append(f'[{state_column}]=%s');values.append(state)
    date_error='';start=request.GET.get('desde','');end=request.GET.get('hasta','')
    if date_column and (start or end):
        try:
            first=date.fromisoformat(start) if start else None
            last=date.fromisoformat(end) if end else None
            if first and last and first>last:raise ValueError()
            exclusive=last+timedelta(days=1) if last else None
            if first:clauses.append(f'[{date_column}]>=%s');values.append(first)
            if last:clauses.append(f'[{date_column}]<%s');values.append(exclusive)
        except (ValueError,OverflowError):
            clauses.append('1=0');date_error='Revisa las fechas y su orden.'
    where=' WHERE '+' AND '.join(clauses) if clauses else ''
    source=source.strip().rstrip(';')
    total=execute_query(f'SELECT COUNT_BIG(*) AS total FROM ({source}) AS records'+where,values,one=True)['total']
    pages=max(1,ceil(total/size));page=min(page,pages)
    order=f'[{sort}] {direction}'+(f', [{pk}] ASC' if sort!=pk else '')
    rows=execute_query(f'SELECT * FROM ({source}) AS records'+where+f' ORDER BY {order} OFFSET %s ROWS FETCH NEXT %s ROWS ONLY',values+[(page-1)*size,size])
    def link(number):
        query=request.GET.copy();query['page']=number
        return '?'+query.urlencode()
    return rows,{'date_filter':bool(date_column),'desde':start,'hasta':end,'error':date_error,'total':total,'page':page,'pages':pages,'size':size,'q':q,'sort':sort,'direction':direction.lower(),'sorts':list(columns),'states':states,'state':state,'previous':link(page-1) if page>1 else None,'next':link(page+1) if page<pages else None}
