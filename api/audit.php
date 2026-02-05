<?php
/**
 * Логирование действий пользователей для аудита безопасности
 */
require_once 'config.php';

// Проверка авторизации
requireAuth();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error('Метод не поддерживается', 405);
}

$data = json_decode(file_get_contents('php://input'), true);
$action = $data['action'] ?? 'unknown';
$timestamp = $data['timestamp'] ?? date('c');
$details = $data['details'] ?? [];

// Получить информацию о пользователе из сессии
$username = $_SESSION['username'] ?? 'unknown';
$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$userAgent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';

$logEntry = [
    'timestamp' => $timestamp,
    'username' => $username,
    'action' => $action,
    'ip' => $ip,
    'userAgent' => $userAgent,
    'details' => $details
];

$logFile = DATA_DIR . 'audit.log';

// Создать директорию, если не существует
if (!file_exists(DATA_DIR)) {
    mkdir(DATA_DIR, 0755, true);
}

// Записать в лог
$logLine = json_encode($logEntry, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT) . "\n";
file_put_contents($logFile, $logLine, FILE_APPEND | LOCK_EX);

respond(['success' => true, 'logged' => true]);
