"""
Утилиты для логирования пользовательских действий в коде
"""
import logging
import json
from functools import wraps
from django.contrib.auth import get_user_model

logger = logging.getLogger('user_actions')

def log_user_action(action_name, **kwargs):
    """
    Универсальная функция для логирования пользовательских действий
    
    Использование:
        log_user_action('user_login', user_id=user.id, username=user.username)
        log_user_action('project_created', user_id=request.user.id, project_id=project.id, project_name=project.name)
    """
    log_data = {
        'action': action_name,
        **kwargs
    }
    logger.info(json.dumps(log_data, ensure_ascii=False))


def log_action(action_name):
    """
    Декоратор для автоматического логирования действий функций/методов
    
    Использование:
        @log_action('create_project')
        def create_project(request, data):
            ...
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Пытаемся извлечь request из аргументов
            request = None
            for arg in args:
                if hasattr(arg, 'user'):
                    request = arg
                    break
            
            user_info = {}
            if request and hasattr(request, 'user'):
                user_info = {
                    'user_id': request.user.id if request.user.is_authenticated else None,
                    'username': request.user.username if request.user.is_authenticated else 'anonymous',
                }
            
            try:
                result = func(*args, **kwargs)
                
                # Логируем успешное выполнение
                log_data = {
                    'action': action_name,
                    'status': 'success',
                    'function': func.__name__,
                    **user_info
                }
                logger.info(json.dumps(log_data, ensure_ascii=False))
                
                return result
            except Exception as e:
                # Логируем ошибку
                log_data = {
                    'action': action_name,
                    'status': 'error',
                    'function': func.__name__,
                    'error': str(e),
                    'error_type': type(e).__name__,
                    **user_info
                }
                logger.error(json.dumps(log_data, ensure_ascii=False))
                raise
        
        return wrapper
    return decorator


class ActionLogger:
    """
    Класс для структурированного логирования действий
    
    Использование:
        logger = ActionLogger(request.user)
        logger.log('project_created', project_id=project.id, project_name=project.name)
    """
    
    def __init__(self, user=None):
        self.user = user
        self.logger = logging.getLogger('user_actions')
    
    def log(self, action_name, level='info', **kwargs):
        """
        Логирует действие с информацией о пользователе
        
        Args:
            action_name: Название действия
            level: Уровень логирования ('info', 'warning', 'error')
            **kwargs: Дополнительные данные для логирования
        """
        user_info = {}
        if self.user and hasattr(self.user, 'id'):
            user_info = {
                'user_id': self.user.id if self.user.is_authenticated else None,
                'username': self.user.username if self.user.is_authenticated else 'anonymous',
                'email': getattr(self.user, 'email', None) if self.user.is_authenticated else None,
            }
        
        log_data = {
            'action': action_name,
            **user_info,
            **kwargs
        }
        
        log_message = json.dumps(log_data, ensure_ascii=False)
        
        if level == 'error':
            self.logger.error(log_message)
        elif level == 'warning':
            self.logger.warning(log_message)
        else:
            self.logger.info(log_message)
    
    def log_success(self, action_name, **kwargs):
        """Логирует успешное действие"""
        self.log(action_name, level='info', status='success', **kwargs)
    
    def log_error(self, action_name, error, **kwargs):
        """Логирует ошибку"""
        self.log(action_name, level='error', status='error', error=str(error), **kwargs)
