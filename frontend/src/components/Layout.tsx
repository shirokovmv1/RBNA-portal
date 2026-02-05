import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { UserRole } from '../types';
import './Layout.css';

interface LayoutProps {
  children: React.ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  const { currentUser, setCurrentUser } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    setCurrentUser(null);
    navigate('/login');
  };

  const canAccessFinancial = () => {
    if (!currentUser) return false;
    return [
      UserRole.ADMIN,
      UserRole.TOP_MANAGER,
      UserRole.FIN_MANAGER,
    ].includes(currentUser.role);
  };

  const canAccessUnitRates = () => {
    if (!currentUser) return false;
    return [
      UserRole.ADMIN,
      UserRole.PM,
      UserRole.FIN_MANAGER,
    ].includes(currentUser.role);
  };

  return (
    <div className="layout">
      <nav className="navbar">
        <div className="navbar-brand">
          <Link to="/">RBNA Portal</Link>
        </div>
        <div className="navbar-menu">
          <Link to="/" className="nav-link">
            Проекты
          </Link>
          {canAccessFinancial() && (
            <Link to="/financial" className="nav-link">
              Финансы
            </Link>
          )}
          <Link to="/contractors" className="nav-link">
            Подрядчики
          </Link>
          {canAccessUnitRates() && (
            <Link to="/unit-rates" className="nav-link">
              Единичные расценки
            </Link>
          )}
        </div>
        <div className="navbar-user">
          {currentUser && (
            <>
              <span className="user-info">
                {currentUser.name} ({currentUser.role_display})
              </span>
              <button onClick={handleLogout} className="btn btn-secondary">
                Выйти
              </button>
            </>
          )}
        </div>
      </nav>
      <main className="main-content">{children}</main>
    </div>
  );
};

export default Layout;
