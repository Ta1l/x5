@echo off
REM Скрипт для развертывания x5 на сервер
REM Для Windows - используем встроенный SSH

setlocal enabledelayedexpansion

set PROXY_HOST=46.8.17.103
set PROXY_PORT=5501
set PROXY_USER=6NeZMV
set PROXY_PASS=iSxcP9mEj0

set SERVER_HOST=62.217.182.74
set SERVER_USER=root
set SERVER_PASS=*9w1Z*!R7WxH

echo.
echo ============================================
echo.   ^!^! ВНИМАНИЕ ^!^!
echo ============================================
echo.
echo Так как Password-based SSH автоматизация
echo на Windows затруднена, используйте один
echo из следующих методов:
echo.
echo МЕТОД 1: Копирование команды в PowerShell
echo =========================================
echo.
echo Скопируйте эту команду и выполните в PowerShell:
echo.
powershell -Command "Write-Host 'pwsh (New-Object PSCredential('root',(ConvertTo-SecureString '*9w1Z*!R7WxH' -AsPlainText -Force))).GetNetworkCredential().Password'"
echo.
echo МЕТОД 2: Использование быстрого скрипта
echo =========================================
echo.
echo Запустите на сервере:
echo.
echo   bash ^<(curl -fsSL https://raw.githubusercontent.com/Ta1l/x5/main/quick-deploy.sh)
echo.
echo МЕТОД 3: Через PuTTY или MobaXterm
echo ===============================
echo.
echo   1. Откройте PuTTY
echo   2. Host: 62.217.182.74
echo   3. Port: 22
echo   4. User: root
echo   5. Password: *9w1Z*!R7WxH
echo   6. Выполните развертывание
echo.
echo.
pause
