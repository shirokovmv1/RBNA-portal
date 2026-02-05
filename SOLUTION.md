# 🔧 Решение ошибки развертывания

## Проблема

Скрипт `deploy_to_151.245.137.147.sh` не найден в репозитории, потому что он был создан локально и не закоммичен в Git.

## ✅ Решение - Выполните на сервере:

### Вариант 1: Использовать deploy_complete.sh (если есть в репозитории)

**На сервере выполните:**

```bash
cd /root/rbna-temp

# Проверьте, какие скрипты есть
ls -la *.sh

# Если есть deploy_complete.sh, используйте его:
chmod +x deploy_complete.sh
./deploy_complete.sh 151.245.137.147 https://github.com/shirokovmv1/RBNA-portal.git
```

### Вариант 2: Создать скрипт прямо на сервере

**Выполните эту команду на сервере (скопируйте полностью):**

```bash
cat > /root/deploy.sh << 'DEPLOY_END'
#!/bin/bash
set -e
DOMAIN="151.245.137.147"
GIT_REPO="https://github.com/shirokovmv1/RBNA-portal.git"
echo "🚀 Развертывание RBNA Portal на $DOMAIN"
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  Запустите с sudo"
    exit 1
fi
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get upgrade -y -qq
apt-get install -y -qq python3 python3-pip python3-venv python3-dev postgresql postgresql-contrib nginx git build-essential libssl-dev libffi-dev ufw curl wget openssl
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
apt-get install -y -qq nodejs
if ! id "rbna" &>/dev/null; then
    adduser --disabled-password --gecos "" rbna
    usermod -aG sudo rbna
    echo "rbna ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi
systemctl start postgresql > /dev/null 2>&1
systemctl enable postgresql > /dev/null 2>&1
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
sudo -u postgres psql <<EOF > /dev/null 2>&1
SELECT 'CREATE DATABASE rbna_portal' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'rbna_portal')\gexec
DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'rbna_user') THEN CREATE USER rbna_user WITH PASSWORD '$DB_PASSWORD'; END IF; END \$\$;
ALTER ROLE rbna_user SET client_encoding TO 'utf8';
ALTER ROLE rbna_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE rbna_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE rbna_portal TO rbna_user;
\q
EOF
ufw --force enable > /dev/null 2>&1
ufw allow 22/tcp > /dev/null 2>&1
ufw allow 80/tcp > /dev/null 2>&1
ufw allow 443/tcp > /dev/null 2>&1
mkdir -p /home/rbna/rbna-portal/{backend,frontend,logs}
chown -R rbna:rbna /home/rbna/rbna-portal
su - rbna <<RBNA_EOF
cd /home/rbna/rbna-portal
git clone $GIT_REPO .
cd backend
python3 -m venv venv
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
cd ../frontend
cat > .env.production <<ENVEOF
REACT_APP_API_URL=http://$DOMAIN/api
ENVEOF
npm install --legacy-peer-deps --silent
npm run build
RBNA_EOF
tee /etc/systemd/system/rbna-portal.service > /dev/null <<EOF
[Unit]
Description=RBNA Portal Gunicorn daemon
After=network.target postgresql.service
[Service]
User=rbna
Group=rbna
WorkingDirectory=/home/rbna/rbna-portal/backend
Environment="PATH=/home/rbna/rbna-portal/backend/venv/bin"
ExecStart=/home/rbna/rbna-portal/backend/venv/bin/gunicorn --config /home/rbna/rbna-portal/backend/gunicorn_config.py rbnaportal.wsgi:application
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable rbna-portal
systemctl start rbna-portal
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
echo "✅ Развертывание завершено!"
echo "Приложение доступно: http://$DOMAIN"
DEPLOY_END

chmod +x /root/deploy.sh
/root/deploy.sh
```

### Вариант 3: Загрузить скрипт через SCP

**На вашем локальном компьютере:**

```bash
scp deploy_to_151.245.137.147.sh root@151.245.137.147:/root/
```

**Затем на сервере:**

```bash
chmod +x /root/deploy_to_151.245.137.147.sh
/root/deploy_to_151.245.137.147.sh
```

---

## 🎯 Рекомендуемый способ

**На сервере выполните:**

```bash
cd /root/rbna-temp
ls -la deploy*.sh
```

Если увидите `deploy_complete.sh`, используйте его:

```bash
chmod +x deploy_complete.sh
./deploy_complete.sh 151.245.137.147 https://github.com/shirokovmv1/RBNA-portal.git
```

Если нет - используйте Вариант 2 выше (создать скрипт на сервере).
