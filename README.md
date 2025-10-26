# Bezpieczeństwo Serwerów i Aplikacji Webowych - L

## Wymagania
- Python 3.10+

## Instalacja i uruchomienie

1. **Sklonuj repozytorium lub pobierz pliki projektu.**

2. **Utwórz i aktywuj środowisko wirtualne:**
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate    # Windows
```

3. **Zainstaluj wymagane pakiety:**
```bash
pip install -r requirements.txt
```

4. **Wykonaj migracje bazy danych:**
```bash
python manage.py migrate
```

5. **(Opcjonalnie) Utwórz konto administratora do panelu admina:**
```bash
python manage.py createsuperuser
```

6. **Uruchom serwer:**
```bash
python manage.py runserver
```

7. **Otwórz aplikację w przeglądarce:**
```
http://127.0.0.1:8000/
```
