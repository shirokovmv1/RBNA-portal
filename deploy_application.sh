#!/bin/bash
# Скрипт развертывания приложения (запускать от пользователя rbna)
# Использование: ./deploy_application.sh yourdomain.com

set -e

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
    echo "❌ Ошибка: Укажите домен"
    echo "Использование: ./deploy_application.sh yourdomain.com"
    exit 1
fi

# Проверка, что запущено от правильного пользователя
if [ "$USER" != "rbna" ]; then
    echo "⚠️  Запустите скрипт от пользователя rbna"
    echo "Использование: su - rbna, затем ./deploy_application.sh $DOMAIN"
    exit 1
fi

echo "🚀 Развертывание приложения RBNA Portal"
echo "========================================"
echo ""

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${GREEN}[ШАГ]${NC} $1"
}

# Проверка наличия проекта
if [ ! -d "/home/rbna/rbna-portal/backend" ] || [ ! -d "/home/rbna/rbna-portal/frontend" ]; then
    echo "❌ Ошибка: Проект не найден!"
    echo ""
    echo "Загрузите проект на сервер:"
    echo "  scp -r backend/ frontend/ rbna@$DOMAIN:/home/rbna/rbna-portal/"
    echo ""
    echo "Или клонируйте из Git:"
    echo "  cd /home/rbna/rbna-portal"
    echo "  git clone https://github.com/your-username/RBNA-portal.git ."
    exit 1
fi

# Чтение пароля БД из credentials.txt
if [ -f "/home/rbna/rbna-portal/credentials.txt" ]; then
    DB_PASSWORD=$(grep "Пароль:" /home/rbna/rbna-portal/credentials.txt | awk '{print $2}')
else
    echo "⚠️  Пароль БД не найден. Введите вручную:"
    read -s DB_PASSWORD
fi

# ШАГ 1: Backend
print_step "Настройка Backend..."

cd /home/rbna/rbna-portal/backend

# Виртуальное окружение
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

source venv/bin/activate

# Установка зависимостей
pip install --upgrade pip -q
pip install -r requirements.txt -q
pip install gunicorn psycopg2-binary -q

# Генерация SECRET_KEY
SECRET_KEY=$(python manage.py shell -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")

# Создание .env
if [ ! -f ".env" ]; then
    cat > .env <<EOF
SECRET_KEY=$SECRET_KEY
DEBUG=False
ALLOWED_HOSTS=$DOMAIN,www.$DOMAIN
CORS_ALLOWED_ORIGINS=https://$DOMAIN,https://www.$DOMAIN
SECURE_SSL_REDIRECT=True
DB_NAME=rbna_portal
DB_USER=rbna_user
DB_PASSWORD=$DB_PASSWORD
DB_HOST=localhost
DB_PORT=5432
EOF
    echo "✅ .env файл создан"
else
    echo "⚠️  .env файл уже существует, обновляю SECRET_KEY и настройки..."
    sed -i "s|SECRET_KEY=.*|SECRET_KEY=$SECRET_KEY|" .env
    sed -i "s|DEBUG=.*|DEBUG=False|" .env
    sed -i "s|ALLOWED_HOSTS=.*|ALLOWED_HOSTS=$DOMAIN,www.$DOMAIN|" .env
    sed -i "s|CORS_ALLOWED_ORIGINS=.*|CORS_ALLOWED_ORIGINS=https://$DOMAIN,https://www.$DOMAIN|" .env
    sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASSWORD|" .env
fi

# Обновление settings.py для PostgreSQL (если нужно)
if ! grep -q "django.db.backends.postgresql" rbnaportal/settings.py; then
    echo "📝 Обновление settings.py для PostgreSQL..."
    # Резервная копия
    cp rbnaportal/settings.py rbnaportal/settings.py.backup
    
    # Замена DATABASES секции
    python3 << 'PYEOF'
import re

with open('rbnaportal/settings.py', 'r') as f:
    content = f.read()

# Заменить DATABASES секцию
new_db_config = """DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'rbna_portal'),
        'USER': os.environ.get('DB_USER', 'rbna_user'),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}"""

# Найти и заменить DATABASES
pattern = r'DATABASES\s*=\s*\{[^}]+\}'
content = re.sub(pattern, new_db_config, content, flags=re.DOTALL)

with open('rbnaportal/settings.py', 'w') as f:
    f.write(content)
PYEOF
    echo "✅ settings.py обновлен"
fi

# Миграции
python manage.py migrate --noinput
echo "✅ Миграции применены"

# Загрузка демо-данных (опционально)
read -p "Загрузить демо-данные? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    python manage.py seed_data
    echo "✅ Демо-данные загружены"
fi

# Создание суперпользователя
echo ""
echo "Создание суперпользователя Django:"
python manage.py createsuperuser || echo "⚠️  Суперпользователь уже существует или создание пропущено"

# Сбор статических файлов
python manage.py collectstatic --noinput
echo "✅ Статические файлы собраны"

# Создание конфигурации Gunicorn
cat > gunicorn_config.py <<EOF
import multiprocessing

bind = "127.0.0.1:8000"
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
timeout = 120
keepalive = 5
max_requests = 1000
max_requests_jitter = 50
user = "rbna"
group = "rbna"
logfile = "/home/rbna/rbna-portal/logs/gunicorn.log"
loglevel = "info"
EOF

echo "✅ Gunicorn конфигурация создана"

# Создание systemd сервиса (требует sudo)
print_step "Создание systemd сервиса..."
sudo tee /etc/systemd/system/rbna-portal.service > /dev/null <<EOF
[Unit]
Description=RBNA Portal Gunicorn daemon
After=network.target postgresql.service

[Service]
User=rbna
Group=rbna
WorkingDirectory=/home/rbna/rbna-portal/backend
Environment="PATH=/home/rbna/rbna-portal/backend/venv/bin"
ExecStart=/home/rbna/rbna-portal/backend/venv/bin/gunicorn \\
    --config /home/rbna/rbna-portal/backend/gunicorn_config.py \\
    rbnaportal.wsgi:application
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable rbna-portal
sudo systemctl start rbna-portal

echo "✅ Systemd сервис создан и запущен"

# ШАГ 2: Frontend
print_step "Настройка Frontend..."

cd /home/rbna/rbna-portal/frontend

# Создание .env.production
cat > .env.production <<EOF
REACT_APP_API_URL=https://$DOMAIN/api
EOF

# Установка зависимостей и сборка
npm install --legacy-peer-deps --silent
npm run build

echo "✅ Frontend собран"

# ШАГ 3: Nginx
print_step "Настройка Nginx..."

sudo tee /etc/nginx/sites-available/rbna-portal > /dev/null <<EOF
# Редирект HTTP на HTTPS
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS сервер (SSL будет настроен certbot)
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # Временные самоподписанные сертификаты (будут заменены certbot)
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    client_max_body_size 10M;

    # Frontend
    location / {
        root /home/rbna/rbna-portal/frontend/build;
        try_files \$uri \$uri/ /index.html;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # Статические файлы Django
    location /static/ {
        alias /home/rbna/rbna-portal/backend/staticfiles/;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # API
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
    }

    # Админка Django
    location /admin/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Активация конфигурации
sudo ln -sf /etc/nginx/sites-available/rbna-portal /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Проверка и перезагрузка Nginx
sudo nginx -t
sudo systemctl reload nginx

echo "✅ Nginx настроен"

# ШАГ 4: SSL сертификат
print_step "Настройка SSL сертификата..."

if command -v certbot &> /dev/null; then
    echo "Установка SSL сертификата Let's Encrypt..."
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN --redirect || {
        echo "⚠️  Не удалось установить SSL автоматически"
        echo "Выполните вручную: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    }
else
    echo "⚠️  Certbot не установлен. Установите: sudo apt-get install certbot python3-certbot-nginx"
    echo "Затем выполните: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
fi

echo ""
echo "=========================================="
echo "✅ Развертывание завершено!"
echo "=========================================="
echo ""
echo "🌐 Приложение доступно по адресу:"
echo "   https://$DOMAIN"
echo ""
echo "🔐 Админка Django:"
echo "   https://$DOMAIN/admin/"
echo ""
echo "📊 Проверка статуса:"
echo "   sudo systemctl status rbna-portal"
echo ""
echo "📝 Логи:"
echo "   sudo journalctl -u rbna-portal -f"
echo "   tail -f /home/rbna/rbna-portal/logs/gunicorn.log"
echo ""
