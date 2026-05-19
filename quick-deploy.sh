#!/bin/bash

# Быстрое развертывание проекта x5 за одну команду
# Использование: bash <(curl -s https://raw.githubusercontent.com/Ta1l/x5/main/quick-deploy.sh)

set -e

echo "================================"
echo "  🚀 Быстрое развертывание x5"
echo "================================"
echo ""

# 1. Обновление системы
echo "[1/8] 📦 Обновление системы..."
apt-get update -qq
apt-get upgrade -y -qq

# 2. Установка зависимостей
echo "[2/8] 📦 Установка Node.js 20, npm, git..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - > /dev/null 2>&1
apt-get install -y nodejs git build-essential > /dev/null 2>&1

# 3. Версии
echo "   ✅ Node.js: $(node -v)"
echo "   ✅ npm: $(npm -v)"
echo "   ✅ git: $(git --version)"
echo ""

# 4. Клонирование или обновление репозитория
echo "[3/8] 📥 Клонирование проекта..."
mkdir -p /var/www
cd /var/www

if [ -d "x5" ]; then
  echo "   ⚠️  x5 уже существует, обновляю..."
  cd x5
  git fetch origin
  git reset --hard origin/main
else
  git clone https://github.com/Ta1l/x5.git
  cd x5
fi

echo "   ✅ Проект готов"
echo ""

# 5. Установка npm зависимостей
echo "[4/8] 📦 Установка npm зависимостей..."
npm install --production --silent > /dev/null 2>&1
echo "   ✅ Зависимости установлены"
echo ""

# 6. Права доступа
echo "[5/8] 🔐 Установка прав доступа..."
chown -R www-data:www-data /var/www/x5
chmod +x /var/www/x5/server.js
echo "   ✅ Права установлены"
echo ""

# 7. Systemd сервис
echo "[6/8] ⚙️  Создание systemd сервиса..."
cat > /etc/systemd/system/courier-app.service <<'EOF'
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

systemctl daemon-reload
systemctl start courier-app
systemctl enable courier-app
echo "   ✅ Сервис создан и запущен"
echo ""

# 8. Nginx
echo "[7/8] 🌐 Настройка Nginx..."
apt-get install -y nginx > /dev/null 2>&1

cat > /etc/nginx/sites-available/slotworker.ru <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name slotworker.ru www.slotworker.ru;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

ln -sf /etc/nginx/sites-available/slotworker.ru /etc/nginx/sites-enabled/ 2>/dev/null || true
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
nginx -t > /dev/null 2>&1
systemctl restart nginx
systemctl enable nginx
echo "   ✅ Nginx настроен"
echo ""

# 9. SSL
echo "[8/8] 🔒 Установка SSL сертификата..."
apt-get install -y certbot python3-certbot-nginx > /dev/null 2>&1

# Получаем сертификат (используй свой email)
certbot --nginx \
  -d slotworker.ru \
  -d www.slotworker.ru \
  --non-interactive \
  --agree-tos \
  --email admin@slotworker.ru \
  --force-renewal 2>&1 | grep -v "^$" || true

echo "   ✅ SSL установлен"
echo ""

echo "================================"
echo "  ✅ Развертывание завершено!"
echo "================================"
echo ""
echo "📊 Информация о проекте:"
echo "   • Проект: /var/www/x5"
echo "   • Сервис: courier-app"
echo "   • URL: https://slotworker.ru"
echo "   • API: https://slotworker.ru/api/"
echo "   • БД: /var/www/x5/courier_applications.db"
echo ""
echo "📋 Проверка:"
echo "   https://slotworker.ru          # Главная страница"
echo "   https://slotworker.ru/api/stats   # Статистика"
echo ""
echo "🛠️  Команды:"
echo "   systemctl status courier-app   # Статус сервиса"
echo "   systemctl logs courier-app     # Логи"
echo "   sqlite3 /var/www/x5/courier_applications.db  # БД"
echo ""
