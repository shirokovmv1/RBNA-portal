# Исправления безопасности для RBNA Portal

## Быстрые исправления для прототипа

### 1. Вынос SECRET_KEY в переменные окружения

Создайте файл `.env` в директории `backend/`:

```bash
SECRET_KEY=your-secret-key-here-generate-with-django-admin
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
```

Обновите `settings.py`:

```python
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# Загрузка переменных окружения из .env файла
# Установите: pip install python-dotenv
from dotenv import load_dotenv
load_dotenv(BASE_DIR / '.env')

SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-dev-key-change-in-production')
DEBUG = os.environ.get('DEBUG', 'True') == 'True'
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')
```

### 2. Добавление базовой аутентификации

Обновите `backend/api/views.py`:

```python
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import permission_classes

class UserViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [AllowAny]  # Для прототипа - разрешить всем
    # Для production: permission_classes = [IsAuthenticated]

class ProjectViewSet(viewsets.ModelViewSet):
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    permission_classes = [AllowAny]  # Для прототипа
    # Для production: permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    # ... остальной код
```

### 3. Добавление .env в .gitignore

Убедитесь, что `.env` файл в `.gitignore`:

```gitignore
# Environment
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
```

### 4. Генерация нового SECRET_KEY

Выполните в терминале:

```bash
cd backend
python manage.py shell
```

В Python shell:

```python
from django.core.management.utils import get_random_secret_key
print(get_random_secret_key())
```

Скопируйте сгенерированный ключ в `.env` файл.

## Исправления для production

### 1. Установка зависимостей

```bash
pip install python-dotenv django-ratelimit djangorestframework-simplejwt
```

### 2. Настройка JWT аутентификации

В `settings.py`:

```python
INSTALLED_APPS = [
    # ... существующие приложения
    'rest_framework_simplejwt',
]

REST_FRAMEWORK = {
    # ... существующие настройки
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    'ROTATE_REFRESH_TOKENS': True,
}
```

### 3. Добавление rate limiting

В `views.py`:

```python
from django_ratelimit.decorators import ratelimit
from django.utils.decorators import method_decorator

@method_decorator(ratelimit(key='ip', rate='100/h', method='GET'), name='list')
@method_decorator(ratelimit(key='ip', rate='10/h', method='POST'), name='create')
class ProjectViewSet(viewsets.ModelViewSet):
    # ... код
```

### 4. Настройка валидации

В `serializers.py` добавьте валидаторы:

```python
class ContractSerializer(serializers.ModelSerializer):
    # ... существующие поля
    
    def validate(self, data):
        # Проверка, что проект существует
        if 'project' in data:
            if not Project.objects.filter(id=data['project'].id).exists():
                raise serializers.ValidationError({"project": "Project does not exist"})
        
        # Проверка сумм
        if 'planned_amount' in data and 'contracted_amount' in data:
            if data['contracted_amount'] < 0:
                raise serializers.ValidationError({"contracted_amount": "Amount cannot be negative"})
        
        return data
```

## Чеклист безопасности

- [ ] SECRET_KEY вынесен в переменные окружения
- [ ] DEBUG отключен для production
- [ ] ALLOWED_HOSTS настроен правильно
- [ ] Добавлена аутентификация (JWT или Session)
- [ ] Добавлена авторизация (permission_classes)
- [ ] Настроен HTTPS (SECURE_SSL_REDIRECT)
- [ ] Настроен CORS правильно
- [ ] Добавлен rate limiting
- [ ] Добавлена валидация входных данных
- [ ] Настроено логирование
- [ ] База данных переведена на PostgreSQL
- [ ] Регулярные бэкапы настроены
- [ ] Мониторинг и алерты настроены

## Дополнительные рекомендации

1. **Используйте HTTPS** - обязательно для production
2. **Настройте брандмауэр** - ограничьте доступ к портам
3. **Регулярные обновления** - обновляйте зависимости
4. **Мониторинг** - используйте Sentry или аналоги
5. **Аудит** - логируйте все важные действия
6. **Тестирование** - добавьте security тесты

## Полезные ссылки

- [Django Security Checklist](https://docs.djangoproject.com/en/4.2/howto/deployment/checklist/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Django REST Framework Security](https://www.django-rest-framework.org/api-guide/permissions/)
