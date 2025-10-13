import { useState } from 'react';
import './IconPicker.css';

const PREDEFINED_ICONS = [
  {
    name: 'Mensaje/Chat',
    path: '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>',
  },
  {
    name: 'Código',
    path: '<polyline points="16,18 22,12 16,6"></polyline><polyline points="8,6 2,12 8,18"></polyline>',
  },
  {
    name: 'Escudo/Seguridad',
    path: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>',
  },
  {
    name: 'Globo/Web',
    path: '<circle cx="12" cy="12" r="10"></circle><line x1="2" y1="12" x2="22" y2="12"></line><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>',
  },
  {
    name: 'Smartphone',
    path: '<rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect><line x1="12" y1="18" x2="12.01" y2="18"></line>',
  },
  {
    name: 'Monitor/PC',
    path: '<rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect><line x1="8" y1="21" x2="16" y2="21"></line><line x1="12" y1="17" x2="12" y2="21"></line>',
  },
  {
    name: 'Email',
    path: '<path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path><polyline points="22,6 12,13 2,6"></polyline>',
  },
  {
    name: 'Teléfono',
    path: '<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path>',
  },
  {
    name: 'Carrito/Compras',
    path: '<circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>',
  },
  {
    name: 'Configuración',
    path: '<circle cx="12" cy="12" r="3"></circle><path d="M12 1v6m0 6v6M1 12h6m6 0h6"></path>',
  },
  {
    name: 'Usuario/Persona',
    path: '<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle>',
  },
  {
    name: 'Estrella',
    path: '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>',
  },
  {
    name: 'Corazón',
    path: '<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>',
  },
  {
    name: 'Check/Verificado',
    path: '<polyline points="20 6 9 17 4 12"></polyline>',
  },
  {
    name: 'Ubicación/Pin',
    path: '<path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path><circle cx="12" cy="10" r="3"></circle>',
  },
  {
    name: 'Reloj/Tiempo',
    path: '<circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline>',
  },
  {
    name: 'Búsqueda/Lupa',
    path: '<circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line>',
  },
  {
    name: 'Gráfico/Stats',
    path: '<line x1="12" y1="20" x2="12" y2="10"></line><line x1="18" y1="20" x2="18" y2="4"></line><line x1="6" y1="20" x2="6" y2="16"></line>',
  },
  {
    name: 'Nube/Cloud',
    path: '<path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"></path>',
  },
  {
    name: 'Cohete/Rocket',
    path: '<path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09z"></path><path d="m12 15-3-3a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.35 22.35 0 0 1-4 2z"></path>',
  },
  {
    name: 'Base de Datos',
    path: '<ellipse cx="12" cy="5" rx="9" ry="3"></ellipse><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"></path><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"></path>',
  },
];

const IconPicker = ({ value, onChange }) => {
  const [showPicker, setShowPicker] = useState(false);

  const selectIcon = icon => {
    onChange(icon.path);
    setShowPicker(false);
  };

  return (
    <div className="icon-picker">
      <div className="icon-picker-header">
        <label htmlFor="iconInput">SVG del Ícono</label>
        <button
          type="button"
          className="btn btn-sm btn-outline"
          onClick={() => setShowPicker(!showPicker)}
        >
          {showPicker ? 'Ocultar' : 'Ver'} Íconos Predefinidos
        </button>
      </div>

      {showPicker && (
        <div className="icon-picker-grid">
          {PREDEFINED_ICONS.map((icon, idx) => (
            <div
              key={idx}
              className={`icon-option ${value === icon.path ? 'selected' : ''}`}
              onClick={() => selectIcon(icon)}
              title={icon.name}
            >
              <svg
                width="32"
                height="32"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                dangerouslySetInnerHTML={{ __html: icon.path }}
              />
              <span>{icon.name}</span>
            </div>
          ))}
        </div>
      )}

      <textarea
        id="iconInput"
        value={value}
        onChange={e => onChange(e.target.value)}
        placeholder="Seleccione un ícono arriba o pegue su SVG path aquí"
        rows={3}
        required
      />
    </div>
  );
};

export default IconPicker;
