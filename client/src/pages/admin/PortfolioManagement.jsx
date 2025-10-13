import { useState, useEffect } from 'react';
import api, { uploadFile } from '../../services/api';
import Modal from '../../components/Modal';
import Toast from '../../components/Toast';
import './Management.css';

const PortfolioManagement = () => {
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingClient, setEditingClient] = useState(null);
  const [toast, setToast] = useState(null);

  useEffect(() => {
    loadClients();
  }, []);

  const loadClients = async () => {
    try {
      const response = await api.get('/portfolio');
      setClients(response.data || []);
    } catch (error) {
      showToastMessage('Error al cargar clientes', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async formData => {
    try {
      if (editingClient) {
        await uploadFile(`/portfolio/${editingClient.id}`, formData, 'PUT');
        showToastMessage('¡Cliente actualizado con éxito!', 'success');
      } else {
        await uploadFile('/portfolio', formData, 'POST');
        showToastMessage('¡Cliente creado con éxito!', 'success');
      }
      setShowModal(false);
      loadClients();
    } catch (error) {
      console.error('Error al guardar cliente:', error);
      showToastMessage(error.message || 'Error al guardar cliente', 'error');
    }
  };

  const handleDelete = async id => {
    if (!window.confirm('¿Está seguro de que desea eliminar este cliente?'))
      return;

    try {
      await api.delete(`/portfolio/${id}`);
      showToastMessage('¡Cliente eliminado con éxito!', 'success');
      loadClients();
    } catch (error) {
      showToastMessage('Error al eliminar cliente', 'error');
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
            setEditingClient(null);
            setShowModal(true);
          }}
        >
          + Agregar Cliente
        </button>
      </div>

      <div className="data-grid">
        {clients.length === 0 ? (
          <p className="empty-message">Ningún cliente registrado</p>
        ) : (
          clients.map(client => (
            <div key={client.id} className="data-card">
              <img
                src={client.logo_url}
                alt={client.name}
                className="card-image logo"
                onError={e =>
                  (e.target.src = `https://via.placeholder.com/300x150?text=${client.name}`)
                }
              />
              <h3>{client.name}</h3>
              <div className="card-actions">
                <button
                  className="btn btn-sm btn-outline"
                  onClick={() => {
                    setEditingClient(client);
                    setShowModal(true);
                  }}
                >
                  Editar
                </button>
                <button
                  className="btn btn-sm btn-danger"
                  onClick={() => handleDelete(client.id)}
                >
                  Eliminar
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {showModal && (
        <ClientModal
          client={editingClient}
          onClose={() => setShowModal(false)}
          onSubmit={handleSubmit}
        />
      )}

      {toast && <Toast message={toast.message} type={toast.type} />}
    </div>
  );
};

const ClientModal = ({ client, onClose, onSubmit }) => {
  const [name, setName] = useState(client?.name || '');
  const [logoFile, setLogoFile] = useState(null);
  const [preview, setPreview] = useState(client?.logo_url || '');

  const handleLogoChange = e => {
    const file = e.target.files?.[0];
    if (file) {
      setLogoFile(file);
      const reader = new FileReader();
      reader.onload = e => setPreview(e.target?.result);
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = e => {
    e.preventDefault();

    const data = new FormData();
    data.append('name', name);
    data.append('order_position', 0);
    data.append('active', 1);

    if (logoFile) {
      data.append('logo', logoFile);
    }

    onSubmit(data);
  };

  return (
    <Modal
      title={client ? 'Editar Cliente' : 'Agregar Cliente'}
      onClose={onClose}
    >
      <form onSubmit={handleSubmit} className="modal-form">
        <div className="form-group">
          <label>Nombre del Cliente</label>
          <input
            type="text"
            value={name}
            onChange={e => setName(e.target.value)}
            required
          />
        </div>

        <div className="form-group">
          <label>Logo</label>
          <input type="file" accept="image/*" onChange={handleLogoChange} />
          {preview && (
            <img src={preview} alt="Preview" className="image-preview" />
          )}
        </div>

        <div className="modal-footer">
          <button type="button" className="btn btn-outline" onClick={onClose}>
            Cancelar
          </button>
          <button type="submit" className="btn btn-primary">
            {client ? 'Actualizar' : 'Crear'}
          </button>
        </div>
      </form>
    </Modal>
  );
};

export default PortfolioManagement;
