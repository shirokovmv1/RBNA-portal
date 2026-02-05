# PowerShell скрипт для автоматического развертывания на сервер 151.245.137.147
# Использование: .\deploy.ps1

$serverIP = "151.245.137.147"
$serverPassword = "u14YDBo+u4"
$serverUser = "root"

Write-Host "🚀 Начало развертывания RBNA Portal на $serverIP" -ForegroundColor Green
Write-Host ""

# Проверка наличия SSH
if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ SSH не найден. Установите OpenSSH или используйте команды вручную." -ForegroundColor Red
    exit 1
}

# Функция для выполнения команд на удаленном сервере
function Invoke-RemoteCommand {
    param(
        [string]$Command,
        [string]$Server = $serverIP,
        [string]$User = $serverUser,
        [string]$Password = $serverPassword
    )
    
    # Используем sshpass если доступен, иначе обычный ssh
    if (Get-Command sshpass -ErrorAction SilentlyContinue) {
        $env:SSHPASS = $Password
        sshpass -e ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${User}@${Server}" $Command
    } else {
        # Альтернативный способ через expect или plink
        Write-Host "⚠️  sshpass не найден. Выполните команды вручную." -ForegroundColor Yellow
        Write-Host "Команда для выполнения: $Command" -ForegroundColor Cyan
        return $false
    }
}

# Загрузка скрипта на сервер
Write-Host "📤 Загрузка скрипта развертывания на сервер..." -ForegroundColor Cyan

# Используем SCP для загрузки
if (Get-Command scp -ErrorAction SilentlyContinue) {
    if (Get-Command sshpass -ErrorAction SilentlyContinue) {
        $env:SSHPASS = $serverPassword
        sshpass -e scp -o StrictHostKeyChecking=no deploy_to_151.245.137.147.sh "${serverUser}@${serverIP}:/root/"
        Write-Host "✅ Скрипт загружен" -ForegroundColor Green
    } else {
        Write-Host "⚠️  sshpass не найден. Загрузите скрипт вручную:" -ForegroundColor Yellow
        Write-Host "scp deploy_to_151.245.137.147.sh ${serverUser}@${serverIP}:/root/" -ForegroundColor Cyan
    }
} else {
    Write-Host "⚠️  SCP не найден. Загрузите скрипт вручную." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Выполните следующие команды на сервере:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Подключитесь к серверу:" -ForegroundColor Cyan
Write-Host "   ssh ${serverUser}@${serverIP}" -ForegroundColor White
Write-Host "   Пароль: $serverPassword" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Запустите развертывание:" -ForegroundColor Cyan
Write-Host "   chmod +x /root/deploy_to_151.245.137.147.sh" -ForegroundColor White
Write-Host "   /root/deploy_to_151.245.137.147.sh" -ForegroundColor White
Write-Host ""
Write-Host "Или используйте готовые команды из DEPLOY_COMMANDS.md" -ForegroundColor Green
