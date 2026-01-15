<?php
// Конфигурация API
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

header('Content-Type: application/json; charset=utf-8');

$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https://' : 'http://';
$host = $scheme . ($_SERVER['HTTP_HOST'] ?? '');
$allowedOrigins = [$host];
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';

if ($origin && in_array($origin, $allowedOrigins, true)) {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Vary: Origin');
}

header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Auth-Token');

// Обработка preflight запросов
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Путь к файлам данных
define('DATA_DIR', __DIR__ . '/data/');

// Создаём папку data если не существует
if (!file_exists(DATA_DIR)) {
    mkdir(DATA_DIR, 0755, true);
}

// Функция чтения данных
function readData($file) {
    $path = DATA_DIR . $file . '.json';
    if (file_exists($path)) {
        $content = file_get_contents($path);
        return json_decode($content, true) ?: [];
    }
    return [];
}

// Функция записи данных
function writeData($file, $data) {
    $path = DATA_DIR . $file . '.json';
    return file_put_contents($path, json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
}

// Функция удаления данных
function deleteData($file) {
    $path = DATA_DIR . $file . '.json';
    if (file_exists($path)) {
        return unlink($path);
    }
    return true;
}

// Функция ответа
function respond($data, $code = 200) {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

// Функция ошибки
function error($message, $code = 400) {
    respond(['error' => $message], $code);
}

// Проверка авторизации
function requireAuth() {
    if (!isset($_SESSION['logged_in']) || $_SESSION['logged_in'] !== true) {
        error('Не авторизован', 401);
    }

    $token = '';
    if (!empty($_SERVER['HTTP_AUTHORIZATION']) && preg_match('/Bearer\s+(.*)$/i', $_SERVER['HTTP_AUTHORIZATION'], $matches)) {
        $token = trim($matches[1]);
    } elseif (!empty($_SERVER['HTTP_X_AUTH_TOKEN'])) {
        $token = trim($_SERVER['HTTP_X_AUTH_TOKEN']);
    }

    if (!empty($_SESSION['token'])) {
        if (!$token) {
            error('Требуется токен', 401);
        }
        if (!hash_equals($_SESSION['token'], $token)) {
            error('Неверный токен', 401);
        }
    }
}
