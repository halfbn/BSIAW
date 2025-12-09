FROM python:3.10-slim

RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

RUN pip install gunicorn

WORKDIR /bsiaw

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
COPY nginx.conf /etc/nginx/nginx.conf

RUN groupadd -r appgroup && useradd -r -g appgroup appuser

RUN mkdir -p /bsiaw/static && \
    touch /tmp/nginx.pid && \
    chown -R appuser:appgroup /tmp/nginx.pid /var/lib/nginx /var/log/nginx /etc/nginx /bsiaw

USER appuser

EXPOSE 8080

CMD ["/bin/sh", "-c", "python manage.py collectstatic --noinput && python manage.py migrate && nginx && gunicorn --bind 0.0.0.0:8000 bsiaw.wsgi:application"]
