# 🚀 Courier App - Платформа для парт-курьеров

Веб-приложение для поиска работы курьеров-партнеров.

## ✨ Особенности

- ✅ Полностью адаптивный дизайн
- ✅ SQLite база данных на backend
- ✅ REST API для сохранения заявок
- ✅ Красивый интерфейс на Tailwind CSS
- ✅ Быстрое развертывание на Linux сервер

## 🛠️ Технический стек

**Frontend:**
- HTML5
- Tailwind CSS
- Vanilla JavaScript

**Backend:**
- Node.js 20+
- Express.js
- SQLite3
- CORS поддержка

**DevOps:**
- Nginx как reverse proxy
- Systemd для управления сервисом
- Let's Encrypt SSL
- GitHub Actions (optional)

## 🚀 Быстрое начало

### Локальное развитие

```bash
# 1. Клонируем репозиторий
git clone https://github.com/Ta1l/x5.git
cd x5

# 2. Устанавливаем зависимости
npm install

# 3. Запускаем сервер
npm start

# 4. Открываем в браузере
# http://localhost:3000
```

### Развертывание на production

**Требования:**
- Ubuntu 20.04+ или Debian 11+
- SSH доступ с правами root
- Домен с DNS записью, указывающей на IP сервера

**Вариант 1: Быстрое развертывание (рекомендуется)**

Подключитесь к серверу и выполните одну команду:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/quick-deploy.sh)
```

**Вариант 2: Пошаговое развертывание**

Смотрите [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) или [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

## 📁 Структура проекта

```
x5/
├── index.html           # Главная страница
├── server.js            # Node.js сервер с Express API
├── courier_applications.db  # SQLite база данных (создается сами)
├── package.json         # Зависимости npm
├── package-lock.json    # Lock файл npm
├── quick-deploy.sh      # Скрипт для быстрого развертывания
├── DEPLOYMENT_GUIDE.md  # Полное руководство развертывания
├── SETUP_INSTRUCTIONS.md # Пошаговые инструкции
└── README.md            # Этот файл
```

## 🌐 API Endpoints

### POST /api/courier-application
Сохранение новой заявки

**Request:**
```json
{
  "name": "Иван Петров",
  "phone": "+7 999 123-45-67",
  "citizenship": "Гражданство РФ",
  "messenger": "Телеграм",
  "timestamp": "2026-05-19T10:30:00.000Z",
  "submittedAt": "19.05.2026 10:30:00"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Заявка успешно сохранена",
  "id": 1
}
```

### GET /api/applications
Получение всех заявок (требует доступа с сервера)

**Response:**
```json
{
  "success": true,
  "count": 5,
  "applications": [...]
}
```

### GET /api/stats
Получение статистики

**Response:**
```json
{
  "success": true,
  "count": 5,
  "applications": [...]
}
```

## 📊 База данных

Таблица `courier_applications` содержит:

| Колонка | Тип | Описание |
|---------|-----|---------|
| id | INTEGER | Уникальный ID (Primary Key) |
| name | TEXT | Имя курьера |
| phone | TEXT | Номер телефона |
| citizenship | TEXT | Гражданство |
| messenger | TEXT | Предпочтенный мессенджер |
| timestamp | TEXT | ISO 8601 временная метка |
| submitted_at | TEXT | Дата и время в формате РФ |
| created_at | DATETIME | Время создания записи |

### Примеры запросов к БД

```bash
# Подключение к БД
sqlite3 courier_applications.db

# Все заявки
SELECT * FROM courier_applications;

# Количество заявок
SELECT COUNT(*) FROM courier_applications;

# Заявки по месячам
SELECT COUNT(*), strftime('%Y-%m', created_at) FROM courier_applications GROUP BY strftime('%Y-%m', created_at);

# Популярные мессенджеры
SELECT messenger, COUNT(*) FROM courier_applications GROUP BY messenger ORDER BY COUNT DESC;

# Последние 10 заявок
SELECT * FROM courier_applications ORDER BY created_at DESC LIMIT 10;

# Резервная копия
.backup courier_apps_backup.db

# Выход
.quit
```

## 🔧 Конфигурация

### Переменные окружения

Создайте файл `.env` (опционально):

```env
PORT=3000
NODE_ENV=production
DB_PATH=/var/www/x5/courier_applications.db
```

### Настройка Nginx

Конфиг находится в `/etc/nginx/sites-available/slotworker.ru`

Для изменения:
```bash
sudo nano /etc/nginx/sites-available/slotworker.ru
sudo nginx -t
sudo systemctl reload nginx
```

## 📈 Мониторинг

### Проверка статуса сервиса

```bash
sudo systemctl status courier-app
sudo journalctl -u courier-app -f
```

### Проверка Nginx

```bash
sudo systemctl status nginx
sudo tail -f /var/log/nginx/error.log
```

### Размер БД

```bash
du -sh courier_applications.db
```

## 🔐 Безопасность

- ✅ SSL/TLS сертификат от Let's Encrypt
- ✅ Автоматическое обновление сертификата
- ✅ CORS настроена правильно
- ✅ Input validation на backend
- ✅ SQL injection защита через parameterized queries

### Обновление сертификата

```bash
sudo certbot renew --dry-run  # Тест
sudo certbot renew             # Реальное обновление
```

## 🐛 Troubleshooting

### Сервис не запускается
```bash
sudo journalctl -u courier-app -n 100
```

### Nginx ошибка
```bash
sudo nginx -t
sudo systemctl restart nginx
```

### БД не сохраняет данные
```bash
sudo chown www-data:www-data /var/www/x5/courier_applications.db
sudo chmod 644 /var/www/x5/courier_applications.db
```

### Порт 3000 занят
```bash
sudo lsof -i :3000
sudo kill -9 <PID>
```

## 📝 Логирование и развитие

### Включить более подробное логирование

Отредактируйте `server.js` и раскомментируйте/добавьте:

```javascript
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
  next();
});
```

### Добавить аналитику

Используйте GA или Yandex.Метрика добавив код в `index.html`:

```html
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXX"></script>
```

## 📦 Обновление проекта

```bash
cd /var/www/x5
git pull origin main
npm install --production
sudo systemctl restart courier-app
```

## 📄 Лицензия

MIT

## 👤 Автор

- GitHub: [@Ta1l](https://github.com/Ta1l)

## 🤝 Поддержка

Если у вас есть вопросы, создайте Issue в GitHub репозитории.

---

**Успешного развертывания! 🚀**

Задавайте вопросы и оставляйте feedback в Issues.
