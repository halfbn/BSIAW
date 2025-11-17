# Użyj oficjalnego obrazu Pythona
FROM python:3.10-slim

# Ustaw zmienne środowiskowe, aby zapobiec tworzeniu plików .pyc i buforowaniu outputu
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Ustaw katalog roboczy w kontenerze
WORKDIR /app

# Zainstaluj zależności systemowe
# (Na ten moment nie są potrzebne, ale to dobre miejsce na apt-get install)

# Zainstaluj zależności Pythona
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Skopiuj cały kod projektu do katalogu roboczego
COPY . .

# Uruchom migracje i zbierz pliki statyczne
RUN python manage.py migrate --noinput
RUN python manage.py collectstatic --noinput

# Uruchom serwer aplikacji Gunicorn.
# Będzie on nasłuchiwał na wszystkie interfejsy sieciowe wewnątrz kontenera na porcie 8000.
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "bsiaw.wsgi:application"]
