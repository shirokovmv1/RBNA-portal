# Быстрый старт RBNA Portal

## Шаг 1: Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
# или source venv/bin/activate  # Linux/Mac
pip install -r requirements.txt
python manage.py migrate
python manage.py seed_data
python manage.py runserver
```

Backend запущен на http://localhost:8000

## Шаг 2: Frontend

В новом терминале:

```bash
cd frontend
npm install
npm start
```

Frontend запущен на http://localhost:3000

## Шаг 3: Вход

1. Откройте http://localhost:3000
2. Выберите пользователя из списка (например, "admin" или "volkov")
3. Нажмите "Войти"

## Демо-пользователи

- **admin** - Администратор (полный доступ)
- **volkov** - Волков А. (TOP_MANAGER)
- **uvarova** - Уварова Е. (FIN_MANAGER)
- **site1** - Прораб Иванов (SITE_MANAGER)
- **pm1** - РП Сидоров (PM)

## Основные страницы

- `/` - Главная панель (проекты)
- `/financial` - Финансовая панель
- `/contractors` - Рейтинг подрядчиков
- `/unit-rates` - База единичных расценок
- `/project/{id}` - Карточка проекта

## API

API доступен по адресу: http://localhost:8000/api/

Примеры:
- http://localhost:8000/api/projects/
- http://localhost:8000/api/contractors/
- http://localhost:8000/api/contracts/
