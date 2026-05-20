# ⚠️ ИНСТРУКЦИЯ K РУЧНОМУ РАЗВЕРТЫВАНИЮ НА СЕРВЕРЕ

## 🔴 ПРОБЛЕМА
Автоматическое развертывание через SSH не сработало из-за блокировки доступа.  
**Решение:** Подключитесь к серверу вручную и выполните команды ниже.

---

## 📝 ПОШАГОВАЯ ИНСТРУКЦИЯ

### Шаг 1️⃣: Подключиться к серверу

```bash
# Через консоль VPS панели или через SSH с другой машины:
ssh root@62.217.182.74
# Пароль: *9w1Z*!R7WxH

# ИЛИ через прокси (если требуется):
ssh -o ProxyCommand="nc -X 5 -x 6NeZMV:iSxcP9mEj0@46.8.17.103:5501 %h %p" root@62.217.182.74
```

### Шаг 2️⃣: Выполнить одну команду (все автоматически)

**На сервере выполните:**

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/deploy-full-domain.sh)
```

Это выполнит полное развертывание (~10 минут):
- ✅ Обновление системы
- ✅ Установка Node.js 20
- ✅ Установка Nginx
- ✅ Получение SSL сертификатов
- ✅ Подготовка приложения
- ✅ Проверка всех компонентов

---

## ✅ ПРОВЕРКА ГОТОВНОСТИ (после развертывания)

### На сервере выполните:

```bash
# Полная диагностика
bash /var/www/x5/server-diagnostic.sh

# Должны быть ВСЕ зеленые галочки ✅
```

### В браузере откройте:

```
https://slotworker.ru/
https://www.slotworker.ru/
https://slotworker.ru/api/stats
```

---

## 🔧 ЕСЛИ ЧТО-ТО НЕ РАБОТАЕТ

### В ПРОЦЕССЕ РАЗВЕРТЫВАНИЯ

Если скрипт выдает ошибку, проверьте промежуточные шаги вручную:

```bash
# 1. Проверить что Node.js установлен
node -v
npm -v

# 2. Проверить что проект клонирован
ls -la /var/www/x5/

# 3. Проверить что сервис запущен
sudo systemctl status courier-app

# 4. Проверить что Nginx запущен
sudo systemctl status nginx

# 5. Проверить логи ошибок
sudo journalctl -u courier-app -n 50
sudo tail -50 /var/log/nginx/error.log
```

### ЕСЛИ ПОРТЫ НЕ ОТКРЫТЫ

```bash
# Проверить портов
sudo ss -tlnp | grep -E ":80|:443|:3000"

# Если firewall блокирует:
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw reload
```

### ЕСЛИ SSL СЕРТИФИКАТ НЕ ПОЛУЧЕН

```bash
# Переполучить сертификат вручную
sudo certbot --nginx -d slotworker.ru -d www.slotworker.ru --force-renewal

# Перезагрузить Nginx
sudo systemctl reload nginx
```

### ЕСЛИ ФОРМА НЕ СОХРАНЯЕТ ДАННЫЕ

```bash
# Проверить что БД существует
ls -la /var/www/x5/courier_applications.db

# Проверить права
sudo chown root:root /var/www/x5/courier_applications.db
sudo chmod 644 /var/www/x5/courier_applications.db

# Перезагрузить приложение
sudo systemctl restart courier-app
```

---

## 📊 ПОЛНЫЙ ЧЕКЛИСТ

Если скрипт не работает - выполните шаги вручную:

### Обновление системы
```bash
apt-get update -qq
apt-get upgrade -y -qq
```

### Установка Node.js
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
node -v && npm -v
```

### Подготовка проекта
```bash
mkdir -p /var/www
cd /var/www
git clone https://github.com/Ta1l/x5.git
cd x5
npm install --production
```

### Создание systemd сервиса
```bash
sudo tee /etc/systemd/system/courier-app.service > /dev/null <<'EOF'
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

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start courier-app
sudo systemctl enable courier-app
sudo systemctl status courier-app
```

### Установка Nginx
```bash
apt-get install -y nginx
```

### Конфигурация Nginx
```bash
sudo tee /etc/nginx/sites-available/slotworker.ru > /dev/null <<'EOF'
server {
    listen 80;
    server_name slotworker.ru www.slotworker.ru;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name slotworker.ru www.slotworker.ru;

    ssl_certificate /etc/letsencrypt/live/slotworker.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/slotworker.ru/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/slotworker.ru /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Получение SSL сертификатов
```bash
apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d slotworker.ru -d www.slotworker.ru --non-interactive --agree-tos --email admin@slotworker.ru
sudo systemctl reload nginx
```

---

## 📞 ИТОГОВЫЙ СТАТУС

Когда все выполнено, сайт будет доступен по адресу:

✅ **https://slotworker.ru**  
✅ **https://www.slotworker.ru**  
✅ **https://slotworker.ru/api/stats**

---

## 🚨 ЕСЛИ НИЧЕГО НЕ ПОМОГАЕТ

Свяжитесь с хостером и попросите:
1. Проверить что порты 80, 443, 3000, 22 открыты
2. Проверить DNS записи указывают на 62.217.182.74
3. Предоставить доступ через консоль VPS если SSH блокирован

---

**Комплексное руководство:** [DOMAIN_DEPLOYMENT.md](DOMAIN_DEPLOYMENT.md)  
**Все скрипты:** https://github.com/Ta1l/x5  
**Главный скрипт:** https://raw.githubusercontent.com/Ta1l/x5/main/deploy-full-domain.sh
