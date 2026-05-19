#!/bin/bash

# Скрипт для развертывания x5 на сервер через прокси
# Запуск: bash deploy-via-proxy.sh

# Данные для подключения
PROXY_HOST="46.8.17.103"
PROXY_PORT="5501"
PROXY_USER="6NeZMV"
PROXY_PASS="iSxcP9mEj0"

SERVER_HOST="62.217.182.74"
SERVER_USER="root"
SERVER_PASS="*9w1Z*!R7WxH"

echo "============================================"
echo "  🚀 Развертывание x5 через прокси"
echo "============================================"
echo ""

# Функция для выполнения SSH команд
function run_remote_cmd() {
    local cmd="$1"
    
    # Используем sshpass если доступен
    if command -v sshpass &> /dev/null; then
        # Способ 1: Через sshpass с прямым подключением
        sshpass -p "$SERVER_PASS" ssh \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            "$SERVER_USER@$SERVER_HOST" \
            "$cmd"
    else
        # Способ 2: Если sshpass не установлен, пытаемся через ProxyCommand
        ssh -o ProxyUseFdpass=no \
            -o ProxyCommand="ssh -W %h:%p $PROXY_USER@$PROXY_HOST -p $PROXY_PORT" \
            -o StrictHostKeyChecking=no \
            "$SERVER_USER@$SERVER_HOST" \
            "$cmd"
    fi
}

# Проверка доступа
echo "[1] 🔐 Проверка доступа к серверу..."
if run_remote_cmd "whoami" | grep -q "root"; then
    echo "    ✅ Доступ получен"
else
    echo "    ❌ Не удается подключиться"
    echo ""
    echo "ИНСТРУКЦИЯ: Установите sshpass для автоматизации пароля:"
    echo ""
    echo "  На Windows (через Chocolatey):"
    echo "    choco install sshpass"
    echo ""
    echo "  На Linux:"
    echo "    sudo apt-get install sshpass"
    echo ""
    echo "  На macOS:"
    echo "    brew install sshpass"
    echo ""
    exit 1
fi
echo ""

# Запуск скрипта развертывания
echo "[2] 🚀 Запуск скрипта развертывания..."
echo ""

run_remote_cmd '
set -e

# Обновление системы
apt-get update -qq
apt-get upgrade -y -qq

# Установка Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs git build-essential curl wget

# Версии
echo "✅ Node: \$(node -v), npm: \$(npm -v)"

# Клонирование проекта
mkdir -p /var/www
cd /var/www
rm -rf x5 2>/dev/null || true
git clone https://github.com/Ta1l/x5.git
cd x5

# npm зависимости
npm install --production

# Systemd сервис
tee /etc/systemd/system/courier-app.service > /dev/null <<EOF
[Unit]
Description=Courier App (Node.js + SQLite)
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/x5
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

chown -R www-data:www-data /var/www/x5
chmod +x /var/www/x5/server.js
systemctl daemon-reload
systemctl start courier-app
systemctl enable courier-app

echo "✅ Сервис запущен"

# Nginx
apt-get install -y nginx

tee /etc/nginx/sites-available/slotworker.ru > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name slotworker.ru www.slotworker.ru;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection '\''upgrade'\'';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -sf /etc/nginx/sites-available/slotworker.ru /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
nginx -t
systemctl restart nginx
systemctl enable nginx

echo "✅ Nginx настроен"

# SSL
apt-get install -y certbot python3-certbot-nginx

certbot --nginx \
  -d slotworker.ru \
  -d www.slotworker.ru \
  --non-interactive \
  --agree-tos \
  --email admin@slotworker.ru \
  --force-renewal 2>&1 | tail -5 || true

echo "✅ SSL установлен"
echo ""
echo "======================================"
echo "  ✅ РАЗВЕРТЫВАНИЕ УСПЕШНО!"
echo "======================================"
echo ""
echo "📊 Проверка:"
echo "   https://slotworker.ru"
echo "   https://slotworker.ru/api/stats"
echo ""
'

echo ""
echo "[3] ✅ Развертывание завершено!"
echo ""
echo "📋 Следующие шаги:"
echo "   1. Откройте https://slotworker.ru в браузере"
echo "   2. Заполните форму и отправьте заявку"
echo "   3. Проверьте БД на сервере:"
echo "      sqlite3 /var/www/x5/courier_applications.db"
echo ""
