# RBNA Portal - Портал подрядчиков

Веб-приложение для управления строительными проектами, подрядчиками и финансами.

## Технологический стек

### Backend
- Python 3.10+
- Django 4.2
- Django REST Framework
- SQLite (для прототипа)

### Frontend
- React 18
- TypeScript
- React Router
- Axios

## Структура проекта

```
.
├── backend/          # Django backend
│   ├── api/         # API приложение
│   ├── rbnaportal/  # Настройки Django
│   └── manage.py
├── frontend/        # React frontend
│   ├── src/
│   └── public/
└── README.md
```

## Установка и запуск

### Backend

1. Перейдите в директорию backend:
```bash
cd backend
```

2. Создайте виртуальное окружение (рекомендуется):
```bash
python -m venv venv
```

3. Активируйте виртуальное окружение:
- Windows:
```bash
venv\Scripts\activate
```
- Linux/Mac:
```bash
source venv/bin/activate
```

4. Установите зависимости:
```bash
pip install -r requirements.txt
```

5. Выполните миграции:
```bash
python manage.py migrate
```

6. Создайте суперпользователя (опционально, для доступа к Django admin):
```bash
python manage.py createsuperuser
```

7. Загрузите демо-данные:
```bash
python manage.py seed_data
```

8. Запустите сервер разработки:
```bash
python manage.py runserver
```

Backend будет доступен по адресу: http://localhost:8000

API документация: http://localhost:8000/api/

### Frontend

1. Перейдите в директорию frontend:
```bash
cd frontend
```

2. Установите зависимости:
```bash
npm install
```

3. Запустите сервер разработки:
```bash
npm start
```

Frontend будет доступен по адресу: http://localhost:3000

## Использование

### Вход в систему

Для прототипа используется простой выбор пользователя без настоящей аутентификации. При входе выберите пользователя из списка:

- **admin** - Администратор (доступ ко всем функциям)
- **volkov** - Волков А. (TOP_MANAGER)
- **uvarova** - Уварова Е. (FIN_MANAGER)
- **site1, site2** - Прорабы (SITE_MANAGER)
- **pm1, pm2** - Руководители проектов (PM)

### Роли и доступ

- **ADMIN** - Полный доступ ко всем функциям
- **TOP_MANAGER** - Главная панель с проектами, рейтинг подрядчиков
- **FIN_MANAGER** - Финансовая панель, отчёты генподрядчика
- **SITE_MANAGER** - Панель проекта, прогресс работ
- **PM** - Доступ к проекту, финансам, единичным расценкам

### Основные функции

1. **Главная панель** - Список проектов с фильтрацией, алерты, экспорт в CSV
2. **Финансовая панель** - Договоры, статьи затрат, отчёты генподрядчика
3. **Карточка проекта** - Детальная информация о проекте, подрядчики, статьи затрат
4. **Рейтинг подрядчиков** - Список подрядчиков с фильтрацией и детальной информацией
5. **База единичных расценок** - Управление расценками (CRUD)

### Экспорт данных

На страницах с таблицами доступна функция экспорта в CSV:
- Проекты
- Договоры
- Статьи затрат
- Подрядчики

## API Endpoints

### Projects
- `GET /api/projects/` - Список проектов
- `GET /api/projects/{id}/` - Детали проекта
- `GET /api/projects/alerts/` - Алерты по проектам
- `GET /api/projects/export_csv/` - Экспорт в CSV

### Contractors
- `GET /api/contractors/` - Список подрядчиков
- `GET /api/contractors/{id}/` - Детали подрядчика
- `GET /api/contractors/{id}/details/` - Детальная информация с проектами
- `GET /api/contractors/export_csv/` - Экспорт в CSV

### Contracts
- `GET /api/contracts/` - Список договоров
- `GET /api/contracts/{id}/` - Детали договора
- `GET /api/contracts/export_csv/` - Экспорт в CSV

### Cost Items
- `GET /api/cost-items/` - Список статей затрат
- `GET /api/cost-items/export_csv/` - Экспорт в CSV

### Unit Rates
- `GET /api/unit-rates/` - Список расценок
- `POST /api/unit-rates/` - Создать расценку
- `PUT /api/unit-rates/{id}/` - Обновить расценку
- `DELETE /api/unit-rates/{id}/` - Удалить расценку

### Reports
- `GET /api/reports/` - Список отчётов
- `PATCH /api/reports/{id}/` - Обновить статус отчёта

### Payments
- `GET /api/payments/` - Список платежей

## Демо-данные

Скрипт `seed_data` создаёт:
- 8 пользователей с разными ролями
- 8 подрядчиков (генподрядчики и подрядчики)
- 5 проектов разных типов
- 15+ договоров
- 30+ статей затрат
- Единичные расценки
- Платежи по договорам
- Отчёты генподрядчика

## Важные замечания

⚠️ **Open Book модуль не реализован** - согласно требованиям, модуль Open Book не содержит логики расчётов. В коде могут быть заготовки/интерфейсы на будущее, но без реализации алгоритмов.

## Разработка

### Backend

Для создания новых миграций:
```bash
python manage.py makemigrations
python manage.py migrate
```

Для доступа к Django admin:
- URL: http://localhost:8000/admin/
- Используйте созданного суперпользователя

### Frontend

Для сборки production версии:
```bash
npm run build
```

## Лицензия

Проект создан для внутреннего использования.
