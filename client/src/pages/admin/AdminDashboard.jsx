import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../../services/api';
import './AdminDashboard.css';

const AdminDashboard = () => {
  const [stats, setStats] = useState({
    slides: 0,
    services: 0,
    clients: 0,
    messages: 0,
  });
  const navigate = useNavigate();

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      const [slides, services, portfolio, messages] = await Promise.all([
        api.get('/slides'),
        api.get('/services'),
        api.get('/portfolio'),
        api.get('/contact'),
      ]);

      setStats({
        slides: slides.data?.length || 0,
        services: services.data?.length || 0,
        clients: portfolio.data?.length || 0,
        messages: messages.data?.length || 0,
      });
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  };

  return (
    <div className="dashboard">
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon" style={{ backgroundColor: '#dbeafe' }}>
            <span style={{ color: '#3b82f6' }}>📊</span>
          </div>
          <div className="stat-info">
            <h3>{stats.slides}</h3>
            <p>Slides</p>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ backgroundColor: '#dcfce7' }}>
            <span style={{ color: '#22c55e' }}>🔧</span>
          </div>
          <div className="stat-info">
            <h3>{stats.services}</h3>
            <p>Servicios</p>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ backgroundColor: '#fef3c7' }}>
            <span style={{ color: '#f59e0b' }}>💼</span>
          </div>
          <div className="stat-info">
            <h3>{stats.clients}</h3>
            <p>Clientes</p>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon" style={{ backgroundColor: '#fce7f3' }}>
            <span style={{ color: '#ec4899' }}>📧</span>
          </div>
          <div className="stat-info">
            <h3>{stats.messages}</h3>
            <p>Mensajes</p>
          </div>
        </div>
      </div>

      <div className="welcome-card">
        <h2>Bienvenido al Panel Administrativo</h2>
        <p>
          Gestiona todo el contenido del sitio web de Novusio desde este panel.
          Usa el menú lateral para navegar entre las diferentes secciones.
        </p>
        <div className="quick-actions">
          <button
            className="btn btn-primary"
            onClick={() => navigate('/admin/slides')}
          >
            Gestionar Slides
          </button>
          <button
            className="btn btn-outline"
            onClick={() => navigate('/admin/messages')}
          >
            Ver Mensajes
          </button>
        </div>
      </div>
    </div>
  );
};

export default AdminDashboard;
