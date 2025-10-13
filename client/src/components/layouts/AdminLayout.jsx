import { Outlet, Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import './AdminLayout.css';

const AdminLayout = () => {
  const { user, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/admin/login');
  };

  const menuItems = [
    { path: '/admin', label: 'Panel Principal', icon: 'dashboard' },
    { path: '/admin/slides', label: 'Slides Hero', icon: 'slides' },
    { path: '/admin/services', label: 'Servicios', icon: 'services' },
    { path: '/admin/portfolio', label: 'Portafolio', icon: 'portfolio' },
    { path: '/admin/messages', label: 'Mensajes', icon: 'messages' },
    { path: '/admin/company', label: 'Información', icon: 'company' },
  ];

  return (
    <div className="admin-layout">
      <aside className="sidebar">
        <div className="sidebar-header">
          <div className="logo-small">
            <span className="logo-text">N</span>
          </div>
          <span className="company-name">NOVUSIO</span>
        </div>

        <nav className="sidebar-nav">
          {menuItems.map(item => (
            <Link
              key={item.path}
              to={item.path}
              className={`nav-item ${
                location.pathname === item.path ? 'active' : ''
              }`}
            >
              <span>{item.label}</span>
            </Link>
          ))}
        </nav>

        <div className="sidebar-footer">
          <button onClick={handleLogout} className="btn btn-outline btn-block">
            Cerrar Sesión
          </button>
        </div>
      </aside>

      <main className="main-content">
        <header className="top-header">
          <h1>
            {menuItems.find(item => item.path === location.pathname)?.label ||
              'Admin'}
          </h1>
          <div className="user-info">
            <span>{user?.name || 'Administrador'}</span>
          </div>
        </header>

        <div className="content-area">
          <Outlet />
        </div>
      </main>
    </div>
  );
};

export default AdminLayout;
