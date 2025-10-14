import { useState, useEffect } from 'react';
import './Hero.css';

const Hero = ({ slides = [] }) => {
  const [currentSlide, setCurrentSlide] = useState(0);

  useEffect(() => {
    if (slides.length === 0) return;

    const interval = setInterval(() => {
      setCurrentSlide(prev => (prev + 1) % slides.length);
    }, 5000);

    return () => clearInterval(interval);
  }, [slides.length]);

  const goToSlide = index => {
    setCurrentSlide(index);
  };

  const nextSlide = () => {
    setCurrentSlide(prev => (prev + 1) % slides.length);
  };

  const prevSlide = () => {
    setCurrentSlide(prev => (prev - 1 + slides.length) % slides.length);
  };

  if (slides.length === 0) {
    return (
      <section id="inicio" className="hero">
        <div className="hero-content">
          <h1>Bienvenido a Novusio</h1>
          <p>Soluciones Digitales Innovadoras</p>
        </div>
      </section>
    );
  }

  return (
    <section id="inicio" className="hero">
      <div className="hero-carousel">
        {slides.map((slide, index) => (
          <div
            key={slide.id}
            className={`hero-slide ${index === currentSlide ? 'active' : ''}`}
          >
            <div className="hero-overlay"></div>
            <img
              src={slide.image_url}
              alt={slide.title}
              className="hero-image"
            />
            <div className="hero-content">
              {slide?.title?.trim() && (
                <h1 className="hero-title">{slide.title}</h1>
              )}
              {slide?.subtitle?.trim() && (
                <p className="hero-subtitle">{slide.subtitle}</p>
              )}
            </div>
          </div>
        ))}
      </div>

      <button className="hero-nav hero-nav-prev" onClick={prevSlide}>
        ‹
      </button>
      <button className="hero-nav hero-nav-next" onClick={nextSlide}>
        ›
      </button>

      <div className="hero-dots">
        {slides.map((_, index) => (
          <button
            key={index}
            className={`hero-dot ${index === currentSlide ? 'active' : ''}`}
            onClick={() => goToSlide(index)}
          />
        ))}
      </div>
    </section>
  );
};

export default Hero;
