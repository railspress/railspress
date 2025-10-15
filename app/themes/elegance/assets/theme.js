/**
 * Elegance Theme JavaScript
 * Premium theme with comprehensive customization options
 */

(function() {
  'use strict';

  // Theme initialization
  function initTheme() {
    initSmoothScrolling();
    initAnimations();
    initMobileMenu();
    initSearch();
    initTestimonials();
    initLazyLoading();
    initFormValidation();
  }

  // Smooth scrolling for anchor links
  function initSmoothScrolling() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
      anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
          target.scrollIntoView({
            behavior: 'smooth',
            block: 'start'
          });
        }
      });
    });
  }

  // Intersection Observer for animations
  function initAnimations() {
    const observerOptions = {
      threshold: 0.1,
      rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('animate-in');
        }
      });
    }, observerOptions);

    // Observe elements with animation classes
    document.querySelectorAll('.animate-on-scroll').forEach(el => {
      observer.observe(el);
    });
  }

  // Mobile menu functionality
  function initMobileMenu() {
    const mobileMenuToggle = document.querySelector('[data-mobile-menu-toggle]');
    const mobileMenu = document.querySelector('[data-mobile-menu]');
    const mobileMenuOverlay = document.querySelector('[data-mobile-menu-overlay]');

    if (mobileMenuToggle && mobileMenu) {
      mobileMenuToggle.addEventListener('click', () => {
        const isOpen = mobileMenu.classList.contains('is-open');
        
        if (isOpen) {
          closeMobileMenu();
        } else {
          openMobileMenu();
        }
      });

      // Close menu when clicking overlay
      if (mobileMenuOverlay) {
        mobileMenuOverlay.addEventListener('click', closeMobileMenu);
      }

      // Close menu when clicking on links
      mobileMenu.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', closeMobileMenu);
      });

      // Close menu on escape key
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && mobileMenu.classList.contains('is-open')) {
          closeMobileMenu();
        }
      });
    }

    function openMobileMenu() {
      mobileMenu.classList.add('is-open');
      document.body.classList.add('menu-open');
      mobileMenuToggle.setAttribute('aria-expanded', 'true');
    }

    function closeMobileMenu() {
      mobileMenu.classList.remove('is-open');
      document.body.classList.remove('menu-open');
      mobileMenuToggle.setAttribute('aria-expanded', 'false');
    }
  }

  // Search functionality
  function initSearch() {
    const searchToggle = document.querySelector('[data-search-toggle]');
    const searchModal = document.querySelector('[data-search-modal]');
    const searchInput = document.querySelector('[data-search-input]');
    const searchClose = document.querySelector('[data-search-close]');

    if (searchToggle && searchModal) {
      searchToggle.addEventListener('click', () => {
        openSearchModal();
      });

      if (searchClose) {
        searchClose.addEventListener('click', closeSearchModal);
      }

      // Close on escape key
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && searchModal.classList.contains('is-open')) {
          closeSearchModal();
        }
      });

      // Focus search input when opened
      if (searchInput) {
        searchToggle.addEventListener('click', () => {
          setTimeout(() => searchInput.focus(), 100);
        });
      }
    }

    function openSearchModal() {
      searchModal.classList.add('is-open');
      document.body.classList.add('search-open');
    }

    function closeSearchModal() {
      searchModal.classList.remove('is-open');
      document.body.classList.remove('search-open');
    }
  }

  // Testimonials carousel/slider
  function initTestimonials() {
    const testimonialContainers = document.querySelectorAll('[data-testimonials-carousel]');
    
    testimonialContainers.forEach(container => {
      const slides = container.querySelectorAll('.testimonial-item');
      const prevBtn = container.querySelector('[data-testimonial-prev]');
      const nextBtn = container.querySelector('[data-testimonial-next]');
      const indicators = container.querySelectorAll('[data-testimonial-indicator]');
      
      let currentSlide = 0;
      const totalSlides = slides.length;

      if (totalSlides <= 1) return;

      function showSlide(index) {
        slides.forEach((slide, i) => {
          slide.classList.toggle('active', i === index);
        });

        indicators.forEach((indicator, i) => {
          indicator.classList.toggle('active', i === index);
        });

        currentSlide = index;
      }

      function nextSlide() {
        const next = (currentSlide + 1) % totalSlides;
        showSlide(next);
      }

      function prevSlide() {
        const prev = (currentSlide - 1 + totalSlides) % totalSlides;
        showSlide(prev);
      }

      // Button event listeners
      if (nextBtn) {
        nextBtn.addEventListener('click', nextSlide);
      }

      if (prevBtn) {
        prevBtn.addEventListener('click', prevSlide);
      }

      // Indicator event listeners
      indicators.forEach((indicator, index) => {
        indicator.addEventListener('click', () => showSlide(index));
      });

      // Auto-play
      const autoPlay = container.dataset.autoplay === 'true';
      if (autoPlay) {
        setInterval(nextSlide, 5000); // Change slide every 5 seconds
      }

      // Initialize first slide
      showSlide(0);
    });
  }

  // Lazy loading for images
  function initLazyLoading() {
    const images = document.querySelectorAll('img[data-src]');
    
    if ('IntersectionObserver' in window) {
      const imageObserver = new IntersectionObserver((entries, observer) => {
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
    } else {
      // Fallback for older browsers
      images.forEach(img => {
        img.src = img.dataset.src;
        img.classList.remove('lazy');
      });
    }
  }

  // Form validation
  function initFormValidation() {
    const forms = document.querySelectorAll('form[data-validate]');
    
    forms.forEach(form => {
      form.addEventListener('submit', (e) => {
        if (!validateForm(form)) {
          e.preventDefault();
        }
      });

      // Real-time validation
      const inputs = form.querySelectorAll('input, textarea, select');
      inputs.forEach(input => {
        input.addEventListener('blur', () => validateField(input));
        input.addEventListener('input', () => clearFieldError(input));
      });
    });

    function validateForm(form) {
      let isValid = true;
      const inputs = form.querySelectorAll('input[required], textarea[required], select[required]');
      
      inputs.forEach(input => {
        if (!validateField(input)) {
          isValid = false;
        }
      });

      return isValid;
    }

    function validateField(field) {
      const value = field.value.trim();
      const type = field.type;
      let isValid = true;
      let errorMessage = '';

      // Required field validation
      if (field.hasAttribute('required') && !value) {
        isValid = false;
        errorMessage = 'This field is required.';
      }

      // Email validation
      if (type === 'email' && value) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(value)) {
          isValid = false;
          errorMessage = 'Please enter a valid email address.';
        }
      }

      // Phone validation
      if (type === 'tel' && value) {
        const phoneRegex = /^[\+]?[1-9][\d]{0,15}$/;
        if (!phoneRegex.test(value.replace(/\s/g, ''))) {
          isValid = false;
          errorMessage = 'Please enter a valid phone number.';
        }
      }

      // Min length validation
      const minLength = field.getAttribute('minlength');
      if (minLength && value.length < parseInt(minLength)) {
        isValid = false;
        errorMessage = `Minimum length is ${minLength} characters.`;
      }

      // Show/hide error
      if (isValid) {
        clearFieldError(field);
      } else {
        showFieldError(field, errorMessage);
      }

      return isValid;
    }

    function showFieldError(field, message) {
      clearFieldError(field);
      
      field.classList.add('error');
      
      const errorDiv = document.createElement('div');
      errorDiv.className = 'field-error';
      errorDiv.textContent = message;
      
      field.parentNode.appendChild(errorDiv);
    }

    function clearFieldError(field) {
      field.classList.remove('error');
      
      const existingError = field.parentNode.querySelector('.field-error');
      if (existingError) {
        existingError.remove();
      }
    }
  }

  // Utility functions
  function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }

  function throttle(func, limit) {
    let inThrottle;
    return function() {
      const args = arguments;
      const context = this;
      if (!inThrottle) {
        func.apply(context, args);
        inThrottle = true;
        setTimeout(() => inThrottle = false, limit);
      }
    };
  }

  // Header scroll effect
  function initHeaderScroll() {
    const header = document.querySelector('.header');
    if (!header) return;

    const handleScroll = throttle(() => {
      if (window.scrollY > 100) {
        header.classList.add('scrolled');
      } else {
        header.classList.remove('scrolled');
      }
    }, 100);

    window.addEventListener('scroll', handleScroll);
  }

  // Back to top button
  function initBackToTop() {
    const backToTopBtn = document.querySelector('[data-back-to-top]');
    if (!backToTopBtn) return;

    const handleScroll = throttle(() => {
      if (window.scrollY > 300) {
        backToTopBtn.classList.add('visible');
      } else {
        backToTopBtn.classList.remove('visible');
      }
    }, 100);

    window.addEventListener('scroll', handleScroll);

    backToTopBtn.addEventListener('click', () => {
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    });
  }

  // Initialize everything when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      initTheme();
      initHeaderScroll();
      initBackToTop();
    });
  } else {
    initTheme();
    initHeaderScroll();
    initBackToTop();
  }

  // Expose utilities globally if needed
  window.EleganceTheme = {
    debounce,
    throttle
  };

})();

