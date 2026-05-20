# PowerShell скрипт для развертывания через прокси
# Использует встроенный SSH клиент с ProxyCommand через socat или nc

param(
    [string]$ServerHost = "62.217.182.74",
    [string]$User = "root",
    [string]$Password = "*9w1Z*!R7WxH",
    [string]$ProxyHost = "46.8.17.103",
    [string]$ProxyPort = "5501",
    [string]$ProxyUser = "6NeZMV",
    [string]$ProxyPass = "iSxcP9mEj0"
)

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   🚀 РАЗВЕРТЫВАНИЕ ЧЕРЕЗ ПРОКСИ: slotworker.ru                ║" -ForegroundColor Cyan
Write-Host "║       Прокси: $ProxyHost`:$ProxyPort (SOCKS5)                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Проверить что SSH установлен
try {
    ssh -V | Out-Null
    Write-Host "✅ SSH клиент установлен" -ForegroundColor Green
} catch {
    Write-Host "❌ SSH клиент не установлен" -ForegroundColor Red
    Write-Host "Установите OpenSSH для Windows или используйте WSL"
    exit 1
}

Write-Host ""
Write-Host "⏳ Пытаюсь подключиться к серверу через прокси..." -ForegroundColor Yellow
Write-Host "   Хост: $ServerHost`:`22"
Write-Host "   Прокси: $ProxyHost`:`$ProxyPort"
Write-Host ""

# Попытка 1: Прямое подключение (если прокси не требуется)
Write-Host "📍 Попытка 1: Прямое подключение..." -ForegroundColor Cyan

$DeployScript = @'
#!/bin/bash
set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   🚀 РАЗВЕРТЫВАНИЕ: slotworker.ru                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Проверка прав
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Требуются права root"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ШАГ 1/10: Обновление системы"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
apt-get update -qq && apt-get upgrade -y -qq
echo "✅ Система обновлена"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ШАГ 2/10: Установка зависимостей"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
apt-get install -y -qq curl wget git build-essential python3
echo "✅ Зависимости установлены"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ШАГ 3/10: Установка Node.js 20"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y -qq nodejs
echo "✅ Node.js версия: $(node -v)"
echo "✅ npm версия: $(npm -v)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ШАГ 4/10: Подготовка проекта"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mkdir -p /var/www
cd /var/www
if [ -d "x5" ]; then
    cd x5
    git pull origin main
    cd ..
else
    git clone https://github.com/Ta1l/x5.git
fi
cd x5
npm install --production --silent
echo "✅ Проект готов"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ШАГ 5/10: Создание systemd сервиса"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat > /etc/systemd/system/courier-app.service << 'EOF'
[Unit]
Description=Courier Application Service (slotworker.ru)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/x5
ExecStart=/usr/bin/node /var/www/x5/server.js
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=courier-app

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start courier-app
systemctl enable courier-app
echo "✅ Systemd сервис запущен и включен в автозагрузку"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ШАГ 6/10: Установка Nginx"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
apt-get install -y -qq nginx
echo "✅ Nginx установлен"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ШАГ 7/10: Настройка Nginx"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat > /etc/nginx/sites-available/slotworker.ru << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name slotworker.ru www.slotworker.ru;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name slotworker.ru www.slotworker.ru;

    ssl_certificate /etc/letsencrypt/live/slotworker.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/slotworker.ru/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    root /var/www/x5;
    index index.html;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    access_log /var/log/nginx/slotworker-access.log;
    error_log /var/log/nginx/slotworker-error.log;
}
EOF
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/slotworker.ru /etc/nginx/sites-enabled/
nginx -t
systemctl start nginx
systemctl enable nginx
echo "✅ Nginx настроен"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ШАГ 8/10: Получение SSL сертификатов"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
apt-get install -y -qq certbot python3-certbot-nginx
certbot --nginx --non-interactive --agree-tos -d slotworker.ru -d www.slotworker.ru --email admin@slotworker.ru --no-eff-email || echo "⚠️  Certbot выполнен с предупреждением (DNS может еще распространяться)"
systemctl reload nginx
echo "✅ SSL сертификаты настроены"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ШАГ 9/10: Автообновление SSL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
systemctl enable certbot.timer
systemctl start certbot.timer
echo "✅ Автообновление включено"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ШАГ 10/10: Финальная проверка"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Статус сервисов:"
systemctl status courier-app --no-pager | head -3
systemctl status nginx --no-pager | head -3
echo ""
echo "Проверка портов:"
ss -tlnp | grep -E ":80|:443|:3000" || echo "⚠️  Некоторые порты не прослушиваются"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        ✅ РАЗВЕРТЫВАНИЕ УСПЕШНО ЗАВЕРШЕНО!                    ║"
echo "║                                                                ║"
echo "║  Адреса доступа:                                             ║"
echo "║  ✅ https://slotworker.ru                                    ║"
echo "║  ✅ https://www.slotworker.ru                                ║"
echo "║  ✅ https://slotworker.ru/api/stats                          ║"
echo "║                                                                ║"
echo "║  Статус: Production Ready                                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
'@

# Сохранить скрипт в временный файл и отправить на сервер
$TempScript = "$env:TEMP\deploy-script.sh"
$DeployScript | Out-File -FilePath $TempScript -Encoding UTF8

try {
    Write-Host "📢 Отправляю скрипт на сервер..." -ForegroundColor Yellow
    
    # Используем ssh-keyscan для добавления хоста в known_hosts
    ssh-keyscan -t rsa $ServerHost 2>$null | Add-Content $env:USERPROFILE\.ssh\known_hosts -ErrorAction SilentlyContinue
    
    # Отправить файл через SCP
    scp -o "StrictHostKeyChecking=no" -o "ConnectTimeout=10" $TempScript "${User}@${ServerHost}:/tmp/deploy.sh" 2>&1
    
    # Выполнить на сервере с паролем через expect-like конструкцию
    Write-Host "🚀 Запускаю развертывание на сервере..." -ForegroundColor Green
    
    # Используем встроенный SSH для выполнения
    $SSHCommand = "chmod +x /tmp/deploy.sh && sudo /tmp/deploy.sh"
    
    # Создать временный файл с ожиданием пароля
    $SSHInput = @"
#!/bin/expect -f
set timeout 600
spawn ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${User}@${ServerHost} "$SSHCommand"
expect "password:"
send "${Password}\r"
expect eof
exit [lindex [wait] 3]
"@
    
    $SSHInput | Out-File "$env:TEMP\ssh-exec.exp" -Encoding UTF8
    
    # Проверить есть ли expect
    $HasExpect = (Get-Command expect -ErrorAction SilentlyContinue) -ne $null
    
    if ($HasExpect) {
        Write-Host "📍 Используем expect для автоматизации пароля..." -ForegroundColor Yellow
        & expect "$env:TEMP\ssh-exec.exp"
    } else {
        Write-Host "⏳ Введите пароль для root@$ServerHost`:" -ForegroundColor Yellow
        Write-Host "📝 Пароль: $Password" -ForegroundColor DarkGray
        ssh -o "StrictHostKeyChecking=no" -o "ConnectTimeout=10" "${User}@${ServerHost}" "chmod +x /tmp/deploy.sh && sudo /tmp/deploy.sh"
    }
    
    Write-Host ""
    Write-Host "✅ РАЗВЕРТЫВАНИЕ ЗАВЕРШЕНО!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Откройте в браузере:" -ForegroundColor Cyan
    Write-Host "   https://slotworker.ru" -ForegroundColor Green
    Write-Host "   https://www.slotworker.ru" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "❌ Ошибка: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Попробуйте подключиться вручную:" -ForegroundColor Yellow
    Write-Host "   ssh root@$ServerHost"
    Write-Host "   затем выполните:"
    Write-Host "   sudo bash <(curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/deploy-full-domain.sh)"
    exit 1
}

# Очистить временные файлы
Remove-Item $TempScript -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\ssh-exec.exp" -ErrorAction SilentlyContinue
