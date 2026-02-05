#!/bin/bash
# Скрипт установки TCPDF для BSO Portal

echo "=========================================="
echo "Установка TCPDF для BSO Portal"
echo "=========================================="

cd "$(dirname "$0")"

# Проверка наличия PHP
if ! command -v php &> /dev/null; then
    echo "❌ Ошибка: PHP не найден. Установите PHP 7.0 или выше."
    exit 1
fi

echo "✅ PHP найден: $(php -v | head -n 1)"

# Вариант 1: Установка через Composer (рекомендуется)
if command -v composer &> /dev/null; then
    echo ""
    echo "📦 Установка через Composer..."
    composer require tecnickcom/tcpdf
    if [ $? -eq 0 ]; then
        echo "✅ TCPDF успешно установлен через Composer"
        echo "📁 Путь: vendor/tecnickcom/tcpdf/tcpdf.php"
        exit 0
    fi
fi

# Вариант 2: Установка Composer локально
if [ ! -f "composer.phar" ]; then
    echo ""
    echo "📥 Загрузка Composer..."
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --quiet
    php -r "unlink('composer-setup.php');"
fi

if [ -f "composer.phar" ]; then
    echo ""
    echo "📦 Установка TCPDF через локальный Composer..."
    php composer.phar require tecnickcom/tcpdf --no-interaction
    if [ $? -eq 0 ]; then
        echo "✅ TCPDF успешно установлен"
        echo "📁 Путь: vendor/tecnickcom/tcpdf/tcpdf.php"
        exit 0
    fi
fi

# Вариант 3: Ручная установка
echo ""
echo "📥 Ручная установка TCPDF..."
TCPDF_VERSION="6.6.5"
TCPDF_URL="https://github.com/tecnickcom/TCPDF/archive/refs/tags/${TCPDF_VERSION}.tar.gz"

if command -v wget &> /dev/null; then
    wget -q "${TCPDF_URL}" -O tcpdf.tar.gz
elif command -v curl &> /dev/null; then
    curl -L -s "${TCPDF_URL}" -o tcpdf.tar.gz
else
    echo "❌ Ошибка: wget или curl не найдены. Установите один из них."
    exit 1
fi

if [ -f "tcpdf.tar.gz" ]; then
    tar -xzf tcpdf.tar.gz
    mv "TCPDF-${TCPDF_VERSION}" tcpdf
    rm tcpdf.tar.gz
    
    if [ -f "tcpdf/tcpdf.php" ]; then
        echo "✅ TCPDF успешно установлен вручную"
        echo "📁 Путь: tcpdf/tcpdf.php"
        exit 0
    else
        echo "❌ Ошибка: TCPDF не найден после распаковки"
        exit 1
    fi
else
    echo "❌ Ошибка: Не удалось скачать TCPDF"
    exit 1
fi
