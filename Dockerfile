FROM python:3.12-slim-bookworm AS runtime
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 APP_CONTAINER=1 DEBUG=0 STATIC_ROOT=/srv/staticfiles TZ=America/Guatemala
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unixodbc tzdata \
 && curl -fsSL https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -o /tmp/ms.deb \
 && dpkg -i /tmp/ms.deb && rm /tmp/ms.deb && apt-get update \
 && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /srv/app
COPY app/requirements*.txt ./
RUN pip install --no-cache-dir -r requirements-container.txt \
 && useradd --system --uid 10001 --create-home pos
COPY app/ ./
COPY database/ /srv/database/
COPY ops/bootstrap.py /srv/ops/bootstrap.py
RUN SECRET_KEY="$(python -c 'import secrets;print(secrets.token_hex(32))')" python manage.py collectstatic --noinput
ARG APP_REVISION=local
ENV APP_REVISION=$APP_REVISION
USER 10001
EXPOSE 8000
HEALTHCHECK --interval=20s --timeout=7s --start-period=30s CMD curl -fsS http://127.0.0.1:8000/health/ready/ || exit 1
CMD ["gunicorn","config.wsgi:application","--bind=0.0.0.0:8000","--workers=2","--access-logfile=-","--error-logfile=-","--graceful-timeout=25"]

FROM runtime AS tests
USER root
RUN pip install --no-cache-dir -r requirements-test.txt
USER 10001
CMD ["python","manage.py","test","core"]

FROM runtime AS production
