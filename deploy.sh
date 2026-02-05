#!/bin/bash
# Скрипт автоматического развертывания RBNA Portal на VPS
# Использование: ./deploy.sh yourdomain.com

set -e

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
    echo "❌ Ошибка: Укажите домен"
    echo "Использование: ./deploy.sh yourdomain.com"
    exit 1
fi

echo "🚀 Начало развертывания RBNA Portal на $DOMAIN"
echo ""

# Проверка прав root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  Запустите скрипт с sudo или от root"
    exit 1
fi

# Обновление системы
echo "📦 Обновление системы..."
apt-get update
apt-get upgrade -y

# Установка базовых пакетов
echo "📦 Установка зависимостей..."
apt-get install -y python3 python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib nginx git build-essential \
    libssl-dev libffi-dev ufw

# Установка Node.js
echo "📦 Установка Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Создание пользователя
if ! id "rbna" &>/dev/null; then
    echo "👤 Создание пользователя rbna..."
    adduser --disabled-password --gecos "" rbna
    usermod -aG sudo rbna
else
    echo "✅ Пользователь rbna уже существует"
fi

# Настройка PostgreSQL
echo "🗄️  Настройка PostgreSQL..."
sudo -u postgres psql <<EOF
-- Создать базу данных если не существует
SELECT 'CREATE DATABASE rbna_portal'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'rbna_portal')\gexec

-- Создать пользователя если не существует
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'rbna_user') THEN
        CREATE USER rbna_user WITH PASSWORD 'rbna_secure_password_123';
    END IF;
END
\$\$;

-- Настроить права
ALTER ROLE rbna_user SET client_encoding TO 'utf8';
ALTER ROLE rbna_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE rbna_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE rbna_portal TO rbna_user;
\q
EOF

echo "✅ PostgreSQL настроен"
echo "⚠️  ВАЖНО: Измените пароль БД вручную!"

# Настройка файрвола
echo "🔥 Настройка файрвола..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Создание директорий
echo "📁 Создание директорий..."
mkdir -p /home/rbna/rbna-portal/logs
chown -R rbna:rbna /home/rbna/rbna-portal

echo ""
echo "✅ Базовая настройка сервера завершена!"
echo ""
echo "📋 Следующие шаги:"
echo "   1. Загрузите проект на сервер:"
echo "      scp -r backend/ frontend/ rbna@$DOMAIN:/home/rbna/rbna-portal/"
echo ""
echo "   2. Подключитесь к серверу:"
echo "      ssh rbna@$DOMAIN"
echo ""
echo "   3. Следуйте инструкциям в VPS_DEPLOYMENT.md"
echo ""
echo "   4. Или выполните вручную:"
echo "      cd /home/rbna/rbna-portal/backend"
echo "      python3 -m venv venv"
echo "      source venv/bin/activate"
echo "      pip install -r requirements.txt gunicorn psycopg2-binary"
echo "      cp .env.example .env"
echo "      # Отредактируйте .env"
echo "      python manage.py migrate"
echo "      python manage.py collectstatic --noinput"
echo ""
echo "📚 Подробные инструкции: VPS_DEPLOYMENT.md"
