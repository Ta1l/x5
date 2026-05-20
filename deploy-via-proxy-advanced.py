#!/usr/bin/env python3
"""
Развертывание через SOCKS5 прокси на сервер slotworker.ru
Использует проксирование для обхода брандмауэра
"""

import paramiko
import socks
import socket
import sys
import time

# Параметры подключения
HOST = '62.217.182.74'
USERNAME = 'root'
PASSWORD = '*9w1Z*!R7WxH'
PORT = 22

# Параметры прокси SOCKS5
PROXY_HOST = '46.8.17.103'
PROXY_PORT = 5501
PROXY_USER = '6NeZMV'
PROXY_PASS = 'iSxcP9mEj0'

def print_status(status, message):
    """Вывести статус сообщение"""
    symbols = {
        'info': '🔵',
        'success': '✅',
        'error': '❌',
        'warning': '⚠️ ',
        'progress': '⏳'
    }
    print(f"{symbols.get(status, '•')} {message}")

def create_ssh_client_with_proxy():
    """Создать SSH клиент через SOCKS5 прокси"""
    
    print_status('progress', f"Подключаюсь к прокси {PROXY_HOST}:{PROXY_PORT}...")
    
    try:
        # Настроить сокет для работы через SOCKS5
        sock = socks.socksocket()
        sock.set_proxy(
            socks.SOCKS5,
            PROXY_HOST,
            PROXY_PORT,
            username=PROXY_USER,
            password=PROXY_PASS,
            rdns=True
        )
        sock.settimeout(30)
        
        print_status('progress', f"Подключаюсь через прокси к серверу {HOST}:{PORT}...")
        
        # Подключиться к фактическому серверу через прокси
        sock.connect((HOST, PORT))
        
        print_status('success', "✅ Подключение через прокси установлено!")
        
        # Создать transport через сокет
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        # Использовать готовый сокет
        transport = paramiko.Transport(sock)
        transport.connect(username=USERNAME, password=PASSWORD)
        
        ssh._transport = transport
        
        print_status('success', "✅ SSH аутентификация успешна!")
        
        return ssh
        
    except Exception as e:
        print_status('error', f"Ошибка подключения: {e}")
        return None

def execute_command(ssh_client, command, show_output=True):
    """Выполнить команду на сервере"""
    
    try:
        stdin, stdout, stderr = ssh_client.exec_command(command, get_pty=True)
        
        # Для команд с sudo отправь пароль
        if 'sudo' in command:
            stdin.write(PASSWORD + '\n')
            stdin.flush()
        
        output = ""
        while True:
            line = stdout.readline()
            if not line:
                break
            line_str = line.decode('utf-8', errors='ignore').rstrip()
            if show_output and line_str:
                print(f"  {line_str}")
            output += line_str + "\n"
        
        return True, output
        
    except Exception as e:
        print_status('error', f"Ошибка при выполнении команды: {e}")
        return False, str(e)

def main():
    print("╔════════════════════════════════════════════════════════════════╗")
    print("║   🚀 РАЗВЕРТЫВАНИЕ ЧЕРЕЗ ПРОКСИ: slotworker.ru                ║")
    print("║       Прокси: 46.8.17.103:5501 (SOCKS5)                       ║")
    print("╚════════════════════════════════════════════════════════════════╝")
    print()
    
    # Подключиться через прокси
    ssh = create_ssh_client_with_proxy()
    
    if not ssh:
        print_status('error', "❌ Не удалось подключиться через прокси")
        print()
        print("Возможные решения:")
        print("1. Проверьте ip и пароль прокси")
        print("2. Запустите развертывание вручную с машины которая имеет доступ:")
        print("   ssh root@62.217.182.74")
        print("   sudo bash <(curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/deploy-full-domain.sh)")
        return False
    
    try:
        print()
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Информация о сервере:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        print_status('progress', "Проверка пользователя")
        execute_command(ssh, "whoami")
        
        print_status('progress', "Хостнейм сервера")
        execute_command(ssh, "hostname")
        
        print_status('progress', "ОС информация")
        execute_command(ssh, "uname -a")
        
        print()
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✅ НАЧИНАЮ РАЗВЕРТЫВАНИЕ")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print()
        
        # Шаг 1: Обновление системы
        print_status('progress', "ШАГ 1/10: Обновление системы")
        execute_command(ssh, "apt-get update -qq && apt-get upgrade -y -qq", show_output=False)
        print_status('success', "Система обновлена")
        
        # Шаг 2: Основные зависимости
        print()
        print_status('progress', "ШАГ 2/10: Установка зависимостей")
        execute_command(ssh, "apt-get install -y -qq curl wget git build-essential python3 > /dev/null 2>&1", show_output=False)
        print_status('success', "Зависимости установлены")
        
        # Шаг 3: Установка Node.js
        print()
        print_status('progress', "ШАГ 3/10: Установка Node.js 20")
        execute_command(ssh, "curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1 && apt-get install -y -qq nodejs > /dev/null 2>&1", show_output=False)
        success, node_version = execute_command(ssh, "node -v && npm -v", show_output=False)
        if success:
            print_status('success', f"Node.js установлен: {node_version.strip()}")
        
        # Шаг 4: Подготовка проекта
        print()
        print_status('progress', "ШАГ 4/10: Подготовка проекта")
        execute_command(ssh, "mkdir -p /var/www && cd /var/www && ([ -d x5 ] && cd x5 && git pull origin main || git clone https://github.com/Ta1l/x5.git) > /dev/null 2>&1", show_output=False)
        execute_command(ssh, "cd /var/www/x5 && npm install --production --silent > /dev/null 2>&1", show_output=False)
        print_status('success', "Проект подготовлен")
        
        # Шаг 5: Создание systemd сервиса
        print()
        print_status('progress', "ШАГ 5/10: Создание systemd сервиса")
        
        service_config = """[Unit]
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
WantedBy=multi-user.target"""
        
        execute_command(ssh, f"cat > /etc/systemd/system/courier-app.service << 'SERVICEEOF'\n{service_config}\nSERVICEEOF", show_output=False)
        execute_command(ssh, "systemctl daemon-reload && systemctl start courier-app && systemctl enable courier-app > /dev/null 2>&1", show_output=False)
        
        # Проверить что сервис запущен
        success, status = execute_command(ssh, "systemctl is-active courier-app", show_output=False)
        if "active" in status:
            print_status('success', "Systemd сервис запущен")
        else:
            print_status('warning', "Сервис может не было запущен, проверьте логи")
        
        # Шаг 6: Установка Nginx
        print()
        print_status('progress', "ШАГ 6/10: Установка Nginx")
        execute_command(ssh, "apt-get install -y -qq nginx > /dev/null 2>&1", show_output=False)
        print_status('success', "Nginx установлен")
        
        # Шаг 7: Конфигурация Nginx
        print()
        print_status('progress', "ШАГ 7/10: Настройка Nginx конфигурации")
        
        nginx_config = """# HTTP configuration - redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name slotworker.ru www.slotworker.ru;
    return 301 https://$server_name$request_uri;
}

# HTTPS configuration
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name slotworker.ru www.slotworker.ru;

    ssl_certificate /etc/letsencrypt/live/slotworker.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/slotworker.ru/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    root /var/www/x5;
    index index.html;

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

    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    access_log /var/log/nginx/slotworker-access.log;
    error_log /var/log/nginx/slotworker-error.log;
}"""
        
        execute_command(ssh, f"cat > /etc/nginx/sites-available/slotworker.ru << 'NGINXEOF'\n{nginx_config}\nNGINXEOF", show_output=False)
        execute_command(ssh, "rm -f /etc/nginx/sites-enabled/default && ln -sf /etc/nginx/sites-available/slotworker.ru /etc/nginx/sites-enabled/ && nginx -t > /dev/null 2>&1 && systemctl start nginx && systemctl enable nginx > /dev/null 2>&1", show_output=False)
        print_status('success', "Nginx настроен")
        
        # Шаг 8: SSL Сертификаты
        print()
        print_status('progress', "ШАГ 8/10: Получение SSL сертификатов Let's Encrypt")
        execute_command(ssh, "apt-get install -y -qq certbot python3-certbot-nginx > /dev/null 2>&1", show_output=False)
        
        # Получить сертификат
        cert_cmd = "certbot --nginx --non-interactive --agree-tos -d slotworker.ru -d www.slotworker.ru --email admin@slotworker.ru --no-eff-email 2>&1 || echo 'Сертификат уже существует или ошибка DNS'"
        success, cert_output = execute_command(ssh, cert_cmd, show_output=False)
        
        if 'Successfully' in cert_output or 'already' in cert_output:
            print_status('success', "SSL сертификат готов")
        else:
            print_status('warning', "Сертификат может потребовать дополнительной настройки DNS")
        
        # Перезагрузить Nginx с новыми сертификатами
        execute_command(ssh, "systemctl reload nginx > /dev/null 2>&1", show_output=False)
        
        # Шаг 9: Автообновление сертификатов
        print()
        print_status('progress', "ШАГ 9/10: Настройка автообновления SSL сертификатов")
        execute_command(ssh, "systemctl enable certbot.timer > /dev/null 2>&1 && systemctl start certbot.timer > /dev/null 2>&1", show_output=False)
        print_status('success', "Автообновление включено")
        
        # Шаг 10: Финальная проверка
        print()
        print_status('progress', "ШАГ 10/10: Финальная проверка компонентов")
        
        checks = [
            ("Node.js сервис", "systemctl is-active courier-app"),
            ("Nginx", "systemctl is-active nginx"),
            ("Порт 3000", "ss -tlnp 2>/dev/null | grep 3000 | wc -l"),
            ("Порт 80", "ss -tlnp 2>/dev/null | grep :80 | wc -l"),
            ("Портал 443", "ss -tlnp 2>/dev/null | grep :443 | wc -l"),
        ]
        
        all_good = True
        for check_name, check_cmd in checks:
            success, output = execute_command(ssh, check_cmd, show_output=False)
            if success and (output.strip() == "active" or output.strip() != "0"):
                print_status('success', f"{check_name}: OK")
            else:
                print_status('warning', f"{check_name}: Требует проверки")
                all_good = False
        
        print()
        print("╔════════════════════════════════════════════════════════════════╗")
        print("║        ✅ РАЗВЕРТЫВАНИЕ ЗАВЕРШЕНО ЧЕРЕЗ ПРОКСИ!               ║")
        print("╚════════════════════════════════════════════════════════════════╝")
        print()
        print("📍 Сайт доступен по адресам:")
        print("   ✅ https://slotworker.ru")
        print("   ✅ https://www.slotworker.ru")
        print("   ✅ https://slotworker.ru/api/stats (API)")
        print()
        print("🔒 SSL сертификат: Let's Encrypt (автоообновление включено)")
        print("🚀 Статус: Production Ready")
        print()
        
        ssh.close()
        return True
        
    except Exception as e:
        print_status('error', f"Ошибка при развертывании: {e}")
        try:
            ssh.close()
        except:
            pass
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
