#!/bin/bash
set -e

# Logowanie
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting EC2 instance setup for BSIAW Django CI/CD..."

# Aktualizacja systemu
yum update -y

# Instalacja podstawowych narzędzi
yum install -y git python3 python3-pip nginx supervisor

# Utworzenie użytkownika deploy
useradd -m -s /bin/bash deploy
usermod -aG wheel deploy

# Konfiguracja sudo bez hasła dla deploy
echo "deploy ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/deploy

# Przełączenie na użytkownika deploy dla dalszej konfiguracji
su - deploy << 'EOF'
# Konfiguracja SSH dla deploy
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Klonowanie repozytorium
cd /home/deploy
git clone --branch test-ci-cd https://github.com/halfbn/BSIAW.git bsiaw
cd bsiaw

# Utworzenie środowiska wirtualnego Python
python3 -m venv venv
source venv/bin/activate

# Instalacja zależności Python
pip install --upgrade pip
pip install -r requirements.txt

# Utworzenie prostego pliku .env
cat > .env << EOL
DEBUG=False
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
ALLOWED_HOSTS=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4),localhost,127.0.0.1
STATIC_ROOT=/home/deploy/bsiaw/static/
MEDIA_ROOT=/home/deploy/bsiaw/media/
SESSION_COOKIE_SECURE=False
CSRF_COOKIE_SECURE=False
SECURE_SSL_REDIRECT=False
EOL

# Przygotowanie Django (SQLite)
source venv/bin/activate
python manage.py migrate
python manage.py collectstatic --noinput

# Utworzenie superusera (opcjonalnie)
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'admin123') if not User.objects.filter(username='admin').exists() else None" | python manage.py shell

# Utworzenie katalogu dla logów
mkdir -p /var/log/bsiaw
chmod 755 /var/log/bsiaw

EOF

# Konfiguracja Nginx jako root
cat > /etc/nginx/conf.d/bsiaw.conf << 'EOL'
server {
    listen 80;
    server_name _;

    client_max_body_size 100M;

    location = /favicon.ico { 
        access_log off; 
        log_not_found off; 
    }
    
    location /static/ {
        alias /home/deploy/bsiaw/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    location /media/ {
        alias /home/deploy/bsiaw/media/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
}
EOL

# Usunięcie domyślnej konfiguracji Nginx
rm -f /etc/nginx/nginx.conf.default
rm -f /etc/nginx/conf.d/default.conf

# Test konfiguracji Nginx
nginx -t

# Konfiguracja Supervisor
cat > /etc/supervisor/conf.d/bsiaw.conf << 'EOL'
[program:bsiaw]
command=/home/deploy/bsiaw/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 bsiaw.wsgi:application
directory=/home/deploy/bsiaw
user=deploy
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/bsiaw/gunicorn.log
stderr_logfile=/var/log/bsiaw/gunicorn_error.log
environment=PATH="/home/deploy/bsiaw/venv/bin"

[supervisord]
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
childlogdir=/var/log/supervisor

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock
EOL

# Tworzenie katalogu dla socketów
mkdir -p /run/supervisor
chown deploy:deploy /run/supervisor

# Uruchomienie i włączenie usług
systemctl start nginx
systemctl enable nginx
systemctl start supervisord
systemctl enable supervisord

# Przeładowanie konfiguracji Supervisor
supervisorctl reread
supervisorctl update
supervisorctl start bsiaw

# Tworzenie skryptu do automatycznego deploymentu
cat > /home/deploy/bsiaw/scripts/auto-deploy.sh << 'EOL'
#!/bin/bash
set -e

echo "Starting auto-deployment for BSIAW..."

cd /home/deploy/bsiaw

# Pull latest changes
git pull origin test-ci-cd

# Activate virtual environment
source venv/bin/activate

# Install/update dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Restart application
sudo supervisorctl restart bsiaw

# Reload Nginx
sudo systemctl reload nginx

echo "Auto-deployment completed successfully!"
EOL

# Nadanie uprawnień wykonywania
chmod +x /home/deploy/bsiaw/scripts/auto-deploy.sh
chown deploy:deploy /home/deploy/bsiaw/scripts/auto-deploy.sh

# Dodanie deploy do sudoers dla konkretnych komend
cat > /etc/sudoers.d/deploy-specific << 'EOL'
deploy ALL=(ALL) NOPASSWD: /bin/systemctl reload nginx
deploy ALL=(ALL) NOPASSWD: /usr/bin/supervisorctl restart bsiaw
deploy ALL=(ALL) NOPASSWD: /usr/bin/supervisorctl status
deploy ALL=(ALL) NOPASSWD: /usr/bin/supervisorctl stop bsiaw
deploy ALL=(ALL) NOPASSWD: /usr/bin/supervisorctl start bsiaw
EOL

# Konfiguracja logrotate dla aplikacji
cat > /etc/logrotate.d/bsiaw << 'EOL'
/var/log/bsiaw/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 0644 deploy deploy
    postrotate
        supervisorctl restart bsiaw > /dev/null 2>&1 || true
    endscript
}
EOL

# Tworzenie skryptu healthcheck
cat > /home/deploy/bsiaw/scripts/healthcheck.sh << 'EOL'
#!/bin/bash

# Simple healthcheck script
HEALTH_URL="http://localhost"
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL)

if [ $STATUS_CODE -eq 200 ]; then
    echo "$(date): Application is healthy (HTTP $STATUS_CODE)"
    exit 0
else
    echo "$(date): Application is unhealthy (HTTP $STATUS_CODE)"
    # Try to restart the application
    sudo supervisorctl restart bsiaw
    exit 1
fi
EOL

chmod +x /home/deploy/bsiaw/scripts/healthcheck.sh
chown deploy:deploy /home/deploy/bsiaw/scripts/healthcheck.sh

# Dodanie cronjob dla healthcheck (co 5 minut)
(crontab -u deploy -l 2>/dev/null; echo "*/5 * * * * /home/deploy/bsiaw/scripts/healthcheck.sh >> /var/log/bsiaw/healthcheck.log 2>&1") | crontab -u deploy -

# Sprawdzenie statusu wszystkich usług
echo "=== Service Status Check ==="
systemctl status nginx --no-pager
systemctl status supervisord --no-pager
supervisorctl status

# Test dostępności aplikacji
sleep 10
curl -I http://localhost || echo "Application not yet ready"

# Zapisanie informacji o instancji
cat > /home/deploy/bsiaw/instance-info.txt << EOL
Instance setup completed at: $(date)
Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
Private IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)
Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

Database: SQLite (local file)
Application Status: Running on port 8000 via Gunicorn
Web Server: Nginx on port 80
Process Manager: Supervisor

Admin user: admin / admin123

Logs locations:
- Application: /var/log/bsiaw/gunicorn.log
- Nginx: /var/log/nginx/
- Supervisor: /var/log/supervisor/

Commands:
- Restart app: sudo supervisorctl restart bsiaw
- Check status: sudo supervisorctl status
- View logs: tail -f /var/log/bsiaw/gunicorn.log
- Deploy: /home/deploy/bsiaw/scripts/auto-deploy.sh
EOL

chown deploy:deploy /home/deploy/bsiaw/instance-info.txt

echo "=== EC2 Instance Setup Complete ==="
echo "BSIAW Django application is ready for CI/CD deployment"
echo "Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Application URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Admin panel: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/admin"
echo "Login: admin / admin123"
echo "Instance info saved to: /home/deploy/bsiaw/instance-info.txt"
