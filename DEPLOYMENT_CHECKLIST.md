# 📋 ФИНАЛЬНЫЙ ЧЕКЛИСТ РАЗВЕРТЫВАНИЯ

## 🎯 ЦЕЛЬ
Развернуть x5-app на сервер 62.217.182.74 и сделать доступным по доменам:
- ✅ https://slotworker.ru
- ✅ https://www.slotworker.ru

## 📊 СТАТУС ПРОЕКТА

### ✅ Завершено на локальной машине:
- [x] HTML страница с формой (index.html)
- [x] Backend сервер на Node.js + Express + SQLite (server.js)
- [x] npm зависимости (package.json)
- [x] Тестирование локально (порт 3000 работает)
- [x] Git репозиторий: https://github.com/Ta1l/x5.git
- [x] Документация и гайды развертывания
- [x] Скрипты для автоматизации

### 📋 ТЧ-ЧТО НУЖНО СДЕЛАТЬ:

1. **Подключиться к серверу:**
   ```bash
   ssh root@62.217.182.74
   # Введите пароль: *9w1Z*!R7WxH
   ```

2. **Выполнить развертывание (одна из опций):**

   **ВАРИАНТ A: Супер быстро (рекомендуется)**
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/quick-deploy.sh)
   ```

   **ВАРИАНТ B: Если кёрл не работает**
   - Скопируйте содержимое https://raw.githubusercontent.com/Ta1l/x5/main/quick-deploy.sh
   - Создайте файл: `nano quick-deploy.sh`
   - Вставьте содержимое
   - Скорохранитейте: `chmod +x quick-deploy.sh && ./quick-deploy.sh`

   **ВАРИАНТ C: Пошагово вручную**
   - Следуйте инструкциям в: https://github.com/Ta1l/x5/blob/main/SETUP_INSTRUCTIONS.md

3. **Проверить работу:**
   ```bash
   # На сервере:
   curl http://localhost:3000/api/stats
   
   # В браузере:
   https://slotworker.ru
   https://slotworker.ru/api/stats
   ```

4. **Тестировать форму:**
   - Заполните форму на https://slotworker.ru
   - Отправьте заявку
   - Проверьте БД на сервере:
   ```bash
   sqlite3 /var/www/x5/courier_applications.db "SELECT * FROM courier_applications;"
   ```

---

## 🚨 ВАЖНЫЕ МОМЕНТЫ

### ✅ Что уже готово на GitHub:
- Исходный код проекта
- Все необходимые файлы
- Скрипты развертывания (quick-deploy.sh)
- Полная документация
- Гайды по troubleshooting

### ⚠️ Что может потребоваться:
- Проверить что DNS слотворкер.ru указывает на IP 62.217.182.74
- Убедиться что порты 80, 443 открыты на сервере
- Проверить что на сервере установлена ОС Linux (Ubuntu/Debian)

### 🔐 Безопасность:
- SSL сертификат устанавливается автоматически через Let's Encrypt
- База данных SQLite на сервере
- API защищена через Express.js

---

## 📞 ЕСЛИ ЧТО-ТО ПОШЛО НЕ ТАК

### Проблема: "Connection refused"
```bash
# Проверить что сервис запущен
sudo systemctl status courier-app

# Проверить логи
sudo journalctl -u courier-app -n 50 -f
```

### Проблема: "Nginx error"
```bash
# Проверить конфигурацию
sudo nginx -t

# Перезагрузить
sudo systemctl restart nginx

# Логи
sudo tail -30 /var/log/nginx/error.log
```

### Проблема: "SSL сертификат не получился"
```bash
# Переполучить
sudo certbot --nginx -d slotworker.ru -d www.slotworker.ru --force-renewal

# Проверить логи
cat /var/log/letsencrypt/letsencrypt.log
```

### Проблема: "Заявки не сохраняются"
```bash
# Проверить права БД
ls -la /var/www/x5/courier_applications.db

# Исправить права
sudo chown www-data:www-data /var/www/x5/courier_applications.db
sudo chmod 644 /var/www/x5/courier_applications.db
```

---

## ✅ ФИНАЛЬНЫЙ ЧЕКЛИСТ

После развертывания проверьте:

- [ ] Сервис запущен: `systemctl status courier-app`
- [ ] Портcы открыты: `sudo ss -tlnp`
- [ ] Nginx работает: `sudo systemctl status nginx`
- [ ] БД создана: `ls -la /var/www/x5/courier_applications.db`
- [ ] Доступ по HTTP: `curl http://localhost:3000`
- [ ] API работает: `curl http://localhost:3000/api/stats`
- [ ] Сертификат установлен: `sudo certbot certificates`
- [ ] Доступ по HTTPS: `https://slotworker.ru`
- [ ] Форма сохраняет: Заполните форму и проверьте БД
- [ ] API показывает метрики: `curl https://slotworker.ru/api/stats`

---

## 📚 ПОЛЕЗНЫЕ ССЫЛКИ

- 📖 Полный гайд: [DEPLOYMENT_GUIDE.md](https://github.com/Ta1l/x5/blob/main/DEPLOYMENT_GUIDE.md)
- 📋 Пошаговые инструкции: [SETUP_INSTRUCTIONS.md](https://github.com/Ta1l/x5/blob/main/SETUP_INSTRUCTIONS.md)
- 🚀 Скрипт развертывания: [quick-deploy.sh](https://github.com/Ta1l/x5/blob/main/quick-deploy.sh)
- 📄 README: [README.md](https://github.com/Ta1l/x5/blob/main/README.md)

---

## 🎯 ИТОГ

**Все готово к развертыванию!**

Осталось только:
1. Подключиться к серверу
2. Выполнить одну команду для развертывания
3. Дождаться завершения
4. Проверить работу

**Время развертывства:** ~10-15 минут

**Оценка сложности:** ⭐⭐ (очень просто)

---

Успехов! 🎉

