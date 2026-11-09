from datetime import date, timedelta

from django import forms
from django.urls import reverse

from . import dashboard_repository as repo


class PeriodForm(forms.Form):
    desde = forms.DateField(widget=forms.DateInput(format='%Y-%m-%d', attrs={'type': 'date'}))
    hasta = forms.DateField(widget=forms.DateInput(format='%Y-%m-%d', attrs={'type': 'date'}))

    def clean(self):
        values = super().clean()
        start, end = values.get('desde'), values.get('hasta')
        if start and end:
            if start > end or (end - start).days >= 366:
                raise forms.ValidationError('Selecciona un período de entre 1 y 366 días.')
            if start.year < 1754 or end == date.max:
                raise forms.ValidationError('Las fechas están fuera del intervalo admitido.')
        return values


def metric(title, value, icon, note, money=False, previous=None, comparison=''):
    delta = None
    if previous and previous > 0:
        delta = round(100 * ((value or 0) - previous) / previous, 1)
    return dict(label=title, value=value or 0, icon=icon, note=note, money=money,
                delta=delta, comparison=comparison)


def ranked(rows, label):
    maximum = max((row['Total'] for row in rows), default=0)
    return [dict(label=label(row), value=row['Total'],
                 width=100 * row['Total'] / maximum if maximum else 0) for row in rows]


def trend(title, rows):
    peak = max((r[1] for r in rows), default=0) or 1
    points = []
    for index, (label, value) in enumerate(rows):
        # Coordinates stay in an invariant numeric format for the SVG viewBox.
        x = 310 if len(rows) == 1 else 18 + index * 584 / (len(rows)-1)
        y = 142 - 123 * float(value / peak)
        points.append(dict(label=label, value=value, x=f'{x:.2f}', y=f'{y:.2f}'))
    return dict(title=title, points=points, total=sum(row[1] for row in rows),
                line=' '.join(f"{point['x']},{point['y']}" for point in points))


def load_dashboard(perms, start, end):
    def allowed(module):
        return perms.get(module, {}).get('ver', False)

    data = {'kpis': [], 'activity': [], 'financial': allowed('reportes')}
    kpis = data['kpis']
    if data['financial']:
        today = date.today()
        stop = end + timedelta(days=1)
        stats = repo.sales_metrics(today, today.replace(day=1), start, stop)
        kpis.extend([
            metric('Ventas del día', stats['Hoy'], 'cart', 'Facturación de hoy', True,
                   stats['Ayer'], 'frente a ayer'),
            metric('Ventas del mes', stats['Mes'], 'chart', 'Mes en curso', True,
                   stats['MesAnterior'], 'frente al mes anterior a esta fecha'),
            metric('Facturas emitidas', stats['Facturas'], 'receipt', 'En el período', False,
                   stats['FacturasPrevias'], 'frente al período anterior'),
        ])
        data['ticket'] = stats['Ticket'] or 0
        daily = {r['Fecha']: r['Total'] for r in repo.daily(start, stop)}
        days = [start + timedelta(days=i) for i in range((end-start).days+1)]
        series = [(day.strftime('%d/%m'), daily.get(day, 0)) for day in days]
        monthly = {}
        for day in days:
            month = day.strftime('%m/%Y')
            monthly[month] = monthly.get(month, 0) + daily.get(day, 0)
        data['trends'] = [trend('7 días', series[-7:]), trend('Mensual', list(monthly.items())),
                          trend('Período', series)]
        data['payments'] = repo.payments(start, stop)
        data['paid'] = sum(row['Total'] for row in data['payments'])
        offset = 0
        palette = ['#7254ce', '#bca8ee', '#5eac99', '#e4ab6e', '#8392c1']
        for index, row in enumerate(data['payments']):
            row['offset'] = offset
            row['color'] = palette[index % len(palette)]
            row['share'] = 100 * row['Total'] / data['paid'] if data['paid'] else 0
            offset += row['share']
        def variant(row):
            return f"{row['Producto']} · {row['Presentacion']} · {row['SKU']}"
        data['rankings'] = [
            dict(title='Unidades', rows=ranked(repo.top_products(start, stop), variant)),
            dict(title='Ingresos', rows=ranked(repo.top_products(start, stop, 'income'), variant)),
        ]

    if allowed('cotizaciones'):
        kpis.append(metric('Cotizaciones pendientes', repo.pending_quotes(), 'file', 'Por confirmar'))
    if allowed('inventario'):
        inv = repo.inventory()
        kpis.append(metric('Stock bajo', inv['Bajos'], 'layers', 'En el mínimo o por debajo'))
        data['inventory'] = [
            ('Disponible', inv['Variantes']-inv['Agotados']-inv['Bajos']),
            ('Stock bajo', inv['Bajos']), ('Agotado', inv['Agotados']),
        ]
        data['alerts'] = repo.stock_alerts() if inv['Agotados'] else []
    if allowed('compras'):
        kpis.append(metric('Compras pendientes', repo.pending_purchases(), 'truck', 'Por recibir'))
    if allowed('productos'):
        data['active_products'] = repo.active_products()

    for module, title, icon in [('facturas','Últimas facturas','receipt'),
                                ('cotizaciones','Cotizaciones recientes','file'),
                                ('compras','Últimas compras','truck'),
                                ('inventario','Movimientos recientes','layers')]:
        if allowed(module):
            listing = reverse('inventario_movimientos' if module == 'inventario' else module)
            rows = repo.recent(module)
            for row in rows:
                if module in ('facturas', 'cotizaciones'):
                    view = 'factura_imprimir' if module == 'facturas' else 'cotizacion_detalle'
                    row['url'] = reverse(view, args=[row['ID']])
                else:
                    row['url'] = f"{listing}?registro={row['ID']}"
            data['activity'].append(dict(label=title, icon=icon, url=listing, rows=rows))
    return data
