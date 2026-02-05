<?php
/**
 * Скрипт установки TCPDF для BSO Portal
 * Запустите: php install-tcpdf.php
 */

echo "==========================================\n";
echo "Установка TCPDF для BSO Portal\n";
echo "==========================================\n\n";

$apiDir = __DIR__;
chdir($apiDir);

// Проверка версии PHP
if (version_compare(PHP_VERSION, '7.0.0', '<')) {
    die("❌ Ошибка: Требуется PHP 7.0 или выше. Текущая версия: " . PHP_VERSION . "\n");
}

echo "✅ PHP версия: " . PHP_VERSION . "\n\n";

// Вариант 1: Установка через Composer (если доступен)
$composerPath = null;
if (file_exists('composer.phar')) {
    $composerPath = 'php composer.phar';
    echo "📦 Найден локальный Composer\n";
} elseif (shell_exec('which composer 2>/dev/null')) {
    $composerPath = 'composer';
    echo "📦 Найден системный Composer\n";
}

if ($composerPath) {
    echo "📦 Установка TCPDF через Composer...\n";
    $command = "$composerPath require tecnickcom/tcpdf --no-interaction 2>&1";
    $output = shell_exec($command);
    
    if (file_exists('vendor/tecnickcom/tcpdf/tcpdf.php')) {
        echo "✅ TCPDF успешно установлен через Composer\n";
        echo "📁 Путь: vendor/tecnickcom/tcpdf/tcpdf.php\n";
        exit(0);
    } else {
        echo "⚠️  Composer не смог установить TCPDF, пробуем другой способ...\n\n";
    }
}

// Вариант 2: Скачать и установить Composer локально
if (!file_exists('composer.phar')) {
    echo "📥 Загрузка Composer...\n";
    $composerInstaller = file_get_contents('https://getcomposer.org/installer');
    if ($composerInstaller) {
        file_put_contents('composer-setup.php', $composerInstaller);
        include 'composer-setup.php';
        unlink('composer-setup.php');
        
        if (file_exists('composer.phar')) {
            echo "✅ Composer установлен\n";
            echo "📦 Установка TCPDF...\n";
            $output = shell_exec('php composer.phar require tecnickcom/tcpdf --no-interaction 2>&1');
            
            if (file_exists('vendor/tecnickcom/tcpdf/tcpdf.php')) {
                echo "✅ TCPDF успешно установлен\n";
                echo "📁 Путь: vendor/tecnickcom/tcpdf/tcpdf.php\n";
                exit(0);
            }
        }
    }
}

// Вариант 3: Ручная установка
echo "📥 Ручная установка TCPDF...\n";
$tcpdfVersion = '6.6.5';
$tcpdfUrl = "https://github.com/tecnickcom/TCPDF/archive/refs/tags/{$tcpdfVersion}.tar.gz";
$tcpdfArchive = 'tcpdf.tar.gz';

// Скачивание
echo "📥 Скачивание TCPDF {$tcpdfVersion}...\n";
$archiveContent = @file_get_contents($tcpdfUrl);

if (!$archiveContent) {
    // Попробуем через curl, если доступен
    if (function_exists('curl_init')) {
        $ch = curl_init($tcpdfUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
        $archiveContent = curl_exec($ch);
        curl_close($ch);
    }
}

if (!$archiveContent) {
    die("❌ Ошибка: Не удалось скачать TCPDF. Проверьте подключение к интернету.\n");
}

file_put_contents($tcpdfArchive, $archiveContent);

// Распаковка
echo "📦 Распаковка архива...\n";
if (class_exists('PharData')) {
    $phar = new PharData($tcpdfArchive);
    $phar->extractTo($apiDir);
} else {
    // Альтернативный способ распаковки через команду системы
    if (PHP_OS_FAMILY === 'Windows') {
        // Windows - используем 7zip или tar (если доступен)
        $command = "tar -xzf \"$tcpdfArchive\" 2>&1";
    } else {
        // Linux/Mac
        $command = "tar -xzf \"$tcpdfArchive\" 2>&1";
    }
    exec($command, $output, $returnCode);
    if ($returnCode !== 0) {
        die("❌ Ошибка: Не удалось распаковать архив. Установите tar или используйте Composer.\n");
    }
}

// Переименование
$extractedDir = "TCPDF-{$tcpdfVersion}";
if (is_dir($extractedDir)) {
    if (is_dir('tcpdf')) {
        echo "⚠️  Директория tcpdf уже существует, удаляем старую...\n";
        removeDirectory('tcpdf');
    }
    rename($extractedDir, 'tcpdf');
    unlink($tcpdfArchive);
    
    if (file_exists('tcpdf/tcpdf.php')) {
        echo "✅ TCPDF успешно установлен вручную\n";
        echo "📁 Путь: tcpdf/tcpdf.php\n";
        
        // Установка прав доступа
        chmod('tcpdf', 0755);
        echo "✅ Права доступа установлены\n";
        exit(0);
    } else {
        die("❌ Ошибка: TCPDF не найден после распаковки\n");
    }
} else {
    die("❌ Ошибка: Не удалось распаковать архив\n");
}

function removeDirectory($dir) {
    if (!is_dir($dir)) return;
    $files = array_diff(scandir($dir), ['.', '..']);
    foreach ($files as $file) {
        $path = $dir . '/' . $file;
        is_dir($path) ? removeDirectory($path) : unlink($path);
    }
    rmdir($dir);
}
