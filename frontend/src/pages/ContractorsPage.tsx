import React, { useEffect, useState } from 'react';
import { Contractor } from '../types';
import { getContractors, getContractorDetails, exportContractorsCSV } from '../api/client';
import './ContractorsPage.css';

const ContractorsPage: React.FC = () => {
  const [contractors, setContractors] = useState<Contractor[]>([]);
  const [selectedContractor, setSelectedContractor] = useState<Contractor | null>(null);
  const [contractorDetails, setContractorDetails] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [filterType, setFilterType] = useState<string>('');
  const [filterTaxRisk, setFilterTaxRisk] = useState<string>('');
  const [filterNominated, setFilterNominated] = useState<string>('');

  useEffect(() => {
    loadContractors();
  }, [filterType, filterTaxRisk, filterNominated]);

  useEffect(() => {
    if (selectedContractor) {
      loadContractorDetails();
    }
  }, [selectedContractor]);

  const loadContractors = async () => {
    setLoading(true);
    try {
      const params: Record<string, any> = {};
      if (filterType) params.type = filterType;
      if (filterTaxRisk === 'true') params.tax_risk_flag = true;
      if (filterTaxRisk === 'false') params.tax_risk_flag = false;
      if (filterNominated === 'true') params.nominated_from_above = true;
      if (filterNominated === 'false') params.nominated_from_above = false;

      const data = await getContractors(params);
      setContractors(data);
    } catch (error) {
      console.error('Failed to load contractors:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadContractorDetails = async () => {
    if (!selectedContractor) return;
    try {
      const details = await getContractorDetails(selectedContractor.id);
      setContractorDetails(details);
    } catch (error) {
      console.error('Failed to load contractor details:', error);
    }
  };

  const handleExportCSV = async () => {
    try {
      const params: Record<string, any> = {};
      if (filterType) params.type = filterType;
      if (filterTaxRisk === 'true') params.tax_risk_flag = true;
      if (filterTaxRisk === 'false') params.tax_risk_flag = false;
      if (filterNominated === 'true') params.nominated_from_above = true;
      if (filterNominated === 'false') params.nominated_from_above = false;

      const blob = await exportContractorsCSV(params);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'contractors.csv';
      a.click();
      window.URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Failed to export CSV:', error);
    }
  };

  if (loading) {
    return <div className="loading">Загрузка данных...</div>;
  }

  return (
    <div className="container">
      <h1>Рейтинг подрядчиков</h1>

      <div className="card">
        <div className="card-header">
          <h2>Подрядчики</h2>
          <div className="card-actions">
            <div className="filter-bar">
              <select
                value={filterType}
                onChange={(e) => setFilterType(e.target.value)}
              >
                <option value="">Все типы</option>
                <option value="general_contractor">Генподрядчик</option>
                <option value="subcontractor">Подрядчик</option>
              </select>
              <select
                value={filterTaxRisk}
                onChange={(e) => setFilterTaxRisk(e.target.value)}
              >
                <option value="">Все</option>
                <option value="true">С налоговым риском</option>
                <option value="false">Без налогового риска</option>
              </select>
              <select
                value={filterNominated}
                onChange={(e) => setFilterNominated(e.target.value)}
              >
                <option value="">Все</option>
                <option value="true">Номинированы свыше</option>
                <option value="false">Не номинированы свыше</option>
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
              <th>Уровень квалификации</th>
              <th>Оценка надёжности</th>
              <th>Отклонение сроков</th>
              <th>Отклонение бюджета</th>
              <th>Налоговый риск</th>
              <th>Номинирован свыше</th>
              <th>Проектов</th>
              <th>Действия</th>
            </tr>
          </thead>
          <tbody>
            {contractors.map((contractor) => (
              <tr key={contractor.id}>
                <td>{contractor.name}</td>
                <td>{contractor.type_display}</td>
                <td>{contractor.qualification_level_display}</td>
                <td>{contractor.reliability_score}</td>
                <td>{contractor.average_schedule_deviation.toFixed(1)} дн.</td>
                <td>{contractor.average_budget_deviation.toFixed(1)}%</td>
                <td>{contractor.tax_risk_flag ? 'Да' : 'Нет'}</td>
                <td>{contractor.nominated_from_above ? 'Да' : 'Нет'}</td>
                <td>{contractor.projects_count}</td>
                <td>
                  <button
                    className="btn btn-primary btn-sm"
                    onClick={() => setSelectedContractor(contractor)}
                  >
                    Детали
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {selectedContractor && contractorDetails && (
        <div className="card">
          <h2>Детали: {selectedContractor.name}</h2>
          <div className="contractor-details">
            <div>
              <h3>Проекты и договоры</h3>
              {contractorDetails.projects && contractorDetails.projects.length > 0 ? (
                <table className="table">
                  <thead>
                    <tr>
                      <th>Проект</th>
                      <th>Договор</th>
                      <th>План</th>
                      <th>Контракт</th>
                      <th>Статус</th>
                    </tr>
                  </thead>
                  <tbody>
                    {contractorDetails.contracts.map((contract: any) => (
                      <tr key={contract.id}>
                        <td>{contract.project_name}</td>
                        <td>{contract.scope_description || '-'}</td>
                        <td>{parseFloat(contract.planned_amount).toLocaleString('ru-RU')} ₽</td>
                        <td>{parseFloat(contract.contracted_amount).toLocaleString('ru-RU')} ₽</td>
                        <td>
                          <span className={`badge badge-${contract.status === 'active' ? 'info' : contract.status === 'completed' ? 'success' : 'warning'}`}>
                            {contract.status_display}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ) : (
                <p>Нет проектов</p>
              )}
            </div>
          </div>
          <button
            className="btn btn-secondary"
            onClick={() => {
              setSelectedContractor(null);
              setContractorDetails(null);
            }}
          >
            Закрыть
          </button>
        </div>
      )}
    </div>
  );
};

export default ContractorsPage;
