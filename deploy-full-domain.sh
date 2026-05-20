#!/bin/bash

# ============================================================================
# ПОЛНОЕ РАЗВЕРТЫВАНИЕ SLOWORKER.RU С НАСТРОЙКОЙ ДОМЕНА
# Этот скрипт выполняет все необходимые шаги для работы сайта на домене
# ============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="slotworker.ru"
WWW_DOMAIN="www.slotworker.ru"
PROJECT_DIR="/var/www/x5"
EMAIL="admin@slotworker.ru"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   🚀 ПОЛНОЕ РАЗВЕРТЫВАНИЕ $DOMAIN                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Функция логирования
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Проверка что скрипт запущен от root
if [ "$EUID" -ne 0 ]; then
    log_error "Этот скрипт должен быть запущен от root (используйте: sudo bash deploy-full-domain.sh)"
fi

log "Начало развертывания $DOMAIN..."
echo ""

# ============================================================================
# ШАГ 1: Обновление системы
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "ШАГ 1/10: Обновление системы"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

apt-get update -qq || true
log_success "Система обновлена"
echo ""

# ============================================================================
# ШАГ 2: Установка зависимостей
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "ШАГ 2/10: Установка основных зависимостей"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

apt-get install -y -qq curl wget git build-essential python3 > /dev/null 2>&1
log_success "Основные зависимости установлены"
echo ""

# ============================================================================
# ШАГ 3: Установка Node.js
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "ШАГ 3/10: Установка Node.js 20.x"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! command -v node &> /dev/null; then
    log "Node.js не установлен, устанавливаем..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    apt-get install -y -qq nodejs > /dev/null 2>&1
fi

NODE_VERSION=$(node -v)
NPM_VERSION=$(npm -v)
echo "Node.js: $NODE_VERSION"
echo "npm: $NPM_VERSION"
log_success "Node.js установлен"
echo ""

# ============================================================================
# ШАГ 4: Подготовка проекта
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "ШАГ 4/10: Подготовка проекта"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Создать папку если не существует
mkdir -p /var/www

# Проверить и клонировать/обновить проект
if [ -d "$PROJECT_DIR/.git" ]; then
    log "Проект уже существует, обновляем..."
    cd "$PROJECT_DIR"
    git pull origin main > /dev/null 2>&1 || true
else
    log "Клонируем проект..."
    rm -rf "$PROJECT_DIR"
    git clone https://github.com/Ta1l/x5.git "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

# Установить зависимости
log "Установка npm зависимостей..."
npm install --production --silent > /dev/null 2>&1

# Проверить важные файлы
test -f index.html || log_error "index.html не найден"
test -f server.js || log_error "server.js не найден"
test -f package.json || log_error "package.json не найден"

log_success "Проект подготовлен"
echo ""

# ============================================================================
# ШАГ 5: Создание Systemd сервиса
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "ШАГ 5/10: Создание systemd сервиса"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > /etc/systemd/system/courier-app.service <<EOF
[Unit]
Description=Courier Application Service (slotworker.ru)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/bin/node $PROJECT_DIR/server.js
Restart=on-failure
RestartSec=5

# Логирование
StandardOutput=journal
StandardError=journal
SyslogIdentifier=courier-app

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузить systemd демон
systemctl daemon-reload

# Запустить сервис
systemctl start courier-app || log_error "Не удалось запустить сервис courier-app"
systemctl enable courier-app || true

sleep 2

# Проверить статус
if systemctl is-active --quiet courier-app; then
    log_success "Systemd сервис запущен"
else
    log_error "Systemd сервис не запустился. Проверьте логи: journalctl -u courier-app -n 50"
fi
echo ""

# ============================================================================
# ШАГ 6: Установка Nginx
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "ШАГ 6/10: Установка и настройка Nginx"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

apt-get install -y -qq nginx > /dev/null 2>&1

# Создать конфигурацию для домена
cat > /etc/nginx/sites-available/$DOMAIN <<'EOF'
# HTTP configuration - redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name slotworker.ru www.slotworker.ru;

    # Redirect all HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

# HTTPS configuration
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name slotworker.ru www.slotworker.ru;

    # SSL certificates (will be managed by certbot)
    ssl_certificate /etc/letsencrypt/live/slotworker.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/slotworker.ru/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css text/javascript application/json application/javascript;
    gzip_min_length 1000;

    # Root directory
    root /var/www/x5;
    index index.html;

    # Main application proxy
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # API endpoints
    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Logging
    access_log /var/log/nginx/slotworker-access.log;
    error_log /var/log/nginx/slotworker-error.log;
}
EOF

# Удалить default конфиг
rm -f /etc/nginx/sites-enabled/default

# Включить наш конфиг
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

# Проверить конфиг
nginx -t > /dev/null 2>&1 || log_error "Ошибка в конфигурации Nginx"

# Перезагрузить Nginx (без SSL сертификатов пока)
systemctl start nginx || log_error "Не удалось запустить Nginx"
systemctl enable nginx || true

log_success "Nginx установлен и настроен"
echo ""

# ============================================================================
# ШАГ 7: Установка Certbot SSL сертификатов
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "ШАГ 7/10: Установка Let's Encrypt SSL сертификатов"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

apt-get install -y -qq certbot python3-certbot-nginx > /dev/null 2>&1

# Проверить существуют ли сертификаты
if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    log "Получение SSL сертификата от Let's Encrypt..."
    
    certbot --nginx \
        --non-interactive \
        --agree-tos \
        -d $DOMAIN \
        -d $WWW_DOMAIN \
        --email $EMAIL \
        --no-eff-email 2>&1 | grep -E "Successfully|already" || true
    
    if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        log_warning "Не удалось получить сертификат. Проверьте что域名指向правильно и портов 80/443 открыты"
        log_warning "Вы можете повторить попытку позже с командой:"
        log_warning "sudo certbot --nginx -d $DOMAIN -d $WWW_DOMAIN"
    else
        log_success "SSL сертификат получен"
    fi
else
    log "SSL сертификат уже существует"
fi

# Перезагрузить Nginx с новой конфигурацией
systemctl reload nginx

log_success "Let's Encrypt настроен"
echo ""

# ============================================================================
# ШАГ 8: Настройка автоматического обновления сертификатов
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "ШАГ 8/10: Настройка автоматического обновления сертификатов"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Включить автоматическое обновление
systemctl enable certbot.timer > /dev/null 2>&1 || true
systemctl start certbot.timer > /dev/null 2>&1 || true

log_success "Система автоматического обновления включена"
echo ""

# ============================================================================
# ШАГ 9: Проверка прав доступа
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "ШАГ 9/10: Проверка прав доступа"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Убедиться что права на БД правильные
if [ -f "$PROJECT_DIR/courier_applications.db" ]; then
    chmod 644 "$PROJECT_DIR/courier_applications.db"
    log_success "Права на БД установлены"
fi

# Права на папку
chmod 755 "$PROJECT_DIR"
chmod 644 "$PROJECT_DIR"/*.{html,js,json,md} 2>/dev/null || true

log_success "Права доступа проверены"
echo ""

# ============================================================================
# ШАГ 10: Финальная проверка
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "ШАГ 10/10: Финальная проверка всех компонентов"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ERRORS=0

# Проверка Node.js
if ! systemctl is-active --quiet courier-app; then
    log_error "❌ Сервис courier-app не запущен"
    ERRORS=$((ERRORS + 1))
fi

# Проверка Nginx
if ! systemctl is-active --quiet nginx; then
    log_error "❌ Сервис nginx не запущен"
    ERRORS=$((ERRORS + 1))
fi

# Проверка портов
if ! ss -tlnp 2>/dev/null | grep -q :3000; then
    log_warning "Порт 3000 не слушается"
fi

if ! ss -tlnp 2>/dev/null | grep -q :80; then
    log_error "❌ Порт 80 не слушается"
    ERRORS=$((ERRORS + 1))
fi

# Проверка конфигурации
if ! nginx -t > /dev/null 2>&1; then
    log_error "❌ Конфигурация Nginx неправильная"
    ERRORS=$((ERRORS + 1))
fi

echo ""

if [ $ERRORS -eq 0 ]; then
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo -e "${GREEN}║        ✅ РАЗВЕРТЫВАНИЕ УСПЕШНО ЗАВЕРШЕНО! ✅               ║${NC}"
    echo "║                                                                ║"
    echo -e "${GREEN}║  Сайт доступен по адресам:                              ║${NC}"
    echo -e "${GREEN}║  ✅ https://slotworker.ru                               ║${NC}"
    echo -e "${GREEN}║  ✅ https://www.slotworker.ru                           ║${NC}"
    echo "║                                                                ║"
    echo -e "${GREEN}║  Проверка API:                                         ║${NC}"
    echo -e "${GREEN}║  curl https://slotworker.ru/api/stats                 ║${NC}"
    echo "║                                                                ║"
    echo -e "${GREEN}║  Логи приложения:                                      ║${NC}"
    echo -e "${GREEN}║  journalctl -u courier-app -f                          ║${NC}"
    echo "║                                                                ║"
    echo -e "${GREEN}║  Логи Nginx accesss:                                   ║${NC}"
    echo -e "${GREEN}║  tail -f /var/log/nginx/slotworker-access.log          ║${NC}"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Дополнительная информация
    echo "Статус сервисов:"
    systemctl status courier-app --no-pager | head -3
    echo ""
    systemctl status nginx --no-pager | head -3
    echo ""
    
    # Проверить API локально
    echo "Проверка API..."
    API_RESPONSE=$(curl -s http://localhost:3000/api/stats || echo '{"error":"failed"}')
    echo "API ответ: $API_RESPONSE"
    
else
    echo -e "${RED}❌ Ошибки при развертывании (найдено: $ERRORS)${NC}"
    echo "Проверьте логи:"
    echo "  systemctl status courier-app"
    echo "  systemctl status nginx"
    echo "  tail -50 /var/log/nginx/error.log"
    exit 1
fi
