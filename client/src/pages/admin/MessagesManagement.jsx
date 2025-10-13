import { useState, useEffect } from 'react';
import api from '../../services/api';
import Toast from '../../components/Toast';
import './MessagesManagement.css';

const MessagesManagement = () => {
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState(null);

  useEffect(() => {
    loadMessages();
  }, []);

  const loadMessages = async () => {
    try {
      const response = await api.get('/contact');
      setMessages(response.data || []);
    } catch (error) {
      showToastMessage('Error al cargar mensajes', 'error');
    } finally {
      setLoading(false);
    }
  };

  const markAsRead = async id => {
    try {
      await api.request(`/contact/${id}/read`, { method: 'PATCH' });
      showToastMessage('¡Mensaje marcado como leído!', 'success');
      loadMessages();
    } catch (error) {
      showToastMessage('Error al marcar mensaje', 'error');
    }
  };

  const deleteMessage = async id => {
    if (!window.confirm('¿Está seguro de que desea eliminar este mensaje?'))
      return;

    try {
      await api.delete(`/contact/${id}`);
      showToastMessage('¡Mensaje eliminado con éxito!', 'success');
      loadMessages();
    } catch (error) {
      showToastMessage('Error al eliminar mensaje', 'error');
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
    <div className="messages-page">
      {messages.length === 0 ? (
        <p className="empty-message">Ningún mensaje recibido</p>
      ) : (
        <div className="messages-list">
          {messages.map(message => (
            <div
              key={message.id}
              className={`message-card ${
                message.read_status === 0 ? 'unread' : ''
              }`}
            >
              <div className="message-header">
                <div>
                  <div className="message-sender">{message.name}</div>
                  <div className="message-email">{message.email}</div>
                  {message.phone && (
                    <div className="message-phone">{message.phone}</div>
                  )}
                  {message.company && (
                    <div className="message-company">{message.company}</div>
                  )}
                </div>
                <div className="message-date">
                  {new Date(message.created_at).toLocaleString('es-PY')}
                </div>
              </div>
              <div className="message-text">{message.message}</div>
              <div className="message-actions">
                {message.read_status === 0 && (
                  <button
                    className="btn btn-sm btn-primary"
                    onClick={() => markAsRead(message.id)}
                  >
                    Marcar como Leído
                  </button>
                )}
                <button
                  className="btn btn-sm btn-danger"
                  onClick={() => deleteMessage(message.id)}
                >
                  Eliminar
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {toast && <Toast message={toast.message} type={toast.type} />}
    </div>
  );
};

export default MessagesManagement;
