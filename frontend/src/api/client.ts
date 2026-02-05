import axios from 'axios';
import {
  User,
  Project,
  Contractor,
  Contract,
  CostItem,
  UnitRate,
  Payment,
  Report,
} from '../types';

const API_BASE_URL = process.env.REACT_APP_API_URL || '/api';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Projects
export const getProjects = async (params?: Record<string, any>): Promise<Project[]> => {
  const response = await apiClient.get('/projects/', { params });
  return response.data.results || response.data;
};

export const getProject = async (id: number): Promise<Project> => {
  const response = await apiClient.get(`/projects/${id}/`);
  return response.data;
};

export const getProjectAlerts = async () => {
  const response = await apiClient.get('/projects/alerts/');
  return response.data;
};

export const exportProjectsCSV = async (params?: Record<string, any>): Promise<Blob> => {
  const response = await apiClient.get('/projects/export_csv/', {
    params,
    responseType: 'blob',
  });
  return response.data;
};

// Contractors
export const getContractors = async (params?: Record<string, any>): Promise<Contractor[]> => {
  const response = await apiClient.get('/contractors/', { params });
  return response.data.results || response.data;
};

export const getContractor = async (id: number): Promise<Contractor> => {
  const response = await apiClient.get(`/contractors/${id}/`);
  return response.data;
};

export const getContractorDetails = async (id: number) => {
  const response = await apiClient.get(`/contractors/${id}/details/`);
  return response.data;
};

export const exportContractorsCSV = async (params?: Record<string, any>): Promise<Blob> => {
  const response = await apiClient.get('/contractors/export_csv/', {
    params,
    responseType: 'blob',
  });
  return response.data;
};

// Contracts
export const getContracts = async (params?: Record<string, any>): Promise<Contract[]> => {
  const response = await apiClient.get('/contracts/', { params });
  return response.data.results || response.data;
};

export const getContract = async (id: number): Promise<Contract> => {
  const response = await apiClient.get(`/contracts/${id}/`);
  return response.data;
};

export const exportContractsCSV = async (params?: Record<string, any>): Promise<Blob> => {
  const response = await apiClient.get('/contracts/export_csv/', {
    params,
    responseType: 'blob',
  });
  return response.data;
};

// Cost Items
export const getCostItems = async (params?: Record<string, any>): Promise<CostItem[]> => {
  const response = await apiClient.get('/cost-items/', { params });
  return response.data.results || response.data;
};

export const exportCostItemsCSV = async (params?: Record<string, any>): Promise<Blob> => {
  const response = await apiClient.get('/cost-items/export_csv/', {
    params,
    responseType: 'blob',
  });
  return response.data;
};

// Unit Rates
export const getUnitRates = async (params?: Record<string, any>): Promise<UnitRate[]> => {
  const response = await apiClient.get('/unit-rates/', { params });
  return response.data.results || response.data;
};

export const createUnitRate = async (data: Partial<UnitRate>): Promise<UnitRate> => {
  const response = await apiClient.post('/unit-rates/', data);
  return response.data;
};

export const updateUnitRate = async (id: number, data: Partial<UnitRate>): Promise<UnitRate> => {
  const response = await apiClient.put(`/unit-rates/${id}/`, data);
  return response.data;
};

export const deleteUnitRate = async (id: number): Promise<void> => {
  await apiClient.delete(`/unit-rates/${id}/`);
};

// Payments
export const getPayments = async (params?: Record<string, any>): Promise<Payment[]> => {
  const response = await apiClient.get('/payments/', { params });
  return response.data.results || response.data;
};

// Reports
export const getReports = async (params?: Record<string, any>): Promise<Report[]> => {
  const response = await apiClient.get('/reports/', { params });
  return response.data.results || response.data;
};

export const updateReport = async (id: number, data: Partial<Report>): Promise<Report> => {
  const response = await apiClient.patch(`/reports/${id}/`, data);
  return response.data;
};

// Users
export const getUsers = async (): Promise<User[]> => {
  const response = await apiClient.get('/users/');
  return response.data.results || response.data;
};

export default apiClient;
