import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { Project, Contractor, Contract, CostItem } from '../types';
import { getProject, getContractors, getContracts, getCostItems } from '../api/client';
import './ProjectPage.css';

const ProjectPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [project, setProject] = useState<Project | null>(null);
  const [contractors, setContractors] = useState<Contractor[]>([]);
  const [contracts, setContracts] = useState<Contract[]>([]);
  const [costItems, setCostItems] = useState<CostItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (id) {
      loadProjectData();
    }
  }, [id]);

  const loadProjectData = async () => {
    if (!id) return;
    setLoading(true);
    try {
      const [projectData, contractsData] = await Promise.all([
        getProject(Number(id)),
        getContracts({ project: id }),
      ]);
      setProject(projectData);
      setContracts(contractsData);

      // Получаем подрядчиков проекта
      const contractorIds = Array.from(new Set(contractsData.map((c) => c.contractor)));
      const contractorsData = await Promise.all(
        contractorIds.map((cid) => getContractors({ id: cid }).then((data) => data[0]))
      );
      setContractors(contractorsData.filter(Boolean));

      // Получаем все статьи затрат проекта
      const allCostItems: CostItem[] = [];
      for (const contract of contractsData) {
        const items = await getCostItems({ contract: contract.id });
        allCostItems.push(...items);
      }
      setCostItems(allCostItems);
    } catch (error) {
      console.error('Failed to load project data:', error);
    } finally {
      setLoading(false);
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

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return '-';
    return new Date(dateStr).toLocaleDateString('ru-RU');
  };

  if (loading) {
    return <div className="loading">Загрузка данных проекта...</div>;
  }

  if (!project) {
    return <div className="loading">Проект не найден</div>;
  }

  return (
    <div className="container">
      <h1>{project.name}</h1>

      <div className="card">
        <h2>Основная информация</h2>
        <div className="project-info-grid">
          <div>
            <strong>Тип:</strong> {project.type_display}
          </div>
          <div>
            <strong>Прогресс:</strong> {parseFloat(project.progress_percent).toFixed(1)}%
          </div>
          <div>
            <strong>Бюджет план:</strong> {formatCurrency(project.budget_planned)}
          </div>
          <div>
            <strong>Бюджет факт:</strong> {formatCurrency(project.budget_actual)}
          </div>
          <div>
            <strong>Бюджет контракт:</strong> {formatCurrency(project.budget_contracted)}
          </div>
          <div>
            <strong>Отклонение:</strong>{' '}
            <span
              className={
                parseFloat(project.budget_variance_percent) > 0
                  ? 'text-danger'
                  : 'text-success'
              }
            >
              {parseFloat(project.budget_variance_percent).toFixed(1)}%
            </span>
          </div>
          <div>
            <strong>План начала:</strong> {formatDate(project.schedule_planned_start)}
          </div>
          <div>
            <strong>Факт начала:</strong> {formatDate(project.schedule_actual_start)}
          </div>
          <div>
            <strong>План окончания:</strong> {formatDate(project.schedule_planned_finish)}
          </div>
          <div>
            <strong>Факт окончания:</strong> {formatDate(project.schedule_actual_finish)}
          </div>
          <div>
            <strong>Статус ковенантов:</strong>{' '}
            <span
              className={`badge ${
                project.bank_covenants_status === 'met'
                  ? 'badge-success'
                  : project.bank_covenants_status === 'at_risk'
                  ? 'badge-warning'
                  : 'badge-danger'
              }`}
            >
              {project.bank_covenants_status_display}
            </span>
          </div>
          {project.is_overdue && (
            <div>
              <span className="badge badge-danger">ПРОСРОЧЕН</span>
            </div>
          )}
        </div>
      </div>

      <div className="card">
        <h2>Подрядчики проекта</h2>
        <table className="table">
          <thead>
            <tr>
              <th>Название</th>
              <th>Тип</th>
              <th>Оценка надёжности</th>
              <th>Налоговый риск</th>
              <th>Номинирован свыше</th>
              <th>Кол-во договоров</th>
            </tr>
          </thead>
          <tbody>
            {contractors.map((contractor) => {
              const contractorContracts = contracts.filter(
                (c) => c.contractor === contractor.id
              );
              return (
                <tr key={contractor.id}>
                  <td>{contractor.name}</td>
                  <td>{contractor.type_display}</td>
                  <td>{contractor.reliability_score}</td>
                  <td>{contractor.tax_risk_flag ? 'Да' : 'Нет'}</td>
                  <td>{contractor.nominated_from_above ? 'Да' : 'Нет'}</td>
                  <td>{contractorContracts.length}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <div className="card">
        <h2>Статьи затрат и физические объёмы</h2>
        <table className="table">
          <thead>
            <tr>
              <th>Вид работ</th>
              <th>Единица</th>
              <th>Объём план</th>
              <th>Объём факт</th>
              <th>Стоимость план</th>
              <th>Стоимость факт</th>
              <th>Отклонение</th>
            </tr>
          </thead>
          <tbody>
            {costItems.map((item) => (
              <tr key={item.id}>
                <td>{item.work_type}</td>
                <td>{item.unit}</td>
                <td>{parseFloat(item.physical_volume_planned).toFixed(2)}</td>
                <td>{parseFloat(item.physical_volume_actual).toFixed(2)}</td>
                <td>{formatCurrency(item.cost_planned)}</td>
                <td>{formatCurrency(item.cost_actual)}</td>
                <td>
                  <span
                    className={
                      parseFloat(item.variance_percent) > 0
                        ? 'text-danger'
                        : 'text-success'
                    }
                  >
                    {parseFloat(item.variance_percent).toFixed(1)}%
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default ProjectPage;
