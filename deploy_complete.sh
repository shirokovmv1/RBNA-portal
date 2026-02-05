#!/bin/bash
# Полностью автоматический скрипт развертывания RBNA Portal
# Использование: ./deploy_complete.sh yourdomain.com [git-repo-url]
# Если git-repo-url не указан, нужно будет загрузить проект вручную

set -e

DOMAIN=$1
GIT_REPO=$2

if [ -z "$DOMAIN" ]; then
    echo "❌ Ошибка: Укажите домен"
    echo "Использование: ./deploy_complete.sh yourdomain.com [git-repo-url]"
    exit 1
fi

echo "🚀 Полностью автоматическое развертывание RBNA Portal"
echo "====================================================="
echo "Домен: $DOMAIN"
if [ -n "$GIT_REPO" ]; then
    echo "Git репозиторий: $GIT_REPO"
fi
echo ""

# Проверка прав root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  Запустите скрипт с sudo или от root"
    exit 1
fi

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${GREEN}[ШАГ $1]${NC} $2"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Генерация паролей
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# ============================================
# ЭТАП 1: Подготовка сервера
# ============================================

print_step "1" "Обновление системы..."
apt-get update -qq
apt-get upgrade -y -qq

print_step "2" "Установка зависимостей..."
apt-get install -y -qq python3 python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib nginx git build-essential \
    libssl-dev libffi-dev ufw curl wget

print_step "3" "Установка Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
apt-get install -y -qq nodejs

print_step "4" "Создание пользователя rbna..."
if ! id "rbna" &>/dev/null; then
    adduser --disabled-password --gecos "" rbna
    usermod -aG sudo rbna
fi

print_step "5" "Настройка PostgreSQL..."
systemctl start postgresql > /dev/null 2>&1
systemctl enable postgresql > /dev/null 2>&1

sudo -u postgres psql <<EOF > /dev/null 2>&1
SELECT 'CREATE DATABASE rbna_portal'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'rbna_portal')\gexec

DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'rbna_user') THEN
        CREATE USER rbna_user WITH PASSWORD '$DB_PASSWORD';
    END IF;
END
\$\$;

ALTER ROLE rbna_user SET client_encoding TO 'utf8';
ALTER ROLE rbna_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE rbna_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE rbna_portal TO rbna_user;
\q
EOF

print_step "6" "Настройка файрвола..."
ufw --force enable > /dev/null 2>&1
ufw allow 22/tcp > /dev/null 2>&1
ufw allow 80/tcp > /dev/null 2>&1
ufw allow 443/tcp > /dev/null 2>&1

print_step "7" "Создание директорий..."
mkdir -p /home/rbna/rbna-portal/{backend,frontend,logs}
chown -R rbna:rbna /home/rbna/rbna-portal

# Сохранение учетных данных
cat > /home/rbna/rbna-portal/credentials.txt <<EOF
===========================================
RBNA Portal - Учетные данные
===========================================

База данных:
  Имя БД: rbna_portal
  Пользователь: rbna_user
  Пароль: $DB_PASSWORD

===========================================
EOF
chown rbna:rbna /home/rbna/rbna-portal/credentials.txt
chmod 600 /home/rbna/rbna-portal/credentials.txt

print_info "Учетные данные сохранены в /home/rbna/rbna-portal/credentials.txt"

# ============================================
# ЭТАП 2: Загрузка проекта
# ============================================

if [ -n "$GIT_REPO" ]; then
    print_step "8" "Клонирование проекта из Git..."
    su - rbna <<RBNA_EOF
cd /home/rbna/rbna-portal
git clone $GIT_REPO . || {
    echo "⚠️  Не удалось клонировать. Убедитесь, что репозиторий доступен."
    exit 1
}
RBNA_EOF
else
    print_step "8" "Ожидание загрузки проекта..."
    echo ""
    echo -e "${YELLOW}⚠️  Загрузите проект на сервер:${NC}"
    echo "   scp -r backend/ frontend/ rbna@$DOMAIN:/home/rbna/rbna-portal/"
    echo ""
    read -p "Нажмите Enter после загрузки проекта..."
fi

# Проверка наличия проекта
if [ ! -d "/home/rbna/rbna-portal/backend" ] || [ ! -d "/home/rbna/rbna-portal/frontend" ]; then
    echo "❌ Ошибка: Проект не найден!"
    exit 1
fi

# ============================================
# ЭТАП 3: Развертывание Backend
# ============================================

print_step "9" "Настройка Backend..."

su - rbna <<RBNA_EOF
cd /home/rbna/rbna-portal/backend

# Виртуальное окружение
python3 -m venv venv
source venv/bin/activate

# Зависимости
pip install --upgrade pip -q
pip install -r requirements.txt -q
pip install gunicorn psycopg2-binary -q

# SECRET_KEY
SECRET_KEY=\$(python manage.py shell -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")

# .env файл
cat > .env <<ENVEOF
SECRET_KEY=\$SECRET_KEY
DEBUG=False
ALLOWED_HOSTS=$DOMAIN,www.$DOMAIN
CORS_ALLOWED_ORIGINS=https://$DOMAIN,https://www.$DOMAIN
SECURE_SSL_REDIRECT=True
DB_NAME=rbna_portal
DB_USER=rbna_user
DB_PASSWORD=$DB_PASSWORD
DB_HOST=localhost
DB_PORT=5432
ENVEOF

# Обновление settings.py для PostgreSQL
python3 << 'PYEOF'
import re
import os

with open('rbnaportal/settings.py', 'r') as f:
    content = f.read()

# Заменить DATABASES
new_db = """DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'rbna_portal'),
        'USER': os.environ.get('DB_USER', 'rbna_user'),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}"""

pattern = r'DATABASES\s*=\s*\{[^}]+\}'
content = re.sub(pattern, new_db, content, flags=re.DOTALL)

with open('rbnaportal/settings.py', 'w') as f:
    f.write(content)
PYEOF

# Миграции
python manage.py migrate --noinput

# Статические файлы
python manage.py collectstatic --noinput

# Gunicorn конфигурация
cat > gunicorn_config.py <<GUNICORNEOF
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
GUNICORNEOF

RBNA_EOF

# Systemd сервис
print_step "10" "Создание systemd сервиса..."
tee /etc/systemd/system/rbna-portal.service > /dev/null <<EOF
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

systemctl daemon-reload
systemctl enable rbna-portal
systemctl start rbna-portal

# ============================================
# ЭТАП 4: Развертывание Frontend
# ============================================

print_step "11" "Сборка Frontend..."

su - rbna <<RBNA_EOF
cd /home/rbna/rbna-portal/frontend

# .env.production
cat > .env.production <<ENVEOF
REACT_APP_API_URL=https://$DOMAIN/api
ENVEOF

# Сборка
npm install --legacy-peer-deps --silent
npm run build
RBNA_EOF

# ============================================
# ЭТАП 5: Настройка Nginx
# ============================================

print_step "12" "Настройка Nginx..."

tee /etc/nginx/sites-available/rbna-portal > /dev/null <<EOF
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

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    client_max_body_size 10M;

    location / {
        root /home/rbna/rbna-portal/frontend/build;
        try_files \$uri \$uri/ /index.html;
    }

    location /static/ {
        alias /home/rbna/rbna-portal/backend/staticfiles/;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /admin/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/rbna-portal /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

# ============================================
# ЭТАП 6: SSL сертификат
# ============================================

print_step "13" "Установка SSL сертификата..."

if command -v certbot &> /dev/null; then
    apt-get install -y -qq certbot python3-certbot-nginx
    certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN --redirect || {
        print_info "SSL не установлен автоматически. Выполните: certbot --nginx -d $DOMAIN"
    }
else
    apt-get install -y -qq certbot python3-certbot-nginx
    certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN --redirect || {
        print_info "SSL не установлен автоматически. Выполните: certbot --nginx -d $DOMAIN"
    }
fi

# ============================================
# ФИНАЛ
# ============================================

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Развертывание завершено!${NC}"
echo "=========================================="
echo ""
echo "🌐 Приложение доступно:"
echo "   https://$DOMAIN"
echo ""
echo "🔐 Админка Django:"
echo "   https://$DOMAIN/admin/"
echo ""
echo "📊 Проверка статуса:"
echo "   systemctl status rbna-portal"
echo ""
echo "📝 Учетные данные БД:"
echo "   /home/rbna/rbna-portal/credentials.txt"
echo ""
echo "⚠️  ВАЖНО:"
echo "   1. Создайте суперпользователя Django:"
echo "      su - rbna"
echo "      cd /home/rbna/rbna-portal/backend"
echo "      source venv/bin/activate"
echo "      python manage.py createsuperuser"
echo ""
echo "   2. Загрузите демо-данные (опционально):"
echo "      python manage.py seed_data"
echo ""
