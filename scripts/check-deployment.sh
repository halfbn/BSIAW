#!/bin/bash

# Skrypt do sprawdzania stanu aplikacji BSIAW na EC2
# Użycie: ./scripts/check-deployment.sh

echo "=== BSIAW Application Status Check ==="
echo "Timestamp: $(date)"
echo ""

# Sprawdź publiczny IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "Unknown")
echo "Public IP: $PUBLIC_IP"
echo ""

# Sprawdź status usług systemowych
echo "=== System Services ==="
echo "Nginx status:"
systemctl is-active nginx && echo "✅ Nginx: Running" || echo "❌ Nginx: Not running"

echo "Supervisor status:"
systemctl is-active supervisord && echo "✅ Supervisor: Running" || echo "❌ Supervisor: Not running"

echo "Docker status:"
systemctl is-active docker && echo "✅ Docker: Running" || echo "❌ Docker: Not running"
echo ""

# Sprawdź aplikację Django
echo "=== Django Application ==="
supervisorctl status bsiaw 2>/dev/null && echo "✅ BSIAW app: Running" || echo "❌ BSIAW app: Not running"
echo ""

# Sprawdź porty
echo "=== Network Status ==="
echo "Port 80 (HTTP):"
netstat -tlnp | grep :80 && echo "✅ Port 80: Open" || echo "❌ Port 80: Closed"

echo "Port 8000 (Django):"
netstat -tlnp | grep :8000 && echo "✅ Port 8000: Open" || echo "❌ Port 8000: Closed"

echo "Port 22 (SSH):"
netstat -tlnp | grep :22 && echo "✅ Port 22: Open" || echo "❌ Port 22: Closed"
echo ""

# Test HTTP response
echo "=== HTTP Health Check ==="
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null || echo "000")
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ HTTP Response: $HTTP_STATUS (OK)"
elif [ "$HTTP_STATUS" = "000" ]; then
    echo "❌ HTTP Response: Connection failed"
else
    echo "⚠️  HTTP Response: $HTTP_STATUS"
fi
echo ""

# Sprawdź logi
echo "=== Recent Logs ==="
echo "Last 5 lines from application log:"
tail -n 5 /var/log/bsiaw/gunicorn.log 2>/dev/null || echo "No application logs found"
echo ""

echo "Last 5 lines from Nginx error log:"
tail -n 5 /var/log/nginx/error.log 2>/dev/null || echo "No Nginx error logs"
echo ""

# Sprawdź miejsce na dysku
echo "=== Disk Usage ==="
df -h / | grep -v Filesystem
echo ""

# Sprawdź pamięć
echo "=== Memory Usage ==="
free -h
echo ""

# Sprawdź procesy
echo "=== Key Processes ==="
ps aux | grep -E "(gunicorn|nginx|supervisord)" | grep -v grep
echo ""

# Sprawdź bazę danych SQLite
echo "=== Database Status ==="
cd /home/deploy/bsiaw 2>/dev/null || cd /opt/app
if [ -f db.sqlite3 ]; then
    DB_SIZE=$(du -h db.sqlite3 | cut -f1)
    echo "✅ SQLite Database: $DB_SIZE"
    
    if [ -f venv/bin/activate ]; then
        source venv/bin/activate
        TABLES_COUNT=$(python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
cursor.execute(\"SELECT count(*) FROM sqlite_master WHERE type='table'\")
print(cursor.fetchone()[0])
" 2>/dev/null || echo "0")
        echo "📊 Tables count: $TABLES_COUNT"
    fi
else
    echo "❌ Database: SQLite file not found"
fi
echo ""

# Podsumowanie
echo "=== Summary ==="
if [ "$HTTP_STATUS" = "200" ]; then
    echo "🎉 Application Status: HEALTHY"
    echo "🌐 Access URL: http://$PUBLIC_IP"
else
    echo "🚨 Application Status: UNHEALTHY"
    echo "🔧 Check logs and restart services if needed"
fi
echo ""
echo "=== Quick Commands ==="
echo "Restart application: sudo supervisorctl restart bsiaw"
echo "Reload Nginx: sudo systemctl reload nginx"
echo "View app logs: tail -f /var/log/bsiaw/gunicorn.log"
echo "Check instance info: cat /home/deploy/bsiaw/instance-info.txt"
