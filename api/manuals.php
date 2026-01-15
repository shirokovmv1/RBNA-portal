<?php
// API для мануалов
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];
$data = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        $manuals = readData('manuals');
        if (empty($manuals)) {
            $manuals = [
                [
                    'id' => 1,
                    'title' => 'Инструкция по работе с почтой',
                    'description' => 'Настройка почтового клиента и основы работы',
                    'url' => 'manuals/email.pdf'
                ],
                [
                    'id' => 2,
                    'title' => 'Руководство по 1С',
                    'description' => 'Базовые операции в программе 1С:Предприятие',
                    'url' => 'manuals/1c-guide.pdf'
                ]
            ];
            writeData('manuals', $manuals);
        }
        respond($manuals);
        break;

    case 'POST':
        requireAuth();
        $manuals = readData('manuals');
        $newItem = [
            'id' => time(),
            'title' => $data['title'] ?? '',
            'description' => $data['description'] ?? '',
            'url' => $data['url'] ?? ''
        ];
        $manuals[] = $newItem;
        writeData('manuals', $manuals);
        respond($newItem, 201);
        break;

    case 'PUT':
        requireAuth();
        if (!isset($data['id'])) error('ID не указан');
        $manuals = readData('manuals');
        foreach ($manuals as &$item) {
            if ($item['id'] == $data['id']) {
                $item['title'] = $data['title'] ?? $item['title'];
                $item['description'] = $data['description'] ?? $item['description'];
                $item['url'] = $data['url'] ?? $item['url'];
                writeData('manuals', $manuals);
                respond($item);
            }
        }
        error('Мануал не найден', 404);
        break;

    case 'DELETE':
        requireAuth();
        $id = $_GET['id'] ?? null;
        if (!$id) error('ID не указан');
        $manuals = readData('manuals');
        $manuals = array_filter($manuals, fn($item) => $item['id'] != $id);
        $manuals = array_values($manuals);
        writeData('manuals', $manuals);
        respond(['success' => true]);
        break;

    default:
        error('Метод не поддерживается', 405);
}
