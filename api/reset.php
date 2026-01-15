<?php
// API для сброса данных к значениям по умолчанию
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'POST') {
    error('Метод не поддерживается', 405);
}

requireAuth();

$filesToReset = [
    'news',
    'events',
    'applications',
    'contacts',
    'faq',
    'manuals',
    'helpdesk',
    'it-contacts'
];

foreach ($filesToReset as $file) {
    deleteData($file);
}

respond(['success' => true]);
