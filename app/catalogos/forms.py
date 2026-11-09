from django import forms

class ClienteForm(forms.Form):
    tipo_cliente=forms.ChoiceField(label='Tipo de cliente',choices=[('PARTICULAR','Particular'),('EMPRESA','Empresa')])
    nit=forms.CharField(max_length=20,required=False,label='NIT')
    nombre=forms.CharField(max_length=150)
    telefono=forms.CharField(max_length=30,required=False)
    correo=forms.EmailField(max_length=120,required=False)
    direccion=forms.CharField(max_length=250,required=False,widget=forms.Textarea(attrs={'rows':2}))

class ProveedorForm(forms.Form):
    nit=forms.CharField(max_length=20,required=False,label='NIT')
    nombre=forms.CharField(max_length=150)
    contacto=forms.CharField(max_length=120,required=False)
    telefono=forms.CharField(max_length=30,required=False)
    correo=forms.EmailField(max_length=120,required=False)
    direccion=forms.CharField(max_length=250,required=False,widget=forms.Textarea(attrs={'rows':2}))

class CategoriaForm(forms.Form):
    nombre=forms.CharField(max_length=80)
    tipo_control=forms.ChoiceField(label='Tipo de control',choices=[
        ('ACCESORIO','Accesorio'),('SOLVENTE','Solvente'),('PINTURA','Pintura'),('BARNIZ','Barniz'),('OTRO','Otro')])
    maneja_lote=forms.BooleanField(required=False,label='Maneja lotes / PEPS')
    descripcion=forms.CharField(max_length=200,required=False,widget=forms.Textarea(attrs={'rows':2}))

class MarcaForm(forms.Form):
    nombre=forms.CharField(max_length=100)
    descripcion=forms.CharField(max_length=200,required=False,widget=forms.Textarea(attrs={'rows':2}))
