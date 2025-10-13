import { useState, useEffect } from 'react';
import api from '../../services/api';
import Navbar from '../../components/public/Navbar';
import Hero from '../../components/public/Hero';
import './HomePage.css';

const HomePage = () => {
  const [slides, setSlides] = useState([]);
  const [services, setServices] = useState([]);
  const [clients, setClients] = useState([]);
  const [companyInfo, setCompanyInfo] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadContent();
  }, []);

  const loadContent = async () => {
    try {
      const [slidesRes, servicesRes, portfolioRes, companyRes] =
        await Promise.all([
          api.get('/slides').catch(() => ({ data: [] })),
          api.get('/services').catch(() => ({ data: [] })),
          api.get('/portfolio').catch(() => ({ data: [] })),
          api.get('/company').catch(() => ({ data: {} })),
        ]);

      setSlides(slidesRes.data || []);
      setServices(servicesRes.data || []);
      setClients(portfolioRes.data || []);
      setCompanyInfo(companyRes.data || {});
    } catch (error) {
      console.error('Error loading content:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleContactSubmit = async e => {
    e.preventDefault();

    const formData = new FormData(e.target);
    const data = Object.fromEntries(formData);

    try {
      await api.post('/contact', data);
      alert('¡Mensaje enviado con éxito! Te contactaremos pronto.');
      e.target.reset();
    } catch (error) {
      console.error('Error al enviar mensaje:', error);
      alert('Error al enviar mensaje. Por favor, intenta nuevamente.');
    }
  };

  if (loading) {
    return (
      <div className="loading-page">
        <div className="spinner"></div>
      </div>
    );
  }

  return (
    <div className="home-page">
      <Navbar />
      <Hero slides={slides} />

      {/* Services Section */}
      <section id="servicios" className="services">
        <div className="container">
          <div className="section-header">
            <h2 className="section-title">Nuestras Soluciones</h2>
            <p className="section-subtitle">
              Ofrecemos soluciones tecnológicas completas para llevar tu negocio
              al siguiente nivel digital
            </p>
          </div>

          <div className="services-grid">
            {services.map(service => (
              <div key={service.id} className="service-card">
                <div className="service-icon">
                  <svg
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    dangerouslySetInnerHTML={{ __html: service.icon }}
                  />
                </div>
                <h3 className="service-title">{service.title}</h3>
                <p className="service-description">{service.description}</p>
                {service.features && service.features.length > 0 && (
                  <ul className="service-features">
                    {service.features.map((feature, idx) => (
                      <li key={`${service.id}-${idx}`}>{feature}</li>
                    ))}
                  </ul>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Portfolio Section */}
      <section id="portafolio" className="portfolio">
        <div className="container">
          <div className="section-header">
            <h2 className="section-title">Nuestros Clientes</h2>
            <p className="section-subtitle">
              Empresas que confían en nuestras soluciones digitales
            </p>
          </div>

          <div className="portfolio-grid">
            {clients.map(client => (
              <div key={client.id} className="portfolio-item">
                <img
                  src={client.logo_url}
                  alt={client.name}
                  className="portfolio-logo"
                  onError={e => (e.target.style.display = 'none')}
                />
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* About Section */}
      <section id="nosotros" className="about">
        <div className="container">
          <div className="about-content">
            <div className="about-text">
              <h2 className="section-title">Sobre Nosotros</h2>
              <p className="about-description">
                {companyInfo.about_text ||
                  'Somos una empresa especializada en soluciones digitales innovadoras.'}
              </p>
              <div className="about-details">
                <div className="about-item">
                  <h4>Nuestra Misión</h4>
                  <p>
                    Transformar negocios a través de soluciones digitales
                    innovadoras y accesibles.
                  </p>
                </div>
                <div className="about-item">
                  <h4>Nuestra Visión</h4>
                  <p>
                    Ser la empresa líder en América Latina en transformación
                    digital.
                  </p>
                </div>
              </div>
            </div>
            <div className="about-image">
              <img
                src="https://images.unsplash.com/photo-1709715357520-5e1047a2b691?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080"
                alt="Equipo Novusio"
                className="about-img"
              />
            </div>
          </div>

          <div className="values-section">
            <h3 className="values-title">Nuestros Valores</h3>
            <div className="values-grid">
              {['Innovación', 'Excelencia', 'Compromiso', 'Transparencia'].map(
                value => (
                  <div key={value} className="value-card">
                    <h4>{value}</h4>
                  </div>
                ),
              )}
            </div>
          </div>
        </div>
      </section>

      {/* Contact Section */}
      <section id="contacto" className="contact">
        <div className="container">
          <div className="section-header">
            <h2 className="section-title">Contáctanos</h2>
            <p className="section-subtitle">
              ¿Tienes un proyecto en mente? Hablemos
            </p>
          </div>

          <div className="contact-content">
            <div className="contact-info">
              <div className="contact-card">
                <div className="contact-icon">📧</div>
                <div className="contact-details">
                  <h4>Email</h4>
                  <p>{companyInfo.email || 'contacto@novusiopy.com'}</p>
                </div>
              </div>

              <div className="contact-card">
                <div className="contact-icon">📞</div>
                <div className="contact-details">
                  <h4>Teléfono</h4>
                  <p>{companyInfo.phone || '+595 981 234 567'}</p>
                </div>
              </div>

              <div className="contact-card">
                <div className="contact-icon">📍</div>
                <div className="contact-details">
                  <h4>Ubicación</h4>
                  <p>{companyInfo.location || 'Asunción, Paraguay'}</p>
                </div>
              </div>
            </div>

            <div className="contact-form-container">
              <form className="contact-form" onSubmit={handleContactSubmit}>
                <div className="form-row">
                  <div className="form-group">
                    <label htmlFor="name">Nombre</label>
                    <input
                      type="text"
                      id="name"
                      name="name"
                      placeholder="Tu nombre"
                      required
                    />
                  </div>
                  <div className="form-group">
                    <label htmlFor="email">Email</label>
                    <input
                      type="email"
                      id="email"
                      name="email"
                      placeholder="tu@email.com"
                      required
                    />
                  </div>
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label htmlFor="phone">Teléfono</label>
                    <input
                      type="tel"
                      id="phone"
                      name="phone"
                      placeholder="+595 981 234 567"
                    />
                  </div>
                  <div className="form-group">
                    <label htmlFor="company">Empresa</label>
                    <input
                      type="text"
                      id="company"
                      name="company"
                      placeholder="Tu empresa"
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label htmlFor="message">Mensaje</label>
                  <textarea
                    id="message"
                    name="message"
                    placeholder="Cuéntanos sobre tu proyecto..."
                    rows="6"
                    required
                  />
                </div>

                <button type="submit" className="submit-btn">
                  Enviar Mensaje
                </button>
              </form>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="footer">
        <div className="container">
          <div className="footer-content">
            <div className="footer-brand">
              <div className="footer-logo">
                <span className="footer-logo-text">N</span>
              </div>
              <span className="footer-company-name">NOVUSIO</span>
            </div>

            <div className="footer-links">
              <div className="footer-section">
                <h4>Servicios</h4>
                <ul>
                  <li>
                    <a href="#servicios">E-commerce</a>
                  </li>
                  <li>
                    <a href="#servicios">Integraciones</a>
                  </li>
                </ul>
              </div>

              <div className="footer-section">
                <h4>Empresa</h4>
                <ul>
                  <li>
                    <a href="#nosotros">Sobre Nosotros</a>
                  </li>
                  <li>
                    <a href="#portafolio">Portafolio</a>
                  </li>
                </ul>
              </div>

              <div className="footer-section">
                <h4>Soporte</h4>
                <ul>
                  <li>
                    <a href="#contacto">Contacto</a>
                  </li>
                  <li>
                    <a href="#contacto">FAQ</a>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          <div className="footer-bottom">
            <p className="footer-copyright">
              © 2025 Novusio Paraguay. Todos los derechos reservados.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default HomePage;
