from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import (
    User, Project, Contractor, Contract, CostItem,
    UnitRate, Payment, Report
)


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['username', 'name', 'role', 'email']
    list_filter = ['role']
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Дополнительная информация', {'fields': ('name', 'role')}),
    )


@admin.register(Project)
class ProjectAdmin(admin.ModelAdmin):
    list_display = ['name', 'type', 'progress_percent', 'budget_planned', 'budget_actual', 'bank_covenants_status']
    list_filter = ['type', 'bank_covenants_status']
    search_fields = ['name']


@admin.register(Contractor)
class ContractorAdmin(admin.ModelAdmin):
    list_display = ['name', 'type', 'qualification_level', 'reliability_score', 'tax_risk_flag', 'nominated_from_above']
    list_filter = ['type', 'qualification_level', 'tax_risk_flag', 'nominated_from_above']
    search_fields = ['name']


@admin.register(Contract)
class ContractAdmin(admin.ModelAdmin):
    list_display = ['__str__', 'project', 'contractor', 'planned_amount', 'contracted_amount', 'status']
    list_filter = ['status', 'discount_flag', 'project__type']
    search_fields = ['project__name', 'contractor__name']


@admin.register(CostItem)
class CostItemAdmin(admin.ModelAdmin):
    list_display = ['work_type', 'contract', 'cost_planned', 'cost_actual', 'variance_percent']
    list_filter = ['work_type', 'contract__project']
    search_fields = ['work_type']


@admin.register(UnitRate)
class UnitRateAdmin(admin.ModelAdmin):
    list_display = ['work_type', 'project_type', 'unit', 'rate_own_db', 'source']
    list_filter = ['project_type', 'source', 'unit']
    search_fields = ['work_type']


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ['date', 'project', 'contract', 'amount', 'cash_flow_type']
    list_filter = ['cash_flow_type', 'source_system', 'date']
    search_fields = ['project__name']


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ['project', 'contractor', 'period_start', 'period_end', 'status', 'consistency_score', 'processing_effort_hours']
    list_filter = ['status', 'period_start']
    search_fields = ['project__name', 'contractor__name']
