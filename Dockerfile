FROM python:3.10.14-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir gunicorn==21.2.0

WORKDIR /bsiaw

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
COPY nginx.conf /etc/nginx/nginx.conf

RUN groupadd -r appgroup && useradd -r -g appgroup appuser

RUN chown -R root:root /etc/nginx && chmod -R 755 /etc/nginx

# Create writable dirs for read-only root at runtime
RUN mkdir -p /bsiaw/static /run/nginx /var/log/nginx && \
    chown -R appuser:appgroup /bsiaw /run/nginx /var/log/nginx

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:8000/ || exit 1

CMD ["sh", "-c", "\
    python manage.py collectstatic --noinput && \
    python manage.py migrate && \
    gunicorn --bind 0.0.0.0:8000 bsiaw.wsgi:application & \
    nginx -g 'daemon off;' \
"]
