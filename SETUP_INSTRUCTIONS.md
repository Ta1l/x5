# 🚀 ОДНА КОМАНДА ДЛЯ РАЗВЕРТЫВАНИЯ

## Скопируйте эту команду и выполните на сервере через SSH:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/quick-deploy.sh)
```

## ИЛИ выполните пошагово:

### 1️⃣  Подключитесь к серверу:
```bash
ssh root@62.217.182.74
# Введите пароль: *9w1Z*!R7WxH
```

### 2️⃣  Выполните эту команду для полного развертывания:

```bash
# Обновление системы
apt-get update && apt-get upgrade -y

# Установка Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs git build-essential curl wget

# Проверка версий
node -v && npm -v && git --version

# Клонирование проекта
mkdir -p /var/www && cd /var/www
git clone https://github.com/Ta1l/x5.git
cd x5

# Установка зависимостей
npm install --production

# Создание systemd сервиса
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

# Запуск сервиса
sudo chown -R www-data:www-data /var/www/x5
sudo chmod +x /var/www/x5/server.js
sudo systemctl daemon-reload
sudo systemctl start courier-app
sudo systemctl enable courier-app
sudo systemctl status courier-app

# Установка Nginx
apt-get install -y nginx

# Конфигурация Nginx
sudo tee /etc/nginx/sites-available/slotworker.ru > /dev/null <<'EOF'
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

# Активируем сайт
sudo ln -sf /etc/nginx/sites-available/slotworker.ru /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Проверяем конфиг
sudo nginx -t

# Перезагружаем Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx

# Установка SSL (Let's Encrypt)
apt-get install -y certbot python3-certbot-nginx

# Получение сертификата
sudo certbot --nginx \
  -d slotworker.ru \
  -d www.slotworker.ru \
  --non-interactive \
  --agree-tos \
  --email admin@slotworker.ru \
  --force-renewal 2>&1 | tail -20

echo ""
echo "✅ Развертывание завершено!"
echo ""
echo "📊 Проверка:"
echo "   curl http://localhost:3000/api/stats"
echo "   https://slotworker.ru"
echo ""
echo "🗄️  БД:"
echo "   sqlite3 /var/www/x5/courier_applications.db"
echo ""
```

---

## 📋 БЫСТРАЯ ПРОВЕРКА ПОСЛЕ РАЗВЕРТЫВАНИЯ

На сервере выполните:

```bash
# 1. Статус сервиса
systemctl status courier-app

# 2. Логи
sudo journalctl -u courier-app -n 50

# 3. Проверка API локально
curl http://localhost:3000/api/stats

# 4. Проверка БД
sqlite3 /var/www/x5/courier_applications.db "SELECT COUNT(*) as total FROM courier_applications;"

# 5. Проверка портов
sudo netstat -tlnp | grep -E '(3000|80|443)'

# 6. Проверка размера БД
du -sh /var/www/x5/courier_applications.db

# 7. Проверка места на диске
df -h /var/www
```

---

## ✅ ЧТО ДОЛЖНО РАБОТАТЬ

После всех команд:

✅ **http://62.217.182.74** - Должна открыться главная страница
✅ **https://slotworker.ru** - Должна открыться главная страница с SSL
✅ **https://slotworker.ru/api/stats** - Должен показать: `{"success":true,"count":0,"applications":[]}`
✅ **Форма** - Должна сохранять заявки в БД

---

## 🆘 ЕСЛИ ЧТО-ТО НЕ РАБОТАЕТ

### Node.js не запускается:
```bash
sudo journalctl -u courier-app -n 100 -f
```

### Nginx не работает:
```bash
sudo nginx -t
sudo tail -30 /var/log/nginx/error.log
```

### Порты не открыты:
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw enable
```

### SSL сертификат не получается:
```bash
sudo certbot renew --dry-run
sudo tail -30 /var/log/letsencrypt/letsencrypt.log
```

---

## 📞 ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ

**Проект хранится в:** `/var/www/x5`
**БД хранится в:** `/var/www/x5/courier_applications.db`
**Логи Node.js:** `sudo journalctl -u courier-app -f`
**Логи Nginx:** `/var/log/nginx/error.log`
**Конфиг Nginx:** `/etc/nginx/sites-available/slotworker.ru`

