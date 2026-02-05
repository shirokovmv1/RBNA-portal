# Установка TCPDF для генерации PDF на сервере

## Зачем это нужно?

Генерация PDF на сервере устраняет критическую уязвимость безопасности - утечку персональных данных через внешний CDN и браузер пользователя.

## Вариант 1: Установка через Composer (рекомендуется)

### На Synology NAS:

1. Установите Composer (если еще не установлен):
```bash
cd /var/www/html/bso-portal/api
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"
```

2. Установите TCPDF:
```bash
cd /var/www/html/bso-portal/api
php composer.phar require tecnickcom/tcpdf
```

3. Проверьте установку:
```bash
ls -la vendor/tecnickcom/tcpdf/
```

4. Обновите путь в `api/helpdesk-pdf.php`:
```php
$tcpdfPath = __DIR__ . '/vendor/tecnickcom/tcpdf/tcpdf.php';
```

## Вариант 2: Ручная установка

1. Скачайте TCPDF:
```bash
cd /var/www/html/bso-portal/api
wget https://github.com/tecnickcom/TCPDF/archive/refs/tags/6.6.5.tar.gz
tar -xzf 6.6.5.tar.gz
mv TCPDF-6.6.5 tcpdf
```

2. Установите права доступа:
```bash
chmod -R 755 tcpdf
chown -R http:http tcpdf  # или www-data:www-data в зависимости от системы
```

3. Проверьте установку:
```bash
ls -la tcpdf/tcpdf.php
```

## Вариант 3: Использование без TCPDF (fallback)

Если TCPDF не установлен, система будет использовать HTML fallback. Это менее идеально, но функционально.

Для полной безопасности рекомендуется установить TCPDF.

## Проверка работы

1. Откройте форму Help Desk на портале
2. Заполните форму
3. Нажмите "Сохранить заявку"
4. Должен скачаться PDF файл

Если PDF не генерируется, проверьте:
- Логи PHP: `/var/log/php_errors.log`
- Права доступа к директории `api/tcpdf/`
- Версию PHP (требуется PHP 7.0+)

## Настройка шрифтов для кириллицы

TCPDF по умолчанию поддерживает кириллицу через шрифт `dejavusans`. Если нужны другие шрифты:

1. Скачайте шрифты в `tcpdf/fonts/`
2. Используйте утилиту `tcpdf/tools/tcpdf_addfont.php` для добавления шрифтов

## Безопасность

После установки TCPDF:
- ✅ PDF генерируется на сервере (данные не проходят через браузер)
- ✅ Нет зависимости от внешних CDN
- ✅ Персональные данные защищены

## Обновление

Для обновления TCPDF через Composer:
```bash
cd /var/www/html/bso-portal/api
php composer.phar update tecnickcom/tcpdf
```

Для ручной установки - скачайте новую версию и замените директорию `tcpdf/`.
