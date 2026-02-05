#!/bin/bash
# Скрипт восстановления из бэкапа

set -e

BACKUP_DIR="/home/rbna/backups"
PROJECT_DIR="/home/rbna/rbna-portal"
LOG_FILE="$PROJECT_DIR/logs/restore.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ -z "$1" ]; then
    echo "Использование: $0 <backup_name>"
    echo "Доступные бэкапы:"
    ls -1 "$BACKUP_DIR" | grep "^backup_"
    exit 1
fi

BACKUP_NAME="$1"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

if [ ! -d "$BACKUP_PATH" ]; then
    log "❌ Бэкап не найден: $BACKUP_PATH"
    exit 1
fi

log "🔄 Восстановление из бэкапа: $BACKUP_NAME"

# Остановка сервиса
log "⏸️  Остановка сервиса..."
sudo systemctl stop rbna-portal

# Восстановление базы данных
if [ -f "$BACKUP_PATH/database.json" ]; then
    log "💾 Восстановление базы данных..."
    cd "$PROJECT_DIR/backend"
    source venv/bin/activate
    python manage.py loaddata "$BACKUP_PATH/database.json"
    log "✅ База данных восстановлена"
fi

# Восстановление файлов
if [ -f "$BACKUP_PATH/files.tar.gz" ]; then
    log "📁 Восстановление файлов..."
    cd "$PROJECT_DIR"
    tar -xzf "$BACKUP_PATH/files.tar.gz"
    log "✅ Файлы восстановлены"
fi

# Восстановление статических файлов
if [ -f "$BACKUP_PATH/staticfiles.tar.gz" ]; then
    log "📦 Восстановление статических файлов..."
    cd "$PROJECT_DIR/backend"
    tar -xzf "$BACKUP_PATH/staticfiles.tar.gz"
    log "✅ Статические файлы восстановлены"
fi

# Запуск сервиса
log "▶️  Запуск сервиса..."
sudo systemctl start rbna-portal
sleep 3

if systemctl is-active --quiet rbna-portal; then
    log "✅ Сервис успешно запущен"
else
    log "❌ ОШИБКА: Сервис не запустился!"
    exit 1
fi

log "🎉 Восстановление завершено!"
