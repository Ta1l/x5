# 📋 Развертывание проекта x5 на сервер

## ✅ Предусловия
- Доступ к серверу (62.217.182.74) с логином root и паролем *9w1Z*!R7WxH
- ОС: Ubuntu 20.04 / 22.04 или Debian 11+
- Домен slotworker.ru указан в DNS на этот IP
- Порты 80, 443, 3000 открыты

---

## 🚀 Шаг 1: Подключение к серверу

```bash
ssh root@62.217.182.74
# При запросе введите пароль: *9w1Z*!R7WxH
```

---

## 📦 Шаг 2: Обновление системы

```bash
apt-get update
apt-get upgrade -y
apt-get install -y curl wget git build-essential
```

---

## 🟢 Шаг 3: Установка Node.js 20.x

```bash
# Добавляем репозиторий NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Устанавливаем Node.js
apt-get install -y nodejs

# Проверяем версии
node -v
npm -v
git --version
```

---

## 📥 Шаг 4: Клонирование проекта с GitHub

```bash
# Создаем директорию для проектов
mkdir -p /var/www
cd /var/www

# Клонируем репозиторий
git clone https://github.com/Ta1l/x5.git
cd x5

# Проверяем что все файлы на месте
ls -la
```

---

## 📦 Шаг 5: Установка зависимостей NPM

```bash
npm install --production

# Проверяем что установились:
# - express
# - sqlite3
# - cors
# - body-parser

npm list
```

---

## ⚙️ Шаг 6: Создание systemd сервиса

```bash
# Создаем файл сервиса
sudo tee /etc/systemd/system/courier-app.service > /dev/null <<EOF
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

# Устанавливаем правильные права
sudo chown -R www-data:www-data /var/www/x5
sudo chmod +x /var/www/x5/server.js

# Перезагружаем systemd
sudo systemctl daemon-reload

# Запускаем сервис
sudo systemctl start courier-app
sudo systemctl enable courier-app

# Проверяем статус
sudo systemctl status courier-app
```

Вывод должен быть:
```
● courier-app.service - Courier App (Node.js + SQLite)
   Loaded: loaded (/etc/systemd/system/courier-app.service; enabled; vendor preset: enabled)
   Active: active (running) since ...
```

---

## 🌐 Шаг 7: Установка и настройка Nginx

```bash
# Устанавливаем Nginx
apt-get install -y nginx

# Создаем конфигурацию для вашего сайта
sudo tee /etc/nginx/sites-available/slotworker.ru > /dev/null <<'NGINX_EOF'
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
NGINX_EOF

# Активируем сайт
sudo ln -sf /etc/nginx/sites-available/slotworker.ru /etc/nginx/sites-enabled/

# Отключаем default сайт если активен
sudo rm -f /etc/nginx/sites-enabled/default

# Тестируем конфигурацию
sudo nginx -t

# Перезагружаем Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

---

## 🔒 Шаг 8: SSL сертификат Let's Encrypt

```bash
# Устанавливаем certbot
apt-get install -y certbot python3-certbot-nginx

# Получаем сертификат (заменить admin@slotworker.ru на ваш email)
sudo certbot --nginx \
  -d slotworker.ru \
  -d www.slotworker.ru \
  --non-interactive \
  --agree-tos \
  --email admin@slotworker.ru

# Проверяем что сертификат установлен
sudo certbot certificates

# Тестируем автоматическое обновление
sudo certbot renew --dry-run
```

---

## ✅ Шаг 9: Проверка работоспособности

### 9.1 Проверяем сервис Node.js
```bash
sudo systemctl status courier-app

# Смотрим логи
sudo journalctl -u courier-app -f

# Должны увидеть:
# ✅ Подключение к SQLite успешно
# ✅ Таблица готова
# 🚀 Сервер запущен успешно!
```

### 9.2 Проверяем что API работает локально на сервере
```bash
curl http://localhost:3000

# Должны получить HTML страницу

curl http://localhost:3000/api/stats

# Должны получить:
# {"success":true,"count":0,"applications":[]}
```

### 9.3 Проверяем Nginx
```bash
sudo nginx -t

# Должно быть:
# nginx: configuration test is successful
```

### 9.4 Посещаем сайт в браузере
```
http://62.217.182.74
https://slotworker.ru
https://www.slotworker.ru
```

---

## 📊 Шаг 10: Просмотр сохраненных заявок

```bash
# Подключаемся к БД SQLite
sqlite3 /var/www/x5/courier_applications.db

# Смотрим все заявки
SELECT * FROM courier_applications;

# Смотрим количество
SELECT COUNT(*) as total FROM courier_applications;

# Выход
.quit
```

Или через API:
```bash
curl https://slotworker.ru/api/applications
```

---

## 🛠️ Полезные команды управления

### Управление сервисом
```bash
# Статус
sudo systemctl status courier-app

# Перезагрузить
sudo systemctl restart courier-app

# Остановить
sudo systemctl stop courier-app

# Запустить
sudo systemctl start courier-app

# Логи
sudo journalctl -u courier-app -n 50 -f
```

### Управление Nginx
```bash
# Перезагрузить конфигурацию
sudo systemctl reload nginx

# Перезагрузить
sudo systemctl restart nginx

# Статус
sudo systemctl status nginx

# Логи
sudo tail -f /var/log/nginx/error.log
```

### Работа с БД
```bash
# Резервная копия БД
cp /var/www/x5/courier_applications.db /var/www/x5/backups/courier_applications_$(date +%Y%m%d_%H%M%S).db

# Удаление старых заявок (старше 30 дней)
sqlite3 /var/www/x5/courier_applications.db "DELETE FROM courier_applications WHERE created_at < datetime('now', '-30 days');"
```

### Свободное место на диске
```bash
df -h

# На /var/www должно быть достаточно места
# Проверяем размер проекта
du -sh /var/www/x5
```

---

## 🐛 Troubleshooting

### Проблема: "Connection refused" при посещении сайта
```bash
# Проверяем что сервис запущен
sudo systemctl status courier-app

# Проверяем что Nginx работает
sudo systemctl status nginx

# Проверяем логи Node.js
sudo journalctl -u courier-app -n 20

# Проверяем что порт 3000 слушается
sudo netstat -tlnp | grep 3000
# или
sudo ss -tlnp | grep 3000
```

### Проблема: Nginx не может подключиться к Node.js
```bash
# Проверяем что localhost:3000 доступен
curl http://127.0.0.1:3000

# Проверяем конфигурацию Nginx
sudo nginx -T

# Смотрим ошибки Nginx
sudo tail -30 /var/log/nginx/error.log
```

### Проблема: Заявки не сохраняются
```bash
# Проверяем права доступа на БД
ls -la /var/www/x5/courier_applications.db

# Должны видеть www-data:www-data

# Если неправильно, исправляем:
sudo chown www-data:www-data /var/www/x5/courier_applications.db
sudo chmod 644 /var/www/x5/courier_applications.db

# Проверяем что таблица существует
sqlite3 /var/www/x5/courier_applications.db ".schema"
```

### Проблема: SSL сертификат не установился
```bash
# Проверяем статус certbot
sudo certbot status

# Смотрим логи certbot
cat /var/log/letsencrypt/letsencrypt.log

# Пытаемся получить сертификат заново
sudo certbot --nginx -d slotworker.ru -d www.slotworker.ru --force-renewal
```

---

## 📈 Мониторинг и обслуживание

### Ежедневная проверка
```bash
# Статус всех сервисов
sudo systemctl status courier-app nginx

# Свободное место
df -h

# Размер БД
du -sh /var/www/x5/courier_applications.db
```

### Ежемесячная проверка
```bash
# Резервная копия
sudo cp /var/www/x5/courier_applications.db /backup/courier_db_$(date +%Y%m%d).db

# Обновление системы
sudo apt-get update
sudo apt-get upgrade -y
```

### Логирование
```bash
# Включить более подробное логирование в server.js
# Отредактируй /var/www/x5/server.js и добавь логирование

# Смотри логи в реальном времени
sudo journalctl -u courier-app -f
```

---

## 🎯 Проверка установки

После выполнения всех шагов, проверьте:

✅ Доступ по HTTPS: https://slotworker.ru
✅ Форма загружается
✅ Заполните форму и отправьте заявку
✅ Заявка появляется в БД: 
   ```bash
   sqlite3 /var/www/x5/courier_applications.db "SELECT * FROM courier_applications;"
   ```
✅ Проверьте в браузере: https://slotworker.ru/api/stats (должно показать количество заявок)

---

## 📞 Вопросы?

Если что-то не работает, проверьте:
1. Логи: `sudo journalctl -u courier-app -n 100`
2. Конфигурацию: `sudo nginx -T`
3. Доступность портов: `sudo ss -tlnp`
4. Размер диска: `df -h`
5. Память: `free -h`

