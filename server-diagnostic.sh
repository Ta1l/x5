#!/bin/bash

# ============================================================================
# ПОЛНАЯ ДИАГНОСТИКА СЕРВЕРА SLOTWORKER.RU
# Скрипт для проверки всех компонентов
# ============================================================================

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   🔍 ДИАГНОСТИКА СЕРВЕРА SLOTWORKER.RU ($(date '+%d.%m.%Y %H:%M'))       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Счетчики
PASSED=0
FAILED=0
WARNINGS=0

# Функция для проверки успеха
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $1"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: $1"
        ((FAILED++))
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  СИСТЕМНАЯ ИНФОРМАЦИЯ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Пользователь: $(whoami)"
echo "Хостнейм: $(hostname)"
echo "ОС: $(uname -s) $(uname -r)"
echo "Ядер: $(nproc)"
echo "Памяти: $(free -h | grep Mem | awk '{print $2}')"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  ПРОВЕРКА NODE.JS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

which node > /dev/null 2>&1
check_status "Node.js установлен"

if command -v node &> /dev/null; then
    echo "Версия Node.js: $(node -v)"
    echo "Версия npm: $(npm -v)"
fi

echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  ПРОВЕРКА ПРОЕКТА"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

test -d /var/www/x5
check_status "Папка проекта /var/www/x5 существует"

test -f /var/www/x5/index.html
check_status "index.html существует"

test -f /var/www/x5/server.js
check_status "server.js существует"

test -f /var/www/x5/package.json
check_status "package.json существует"

test -f /var/www/x5/courier_applications.db
check_status "БД courier_applications.db существует"

if [ -d /var/www/x5/node_modules ]; then
    echo -e "${GREEN}✅ PASS${NC}: node_modules установлены ($(ls -1 /var/www/x5/node_modules | wc -l) пакетов)"
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC}: node_modules не установлены"
    ((FAILED++))
fi

echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  ПРОВЕРКА SYSTEMD СЕРВИСА"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

systemctl list-units --type service | grep courier-app > /dev/null 2>&1
check_status "Сервис courier-app существует"

systemctl is-active --quiet courier-app
check_status "Сервис courier-app запущен"

systemctl is-enabled --quiet courier-app
check_status "Сервис courier-app включен в автозагрузку"

echo "Статус: $(systemctl is-active courier-app)"

echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  ПРОВЕРКА ПОРТОВ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ss -tlnp 2>/dev/null | grep :3000 > /dev/null 2>&1
check_status "Порт 3000 (Node.js) прослушивается"

ss -tlnp 2>/dev/null | grep :80 > /dev/null 2>&1
check_status "Порт 80 (HTTP) прослушивается"

ss -tlnp 2>/dev/null | grep :443 > /dev/null 2>&1
check_status "Порт 443 (HTTPS) прослушивается"

echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6️⃣  ПРОВЕРКА NGINX"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

which nginx > /dev/null 2>&1
check_status "Nginx установлен"

nginx -t > /dev/null 2>&1
check_status "Конфигурация Nginx правильна"

systemctl is-active --quiet nginx
check_status "Nginx запущен"

test -f /etc/nginx/sites-available/slotworker.ru
check_status "Конфиг /etc/nginx/sites-available/slotworker.ru существует"

test -L /etc/nginx/sites-enabled/slotworker.ru
check_status "Символическая ссылка в sites-enabled существует"

echo "Версия Nginx: $(nginx -v 2>&1)"

echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7️⃣  ПРОВЕРКА SSL СЕРТИФИКАТОВ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

which certbot > /dev/null 2>&1
check_status "Certbot установлен"

test -d /etc/letsencrypt/live/slotworker.ru
check_status "Сертификат Let's Encrypt для slotworker.ru существует"

# Проверить дату истечения сертификата
if [ -f "/etc/letsencrypt/live/slotworker.ru/cert.pem" ]; then
    CERT_DATE=$(openssl x509 -enddate -noout -in /etc/letsencrypt/live/slotworker.ru/cert.pem | cut -d= -f2)
    echo "Сертификат истекает: $CERT_DATE"
    
    # Проверить что сертификат не истек
    openssl x509 -checkend 0 -noout -in /etc/letsencrypt/live/slotworker.ru/cert.pem > /dev/null 2>&1
    check_status "Сертификат еще действительный"
    
    # Предупреждение если истечет в ближайшие 30 дней
    openssl x509 -checkend 2592000 -noout -in /etc/letsencrypt/live/slotworker.ru/cert.pem > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}⚠️  WARNING${NC}: Сертификат истечет в ближайшие 30 дней"
        ((WARNINGS++))
    fi
fi

echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8️⃣  ПРОВЕРКА DNS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Получить текущий IP сервера
CURRENT_IP=$(hostname -I | awk '{print $1}')
echo "IP сервера: $CURRENT_IP"

# Проверить DNS
DNS_IP=$(dig +short slotworker.ru @8.8.8.8 | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
if [ -z "$DNS_IP" ]; then
    echo -e "${RED}❌ FAIL${NC}: DNS не разрешается"
    ((FAILED++))
else
    echo "DNS разрешается на: $DNS_IP"
    
    if [ "$DNS_IP" = "62.217.182.74" ]; then
        echo -e "${GREEN}✅ PASS${NC}: DNS указывает на правильный IP (62.217.182.74)"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: DNS указывает на неправильный IP ($DNS_IP вместо 62.217.182.74)"
        ((FAILED++))
    fi
fi

echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "9️⃣  ПРОВЕРКА API"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Тест локально
curl -s http://localhost:3000/ > /dev/null 2>&1
check_status "Локальный Node.js отвечает (http://localhost:3000)"

curl -s http://localhost:3000/api/stats > /dev/null 2>&1
check_status "API /api/stats доступен"

# Тест через домен по HTTP
curl -s -o /dev/null -w "%{http_code}" http://slotworker.ru/ > /dev/null 2>&1
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://slotworker.ru/)
if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "308" ]; then
    echo -e "${GREEN}✅ PASS${NC}: HTTP перенаправляет на HTTPS (статус: $HTTP_CODE)"
    ((PASSED++))
elif [ "$HTTP_CODE" = "200" ]; then
    echo -e "${YELLOW}⚠️  WARNING${NC}: HTTP отвечает 200 (должно быть перенаправление на HTTPS)"
    ((WARNINGS++))
else
    echo -e "${RED}❌ FAIL${NC}: HTTP ошибка $HTTP_CODE"
    ((FAILED++))
fi

# Тест через домен по HTTPS
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://slotworker.ru/ 2>/dev/null || echo "000")
if [ "$HTTPS_CODE" = "200" ]; then
    echo -e "${GREEN}✅ PASS${NC}: HTTPS работает (статус: 200)"
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC}: HTTPS статус $HTTPS_CODE"
    ((FAILED++))
fi

echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔟 ПРОВЕРКА ЛОГОВ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Проверить последние ошибки в приложении
ERRORS=$(sudo journalctl -u courier-app -n 50 2>/dev/null | grep -i error | wc -l)
if [ "$ERRORS" = "0" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Нет ошибок в логах приложения"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠️  WARNING${NC}: Найдено $ERRORS строк с ошибками в логах"
    ((WARNINGS++))
    echo "Последние ошибки:"
    sudo journalctl -u courier-app -n 20 2>/dev/null | grep -i error | head -5
fi

# Проверить Nginx логи
NGINX_ERRORS=$(sudo tail -100 /var/log/nginx/error.log 2>/dev/null | grep -v "^#" | wc -l)
if [ "$NGINX_ERRORS" = "0" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Нет ошибок в логах Nginx"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠️  WARNING${NC}: Найдено $NGINX_ERRORS строк в error.log Nginx"
    ((WARNINGS++))
fi

echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 ИТОГОВЫЙ СТАТУС"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "${GREEN}✅ Успешно: $PASSED${NC}"
echo -e "${RED}❌ Ошибок: $FAILED${NC}"
echo -e "${YELLOW}⚠️  Предупреждений: $WARNINGS${NC}"

echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           🎉 СЕРВЕР ПОЛНОСТЬЮ ГОТОВ К РАБОТЕ! 🎉             ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║  Адреса доступа:                                             ║${NC}"
    echo -e "${GREEN}║  ✅ https://slotworker.ru                                    ║${NC}"
    echo -e "${GREEN}║  ✅ https://www.slotworker.ru                                ║${NC}"
    echo -e "${GREEN}║  ✅ https://slotworker.ru/api/stats                          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              ⚠️  ОБНАРУЖЕНЫ ПРОБЛЕМЫ ($FAILED)  ⚠️              ║${NC}"
    echo -e "${RED}║  Проверьте детали выше и исправьте проблемы                  ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
