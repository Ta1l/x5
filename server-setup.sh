#!/bin/bash

# Скрипт первичной настройки сервера для проекта x5

echo "========================================"
echo "  🚀 Начало первичной настройки сервера"
echo "========================================"

# Обновление пакетов
echo ""
echo "📦 Обновление пакетного менеджера..."
apt-get update -qq
apt-get upgrade -y -qq

# Установка необходимых пакетов
echo ""
echo "📦 Установка Node.js, npm и git..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs git build-essential

# Проверка версий
echo ""
echo "✅ Проверка установленных версий:"
echo "Node.js: $(node -v)"
echo "npm: $(npm -v)"
echo "git: $(git --version)"

# Клонирование репозитория
echo ""
echo "📥 Клонирование репозитория с GitHub..."
cd /var/www || mkdir -p /var/www && cd /var/www
if [ -d "x5" ]; then
  echo "⚠️  Директория x5 уже существует, обновляю..."
  cd x5
  git pull origin main
else
  git clone https://github.com/Ta1l/x5.git
  cd x5
fi

# Установка зависимостей npm
echo ""
echo "📦 Установка зависимостей npm..."
npm install --production

# Создание systemd сервиса
echo ""
echo "⚙️  Создание systemd сервиса..."
cat > /etc/systemd/system/courier-app.service <<EOF
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

# Разрешения для www-data
echo ""
echo "🔐 Установка прав доступа..."
chown -R www-data:www-data /var/www/x5
chmod +x /var/www/x5/server.js

# Перезагрузка systemd
systemctl daemon-reload

# Запуск сервиса
echo ""
echo "🚀 Запуск сервиса..."
systemctl start courier-app
systemctl enable courier-app

# Проверка статуса
echo ""
echo "✅ Проверка статуса сервиса:"
systemctl status courier-app --no-pager

# Установка Nginx как reverse proxy
echo ""
echo "⚙️  Установка и настройка Nginx..."
apt-get install -y nginx

# Конфигурация Nginx
cat > /etc/nginx/sites-available/slotworker.ru <<'NGINX_EOF'
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

    # API endpoints
    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Content-Type application/json;
    }

    # Кеширование статических файлов
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
NGINX_EOF

# Активация сайта
ln -sf /etc/nginx/sites-available/slotworker.ru /etc/nginx/sites-enabled/

# Тест конфигурации Nginx
nginx -t

# Перезагрузка Nginx
systemctl restart nginx
systemctl enable nginx

# Установка SSL сертификата (Let's Encrypt)
echo ""
echo "🔒 Установка SSL сертификата (Let's Encrypt)..."
apt-get install -y certbot python3-certbot-nginx

# Автоматическое получение сертификата
certbot --nginx -d slotworker.ru -d www.slotworker.ru --non-interactive --agree-tos --email admin@slotworker.ru

echo ""
echo "========================================"
echo "  ✅ Сервер успешно настроен!"
echo "========================================"
echo ""
echo "📊 Информация о проекте:"
echo "  • Проект: /var/www/x5"
echo "  • Сервис: courier-app"
echo "  • URL: https://slotworker.ru"
echo "  • API: https://slotworker.ru/api/"
echo "  • БД: /var/www/x5/courier_applications.db"
echo ""
echo "📋 Полезные команды:"
echo "  • systemctl status courier-app          # Статус сервиса"
echo "  • systemctl logs courier-app            # Логи сервиса"
echo "  • sqlite3 /var/www/x5/courier_applications.db # Доступ к БД"
echo "  • nginx -t                              # Тест конфигурации Nginx"
echo ""
