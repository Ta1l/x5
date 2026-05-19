#!/usr/bin/env python3
"""
Скрипт для развертывания проекта x5 на удаленном сервере через прокси
Использование: python deploy.py
"""

import subprocess
import sys
import getpass

# Данные прокси
PROXY_HOST = "46.8.17.103"
PROXY_PORT = 5501
PROXY_USER = "6NeZMV"
PROXY_PASS = "iSxcP9mEj0"

# Данные целевого сервера
SERVER_HOST = "62.217.182.74"
SERVER_USER = "root"
SERVER_PASS = "*9w1Z*!R7WxH"

def run_ssh_command(command):
    """Выполнить команду на сервере через SSH с прокси"""
    try:
        # Попытка 1: напрямую через SSH туннель
        full_command = f'ssh -o ProxyUseFdpass=no -o ProxyCommand="ssh -W %h:%p {PROXY_USER}@{PROXY_HOST} -p {PROXY_PORT}" -o StrictHostKeyChecking=no {SERVER_USER}@{SERVER_HOST} "{command}"'
        
        result = subprocess.run(full_command, shell=True, capture_output=True, text=True, timeout=30)
        
        if result.returncode != 0:
            print(f"❌ Ошибка: {result.stderr}")
            return False
        
        print(result.stdout)
        return True
        
    except subprocess.TimeoutExpired:
        print("❌ Timeout при подключении")
        return False
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        return False

def main():
    print("=" * 50)
    print("  🚀 Развертывание проекта x5")
    print("=" * 50)
    print()
    
    # Шаг 1: Проверка доступа
    print("[1/9] 🔐 Проверка доступа к серверу...")
    if not run_ssh_command("whoami"):
        print("\n❌ Не удается подключиться к серверу")
        print("Проверьте:")
        print("  - Доступность прокси")
        print("  - IP адрес сервера")
        print("  - Учетные данные")
        sys.exit(1)
    
    print("✅ Доступ получен\n")
    
    # Шаг 2: Обновление системы
    print("[2/9] 📦 Обновление системы...")
    run_ssh_command("apt-get update && apt-get upgrade -y")
    print()
    
    # Шаг 3: Установка Node.js
    print("[3/9] 🟢 Установка Node.js 20...")
    commands = [
        "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -",
        "apt-get install -y nodejs git build-essential wget curl",
    ]
    for cmd in commands:
        run_ssh_command(cmd)
    print()
    
    # Шаг 4: Клонирование проекта
    print("[4/9] 📥 Клонирование проекта с GitHub...")
    run_ssh_command("mkdir -p /var/www && cd /var/www && rm -rf x5 && git clone https://github.com/Ta1l/x5.git && cd x5 && ls -la")
    print()
    
    # Шаг 5: Установка npm зависимостей
    print("[5/9] 📦 Установка npm зависимостей...")
    run_ssh_command("cd /var/www/x5 && npm install --production")
    print()
    
    # Шаг 6: Создание systemd сервиса
    print("[6/9] ⚙️  Создание systemd сервиса...")
    service_content = """[Unit]
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
WantedBy=multi-user.target"""
    
    run_ssh_command(f"cat > /etc/systemd/system/courier-app.service <<'SERVICEEOF'\n{service_content}\nSERVICEEOF")
    run_ssh_command("chmod -R www-data:www-data /var/www/x5 && systemctl daemon-reload && systemctl start courier-app && systemctl enable courier-app")
    print()
    
    # Шаг 7: Установка Nginx
    print("[7/9] 🌐 Установка и настройка Nginx...")
    run_ssh_command("apt-get install -y nginx")
    
    nginx_config = """server {
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
}"""
    
    run_ssh_command(f"cat > /etc/nginx/sites-available/slotworker.ru <<'NGINXEOF'\n{nginx_config}\nNGINXEOF")
    run_ssh_command("ln -sf /etc/nginx/sites-available/slotworker.ru /etc/nginx/sites-enabled/ && rm -f /etc/nginx/sites-enabled/default && nginx -t && systemctl restart nginx && systemctl enable nginx")
    print()
    
    # Шаг 8: SSL сертификат
    print("[8/9] 🔒 Установка SSL сертификата (Let's Encrypt)...")
    run_ssh_command("apt-get install -y certbot python3-certbot-nginx")
    run_ssh_command("certbot --nginx -d slotworker.ru -d www.slotworker.ru --non-interactive --agree-tos --email admin@slotworker.ru --force-renewal")
    print()
    
    # Шаг 9: Проверка
    print("[9/9] ✅ Проверка работоспособности...")
    run_ssh_command("systemctl status courier-app --no-pager")
    run_ssh_command("curl -s http://localhost:3000/api/stats | head -20")
    print()
    
    print("=" * 50)
    print("  ✅ Развертывание завершено!")
    print("=" * 50)
    print()
    print("🌐 Доступ:")
    print("   https://slotworker.ru")
    print("   https://www.slotworker.ru")
    print()
    print("📊 Статистика:")
    print("   https://slotworker.ru/api/stats")
    print()
    print("🛠️  Команды на сервере:")
    print("   systemctl status courier-app")
    print("   systemctl logs courier-app")
    print("   sqlite3 /var/www/x5/courier_applications.db")
    print()

if __name__ == "__main__":
    main()
