# Структура проекта RBNA Portal

## Backend (Django)

```
backend/
├── api/                          # Основное приложение API
│   ├── management/
│   │   └── commands/
│   │       └── seed_data.py     # Скрипт для загрузки демо-данных
│   ├── migrations/               # Миграции БД
│   ├── admin.py                 # Настройки Django admin
│   ├── models.py                # Модели данных
│   ├── serializers.py           # DRF сериализаторы
│   ├── views.py                 # ViewSets для API
│   └── urls.py                  # URL маршруты API
├── rbnaportal/                   # Настройки Django проекта
│   ├── settings.py              # Настройки
│   ├── urls.py                  # Главные URL маршруты
│   └── wsgi.py                  # WSGI конфигурация
├── manage.py                    # Django management script
├── requirements.txt             # Python зависимости
└── db.sqlite3                   # SQLite база данных (создаётся автоматически)
```

## Frontend (React + TypeScript)

```
frontend/
├── public/
│   └── index.html               # HTML шаблон
├── src/
│   ├── api/
│   │   └── client.ts           # API клиент (axios)
│   ├── components/
│   │   ├── Layout.tsx          # Основной layout с навигацией
│   │   ├── Layout.css
│   │   └── PrivateRoute.tsx    # Защищённые маршруты
│   ├── contexts/
│   │   └── AuthContext.tsx      # Контекст аутентификации
│   ├── pages/
│   │   ├── LoginPage.tsx       # Страница входа
│   │   ├── DashboardPage.tsx   # Главная панель (TOP_MANAGER)
│   │   ├── FinancialPage.tsx   # Финансовая панель (FIN_MANAGER)
│   │   ├── ProjectPage.tsx     # Карточка проекта (SITE_MANAGER/PM)
│   │   ├── ContractorsPage.tsx # Рейтинг подрядчиков
│   │   └── UnitRatesPage.tsx   # База единичных расценок
│   ├── types/
│   │   └── index.ts            # TypeScript типы
│   ├── App.tsx                 # Главный компонент
│   ├── App.css                 # Стили приложения
│   ├── index.tsx               # Точка входа
│   └── index.css               # Глобальные стили
├── package.json                # Node.js зависимости
├── tsconfig.json               # TypeScript конфигурация
└── .gitignore
```

## Модели данных

### User
- Пользователи системы с ролями (ADMIN, TOP_MANAGER, FIN_MANAGER, SITE_MANAGER, PM)

### Project
- Объекты строительства
- Бюджет (план/факт/контракт)
- Сроки (план/факт)
- Прогресс
- Статус банковских ковенантов

### Contractor
- Подрядчики и генподрядчики
- Оценка надёжности
- Флаги рисков
- Средние отклонения по срокам и бюджету

### Contract
- Договоры между проектом и подрядчиком
- Суммы (план/контракт/оплачено)
- Статусы

### CostItem
- Статьи затрат по договорам
- Физические объёмы и стоимость
- Отклонения

### UnitRate
- Единичные расценки
- По типам проектов и видам работ

### Payment
- Платежи и денежные потоки
- Авансы, оплаты, удержания

### Report
- Отчёты генподрядчика
- Статусы обработки
- Оценка непротиворечивости

## API Endpoints

Все endpoints доступны по префиксу `/api/`:

- `/projects/` - CRUD проектов + alerts, export_csv
- `/contractors/` - CRUD подрядчиков + details, export_csv
- `/contracts/` - CRUD договоров + export_csv
- `/cost-items/` - CRUD статей затрат + export_csv
- `/unit-rates/` - CRUD единичных расценок
- `/payments/` - Список платежей
- `/reports/` - CRUD отчётов
- `/users/` - Список пользователей (read-only)

## Роли и доступ

### ADMIN
- Полный доступ ко всем функциям

### TOP_MANAGER
- Главная панель с проектами
- Рейтинг подрядчиков
- Алерты

### FIN_MANAGER
- Финансовая панель
- Договоры и статьи затрат
- Отчёты генподрядчика

### SITE_MANAGER
- Карточка проекта
- Прогресс работ
- Подрядчики проекта

### PM
- Карточка проекта
- Финансы проекта
- База единичных расценок
