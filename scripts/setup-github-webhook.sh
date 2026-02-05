#!/bin/bash
# Скрипт настройки GitHub Webhook для автоматического деплоя

set -e

PROJECT_DIR="/home/rbna/rbna-portal"
BACKUP_DIR="/home/rbna/backups"
WEBHOOK_DIR="/home/rbna/webhook-server"
GITHUB_REPO_URL=""  # Будет заполнено пользователем
WEBHOOK_SECRET=$(openssl rand -hex 20)

echo "🚀 Настройка автоматического деплоя с GitHub"
echo "=============================================="

# 1. Создание директорий
echo "📁 Создание необходимых директорий..."
mkdir -p "$BACKUP_DIR"
mkdir -p "$WEBHOOK_DIR"
mkdir -p "$PROJECT_DIR/logs"

# 2. Установка зависимостей для webhook сервера
echo "📦 Установка зависимостей..."
if ! command -v node &> /dev/null; then
    echo "Node.js не установлен. Установите Node.js сначала."
    exit 1
fi

cd "$WEBHOOK_DIR"
npm init -y
npm install github-webhook-handler express --save

# 3. Создание webhook сервера
cat > "$WEBHOOK_DIR/webhook-server.js" << 'EOF'
const http = require('http');
const createHandler = require('github-webhook-handler');
const { exec } = require('child_process');
const handler = createHandler({ path: '/webhook', secret: process.env.WEBHOOK_SECRET });

const deployScript = '/home/rbna/rbna-portal/scripts/deploy.sh';

http.createServer((req, res) => {
  handler(req, res, (err) => {
    res.statusCode = 404;
    res.end('Not found');
  });
}).listen(9000, () => {
  console.log('Webhook server listening on port 9000');
});

handler.on('push', (event) => {
  console.log('Received push event:', event.payload.ref);
  
  if (event.payload.ref === 'refs/heads/main' || event.payload.ref === 'refs/heads/master') {
    console.log('Deploying...');
    exec(`bash ${deployScript}`, (error, stdout, stderr) => {
      if (error) {
        console.error('Deploy error:', error);
        return;
      }
      console.log('Deploy output:', stdout);
      if (stderr) console.error('Deploy stderr:', stderr);
    });
  }
});

handler.on('error', (err) => {
  console.error('Webhook error:', err.message);
});
EOF

# 4. Создание systemd сервиса для webhook
cat > /tmp/rbna-webhook.service << EOF
[Unit]
Description=RBNA Portal GitHub Webhook Server
After=network.target

[Service]
Type=simple
User=rbna
WorkingDirectory=$WEBHOOK_DIR
Environment="WEBHOOK_SECRET=$WEBHOOK_SECRET"
Environment="NODE_ENV=production"
ExecStart=/usr/bin/node $WEBHOOK_DIR/webhook-server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/rbna-webhook.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable rbna-webhook
sudo systemctl start rbna-webhook

echo ""
echo "✅ Webhook сервер настроен!"
echo ""
echo "📋 Информация для настройки GitHub:"
echo "====================================="
echo "Webhook URL: http://151.245.137.147:9000/webhook"
echo "Secret: $WEBHOOK_SECRET"
echo ""
echo "Инструкции:"
echo "1. Перейдите в настройки вашего GitHub репозитория"
echo "2. Settings -> Webhooks -> Add webhook"
echo "3. Payload URL: http://151.245.137.147:9000/webhook"
echo "4. Content type: application/json"
echo "5. Secret: $WEBHOOK_SECRET"
echo "6. Events: Just the push event"
echo "7. Active: ✓"
echo ""
echo "⚠️  ВАЖНО: Убедитесь, что порт 9000 открыт в firewall!"
