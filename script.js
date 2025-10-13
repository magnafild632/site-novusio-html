// Mobile Menu Toggle
document.addEventListener('DOMContentLoaded', function () {
  const mobileMenuBtn = document.getElementById('mobileMenuBtn');
  const navMenu = document.getElementById('navMenu');

  if (mobileMenuBtn && navMenu) {
    mobileMenuBtn.addEventListener('click', function () {
      mobileMenuBtn.classList.toggle('active');
      navMenu.classList.toggle('active');
    });

    // Close mobile menu when clicking on a link
    const navLinks = navMenu.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
      link.addEventListener('click', function () {
        mobileMenuBtn.classList.remove('active');
        navMenu.classList.remove('active');
      });
    });
  }
});

// Hero Carousel
class HeroCarousel {
  constructor() {
    this.slides = document.querySelectorAll('.hero-slide');
    this.dots = document.querySelectorAll('.hero-dot');
    this.prevBtn = document.getElementById('prevSlide');
    this.nextBtn = document.getElementById('nextSlide');
    this.currentSlide = 0;
    this.autoPlayInterval = null;

    this.init();
  }

  init() {
    if (this.slides.length === 0) return;

    // Event listeners
    if (this.prevBtn) {
      this.prevBtn.addEventListener('click', () => this.prevSlide());
    }

    if (this.nextBtn) {
      this.nextBtn.addEventListener('click', () => this.nextSlide());
    }

    // Dot navigation
    this.dots.forEach((dot, index) => {
      dot.addEventListener('click', () => this.goToSlide(index));
    });

    // Auto-play
    this.startAutoPlay();

    // Pause on hover
    const heroSection = document.querySelector('.hero');
    if (heroSection) {
      heroSection.addEventListener('mouseenter', () => this.stopAutoPlay());
      heroSection.addEventListener('mouseleave', () => this.startAutoPlay());
    }

    // Keyboard navigation
    document.addEventListener('keydown', e => {
      if (e.key === 'ArrowLeft') {
        this.prevSlide();
      } else if (e.key === 'ArrowRight') {
        this.nextSlide();
      }
    });
  }

  showSlide(index) {
    // Remove active class from all slides and dots
    this.slides.forEach(slide => slide.classList.remove('active'));
    this.dots.forEach(dot => dot.classList.remove('active'));

    // Add active class to current slide and dot
    if (this.slides[index]) {
      this.slides[index].classList.add('active');
    }
    if (this.dots[index]) {
      this.dots[index].classList.add('active');
    }

    this.currentSlide = index;
  }

  nextSlide() {
    const nextIndex = (this.currentSlide + 1) % this.slides.length;
    this.showSlide(nextIndex);
  }

  prevSlide() {
    const prevIndex =
      (this.currentSlide - 1 + this.slides.length) % this.slides.length;
    this.showSlide(prevIndex);
  }

  goToSlide(index) {
    this.showSlide(index);
  }

  startAutoPlay() {
    this.stopAutoPlay();
    this.autoPlayInterval = setInterval(() => {
      this.nextSlide();
    }, 5000);
  }

  stopAutoPlay() {
    if (this.autoPlayInterval) {
      clearInterval(this.autoPlayInterval);
      this.autoPlayInterval = null;
    }
  }
}

// Smooth Scrolling for Navigation Links
function initSmoothScrolling() {
  const navLinks = document.querySelectorAll('a[href^="#"]');

  navLinks.forEach(link => {
    link.addEventListener('click', function (e) {
      e.preventDefault();

      const targetId = this.getAttribute('href');
      const targetElement = document.querySelector(targetId);

      if (targetElement) {
        const offsetTop = targetElement.offsetTop - 80; // Account for fixed navbar

        window.scrollTo({
          top: offsetTop,
          behavior: 'smooth',
        });
      }
    });
  });
}

// Contact Form Handler
function initContactForm() {
  const contactForm = document.getElementById('contactForm');

  if (contactForm) {
    contactForm.addEventListener('submit', async function (e) {
      e.preventDefault();

      // Get form data
      const formData = new FormData(this);
      const data = Object.fromEntries(formData);

      // Basic validation
      if (!data.name || !data.email || !data.message) {
        alert('Por favor, completa todos los campos obligatorios.');
        return;
      }

      // Email validation
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(data.email)) {
        alert('Por favor, ingresa un email válido.');
        return;
      }

      // Submit to API
      const submitBtn = this.querySelector('.submit-btn');
      const originalText = submitBtn.innerHTML;

      submitBtn.innerHTML = 'Enviando...';
      submitBtn.disabled = true;

      try {
        const response = await fetch('/api/contact', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(data),
        });

        const result = await response.json();

        if (result.success) {
          alert('¡Mensaje enviado con éxito! Te contactaremos pronto.');
          this.reset();
        } else {
          alert('Error al enviar mensaje. Por favor, intenta nuevamente.');
        }
      } catch (error) {
        console.error('Error:', error);
        alert('Error al enviar mensaje. Por favor, intenta nuevamente.');
      } finally {
        submitBtn.innerHTML = originalText;
        submitBtn.disabled = false;
      }
    });
  }
}

// Scroll Animations
function initScrollAnimations() {
  const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px',
  };

  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('fade-in');
      }
    });
  }, observerOptions);

  // Observe elements for animation
  const animateElements = document.querySelectorAll(
    '.service-card, .portfolio-item, .value-card, .contact-card',
  );
  animateElements.forEach(el => {
    observer.observe(el);
  });
}

// Navbar Background on Scroll
function initNavbarScroll() {
  const navbar = document.querySelector('.navbar');

  if (navbar) {
    window.addEventListener('scroll', function () {
      if (window.scrollY > 100) {
        navbar.style.backgroundColor = 'rgba(255, 255, 255, 0.98)';
        navbar.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.1)';
      } else {
        navbar.style.backgroundColor = 'rgba(255, 255, 255, 0.95)';
        navbar.style.boxShadow = '0 1px 3px 0 rgba(0, 0, 0, 0.1)';
      }
    });
  }
}

// Active Navigation Link
function initActiveNavigation() {
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-link');

  function updateActiveLink() {
    const scrollPos = window.scrollY + 100;

    sections.forEach(section => {
      const sectionTop = section.offsetTop;
      const sectionHeight = section.offsetHeight;
      const sectionId = section.getAttribute('id');

      if (scrollPos >= sectionTop && scrollPos < sectionTop + sectionHeight) {
        navLinks.forEach(link => {
          link.classList.remove('active');
          if (link.getAttribute('href') === `#${sectionId}`) {
            link.classList.add('active');
          }
        });
      }
    });
  }

  window.addEventListener('scroll', updateActiveLink);
  window.addEventListener('load', updateActiveLink);
}

// Image Lazy Loading
function initLazyLoading() {
  const images = document.querySelectorAll('img[data-src]');

  const imageObserver = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const img = entry.target;
        img.src = img.dataset.src;
        img.classList.remove('lazy');
        imageObserver.unobserve(img);
      }
    });
  });

  images.forEach(img => imageObserver.observe(img));
}

// Portfolio Filter (if needed in the future)
function initPortfolioFilter() {
  // This can be expanded if portfolio filtering is needed
  const portfolioItems = document.querySelectorAll('.portfolio-item');

  portfolioItems.forEach(item => {
    item.addEventListener('click', function () {
      // Add click effect or modal functionality here
      this.style.transform = 'scale(0.95)';
      setTimeout(() => {
        this.style.transform = 'scale(1)';
      }, 150);
    });
  });
}

// Service Cards Hover Effect
function initServiceCards() {
  const serviceCards = document.querySelectorAll('.service-card');

  serviceCards.forEach(card => {
    card.addEventListener('mouseenter', function () {
      this.style.transform = 'translateY(-8px)';
    });

    card.addEventListener('mouseleave', function () {
      this.style.transform = 'translateY(0)';
    });
  });
}

// Error Handling for Images
function initImageErrorHandling() {
  const images = document.querySelectorAll('img');

  images.forEach(img => {
    img.addEventListener('error', function () {
      // Replace with placeholder image or hide
      this.style.display = 'none';
      console.warn('Failed to load image:', this.src);
    });
  });
}

// Performance Optimization
function initPerformanceOptimizations() {
  // Debounce scroll events
  let scrollTimeout;
  window.addEventListener('scroll', function () {
    if (scrollTimeout) {
      clearTimeout(scrollTimeout);
    }
    scrollTimeout = setTimeout(function () {
      // Scroll-dependent functions here
    }, 10);
  });

  // Preload critical images
  const criticalImages = [
    'https://images.unsplash.com/photo-1531746790731-6c087fecd65a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaGF0Ym90JTIwYXJ0aWZpY2lhbCUyMGludGVsbGlnZW5jZXxlbnwxfHx8fDE3NTk5NDg5OTd8MA&ixlib=rb-4.1.0&q=80&w=1080',
  ];

  criticalImages.forEach(src => {
    const link = document.createElement('link');
    link.rel = 'preload';
    link.as = 'image';
    link.href = src;
    document.head.appendChild(link);
  });
}

// Load dynamic content from API
async function loadDynamicContent() {
  try {
    // Load hero slides
    const slidesResponse = await fetch('/api/slides');
    const slidesData = await slidesResponse.json();

    if (slidesData.success && slidesData.data.length > 0) {
      updateHeroSlides(slidesData.data);
    }

    // Load services
    const servicesResponse = await fetch('/api/services');
    const servicesData = await servicesResponse.json();

    if (servicesData.success && servicesData.data.length > 0) {
      updateServices(servicesData.data);
    }

    // Load portfolio clients
    const portfolioResponse = await fetch('/api/portfolio');
    const portfolioData = await portfolioResponse.json();

    if (portfolioData.success && portfolioData.data.length > 0) {
      updatePortfolio(portfolioData.data);
    }

    // Load company info
    const companyResponse = await fetch('/api/company');
    const companyData = await companyResponse.json();

    if (companyData.success) {
      updateCompanyInfo(companyData.data);
    }
  } catch (error) {
    console.error('Error loading dynamic content:', error);
    // Continue with static content if API fails
  }
}

function updateHeroSlides(slides) {
  // Implementation would update the hero carousel with new slides
  console.log('Dynamic slides loaded:', slides.length);
}

function updateServices(services) {
  // Implementation would update services section
  console.log('Dynamic services loaded:', services.length);
}

function updatePortfolio(clients) {
  // Implementation would update portfolio section
  console.log('Dynamic portfolio loaded:', clients.length);
}

function updateCompanyInfo(info) {
  // Implementation would update company information
  console.log('Company info loaded');
}

// Initialize all functionality
document.addEventListener('DOMContentLoaded', function () {
  // Load dynamic content first
  loadDynamicContent();

  // Initialize all components
  const heroCarousel = new HeroCarousel();
  window.heroCarousel = heroCarousel; // Make it globally accessible

  initSmoothScrolling();
  initContactForm();
  initScrollAnimations();
  initNavbarScroll();
  initActiveNavigation();
  initLazyLoading();
  initPortfolioFilter();
  initServiceCards();
  initImageErrorHandling();
  initPerformanceOptimizations();

  console.log('Novusio website initialized successfully!');
});

// Handle page visibility changes
document.addEventListener('visibilitychange', function () {
  const heroCarousel = window.heroCarousel;
  if (document.hidden) {
    if (heroCarousel && heroCarousel.stopAutoPlay) {
      heroCarousel.stopAutoPlay();
    }
  } else {
    if (heroCarousel && heroCarousel.startAutoPlay) {
      heroCarousel.startAutoPlay();
    }
  }
});

// Export for potential module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    HeroCarousel,
    initSmoothScrolling,
    initContactForm,
    initScrollAnimations,
  };
}
