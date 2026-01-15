<?php
// API для категорий Help Desk
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];
$data = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        $categories = readData('helpdesk');
        if (empty($categories)) {
            $categories = [
                ['id' => 1, 'value' => 'hardware', 'label' => 'Оборудование (ПК, принтер, монитор)'],
                ['id' => 2, 'value' => 'software', 'label' => 'Программное обеспечение'],
                ['id' => 3, 'value' => 'network', 'label' => 'Сеть и интернет'],
                ['id' => 4, 'value' => 'email', 'label' => 'Электронная почта'],
                ['id' => 5, 'value' => 'access', 'label' => 'Доступ и пароли'],
                ['id' => 6, 'value' => '1c', 'label' => '1С и учётные системы'],
                ['id' => 7, 'value' => 'other', 'label' => 'Другое']
            ];
            writeData('helpdesk', $categories);
        }
        respond($categories);
        break;

    case 'POST':
        requireAuth();
        $categories = readData('helpdesk');
        $newItem = [
            'id' => time(),
            'value' => $data['value'] ?? '',
            'label' => $data['label'] ?? ''
        ];
        $categories[] = $newItem;
        writeData('helpdesk', $categories);
        respond($newItem, 201);
        break;

    case 'PUT':
        requireAuth();
        if (!isset($data['id'])) error('ID не указан');
        $categories = readData('helpdesk');
        foreach ($categories as &$item) {
            if ($item['id'] == $data['id']) {
                $item['value'] = $data['value'] ?? $item['value'];
                $item['label'] = $data['label'] ?? $item['label'];
                writeData('helpdesk', $categories);
                respond($item);
            }
        }
        error('Категория не найдена', 404);
        break;

    case 'DELETE':
        requireAuth();
        $id = $_GET['id'] ?? null;
        if (!$id) error('ID не указан');
        $categories = readData('helpdesk');
        $categories = array_filter($categories, fn($item) => $item['id'] != $id);
        $categories = array_values($categories);
        writeData('helpdesk', $categories);
        respond(['success' => true]);
        break;

    default:
        error('Метод не поддерживается', 405);
}
