import { Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import PublicLayout from './components/layouts/PublicLayout';
import AdminLayout from './components/layouts/AdminLayout';
import HomePage from './pages/public/HomePage';
import LoginPage from './pages/admin/LoginPage';
import AdminDashboard from './pages/admin/AdminDashboard';
import SlidesManagement from './pages/admin/SlidesManagement';
import ServicesManagement from './pages/admin/ServicesManagement';
import PortfolioManagement from './pages/admin/PortfolioManagement';
import MessagesManagement from './pages/admin/MessagesManagement';
import CompanyInfo from './pages/admin/CompanyInfo';
import ProtectedRoute from './components/ProtectedRoute';

function App() {
  return (
    <AuthProvider>
      <Routes>
        {/* Rutas Públicas */}
        <Route path="/" element={<PublicLayout />}>
          <Route index element={<HomePage />} />
        </Route>

        {/* Ruta de Login */}
        <Route path="/admin/login" element={<LoginPage />} />

        {/* Rutas Admin Protegidas */}
        <Route
          path="/admin"
          element={
            <ProtectedRoute>
              <AdminLayout />
            </ProtectedRoute>
          }
        >
          <Route index element={<AdminDashboard />} />
          <Route path="slides" element={<SlidesManagement />} />
          <Route path="services" element={<ServicesManagement />} />
          <Route path="portfolio" element={<PortfolioManagement />} />
          <Route path="messages" element={<MessagesManagement />} />
          <Route path="company" element={<CompanyInfo />} />
        </Route>

        {/* Ruta 404 */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </AuthProvider>
  );
}

export default App;
