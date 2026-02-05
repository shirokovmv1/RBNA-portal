import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { User, UserRole } from '../types';
import { getUsers } from '../api/client';

interface AuthContextType {
  currentUser: User | null;
  setCurrentUser: (user: User | null) => void;
  users: User[];
  loading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Загружаем список пользователей
    getUsers()
      .then((data) => {
        setUsers(data);
        // Восстанавливаем выбранного пользователя из localStorage
        const savedUserId = localStorage.getItem('currentUserId');
        if (savedUserId) {
          const user = data.find((u) => u.id === parseInt(savedUserId));
          if (user) {
            setCurrentUser(user);
          }
        }
      })
      .catch((error) => {
        console.error('Failed to load users:', error);
      })
      .finally(() => {
        setLoading(false);
      });
  }, []);

  const handleSetCurrentUser = (user: User | null) => {
    setCurrentUser(user);
    if (user) {
      localStorage.setItem('currentUserId', user.id.toString());
    } else {
      localStorage.removeItem('currentUserId');
    }
  };

  return (
    <AuthContext.Provider
      value={{
        currentUser,
        setCurrentUser: handleSetCurrentUser,
        users,
        loading,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
