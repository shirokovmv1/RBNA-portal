#!/usr/bin/env python
"""
Скрипт для автоматической замены AllowAny на IsAuthenticated
в файле api/views.py
"""

import re
import sys
from pathlib import Path

def replace_allowany(file_path):
    """Заменяет AllowAny на IsAuthenticated в views.py"""
    
    # Читаем файл
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Подсчитываем количество замен
    count_before = content.count('permission_classes = [AllowAny]')
    
    if count_before == 0:
        print("✅ AllowAny не найден. Возможно, уже заменен.")
        return
    
    # Заменяем все вхождения
    # Вариант 1: С комментарием
    content = re.sub(
        r'permission_classes = \[AllowAny\]\s*#.*?Для production.*?',
        'permission_classes = [IsAuthenticated]',
        content,
        flags=re.MULTILINE
    )
    
    # Вариант 2: Без комментария
    content = re.sub(
        r'permission_classes = \[AllowAny\]',
        'permission_classes = [IsAuthenticated]',
        content
    )
    
    # Подсчитываем после замены
    count_after = content.count('permission_classes = [IsAuthenticated]')
    
    # Записываем обратно
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Заменено: {count_before} вхождений AllowAny на IsAuthenticated")
    print(f"✅ Всего IsAuthenticated теперь: {count_after}")

if __name__ == '__main__':
    # Определяем путь к файлу
    script_dir = Path(__file__).parent
    views_file = script_dir.parent / 'api' / 'views.py'
    
    if not views_file.exists():
        print(f"❌ Файл не найден: {views_file}")
        sys.exit(1)
    
    print(f"📝 Обработка файла: {views_file}")
    replace_allowany(views_file)
    print("✅ Готово!")
