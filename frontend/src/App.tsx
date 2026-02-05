import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import FinancialPage from './pages/FinancialPage';
import ProjectPage from './pages/ProjectPage';
import ContractorsPage from './pages/ContractorsPage';
import UnitRatesPage from './pages/UnitRatesPage';
import PrivateRoute from './components/PrivateRoute';
import Layout from './components/Layout';
import './App.css';

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route
            path="/"
            element={
              <PrivateRoute>
                <Layout>
                  <DashboardPage />
                </Layout>
              </PrivateRoute>
            }
          />
          <Route
            path="/financial"
            element={
              <PrivateRoute>
                <Layout>
                  <FinancialPage />
                </Layout>
              </PrivateRoute>
            }
          />
          <Route
            path="/project/:id"
            element={
              <PrivateRoute>
                <Layout>
                  <ProjectPage />
                </Layout>
              </PrivateRoute>
            }
          />
          <Route
            path="/contractors"
            element={
              <PrivateRoute>
                <Layout>
                  <ContractorsPage />
                </Layout>
              </PrivateRoute>
            }
          />
          <Route
            path="/unit-rates"
            element={
              <PrivateRoute>
                <Layout>
                  <UnitRatesPage />
                </Layout>
              </PrivateRoute>
            }
          />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;
