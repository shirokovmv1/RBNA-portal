# Автоматизация настройки Production

## Использование скриптов

### Скрипт 1: Базовая настройка (Linux/Mac)

```bash
cd backend
chmod +x scripts/setup_production.sh
./scripts/setup_production.sh
```

**Что делает:**
- Создает .env из шаблона
- Генерирует новый SECRET_KEY
- Устанавливает djangorestframework-simplejwt
- Применяет миграции
- Собирает статические файлы

### Скрипт 2: Замена AllowAny (все платформы)

```bash
cd backend
python scripts/replace_allowany.py
```

**Что делает:**
- Автоматически заменяет все `AllowAny` на `IsAuthenticated` в `api/views.py`

---

## Ручная настройка (если скрипты не работают)

См. подробные инструкции в `PRODUCTION_STEP_BY_STEP.md`

---

## Быстрая проверка после настройки

```bash
# Проверка настроек
python manage.py check --deploy

# Проверка количества IsAuthenticated
grep -c "IsAuthenticated" api/views.py
# Должно быть: 8

# Проверка отсутствия AllowAny
grep -c "AllowAny" api/views.py
# Должно быть: 0 (или только в импортах)
```
