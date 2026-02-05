import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import './LoginPage.css';

const LoginPage: React.FC = () => {
  const { users, setCurrentUser, loading } = useAuth();
  const [selectedUserId, setSelectedUserId] = useState<number | ''>('');
  const navigate = useNavigate();

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    if (selectedUserId) {
      const user = users.find((u) => u.id === selectedUserId);
      if (user) {
        setCurrentUser(user);
        navigate('/');
      }
    }
  };

  if (loading) {
    return <div className="loading">Загрузка пользователей...</div>;
  }

  return (
    <div className="login-page">
      <div className="login-container">
        <h1>RBNA Portal</h1>
        <p className="login-subtitle">Портал подрядчиков</p>
        <form onSubmit={handleLogin} className="login-form">
          <div className="form-group">
            <label htmlFor="user-select">Выберите пользователя:</label>
            <select
              id="user-select"
              value={selectedUserId}
              onChange={(e) => setSelectedUserId(Number(e.target.value) || '')}
              required
            >
              <option value="">-- Выберите пользователя --</option>
              {users.map((user) => (
                <option key={user.id} value={user.id}>
                  {user.name} ({user.role_display})
                </option>
              ))}
            </select>
          </div>
          <button type="submit" className="btn btn-primary btn-block">
            Войти
          </button>
        </form>
        <p className="login-note">
          Для прототипа используется простой выбор пользователя без настоящей аутентификации
        </p>
      </div>
    </div>
  );
};

export default LoginPage;
