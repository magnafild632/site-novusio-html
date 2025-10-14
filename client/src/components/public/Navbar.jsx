import { useState } from 'react';
import './Navbar.css';

const Navbar = () => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const scrollToSection = sectionId => {
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth', block: 'start' });
      setMobileMenuOpen(false);
    }
  };

  return (
    <nav className="navbar">
      <div className="nav-container">
        <div className="nav-brand">
          <div className="logo">
            <img src="/uploads/logo.svg" alt="Logo" className="logo-img" />
          </div>
          <span className="company-name">NOVUSIO</span>
        </div>

        <div className={`nav-menu ${mobileMenuOpen ? 'active' : ''}`}>
          <a
            href="#inicio"
            className="nav-link"
            onClick={e => {
              e.preventDefault();
              scrollToSection('inicio');
            }}
          >
            Inicio
          </a>
          <a
            href="#servicios"
            className="nav-link"
            onClick={e => {
              e.preventDefault();
              scrollToSection('servicios');
            }}
          >
            Servicios
          </a>
          <a
            href="#portafolio"
            className="nav-link"
            onClick={e => {
              e.preventDefault();
              scrollToSection('portafolio');
            }}
          >
            Portafolio
          </a>
          <a
            href="#nosotros"
            className="nav-link"
            onClick={e => {
              e.preventDefault();
              scrollToSection('nosotros');
            }}
          >
            Nosotros
          </a>
          <a
            href="#contacto"
            className="nav-link"
            onClick={e => {
              e.preventDefault();
              scrollToSection('contacto');
            }}
          >
            Contacto
          </a>
        </div>

        <button
          className={`mobile-menu-btn ${mobileMenuOpen ? 'active' : ''}`}
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
        >
          <span className="hamburger"></span>
          <span className="hamburger"></span>
          <span className="hamburger"></span>
        </button>
      </div>
    </nav>
  );
};

export default Navbar;
