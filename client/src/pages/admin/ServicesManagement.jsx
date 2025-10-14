import { useState, useEffect } from 'react';
import api from '../../services/api';
import Modal from '../../components/Modal';
import Toast from '../../components/Toast';
import IconPicker from '../../components/IconPicker';
import sanitizeSvgFragment from '../../utils/sanitizeSvg';
import './Management.css';

const ServicesManagement = () => {
  const [services, setServices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingService, setEditingService] = useState(null);
  const [toast, setToast] = useState(null);

  useEffect(() => {
    loadServices();
  }, []);

  const loadServices = async () => {
    try {
      const response = await api.get('/services');
      setServices(response.data || []);
    } catch (error) {
      console.error('Error loading services:', error);
      showToastMessage('Error al cargar servicios', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async data => {
    try {
      console.log('Enviando datos:', data);
      if (editingService) {
        await api.put(`/services/${editingService.id}`, data);
        showToastMessage('¡Servicio actualizado con éxito!', 'success');
      } else {
        await api.post('/services', data);
        showToastMessage('¡Servicio creado con éxito!', 'success');
      }
      setShowModal(false);
      loadServices();
    } catch (error) {
      console.error('Error completo:', error);
      showToastMessage(error.message || 'Error al guardar servicio', 'error');
    }
  };

  const handleDelete = async id => {
    if (!window.confirm('¿Está seguro de que desea eliminar este servicio?'))
      return;

    try {
      await api.delete(`/services/${id}`);
      showToastMessage('¡Servicio eliminado con éxito!', 'success');
      loadServices();
    } catch (error) {
      console.error('Error deleting service:', error);
      showToastMessage('Error al eliminar servicio', 'error');
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
    <div className="management-page">
      <div className="page-header">
        <button
          className="btn btn-primary"
          onClick={() => {
            setEditingService(null);
            setShowModal(true);
          }}
        >
          + Agregar Servicio
        </button>
      </div>

      <div className="data-grid">
        {services.length === 0 ? (
          <p className="empty-message">Ningún servicio registrado</p>
        ) : (
          services.map(service => {
            const sanitizedIcon = sanitizeSvgFragment(service.icon);

            return (
              <div key={service.id} className="data-card">
                <div className="service-icon-display">
                  {sanitizedIcon ? (
                    <div dangerouslySetInnerHTML={{ __html: sanitizedIcon }} />
                  ) : (
                    <div className="icon-placeholder">📋</div>
                  )}
                </div>
                <h3>{service.title}</h3>
                <p>{service.description}</p>
                <div className="card-actions">
                  <button
                    className="btn btn-sm btn-outline"
                    onClick={() => {
                      setEditingService(service);
                      setShowModal(true);
                    }}
                  >
                    Editar
                  </button>
                  <button
                    className="btn btn-sm btn-danger"
                    onClick={() => handleDelete(service.id)}
                  >
                    Eliminar
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>

      {showModal && (
        <ServiceModal
          service={editingService}
          onClose={() => setShowModal(false)}
          onSubmit={handleSubmit}
        />
      )}

      {toast && <Toast message={toast.message} type={toast.type} />}
    </div>
  );
};

/* eslint-disable react/prop-types */
const ServiceModal = ({ service, onClose, onSubmit }) => {
  const [formData, setFormData] = useState({
    title: service?.title || '',
    description: service?.description || '',
    icon: service?.icon || '',
    features: service?.features ? service.features.join('\n') : '',
    order_position: service?.order_position || 0,
    active: service?.active !== 0,
  });

  const handleSubmit = e => {
    e.preventDefault();

    // Validación
    if (!formData.icon || formData.icon.trim() === '') {
      alert('Por favor, seleccione un ícono o ingrese un SVG path');
      return;
    }

    const data = {
      ...formData,
      features: formData.features.split('\n').filter(f => f.trim()),
      order_position: parseInt(formData.order_position),
      active: formData.active ? 1 : 0,
    };

    onSubmit(data);
  };

  return (
    <Modal
      title={service ? 'Editar Servicio' : 'Agregar Servicio'}
      onClose={onClose}
    >
      <form onSubmit={handleSubmit} className="modal-form">
        <div className="form-group">
          <label htmlFor="serviceTitle">Título</label>
          <input
            id="serviceTitle"
            type="text"
            value={formData.title}
            onChange={e => setFormData({ ...formData, title: e.target.value })}
            required
          />
        </div>

        <div className="form-group">
          <label htmlFor="serviceDescription">Descripción</label>
          <textarea
            id="serviceDescription"
            value={formData.description}
            onChange={e =>
              setFormData({ ...formData, description: e.target.value })
            }
            required
          />
        </div>

        <div className="form-group">
          <IconPicker
            value={formData.icon}
            onChange={icon => setFormData({ ...formData, icon })}
          />
        </div>

        <div className="form-group">
          <label htmlFor="serviceFeatures">
            Características (una por línea)
          </label>
          <textarea
            id="serviceFeatures"
            value={formData.features}
            onChange={e =>
              setFormData({ ...formData, features: e.target.value })
            }
            rows={4}
          />
        </div>

        <div className="form-group">
          <label htmlFor="serviceOrder">Orden</label>
          <input
            id="serviceOrder"
            type="number"
            value={formData.order_position}
            onChange={e =>
              setFormData({ ...formData, order_position: e.target.value })
            }
          />
        </div>

        <div className="form-group">
          <label htmlFor="serviceActive">
            <input
              id="serviceActive"
              type="checkbox"
              checked={formData.active}
              onChange={e =>
                setFormData({ ...formData, active: e.target.checked })
              }
            />{' '}
            Activo
          </label>
        </div>

        <div className="modal-footer">
          <button type="button" className="btn btn-outline" onClick={onClose}>
            Cancelar
          </button>
          <button type="submit" className="btn btn-primary">
            {service ? 'Actualizar' : 'Crear'}
          </button>
        </div>
      </form>
    </Modal>
  );
};

export default ServicesManagement;
