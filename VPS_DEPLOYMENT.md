# Развертывание RBNA Portal на VPS сервере

## 📋 Предварительные требования

- VPS сервер с Ubuntu 20.04+ или Debian 11+
- Root доступ или пользователь с sudo правами
- Доменное имя (опционально, но рекомендуется)
- Минимум 2GB RAM, 20GB диска

---

## 🚀 Шаг 1: Подготовка сервера

### 1.1. Подключение к серверу

```bash
ssh root@your-server-ip
# или
ssh your-username@your-server-ip
```

### 1.2. Обновление системы

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### 1.3. Создание пользователя для приложения (рекомендуется)

```bash
# Создать пользователя
sudo adduser rbna
sudo usermod -aG sudo rbna

# Переключиться на нового пользователя
su - rbna
```

---

## 🐍 Шаг 2: Установка Python и зависимостей

### 2.1. Установка Python 3.10+

```bash
sudo apt-get install -y python3 python3-pip python3-venv python3-dev
sudo apt-get install -y build-essential libssl-dev libffi-dev
```

### 2.2. Установка PostgreSQL

```bash
sudo apt-get install -y postgresql postgresql-contrib

# Запустить PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Создать базу данных и пользователя
sudo -u postgres psql

# В PostgreSQL shell:
CREATE DATABASE rbna_portal;
CREATE USER rbna_user WITH PASSWORD 'your_secure_password_here';
ALTER ROLE rbna_user SET client_encoding TO 'utf8';
ALTER ROLE rbna_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE rbna_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE rbna_portal TO rbna_user;
\q
```

**Запомните пароль базы данных!**

### 2.3. Установка Nginx

```bash
sudo apt-get install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 2.4. Установка Node.js (для сборки frontend)

```bash
# Установка Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Проверка
node --version
npm --version
```

---

## 📦 Шаг 3: Развертывание Backend

### 3.1. Клонирование проекта (или загрузка файлов)

**Вариант A: Git (если проект в репозитории)**

```bash
cd /home/rbna
git clone https://github.com/your-username/RBNA-portal.git
cd RBNA-portal
```

**Вариант B: Загрузка файлов через SCP**

На вашем локальном компьютере:
```bash
scp -r backend/ rbna@your-server-ip:/home/rbna/rbna-portal/
```

### 3.2. Настройка виртуального окружения

```bash
cd /home/rbna/rbna-portal/backend
python3 -m venv venv
source venv/bin/activate
```

### 3.3. Установка зависимостей

```bash
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn psycopg2-binary
```

### 3.4. Создание .env файла

```bash
cd /home/rbna/rbna-portal/backend
cp .env.example .env
nano .env
```

**Заполните .env:**

```env
SECRET_KEY=your-generated-secret-key-here
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,your-server-ip
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
SECURE_SSL_REDIRECT=True

# PostgreSQL настройки
DB_NAME=rbna_portal
DB_USER=rbna_user
DB_PASSWORD=your_secure_password_here
DB_HOST=localhost
DB_PORT=5432
```

**Сгенерируйте SECRET_KEY:**
```bash
python manage.py shell
# В shell:
from django.core.management.utils import get_random_secret_key
print(get_random_secret_key())
exit()
```

### 3.5. Настройка settings.py для PostgreSQL

Откройте `backend/rbnaportal/settings.py` и найдите секцию DATABASES:

```python
# Замените SQLite настройки на:
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'rbna_portal'),
        'USER': os.environ.get('DB_USER', 'rbna_user'),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}
```

Или добавьте в `.env` и используйте:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME'),
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}
```

### 3.6. Применение миграций и загрузка данных

```bash
cd /home/rbna/rbna-portal/backend
source venv/bin/activate

# Применить миграции
python manage.py migrate

# Загрузить демо-данные (опционально)
python manage.py seed_data

# Создать суперпользователя
python manage.py createsuperuser

# Собрать статические файлы
python manage.py collectstatic --noinput
```

### 3.7. Настройка Gunicorn

Создайте файл `backend/gunicorn_config.py`:

```python
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
```

Создайте директорию для логов:

```bash
mkdir -p /home/rbna/rbna-portal/logs
```

### 3.8. Создание systemd сервиса

Создайте файл `/etc/systemd/system/rbna-portal.service`:

```bash
sudo nano /etc/systemd/system/rbna-portal.service
```

**Содержимое:**

```ini
[Unit]
Description=RBNA Portal Gunicorn daemon
After=network.target postgresql.service

[Service]
User=rbna
Group=rbna
WorkingDirectory=/home/rbna/rbna-portal/backend
Environment="PATH=/home/rbna/rbna-portal/backend/venv/bin"
ExecStart=/home/rbna/rbna-portal/backend/venv/bin/gunicorn \
    --config /home/rbna/rbna-portal/backend/gunicorn_config.py \
    rbnaportal.wsgi:application
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

**Активируйте и запустите:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable rbna-portal
sudo systemctl start rbna-portal
sudo systemctl status rbna-portal
```

---

## ⚛️ Шаг 4: Развертывание Frontend

### 4.1. Сборка frontend на сервере

```bash
cd /home/rbna/rbna-portal/frontend

# Установить зависимости
npm install --legacy-peer-deps

# Собрать production версию
npm run build
```

### 4.2. Настройка переменных окружения frontend

Создайте файл `frontend/.env.production`:

```env
REACT_APP_API_URL=https://yourdomain.com/api
```

Пересоберите:

```bash
npm run build
```

---

## 🌐 Шаг 5: Настройка Nginx

### 5.1. Создание конфигурации Nginx

Создайте файл `/etc/nginx/sites-available/rbna-portal`:

```bash
sudo nano /etc/nginx/sites-available/rbna-portal
```

**Содержимое:**

```nginx
# Редирект HTTP на HTTPS
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    # Для Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS сервер
server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # SSL сертификаты (будут настроены certbot)
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Максимальный размер загружаемых файлов
    client_max_body_size 10M;

    # Статические файлы frontend
    location / {
        root /home/rbna/rbna-portal/frontend/build;
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # Статические файлы Django
    location /static/ {
        alias /home/rbna/rbna-portal/backend/staticfiles/;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # Медиа файлы (если будут)
    location /media/ {
        alias /home/rbna/rbna-portal/backend/media/;
    }

    # API проксирование на Gunicorn
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }

    # Админка Django
    location /admin/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 5.2. Активация конфигурации

```bash
# Создать символическую ссылку
sudo ln -s /etc/nginx/sites-available/rbna-portal /etc/nginx/sites-enabled/

# Удалить дефолтную конфигурацию (опционально)
sudo rm /etc/nginx/sites-enabled/default

# Проверить конфигурацию
sudo nginx -t

# Перезагрузить Nginx
sudo systemctl reload nginx
```

---

## 🔒 Шаг 6: Настройка SSL (Let's Encrypt)

### 6.1. Установка Certbot

```bash
sudo apt-get install -y certbot python3-certbot-nginx
```

### 6.2. Получение SSL сертификата

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Следуйте инструкциям на экране. Certbot автоматически:
- Получит сертификат
- Настроит Nginx
- Настроит автоматическое обновление

### 6.3. Проверка автоматического обновления

```bash
sudo certbot renew --dry-run
```

---

## 🔧 Шаг 7: Финальная настройка

### 7.1. Настройка файрвола

```bash
# Установить UFW (если не установлен)
sudo apt-get install -y ufw

# Разрешить SSH
sudo ufw allow 22/tcp

# Разрешить HTTP и HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Включить файрвол
sudo ufw enable
sudo ufw status
```

### 7.2. Настройка логирования

Создайте ротацию логов. Создайте файл `/etc/logrotate.d/rbna-portal`:

```bash
sudo nano /etc/logrotate.d/rbna-portal
```

**Содержимое:**

```
/home/rbna/rbna-portal/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 rbna rbna
    sharedscripts
    postrotate
        systemctl reload rbna-portal > /dev/null 2>&1 || true
    endscript
}
```

### 7.3. Проверка работы всех сервисов

```bash
# Проверить статус всех сервисов
sudo systemctl status rbna-portal
sudo systemctl status nginx
sudo systemctl status postgresql

# Проверить логи
sudo journalctl -u rbna-portal -f
sudo tail -f /home/rbna/rbna-portal/logs/gunicorn.log
sudo tail -f /var/log/nginx/error.log
```

---

## ✅ Шаг 8: Проверка развертывания

### 8.1. Проверка backend API

```bash
curl http://localhost:8000/api/users/
```

### 8.2. Проверка через браузер

Откройте в браузере:
- `https://yourdomain.com` - должен открыться frontend
- `https://yourdomain.com/api/users/` - должен вернуть JSON
- `https://yourdomain.com/admin/` - админка Django

---

## 🔄 Шаг 9: Обновление приложения

### 9.1. Скрипт для обновления

Создайте файл `/home/rbna/rbna-portal/update.sh`:

```bash
#!/bin/bash
set -e

echo "🔄 Обновление RBNA Portal..."

cd /home/rbna/rbna-portal

# Обновить код (если используется Git)
# git pull

# Backend
cd backend
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart rbna-portal

# Frontend
cd ../frontend
npm install --legacy-peer-deps
npm run build

# Перезагрузить Nginx
sudo systemctl reload nginx

echo "✅ Обновление завершено!"
```

Сделайте исполняемым:

```bash
chmod +x /home/rbna/rbna-portal/update.sh
```

---

## 📊 Мониторинг

### Просмотр логов

```bash
# Логи приложения
sudo journalctl -u rbna-portal -f

# Логи Gunicorn
tail -f /home/rbna/rbna-portal/logs/gunicorn.log

# Логи Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Логи PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### Проверка использования ресурсов

```bash
# Использование памяти и CPU
htop

# Использование диска
df -h

# Использование памяти PostgreSQL
sudo -u postgres psql -c "SELECT pg_size_pretty(pg_database_size('rbna_portal'));"
```

---

## 🆘 Решение проблем

### Проблема: Приложение не запускается

```bash
# Проверить статус
sudo systemctl status rbna-portal

# Проверить логи
sudo journalctl -u rbna-portal -n 50

# Проверить конфигурацию
cd /home/rbna/rbna-portal/backend
source venv/bin/activate
python manage.py check
```

### Проблема: Nginx возвращает 502 Bad Gateway

```bash
# Проверить, что Gunicorn запущен
sudo systemctl status rbna-portal

# Проверить, что порт 8000 слушается
sudo netstat -tlnp | grep 8000

# Проверить логи Nginx
sudo tail -f /var/log/nginx/error.log
```

### Проблема: База данных не подключается

```bash
# Проверить статус PostgreSQL
sudo systemctl status postgresql

# Проверить подключение
sudo -u postgres psql -d rbna_portal -U rbna_user

# Проверить настройки в .env
cat /home/rbna/rbna-portal/backend/.env | grep DB_
```

---

## 📝 Чеклист развертывания

- [ ] Сервер обновлен
- [ ] Python 3.10+ установлен
- [ ] PostgreSQL установлен и настроен
- [ ] База данных создана
- [ ] Nginx установлен
- [ ] Node.js установлен
- [ ] Проект загружен на сервер
- [ ] Виртуальное окружение создано
- [ ] Зависимости установлены
- [ ] .env файл создан и заполнен
- [ ] settings.py настроен для PostgreSQL
- [ ] Миграции применены
- [ ] Статические файлы собраны
- [ ] Gunicorn настроен
- [ ] Systemd сервис создан и запущен
- [ ] Frontend собран
- [ ] Nginx настроен
- [ ] SSL сертификат установлен
- [ ] Файрвол настроен
- [ ] Логирование настроено
- [ ] Все сервисы работают
- [ ] Приложение доступно по HTTPS

---

## 🎉 Готово!

Ваше приложение развернуто и доступно по адресу:
**https://yourdomain.com**

Для входа в админку:
**https://yourdomain.com/admin/**

---

## 📚 Дополнительные ресурсы

- [Django Deployment Checklist](https://docs.djangoproject.com/en/4.2/howto/deployment/checklist/)
- [Gunicorn Documentation](https://docs.gunicorn.org/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
