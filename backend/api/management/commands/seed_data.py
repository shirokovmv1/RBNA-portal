from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
import random

from api.models import (
    User, Project, Contractor, Contract, CostItem,
    UnitRate, Payment, Report
)


class Command(BaseCommand):
    help = 'Заполняет базу данных демо-данными'

    def handle(self, *args, **options):
        self.stdout.write('Создание пользователей...')
        self.create_users()
        
        self.stdout.write('Создание подрядчиков...')
        contractors = self.create_contractors()
        
        self.stdout.write('Создание проектов...')
        projects = self.create_projects()
        
        self.stdout.write('Создание договоров...')
        contracts = self.create_contracts(projects, contractors)
        
        self.stdout.write('Создание статей затрат...')
        self.create_cost_items(contracts)
        
        self.stdout.write('Создание единичных расценок...')
        self.create_unit_rates()
        
        self.stdout.write('Создание платежей...')
        self.create_payments(contracts, projects)
        
        self.stdout.write('Создание отчётов...')
        self.create_reports(contractors, projects)
        
        self.stdout.write(self.style.SUCCESS('Данные успешно созданы!'))

    def create_users(self):
        users_data = [
            {'username': 'admin', 'name': 'Администратор', 'role': User.Role.ADMIN},
            {'username': 'volkov', 'name': 'Волков А.', 'role': User.Role.TOP_MANAGER},
            {'username': 'uvarova', 'name': 'Уварова Е.', 'role': User.Role.FIN_MANAGER},
            {'username': 'fin1', 'name': 'Финансовый менеджер 1', 'role': User.Role.FIN_MANAGER},
            {'username': 'site1', 'name': 'Прораб Иванов', 'role': User.Role.SITE_MANAGER},
            {'username': 'site2', 'name': 'Прораб Петров', 'role': User.Role.SITE_MANAGER},
            {'username': 'pm1', 'name': 'РП Сидоров', 'role': User.Role.PM},
            {'username': 'pm2', 'name': 'ГИП Козлов', 'role': User.Role.PM},
        ]
        
        for user_data in users_data:
            User.objects.get_or_create(
                username=user_data['username'],
                defaults={
                    'name': user_data['name'],
                    'role': user_data['role'],
                    'email': f"{user_data['username']}@example.com",
                }
            )

    def create_contractors(self):
        contractors_data = [
            {
                'name': 'ООО "СтройГрупп"', 'type': Contractor.ContractorType.GENERAL_CONTRACTOR,
                'qualification_level': Contractor.QualificationLevel.HIGH,
                'reliability_score': 85, 'tax_risk_flag': False, 'nominated_from_above': False
            },
            {
                'name': 'ООО "ПромСтрой"', 'type': Contractor.ContractorType.GENERAL_CONTRACTOR,
                'qualification_level': Contractor.QualificationLevel.MEDIUM,
                'reliability_score': 65, 'tax_risk_flag': True, 'nominated_from_above': True
            },
            {
                'name': 'ООО "БетонСтрой"', 'type': Contractor.ContractorType.SUBCONTRACTOR,
                'qualification_level': Contractor.QualificationLevel.HIGH,
                'reliability_score': 90, 'tax_risk_flag': False, 'nominated_from_above': False
            },
            {
                'name': 'ООО "ФасадПро"', 'type': Contractor.ContractorType.SUBCONTRACTOR,
                'qualification_level': Contractor.QualificationLevel.MEDIUM,
                'reliability_score': 70, 'tax_risk_flag': False, 'nominated_from_above': False
            },
            {
                'name': 'ООО "ИнжСети"', 'type': Contractor.ContractorType.SUBCONTRACTOR,
                'qualification_level': Contractor.QualificationLevel.MEDIUM,
                'reliability_score': 75, 'tax_risk_flag': True, 'nominated_from_above': False
            },
            {
                'name': 'ООО "ЭлектроМонтаж"', 'type': Contractor.ContractorType.SUBCONTRACTOR,
                'qualification_level': Contractor.QualificationLevel.HIGH,
                'reliability_score': 88, 'tax_risk_flag': False, 'nominated_from_above': False
            },
            {
                'name': 'ООО "ДемпингСтрой"', 'type': Contractor.ContractorType.SUBCONTRACTOR,
                'qualification_level': Contractor.QualificationLevel.LOW,
                'reliability_score': 45, 'tax_risk_flag': True, 'nominated_from_above': True
            },
            {
                'name': 'ООО "КачествоСтрой"', 'type': Contractor.ContractorType.GENERAL_CONTRACTOR,
                'qualification_level': Contractor.QualificationLevel.HIGH,
                'reliability_score': 92, 'tax_risk_flag': False, 'nominated_from_above': False
            },
        ]
        
        contractors = []
        for data in contractors_data:
            contractor, _ = Contractor.objects.get_or_create(name=data['name'], defaults=data)
            contractors.append(contractor)
        
        return contractors

    def create_projects(self):
        today = timezone.now().date()
        projects_data = [
            {
                'name': 'Промышленный комплекс "Северный"',
                'type': Project.ProjectType.INDUSTRIAL,
                'budget_planned': Decimal('500000000'),
                'budget_actual': Decimal('520000000'),
                'budget_contracted': Decimal('510000000'),
                'schedule_planned_start': today - timedelta(days=180),
                'schedule_planned_finish': today + timedelta(days=90),
                'schedule_actual_start': today - timedelta(days=175),
                'schedule_actual_finish': None,
                'progress_percent': Decimal('65.5'),
                'bank_covenants_status': Project.BankCovenantsStatus.AT_RISK,
            },
            {
                'name': 'Жилой комплекс "Солнечный"',
                'type': Project.ProjectType.RESIDENTIAL,
                'budget_planned': Decimal('1200000000'),
                'budget_actual': Decimal('1180000000'),
                'budget_contracted': Decimal('1190000000'),
                'schedule_planned_start': today - timedelta(days=120),
                'schedule_planned_finish': today + timedelta(days=180),
                'schedule_actual_start': today - timedelta(days=125),
                'schedule_actual_finish': None,
                'progress_percent': Decimal('42.3'),
                'bank_covenants_status': Project.BankCovenantsStatus.MET,
            },
            {
                'name': 'Офисный центр "Бизнес-Плаза"',
                'type': Project.ProjectType.OFFICE,
                'budget_planned': Decimal('800000000'),
                'budget_actual': Decimal('850000000'),
                'budget_contracted': Decimal('820000000'),
                'schedule_planned_start': today - timedelta(days=90),
                'schedule_planned_finish': today + timedelta(days=120),
                'schedule_actual_start': today - timedelta(days=95),
                'schedule_actual_finish': None,
                'progress_percent': Decimal('55.8'),
                'bank_covenants_status': Project.BankCovenantsStatus.VIOLATED,
            },
            {
                'name': 'Технопарк "Инновации"',
                'type': Project.ProjectType.TECHNOPARK,
                'budget_planned': Decimal('600000000'),
                'budget_actual': Decimal('580000000'),
                'budget_contracted': Decimal('590000000'),
                'schedule_planned_start': today - timedelta(days=60),
                'schedule_planned_finish': today + timedelta(days=150),
                'schedule_actual_start': today - timedelta(days=58),
                'schedule_actual_finish': None,
                'progress_percent': Decimal('28.7'),
                'bank_covenants_status': Project.BankCovenantsStatus.MET,
            },
            {
                'name': 'Промышленный комплекс "Южный"',
                'type': Project.ProjectType.INDUSTRIAL,
                'budget_planned': Decimal('450000000'),
                'budget_actual': Decimal('470000000'),
                'budget_contracted': Decimal('460000000'),
                'schedule_planned_start': today - timedelta(days=200),
                'schedule_planned_finish': today - timedelta(days=10),
                'schedule_actual_start': today - timedelta(days=195),
                'schedule_actual_finish': today - timedelta(days=5),
                'progress_percent': Decimal('100.0'),
                'bank_covenants_status': Project.BankCovenantsStatus.MET,
            },
        ]
        
        projects = []
        for data in projects_data:
            project, _ = Project.objects.get_or_create(name=data['name'], defaults=data)
            projects.append(project)
        
        return projects

    def create_contracts(self, projects, contractors):
        contracts = []
        gen_contractors = [c for c in contractors if c.type == Contractor.ContractorType.GENERAL_CONTRACTOR]
        sub_contractors = [c for c in contractors if c.type == Contractor.ContractorType.SUBCONTRACTOR]
        
        today = timezone.now().date()
        
        for project in projects:
            # Генподрядчик
            if gen_contractors:
                gen_contractor = random.choice(gen_contractors)
                contract = Contract.objects.create(
                    project=project,
                    contractor=gen_contractor,
                    planned_amount=project.budget_planned * Decimal('0.6'),
                    contracted_amount=project.budget_contracted * Decimal('0.6'),
                    paid_amount=project.budget_contracted * Decimal('0.4'),
                    scope_description='Генеральный подряд',
                    start_date=project.schedule_planned_start,
                    end_date=project.schedule_planned_finish,
                    schedule_planned_end=project.schedule_planned_finish,
                    status=Contract.ContractStatus.ACTIVE if project.progress_percent < 100 else Contract.ContractStatus.COMPLETED,
                    discount_flag=False,
                )
                contracts.append(contract)
            
            # Подрядчики
            for i, sub_contractor in enumerate(random.sample(sub_contractors, min(3, len(sub_contractors)))):
                planned = project.budget_planned * Decimal(random.uniform(0.05, 0.15))
                contracted = planned * Decimal(random.uniform(0.95, 1.15))
                paid = contracted * Decimal(random.uniform(0.3, 0.7))
                
                contract = Contract.objects.create(
                    project=project,
                    contractor=sub_contractor,
                    planned_amount=planned,
                    contracted_amount=contracted,
                    paid_amount=paid,
                    scope_description=f'Работы по {["бетону", "фасаду", "инж. сетям", "электромонтажу"][i % 4]}',
                    start_date=project.schedule_planned_start + timedelta(days=random.randint(0, 30)),
                    end_date=project.schedule_planned_finish - timedelta(days=random.randint(0, 30)),
                    schedule_planned_end=project.schedule_planned_finish - timedelta(days=random.randint(0, 30)),
                    status=random.choice([Contract.ContractStatus.ACTIVE, Contract.ContractStatus.AT_RISK, Contract.ContractStatus.COMPLETED]),
                    discount_flag=sub_contractor.name == 'ООО "ДемпингСтрой"',
                )
                contracts.append(contract)
        
        return contracts

    def create_cost_items(self, contracts):
        work_types = {
            'concrete': {'unit': 'm3', 'rate': Decimal('5000')},
            'facade': {'unit': 'm2', 'rate': Decimal('3000')},
            'engineering_networks': {'unit': 'm', 'rate': Decimal('15000')},
            'electrical': {'unit': 'm', 'rate': Decimal('8000')},
            'roofing': {'unit': 'm2', 'rate': Decimal('4000')},
            'foundation': {'unit': 'm3', 'rate': Decimal('6000')},
        }
        
        for contract in contracts:
            selected_works = random.sample(list(work_types.items()), random.randint(2, 4))
            
            for work_type, work_data in selected_works:
                volume_planned = Decimal(random.uniform(100, 1000))
                volume_actual = volume_planned * Decimal(random.uniform(0.85, 1.15))
                cost_planned = volume_planned * work_data['rate']
                cost_actual = volume_actual * work_data['rate'] * Decimal(random.uniform(0.9, 1.2))
                
                CostItem.objects.create(
                    contract=contract,
                    work_type=work_type,
                    unit=work_data['unit'],
                    physical_volume_planned=volume_planned,
                    physical_volume_actual=volume_actual,
                    cost_planned=cost_planned,
                    cost_actual=cost_actual,
                )

    def create_unit_rates(self):
        project_types = Project.ProjectType.choices
        work_types = ['concrete', 'facade', 'engineering_networks', 'electrical', 'roofing', 'foundation']
        units = ['m3', 'm2', 'm', 'piece']
        
        today = timezone.now().date()
        
        for project_type, _ in project_types:
            for work_type in work_types:
                unit = 'm3' if work_type in ['concrete', 'foundation'] else ('m2' if work_type in ['facade', 'roofing'] else 'm')
                
                UnitRate.objects.create(
                    project_type=project_type,
                    work_type=work_type,
                    unit=unit,
                    rate_own_db=Decimal(random.uniform(3000, 10000)),
                    rate_market=Decimal(random.uniform(3500, 11000)),
                    date_from=today - timedelta(days=365),
                    date_to=None,
                    source=random.choice([UnitRate.Source.OWN_DB, UnitRate.Source.MARKET, UnitRate.Source.COMBINED]),
                )

    def create_payments(self, contracts, projects):
        today = timezone.now().date()
        
        for contract in contracts:
            # Аванс
            Payment.objects.create(
                contract=contract,
                project=contract.project,
                date=contract.start_date or today - timedelta(days=random.randint(30, 180)),
                amount=contract.contracted_amount * Decimal('0.3'),
                cash_flow_type=Payment.CashFlowType.ADVANCE,
                source_system=random.choice([Payment.SourceSystem.ONEC, Payment.SourceSystem.BITFINANCE, Payment.SourceSystem.MANUAL]),
            )
            
            # Частичные оплаты
            num_payments = random.randint(2, 5)
            remaining = contract.contracted_amount * Decimal('0.7')
            
            for i in range(num_payments):
                if remaining <= 0:
                    break
                payment_amount = remaining / Decimal(num_payments - i) * Decimal(random.uniform(0.8, 1.0))
                payment_amount = min(payment_amount, remaining)
                
                Payment.objects.create(
                    contract=contract,
                    project=contract.project,
                    date=(contract.start_date or today) + timedelta(days=random.randint(30, 180)),
                    amount=payment_amount,
                    cash_flow_type=Payment.CashFlowType.PAYMENT,
                    source_system=random.choice([Payment.SourceSystem.ONEC, Payment.SourceSystem.BITFINANCE]),
                )
                remaining -= payment_amount
            
            # Удержания (если есть)
            if random.random() > 0.5:
                Payment.objects.create(
                    contract=contract,
                    project=contract.project,
                    date=today - timedelta(days=random.randint(0, 60)),
                    amount=contract.contracted_amount * Decimal(random.uniform(0.05, 0.1)),
                    cash_flow_type=Payment.CashFlowType.RETENTION,
                    source_system=Payment.SourceSystem.MANUAL,
                )

    def create_reports(self, contractors, projects):
        gen_contractors = [c for c in contractors if c.type == Contractor.ContractorType.GENERAL_CONTRACTOR]
        today = timezone.now().date()
        
        for project in projects:
            for gen_contractor in gen_contractors:
                if Contract.objects.filter(project=project, contractor=gen_contractor).exists():
                    # Создаём отчёты за последние 6 месяцев
                    for month_offset in range(6):
                        period_start = today - timedelta(days=30 * (month_offset + 1))
                        period_end = today - timedelta(days=30 * month_offset)
                        
                        Report.objects.create(
                            contractor=gen_contractor,
                            project=project,
                            period_start=period_start,
                            period_end=period_end,
                            source_file_ref=f'/reports/{project.id}/{gen_contractor.id}/{period_start}.pdf',
                            status=random.choice([
                                Report.ReportStatus.RECEIVED,
                                Report.ReportStatus.UNDER_REVIEW,
                                Report.ReportStatus.ACCEPTED,
                                Report.ReportStatus.ACCEPTED_WITH_ISSUES,
                                Report.ReportStatus.REJECTED,
                            ]),
                            consistency_score=random.randint(60, 100),
                            prepared_by=f'{gen_contractor.name} - Отдел отчётности',
                            checked_by=random.choice(['Уварова Е.', 'Финансовый менеджер 1', '']),
                            processing_effort_hours=Decimal(random.uniform(0.5, 40.0)),
                        )
