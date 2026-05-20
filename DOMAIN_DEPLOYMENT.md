# 🌍 ПОЛНОЕ РУКОВОДСТВО ПО РАЗВЕРТЫВАНИЮ НА ДОМЕНЕ slotworker.ru

**Дата обновления:** 20.05.2026  
**Статус:** ✅ ПОЛНОСТЬЮ ГОТОВО К РАЗВЕРТЫВАНИЮ

---

## 📋 ТАБДИЦА СОДЕРЖАНИЯ

1. [Предварительные проверки](#предварительные-проверки)
2. [Шаг за шагом развертывание](#шаг-за-шагом-развертывание)
3. [Проверка работоспособности](#проверка-работоспособности)
4. [Решение проблем](#решение-проблем)
5. [Файлы для развертывания](#файлы-для-развертывания)

---

## 🔍 ПРЕДВАРИТЕЛЬНЫЕ ПРОВЕРКИ

### ✅ ЧТО УЖЕ ГОТОВО

- ✅ Проект на GitHub: https://github.com/Ta1l/x5
- ✅ Node.js приложение протестировано
- ✅ SQLite база данных создана
- ✅ Все документация написана
- ✅ Скрипты развертывания готовы

### 📝 ЧТО НУЖНО ПРОВЕРИТЬ

Перед запуском развертывания убедитесь что:

1. **DNS настроена правильно:**
   ```bash
   # На локальной машине выполните:
   nslookup slotworker.ru
   
   # Должно показать IP: 62.217.182.74
   ```
   
   Если DNS не настроена:
   - Перейдите к регистратору домена (где вы покупали домен)
   - Создайте A запись:
     - Имя: `slotworker.ru`
     - Тип: `A`
     - Значение: `62.217.182.74`
     - TTL: `3600`
   - Создайте вторую A запись для www:
     - Имя: `www.slotworker.ru`
     - Тип: `A`
     - Значение: `62.217.182.74`
     - TTL: `3600`

2. **Сервер доступен по SSH:**
   ```bash
   ssh root@62.217.182.74
   # Пароль: *9w1Z*!R7WxH
   ```
   
   Если не подключается через direct SSH, используйте прокси:
   ```bash
   ssh -o ProxyCommand='nc -X 5 -x 6NeZMV:iSxcP9mEj0@46.8.17.103:5501 %h %p' root@62.217.182.74
   ```

3. **Портов 80 и 443 открыты:**
   ```bash
   # На сервере выполните:
   sudo nc -zv 62.217.182.74 80
   sudo nc -zv 62.217.182.74 443
   
   # Должны быть: "succeeded" или "open"
   ```

4. **Интернет на сервере работает:**
   ```bash
   # На сервере:
   ping 8.8.8.8 -c 5
   curl -I https://www.google.com
   ```

---

## 🚀 ШАГ ЗА ШАГОМ РАЗВЕРТЫВАНИЕ

### СПОСОБ 1️⃣: АВТОМАТИЧЕСКОЕ РАЗВЕРТЫВАНИЕ (РЕКОМЕНДУЕТСЯ)

**На сервере выполните одну команду:**

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/deploy-full-domain.sh)
```

Скрипт автоматически выполнит:
1. ✅ Обновление системы
2. ✅ Установку Node.js 20
3. ✅ Установку npm зависимостей
4. ✅ Создание systemd сервиса
5. ✅ Установку Nginx
6. ✅ Настройку SSL сертификатов Let's Encrypt
7. ✅ Автоматическое обновление сертификатов
8. ✅ Настройку перенаправлений

**Время выполнения:** ~5-10 минут

**Результат:** Автоматический вывод статуса всех компонентов

---

### СПОСОБ 2️⃣: ПОШАГОВОЕ РАЗВЕРТЫВАНИЕ (ДЛЯ ОПЫТНЫХ)

Если вы предпочитаете контролировать каждый шаг:

#### Шаг 1: Подключение к серверу
```bash
ssh root@62.217.182.74
# Пароль: *9w1Z*!R7WxH
```

#### Шаг 2: Обновление системы
```bash
apt-get update && apt-get upgrade -y
```

#### Шаг 3: Установка Node.js
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs
node -v && npm -v
```

#### Шаг 4: Установка и подготовка проекта
```bash
cd /var/www
git clone https://github.com/Ta1l/x5.git
cd x5
npm install --production
```

#### Шаг 5: Создание systemd сервиса
```bash
sudo tee /etc/systemd/system/courier-app.service > /dev/null <<EOF
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
systemctl status courier-app
```

#### Шаг 6: Установка Nginx
```bash
apt-get install -y nginx
```

#### Шаг 7: Создание конфигурации Nginx
```bash
sudo tee /etc/nginx/sites-available/slotworker.ru > /dev/null <<'EOF'
# HTTP - Redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name slotworker.ru www.slotworker.ru;
    return 301 https://$server_name$request_uri;
}

# HTTPS
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
```

#### Шаг 8: Установка SSL сертификатов
```bash
apt-get install -y certbot python3-certbot-nginx

certbot --nginx \
  -d slotworker.ru \
  -d www.slotworker.ru \
  --non-interactive \
  --agree-tos \
  --email admin@slotworker.ru

systemctl reload nginx
```

#### Шаг 9: Проверка что всё работает
```bash
curl http://localhost:3000/
curl http://localhost:3000/api/stats
curl -I https://slotworker.ru
```

---

## ✅ ПРОВЕРКА РАБОТОСПОСОБНОСТИ

### Локальная проверка с сервера

```bash
# Получить диагностику всех компонентов
bash /var/www/x5/server-diagnostic.sh
```

Результат должен быть:
```
✅ PASS: Node.js установлен
✅ PASS: Папка проекта /var/www/x5 существует
✅ PASS: Сервис courier-app запущен
✅ PASS: Порт 3000 (Node.js) прослушивается
✅ PASS: Nginx установлен
✅ PASS: Конфигурация Nginx правильна
✅ PASS: Сертификат Let's Encrypt для slotworker.ru существует
```

### Тестирование из браузера

1. **HTTP версия (должно перенаправить на HTTPS):**
   ```
   http://slotworker.ru
   ```

2. **HTTPS версия (зеленый замок 🔒):**
   ```
   https://slotworker.ru
   ```

3. **WWW версия:**
   ```
   https://www.slotworker.ru
   ```

4. **API тест:**
   ```
   https://slotworker.ru/api/stats
   ```
   
   Должен ответить JSON вроде:
   ```json
   {"success":true,"count":5,"stats":{...}}
   ```

### Функциональное тестирование

1. Откройте https://slotworker.ru
2. Заполните форму с примерными данными
3. Отправьте заявку
4. Должно появиться сообщение об успехе
5. Проверьте что заявка сохранена в БД:

```bash
# На сервере
sqlite3 /var/www/x5/courier_applications.db "SELECT * FROM courier_applications LIMIT 5;"
```

---

## 🐛 РЕШЕНИЕ ПРОБЛЕМ

### Проблема 1: "Connection refused" при подключении

**Решение:**
```bash
# Проверить что Node.js запущен
systemctl status courier-app

# Если не запущен:
systemctl restart courier-app
sleep 3
systemctl status courier-app

# Проверить логи
journalctl -u courier-app -n 50
```

### Проблема 2: "SSL certificate problem"

**Решение:**
```bash
# Перепроверить сертификаты
sudo certbot certificates

# Если не существуют - получить новые
sudo certbot --nginx -d slotworker.ru -d www.slotworker.ru --force-renewal

# Перезагрузить Nginx
sudo systemctl reload nginx
```

### Проблема 3: "502 Bad Gateway" или "504 Timeout"

**Решение:**
```bash
# Проверить что Node.js слушает
ss -tlnp | grep 3000

# Если не слушает - перезагрузить
systemctl restart courier-app
sleep 2

# Проверить конфиг Nginx
nginx -t

# Перезагрузить Nginx
systemctl reload nginx
```

### Проблема 4: DNS не разрешается

**Решение:**
1. Проверьте что запись A создана в регистраторе домена
2. Дождитесь распространения DNS (5-24 часа)
3. Очистите кеш браузера (Ctrl+Shift+Del)
4. Проверьте от другого браузера/машины

### Проблема 5: "Permission denied" или ошибки доступа

**Решение:**
```bash
# Исправить права на файлы
chmod 644 /var/www/x5/courier_applications.db
chmod 755 /var/www/x5

# Если пользователь root
chown root:root /var/www/x5/courier_applications.db

# Перезагрузить приложение
systemctl restart courier-app
```

---

## 📁 ФАЙЛЫ ДЛЯ РАЗВЕРТЫВАНИЯ

### В этом пакете включены:

| Файл | Описание |
|------|---------|
| `deploy-full-domain.sh` | 🚀 **Основной скрипт** - Полное развертывание одной командой |
| `server-diagnostic.sh` | 🔍 Диагностика всех компонентов сервера |
| `SERVER_VERIFICATION_CHECKLIST.md` | ✅ Подробный чеклист проверки |
| `DOMAIN_DEPLOYMENT.md` | 📖 Это руководство |
| `index.html` | 🎨 Главная страница приложения |
| `server.js` | 🔧 Node.js приложение |
| `package.json` | 📦 Зависимости npm |

### Как использовать эти файлы на сервере:

```bash
# Скрипты уже в репо - используйте их:
curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/deploy-full-domain.sh | sudo bash

# Или локально если скопировали:
sudo bash deploy-full-domain.sh
```

---

## 🎯 РЕЗЮМЕ

### Минимум для быстрого старта:

```bash
# 1. Убедитесь что DNS настроена на 62.217.182.74
# 2. Подключитесь к серверу
ssh root@62.217.182.74

# 3. Запустите автоматическое развертывание
sudo bash <(curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/deploy-full-domain.sh)

# 4. Дождитесь завершения (~10 минут)
# 5. Проверьте результаты
bash /var/www/x5/server-diagnostic.sh

# 6. Откройте в браузере
# https://slotworker.ru
```

### Ожидаемый результат:

✅ Доступны адреса:
- https://slotworker.ru
- https://www.slotworker.ru
- https://slotworker.ru/api/stats

✅ Форма отправляет заявки в БД
✅ SSL сертификат валиден (зеленый 🔒)
✅ Автоматическое обновление сертификатов настроено

---

## 📞 ПОМОЩЬ И ПОДДЕРЖКА

Если что-то не работает - выполните на сервере:

```bash
# Полная диагностика
echo "=== СИСТЕМА ===" && whoami && hostname && uname -a
echo "=== СТАТУС ===" && systemctl status courier-app --no-pager && systemctl status nginx --no-pager
echo "=== ЛОГИ ===" && journalctl -u courier-app -n 20
echo "=== ПОРТОВ ===" && ss -tlnp
echo "=== DNS ===" && nslookup slotworker.ru
echo "=== СЕРТИФИКАТЫ ===" && certbot certificates
```

Скопируйте результаты для диагностики проблемы.

---

**Статус:** ✅ ГОТОВО К РАЗВЕРТЫВАНИЮ  
**Дата:** 20.05.2026  
**Версия:** 1.0
