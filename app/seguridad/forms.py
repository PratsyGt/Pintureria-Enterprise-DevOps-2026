from django import forms

class LoginForm(forms.Form):
    usuario=forms.CharField(max_length=50,label='Usuario',widget=forms.TextInput(attrs={'autofocus':True}))
    clave=forms.CharField(label='Contraseña',widget=forms.PasswordInput())

class UsuarioForm(forms.Form):
    nombre_usuario=forms.CharField(max_length=50,label='Usuario')
    nombres=forms.CharField(max_length=80)
    apellidos=forms.CharField(max_length=80)
    correo=forms.EmailField(max_length=120,required=False)
    rol_id=forms.ChoiceField(label='Rol',choices=[])
    clave=forms.CharField(label='Contraseña',required=False,widget=forms.PasswordInput(),help_text='Obligatoria al crear. En edición, deje vacío para conservarla.')

    def __init__(self,*args,roles=None,editing=False,**kwargs):
        self.editing=editing
        super().__init__(*args,**kwargs)
        self.fields['rol_id'].choices=[(r['RolID'],r['Nombre']) for r in (roles or [])]

    def clean(self):
        cleaned=super().clean()
        if not self.editing and not cleaned.get('clave'):
            self.add_error('clave','La contraseña es obligatoria para un usuario nuevo.')
        if cleaned.get('clave') and len(cleaned['clave']) < 12:
            self.add_error('clave','Use al menos 12 caracteres.')
        return cleaned
