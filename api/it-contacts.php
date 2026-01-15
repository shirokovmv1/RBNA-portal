<?php
// API для контактов ИТ отдела
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];
$data = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        $contacts = readData('it-contacts');
        if (empty($contacts)) {
            $contacts = [
                [
                    'id' => 1,
                    'type' => 'email',
                    'icon' => '📧',
                    'title' => 'Email',
                    'description' => 'Для обращений в IT отдел',
                    'value' => 'it@bso-cc.ru',
                    'link' => 'mailto:it@bso-cc.ru'
                ],
                [
                    'id' => 2,
                    'type' => 'phone',
                    'icon' => '📱',
                    'title' => 'Телефон',
                    'description' => 'Для срочных вопросов',
                    'value' => '+7 (495) 147-55-66',
                    'link' => 'tel:+74951475566'
                ],
                [
                    'id' => 3,
                    'type' => 'address',
                    'icon' => '📍',
                    'title' => 'Адрес офиса',
                    'description' => 'Москва, Ленинский пр.',
                    'value' => 'д. 11, стр. 2',
                    'link' => ''
                ]
            ];
            writeData('it-contacts', $contacts);
        }
        respond($contacts);
        break;

    case 'POST':
        requireAuth();
        $contacts = readData('it-contacts');
        $newItem = [
            'id' => time(),
            'type' => $data['type'] ?? 'other',
            'icon' => $data['icon'] ?? '',
            'title' => $data['title'] ?? '',
            'description' => $data['description'] ?? '',
            'value' => $data['value'] ?? '',
            'link' => $data['link'] ?? ''
        ];
        $contacts[] = $newItem;
        writeData('it-contacts', $contacts);
        respond($newItem, 201);
        break;

    case 'PUT':
        requireAuth();
        if (!isset($data['id'])) error('ID не указан');
        $contacts = readData('it-contacts');
        foreach ($contacts as &$item) {
            if ($item['id'] == $data['id']) {
                $item['type'] = $data['type'] ?? $item['type'];
                $item['icon'] = $data['icon'] ?? $item['icon'];
                $item['title'] = $data['title'] ?? $item['title'];
                $item['description'] = $data['description'] ?? $item['description'];
                $item['value'] = $data['value'] ?? $item['value'];
                $item['link'] = $data['link'] ?? $item['link'];
                writeData('it-contacts', $contacts);
                respond($item);
            }
        }
        error('Контакт не найден', 404);
        break;

    case 'DELETE':
        requireAuth();
        $id = $_GET['id'] ?? null;
        if (!$id) error('ID не указан');
        $contacts = readData('it-contacts');
        $contacts = array_filter($contacts, fn($item) => $item['id'] != $id);
        $contacts = array_values($contacts);
        writeData('it-contacts', $contacts);
        respond(['success' => true]);
        break;

    default:
        error('Метод не поддерживается', 405);
}
