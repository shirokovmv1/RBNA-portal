# Пошаговая настройка Production окружения

## Шаг 1: Создание .env файла с production значениями

### 1.1. Создайте .env файл

```bash
cd backend
cp .env.example .env
```

### 1.2. Сгенерируйте новый SECRET_KEY

Выполните в терминале:

```bash
cd backend
python manage.py shell
```

В Python shell выполните:

```python
from django.core.management.utils import get_random_secret_key
print(get_random_secret_key())
```

Скопируйте сгенерированный ключ.

### 1.3. Отредактируйте .env файл

Откройте `backend/.env` и установите следующие значения:

```env
# ОБЯЗАТЕЛЬНО: Замените на сгенерированный ключ!
SECRET_KEY=django-insecure-YOUR-GENERATED-SECRET-KEY-HERE

# ОБЯЗАТЕЛЬНО: False для production!
DEBUG=False

# ОБЯЗАТЕЛЬНО: Укажите ваш домен!
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

# Укажите ваш frontend домен
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Для HTTPS (если используете)
SECURE_SSL_REDIRECT=True
```

**Пример для реального домена:**
```env
SECRET_KEY=django-insecure-abc123xyz789secretkey456
DEBUG=False
ALLOWED_HOSTS=rbna-portal.com,www.rbna-portal.com
CORS_ALLOWED_ORIGINS=https://rbna-portal.com,https://www.rbna-portal.com
SECURE_SSL_REDIRECT=True
```

---

## Шаг 2: Замена AllowAny на IsAuthenticated в ViewSets

### 2.1. Откройте файл `backend/api/views.py`

### 2.2. Найдите все места с `permission_classes = [AllowAny]`

Их будет 8 штук в следующих ViewSets:
- UserViewSet
- ProjectViewSet
- ContractorViewSet
- ContractViewSet
- CostItemViewSet
- UnitRateViewSet
- PaymentViewSet
- ReportViewSet

### 2.3. Замените AllowAny на IsAuthenticated

**Было:**
```python
permission_classes = [AllowAny]  # Для production: [IsAuthenticated]
```

**Стало:**
```python
permission_classes = [IsAuthenticated]
```

### 2.4. Пример полного изменения для одного ViewSet

**До:**
```python
class ProjectViewSet(viewsets.ModelViewSet):
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    permission_classes = [AllowAny]  # Для production: [IsAuthenticated]
    # ... остальной код
```

**После:**
```python
class ProjectViewSet(viewsets.ModelViewSet):
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    permission_classes = [IsAuthenticated]
    # ... остальной код
```

### 2.5. Автоматическая замена (опционально)

Можно использовать поиск и замену в редакторе:
- Найти: `permission_classes = [AllowAny]  # Для production: [IsAuthenticated]`
- Заменить на: `permission_classes = [IsAuthenticated]`

Или найти: `permission_classes = [AllowAny]`
И заменить на: `permission_classes = [IsAuthenticated]`

---

## Шаг 3: Настройка JWT аутентификации

### 3.1. Установите необходимые пакеты

```bash
cd backend
pip install djangorestframework-simplejwt
```

Добавьте в `requirements.txt`:
```bash
echo "djangorestframework-simplejwt==5.3.0" >> requirements.txt
```

### 3.2. Обновите settings.py

Откройте `backend/rbnaportal/settings.py` и найдите секцию `INSTALLED_APPS`.

**Добавьте:**
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

### 3.3. Настройте REST_FRAMEWORK для JWT

Найдите секцию `REST_FRAMEWORK` в `settings.py` и замените на:

```python
from datetime import timedelta

REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 100,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
    # Добавьте эти настройки:
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.SessionAuthentication',  # Опционально, для админки
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

# Настройки JWT токенов
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),  # Токен действителен 1 час
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),     # Refresh токен действителен 1 день
    'ROTATE_REFRESH_TOKENS': True,                   # Обновлять refresh токен при использовании
    'BLACKLIST_AFTER_ROTATION': True,                # Старые токены в черный список
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
}
```

### 3.4. Добавьте URL для получения токенов

Откройте `backend/rbnaportal/urls.py` и добавьте:

```python
from django.urls import path, include
from django.contrib import admin
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
    # Добавьте эти маршруты для JWT:
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
```

### 3.5. Обновите frontend для использования JWT

Откройте `frontend/src/api/client.ts` и обновите:

```typescript
import axios from 'axios';
import {
  User,
  Project,
  Contractor,
  // ... остальные импорты
} from '../types';

const API_BASE_URL = process.env.REACT_APP_API_URL || '/api';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Добавьте interceptor для добавления токена к запросам
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Добавьте interceptor для обновления токена при 401 ошибке
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        const refreshToken = localStorage.getItem('refresh_token');
        const response = await axios.post(`${API_BASE_URL}/token/refresh/`, {
          refresh: refreshToken,
        });
        
        const { access } = response.data;
        localStorage.setItem('access_token', access);
        originalRequest.headers.Authorization = `Bearer ${access}`;
        
        return apiClient(originalRequest);
      } catch (refreshError) {
        // Если refresh не удался, перенаправляем на логин
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }
    
    return Promise.reject(error);
  }
);

// Добавьте функции для работы с токенами
export const login = async (username: string, password: string) => {
  const response = await axios.post(`${API_BASE_URL}/token/`, {
    username,
    password,
  });
  const { access, refresh } = response.data;
  localStorage.setItem('access_token', access);
  localStorage.setItem('refresh_token', refresh);
  return { access, refresh };
};

export const logout = () => {
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
};

// ... остальные функции API остаются без изменений
```

### 3.6. Обновите AuthContext для использования JWT

Обновите `frontend/src/contexts/AuthContext.tsx` для работы с JWT (или создайте новую систему аутентификации).

---

## Шаг 4: Включение HTTPS

### 4.1. Настройка в settings.py

Убедитесь, что в `backend/rbnaportal/settings.py` есть следующие настройки (они уже добавлены, но проверьте):

```python
# Security settings (активируются только если DEBUG=False)
if not DEBUG:
    SECURE_SSL_REDIRECT = os.environ.get('SECURE_SSL_REDIRECT', 'False') == 'True'
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
    
    # Дополнительные настройки для production:
    SECURE_HSTS_SECONDS = 31536000  # 1 год
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
```

### 4.2. Настройка веб-сервера (Nginx)

Создайте конфигурацию Nginx `/etc/nginx/sites-available/rbna-portal`:

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate /path/to/your/certificate.crt;
    ssl_certificate_key /path/to/your/private.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /path/to/your/staticfiles/;
    }
}
```

### 4.3. Получение SSL сертификата (Let's Encrypt)

```bash
# Установите certbot
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# Получите сертификат
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Автоматическое обновление
sudo certbot renew --dry-run
```

### 4.4. Настройка Django для работы за прокси

В `settings.py` добавьте:

```python
# Для работы за reverse proxy (Nginx)
USE_X_FORWARDED_HOST = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
```

---

## Шаг 5: Проверка настроек

### 5.1. Проверьте настройки Django

```bash
cd backend
python manage.py check --deploy
```

Должно вывести предупреждения о настройках для production.

### 5.2. Проверьте миграции

```bash
python manage.py makemigrations
python manage.py migrate
```

### 5.3. Соберите статические файлы

```bash
python manage.py collectstatic --noinput
```

### 5.4. Создайте суперпользователя (если нужно)

```bash
python manage.py createsuperuser
```

---

## Шаг 6: Запуск в production

### 6.1. Используйте Gunicorn вместо runserver

```bash
pip install gunicorn
```

Создайте `backend/gunicorn_config.py`:

```python
bind = "127.0.0.1:8000"
workers = 4
worker_class = "sync"
timeout = 120
keepalive = 5
max_requests = 1000
max_requests_jitter = 50
```

### 6.2. Запуск с Gunicorn

```bash
cd backend
gunicorn rbnaportal.wsgi:application --config gunicorn_config.py
```

### 6.3. Использование systemd (опционально)

Создайте `/etc/systemd/system/rbna-portal.service`:

```ini
[Unit]
Description=RBNA Portal Gunicorn daemon
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/path/to/backend
ExecStart=/path/to/venv/bin/gunicorn rbnaportal.wsgi:application --config gunicorn_config.py
Restart=always

[Install]
WantedBy=multi-user.target
```

Запустите:
```bash
sudo systemctl start rbna-portal
sudo systemctl enable rbna-portal
```

---

## Чеклист для production

- [ ] SECRET_KEY изменен и хранится в .env
- [ ] DEBUG = False
- [ ] ALLOWED_HOSTS настроен правильно
- [ ] AllowAny заменен на IsAuthenticated во всех ViewSets
- [ ] JWT аутентификация настроена
- [ ] Frontend обновлен для работы с JWT
- [ ] HTTPS настроен и работает
- [ ] SSL сертификат установлен и обновляется автоматически
- [ ] Статические файлы собраны
- [ ] Миграции применены
- [ ] Gunicorn настроен и запущен
- [ ] Nginx настроен как reverse proxy
- [ ] Логирование настроено
- [ ] Бэкапы настроены
- [ ] Мониторинг настроен

---

## Полезные команды

```bash
# Проверка настроек
python manage.py check --deploy

# Сбор статических файлов
python manage.py collectstatic

# Создание миграций
python manage.py makemigrations

# Применение миграций
python manage.py migrate

# Запуск Gunicorn
gunicorn rbnaportal.wsgi:application

# Проверка логов
tail -f /var/log/nginx/error.log
journalctl -u rbna-portal -f
```
