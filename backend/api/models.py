from django.db import models
from django.contrib.auth.models import AbstractUser
from django.core.validators import MinValueValidator, MaxValueValidator


class User(AbstractUser):
    """Пользователь системы с ролью"""
    class Role(models.TextChoices):
        ADMIN = 'ADMIN', 'Администратор'
        TOP_MANAGER = 'TOP_MANAGER', 'Топ-менеджер'
        FIN_MANAGER = 'FIN_MANAGER', 'Финансовый менеджер'
        SITE_MANAGER = 'SITE_MANAGER', 'Прораб'
        PM = 'PM', 'Руководитель проекта'

    role = models.CharField(max_length=20, choices=Role.choices, default=Role.PM)
    name = models.CharField(max_length=255, blank=True)

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"


class Contractor(models.Model):
    """Подрядчик/генподрядчик"""
    class ContractorType(models.TextChoices):
        GENERAL_CONTRACTOR = 'general_contractor', 'Генподрядчик'
        SUBCONTRACTOR = 'subcontractor', 'Подрядчик'

    class QualificationLevel(models.TextChoices):
        LOW = 'low', 'Низкий'
        MEDIUM = 'medium', 'Средний'
        HIGH = 'high', 'Высокий'

    name = models.CharField(max_length=255)
    type = models.CharField(max_length=20, choices=ContractorType.choices)
    qualification_level = models.CharField(max_length=10, choices=QualificationLevel.choices, default=QualificationLevel.MEDIUM)
    reliability_score = models.IntegerField(
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        default=50
    )
    tax_risk_flag = models.BooleanField(default=False)
    nominated_from_above = models.BooleanField(default=False, verbose_name="Номинирован свыше")

    def __str__(self):
        return self.name

    @property
    def average_schedule_deviation(self):
        """Среднее отклонение по срокам (в днях)"""
        contracts = self.contracts.all()
        if not contracts.exists():
            return 0
        
        total_deviation = 0
        count = 0
        for contract in contracts:
            if contract.end_date and contract.schedule_planned_end:
                deviation = (contract.end_date - contract.schedule_planned_end).days
                total_deviation += deviation
                count += 1
        
        return total_deviation / count if count > 0 else 0

    @property
    def average_budget_deviation(self):
        """Среднее отклонение по бюджету (в процентах)"""
        contracts = self.contracts.all()
        if not contracts.exists():
            return 0
        
        total_deviation = 0
        count = 0
        for contract in contracts:
            if contract.planned_amount > 0:
                deviation = ((contract.contracted_amount - contract.planned_amount) / contract.planned_amount) * 100
                total_deviation += deviation
                count += 1
        
        return total_deviation / count if count > 0 else 0


class Project(models.Model):
    """Объект строительства"""
    class ProjectType(models.TextChoices):
        INDUSTRIAL = 'industrial', 'Промышленное'
        RESIDENTIAL = 'residential', 'Жилое'
        OFFICE = 'office', 'Офисное'
        TECHNOPARK = 'technopark', 'Технопарк'

    class BankCovenantsStatus(models.TextChoices):
        MET = 'met', 'Соблюдены'
        AT_RISK = 'at_risk', 'Под риском'
        VIOLATED = 'violated', 'Нарушены'

    name = models.CharField(max_length=255)
    type = models.CharField(max_length=20, choices=ProjectType.choices)
    budget_planned = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    budget_actual = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    budget_contracted = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    schedule_planned_start = models.DateField(null=True, blank=True)
    schedule_planned_finish = models.DateField(null=True, blank=True)
    schedule_actual_start = models.DateField(null=True, blank=True)
    schedule_actual_finish = models.DateField(null=True, blank=True)
    progress_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0, validators=[MinValueValidator(0), MaxValueValidator(100)])
    bank_covenants_status = models.CharField(max_length=10, choices=BankCovenantsStatus.choices, default=BankCovenantsStatus.MET)

    def __str__(self):
        return self.name

    @property
    def budget_variance(self):
        """Отклонение бюджета (факт - план)"""
        return self.budget_actual - self.budget_planned

    @property
    def budget_variance_percent(self):
        """Отклонение бюджета в процентах"""
        if self.budget_planned == 0:
            return 0
        return ((self.budget_actual - self.budget_planned) / self.budget_planned) * 100

    @property
    def is_overdue(self):
        """Просрочен ли проект по срокам"""
        if not self.schedule_planned_finish:
            return False
        if self.schedule_actual_finish:
            return self.schedule_actual_finish > self.schedule_planned_finish
        from django.utils import timezone
        return timezone.now().date() > self.schedule_planned_finish


class Contract(models.Model):
    """Договор"""
    class ContractStatus(models.TextChoices):
        ACTIVE = 'active', 'Активен'
        COMPLETED = 'completed', 'Завершён'
        AT_RISK = 'at_risk', 'Под риском'

    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='contracts')
    contractor = models.ForeignKey(Contractor, on_delete=models.CASCADE, related_name='contracts')
    planned_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    contracted_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    paid_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    scope_description = models.TextField(blank=True)
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    schedule_planned_end = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=10, choices=ContractStatus.choices, default=ContractStatus.ACTIVE)
    discount_flag = models.BooleanField(default=False, verbose_name="Подозрение на демпинг")

    def __str__(self):
        return f"{self.project.name} - {self.contractor.name}"

    @property
    def variance_amount(self):
        """Отклонение суммы договора"""
        return self.contracted_amount - self.planned_amount

    @property
    def variance_percent(self):
        """Отклонение суммы договора в процентах"""
        if self.planned_amount == 0:
            return 0
        return ((self.contracted_amount - self.planned_amount) / self.planned_amount) * 100


class CostItem(models.Model):
    """Статья затрат / вид работ"""
    contract = models.ForeignKey(Contract, on_delete=models.CASCADE, related_name='cost_items')
    work_type = models.CharField(max_length=100)
    unit = models.CharField(max_length=20)  # m3, m2, t, piece и др.
    physical_volume_planned = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    physical_volume_actual = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    cost_planned = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    cost_actual = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    variance_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    variance_percent = models.DecimalField(max_digits=10, decimal_places=2, default=0)

    def __str__(self):
        return f"{self.work_type} ({self.contract})"

    def save(self, *args, **kwargs):
        """Автоматический расчёт отклонений при сохранении"""
        self.variance_amount = self.cost_actual - self.cost_planned
        if self.cost_planned > 0:
            self.variance_percent = ((self.cost_actual - self.cost_planned) / self.cost_planned) * 100
        super().save(*args, **kwargs)


class UnitRate(models.Model):
    """Единичная расценка"""
    class Source(models.TextChoices):
        OWN_DB = 'own_db', 'Собственная БД'
        MARKET = 'market', 'Рыночная'
        COMBINED = 'combined', 'Комбинированная'

    project_type = models.CharField(max_length=20, choices=Project.ProjectType.choices)
    work_type = models.CharField(max_length=100)
    unit = models.CharField(max_length=20)
    rate_own_db = models.DecimalField(max_digits=15, decimal_places=2)
    rate_market = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    date_from = models.DateField()
    date_to = models.DateField(null=True, blank=True)
    source = models.CharField(max_length=20, choices=Source.choices, default=Source.OWN_DB)

    def __str__(self):
        return f"{self.work_type} ({self.project_type}) - {self.rate_own_db} руб/{self.unit}"


class Payment(models.Model):
    """Платёж / денежный поток"""
    class CashFlowType(models.TextChoices):
        ADVANCE = 'advance', 'Аванс'
        PAYMENT = 'payment', 'Оплата'
        RETENTION = 'retention', 'Удержание'

    class SourceSystem(models.TextChoices):
        ONEC = 'onec', '1С'
        BITFINANCE = 'bitfinance', 'BitFinance'
        MANUAL = 'manual', 'Ручной ввод'

    contract = models.ForeignKey(Contract, on_delete=models.CASCADE, related_name='payments')
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='payments')
    date = models.DateField()
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    cash_flow_type = models.CharField(max_length=10, choices=CashFlowType.choices)
    source_system = models.CharField(max_length=20, choices=SourceSystem.choices, default=SourceSystem.MANUAL)

    def __str__(self):
        return f"{self.date} - {self.amount} ({self.get_cash_flow_type_display()})"


class Report(models.Model):
    """Отчёт генподрядчика"""
    class ReportStatus(models.TextChoices):
        RECEIVED = 'received', 'Получен'
        UNDER_REVIEW = 'under_review', 'На проверке'
        ACCEPTED = 'accepted', 'Принят'
        ACCEPTED_WITH_ISSUES = 'accepted_with_issues', 'Принят с замечаниями'
        REJECTED = 'rejected', 'Отклонён'

    contractor = models.ForeignKey(Contractor, on_delete=models.CASCADE, related_name='reports')
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='reports')
    period_start = models.DateField()
    period_end = models.DateField()
    source_file_ref = models.CharField(max_length=500, blank=True)
    status = models.CharField(max_length=20, choices=ReportStatus.choices, default=ReportStatus.RECEIVED)
    consistency_score = models.IntegerField(
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        default=100
    )
    prepared_by = models.CharField(max_length=255, blank=True)
    checked_by = models.CharField(max_length=255, blank=True)
    processing_effort_hours = models.DecimalField(max_digits=10, decimal_places=2, default=0)

    def __str__(self):
        return f"{self.project.name} - {self.contractor.name} ({self.period_start} - {self.period_end})"
