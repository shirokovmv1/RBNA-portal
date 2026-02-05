import React, { useEffect, useState } from 'react';
import { UnitRate } from '../types';
import {
  getUnitRates,
  createUnitRate,
  updateUnitRate,
  deleteUnitRate,
} from '../api/client';
import './UnitRatesPage.css';

const UnitRatesPage: React.FC = () => {
  const [unitRates, setUnitRates] = useState<UnitRate[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingRate, setEditingRate] = useState<UnitRate | null>(null);
  const [filterProjectType, setFilterProjectType] = useState<string>('');
  const [filterWorkType, setFilterWorkType] = useState<string>('');

  const [formData, setFormData] = useState({
    project_type: '',
    work_type: '',
    unit: '',
    rate_own_db: '',
    rate_market: '',
    date_from: '',
    date_to: '',
    source: 'own_db',
  });

  useEffect(() => {
    loadUnitRates();
  }, [filterProjectType, filterWorkType]);

  const loadUnitRates = async () => {
    setLoading(true);
    try {
      const params: Record<string, any> = {};
      if (filterProjectType) params.project_type = filterProjectType;
      if (filterWorkType) params.work_type = filterWorkType;

      const data = await getUnitRates(params);
      setUnitRates(data);
    } catch (error) {
      console.error('Failed to load unit rates:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const submitData = {
        ...formData,
        rate_own_db: formData.rate_own_db, // Уже строка из формы
        rate_market: formData.rate_market && formData.rate_market.trim() !== '' ? formData.rate_market : null,
        date_to: formData.date_to && formData.date_to.trim() !== '' ? formData.date_to : null,
      };

      if (editingRate) {
        await updateUnitRate(editingRate.id, submitData);
      } else {
        await createUnitRate(submitData);
      }

      resetForm();
      loadUnitRates();
    } catch (error) {
      console.error('Failed to save unit rate:', error);
      alert('Ошибка при сохранении');
    }
  };

  const handleEdit = (rate: UnitRate) => {
    setEditingRate(rate);
    setFormData({
      project_type: rate.project_type,
      work_type: rate.work_type,
      unit: rate.unit,
      rate_own_db: rate.rate_own_db,
      rate_market: rate.rate_market || '',
      date_from: rate.date_from,
      date_to: rate.date_to || '',
      source: rate.source,
    });
    setShowForm(true);
  };

  const handleDelete = async (id: number) => {
    if (window.confirm('Вы уверены, что хотите удалить эту расценку?')) {
      try {
        await deleteUnitRate(id);
        loadUnitRates();
      } catch (error) {
        console.error('Failed to delete unit rate:', error);
        alert('Ошибка при удалении');
      }
    }
  };

  const resetForm = () => {
    setFormData({
      project_type: '',
      work_type: '',
      unit: '',
      rate_own_db: '',
      rate_market: '',
      date_from: '',
      date_to: '',
      source: 'own_db',
    });
    setEditingRate(null);
    setShowForm(false);
  };

  const formatCurrency = (value: string) => {
    const num = parseFloat(value);
    return new Intl.NumberFormat('ru-RU', {
      style: 'currency',
      currency: 'RUB',
      minimumFractionDigits: 0,
    }).format(num);
  };

  if (loading) {
    return <div className="loading">Загрузка данных...</div>;
  }

  return (
    <div className="container">
      <div className="card-header">
        <h1>База единичных расценок</h1>
        <button
          className="btn btn-primary"
          onClick={() => {
            resetForm();
            setShowForm(true);
          }}
        >
          Добавить расценку
        </button>
      </div>

      {showForm && (
        <div className="card">
          <h2>{editingRate ? 'Редактировать расценку' : 'Новая расценка'}</h2>
          <form onSubmit={handleSubmit}>
            <div className="form-row">
              <div className="form-group">
                <label>Тип проекта *</label>
                <select
                  value={formData.project_type}
                  onChange={(e) =>
                    setFormData({ ...formData, project_type: e.target.value })
                  }
                  required
                >
                  <option value="">Выберите тип</option>
                  <option value="industrial">Промышленное</option>
                  <option value="residential">Жилое</option>
                  <option value="office">Офисное</option>
                  <option value="technopark">Технопарк</option>
                </select>
              </div>
              <div className="form-group">
                <label>Вид работ *</label>
                <input
                  type="text"
                  value={formData.work_type}
                  onChange={(e) =>
                    setFormData({ ...formData, work_type: e.target.value })
                  }
                  required
                />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Единица измерения *</label>
                <input
                  type="text"
                  value={formData.unit}
                  onChange={(e) =>
                    setFormData({ ...formData, unit: e.target.value })
                  }
                  required
                />
              </div>
              <div className="form-group">
                <label>Расценка (собственная БД) *</label>
                <input
                  type="number"
                  step="0.01"
                  value={formData.rate_own_db}
                  onChange={(e) =>
                    setFormData({ ...formData, rate_own_db: e.target.value })
                  }
                  required
                />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Расценка (рыночная)</label>
                <input
                  type="number"
                  step="0.01"
                  value={formData.rate_market}
                  onChange={(e) =>
                    setFormData({ ...formData, rate_market: e.target.value })
                  }
                />
              </div>
              <div className="form-group">
                <label>Источник *</label>
                <select
                  value={formData.source}
                  onChange={(e) =>
                    setFormData({ ...formData, source: e.target.value })
                  }
                  required
                >
                  <option value="own_db">Собственная БД</option>
                  <option value="market">Рыночная</option>
                  <option value="combined">Комбинированная</option>
                </select>
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Дата начала *</label>
                <input
                  type="date"
                  value={formData.date_from}
                  onChange={(e) =>
                    setFormData({ ...formData, date_from: e.target.value })
                  }
                  required
                />
              </div>
              <div className="form-group">
                <label>Дата окончания</label>
                <input
                  type="date"
                  value={formData.date_to}
                  onChange={(e) =>
                    setFormData({ ...formData, date_to: e.target.value })
                  }
                />
              </div>
            </div>
            <div className="form-actions">
              <button type="submit" className="btn btn-primary">
                {editingRate ? 'Сохранить' : 'Создать'}
              </button>
              <button
                type="button"
                className="btn btn-secondary"
                onClick={resetForm}
              >
                Отмена
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="card">
        <div className="filter-bar">
          <select
            value={filterProjectType}
            onChange={(e) => setFilterProjectType(e.target.value)}
          >
            <option value="">Все типы проектов</option>
            <option value="industrial">Промышленное</option>
            <option value="residential">Жилое</option>
            <option value="office">Офисное</option>
            <option value="technopark">Технопарк</option>
          </select>
          <input
            type="text"
            placeholder="Поиск по виду работ"
            value={filterWorkType}
            onChange={(e) => setFilterWorkType(e.target.value)}
          />
        </div>

        <table className="table">
          <thead>
            <tr>
              <th>Тип проекта</th>
              <th>Вид работ</th>
              <th>Единица</th>
              <th>Расценка (БД)</th>
              <th>Расценка (рынок)</th>
              <th>Источник</th>
              <th>Период действия</th>
              <th>Действия</th>
            </tr>
          </thead>
          <tbody>
            {unitRates.map((rate) => (
              <tr key={rate.id}>
                <td>{rate.project_type_display}</td>
                <td>{rate.work_type}</td>
                <td>{rate.unit}</td>
                <td>{formatCurrency(rate.rate_own_db)}</td>
                <td>{rate.rate_market ? formatCurrency(rate.rate_market) : '-'}</td>
                <td>{rate.source_display}</td>
                <td>
                  {new Date(rate.date_from).toLocaleDateString('ru-RU')} -{' '}
                  {rate.date_to
                    ? new Date(rate.date_to).toLocaleDateString('ru-RU')
                    : 'н.в.'}
                </td>
                <td>
                  <button
                    className="btn btn-primary btn-sm"
                    onClick={() => handleEdit(rate)}
                  >
                    Редактировать
                  </button>
                  <button
                    className="btn btn-danger btn-sm"
                    onClick={() => handleDelete(rate.id)}
                    style={{ marginLeft: '5px' }}
                  >
                    Удалить
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default UnitRatesPage;
