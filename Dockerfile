FROM python:3.10-slim

RUN apt-get update && apt-get install -y nginx
RUN pip install gunicorn

WORKDIR /bsiaw

COPY . .
COPY static/pizza.png static/pizza.png

RUN pip install -r requirements.txt

COPY nginx.conf /etc/nginx/sites-available/default

RUN groupadd -r appgroup && useradd -r -g appgroup appuser
RUN chown -R appuser:appgroup /var/lib/nginx /var/log/nginx /etc/nginx /bsiaw
USER appuser
CMD python manage.py migrate && nginx && gunicorn --bind 0.0.0.0:8000 bsiaw.wsgi:application





