FROM python:3.10-slim

# Instalacja i czyszczenie cache (dobra praktyka)
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

# Instalacja gunicorna
RUN pip install gunicorn

WORKDIR /bsiaw

COPY . .
COPY static/pizza.png static/pizza.png

RUN pip install -r requirements.txt

COPY nginx.conf /etc/nginx/nginx.conf
RUN python manage.py collectstatic --noinput
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

RUN touch /tmp/nginx.pid && chown appuser:appgroup /tmp/nginx.pid

# Nadawanie uprawnień do katalogów Nginxa i Aplikacji
RUN chown -R appuser:appgroup /var/lib/nginx /var/log/nginx /etc/nginx /bsiaw

USER appuser

EXPOSE 8080

CMD python manage.py migrate && nginx && gunicorn --bind 0.0.0.0:8000 bsiaw.wsgi:application

