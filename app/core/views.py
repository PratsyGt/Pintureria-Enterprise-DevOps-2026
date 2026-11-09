from datetime import date,timedelta
from django.shortcuts import render
from .decorators import login_required_custom
from .permissions import user_permissions
from .dashboard_services import PeriodForm,load_dashboard

@login_required_custom
def dashboard(request):
    today=date.today();initial={'desde':today-timedelta(days=29),'hasta':today}
    form=PeriodForm(request.GET if request.GET else None,initial=initial)
    period=form.cleaned_data if request.GET and form.is_valid() else initial
    data=load_dashboard(user_permissions(request),period['desde'],period['hasta'])
    return render(request,'core/dashboard.html',{'dashboard':data,'period_form':form,'period':period})

@login_required_custom
def perfil(request):
    return render(request,'seguridad/perfil.html')
