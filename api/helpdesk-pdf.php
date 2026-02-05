<?php
/**
 * Генерация PDF для заявок Help Desk на сервере
 * Устраняет утечку данных через внешний CDN
 */

require_once 'config.php';

date_default_timezone_set('Europe/Moscow');

// Проверка метода запроса
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Метод не поддерживается']);
    exit;
}

// Получение данных
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data) {
    http_response_code(400);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Некорректные данные']);
    exit;
}

// Валидация обязательных полей
$requestNumber = trim($data['requestNumber'] ?? '');
$createdAt = trim($data['createdAt'] ?? '');
$name = trim($data['name'] ?? '');
$email = trim($data['email'] ?? '');
$phone = trim($data['phone'] ?? '');
$category = trim($data['category'] ?? '');
$anydesk = trim($data['anydesk'] ?? 'НЕТ');
$description = trim($data['description'] ?? '');

if (!$requestNumber || !$name || !$email || !$phone || !$category || !$description) {
    http_response_code(400);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Заполните все обязательные поля']);
    exit;
}

// Экранирование данных для безопасности
$requestNumberSafe = htmlspecialchars($requestNumber, ENT_QUOTES, 'UTF-8');
$createdAtSafe = htmlspecialchars($createdAt, ENT_QUOTES, 'UTF-8');
$nameSafe = htmlspecialchars($name, ENT_QUOTES, 'UTF-8');
$emailSafe = htmlspecialchars($email, ENT_QUOTES, 'UTF-8');
$phoneSafe = htmlspecialchars($phone, ENT_QUOTES, 'UTF-8');
$categorySafe = htmlspecialchars($category, ENT_QUOTES, 'UTF-8');
$anydeskSafe = htmlspecialchars($anydesk, ENT_QUOTES, 'UTF-8');
$descriptionSafe = nl2br(htmlspecialchars($description, ENT_QUOTES, 'UTF-8'));

// Проверка формата запроса (download или base64)
$format = $_GET['format'] ?? 'download';

// Попытка использовать TCPDF, если доступен
// Проверяем несколько возможных путей установки
$tcpdfPath = null;
$possiblePaths = [
    __DIR__ . '/vendor/tecnickcom/tcpdf/tcpdf.php',  // Composer установка
    __DIR__ . '/tcpdf/tcpdf.php'                      // Ручная установка
];

foreach ($possiblePaths as $path) {
    if (file_exists($path)) {
        $tcpdfPath = $path;
        break;
    }
}

$useTcpdf = ($tcpdfPath !== null);

if ($useTcpdf && $tcpdfPath) {
    require_once $tcpdfPath;
    
    $pdf = new TCPDF(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false);
    $pdf->SetCreator('БСО Портал');
    $pdf->SetAuthor('БСО Портал');
    $pdf->SetTitle('Заявка в Help Desk');
    $pdf->SetSubject('Заявка в Help Desk');
    
    $pdf->setPrintHeader(false);
    $pdf->setPrintFooter(false);
    $pdf->SetDefaultMonospacedFont(PDF_FONT_MONOSPACED);
    $pdf->SetMargins(15, 15, 15);
    $pdf->SetAutoPageBreak(TRUE, 15);
    $pdf->setImageScale(PDF_IMAGE_SCALE_RATIO);
    
    $pdf->AddPage();
    $pdf->SetFont('dejavusans', '', 12);
    
    $html = '
    <h1 style="text-align:center;font-size:16px;font-weight:bold;margin-bottom:20px;">Заявка в Help Desk</h1>
    <p><strong>Номер заявки:</strong> ' . $requestNumberSafe . '</p>
    <p><strong>Дата и время заявки:</strong> ' . $createdAtSafe . '</p>
    <p><strong>ФИО сотрудника:</strong> ' . $nameSafe . '</p>
    <p><strong>E-mail сотрудника:</strong> ' . $emailSafe . '</p>
    <p><strong>Телефон для связи:</strong> ' . $phoneSafe . '</p>
    <p><strong>Категория проблемы:</strong> ' . $categorySafe . '</p>
    <p><strong>Any Desk установлен:</strong> ' . $anydeskSafe . '</p>
    <p><strong>Описание проблемы:</strong></p>
    <p>' . $descriptionSafe . '</p>
    ';
    
    $pdf->writeHTML($html, true, false, true, false, '');
    
    if ($format === 'base64') {
        // Возвращаем base64 для отправки по email
        $pdfContent = $pdf->Output('', 'S');
        header('Content-Type: application/json');
        echo json_encode(['pdfBase64' => base64_encode($pdfContent)]);
    } else {
        // Скачивание файла
        $pdf->Output('helpdesk_' . $requestNumberSafe . '.pdf', 'D');
    }
    exit;
}

// Fallback: простая генерация PDF через HTML (если TCPDF недоступен)
// Используем простой подход с правильными заголовками
// В продакшене рекомендуется установить TCPDF

$html = '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Заявка в Help Desk</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        h1 { text-align: center; font-size: 18px; margin-bottom: 20px; }
        p { margin: 8px 0; }
        strong { font-weight: bold; }
    </style>
</head>
<body>
    <h1>Заявка в Help Desk</h1>
    <p><strong>Номер заявки:</strong> ' . $requestNumberSafe . '</p>
    <p><strong>Дата и время заявки:</strong> ' . $createdAtSafe . '</p>
    <p><strong>ФИО сотрудника:</strong> ' . $nameSafe . '</p>
    <p><strong>E-mail сотрудника:</strong> ' . $emailSafe . '</p>
    <p><strong>Телефон для связи:</strong> ' . $phoneSafe . '</p>
    <p><strong>Категория проблемы:</strong> ' . $categorySafe . '</p>
    <p><strong>Any Desk установлен:</strong> ' . $anydeskSafe . '</p>
    <p><strong>Описание проблемы:</strong></p>
    <p>' . $descriptionSafe . '</p>
</body>
</html>';

if ($format === 'base64') {
    // Для base64 формата возвращаем HTML (клиент может конвертировать)
    // Или можно использовать wkhtmltopdf, если установлен
    header('Content-Type: application/json');
    echo json_encode([
        'pdfBase64' => base64_encode($html),
        'warning' => 'TCPDF не установлен. Используется HTML fallback. Установите TCPDF для полной поддержки PDF.'
    ]);
} else {
    // Возвращаем HTML (браузер может сохранить как PDF)
    header('Content-Type: text/html; charset=UTF-8');
    header('Content-Disposition: attachment; filename="helpdesk_' . $requestNumberSafe . '.html"');
    echo $html;
}
