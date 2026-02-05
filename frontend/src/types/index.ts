export enum UserRole {
  ADMIN = 'ADMIN',
  TOP_MANAGER = 'TOP_MANAGER',
  FIN_MANAGER = 'FIN_MANAGER',
  SITE_MANAGER = 'SITE_MANAGER',
  PM = 'PM',
}

export interface User {
  id: number;
  username: string;
  name: string;
  role: UserRole;
  role_display: string;
}

export interface Project {
  id: number;
  name: string;
  type: string;
  type_display: string;
  budget_planned: string;
  budget_actual: string;
  budget_contracted: string;
  budget_variance: string;
  budget_variance_percent: string;
  schedule_planned_start: string | null;
  schedule_planned_finish: string | null;
  schedule_actual_start: string | null;
  schedule_actual_finish: string | null;
  progress_percent: string;
  bank_covenants_status: string;
  bank_covenants_status_display: string;
  is_overdue: boolean;
}

export interface Contractor {
  id: number;
  name: string;
  type: string;
  type_display: string;
  qualification_level: string;
  qualification_level_display: string;
  reliability_score: number;
  tax_risk_flag: boolean;
  nominated_from_above: boolean;
  average_schedule_deviation: number;
  average_budget_deviation: number;
  projects_count: number;
}

export interface Contract {
  id: number;
  project: number;
  project_name: string;
  contractor: number;
  contractor_name: string;
  planned_amount: string;
  contracted_amount: string;
  paid_amount: string;
  variance_amount: string;
  variance_percent: string;
  scope_description: string;
  start_date: string | null;
  end_date: string | null;
  schedule_planned_end: string | null;
  status: string;
  status_display: string;
  discount_flag: boolean;
}

export interface CostItem {
  id: number;
  contract: number;
  contract_id: number;
  contract_name: string;
  project_name: string;
  work_type: string;
  unit: string;
  physical_volume_planned: string;
  physical_volume_actual: string;
  cost_planned: string;
  cost_actual: string;
  variance_amount: string;
  variance_percent: string;
}

export interface UnitRate {
  id: number;
  project_type: string;
  project_type_display: string;
  work_type: string;
  unit: string;
  rate_own_db: string;
  rate_market: string | null;
  date_from: string;
  date_to: string | null;
  source: string;
  source_display: string;
}

export interface Payment {
  id: number;
  contract: number;
  contract_name: string;
  project: number;
  project_name: string;
  date: string;
  amount: string;
  cash_flow_type: string;
  cash_flow_type_display: string;
  source_system: string;
  source_system_display: string;
}

export interface Report {
  id: number;
  contractor: number;
  contractor_name: string;
  project: number;
  project_name: string;
  period_start: string;
  period_end: string;
  source_file_ref: string;
  status: string;
  status_display: string;
  consistency_score: number;
  prepared_by: string;
  checked_by: string;
  processing_effort_hours: string;
}
