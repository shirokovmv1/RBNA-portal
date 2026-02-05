"""
Middleware для логирования пользовательских действий
"""
import logging
import json
import time
from django.utils.deprecation import MiddlewareMixin
from django.http import JsonResponse
from django.urls import resolve

logger = logging.getLogger('user_actions')

class UserActionLoggingMiddleware(MiddlewareMixin):
    """
    Middleware для логирования всех пользовательских действий
    """
    
    def process_request(self, request):
        """Сохраняем время начала запроса"""
        request._start_time = time.time()
        return None
    
    def process_response(self, request, response):
        """Логируем запрос и ответ"""
        # Пропускаем статические файлы и админку Django
        if request.path.startswith('/static/') or request.path.startswith('/admin/'):
            return response
        
        # Вычисляем время выполнения
        duration = time.time() - getattr(request, '_start_time', 0)
        
        # Получаем информацию о пользователе
        user_info = {
            'id': request.user.id if request.user.is_authenticated else None,
            'username': request.user.username if request.user.is_authenticated else 'anonymous',
            'email': getattr(request.user, 'email', None) if request.user.is_authenticated else None,
        }
        
        # Получаем информацию о запросе
        try:
            resolved = resolve(request.path)
            view_name = resolved.view_name if resolved else None
            url_name = resolved.url_name if resolved else None
        except:
            view_name = None
            url_name = None
        
        # Получаем данные запроса
        request_data = {}
        if request.method in ['POST', 'PUT', 'PATCH']:
            try:
                if request.content_type == 'application/json':
                    request_data = json.loads(request.body.decode('utf-8'))
                else:
                    request_data = dict(request.POST)
            except:
                request_data = {'error': 'Could not parse request data'}
        
        # Получаем IP адрес
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip_address = x_forwarded_for.split(',')[0]
        else:
            ip_address = request.META.get('REMOTE_ADDR', 'unknown')
        
        # Формируем лог запись
        log_data = {
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
            'method': request.method,
            'path': request.path,
            'view_name': view_name,
            'url_name': url_name,
            'user': user_info,
            'ip_address': ip_address,
            'status_code': response.status_code,
            'duration_ms': round(duration * 1000, 2),
            'request_data': request_data if request.method in ['POST', 'PUT', 'PATCH'] else None,
            'user_agent': request.META.get('HTTP_USER_AGENT', 'unknown'),
        }
        
        # Логируем в зависимости от статуса ответа
        if response.status_code >= 500:
            logger.error(json.dumps(log_data, ensure_ascii=False))
        elif response.status_code >= 400:
            logger.warning(json.dumps(log_data, ensure_ascii=False))
        else:
            logger.info(json.dumps(log_data, ensure_ascii=False))
        
        return response
    
    def process_exception(self, request, exception):
        """Логируем исключения"""
        user_info = {
            'id': request.user.id if request.user.is_authenticated else None,
            'username': request.user.username if request.user.is_authenticated else 'anonymous',
        }
        
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip_address = x_forwarded_for.split(',')[0]
        else:
            ip_address = request.META.get('REMOTE_ADDR', 'unknown')
        
        log_data = {
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
            'method': request.method,
            'path': request.path,
            'user': user_info,
            'ip_address': ip_address,
            'exception_type': type(exception).__name__,
            'exception_message': str(exception),
            'user_agent': request.META.get('HTTP_USER_AGENT', 'unknown'),
        }
        
        logger.error(json.dumps(log_data, ensure_ascii=False))
        
        return None
