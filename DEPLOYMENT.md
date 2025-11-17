# BSIAW Django - Instrukcja deploymentu CI/CD

## Przygotowanie środowiska AWS EC2

### Opcja 1: Automatyczna konfiguracja z User Data (ZALECANE)

Użyj skryptu `scripts/ec2-user-data.sh` jako User Data podczas tworzenia instancji EC2. Skrypt automatycznie:

- ✅ Zainstaluje wszystkie niezbędne komponenty
- ✅ Skonfiguruje użytkownika `deploy`
- ✅ Sklonuje repozytorium i uruchomi aplikację
- ✅ Skonfiguruje Nginx, Supervisor i wszystkie usługi
- ✅ Połączy się z bazą danych RDS PostgreSQL
- ✅ Przygotuje środowisko do CI/CD

**Kroki:**
1. W AWS Console podczas tworzenia EC2 w sekcji "Advanced Details"
2. W polu "User data" wklej zawartość pliku `scripts/ec2-user-data.sh`
3. Uruchom instancję
4. Poczekaj 5-10 minut na zakończenie konfiguracji
5. Sprawdź dostępność aplikacji pod publicznym IP instancji

### Opcja 2: Manualna konfiguracja instancji EC2

Jeśli wolisz ręczną konfigurację, zaloguj się na instancję i wykonaj:

```bash
# Aktualizacja systemu (Amazon Linux 2)
sudo yum update -y

# Instalacja niezbędnego oprogramowania
sudo yum install -y python3 python3-pip nginx supervisor git docker

# Utworzenie użytkownika deploymentowego
sudo useradd -m deploy
sudo usermod -aG wheel deploy
sudo usermod -aG docker deploy

# Konfiguracja SSH dla deploymentu
sudo su - deploy
mkdir ~/.ssh
chmod 700 ~/.ssh
```

### 2. Klonowanie repozytorium (tylko dla opcji manualnej)

```bash
# Jako użytkownik deploy
cd /home/deploy
git clone https://github.com/halfbn/BSIAW.git bsiaw
cd bsiaw

# Utworzenie środowiska wirtualnego
python3 -m venv venv
source venv/bin/activate

# Instalacja zależności
pip install -r requirements.txt
```

### 3. Konfiguracja środowiska (automatyczna z User Data)

Plik `.env` jest automatycznie tworzony z konfiguracją:

```bash
# Sprawdź konfigurację (jako deploy)
cat /home/deploy/bsiaw/.env
```

**Zawiera:**
- Połączenie z RDS PostgreSQL (automatycznie pobrane z AWS Secrets Manager)
- Wygenerowany SECRET_KEY
- Publiczny IP instancji w ALLOWED_HOSTS
- Konfigurację plików statycznych i mediów

### 4. Przygotowanie Django

```bash
# Aktywuj środowisko wirtualne
source venv/bin/activate

# Wykonaj migracje
python manage.py migrate

# Zbierz pliki statyczne
python manage.py collectstatic --noinput

# Utwórz superusera (opcjonalnie)
python manage.py createsuperuser
```

### 5. Konfiguracja Nginx

```bash
# Skopiuj konfigurację Nginx
sudo cp config/nginx.conf /etc/nginx/sites-available/bsiaw

# Edytuj konfigurację - zmień your-domain.com i your-ec2-ip
sudo nano /etc/nginx/sites-available/bsiaw

# Aktywuj konfigurację
sudo ln -s /etc/nginx/sites-available/bsiaw /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Testuj konfigurację
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

### 6. Konfiguracja Supervisor

```bash
# Skopiuj konfigurację Supervisor
sudo cp config/supervisor.conf /etc/supervisor/conf.d/bsiaw.conf

# Przeładuj konfigurację
sudo supervisorctl reread
sudo supervisorctl update

# Uruchom aplikację
sudo supervisorctl start bsiaw

# Sprawdź status
sudo supervisorctl status
```

## Konfiguracja GitHub Actions

### 1. Dodaj Secrets w GitHub

W repozytorium GitHub idź do **Settings > Secrets and variables > Actions** i dodaj:

- `AWS_EC2_HOST` - publiczny IP twojej instancji EC2
- `AWS_EC2_USERNAME` - `deploy`
- `AWS_EC2_PRIVATE_KEY` - treść klucza prywatnego SSH
- `DJANGO_SECRET_KEY` - bezpieczny klucz dla Django

### 2. Konfiguracja klucza SSH

Na swojej lokalnej maszynie:

```bash
# Wygeneruj parę kluczy SSH (jeśli nie masz)
ssh-keygen -t rsa -b 4096 -C "deploy@yourproject"

# Skopiuj klucz publiczny na serwer EC2
ssh-copy-id -i ~/.ssh/id_rsa.pub deploy@YOUR_EC2_IP
```

### 3. Test deploymentu

```bash
# Commituj i pushuj zmiany
git add .
git commit -m "Add CI/CD configuration"
git push origin main
```

## Struktura plików

```
BSIAW/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions workflow
├── config/
│   ├── nginx.conf              # Konfiguracja Nginx
│   └── supervisor.conf         # Konfiguracja Supervisor
├── scripts/
│   ├── deploy.sh               # Skrypt deploymentowy (legacy)
│   ├── auto-deploy.sh          # Automatyczny deployment (na serwerze)
│   ├── ec2-user-data.sh        # User Data script dla EC2
│   ├── check-deployment.sh     # Sprawdzanie stanu aplikacji
│   └── healthcheck.sh          # Health check (na serwerze)
├── .env.example                # Przykładowy plik środowiskowy
├── .gitignore                  # Pliki do ignorowania
├── requirements.txt            # Zaktualizowane zależności
├── DEPLOYMENT.md               # Ta dokumentacja
└── AWS-SECURITY-GROUPS.md      # Konfiguracja Security Groups
```

## Rozwiązywanie problemów

### Sprawdzanie logów

```bash
# Logi aplikacji
sudo tail -f /var/log/bsiaw.log

# Logi Nginx
sudo tail -f /var/log/nginx/error.log

# Status Supervisor
sudo supervisorctl status

# Restart aplikacji
sudo supervisorctl restart bsiaw
```

### Typowe problemy

1. **Błąd 502 Bad Gateway**: Sprawdź czy Gunicorn działa poprawnie
2. **Błąd statycznych plików**: Upewnij się, że `collectstatic` zostało wykonane
3. **Błąd bazy danych**: Sprawdź czy migracje zostały wykonane

## Bezpieczeństwo

- Zmień domyślne hasła
- Konfiguruj firewall (Security Groups w AWS)
- Używaj HTTPS w produkcji
- Regularnie aktualizuj zależności
