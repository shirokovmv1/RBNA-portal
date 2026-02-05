from rest_framework import viewsets, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q, Avg, Count, F
from django.http import HttpResponse
from django.utils import timezone
import csv

from .models import (
    User, Project, Contractor, Contract, CostItem,
    UnitRate, Payment, Report
)
from .serializers import (
    UserSerializer, ProjectSerializer, ContractorSerializer,
    ContractSerializer, CostItemSerializer, UnitRateSerializer,
    PaymentSerializer, ReportSerializer
)


class UserViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet для пользователей.
    Для прототипа: AllowAny (доступ без аутентификации)
    Для production: IsAuthenticated или IsAdminUser
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [AllowAny]  # Для production: [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['username', 'name']
    ordering_fields = ['username', 'role']


class ProjectViewSet(viewsets.ModelViewSet):
    """
    ViewSet для проектов.
    Для прототипа: AllowAny
    Для production: IsAuthenticated с проверкой ролей
    """
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    permission_classes = [AllowAny]  # Для production: [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['type', 'bank_covenants_status']
    search_fields = ['name']
    ordering_fields = ['name', 'budget_planned', 'progress_percent', 'schedule_planned_finish']

    @action(detail=False, methods=['get'])
    def alerts(self, request):
        """Алерты: просроченные проекты, перерасход, нарушение ковенантов"""
        overdue = Project.objects.filter(
            Q(schedule_actual_finish__gt=F('schedule_planned_finish')) |
            Q(schedule_planned_finish__lt=timezone.now().date(), schedule_actual_finish__isnull=True)
        )
        
        over_budget = Project.objects.filter(
            budget_actual__gt=F('budget_planned') * 1.1  # Перерасход > 10%
        )
        
        covenant_issues = Project.objects.exclude(bank_covenants_status='met')
        
        return Response({
            'overdue': ProjectSerializer(overdue, many=True).data,
            'over_budget': ProjectSerializer(over_budget, many=True).data,
            'covenant_issues': ProjectSerializer(covenant_issues, many=True).data,
        })

    @action(detail=False, methods=['get'])
    def export_csv(self, request):
        """Экспорт проектов в CSV"""
        projects = self.filter_queryset(self.get_queryset())
        
        response = HttpResponse(content_type='text/csv; charset=utf-8')
        response['Content-Disposition'] = 'attachment; filename="projects.csv"'
        
        writer = csv.writer(response)
        writer.writerow([
            'Название', 'Тип', 'Прогресс %', 'Бюджет план', 'Бюджет факт',
            'Бюджет контракт', 'Отклонение %', 'Статус ковенантов'
        ])
        
        for project in projects:
            writer.writerow([
                project.name, project.get_type_display(), project.progress_percent,
                project.budget_planned, project.budget_actual, project.budget_contracted,
                project.budget_variance_percent, project.get_bank_covenants_status_display()
            ])
        
        return response


class ContractorViewSet(viewsets.ModelViewSet):
    """
    ViewSet для подрядчиков.
    Для прототипа: AllowAny
    Для production: IsAuthenticated
    """
    queryset = Contractor.objects.all()
    serializer_class = ContractorSerializer
    permission_classes = [AllowAny]  # Для production: [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['type', 'tax_risk_flag', 'nominated_from_above', 'qualification_level']
    search_fields = ['name']
    ordering_fields = ['name', 'reliability_score']

    @action(detail=True, methods=['get'])
    def details(self, request, pk=None):
        """Детальная информация о подрядчике с проектами и договорами"""
        contractor = self.get_object()
        contracts = contractor.contracts.select_related('project').all()
        
        return Response({
            'contractor': ContractorSerializer(contractor).data,
            'contracts': ContractSerializer(contracts, many=True).data,
            'projects': ProjectSerializer(
                Project.objects.filter(contracts__contractor=contractor).distinct(),
                many=True
            ).data,
        })

    @action(detail=False, methods=['get'])
    def export_csv(self, request):
        """Экспорт подрядчиков в CSV"""
        contractors = self.filter_queryset(self.get_queryset())
        
        response = HttpResponse(content_type='text/csv; charset=utf-8')
        response['Content-Disposition'] = 'attachment; filename="contractors.csv"'
        
        writer = csv.writer(response)
        writer.writerow([
            'Название', 'Тип', 'Уровень квалификации', 'Оценка надёжности',
            'Налоговый риск', 'Номинирован свыше', 'Отклонение сроков',
            'Отклонение бюджета', 'Кол-во проектов'
        ])
        
        for contractor in contractors:
            writer.writerow([
                contractor.name, contractor.get_type_display(),
                contractor.get_qualification_level_display(), contractor.reliability_score,
                'Да' if contractor.tax_risk_flag else 'Нет',
                'Да' if contractor.nominated_from_above else 'Нет',
                contractor.average_schedule_deviation,
                contractor.average_budget_deviation,
                contractor.contracts.values('project').distinct().count()
            ])
        
        return response


class ContractViewSet(viewsets.ModelViewSet):
    """
    ViewSet для договоров.
    Для прототипа: AllowAny
    Для production: IsAuthenticated
    """
    queryset = Contract.objects.select_related('project', 'contractor').all()
    serializer_class = ContractSerializer
    permission_classes = [AllowAny]  # Для production: [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['project', 'contractor', 'status', 'discount_flag']
    search_fields = ['scope_description', 'project__name', 'contractor__name']
    ordering_fields = ['planned_amount', 'contracted_amount', 'start_date', 'end_date']

    @action(detail=False, methods=['get'])
    def export_csv(self, request):
        """Экспорт договоров в CSV"""
        contracts = self.filter_queryset(self.get_queryset())
        
        response = HttpResponse(content_type='text/csv; charset=utf-8')
        response['Content-Disposition'] = 'attachment; filename="contracts.csv"'
        
        writer = csv.writer(response)
        writer.writerow([
            'Проект', 'Подрядчик', 'План', 'Контракт', 'Оплачено',
            'Отклонение %', 'Статус', 'Дата начала', 'Дата окончания'
        ])
        
        for contract in contracts:
            writer.writerow([
                contract.project.name, contract.contractor.name,
                contract.planned_amount, contract.contracted_amount, contract.paid_amount,
                contract.variance_percent, contract.get_status_display(),
                contract.start_date, contract.end_date
            ])
        
        return response


class CostItemViewSet(viewsets.ModelViewSet):
    queryset = CostItem.objects.select_related('contract', 'contract__project').all()
    serializer_class = CostItemSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['contract', 'work_type']
    search_fields = ['work_type', 'contract__project__name']
    ordering_fields = ['cost_planned', 'cost_actual', 'variance_amount']

    @action(detail=False, methods=['get'])
    def export_csv(self, request):
        """Экспорт статей затрат в CSV"""
        items = self.filter_queryset(self.get_queryset())
        
        response = HttpResponse(content_type='text/csv; charset=utf-8')
        response['Content-Disposition'] = 'attachment; filename="cost_items.csv"'
        
        writer = csv.writer(response)
        writer.writerow([
            'Проект', 'Договор', 'Вид работ', 'Единица', 'Объём план',
            'Объём факт', 'Стоимость план', 'Стоимость факт', 'Отклонение %'
        ])
        
        for item in items:
            writer.writerow([
                item.contract.project.name, str(item.contract),
                item.work_type, item.unit, item.physical_volume_planned,
                item.physical_volume_actual, item.cost_planned, item.cost_actual,
                item.variance_percent
            ])
        
        return response


class UnitRateViewSet(viewsets.ModelViewSet):
    queryset = UnitRate.objects.all()
    serializer_class = UnitRateSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['project_type', 'work_type', 'unit', 'source']
    search_fields = ['work_type']
    ordering_fields = ['rate_own_db', 'date_from']


class PaymentViewSet(viewsets.ModelViewSet):
    queryset = Payment.objects.select_related('project', 'contract').all()
    serializer_class = PaymentSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['project', 'contract', 'cash_flow_type', 'source_system']
    search_fields = ['project__name']
    ordering_fields = ['date', 'amount']


class ReportViewSet(viewsets.ModelViewSet):
    """
    ViewSet для отчётов генподрядчика.
    Для прототипа: AllowAny
    Для production: IsAuthenticated (только FIN_MANAGER может редактировать)
    """
    queryset = Report.objects.select_related('project', 'contractor').all()
    serializer_class = ReportSerializer
    permission_classes = [AllowAny]  # Для production: [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['project', 'contractor', 'status']
    search_fields = ['project__name', 'contractor__name']
    ordering_fields = ['period_start', 'period_end', 'processing_effort_hours', 'consistency_score']
