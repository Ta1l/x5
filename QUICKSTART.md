# 🚀 БЫСТРЫЙ СТАРТ x5

**Время чтения: 2 минуты | Время развертывания: 10-15 минут**

## 🎯 Цель

Развернуть приложение для работы курьеров на сервер и открыть доступ через домен.

## ✅ Что уже готово

- ✅ Исходный код на GitHub: https://github.com/Ta1l/x5
- ✅ Backend на Node.js + Express + SQLite
- ✅ Frontend на HTML5 + Tailwind CSS
- ✅ Скрипты автоматизации
- ✅ SSL сертификаты (Let's Encrypt)
- ✅ Полная документация

## 🚀 РАЗВЕРТЫВАНИЕ (выбери 1 способ)

### 🟢 СПОСОБ 1: Супер быстро (1 команда)

Подключись к серверу и выполни:

```bash
ssh root@62.217.182.74
# Введи пароль: *9w1Z*!R7WxH

# Затем одна команда:
bash <(curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/quick-deploy.sh)
```

**ГОТОВО! ✅ Жди 10-15 минут**

---

### 🟡 СПОСОБ 2: Если первый способ не работает

**На Windows:**
```powershell
# Запусти PowerShell скрипт для подготовки команд
powershell -File .\Deploy.ps1
```

**Затем подключись SSH и вставь команды:**
```bash
ssh root@62.217.182.74
# Вставь команды из скрипта
```

---

### 🔴 СПОСОБ 3: Вручную (если ничего не работает)

Подключись к серверу и скопируй-вставь команды из [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)

---

## ✅ ПРОВЕРКА РАБОТЫ

После развертывания проверь:

```bash
# На сервере:
curl http://localhost:3000/api/stats

# В браузере:
https://slotworker.ru
https://slotworker.ru/api/stats

# Тестирование:
# 1. Заполни форму
# 2. Отправь заявку  
# 3. Увидишь сообщение об успехе
```

---

## 🔧 УПРАВЛЕНИЕ

**Проверить статус:**
```bash
sudo systemctl status courier-app
```

**Просмотр логов:**
```bash
sudo journalctl -u courier-app -f
```

**Перезагрузить приложение:**
```bash
sudo systemctl restart courier-app
```

**Просмотр БД:**
```bash
sqlite3 /var/www/x5/courier_applications.db "SELECT * FROM courier_applications;"
```

---

## 📚 ДОКУМЕНТАЦИЯ

| Файл | Описание |
|------|---------|
| [README.md](README.md) | Основные сведения о проекте |
| [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) | Пошаговые инструкции |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Полный гайд развертывания |
| [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) | Финальный чек-лист |
| [quick-deploy.sh](quick-deploy.sh) | Автоматический скрипт |

---

## 🆘 ПОМОЩЬ

### "SSH Connection refused"
- Проверь IP адрес: 62.217.182.74
- Проверь пароль: *9w1Z*!R7WxH
- Убедись что сервер включен

### "nginx: [error]"
```bash
sudo nginx -t
sudo systemctl restart nginx
```

### "Форма не сохраняет заявки"
```bash
sudo chown www-data:www-data /var/www/x5/courier_applications.db
sudo chmod 644 /var/www/x5/courier_applications.db
```

### "SSL сертификат ошибка"
```bash
sudo certbot renew --force-renewal
```

---

## 📞 ВАЖНО

✅ **DNS должен быть настроен:**
- slotworker.ru → 62.217.182.74
- www.slotworker.ru → 62.217.182.74

✅ **Порты должны быть открыты:**
- 80 (HTTP)
- 443 (HTTPS)
- 3000 (Node.js - только локально)

✅ **После развертывания:**
- Дождись 1-2 минут загрузки SSL сертификата
- Примерно 5-10 минут полного развертывания
- Проверь https://slotworker.ru

---

## 🎉 ГОТОВО!

После развертывания у вас будет:

- 🌐 **Сайт:** https://slotworker.ru
- 📱 **API:** https://slotworker.ru/api/stats
- 💾 **БД:** /var/www/x5/courier_applications.db
- 🔒 **SSL:** Автоматически обновляется

**Успехов! 🚀**

---

**Полная документация доступна в репозитории: https://github.com/Ta1l/x5**
