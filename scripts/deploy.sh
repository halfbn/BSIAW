#!/bin/bash

# Skrypt deploymentowy dla aplikacji Django BSIAW
echo "Starting deployment..."

# Przejdź do katalogu aplikacji
cd /home/deploy/bsiaw

# Aktywacja środowiska wirtualnego
source venv/bin/activate

# Aktualizacja zależności
echo "Installing/updating dependencies..."
pip install -r requirements.txt

# Migracje bazy danych
echo "Running database migrations..."
python manage.py migrate

# Zbieranie plików statycznych
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Restart aplikacji
echo "Restarting application..."
sudo supervisorctl restart bsiaw

# Reload Nginx
echo "Reloading Nginx..."
sudo systemctl reload nginx

echo "Deployment completed successfully!"
