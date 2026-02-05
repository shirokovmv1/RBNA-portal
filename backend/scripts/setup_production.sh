#!/bin/bash
# Скрипт для настройки production окружения

set -e

echo "🚀 Настройка Production окружения для RBNA Portal"
echo ""

# Шаг 1: Создание .env файла
echo "📝 Шаг 1: Создание .env файла..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ .env файл создан из шаблона"
    
    # Генерация SECRET_KEY
    echo ""
    echo "🔑 Генерация нового SECRET_KEY..."
    SECRET_KEY=$(python manage.py shell -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")
    
    # Замена SECRET_KEY в .env
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/SECRET_KEY=.*/SECRET_KEY=$SECRET_KEY/" .env
    else
        # Linux
        sed -i "s/SECRET_KEY=.*/SECRET_KEY=$SECRET_KEY/" .env
    fi
    
    echo "✅ SECRET_KEY сгенерирован и добавлен в .env"
    echo ""
    echo "⚠️  ВАЖНО: Отредактируйте .env файл и установите:"
    echo "   - DEBUG=False"
    echo "   - ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com"
    echo "   - CORS_ALLOWED_ORIGINS=https://yourdomain.com"
else
    echo "⚠️  .env файл уже существует, пропускаем создание"
fi

# Шаг 2: Установка зависимостей
echo ""
echo "📦 Шаг 2: Установка зависимостей..."
pip install -q djangorestframework-simplejwt
echo "✅ djangorestframework-simplejwt установлен"

# Шаг 3: Проверка настроек
echo ""
echo "🔍 Шаг 3: Проверка настроек Django..."
python manage.py check --deploy || echo "⚠️  Есть предупреждения, но это нормально для первого запуска"

# Шаг 4: Миграции
echo ""
echo "🗄️  Шаг 4: Применение миграций..."
python manage.py migrate

# Шаг 5: Сбор статических файлов
echo ""
echo "📁 Шаг 5: Сбор статических файлов..."
python manage.py collectstatic --noinput

echo ""
echo "✅ Базовая настройка завершена!"
echo ""
echo "📋 Следующие шаги:"
echo "   1. Отредактируйте .env файл с production значениями"
echo "   2. Замените AllowAny на IsAuthenticated в api/views.py"
echo "   3. Настройте JWT в settings.py (см. PRODUCTION_STEP_BY_STEP.md)"
echo "   4. Настройте HTTPS и SSL сертификат"
echo ""
echo "📚 Подробные инструкции: PRODUCTION_STEP_BY_STEP.md"
