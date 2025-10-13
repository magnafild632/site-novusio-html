import { useState, useEffect } from 'react';
import api from '../../services/api';
import Toast from '../../components/Toast';
import './CompanyInfo.css';

const CompanyInfo = () => {
  const [formData, setFormData] = useState({
    company_name: '',
    email: '',
    phone: '',
    location: '',
    about_text: '',
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);

  useEffect(() => {
    loadCompanyInfo();
  }, []);

  const loadCompanyInfo = async () => {
    try {
      const response = await api.get('/company');
      setFormData(response.data || {});
    } catch (error) {
      showToastMessage('Error al cargar información', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async e => {
    e.preventDefault();
    setSaving(true);

    try {
      await api.put('/company', formData);
      showToastMessage('¡Información actualizada con éxito!', 'success');
    } catch (error) {
      showToastMessage('Error al guardar información', 'error');
    } finally {
      setSaving(false);
    }
  };

  const showToastMessage = (message, type) => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  if (loading) {
    return (
      <div className="loading">
        <div className="spinner"></div>
      </div>
    );
  }

  return (
    <div className="company-info-page">
      <form onSubmit={handleSubmit} className="company-form">
        <h3>Información de la Empresa</h3>

        <div className="form-group">
          <label>Nombre de la Empresa</label>
          <input
            type="text"
            value={formData.company_name}
            onChange={e =>
              setFormData({ ...formData, company_name: e.target.value })
            }
            required
          />
        </div>

        <div className="form-group">
          <label>Email</label>
          <input
            type="email"
            value={formData.email}
            onChange={e => setFormData({ ...formData, email: e.target.value })}
            required
          />
        </div>

        <div className="form-group">
          <label>Teléfono</label>
          <input
            type="tel"
            value={formData.phone}
            onChange={e => setFormData({ ...formData, phone: e.target.value })}
            placeholder="+595 981 234 567"
            required
          />
        </div>

        <div className="form-group">
          <label>Ubicación</label>
          <input
            type="text"
            value={formData.location}
            onChange={e =>
              setFormData({ ...formData, location: e.target.value })
            }
            required
          />
        </div>

        <div className="form-group">
          <label>Sobre la Empresa</label>
          <textarea
            value={formData.about_text}
            onChange={e =>
              setFormData({ ...formData, about_text: e.target.value })
            }
            rows={5}
            required
          />
        </div>

        <button type="submit" className="btn btn-primary" disabled={saving}>
          {saving ? 'Guardando...' : 'Guardar Cambios'}
        </button>
      </form>

      {toast && <Toast message={toast.message} type={toast.type} />}
    </div>
  );
};

export default CompanyInfo;
