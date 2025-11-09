FROM python:3.10-slim

RUN apt-get update && apt-get install -y nginx
RUN pip install gunicorn

WORKDIR /bsiaw

COPY . .
COPY /static/pizza.png /static/pizza.png

RUN pip install -r requirements.txt
RUN python manage.py migrate

COPY nginx.conf /etc/nginx/sites-available/default

CMD service nginx start && gunicorn --bind 0.0.0.0:8000 bsiaw.wsgi:application
