import { useState, useEffect } from 'react';
import api, { uploadFile } from '../../services/api';
import Modal from '../../components/Modal';
import Toast from '../../components/Toast';
import './Management.css';

const SlidesManagement = () => {
  const [slides, setSlides] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingSlide, setEditingSlide] = useState(null);
  const [toast, setToast] = useState(null);

  useEffect(() => {
    loadSlides();
  }, []);

  const loadSlides = async () => {
    try {
      const response = await api.get('/slides');
      setSlides(response.data || []);
    } catch (error) {
      showToastMessage('Error al cargar slides', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async formData => {
    try {
      if (editingSlide) {
        await uploadFile(`/slides/${editingSlide.id}`, formData, 'PUT');
        showToastMessage('¡Slide actualizado con éxito!', 'success');
      } else {
        await uploadFile('/slides', formData, 'POST');
        showToastMessage('¡Slide creado con éxito!', 'success');
      }
      setShowModal(false);
      loadSlides();
    } catch (error) {
      console.error('Error al guardar slide:', error);
      showToastMessage(error.message || 'Error al guardar slide', 'error');
    }
  };

  const handleDelete = async id => {
    if (!window.confirm('¿Está seguro de que desea eliminar este slide?'))
      return;

    try {
      await api.delete(`/slides/${id}`);
      showToastMessage('¡Slide eliminado con éxito!', 'success');
      loadSlides();
    } catch (error) {
      showToastMessage('Error al eliminar slide', 'error');
    }
  };

  const showToastMessage = (message, type) => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const openModal = (slide = null) => {
    setEditingSlide(slide);
    setShowModal(true);
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
        <button className="btn btn-primary" onClick={() => openModal()}>
          + Agregar Slide
        </button>
      </div>

      <div className="data-grid">
        {slides.length === 0 ? (
          <p className="empty-message">Ningún slide registrado</p>
        ) : (
          slides.map(slide => (
            <div key={slide.id} className="data-card">
              <img
                src={slide.image_url}
                alt={slide.title}
                className="card-image"
                onError={e =>
                  (e.target.src =
                    'https://via.placeholder.com/300x150?text=Sin+Imagen')
                }
              />
              <h3>{slide.title}</h3>
              <p>{slide.subtitle}</p>
              <div className="card-actions">
                <button
                  className="btn btn-sm btn-outline"
                  onClick={() => openModal(slide)}
                >
                  Editar
                </button>
                <button
                  className="btn btn-sm btn-danger"
                  onClick={() => handleDelete(slide.id)}
                >
                  Eliminar
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {showModal && (
        <SlideModal
          slide={editingSlide}
          onClose={() => setShowModal(false)}
          onSubmit={handleSubmit}
        />
      )}

      {toast && <Toast message={toast.message} type={toast.type} />}
    </div>
  );
};

const SlideModal = ({ slide, onClose, onSubmit }) => {
  const [formData, setFormData] = useState({
    title: slide?.title || '',
    subtitle: slide?.subtitle || '',
    order_position: slide?.order_position || 0,
    active: slide?.active !== 0,
  });
  const [imageFile, setImageFile] = useState(null);
  const [preview, setPreview] = useState(slide?.image_url || '');

  const handleImageChange = e => {
    const file = e.target.files?.[0];
    if (file) {
      setImageFile(file);
      const reader = new FileReader();
      reader.onload = e => setPreview(e.target?.result);
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = e => {
    e.preventDefault();

    const data = new FormData();
    data.append('title', formData.title);
    data.append('subtitle', formData.subtitle);
    data.append('order_position', formData.order_position);
    data.append('active', formData.active ? 1 : 0);

    if (imageFile) {
      data.append('image', imageFile);
    }

    onSubmit(data);
  };

  return (
    <Modal title={slide ? 'Editar Slide' : 'Agregar Slide'} onClose={onClose}>
      <form onSubmit={handleSubmit} className="modal-form">
        <div className="form-group">
          <label>Título</label>
          <input
            type="text"
            value={formData.title}
            onChange={e => setFormData({ ...formData, title: e.target.value })}
            placeholder="Opcional"
          />
        </div>

        <div className="form-group">
          <label>Subtítulo</label>
          <input
            type="text"
            value={formData.subtitle}
            onChange={e =>
              setFormData({ ...formData, subtitle: e.target.value })
            }
            placeholder="Opcional"
          />
        </div>

        <div className="form-group">
          <label>Imagen</label>
          <input type="file" accept="image/*" onChange={handleImageChange} />
          {preview && (
            <img src={preview} alt="Preview" className="image-preview" />
          )}
        </div>

        <div className="form-group">
          <label>Orden</label>
          <input
            type="number"
            value={formData.order_position}
            onChange={e =>
              setFormData({ ...formData, order_position: e.target.value })
            }
          />
        </div>

        <div className="form-group">
          <label>
            <input
              type="checkbox"
              checked={formData.active}
              onChange={e =>
                setFormData({ ...formData, active: e.target.checked })
              }
            />
            Activo
          </label>
        </div>

        <div className="modal-footer">
          <button type="button" className="btn btn-outline" onClick={onClose}>
            Cancelar
          </button>
          <button type="submit" className="btn btn-primary">
            {slide ? 'Actualizar' : 'Crear'}
          </button>
        </div>
      </form>
    </Modal>
  );
};

export default SlidesManagement;
