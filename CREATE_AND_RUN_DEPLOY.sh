#!/bin/bash
# Команда для создания и запуска скрипта развертывания на сервере
# Скопируйте и выполните эту команду на сервере

cat > /root/deploy_rbna.sh << 'DEPLOYSCRIPT'
#!/bin/bash
set -e

DOMAIN="151.245.137.147"
GIT_REPO="https://github.com/shirokovmv1/RBNA-portal.git"

echo "🚀 Развертывание RBNA Portal на $DOMAIN"
echo "========================================"

if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  Запустите скрипт с sudo или от root"
    exit 1
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${GREEN}[ШАГ $1]${NC} $2"
}

DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

print_step "1" "Обновление системы..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq

print_step "2" "Установка зависимостей..."
apt-get install -y -qq python3 python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib nginx git build-essential \
    libssl-dev libffi-dev ufw curl wget openssl

print_step "3" "Установка Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
apt-get install -y -qq nodejs

print_step "4" "Создание пользователя rbna..."
if ! id "rbna" &>/dev/null; then
    adduser --disabled-password --gecos "" rbna
    usermod -aG sudo rbna
    echo "rbna ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
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

cat > /home/rbna/rbna-portal/credentials.txt <<CREDEOF
===========================================
RBNA Portal - Учетные данные
===========================================

База данных:
  Имя БД: rbna_portal
  Пользователь: rbna_user
  Пароль: $DB_PASSWORD

===========================================
CREDEOF
chown rbna:rbna /home/rbna/rbna-portal/credentials.txt
chmod 600 /home/rbna/rbna-portal/credentials.txt

print_step "8" "Клонирование проекта из Git..."
su - rbna <<RBNA_EOF
cd /home/rbna
if [ -d "rbna-portal" ]; then
    if [ -d "rbna-portal/.git" ]; then
        cd rbna-portal
        git pull
    else
        rm -rf rbna-portal
        git clone $GIT_REPO rbna-portal
    fi
else
    git clone $GIT_REPO rbna-portal
fi
RBNA_EOF

if [ ! -d "/home/rbna/rbna-portal/backend" ] || [ ! -d "/home/rbna/rbna-portal/frontend" ]; then
    echo "❌ Ошибка: Проект не найден после клонирования!"
    exit 1
fi

print_step "9" "Настройка Backend..."

su - rbna <<RBNA_EOF
cd /home/rbna/rbna-portal/backend

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate

pip install --upgrade pip -q
pip install -r requirements.txt -q
pip install gunicorn psycopg2-binary -q

SECRET_KEY=\$(python manage.py shell -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")

cat > .env <<ENVEOF
SECRET_KEY=\$SECRET_KEY
DEBUG=False
ALLOWED_HOSTS=$DOMAIN,151.245.137.147
CORS_ALLOWED_ORIGINS=http://$DOMAIN,https://$DOMAIN
SECURE_SSL_REDIRECT=False
DB_NAME=rbna_portal
DB_USER=rbna_user
DB_PASSWORD=$DB_PASSWORD
DB_HOST=localhost
DB_PORT=5432
ENVEOF

python3 << 'PYEOF'
import re
import os

with open('rbnaportal/settings.py', 'r') as f:
    content = f.read()

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

python manage.py migrate --noinput
python manage.py collectstatic --noinput

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

print_step "11" "Сборка Frontend..."

su - rbna <<RBNA_EOF
cd /home/rbna/rbna-portal/frontend

cat > .env.production <<ENVEOF
REACT_APP_API_URL=http://$DOMAIN/api
ENVEOF

npm install --legacy-peer-deps --silent
npm run build
RBNA_EOF

print_step "12" "Настройка Nginx..."

tee /etc/nginx/sites-available/rbna-portal > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

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
        proxy_redirect off;
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

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Развертывание завершено!${NC}"
echo "=========================================="
echo ""
echo "🌐 Приложение доступно:"
echo "   http://$DOMAIN"
echo ""
echo "🔐 Админка Django:"
echo "   http://$DOMAIN/admin/"
echo ""
echo "📝 Учетные данные БД:"
echo "   /home/rbna/rbna-portal/credentials.txt"
echo ""
echo "📊 Создайте суперпользователя:"
echo "   sudo -u rbna bash -c 'cd /home/rbna/rbna-portal/backend && source venv/bin/activate && python manage.py createsuperuser'"
echo ""
echo "📦 Загрузите демо-данные:"
echo "   sudo -u rbna bash -c 'cd /home/rbna/rbna-portal/backend && source venv/bin/activate && python manage.py seed_data'"
echo ""
DEPLOYSCRIPT

chmod +x /root/deploy_rbna.sh
echo "✅ Скрипт создан: /root/deploy_rbna.sh"
echo ""
echo "Запуск развертывания..."
/root/deploy_rbna.sh
