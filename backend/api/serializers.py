from rest_framework import serializers
from django.core.exceptions import ValidationError
from .models import (
    User, Project, Contractor, Contract, CostItem,
    UnitRate, Payment, Report
)


class UserSerializer(serializers.ModelSerializer):
    role_display = serializers.CharField(source='get_role_display', read_only=True)

    class Meta:
        model = User
        fields = ['id', 'username', 'name', 'role', 'role_display']
        read_only_fields = ['id']


class ContractorSerializer(serializers.ModelSerializer):
    type_display = serializers.CharField(source='get_type_display', read_only=True)
    qualification_level_display = serializers.CharField(source='get_qualification_level_display', read_only=True)
    average_schedule_deviation = serializers.ReadOnlyField()
    average_budget_deviation = serializers.ReadOnlyField()
    projects_count = serializers.SerializerMethodField()

    class Meta:
        model = Contractor
        fields = [
            'id', 'name', 'type', 'type_display', 'qualification_level',
            'qualification_level_display', 'reliability_score',
            'tax_risk_flag', 'nominated_from_above',
            'average_schedule_deviation', 'average_budget_deviation',
            'projects_count'
        ]

    def get_projects_count(self, obj):
        return obj.contracts.values('project').distinct().count()


class ProjectSerializer(serializers.ModelSerializer):
    type_display = serializers.CharField(source='get_type_display', read_only=True)
    bank_covenants_status_display = serializers.CharField(source='get_bank_covenants_status_display', read_only=True)
    budget_variance = serializers.ReadOnlyField()
    budget_variance_percent = serializers.ReadOnlyField()
    is_overdue = serializers.ReadOnlyField()

    class Meta:
        model = Project
        fields = [
            'id', 'name', 'type', 'type_display',
            'budget_planned', 'budget_actual', 'budget_contracted',
            'budget_variance', 'budget_variance_percent',
            'schedule_planned_start', 'schedule_planned_finish',
            'schedule_actual_start', 'schedule_actual_finish',
            'progress_percent', 'bank_covenants_status',
            'bank_covenants_status_display', 'is_overdue'
        ]


class ContractSerializer(serializers.ModelSerializer):
    project_name = serializers.CharField(source='project.name', read_only=True)
    contractor_name = serializers.CharField(source='contractor.name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    variance_amount = serializers.ReadOnlyField()
    variance_percent = serializers.ReadOnlyField()

    class Meta:
        model = Contract
        fields = [
            'id', 'project', 'project_name', 'contractor', 'contractor_name',
            'planned_amount', 'contracted_amount', 'paid_amount',
            'variance_amount', 'variance_percent',
            'scope_description', 'start_date', 'end_date',
            'schedule_planned_end', 'status', 'status_display', 'discount_flag'
        ]

    def validate(self, data):
        """Валидация данных договора"""
        # Проверка, что проект существует
        if 'project' in data:
            if not Project.objects.filter(id=data['project'].id).exists():
                raise serializers.ValidationError({"project": "Проект не существует"})
        
        # Проверка, что подрядчик существует
        if 'contractor' in data:
            if not Contractor.objects.filter(id=data['contractor'].id).exists():
                raise serializers.ValidationError({"contractor": "Подрядчик не существует"})
        
        # Проверка сумм на отрицательные значения
        amount_fields = ['planned_amount', 'contracted_amount', 'paid_amount']
        for field in amount_fields:
            if field in data and data[field] < 0:
                raise serializers.ValidationError({field: "Сумма не может быть отрицательной"})
        
        # Проверка, что оплаченная сумма не превышает контрактную
        if 'contracted_amount' in data and 'paid_amount' in data:
            if data['paid_amount'] > data['contracted_amount']:
                raise serializers.ValidationError(
                    {"paid_amount": "Оплаченная сумма не может превышать контрактную"}
                )
        
        # Проверка дат
        if 'start_date' in data and 'end_date' in data:
            if data['end_date'] and data['start_date']:
                if data['end_date'] < data['start_date']:
                    raise serializers.ValidationError(
                        {"end_date": "Дата окончания не может быть раньше даты начала"}
                    )
        
        return data


class CostItemSerializer(serializers.ModelSerializer):
    contract_id = serializers.IntegerField(source='contract.id', read_only=True)
    contract_name = serializers.CharField(source='contract.__str__', read_only=True)
    project_name = serializers.CharField(source='contract.project.name', read_only=True)

    class Meta:
        model = CostItem
        fields = [
            'id', 'contract', 'contract_id', 'contract_name', 'project_name',
            'work_type', 'unit', 'physical_volume_planned',
            'physical_volume_actual', 'cost_planned', 'cost_actual',
            'variance_amount', 'variance_percent'
        ]


class UnitRateSerializer(serializers.ModelSerializer):
    project_type_display = serializers.CharField(source='get_project_type_display', read_only=True)
    source_display = serializers.CharField(source='get_source_display', read_only=True)

    class Meta:
        model = UnitRate
        fields = [
            'id', 'project_type', 'project_type_display',
            'work_type', 'unit', 'rate_own_db', 'rate_market',
            'date_from', 'date_to', 'source', 'source_display'
        ]

    def validate(self, data):
        """Валидация данных единичной расценки"""
        # Проверка расценки на отрицательные значения
        if 'rate_own_db' in data and data['rate_own_db'] < 0:
            raise serializers.ValidationError({"rate_own_db": "Расценка не может быть отрицательной"})
        
        if 'rate_market' in data and data['rate_market'] is not None:
            if data['rate_market'] < 0:
                raise serializers.ValidationError({"rate_market": "Рыночная расценка не может быть отрицательной"})
        
        # Проверка дат
        if 'date_from' in data and 'date_to' in data:
            if data['date_to'] and data['date_from']:
                if data['date_to'] < data['date_from']:
                    raise serializers.ValidationError(
                        {"date_to": "Дата окончания не может быть раньше даты начала"}
                    )
        
        return data


class PaymentSerializer(serializers.ModelSerializer):
    project_name = serializers.CharField(source='project.name', read_only=True)
    contract_name = serializers.CharField(source='contract.__str__', read_only=True)
    cash_flow_type_display = serializers.CharField(source='get_cash_flow_type_display', read_only=True)
    source_system_display = serializers.CharField(source='get_source_system_display', read_only=True)

    class Meta:
        model = Payment
        fields = [
            'id', 'contract', 'contract_name', 'project', 'project_name',
            'date', 'amount', 'cash_flow_type', 'cash_flow_type_display',
            'source_system', 'source_system_display'
        ]

    def validate(self, data):
        """Валидация данных платежа"""
        # Проверка суммы на отрицательные значения
        if 'amount' in data and data['amount'] < 0:
            raise serializers.ValidationError({"amount": "Сумма платежа не может быть отрицательной"})
        
        # Проверка, что проект существует
        if 'project' in data:
            if not Project.objects.filter(id=data['project'].id).exists():
                raise serializers.ValidationError({"project": "Проект не существует"})
        
        # Проверка, что договор существует
        if 'contract' in data:
            if not Contract.objects.filter(id=data['contract'].id).exists():
                raise serializers.ValidationError({"contract": "Договор не существует"})
        
        return data


class ReportSerializer(serializers.ModelSerializer):
    project_name = serializers.CharField(source='project.name', read_only=True)
    contractor_name = serializers.CharField(source='contractor.name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Report
        fields = [
            'id', 'contractor', 'contractor_name', 'project', 'project_name',
            'period_start', 'period_end', 'source_file_ref', 'status',
            'status_display', 'consistency_score', 'prepared_by',
            'checked_by', 'processing_effort_hours'
        ]

    def validate(self, data):
        """Валидация данных отчёта"""
        # Проверка, что проект существует
        if 'project' in data:
            if not Project.objects.filter(id=data['project'].id).exists():
                raise serializers.ValidationError({"project": "Проект не существует"})
        
        # Проверка, что подрядчик существует
        if 'contractor' in data:
            if not Contractor.objects.filter(id=data['contractor'].id).exists():
                raise serializers.ValidationError({"contractor": "Подрядчик не существует"})
        
        # Проверка дат периода
        if 'period_start' in data and 'period_end' in data:
            if data['period_end'] and data['period_start']:
                if data['period_end'] < data['period_start']:
                    raise serializers.ValidationError(
                        {"period_end": "Дата окончания периода не может быть раньше даты начала"}
                    )
        
        # Проверка consistency_score
        if 'consistency_score' in data:
            score = data['consistency_score']
            if score < 0 or score > 100:
                raise serializers.ValidationError(
                    {"consistency_score": "Оценка непротиворечивости должна быть от 0 до 100"}
                )
        
        # Проверка processing_effort_hours
        if 'processing_effort_hours' in data:
            if data['processing_effort_hours'] < 0:
                raise serializers.ValidationError(
                    {"processing_effort_hours": "Время обработки не может быть отрицательным"}
                )
        
        return data
