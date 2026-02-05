# Production настройка - Быстрая справка

## 🚀 Быстрый старт

### Шаг 1: .env файл

```bash
cd backend
cp .env.example .env

# Сгенерировать SECRET_KEY
python manage.py shell
# В shell:
from django.core.management.utils import get_random_secret_key
print(get_random_secret_key())
exit()

# Отредактировать .env
nano .env  # или notepad .env
```

**Содержимое .env:**
```env
SECRET_KEY=ваш-сгенерированный-ключ
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
CORS_ALLOWED_ORIGINS=https://yourdomain.com
SECURE_SSL_REDIRECT=True
```

---

### Шаг 2: Замена AllowAny

**В файле `backend/api/views.py`:**

Найти и заменить во всех 8 ViewSets:
```python
# Было:
permission_classes = [AllowAny]

# Стало:
permission_classes = [IsAuthenticated]
```

**Автозамена в редакторе:**
- Найти: `[AllowAny]`
- Заменить: `[IsAuthenticated]`

---

### Шаг 3: JWT аутентификация

```bash
# 1. Установить пакет
pip install djangorestframework-simplejwt

# 2. Добавить в requirements.txt
echo "djangorestframework-simplejwt==5.3.0" >> requirements.txt
```

**В `settings.py` добавить в INSTALLED_APPS:**
```python
'rest_framework_simplejwt',
```

**В `settings.py` обновить REST_FRAMEWORK:**
```python
from datetime import timedelta

REST_FRAMEWORK = {
    # ... существующие настройки ...
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'AUTH_HEADER_TYPES': ('Bearer',),
}
```

**В `urls.py` добавить:**
```python
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    # ... существующие маршруты ...
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
```

---

### Шаг 4: HTTPS

**В `settings.py` (уже должно быть):**
```python
if not DEBUG:
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
```

**Установить SSL сертификат:**
```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

---

## ✅ Проверка

```bash
# Проверка настроек
python manage.py check --deploy

# Миграции
python manage.py migrate

# Статические файлы
python manage.py collectstatic --noinput
```

---

## 📝 Чеклист

- [ ] .env создан с production значениями
- [ ] SECRET_KEY изменен
- [ ] DEBUG = False
- [ ] ALLOWED_HOSTS настроен
- [ ] AllowAny заменен на IsAuthenticated (8 мест)
- [ ] JWT установлен и настроен
- [ ] URL маршруты для токенов добавлены
- [ ] HTTPS настроен
- [ ] SSL сертификат установлен
- [ ] Миграции применены
- [ ] Статические файлы собраны

---

## 🔗 Полезные ссылки

- Подробная инструкция: `PRODUCTION_STEP_BY_STEP.md`
- Полное руководство: `PRODUCTION_SETUP.md`
