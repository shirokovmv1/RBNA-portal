#!/bin/bash
# Полный автоматический скрипт развертывания RBNA Portal на VPS
# Использование: ./deploy_full.sh yourdomain.com

set -e

DOMAIN=$1
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
SECRET_KEY=""

if [ -z "$DOMAIN" ]; then
    echo "❌ Ошибка: Укажите домен"
    echo "Использование: ./deploy_full.sh yourdomain.com"
    exit 1
fi

echo "🚀 Автоматическое развертывание RBNA Portal на $DOMAIN"
echo "=================================================="
echo ""

# Проверка прав root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  Запустите скрипт с sudo"
    exit 1
fi

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода прогресса
print_step() {
    echo -e "${GREEN}[ШАГ $1]${NC} $2"
}

# Функция для генерации SECRET_KEY
generate_secret_key() {
    python3 << EOF
from django.core.management.utils import get_random_secret_key
print(get_random_secret_key())
EOF
}

# ШАГ 1: Обновление системы
print_step "1" "Обновление системы..."
apt-get update -qq
apt-get upgrade -y -qq

# ШАГ 2: Установка базовых пакетов
print_step "2" "Установка зависимостей..."
apt-get install -y -qq python3 python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib nginx git build-essential \
    libssl-dev libffi-dev ufw curl wget

# Установка Node.js
print_step "2.1" "Установка Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
apt-get install -y -qq nodejs

# ШАГ 3: Создание пользователя
print_step "3" "Создание пользователя rbna..."
if ! id "rbna" &>/dev/null; then
    adduser --disabled-password --gecos "" rbna
    usermod -aG sudo rbna
    echo "✅ Пользователь rbna создан"
else
    echo "✅ Пользователь rbna уже существует"
fi

# ШАГ 4: Настройка PostgreSQL
print_step "4" "Настройка PostgreSQL..."
systemctl start postgresql
systemctl enable postgresql

sudo -u postgres psql <<EOF > /dev/null 2>&1
-- Создать базу данных если не существует
SELECT 'CREATE DATABASE rbna_portal'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'rbna_portal')\gexec

-- Создать пользователя если не существует
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'rbna_user') THEN
        CREATE USER rbna_user WITH PASSWORD '$DB_PASSWORD';
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

echo "✅ База данных создана"
echo "   Пароль БД: $DB_PASSWORD (сохраните его!)"

# ШАГ 5: Настройка файрвола
print_step "5" "Настройка файрвола..."
ufw --force enable > /dev/null 2>&1
ufw allow 22/tcp > /dev/null 2>&1
ufw allow 80/tcp > /dev/null 2>&1
ufw allow 443/tcp > /dev/null 2>&1
echo "✅ Файрвол настроен"

# ШАГ 6: Создание директорий
print_step "6" "Создание структуры директорий..."
mkdir -p /home/rbna/rbna-portal/{backend,frontend,logs}
chown -R rbna:rbna /home/rbna/rbna-portal

# ШАГ 7: Копирование проекта (ожидание пользователя)
print_step "7" "Подготовка к загрузке проекта..."
echo ""
echo -e "${YELLOW}⚠️  ВАЖНО:${NC}"
echo "Скрипт подготовил сервер. Теперь нужно:"
echo ""
echo "1. Загрузите проект на сервер:"
echo "   scp -r backend/ frontend/ rbna@$DOMAIN:/home/rbna/rbna-portal/"
echo ""
echo "2. Или клонируйте из Git (если проект в репозитории):"
echo "   ssh rbna@$DOMAIN"
echo "   cd /home/rbna/rbna-portal"
echo "   git clone https://github.com/your-username/RBNA-portal.git ."
echo ""
echo "3. После загрузки проекта запустите:"
echo "   ./deploy_backend.sh"
echo "   ./deploy_frontend.sh"
echo "   ./deploy_nginx.sh $DOMAIN"
echo ""
echo "Или используйте полный скрипт: deploy_application.sh"
echo ""

# Сохранение паролей в файл
cat > /home/rbna/rbna-portal/credentials.txt <<EOF
===========================================
RBNA Portal - Учетные данные
===========================================

База данных:
  Имя БД: rbna_portal
  Пользователь: rbna_user
  Пароль: $DB_PASSWORD

ВАЖНО: Сохраните эти данные в безопасном месте!
После первого входа удалите этот файл:
  rm /home/rbna/rbna-portal/credentials.txt

===========================================
EOF

chown rbna:rbna /home/rbna/rbna-portal/credentials.txt
chmod 600 /home/rbna/rbna-portal/credentials.txt

echo "✅ Учетные данные сохранены в /home/rbna/rbna-portal/credentials.txt"
echo ""
echo "✅ Базовая настройка сервера завершена!"
echo ""
echo "📋 Следующие шаги смотрите выше"
