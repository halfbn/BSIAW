# Bezpieczeństwo Serwerów i Aplikacji Webowych - Laboratorium.

## Wymagania
- Python 3.10+

## Instalacja i uruchomienie

1. **Sklonuj repozytorium lub pobierz pliki projektu.**

2. **Utwórz i aktywuj środowisko wirtualne:**

   Linux/macOS:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```
   
3. **Zainstaluj wymagane pakiety:**
```bash
pip install -r requirements.txt
```

4. **Wykonaj migracje bazy danych:**
```bash
python manage.py migrate
```
6. **Uruchom serwer:**
```bash
python manage.py runserver
```

7. **Otwórz aplikację w przeglądarce:**
```
http://127.0.0.1:8000/
```

