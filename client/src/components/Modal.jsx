import { useEffect } from 'react';
import './Modal.css';

const Modal = ({ title, children, onClose }) => {
  useEffect(() => {
    const handleEscape = e => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [onClose]);

  return (
    <div
      className="modal"
      onMouseDown={e => {
        // Fecha apenas se o clique for diretamente no backdrop
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div className="modal-content" onMouseDown={e => e.stopPropagation()}>
        <div className="modal-header">
          <h2>{title}</h2>
          <button className="close-modal" onClick={onClose}>
            ×
          </button>
        </div>
        <div className="modal-body">{children}</div>
      </div>
    </div>
  );
};

export default Modal;
