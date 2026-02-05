#!/bin/bash
# Скрипт ручного бэкапа

set -e

PROJECT_DIR="/home/rbna/rbna-portal"
BACKUP_DIR="/home/rbna/backups"
LOG_FILE="$PROJECT_DIR/logs/backup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

mkdir -p "$BACKUP_DIR"
mkdir -p "$PROJECT_DIR/logs"

BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

log "📦 Создание бэкапа: $BACKUP_NAME"
mkdir -p "$BACKUP_PATH"

# Бэкап базы данных
log "💾 Бэкап базы данных..."
cd "$PROJECT_DIR/backend"
source venv/bin/activate
python manage.py dumpdata --exclude=contenttypes --exclude=auth.Permission > "$BACKUP_PATH/database.json" 2>/dev/null || log "⚠️  Не удалось создать бэкап БД"

# Бэкап файлов
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
du -sh "$BACKUP_PATH"
