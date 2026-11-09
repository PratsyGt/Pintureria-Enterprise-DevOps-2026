from pathlib import Path
import os
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / '.env')

from django.core.exceptions import ImproperlyConfigured
SECRET_KEY = os.getenv('SECRET_KEY')
if not SECRET_KEY or len(SECRET_KEY)<50:
    raise ImproperlyConfigured('Configure SECRET_KEY en app/.env (mínimo 50 caracteres aleatorios).')
DEBUG = os.getenv('DEBUG','1') == '1'
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS','localhost,127.0.0.1,testserver').split(',')

INSTALLED_APPS = [
    'django.contrib.staticfiles',
    'django.contrib.sessions',
    'django.contrib.messages',
    'core',
    'seguridad',
    'catalogos',
    'comercial',
    'reportes',
]

MIDDLEWARE = [
    'core.middleware.DatabaseUnavailableMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'
TEMPLATES = [{
    'BACKEND':'django.template.backends.django.DjangoTemplates',
    'DIRS':[BASE_DIR/'templates'],
    'APP_DIRS':True,
    'OPTIONS':{
        'context_processors':[
            'django.template.context_processors.request',
            'django.contrib.messages.context_processors.messages',
            'core.context_processors.usuario_actual',
        ]
    }
}]
WSGI_APPLICATION='config.wsgi.application'

DB_SERVER=os.getenv('DB_SERVER',r'localhost\SQLEXPRESS')
DB_NAME=os.getenv('DB_NAME','PintureriaDB')
DB_USER=os.getenv('DB_USER','')
DB_PASSWORD=os.getenv('DB_PASSWORD','')
trusted=os.getenv('DB_TRUSTED_CONNECTION','yes').lower() in ('1','yes','true','si')
extra='TrustServerCertificate=yes'
if trusted and not DB_USER:
    extra='Trusted_Connection=yes;TrustServerCertificate=yes'

DATABASES={
    'default':{
        'ENGINE':'mssql',
        'NAME':DB_NAME,
        'HOST':DB_SERVER,
        'USER':DB_USER,
        'PASSWORD':DB_PASSWORD,
        'OPTIONS':{
            'driver':os.getenv('DB_DRIVER','ODBC Driver 18 for SQL Server'),
            'extra_params':extra,
            'connection_timeout':5,
        },
    }
}

LANGUAGE_CODE='es-gt'
TIME_ZONE='America/Guatemala'
USE_I18N=True
USE_TZ=False
STATIC_URL='/static/'
STATICFILES_DIRS=[BASE_DIR/'static']
DEFAULT_AUTO_FIELD='django.db.models.BigAutoField'

# Sesiones firmadas: evita crear tablas Django adicionales en SQL Server.
SESSION_ENGINE='django.contrib.sessions.backends.signed_cookies'
SESSION_COOKIE_HTTPONLY=True
SESSION_COOKIE_SAMESITE='Lax'

# Hash seguro con sal aleatoria; el resultado se guarda en dbo.Usuario.PasswordHash.
PASSWORD_HASHERS=['django.contrib.auth.hashers.PBKDF2PasswordHasher']

SESSION_COOKIE_AGE=3600
SESSION_EXPIRE_AT_BROWSER_CLOSE=True
SESSION_COOKIE_SECURE=not DEBUG
CSRF_COOKIE_SECURE=not DEBUG
SECURE_CONTENT_TYPE_NOSNIFF=True
