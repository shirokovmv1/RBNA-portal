# Пошаговая инструкция: Production настройка

## 📋 Быстрая навигация

1. [Шаг 1: Создание .env](#шаг-1-создание-env-файла)
2. [Шаг 2: Замена AllowAny](#шаг-2-замена-allowany-на-isauthenticated)
3. [Шаг 3: Настройка JWT](#шаг-3-настройка-jwt-аутентификации)
4. [Шаг 4: Включение HTTPS](#шаг-4-включение-https)

---

## Шаг 1: Создание .env файла

### ✅ Что нужно сделать:

1. **Создать .env файл из шаблона**
2. **Сгенерировать новый SECRET_KEY**
3. **Заполнить production значения**

### 📝 Детальные шаги:

#### 1.1. Перейдите в директорию backend

```bash
cd backend
```

#### 1.2. Скопируйте шаблон

```bash
cp .env.example .env
```

#### 1.3. Сгенерируйте SECRET_KEY

```bash
python manage.py shell
```

В открывшемся Python shell выполните:

```python
from django.core.management.utils import get_random_secret_key
secret_key = get_random_secret_key()
print(secret_key)
```

**Скопируйте выведенный ключ!** Он будет выглядеть примерно так:
```
django-insecure-abc123xyz789def456ghi012jkl345mno678pqr901stu234vwx567
```

Выйдите из shell:
```python
exit()
```

#### 1.4. Откройте .env файл в редакторе

```bash
# Windows (Notepad)
notepad .env

# Linux/Mac
nano .env
# или
vim .env
```

#### 1.5. Заполните .env файл

Замените содержимое на:

```env
# ВАЖНО: Вставьте сгенерированный SECRET_KEY!
SECRET_KEY=django-insecure-ВАШ-СГЕНЕРИРОВАННЫЙ-КЛЮЧ-ЗДЕСЬ

# ВАЖНО: False для production!
DEBUG=False

# ВАЖНО: Укажите ваш реальный домен!
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

# Укажите ваш frontend домен с https
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Включить редирект на HTTPS
SECURE_SSL_REDIRECT=True
```

**Пример для домена `rbna-portal.example.com`:**
```env
SECRET_KEY=django-insecure-abc123xyz789def456ghi012jkl345mno678pqr901stu234vwx567
DEBUG=False
ALLOWED_HOSTS=rbna-portal.example.com,www.rbna-portal.example.com
CORS_ALLOWED_ORIGINS=https://rbna-portal.example.com,https://www.rbna-portal.example.com
SECURE_SSL_REDIRECT=True
```

#### 1.6. Сохраните файл

Сохраните изменения в `.env` файле.

**✅ Шаг 1 завершен!**

---

## Шаг 2: Замена AllowAny на IsAuthenticated

### ✅ Что нужно сделать:

Заменить `permission_classes = [AllowAny]` на `permission_classes = [IsAuthenticated]` во всех ViewSets.

### 📝 Детальные шаги:

#### 2.1. Откройте файл views.py

```bash
cd backend
# Откройте в вашем редакторе
code api/views.py
# или
nano api/views.py
```

#### 2.2. Найдите все вхождения AllowAny

В редакторе используйте поиск (Ctrl+F / Cmd+F) и найдите:
```
AllowAny
```

Вы найдете 8 мест в следующих классах:
- `UserViewSet` (строка ~25)
- `ProjectViewSet` (строка ~35)
- `ContractorViewSet` (строка ~145)
- `ContractViewSet` (строка ~160)
- `CostItemViewSet` (строка ~195)
- `UnitRateViewSet` (строка ~210)
- `PaymentViewSet` (строка ~225)
- `ReportViewSet` (строка ~240)

#### 2.3. Замените в каждом месте

Для каждого ViewSet найдите строку:
```python
permission_classes = [AllowAny]  # Для production: [IsAuthenticated]
```

И замените на:
```python
permission_classes = [IsAuthenticated]
```

#### 2.4. Пример замены для ProjectViewSet

**Найдите:**
```python
class ProjectViewSet(viewsets.ModelViewSet):
    """
    ViewSet для проектов.
    Для прототипа: AllowAny
    Для production: IsAuthenticated с проверкой ролей
    """
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    permission_classes = [AllowAny]  # Для production: [IsAuthenticated]
```

**Замените на:**
```python
class ProjectViewSet(viewsets.ModelViewSet):
    """
    ViewSet для проектов.
    Для прототипа: AllowAny
    Для production: IsAuthenticated с проверкой ролей
    """
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    permission_classes = [IsAuthenticated]
```

#### 2.5. Автоматическая замена (рекомендуется)

В большинстве редакторов можно использовать "Найти и заменить":

1. Откройте поиск и замену (Ctrl+H / Cmd+H)
2. **Найти:** `permission_classes = [AllowAny]  # Для production: [IsAuthenticated]`
3. **Заменить на:** `permission_classes = [IsAuthenticated]`
4. Нажмите "Заменить все"

Или более простой вариант:
1. **Найти:** `[AllowAny]`
2. **Заменить на:** `[IsAuthenticated]`
3. Проверьте каждое вхождение перед заменой

#### 2.6. Проверьте изменения

Убедитесь, что во всех 8 ViewSets теперь стоит:
```python
permission_classes = [IsAuthenticated]
```

**✅ Шаг 2 завершен!**

---

## Шаг 3: Настройка JWT аутентификации

### ✅ Что нужно сделать:

1. Установить djangorestframework-simplejwt
2. Настроить REST_FRAMEWORK для JWT
3. Добавить URL маршруты для токенов
4. Обновить frontend для работы с JWT

### 📝 Детальные шаги:

#### 3.1. Установите пакет

```bash
cd backend
pip install djangorestframework-simplejwt
```

#### 3.2. Добавьте в requirements.txt

```bash
echo "djangorestframework-simplejwt==5.3.0" >> requirements.txt
```

Или откройте `requirements.txt` и добавьте строку:
```
djangorestframework-simplejwt==5.3.0
```

#### 3.3. Обновите INSTALLED_APPS

Откройте `backend/rbnaportal/settings.py` и найдите `INSTALLED_APPS`.

**Найдите:**
```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'django_filters',
    'corsheaders',
    'api',
]
```

**Добавьте `'rest_framework_simplejwt'` после `'rest_framework'`:**
```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework_simplejwt',  # <-- Добавьте эту строку
    'django_filters',
    'corsheaders',
    'api',
]
```

#### 3.4. Обновите REST_FRAMEWORK настройки

В том же файле `settings.py` найдите секцию `REST_FRAMEWORK`:

**Найдите:**
```python
# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 100,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
}
```

**Замените на:**
```python
from datetime import timedelta

# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 100,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

# Настройки JWT токенов
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
}
```

**Важно:** Добавьте `from datetime import timedelta` в начало файла, если его там нет.

#### 3.5. Добавьте URL маршруты

Откройте `backend/rbnaportal/urls.py`:

**Найдите:**
```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
]
```

**Замените на:**
```python
from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
```

#### 3.6. Проверьте настройки

```bash
cd backend
python manage.py check
```

Должно вывести: "System check identified no issues (0 silenced)."

**✅ Шаг 3 завершен!**

---

## Шаг 4: Включение HTTPS

### ✅ Что нужно сделать:

1. Настроить Django для работы с HTTPS
2. Настроить веб-сервер (Nginx) с SSL
3. Получить SSL сертификат

### 📝 Детальные шаги:

#### 4.1. Проверьте настройки в settings.py

Откройте `backend/rbnaportal/settings.py` и убедитесь, что есть:

```python
# Security settings (активируются только если DEBUG=False)
if not DEBUG:
    SECURE_SSL_REDIRECT = os.environ.get('SECURE_SSL_REDIRECT', 'False') == 'True'
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    USE_X_FORWARDED_HOST = True
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
```

Если этого нет, добавьте в конец файла `settings.py`.

#### 4.2. Установите Nginx (если еще не установлен)

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install nginx
```

**CentOS/RHEL:**
```bash
sudo yum install nginx
```

#### 4.3. Получите SSL сертификат (Let's Encrypt)

**Установите certbot:**
```bash
sudo apt-get install certbot python3-certbot-nginx
```

**Получите сертификат:**
```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Следуйте инструкциям на экране. Certbot автоматически настроит Nginx.

#### 4.4. Настройте Nginx вручную (если нужно)

Создайте файл `/etc/nginx/sites-available/rbna-portal`:

```nginx
# Редирект HTTP на HTTPS
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS сервер
server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Проксирование на Django
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Статические файлы
    location /static/ {
        alias /path/to/backend/staticfiles/;
    }
}
```

**Активируйте конфигурацию:**
```bash
sudo ln -s /etc/nginx/sites-available/rbna-portal /etc/nginx/sites-enabled/
sudo nginx -t  # Проверка конфигурации
sudo systemctl reload nginx
```

#### 4.5. Настройте автоматическое обновление сертификата

```bash
sudo certbot renew --dry-run
```

Certbot автоматически обновляет сертификаты. Проверьте, что cron job настроен:
```bash
sudo systemctl status certbot.timer
```

**✅ Шаг 4 завершен!**

---

## 🎉 Финальная проверка

### Проверьте все настройки:

```bash
cd backend

# 1. Проверка настроек Django
python manage.py check --deploy

# 2. Применение миграций
python manage.py migrate

# 3. Сбор статических файлов
python manage.py collectstatic --noinput

# 4. Создание суперпользователя (если нужно)
python manage.py createsuperuser
```

### Проверьте работу API:

```bash
# Получение токена
curl -X POST http://yourdomain.com/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"yourpassword"}'

# Использование токена
curl http://yourdomain.com/api/projects/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 📚 Дополнительные ресурсы

- [Django Deployment Checklist](https://docs.djangoproject.com/en/4.2/howto/deployment/checklist/)
- [DRF JWT Documentation](https://django-rest-framework-simplejwt.readthedocs.io/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Nginx Configuration Guide](https://nginx.org/en/docs/)

---

**Готово! Ваше приложение настроено для production! 🚀**
