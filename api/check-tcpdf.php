<?php
/**
 * Скрипт проверки установки TCPDF
 * Откройте в браузере: http://your-domain/api/check-tcpdf.php
 */

header('Content-Type: text/html; charset=UTF-8');
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Проверка установки TCPDF</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; max-width: 800px; margin: 0 auto; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
        .info { background: #e7f3ff; padding: 15px; border-left: 4px solid #2196F3; margin: 10px 0; }
        .code { background: #f5f5f5; padding: 10px; border-radius: 4px; font-family: monospace; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>🔍 Проверка установки TCPDF</h1>
    
    <?php
    $apiDir = __DIR__;
    $found = false;
    $tcpdfPath = null;
    $tcpdfVersion = null;
    
    // Проверяем возможные пути
    $possiblePaths = [
        'vendor/tecnickcom/tcpdf/tcpdf.php' => 'Composer установка',
        'tcpdf/tcpdf.php' => 'Ручная установка'
    ];
    
    echo "<div class='info'><strong>Проверка путей установки:</strong></div>";
    
    foreach ($possiblePaths as $path => $description) {
        $fullPath = $apiDir . '/' . $path;
        if (file_exists($fullPath)) {
            echo "<div class='success'>✅ Найден: <code>$path</code> ($description)</div>";
            $found = true;
            $tcpdfPath = $fullPath;
            break;
        } else {
            echo "<div class='warning'>⚠️  Не найден: <code>$path</code></div>";
        }
    }
    
    if ($found && $tcpdfPath) {
        echo "<div class='info'><strong>Попытка загрузки TCPDF...</strong></div>";
        
        try {
            require_once $tcpdfPath;
            
            if (class_exists('TCPDF')) {
                echo "<div class='success'>✅ TCPDF успешно загружен!</div>";
                
                // Пытаемся получить версию
                if (defined('TCPDF_STATIC')) {
                    $tcpdfVersion = TCPDF_STATIC::getTCPDFVersion();
                    echo "<div class='success'>✅ Версия TCPDF: <strong>$tcpdfVersion</strong></div>";
                }
                
                // Тестовая генерация PDF
                echo "<div class='info'><strong>Тестовая генерация PDF...</strong></div>";
                try {
                    $pdf = new TCPDF(PDF_PAGE_ORIENTATION, PDF_UNIT, PDF_PAGE_FORMAT, true, 'UTF-8', false);
                    $pdf->SetCreator('BSO Portal Test');
                    $pdf->SetTitle('Test PDF');
                    $pdf->setPrintHeader(false);
                    $pdf->setPrintFooter(false);
                    $pdf->AddPage();
                    $pdf->SetFont('dejavusans', '', 12);
                    $pdf->Write(0, 'TCPDF работает корректно!', '', 0, 'L', true, 0, false, false, 0);
                    
                    echo "<div class='success'>✅ Тестовая генерация PDF прошла успешно!</div>";
                    echo "<div class='success'><strong>🎉 TCPDF полностью готов к работе!</strong></div>";
                } catch (Exception $e) {
                    echo "<div class='error'>❌ Ошибка при тестовой генерации: " . htmlspecialchars($e->getMessage()) . "</div>";
                }
            } else {
                echo "<div class='error'>❌ Класс TCPDF не найден после загрузки файла</div>";
            }
        } catch (Exception $e) {
            echo "<div class='error'>❌ Ошибка при загрузке TCPDF: " . htmlspecialchars($e->getMessage()) . "</div>";
        }
    } else {
        echo "<div class='error'><strong>❌ TCPDF не установлен!</strong></div>";
        echo "<div class='info'>";
        echo "<strong>Для установки выполните:</strong><br>";
        echo "<div class='code'>cd api<br>php install-tcpdf.php</div>";
        echo "<br>Или через браузер откройте: <code>api/install-tcpdf.php</code>";
        echo "</div>";
    }
    
    // Дополнительная информация
    echo "<hr>";
    echo "<h2>📊 Информация о системе</h2>";
    echo "<div class='info'>";
    echo "<strong>PHP версия:</strong> " . PHP_VERSION . "<br>";
    echo "<strong>Директория API:</strong> <code>$apiDir</code><br>";
    echo "<strong>Права на запись:</strong> " . (is_writable($apiDir) ? '✅ Да' : '❌ Нет') . "<br>";
    echo "</div>";
    
    if (!$found) {
        echo "<div class='info'>";
        echo "<h3>📥 Варианты установки:</h3>";
        echo "<ol>";
        echo "<li><strong>Автоматическая установка:</strong> Откройте <code>api/install-tcpdf.php</code> в браузере</li>";
        echo "<li><strong>Через Composer:</strong> <code>cd api && composer require tecnickcom/tcpdf</code></li>";
        echo "<li><strong>Ручная установка:</strong> См. <code>docs/tcpdf-installation-guide.md</code></li>";
        echo "</ol>";
        echo "</div>";
    }
    ?>
    
    <hr>
    <p><a href="../">← Вернуться на портал</a></p>
</body>
</html>
