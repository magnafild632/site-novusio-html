import axios from 'axios';

const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor para adicionar token
api.interceptors.request.use(
  config => {
    const token = localStorage.getItem('admin_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  error => {
    return Promise.reject(error);
  },
);

// Interceptor para tratar erros
api.interceptors.response.use(
  response => response.data,
  error => {
    if (error.response?.status === 401) {
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_user');
      window.location.href = '/admin/login';
    }
    return Promise.reject(error.response?.data || error.message);
  },
);

// Upload helper
export const uploadFile = async (endpoint, formData, method = 'POST') => {
  const token = localStorage.getItem('admin_token');

  try {
    const response = await fetch(`/api${endpoint}`, {
      method: method,
      headers: {
        Authorization: `Bearer ${token}`,
      },
      body: formData,
    });

    const data = await response.json();

    if (!response.ok) {
      // Mensagens de erro mais específicas
      if (response.status === 413) {
        throw new Error('Arquivo muito grande. O tamanho máximo permitido é 50MB.');
      } else if (response.status === 400) {
        throw new Error(data.message || 'Arquivo inválido ou formato não suportado.');
      } else if (response.status === 500) {
        throw new Error('Erro interno do servidor. Tente novamente.');
      } else {
        throw new Error(data.message || 'Erro no upload do arquivo.');
      }
    }

    return data;
  } catch (error) {
    if (error.name === 'TypeError' && error.message.includes('Failed to fetch')) {
      throw new Error('Erro de conexão. Verifique sua internet e tente novamente.');
    }
    throw error;
  }
};

export default api;
