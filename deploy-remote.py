#!/usr/bin/env python3
"""
Удаленное развертывание на сервер slotworker.ru
Подключается через SSH и выполняет все команды
"""

import paramiko
import sys
import time
from io import StringIO

# Параметры подключения
HOST = '62.217.182.74'
USERNAME = 'root'
PASSWORD = '*9w1Z*!R7WxH'
PORT = 22

# Прокси параметры (если нужны)
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
        'warning': '⚠️',
        'progress': '⏳'
    }
    print(f"{symbols.get(status, '•')} {message}")

def execute_command(ssh_client, command, description=""):
    """Выполнить команду на сервере"""
    if description:
        print_status('progress', f"Выполняю: {description}")
    
    print(f"  $ {command}")
    
    stdin, stdout, stderr = ssh_client.exec_command(command)
    output = stdout.read().decode('utf-8', errors='ignore')
    error = stderr.read().decode('utf-8', errors='ignore')
    
    if output:
        for line in output.split('\n'):
            if line.strip():
                print(f"    {line}")
    
    if error and 'warning' not in error.lower():
        print_status('error', f"Ошибка: {error[:100]}")
        return False
    
    return True

def main():
    print("╔════════════════════════════════════════════════════════════════╗")
    print("║      🚀 УДАЛЕННОЕ РАЗВЕРТЫВАНИЕ slotworker.ru                  ║")
    print("╚════════════════════════════════════════════════════════════════╝")
    print()
    
    # Подключиться к серверу
    print_status('progress', f"Подключаюсь к {HOST}:{PORT}...")
    
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        ssh.connect(
            HOST,
            port=PORT,
            username=USERNAME,
            password=PASSWORD,
            timeout=30,
            banner_timeout=30
        )
        
        print_status('success', "✅ Подключение установлено!")
        
    except Exception as e:
        print_status('error', f"❌ Не удалось подключиться: {e}")
        print()
        print("Проблемы с подключением:")
        print("1. Сервер может быть недоступен")
        print("2. Пароль: *9w1Z*!R7WxH (проверьте)")
        print("3. IP: 62.217.182.74 (правильный?)")
        print("4. Может требоваться прокси")
        print()
        print("Альтернатива - подключитесь вручную:")
        print(f"  ssh root@{HOST}")
        print(f"  Затем запустите:")
        print("  sudo bash <(curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/deploy-full-domain.sh)")
        return False
    
    try:
        print()
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Информация о сервере:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        execute_command(ssh, "whoami", "Проверка пользователя")
        execute_command(ssh, "hostname", "Хостнейм")
        execute_command(ssh, "uname -a", "Информация ОС")
        
        print()
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Начинаю развертывание...")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        # Запустить основной скрипт развертывания
        print_status('progress', "Запуск автоматического развертывания...")
        print()
        
        # Получить и запустить скрипт
        deploy_script = "bash <(curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/deploy-full-domain.sh)"
        
        # Для sudo - предоставим пароль
        stdin, stdout, stderr = ssh.exec_command(f"sudo -S {deploy_script}", get_pty=True)
        stdin.write(PASSWORD + "\n")
        stdin.flush()
        
        # Читать вывод в реальном времени
        while True:
            line = stdout.readline()
            if not line:
                break
            print(line.rstrip())
        
        # Проверить ошибки
        error_output = stderr.read().decode('utf-8', errors='ignore')
        if error_output and 'sudo' not in error_output.lower():
            print_status('warning', f"Потенциальные ошибки: {error_output[:200]}")
        
        print()
        print("╔════════════════════════════════════════════════════════════════╗")
        print("║           ✅ РАЗВЕРТЫВАНИЕ ЗАВЕРШЕНО!                          ║")
        print("╚════════════════════════════════════════════════════════════════╝")
        print()
        print("Проверьте сайт:")
        print("  https://slotworker.ru")
        print("  https://www.slotworker.ru")
        print()
        
        # Проверить диагностику
        print_status('progress', "Выполняю финальную диагностику...")
        execute_command(ssh, "bash /var/www/x5/server-diagnostic.sh 2>/dev/null || echo 'Диагностика недоступна'", "")
        
        ssh.close()
        return True
        
    except Exception as e:
        print_status('error', f"Ошибка при развертывании: {e}")
        ssh.close()
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
