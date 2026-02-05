# 🚀 Развертывание на сервер 151.245.137.147 - Выполните сейчас

## ⚡ Самый быстрый способ

### Выполните эти команды на сервере:

**Подключитесь к серверу:**
```bash
ssh root@151.245.137.147
# Пароль: u14YDBo+u4
```

**На сервере выполните одну команду:**

```bash
# Вариант 1: Если проект уже в Git репозитории
cd /root && curl -o deploy.sh https://raw.githubusercontent.com/shirokovmv1/RBNA-portal/main/deploy_to_151.245.137.147.sh && chmod +x deploy.sh && ./deploy.sh

# Вариант 2: Клонирование и развертывание одной командой
cd /root && git clone https://github.com/shirokovmv1/RBNA-portal.git /tmp/rbna && bash /tmp/rbna/deploy_to_151.245.137.147.sh
```

---

## 📋 Пошаговые команды (если нужен контроль)

### 1. Подключитесь к серверу

```bash
ssh root@151.245.137.147
# Пароль: u14YDBo+u4
```

### 2. Обновите систему

```bash
apt-get update && apt-get upgrade -y
```

### 3. Установите зависимости

```bash
apt-get install -y python3 python3-pip python3-venv python3-dev \
    postgresql postgresql-contrib nginx git build-essential \
    libssl-dev libffi-dev ufw curl wget openssl

# Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
```

### 4. Клонируйте проект

```bash
cd /home
git clone https://github.com/shirokovmv1/RBNA-portal.git rbna-portal
cd rbna-portal
```

### 5. Запустите скрипт развертывания

```bash
# Если скрипт уже в проекте
chmod +x deploy_to_151.245.137.147.sh
./deploy_to_151.245.137.147.sh

# Или используйте общий скрипт
chmod +x deploy_complete.sh
./deploy_complete.sh 151.245.137.147 https://github.com/shirokovmv1/RBNA-portal.git
```

---

## 🎯 Рекомендуемый способ

**Выполните на сервере одну команду:**

```bash
bash <(curl -sSL https://raw.githubusercontent.com/shirokovmv1/RBNA-portal/main/deploy_to_151.245.137.147.sh)
```

**Или если скрипт уже загружен:**

```bash
chmod +x /root/deploy_to_151.245.137.147.sh
/root/deploy_to_151.245.137.147.sh
```

---

## ✅ После выполнения

1. **Создайте суперпользователя:**
```bash
su - rbna
cd /home/rbna/rbna-portal/backend
source venv/bin/activate
python manage.py createsuperuser
```

2. **Проверьте работу:**
- http://151.245.137.147
- http://151.245.137.147/api/users/
- http://151.245.137.147/admin/

---

**Выполните команды выше для развертывания! 🚀**
