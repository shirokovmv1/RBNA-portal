#!/bin/bash
# Скрипт автоматического деплоя с бэкапом и версионностью

set -e

PROJECT_DIR="/home/rbna/rbna-portal"
BACKUP_DIR="/home/rbna/backups"
VERSIONS_DIR="/home/rbna/versions"
LOG_FILE="$PROJECT_DIR/logs/deploy.log"
MAX_VERSIONS=2

# Функция логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Создание директорий
mkdir -p "$BACKUP_DIR"
mkdir -p "$VERSIONS_DIR"
mkdir -p "$PROJECT_DIR/logs"

log "🚀 Начало деплоя RBNA Portal"

# 1. Создание бэкапа текущей версии
log "📦 Создание бэкапа текущей версии..."
BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

mkdir -p "$BACKUP_PATH"

# Бэкап базы данных
log "💾 Бэкап базы данных..."
cd "$PROJECT_DIR/backend"
source venv/bin/activate
python manage.py dumpdata --exclude=contenttypes --exclude=auth.Permission > "$BACKUP_PATH/database.json" 2>/dev/null || log "⚠️  Не удалось создать бэкап БД"

# Бэкап файлов проекта
log "📁 Бэкап файлов проекта..."
tar -czf "$BACKUP_PATH/files.tar.gz" \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='venv' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='staticfiles' \
    -C "$PROJECT_DIR" . 2>/dev/null || log "⚠️  Ошибка при создании архива"

# Бэкап статических файлов
if [ -d "$PROJECT_DIR/backend/staticfiles" ]; then
    tar -czf "$BACKUP_PATH/staticfiles.tar.gz" -C "$PROJECT_DIR/backend" staticfiles
fi

log "✅ Бэкап создан: $BACKUP_PATH"

# 2. Сохранение версии (с ограничением до 2 последних)
log "📌 Сохранение версии..."
VERSION_NAME="version_$(date +%Y%m%d_%H%M%S)"
VERSION_PATH="$VERSIONS_DIR/$VERSION_NAME"

mkdir -p "$VERSION_PATH"
cp -r "$PROJECT_DIR" "$VERSION_PATH/" --exclude='.git' --exclude='node_modules' --exclude='venv' 2>/dev/null || \
rsync -av --exclude='.git' --exclude='node_modules' --exclude='venv' --exclude='__pycache__' "$PROJECT_DIR/" "$VERSION_PATH/"

log "✅ Версия сохранена: $VERSION_NAME"

# Удаление старых версий (оставляем только 2 последние)
log "🧹 Очистка старых версий..."
cd "$VERSIONS_DIR"
ls -t | tail -n +$((MAX_VERSIONS + 1)) | xargs rm -rf 2>/dev/null || true
log "✅ Старые версии удалены (оставлено $MAX_VERSIONS последних)"

# Удаление старых бэкапов (оставляем последние 10)
log "🧹 Очистка старых бэкапов..."
cd "$BACKUP_DIR"
ls -t | tail -n +11 | xargs rm -rf 2>/dev/null || true
log "✅ Старые бэкапы удалены (оставлено 10 последних)"

# 3. Обновление кода из GitHub
log "🔄 Обновление кода из GitHub..."
cd "$PROJECT_DIR"

# Проверка наличия remote
if ! git remote get-url origin &>/dev/null; then
    log "⚠️  GitHub remote не настроен. Пропуск обновления кода."
    log "💡 Настройте remote: git remote add origin <your-repo-url>"
else
    git fetch origin
    CURRENT_BRANCH=$(git branch --show-current || echo "main")
    git reset --hard "origin/$CURRENT_BRANCH" || git reset --hard "origin/main" || git reset --hard "origin/master"
    log "✅ Код обновлен из GitHub"
fi

# 4. Обновление зависимостей backend
log "📦 Обновление зависимостей backend..."
cd "$PROJECT_DIR/backend"
source venv/bin/activate
pip install -q -r requirements.txt
log "✅ Зависимости backend обновлены"

# 5. Применение миграций
log "🗄️  Применение миграций базы данных..."
python manage.py migrate --noinput
log "✅ Миграции применены"

# 6. Сбор статических файлов
log "📦 Сбор статических файлов..."
python manage.py collectstatic --noinput --clear
log "✅ Статические файлы собраны"

# 7. Перезапуск сервиса
log "🔄 Перезапуск сервиса..."
sudo systemctl restart rbna-portal
sleep 3

# Проверка статуса
if systemctl is-active --quiet rbna-portal; then
    log "✅ Сервис успешно перезапущен"
else
    log "❌ ОШИБКА: Сервис не запустился!"
    log "📋 Последние логи сервиса:"
    journalctl -u rbna-portal -n 20 --no-pager | tail -20
    exit 1
fi

log "🎉 Деплой успешно завершен!"
log "📊 Версия: $VERSION_NAME"
log "💾 Бэкап: $BACKUP_NAME"
