import React, { useEffect, useState } from 'react';
import { Contract, CostItem, Report } from '../types';
import { getContracts, getCostItems, getReports, updateReport, exportContractsCSV, exportCostItemsCSV } from '../api/client';
import './FinancialPage.css';

const FinancialPage: React.FC = () => {
  const [selectedProjectId, setSelectedProjectId] = useState<number | ''>('');
  const [selectedContractId, setSelectedContractId] = useState<number | ''>('');
  const [contracts, setContracts] = useState<Contract[]>([]);
  const [costItems, setCostItems] = useState<CostItem[]>([]);
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(false);
  const [reportStatusFilter, setReportStatusFilter] = useState<string>('');

  useEffect(() => {
    if (selectedProjectId) {
      loadContracts();
      loadReports();
    }
  }, [selectedProjectId]);

  useEffect(() => {
    if (selectedContractId) {
      loadCostItems();
    }
  }, [selectedContractId]);

  useEffect(() => {
    if (selectedProjectId) {
      loadReports();
    }
  }, [reportStatusFilter]);

  const loadContracts = async () => {
    if (!selectedProjectId) return;
    setLoading(true);
    try {
      const data = await getContracts({ project: selectedProjectId });
      setContracts(data);
    } catch (error) {
      console.error('Failed to load contracts:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadCostItems = async () => {
    if (!selectedContractId) return;
    setLoading(true);
    try {
      const data = await getCostItems({ contract: selectedContractId });
      setCostItems(data);
    } catch (error) {
      console.error('Failed to load cost items:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadReports = async () => {
    if (!selectedProjectId) return;
    setLoading(true);
    try {
      const params: Record<string, any> = { project: selectedProjectId };
      if (reportStatusFilter) params.status = reportStatusFilter;
      const data = await getReports(params);
      setReports(data);
    } catch (error) {
      console.error('Failed to load reports:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleExportContracts = async () => {
    if (!selectedProjectId) return;
    try {
      const blob = await exportContractsCSV({ project: selectedProjectId });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'contracts.csv';
      a.click();
      window.URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Failed to export CSV:', error);
    }
  };

  const handleExportCostItems = async () => {
    if (!selectedContractId) return;
    try {
      const blob = await exportCostItemsCSV({ contract: selectedContractId });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'cost_items.csv';
      a.click();
      window.URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Failed to export CSV:', error);
    }
  };

  const handleReportStatusChange = async (reportId: number, newStatus: string) => {
    try {
      await updateReport(reportId, { status: newStatus });
      loadReports();
    } catch (error) {
      console.error('Failed to update report:', error);
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

  return (
    <div className="container">
      <h1>Финансовая панель</h1>

      <div className="card">
        <h2>Выбор проекта</h2>
        <div className="form-group">
          <label>Проект ID:</label>
          <input
            type="number"
            value={selectedProjectId}
            onChange={(e) => {
              setSelectedProjectId(Number(e.target.value) || '');
              setSelectedContractId('');
              setCostItems([]);
            }}
            placeholder="Введите ID проекта"
          />
        </div>
      </div>

      {selectedProjectId && (
        <>
          <div className="card">
            <div className="card-header">
              <h2>Договоры проекта</h2>
              <button onClick={handleExportContracts} className="btn btn-secondary">
                Экспорт CSV
              </button>
            </div>
            <table className="table">
              <thead>
                <tr>
                  <th>Подрядчик</th>
                  <th>План</th>
                  <th>Контракт</th>
                  <th>Оплачено</th>
                  <th>Отклонение</th>
                  <th>Статус</th>
                  <th>Действия</th>
                </tr>
              </thead>
              <tbody>
                {contracts.map((contract) => (
                  <tr
                    key={contract.id}
                    onClick={() => setSelectedContractId(contract.id)}
                    className={selectedContractId === contract.id ? 'selected' : ''}
                    style={{ cursor: 'pointer' }}
                  >
                    <td>{contract.contractor_name}</td>
                    <td>{formatCurrency(contract.planned_amount)}</td>
                    <td>{formatCurrency(contract.contracted_amount)}</td>
                    <td>{formatCurrency(contract.paid_amount)}</td>
                    <td>
                      <span
                        className={
                          parseFloat(contract.variance_percent) > 0
                            ? 'text-danger'
                            : 'text-success'
                        }
                      >
                        {parseFloat(contract.variance_percent).toFixed(1)}%
                      </span>
                    </td>
                    <td>
                      <span className={`badge badge-${contract.status === 'active' ? 'info' : contract.status === 'completed' ? 'success' : 'warning'}`}>
                        {contract.status_display}
                      </span>
                    </td>
                    <td>
                      <button
                        className="btn btn-primary btn-sm"
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedContractId(contract.id);
                        }}
                      >
                        Выбрать
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {selectedContractId && (
            <div className="card">
              <div className="card-header">
                <h2>Статьи затрат по договору</h2>
                <button onClick={handleExportCostItems} className="btn btn-secondary">
                  Экспорт CSV
                </button>
              </div>
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
          )}

          <div className="card">
            <h2>Отчёты генподрядчика</h2>
            <div className="filter-bar">
              <select
                value={reportStatusFilter}
                onChange={(e) => setReportStatusFilter(e.target.value)}
              >
                <option value="">Все статусы</option>
                <option value="received">Получен</option>
                <option value="under_review">На проверке</option>
                <option value="accepted">Принят</option>
                <option value="accepted_with_issues">Принят с замечаниями</option>
                <option value="rejected">Отклонён</option>
              </select>
            </div>
            <table className="table">
              <thead>
                <tr>
                  <th>Подрядчик</th>
                  <th>Период</th>
                  <th>Статус</th>
                  <th>Непротиворечивость</th>
                  <th>Часов на обработку</th>
                  <th>Действия</th>
                </tr>
              </thead>
              <tbody>
                {reports.map((report) => (
                  <tr key={report.id}>
                    <td>{report.contractor_name}</td>
                    <td>
                      {new Date(report.period_start).toLocaleDateString('ru-RU')} -{' '}
                      {new Date(report.period_end).toLocaleDateString('ru-RU')}
                    </td>
                    <td>
                      <span className={`badge badge-${report.status === 'accepted' ? 'success' : report.status === 'rejected' ? 'danger' : 'warning'}`}>
                        {report.status_display}
                      </span>
                    </td>
                    <td>{report.consistency_score}%</td>
                    <td>{parseFloat(report.processing_effort_hours).toFixed(1)}</td>
                    <td>
                      <select
                        value={report.status}
                        onChange={(e) => handleReportStatusChange(report.id, e.target.value)}
                        className="form-control-sm"
                      >
                        <option value="received">Получен</option>
                        <option value="under_review">На проверке</option>
                        <option value="accepted">Принят</option>
                        <option value="accepted_with_issues">Принят с замечаниями</option>
                        <option value="rejected">Отклонён</option>
                      </select>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}
    </div>
  );
};

export default FinancialPage;
