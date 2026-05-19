# Deploy x5 on Windows using PowerShell

# Данные для подключения
$ServerHost = "62.217.182.74"  
$ServerUser = "root"
$ServerPass = "*9w1Z*!R7WxH"

Write-Host ""
Write-Host "============================================"
Write-Host "  🚀 Развертывание x5 через SSH"
Write-Host "============================================"
Write-Host ""

Write-Host "[1] 🔐 Подготовка подключения..."
Write-Host ""

$cmd = @"
# На сервере выполните эти команды:

set -e

echo "📦 Обновление системы..."
apt-get update -qq && apt-get upgrade -y -qq

echo "🟢 Установка Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs git build-essential curl wget -qq

echo "📥 Клонирование проекта..."
mkdir -p /var/www && cd /var/www
rm -rf x5 2>/dev/null || true
git clone https://github.com/Ta1l/x5.git
cd x5

echo "📦 Установка зависимостей npm..."
npm install --production --silent

echo "⚙️  Создание systemd сервиса..."
sudo tee /etc/systemd/system/courier-app.service > /dev/null <<'EOF'
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

sudo chown -R www-data:www-data /var/www/x5
sudo chmod +x /var/www/x5/server.js
sudo systemctl daemon-reload
sudo systemctl start courier-app
sudo systemctl enable courier-app

echo "✅ Сервис запущен"

echo "🌐 Установка Nginx..."
apt-get install -y nginx -qq

sudo tee /etc/nginx/sites-available/slotworker.ru > /dev/null <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name slotworker.ru www.slotworker.ru;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
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

sudo ln -sf /etc/nginx/sites-available/slotworker.ru /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "✅ Nginx настроен"

echo "🔒 Установка SSL..."
apt-get install -y certbot python3-certbot-nginx -qq

sudo certbot --nginx \
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
echo "🌐 Адреса:"
echo "   https://slotworker.ru"
echo "   https://www.slotworker.ru"
echo ""
echo "📊 API:"
echo "   https://slotworker.ru/api/stats"
echo ""
"@

Write-Host "[2] 📋 Инструкции:"
Write-Host ""
Write-Host "Выберите один из способов:"
Write-Host ""
Write-Host "[1] Самый быстрый способ (рекомендуется):"
Write-Host "    Подключитесь к серверу и выполните:"
Write-Host "    bash <(curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/quick-deploy.sh)"
Write-Host ""
Write-Host "[2] Интерактивный SSH (Microsoft Windows 10+):"
Write-Host "    ssh.exe root@$ServerHost"
Write-Host "    # Введите пароль: $ServerPass"
Write-Host "    # Затем вставьте команды из меню [3]"
Write-Host ""
Write-Host "[3] Все команды для вставки:"
Write-Host ""

# Выводим команды в буфер обмена (Windows)
$cmd | Set-Clipboard
Write-Host "✅ Команды скопированы в буфер обмена!"
Write-Host ""
Write-Host "Вы можете теперь:"
Write-Host "1. Открыть Terminal/PowerShell/CMD"
Write-Host "2. Выполнить: ssh root@$ServerHost"
Write-Host "3. Вставить скопированные команды"
Write-Host ""

Write-Host "======================================"
Write-Host "  📖 Смотрите остальную документацию:"
Write-Host "======================================"
Write-Host ""
Write-Host "- README.md (основные сведения)"
Write-Host "- SETUP_INSTRUCTIONS.md (пошаговые инструкции)"
Write-Host "- DEPLOYMENT_GUIDE.md (полный гайд)"
Write-Host "- DEPLOYMENT_CHECKLIST.md (финальный чеклист)"
Write-Host ""

Write-Host "Нажмите Enter для завершения..."
Read-Host
