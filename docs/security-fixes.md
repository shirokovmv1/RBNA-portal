# План исправления уязвимостей безопасности

## 🔴 КРИТИЧЕСКОЕ: Генерация PDF на сервере

### Проблема
PDF генерируется на клиенте через внешний CDN (PDFMake), что приводит к утечке персональных данных.

### Решение: Генерация PDF на сервере (PHP)

#### Шаг 1: Установка библиотеки TCPDF

```bash
# На сервере (Synology)
cd /var/www/html/bso-portal/api
composer require tecnickcom/tcpdf
```

Или скачать вручную:
```bash
wget https://github.com/tecnickcom/TCPDF/archive/refs/tags/6.6.5.tar.gz
tar -xzf 6.6.5.tar.gz
mv TCPDF-6.6.5 tcpdf
```

#### Шаг 2: Создать PHP endpoint для генерации PDF

**Файл: `api/helpdesk-pdf.php`**

```php
<?php
require_once 'config.php';
require_once 'tcpdf/tcpdf.php';

// Проверка авторизации (опционально, если нужна защита)
// requireAuth();

header('Content-Type: application/pdf');
header('Content-Disposition: attachment; filename="helpdesk_' . ($_GET['number'] ?? 'request') . '.pdf"');

$data = json_decode(file_get_contents('php://input'), true) ?? $_POST;

$requestNumber = htmlspecialchars($data['requestNumber'] ?? '');
$createdAt = htmlspecialchars($data['createdAt'] ?? '');
$name = htmlspecialchars($data['name'] ?? '');
$email = htmlspecialchars($data['email'] ?? '');
$phone = htmlspecialchars($data['phone'] ?? '');
$category = htmlspecialchars($data['category'] ?? '');
$anydesk = htmlspecialchars($data['anydesk'] ?? 'НЕТ');
$description = htmlspecialchars($data['description'] ?? '');

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
$pdf->setLanguageArray([]);

$pdf->AddPage();
$pdf->SetFont('dejavusans', '', 12);

$html = '
<h1 style="text-align:center;font-size:16px;font-weight:bold;margin-bottom:20px;">Заявка в Help Desk</h1>
<p><strong>Номер заявки:</strong> ' . $requestNumber . '</p>
<p><strong>Дата и время заявки:</strong> ' . $createdAt . '</p>
<p><strong>ФИО сотрудника:</strong> ' . $name . '</p>
<p><strong>E-mail сотрудника:</strong> ' . $email . '</p>
<p><strong>Телефон для связи:</strong> ' . $phone . '</p>
<p><strong>Категория проблемы:</strong> ' . $category . '</p>
<p><strong>Any Desk установлен:</strong> ' . $anydesk . '</p>
<p><strong>Описание проблемы:</strong></p>
<p>' . nl2br($description) . '</p>
';

$pdf->writeHTML($html, true, false, true, false, '');
$pdf->Output('helpdesk_' . $requestNumber . '.pdf', 'D');
exit;
```

#### Шаг 3: Обновить `app.js` для использования серверной генерации

**Заменить функцию `saveHelpdeskPdf`:**

```javascript
async function saveHelpdeskPdf() {
    const meta = await getHelpdeskMeta(true);
    setHelpdeskMetaFields(meta);
    const data = getHelpdeskFormData();
    if (!validateHelpdeskData(data)) return;

    try {
        const response = await fetch(`${CONFIG.apiUrl}/helpdesk-pdf.php`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data),
            credentials: 'same-origin'
        });

        if (!response.ok) {
            throw new Error('Ошибка генерации PDF');
        }

        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `helpdesk_${data.requestNumber}.pdf`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
    } catch (error) {
        console.error('Ошибка генерации PDF:', error);
        alert('Ошибка генерации PDF. Попробуйте еще раз.');
    }
}
```

**Обновить функцию `sendHelpdeskRequest`:**

```javascript
async function sendHelpdeskRequest() {
    const meta = await getHelpdeskMeta(true);
    setHelpdeskMetaFields(meta);
    const data = getHelpdeskFormData();
    if (!validateHelpdeskData(data)) return;

    if (!CONFIG.useServerStorage) {
        alert('Серверная отправка недоступна в локальном режиме.');
        return;
    }

    const sendBtn = document.querySelector('button[onclick="sendHelpdeskRequest()"]');
    if (sendBtn) {
        sendBtn.disabled = true;
        sendBtn.textContent = 'Отправка...';
    }

    try {
        // Генерируем PDF на сервере и получаем base64
        const pdfResponse = await fetch(`${CONFIG.apiUrl}/helpdesk-pdf.php?format=base64`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data),
            credentials: 'same-origin'
        });

        if (!pdfResponse.ok) {
            throw new Error('Ошибка генерации PDF');
        }

        const pdfResult = await pdfResponse.json();
        const pdfBase64 = pdfResult.pdfBase64;

        // Отправляем заявку с PDF
        const formData = new FormData();
        formData.append('requestNumber', data.requestNumber);
        formData.append('createdAt', data.createdAt);
        formData.append('name', data.name);
        formData.append('email', data.email);
        formData.append('phone', data.phone);
        formData.append('category', data.category);
        formData.append('anydesk', data.anydesk);
        formData.append('description', data.description);
        formData.append('pdfBase64', pdfBase64);

        const fileInput = document.getElementById('helpdesk-attachment');
        if (fileInput?.files?.[0]) {
            const file = fileInput.files[0];
            if (file.size > HELP_DESK_MAX_FILE_SIZE) {
                openModal('helpdesk-file-size-modal');
                return;
            }
            formData.append('attachment', file);
        }

        const response = await fetch(`${CONFIG.apiUrl}/helpdesk.php?action=submit`, {
            method: 'POST',
            body: formData,
            credentials: 'same-origin'
        });

        const result = await response.json();
        if (response.ok && result.success) {
            alert(`Заявка отправлена. Номер: ${result.requestNumber}`);
            document.getElementById('helpdesk-form').reset();
            await initHelpdeskForm();
        } else {
            alert(result.error || 'Ошибка отправки заявки');
        }
    } catch (error) {
        console.error('Ошибка отправки заявки:', error);
        alert('Ошибка отправки заявки');
    } finally {
        if (sendBtn) {
            sendBtn.disabled = false;
            sendBtn.textContent = '📤 Отправить заявку';
        }
    }
}
```

#### Шаг 4: Удалить зависимость от PDFMake CDN

**В `it-help.html`:**
```html
<!-- УДАЛИТЬ эти строки: -->
<!-- <script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.7/pdfmake.min.js"></script> -->
<!-- <script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.7/vfs_fonts.js"></script> -->
```

---

## 🔴 КРИТИЧЕСКОЕ: Безопасная отправка Email

### Проблема
Персональные данные отправляются через SMTP без дополнительных мер безопасности.

### Решение

#### Шаг 1: Обновить `api/helpdesk.php` для безопасной отправки

```php
function sendMailWithAttachments($to, $subject, $html, $from, $attachments = [], $replyTo = null) {
    // Использовать PHPMailer вместо mail() для лучшей безопасности
    // Или настроить SMTP с обязательным TLS
    
    // Проверка TLS (должно быть настроено в php.ini)
    $boundary = 'bso-' . md5(uniqid('', true));
    $headers = "MIME-Version: 1.0\r\n";
    $headers .= "From: {$from}\r\n";
    if ($replyTo) {
        $headers .= "Reply-To: {$replyTo}\r\n";
    }
    $headers .= "Content-Type: multipart/mixed; boundary=\"{$boundary}\"\r\n";
    $headers .= "X-Priority: 3\r\n"; // Нормальный приоритет
    $headers .= "X-Mailer: BSO Portal\r\n";

    $body = "--{$boundary}\r\n";
    $body .= "Content-Type: text/html; charset=UTF-8\r\n";
    $body .= "Content-Transfer-Encoding: base64\r\n\r\n";
    $body .= chunk_split(base64_encode($html)) . "\r\n";

    foreach ($attachments as $attachment) {
        $body .= "--{$boundary}\r\n";
        $body .= "Content-Type: {$attachment['type']}; name=\"{$attachment['name']}\"\r\n";
        $body .= "Content-Transfer-Encoding: base64\r\n";
        $body .= "Content-Disposition: attachment; filename=\"{$attachment['name']}\"\r\n\r\n";
        $body .= chunk_split(base64_encode($attachment['content'])) . "\r\n";
    }

    $body .= "--{$boundary}--";

    return mail($to, $subject, $body, $headers);
}
```

#### Шаг 2: Добавить предупреждение в форму

**В `it-help.html` добавить перед формой:**
```html
<div class="alert alert-warning" style="background: #fff3cd; border: 1px solid #ffc107; padding: 12px; border-radius: 4px; margin-bottom: 20px;">
    <strong>⚠️ Внимание:</strong> Отправляя заявку, вы соглашаетесь с обработкой персональных данных. 
    Данные будут переданы в ИТ отдел и могут быть использованы для решения вашей проблемы.
</div>
```

---

## 🔴 КРИТИЧЕСКОЕ: Ограничение экспорта контактов

### Проблема
Любой пользователь с доступом к админ-панели может экспортировать все контакты.

### Решение

#### Шаг 1: Добавить логирование экспорта

**В `app.js` обновить `exportContactsCsv`:**

```javascript
async function exportContactsCsv() {
    // Проверка авторизации
    if (!getAuthToken()) {
        alert('Необходима авторизация для экспорта контактов');
        return;
    }

    // Подтверждение
    const confirmed = confirm(
        '⚠️ ВНИМАНИЕ: Вы собираетесь экспортировать персональные данные сотрудников.\n\n' +
        'Экспортированные данные содержат конфиденциальную информацию и должны храниться в соответствии с политикой безопасности компании.\n\n' +
        'Продолжить экспорт?'
    );
    
    if (!confirmed) {
        return;
    }

    try {
        // Логирование экспорта на сервере
        await fetch(`${CONFIG.apiUrl}/audit.php`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${getAuthToken()}`
            },
            body: JSON.stringify({
                action: 'export_contacts',
                timestamp: new Date().toISOString()
            }),
            credentials: 'same-origin'
        });

        const contacts = await dataManager.getContacts();
        const header = [
            '№',
            'Ф.И.О.',
            'Должность',
            'Компания',
            'Внутренний номер',
            'Дата рождения',
            'Контактный телефон',
            'E-mail'
        ];
        const rows = [header.join(';')];
        contacts.forEach((contact, index) => {
            rows.push([
                index + 1,
                csvEscape(contact.name),
                csvEscape(contact.position),
                csvEscape(contact.company || ''),
                csvEscape(contact.internalNumber || ''),
                csvEscape(contact.birthDate || ''),
                csvEscape(contact.phone),
                csvEscape(contact.email)
            ].join(';'));
        });

        const bom = '\uFEFF';
        const blob = new Blob([bom + rows.join('\r\n')], { type: 'text/csv;charset=utf-8;' });
        downloadBlob(blob, 'contacts_' + new Date().toISOString().split('T')[0] + '.csv');
    } catch (error) {
        console.error('Ошибка экспорта:', error);
        alert('Ошибка экспорта контактов');
    }
}
```

#### Шаг 2: Создать endpoint для логирования

**Файл: `api/audit.php`**

```php
<?php
require_once 'config.php';

requireAuth(); // Только авторизованные пользователи

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error('Метод не поддерживается', 405);
}

$data = json_decode(file_get_contents('php://input'), true);
$action = $data['action'] ?? 'unknown';
$timestamp = $data['timestamp'] ?? date('c');

// Получить информацию о пользователе из сессии
$username = $_SESSION['username'] ?? 'unknown';

$logEntry = [
    'timestamp' => $timestamp,
    'username' => $username,
    'action' => $action,
    'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown'
];

$logFile = DATA_DIR . 'audit.log';
$logLine = json_encode($logEntry, JSON_UNESCAPED_UNICODE) . "\n";
file_put_contents($logFile, $logLine, FILE_APPEND);

respond(['success' => true]);
```

---

## 🟡 СРЕДНЕЕ: Улучшение безопасности localStorage

### Решение

#### Шаг 1: Использовать sessionStorage для временных данных

**В `app.js` заменить `localStorage` на `sessionStorage` для:**
- Токенов авторизации (лучше использовать httpOnly cookies)
- Временных данных формы

#### Шаг 2: Очистка данных при выходе

**В `admin.html` обновить функцию выхода:**

```javascript
function handleLogout() {
    // Очистить все данные из localStorage
    localStorage.removeItem(AUTH_KEY);
    localStorage.removeItem(LOCAL_ADMINS_KEY);
    localStorage.removeItem(LEGACY_ADMIN_KEY);
    
    // Очистить sessionStorage
    sessionStorage.clear();
    
    // Перенаправить на страницу входа
    window.location.href = 'admin.html';
}
```

---

## 🟡 СРЕДНЕЕ: Локализация внешних ресурсов

### Решение

#### Шаг 1: Скачать Google Fonts локально

```bash
# На сервере
cd /var/www/html/bso-portal
mkdir -p fonts
# Скачать шрифты Montserrat и Roboto
# Использовать google-webfonts-helper или аналогичный инструмент
```

**Обновить `styles.css`:**
```css
/* Вместо @import url('https://fonts.googleapis.com/...') */
@font-face {
    font-family: 'Montserrat';
    src: url('fonts/montserrat-v25-latin-regular.woff2') format('woff2');
    font-weight: 400;
}
/* ... остальные варианты шрифтов ... */
```

#### Шаг 2: Удалить зависимость от PDFMake CDN

(Уже описано выше в разделе генерации PDF)

---

## 📋 ЧЕКЛИСТ ВНЕДРЕНИЯ

- [ ] Установить TCPDF на сервере
- [ ] Создать `api/helpdesk-pdf.php`
- [ ] Обновить `app.js` для серверной генерации PDF
- [ ] Удалить PDFMake CDN из HTML
- [ ] Добавить предупреждение о конфиденциальности в форму
- [ ] Настроить SMTP с TLS
- [ ] Добавить логирование экспорта контактов
- [ ] Создать `api/audit.php`
- [ ] Обновить функцию экспорта с подтверждением
- [ ] Перейти на sessionStorage для временных данных
- [ ] Добавить очистку данных при выходе
- [ ] Локализовать Google Fonts
- [ ] Протестировать все изменения

---

**Примечание:** После внедрения всех изменений провести повторный аудит безопасности.
