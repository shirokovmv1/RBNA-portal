# Руководство по установке TCPDF

## Быстрая установка

### Вариант 1: Автоматическая установка (рекомендуется)

**На Windows (через PowerShell или CMD):**
```powershell
cd api
php install-tcpdf.php
```

**На Linux/Mac:**
```bash
cd api
chmod +x install-tcpdf.sh
./install-tcpdf.sh
```

Или через PHP:
```bash
cd api
php install-tcpdf.php
```

### Вариант 2: Установка через Composer

Если у вас установлен Composer:

```bash
cd api
composer require tecnickcom/tcpdf
```

Или если Composer установлен локально:
```bash
cd api
php composer.phar require tecnickcom/tcpdf
```

### Вариант 3: Ручная установка

1. **Скачайте TCPDF:**
   ```bash
   cd api
   wget https://github.com/tecnickcom/TCPDF/archive/refs/tags/6.6.5.tar.gz
   ```

   Или через браузер:
   - Перейдите: https://github.com/tecnickcom/TCPDF/releases/tag/6.6.5
   - Скачайте архив `TCPDF-6.6.5.tar.gz`

2. **Распакуйте архив:**
   ```bash
   tar -xzf 6.6.5.tar.gz
   mv TCPDF-6.6.5 tcpdf
   rm 6.6.5.tar.gz
   ```

3. **Установите права доступа:**
   ```bash
   chmod -R 755 tcpdf
   ```

## Проверка установки

После установки проверьте:

1. **Проверьте наличие файла:**
   ```bash
   ls -la api/vendor/tecnickcom/tcpdf/tcpdf.php
   # или
   ls -la api/tcpdf/tcpdf.php
   ```

2. **Проверьте через PHP:**
   ```bash
   cd api
   php -r "require 'vendor/tecnickcom/tcpdf/tcpdf.php'; echo 'TCPDF установлен: ' . TCPDF_STATIC::getTCPDFVersion();"
   ```

3. **Протестируйте на портале:**
   - Откройте форму Help Desk
   - Заполните форму
   - Нажмите "Сохранить заявку"
   - Должен скачаться PDF файл

## Устранение проблем

### Ошибка: "TCPDF не найден"

**Решение:**
1. Убедитесь, что TCPDF установлен в правильной директории
2. Проверьте права доступа к файлам
3. Проверьте путь в `api/helpdesk-pdf.php`

### Ошибка: "Class 'TCPDF' not found"

**Решение:**
1. Проверьте, что файл `tcpdf.php` существует
2. Убедитесь, что путь к TCPDF правильный
3. Проверьте версию PHP (требуется PHP 7.0+)

### Ошибка прав доступа

**Решение:**
```bash
# На Linux/Mac
chmod -R 755 api/tcpdf
chown -R www-data:www-data api/tcpdf  # или http:http

# На Windows - проверьте права через свойства папки
```

### Проблемы с Composer

Если Composer не работает:

1. **Установите Composer локально:**
   ```bash
   cd api
   php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
   php composer-setup.php
   php -r "unlink('composer-setup.php');"
   ```

2. **Используйте ручную установку** (см. Вариант 3 выше)

## Структура после установки

После успешной установки структура должна быть такой:

```
api/
├── vendor/
│   └── tecnickcom/
│       └── tcpdf/
│           └── tcpdf.php  ← TCPDF установлен здесь
├── helpdesk-pdf.php
└── ...

# ИЛИ

api/
├── tcpdf/
│   └── tcpdf.php  ← TCPDF установлен здесь
├── helpdesk-pdf.php
└── ...
```

## Настройка для Synology NAS

Если вы разворачиваете на Synology:

1. **Войдите через SSH:**
   ```bash
   ssh admin@your-synology-ip
   ```

2. **Перейдите в директорию проекта:**
   ```bash
   cd /var/www/html/bso-portal/api
   ```

3. **Установите TCPDF:**
   ```bash
   php install-tcpdf.php
   ```

4. **Проверьте права:**
   ```bash
   chmod -R 755 vendor/tcpdf  # или tcpdf
   chown -R http:http vendor/tcpdf  # или tcpdf
   ```

5. **Проверьте в веб-интерфейсе:**
   - Откройте портал
   - Протестируйте генерацию PDF

## Дополнительная информация

- **Версия TCPDF:** 6.6.5 (рекомендуется)
- **Минимальная версия PHP:** 7.0
- **Поддержка кириллицы:** Встроенная (шрифт dejavusans)
- **Документация TCPDF:** https://tcpdf.org/

## Поддержка

Если возникли проблемы:
1. Проверьте логи PHP: `/var/log/php_errors.log`
2. Проверьте логи веб-сервера
3. Убедитесь, что PHP имеет права на чтение файлов TCPDF
