# ✅ КОМПЛЕКСНЫЙ ЧЕКЛИСТ РАЗВЕРТЫВАНИЯ slotworker.ru

**Дата:** 20.05.2026  
**Статус:** 🔍 ПРОВЕРКА И НАСТРОЙКА  
**Цель:** Сайт должен быть доступен по адресу https://slotworker.ru

---

## 📋 ПРЕДВАРИТЕЛЬНАЯ ПРОВЕРКА

### 1️⃣ DNS НАСТРОЙКА

**Проверить что DNS правильно указана:**

```bash
# На локальной машине проверь:
nslookup slotworker.ru
# Должно показать: 62.217.182.74

# Или через dig:
dig slotworker.ru
# Должен быть A запись на 62.217.182.74
```

**Если DNS не настроена:**
- Перейди к регистратору домена
- Добавь A запись:
  - Имя: `slotworker.ru`
  - Значение: `62.217.182.74`
  - TTL: 3600 (или default)
- Также добавь для www:
  - Имя: `www.slotworker.ru`
  - Значение: `62.217.182.74`
  - TTL: 3600

**Дождись обновления DNS (5-24 часа)**

---

## 🔧 ПРОВЕРКА СЕРВЕРА

### 2️⃣ ПОДКЛЮЧЕНИЕ И ОСНОВНЫЕ ПРОВЕРКИ

**Подключиться к серверу:**
```bash
ssh root@62.217.182.74
# Пароль: *9w1Z*!R7WxH
```

**Проверить что система доступна:**
```bash
whoami                          # Должно вывести: root
hostname                        # Должно вывести: имя хоста
uname -a                        # Информация о ОС
```

**Проверить интернет соединение:**
```bash
ping 8.8.8.8 -c 5             # Google DNS
curl -I https://www.google.com # Проверить HTTPS
```

---

### 3️⃣ ПРОВЕРКА ПРОЕКТА

**Проверить что проект клонирован:**
```bash
ls -la /var/www/
# Должна быть папка x5

ls -la /var/www/x5/
# Должны быть: index.html, server.js, package.json, courier_applications.db
```

**Если проекта нет - клонируем:**
```bash
mkdir -p /var/www
cd /var/www
git clone https://github.com/Ta1l/x5.git
cd x5
npm install --production
```

---

### 4️⃣ ПРОВЕРКА NODE.JS

**Проверить что Node.js установлен:**
```bash
node -v                        # Должно быть v20+
npm -v                         # Должно быть 10+
npm list --depth=0             # Список зависимостей
```

**Если Node.js не установлен:**
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs
node -v && npm -v
```

---

### 5️⃣ ПРОВЕРКА SYSTEMD СЕРВИСА

**Проверить статус сервиса:**
```bash
sudo systemctl status courier-app
# Должно быть: active (running)

# Если не запущен:
sudo systemctl start courier-app
sudo systemctl enable courier-app
sudo systemctl status courier-app

# Проверить логи:
sudo journalctl -u courier-app -n 20
```

**Проверить что порт 3000 слушается:**
```bash
sudo ss -tlnp | grep 3000
# Или альтернативно:
sudo netstat -tlnp 2>/dev/null | grep 3000

# Должны видеть: node ... 0.0.0.0:3000
```

**Тестировать API локально:**
```bash
curl http://localhost:3000/
# Должен вернуть HTML страницу

curl http://localhost:3000/api/stats
# Должен вернуть JSON
```

---

### 6️⃣ ПРОВЕРКА NGINX

**Проверить что Nginx установлен:**
```bash
nginx -v                       # Должно быть nginx/1.x
```

**Если Nginx не установлен:**
```bash
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
```

**Проверить конфигурацию:**
```bash
sudo nginx -t
# Должно быть: nginx: configuration test is successful
```

**Проверить что сайт включен:**
```bash
ls -la /etc/nginx/sites-enabled/
# Должна быть ссылка на slotworker.ru

# Если нет:
sudo ln -sf /etc/nginx/sites-available/slotworker.ru /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

**Содержимое конфигурации:**
```bash
cat /etc/nginx/sites-available/slotworker.ru
# Проверить что указаны правильные вверх и домены
```

**Если конфиг неправильный - создать его:**
```bash
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
}
EOF

sudo ln -sf /etc/nginx/sites-available/slotworker.ru /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

**Проверить статус Nginx:**
```bash
sudo systemctl status nginx
# Должно быть: active (running)

# Проверить что слушает на портах 80 и 443:
sudo ss -tlnp | grep nginx
```

**Проверить логи Nginx:**
```bash
sudo tail -50 /var/log/nginx/access.log
sudo tail -50 /var/log/nginx/error.log
```

---

### 7️⃣ ПРОВЕРКА SSL СЕРТИФИКАТА

**Проверить что certbot установлен:**
```bash
certbot --version
# Должно быть: certbot 2.x или выше

# Если не установлен:
apt-get install -y certbot python3-certbot-nginx
```

**Проверить существующие сертификаты:**
```bash
sudo certbot certificates
# Должны быть сертификаты для slotworker.ru и www.slotworker.ru
```

**Если сертификатов нет - получить их:**
```bash
sudo certbot --nginx \
  -d slotworker.ru \
  -d www.slotworker.ru \
  --non-interactive \
  --agree-tos \
  --email admin@slotworker.ru \
  --force-renewal
```

**Проверить что HTTPS работает:**
```bash
# На локальной машине:
curl -I https://slotworker.ru
# Должно быть: HTTP/2 200 OK и других ошибок безопасности

# Проверить сертификат:
openssl s_client -connect slotworker.ru:443 -servername slotworker.ru < /dev/null
```

**Проверить что HTTP перенаправляет на HTTPS:**
```bash
# Должна быть редирект на HTTPS
curl -I http://slotworker.ru
# Должен быть: 301 или 302 на https://slotworker.ru
```

---

### 8️⃣ ПРОВЕРКА ПОРТОВ И FIREWALL

**Проверить что порты открыты:**
```bash
# HTTP
sudo ss -tlnp | grep :80
# Должен быть nginx

# HTTPS  
sudo ss -tlnp | grep :443
# Должен быть nginx

# Node.js
sudo ss -tlnp | grep :3000
# Должен быть node
```

**Если используется UFW (firewall):**
```bash
sudo ufw status
# Если активен:
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw reload
```

---

### 9️⃣ ФИНАЛЬНАЯ ПРОВЕРКА

**Тестирование по HTTP:**
```bash
curl -I http://slotworker.ru
# Должно быть перенаправление на HTTPS
```

**Тестирование по HTTPS:**
```bash
curl -I https://slotworker.ru
# Должно быть: HTTP/2 200 OK

curl https://slotworker.ru | head -20
# Должен быть HTML код
```

**Проверка API:**
```bash
curl https://slotworker.ru/api/stats
# Должен быть JSON ответ
```

**Проверка www:**
```bash
curl -I https://www.slotworker.ru
# Должно работать также как без www
```

---

## 🌍 ЛОКАЛЬНАЯ ПРОВЕРКА (с вашей машины)

### В браузере:

1. **HTTP версия:**
   ```
   http://slotworker.ru
   ```
   Должено перенаправить на HTTPS

2. **HTTPS версия:**
   ```
   https://slotworker.ru
   ```
   Должна открыться страница с зеленым замком 🔒

3. **WWW версия:**
   ```
   https://www.slotworker.ru
   ```
   Должна работать так же

4. **API статистика:**
   ```
   https://slotworker.ru/api/stats
   ```
   Должен показать JSON с количеством заявок

### Функциональные тесты:

1. Заполнить форму
2. Отправить заявку
3. Увидеть сообщение об успехе
4. Проверить что данные в БД

---

## 🐛 РЕШЕНИЕ ПРОБЛЕМ

### Проблема: "Connection refused" или "Site can't be reached"

**Шаги решения:**

```bash
# 1. Проверить что Node.js приложение запущено
sudo systemctl status courier-app
sudo journalctl -u courier-app -n 50

# 2. Проверить что Nginx запущен
sudo systemctl status nginx
sudo nginx -t

# 3. Проверить что порты прослушиваются
sudo ss -tlnp

# 4. Проверить логи Nginx
sudo tail -100 /var/log/nginx/error.log

# 5. Если все плохо - перезагрузить все
sudo systemctl restart courier-app
sudo systemctl restart nginx
```

### Проблема: "SSL certificate problem" или "CERTIFICATE_VERIFY_FAILED"

```bash
# Переполучить сертификат:
sudo certbot --nginx -d slotworker.ru -d www.slotworker.ru --force-renewal

# Проверить что сертификат валиден:
sudo certbot certificates

# Если не помогает:
sudo certbot delete --cert-name slotworker.ru
sudo certbot --nginx -d slotworker.ru -d www.slotworker.ru --non-interactive --agree-tos --email admin@slotworker.ru
```

### Проблема: "DNS resolution failed" или "ERR_NAME_NOT_RESOLVED"

```bash
# На сервере проверить DNS:
nslookup slotworker.ru 8.8.8.8
dig slotworker.ru @8.8.8.8

# Если DNS не работает:
# 1. Проверить регистратор домена
# 2. Дождаться пропагации DNS (5-24 часа)
# 3. Очистить кеш браузера (Ctrl+Shift+Del)
# 4. Проверить с другого браузера или машины
```

### Проблема: "504 Gateway Timeout" или "502 Bad Gateway"

```bash
# 1. Проверить что Node.js слушает на локальном хосте
lsof -i :3000
sudo ss -tlnp | grep 3000

# 2. Проверить что Node.js приложение отвечает
curl http://localhost:3000/

# 3. Проверить конфигурацию Nginx proxy
cat /etc/nginx/sites-available/slotworker.ru | grep proxy_pass

# 4. Перезагрузить приложение
sudo systemctl restart courier-app
sleep 2
curl http://localhost:3000/
```

### Проблема: "Форма не сохраняет заявки"

```bash
# 1. Проверить что БД существует
ls -la /var/www/x5/courier_applications.db

# 2. Проверить права на БД
ls -la /var/www/x5/ | grep courier

# 3. Исправить права если нужно
sudo chown www-data:www-data /var/www/x5/courier_applications.db
sudo chmod 644 /var/www/x5/courier_applications.db

# 4. Проверить логи
sudo journalctl -u courier-app -f

# 5. Перезагрузить
sudo systemctl restart courier-app
```

---

## ✅ ПОЛНЫЙ ЧЕКЛИСТ ГОТОВНОСТИ

Перед тем как заявить что сайт готов проверьте все пункты:

### Сервер
- [ ] SSH подключение работает
- [ ] Node.js установлен (v20+)
- [ ] Проект клонирован в `/var/www/x5`
- [ ] npm install выполнен
- [ ] Systemd сервис создан и запущен
- [ ] Nginx установлен и запущен

### DNS и Домен
- [ ] DNS запись указывает на 62.217.182.74
- [ ] `nslookup slotworker.ru` показывает 62.217.182.74
- [ ] Прошло достаточно времени для пропагации DNS

### Портов и Firewall
- [ ] Порт 80 открыт на Nginx
- [ ] Порт 443 открыт на Nginx
- [ ] Порт 3000 открыт на Node.js (локально)
- [ ] Firewall не блокирует эти порты

### Конфигурация
- [ ] `/etc/nginx/sites-available/slotworker.ru` существует
- [ ] Nginx конфиг указывает на localhost:3000
- [ ] SSL сертификаты получены от Let's Encrypt
- [ ] HTTPS работает

### Функциональность
- [ ] `https://slotworker.ru` открывается
- [ ] `https://www.slotworker.ru` открывается
- [ ] `http://slotworker.ru` перенаправляет на HTTPS
- [ ] API статистика работает
- [ ] Форма отправляется
- [ ] Заявки сохраняются в БД

### Производство
- [ ] Логи проверены (нет ошибок)
- [ ] Сертификат валиден (не истекает вскоре)
- [ ] Производительность нормальная
- [ ] Резервная копия БД сделана

---

## 📞 ЕСЛИ ЧТО-ТО НЕ РАБОТАЕТ

**Выполни эти команды на сервере:**

```bash
# Полная диагностика
echo "=== СИСТЕМНАЯ ИНФОРМАЦИЯ ==="
whoami && hostname && uname -a

echo "=== NODE.JS ==="
node -v && npm -v

echo "=== СТАТУС СЕРВИСА ==="
sudo systemctl status courier-app --no-pager

echo "=== ЛОГИ ПРИЛОЖЕНИЯ ==="
sudo journalctl -u courier-app -n 30

echo "=== ПОРТОВ ==="
sudo ss -tlnp

echo "=== NGINX ==="
sudo systemctl status nginx --no-pager
sudo nginx -t

echo "=== DNS ==="
nslookup slotworker.ru

echo "=== ТЕСТИРОВАНИЕ ==="
curl -I http://localhost:3000
curl -I http://slotworker.ru
```

Скопируй результаты и пришли их мне для диагностики.

---

## 🎯 ИТОГ

Если все пройдено - сайт готов!

**Адреса доступа:**
- ✅ https://slotworker.ru
- ✅ https://www.slotworker.ru
- ✅ https://slotworker.ru/api/stats

**Результат:**
- ✅ Домен работает
- ✅ Форма сохраняет заявки
- ✅ HTTPS защищен
- ✅ Production ready

