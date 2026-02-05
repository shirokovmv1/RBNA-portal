# Быстрое развертывание на VPS - Команды

## 🚀 Быстрый старт

### 1. Подготовка сервера

```bash
# Обновление
sudo apt-get update && sudo apt-get upgrade -y

# Установка базовых пакетов
sudo apt-get install -y python3 python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib nginx nodejs git build-essential

# Создание пользователя
sudo adduser rbna
sudo usermod -aG sudo rbna
su - rbna
```

### 2. База данных PostgreSQL

```bash
sudo -u postgres psql
```

```sql
CREATE DATABASE rbna_portal;
CREATE USER rbna_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE rbna_portal TO rbna_user;
\q
```

### 3. Backend

```bash
# Загрузка проекта
cd /home/rbna
git clone https://github.com/your-username/RBNA-portal.git
cd RBNA-portal/backend

# Виртуальное окружение
python3 -m venv venv
source venv/bin/activate

# Зависимости
pip install -r requirements.txt gunicorn psycopg2-binary

# .env файл
cp .env.example .env
nano .env  # Заполните значения

# Миграции
python manage.py migrate
python manage.py collectstatic --noinput
python manage.py createsuperuser
```

### 4. Gunicorn + Systemd

```bash
# Создать gunicorn_config.py
cat > gunicorn_config.py << EOF
bind = "127.0.0.1:8000"
workers = 4
timeout = 120
EOF

# Создать systemd сервис
sudo nano /etc/systemd/system/rbna-portal.service
```

**Содержимое сервиса:**
```ini
[Unit]
Description=RBNA Portal
After=network.target

[Service]
User=rbna
WorkingDirectory=/home/rbna/RBNA-portal/backend
Environment="PATH=/home/rbna/RBNA-portal/backend/venv/bin"
ExecStart=/home/rbna/RBNA-portal/backend/venv/bin/gunicorn --config gunicorn_config.py rbnaportal.wsgi:application
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable rbna-portal
sudo systemctl start rbna-portal
```

### 5. Frontend

```bash
cd /home/rbna/RBNA-portal/frontend
npm install --legacy-peer-deps
npm run build
```

### 6. Nginx

```bash
sudo nano /etc/nginx/sites-available/rbna-portal
```

**Конфигурация:**
```nginx
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    location / {
        root /home/rbna/RBNA-portal/frontend/build;
        try_files $uri /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /home/rbna/RBNA-portal/backend/staticfiles/;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/rbna-portal /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 7. SSL

```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

### 8. Файрвол

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

---

## ✅ Проверка

```bash
# Статус сервисов
sudo systemctl status rbna-portal
sudo systemctl status nginx
sudo systemctl status postgresql

# Логи
sudo journalctl -u rbna-portal -f
```

---

## 🔄 Обновление

```bash
cd /home/rbna/RBNA-portal
git pull
cd backend && source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart rbna-portal
cd ../frontend && npm run build
sudo systemctl reload nginx
```
