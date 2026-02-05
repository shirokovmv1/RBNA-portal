import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { Project, UserRole } from '../types';
import { getProjects, getProjectAlerts, exportProjectsCSV } from '../api/client';
import './DashboardPage.css';

const DashboardPage: React.FC = () => {
  const { currentUser } = useAuth();
  const [projects, setProjects] = useState<Project[]>([]);
  const [alerts, setAlerts] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [filterType, setFilterType] = useState<string>('');
  const [filterCovenant, setFilterCovenant] = useState<string>('');

  useEffect(() => {
    loadData();
  }, [filterType, filterCovenant]);

  const loadData = async () => {
    setLoading(true);
    try {
      const params: Record<string, any> = {};
      if (filterType) params.type = filterType;
      if (filterCovenant) params.bank_covenants_status = filterCovenant;

      const [projectsData, alertsData] = await Promise.all([
        getProjects(params),
        getProjectAlerts(),
      ]);
      setProjects(projectsData);
      setAlerts(alertsData);
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleExportCSV = async () => {
    try {
      const params: Record<string, any> = {};
      if (filterType) params.type = filterType;
      if (filterCovenant) params.bank_covenants_status = filterCovenant;

      const blob = await exportProjectsCSV(params);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'projects.csv';
      a.click();
      window.URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Failed to export CSV:', error);
    }
  };

  const formatCurrency = (value: string) => {
    const num = parseFloat(value);
    return new Intl.NumberFormat('ru-RU', {
      style: 'currency',
      currency: 'RUB',
      minimumFractionDigits: 0,
    }).format(num);
  };

  const getCovenantBadgeClass = (status: string) => {
    switch (status) {
      case 'met':
        return 'badge-success';
      case 'at_risk':
        return 'badge-warning';
      case 'violated':
        return 'badge-danger';
      default:
        return 'badge-info';
    }
  };

  if (loading) {
    return <div className="loading">Загрузка данных...</div>;
  }

  const showAlerts = currentUser?.role === UserRole.ADMIN || currentUser?.role === UserRole.TOP_MANAGER;

  return (
    <div className="container">
      <h1>Главная панель</h1>

      {showAlerts && alerts && (
        <div className="alerts-section">
          <h2>Алерты</h2>
          {alerts.overdue && alerts.overdue.length > 0 && (
            <div className="alert alert-danger">
              <strong>Просроченные проекты:</strong> {alerts.overdue.length}
            </div>
          )}
          {alerts.over_budget && alerts.over_budget.length > 0 && (
            <div className="alert alert-warning">
              <strong>Проекты с перерасходом:</strong> {alerts.over_budget.length}
            </div>
          )}
          {alerts.covenant_issues && alerts.covenant_issues.length > 0 && (
            <div className="alert alert-warning">
              <strong>Нарушение банковских ковенантов:</strong> {alerts.covenant_issues.length}
            </div>
          )}
        </div>
      )}

      <div className="card">
        <div className="card-header">
          <h2>Проекты</h2>
          <div className="card-actions">
            <div className="filter-bar">
              <select
                value={filterType}
                onChange={(e) => setFilterType(e.target.value)}
              >
                <option value="">Все типы</option>
                <option value="industrial">Промышленное</option>
                <option value="residential">Жилое</option>
                <option value="office">Офисное</option>
                <option value="technopark">Технопарк</option>
              </select>
              <select
                value={filterCovenant}
                onChange={(e) => setFilterCovenant(e.target.value)}
              >
                <option value="">Все статусы ковенантов</option>
                <option value="met">Соблюдены</option>
                <option value="at_risk">Под риском</option>
                <option value="violated">Нарушены</option>
              </select>
              <button onClick={handleExportCSV} className="btn btn-secondary">
                Экспорт CSV
              </button>
            </div>
          </div>
        </div>

        <table className="table">
          <thead>
            <tr>
              <th>Название</th>
              <th>Тип</th>
              <th>Прогресс</th>
              <th>Бюджет план</th>
              <th>Бюджет факт</th>
              <th>Бюджет контракт</th>
              <th>Отклонение</th>
              <th>Ковенанты</th>
              <th>Действия</th>
            </tr>
          </thead>
          <tbody>
            {projects.map((project) => (
              <tr key={project.id}>
                <td>
                  <Link to={`/project/${project.id}`} className="link">
                    {project.name}
                  </Link>
                </td>
                <td>{project.type_display}</td>
                <td>{parseFloat(project.progress_percent).toFixed(1)}%</td>
                <td>{formatCurrency(project.budget_planned)}</td>
                <td>{formatCurrency(project.budget_actual)}</td>
                <td>{formatCurrency(project.budget_contracted)}</td>
                <td>
                  <span
                    className={
                      parseFloat(project.budget_variance_percent) > 0
                        ? 'text-danger'
                        : 'text-success'
                    }
                  >
                    {parseFloat(project.budget_variance_percent).toFixed(1)}%
                  </span>
                </td>
                <td>
                  <span className={`badge ${getCovenantBadgeClass(project.bank_covenants_status)}`}>
                    {project.bank_covenants_status_display}
                  </span>
                </td>
                <td>
                  <Link to={`/project/${project.id}`} className="link">
                    Детали
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default DashboardPage;
