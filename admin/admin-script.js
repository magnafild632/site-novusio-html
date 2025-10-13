// API Configuration
const API_BASE_URL = window.location.origin + '/api';
let authToken = localStorage.getItem('admin_token');
let currentUser = JSON.parse(localStorage.getItem('admin_user') || '{}');

// API Helper Functions
const api = {
  async request(endpoint, options = {}) {
    const defaultOptions = {
      headers: {
        'Content-Type': 'application/json',
      },
    };

    if (authToken) {
      defaultOptions.headers['Authorization'] = `Bearer ${authToken}`;
    }

    const config = {
      ...defaultOptions,
      ...options,
      headers: {
        ...defaultOptions.headers,
        ...options.headers,
      },
    };

    const response = await fetch(`${API_BASE_URL}${endpoint}`, config);
    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Erro na requisição');
    }

    return data;
  },

  async get(endpoint) {
    return this.request(endpoint, { method: 'GET' });
  },

  async post(endpoint, body) {
    return this.request(endpoint, {
      method: 'POST',
      body: JSON.stringify(body),
    });
  },

  async put(endpoint, body) {
    return this.request(endpoint, {
      method: 'PUT',
      body: JSON.stringify(body),
    });
  },

  async delete(endpoint) {
    return this.request(endpoint, { method: 'DELETE' });
  },

  async upload(endpoint, formData) {
    const defaultOptions = {
      headers: {},
    };

    if (authToken) {
      defaultOptions.headers['Authorization'] = `Bearer ${authToken}`;
    }

    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      method: 'POST',
      headers: defaultOptions.headers,
      body: formData,
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Erro no upload');
    }

    return data;
  },
};

// Toast Notifications
function showToast(message, type = 'info') {
  const container = document.getElementById('toastContainer');
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.textContent = message;

  container.appendChild(toast);

  setTimeout(() => {
    toast.style.animation = 'slideOut 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}

// Modal Functions
function openModal(title, content) {
  const modal = document.getElementById('modalContainer');
  const modalTitle = document.getElementById('modalTitle');
  const modalBody = document.getElementById('modalBody');

  modalTitle.textContent = title;
  modalBody.innerHTML = content;
  modal.style.display = 'flex';
}

function closeModal() {
  const modal = document.getElementById('modalContainer');
  modal.style.display = 'none';
}

// Click outside modal to close
document.addEventListener('click', e => {
  const modal = document.getElementById('modalContainer');
  if (e.target === modal) {
    closeModal();
  }
});

// Navigation
function navigateToSection(sectionName) {
  // Update active nav item
  document.querySelectorAll('.nav-item').forEach(item => {
    item.classList.remove('active');
    if (item.dataset.section === sectionName) {
      item.classList.add('active');
    }
  });

  // Update active content section
  document.querySelectorAll('.content-section').forEach(section => {
    section.classList.remove('active');
  });

  const section = document.getElementById(`${sectionName}Section`);
  if (section) {
    section.classList.add('active');
  }

  // Update page title
  const titles = {
    dashboard: 'Dashboard',
    slides: 'Gerenciar Slides',
    services: 'Gerenciar Serviços',
    portfolio: 'Gerenciar Portfólio',
    messages: 'Mensagens de Contato',
    company: 'Informações da Empresa',
  };

  document.getElementById('pageTitle').textContent =
    titles[sectionName] || sectionName;

  // Load section data
  loadSectionData(sectionName);
}

// Load section data based on current section
function loadSectionData(sectionName) {
  switch (sectionName) {
    case 'dashboard':
      loadDashboardStats();
      break;
    case 'slides':
      loadSlides();
      break;
    case 'services':
      loadServices();
      break;
    case 'portfolio':
      loadPortfolio();
      break;
    case 'messages':
      loadMessages();
      break;
    case 'company':
      loadCompanyInfo();
      break;
  }
}

// Login
document.getElementById('loginForm')?.addEventListener('submit', async e => {
  e.preventDefault();

  const email = document.getElementById('loginEmail').value;
  const password = document.getElementById('loginPassword').value;
  const errorDiv = document.getElementById('loginError');

  try {
    const response = await api.post('/auth/login', { email, password });

    authToken = response.token;
    currentUser = response.user;

    localStorage.setItem('admin_token', authToken);
    localStorage.setItem('admin_user', JSON.stringify(currentUser));

    document.getElementById('loginScreen').style.display = 'none';
    document.getElementById('adminDashboard').style.display = 'flex';
    document.getElementById('userName').textContent = currentUser.name;

    showToast('Login realizado com sucesso!', 'success');
    loadDashboardStats();
    checkUnreadMessages();
  } catch (error) {
    errorDiv.textContent = error.message;
    errorDiv.style.display = 'block';
  }
});

// Logout
document.getElementById('logoutBtn')?.addEventListener('click', () => {
  localStorage.removeItem('admin_token');
  localStorage.removeItem('admin_user');
  authToken = null;
  currentUser = {};

  document.getElementById('adminDashboard').style.display = 'none';
  document.getElementById('loginScreen').style.display = 'flex';

  showToast('Logout realizado com sucesso!', 'info');
});

// Check authentication on load
window.addEventListener('DOMContentLoaded', () => {
  if (authToken) {
    document.getElementById('loginScreen').style.display = 'none';
    document.getElementById('adminDashboard').style.display = 'flex';
    document.getElementById('userName').textContent =
      currentUser.name || 'Administrador';
    loadDashboardStats();
    checkUnreadMessages();
  }

  // Setup navigation
  document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', e => {
      e.preventDefault();
      navigateToSection(item.dataset.section);
    });
  });
});

// Dashboard Stats
async function loadDashboardStats() {
  try {
    const [slides, services, portfolio, messages] = await Promise.all([
      api.get('/slides'),
      api.get('/services'),
      api.get('/portfolio'),
      api.get('/contact'),
    ]);

    document.getElementById('statsSlides').textContent =
      slides.data?.length || 0;
    document.getElementById('statsServices').textContent =
      services.data?.length || 0;
    document.getElementById('statsClients').textContent =
      portfolio.data?.length || 0;
    document.getElementById('statsMessages').textContent =
      messages.data?.length || 0;
  } catch (error) {
    console.error('Erro ao carregar estatísticas:', error);
  }
}

// Check unread messages
async function checkUnreadMessages() {
  try {
    const response = await api.get('/contact/stats/unread');
    const count = response.data.unread_count;

    const badge = document.getElementById('unreadBadge');
    if (count > 0) {
      badge.textContent = count;
      badge.style.display = 'block';
    } else {
      badge.style.display = 'none';
    }
  } catch (error) {
    console.error('Erro ao verificar mensagens não lidas:', error);
  }
}

// ===== SLIDES MANAGEMENT =====
async function loadSlides() {
  try {
    const response = await api.get('/slides');
    const slides = response.data || [];

    const container = document.getElementById('slidesContent');
    container.innerHTML = '';

    if (slides.length === 0) {
      container.innerHTML =
        '<p style="grid-column: 1/-1; text-align: center; color: var(--text-secondary);">Nenhum slide cadastrado</p>';
      return;
    }

    slides.forEach(slide => {
      const card = createSlideCard(slide);
      container.appendChild(card);
    });
  } catch (error) {
    showToast('Erro ao carregar slides: ' + error.message, 'error');
  }
}

function createSlideCard(slide) {
  const card = document.createElement('div');
  card.className = 'data-card';

  card.innerHTML = `
    <img src="${slide.image_url}" alt="${slide.title}" class="data-card-image" onerror="this.src='https://via.placeholder.com/300x150?text=Sem+Imagem'">
    <h3 class="data-card-title">${slide.title}</h3>
    <p class="data-card-subtitle">${slide.subtitle}</p>
    <div class="data-card-actions">
      <button class="btn btn-sm btn-outline" onclick="editSlide(${slide.id})">Editar</button>
      <button class="btn btn-sm btn-danger" onclick="deleteSlide(${slide.id})">Excluir</button>
    </div>
  `;

  return card;
}

document.getElementById('addSlideBtn')?.addEventListener('click', () => {
  openSlideModal();
});

function openSlideModal(slide = null) {
  const isEdit = slide !== null;
  const title = isEdit ? 'Editar Slide' : 'Adicionar Slide';

  const content = `
    <form id="slideForm" class="modal-form">
      <div class="form-group">
        <label for="slideTitle">Título</label>
        <input type="text" id="slideTitle" name="title" value="${
          slide?.title || ''
        }" required>
      </div>

      <div class="form-group">
        <label for="slideSubtitle">Subtítulo</label>
        <input type="text" id="slideSubtitle" name="subtitle" value="${
          slide?.subtitle || ''
        }" required>
      </div>

      <div class="form-group">
        <label for="slideImage">Imagem</label>
        <div class="file-upload" onclick="document.getElementById('slideImageInput').click()">
          <p>Clique para selecionar uma imagem</p>
          <input type="file" id="slideImageInput" accept="image/*" onchange="previewImage(this, 'slidePreview')">
        </div>
        <div id="slidePreview" class="file-preview">
          ${
            slide?.image_url
              ? `<img src="${slide.image_url}" alt="Preview">`
              : ''
          }
        </div>
      </div>

      <div class="form-group">
        <label for="slideOrder">Ordem</label>
        <input type="number" id="slideOrder" name="order_position" value="${
          slide?.order_position || 0
        }">
      </div>

      <div class="form-group">
        <label>
          <input type="checkbox" id="slideActive" name="active" ${
            slide?.active !== 0 ? 'checked' : ''
          }>
          Ativo
        </label>
      </div>

      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="closeModal()">Cancelar</button>
        <button type="submit" class="btn btn-primary">
          ${isEdit ? 'Atualizar' : 'Criar'}
        </button>
      </div>
    </form>
  `;

  openModal(title, content);

  document.getElementById('slideForm').addEventListener('submit', e => {
    e.preventDefault();
    saveSlide(slide?.id);
  });
}

async function saveSlide(id = null) {
  const form = document.getElementById('slideForm');
  const formData = new FormData();

  formData.append('title', form.title.value);
  formData.append('subtitle', form.subtitle.value);
  formData.append('order_position', form.order_position.value);
  formData.append('active', form.active.checked ? 1 : 0);

  const imageFile = document.getElementById('slideImageInput').files[0];
  if (imageFile) {
    formData.append('image', imageFile);
  }

  try {
    if (id) {
      await api.upload(`/slides/${id}`, formData);
      showToast('Slide atualizado com sucesso!', 'success');
    } else {
      await api.upload('/slides', formData);
      showToast('Slide criado com sucesso!', 'success');
    }

    closeModal();
    loadSlides();
    loadDashboardStats();
  } catch (error) {
    showToast('Erro ao salvar slide: ' + error.message, 'error');
  }
}

async function editSlide(id) {
  try {
    const response = await api.get(`/slides/${id}`);
    openSlideModal(response.data);
  } catch (error) {
    showToast('Erro ao carregar slide: ' + error.message, 'error');
  }
}

async function deleteSlide(id) {
  if (!confirm('Tem certeza que deseja excluir este slide?')) return;

  try {
    await api.delete(`/slides/${id}`);
    showToast('Slide excluído com sucesso!', 'success');
    loadSlides();
    loadDashboardStats();
  } catch (error) {
    showToast('Erro ao excluir slide: ' + error.message, 'error');
  }
}

// ===== SERVICES MANAGEMENT =====
async function loadServices() {
  try {
    const response = await api.get('/services');
    const services = response.data || [];

    const container = document.getElementById('servicesContent');
    container.innerHTML = '';

    if (services.length === 0) {
      container.innerHTML =
        '<p style="grid-column: 1/-1; text-align: center; color: var(--text-secondary);">Nenhum serviço cadastrado</p>';
      return;
    }

    services.forEach(service => {
      const card = createServiceCard(service);
      container.appendChild(card);
    });
  } catch (error) {
    showToast('Erro ao carregar serviços: ' + error.message, 'error');
  }
}

function createServiceCard(service) {
  const card = document.createElement('div');
  card.className = 'data-card';

  const features = Array.isArray(service.features)
    ? service.features.join(', ')
    : '';

  card.innerHTML = `
    <div class="service-icon" style="width: 3rem; height: 3rem; background-color: #a7f3d0; border-radius: 0.5rem; display: flex; align-items: center; justify-content: center; margin-bottom: 1rem; color: #0d9488;">
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        ${service.icon}
      </svg>
    </div>
    <h3 class="data-card-title">${service.title}</h3>
    <p class="data-card-subtitle">${service.description}</p>
    <p style="font-size: 0.75rem; color: var(--text-secondary); margin-top: 0.5rem;">${features}</p>
    <div class="data-card-actions">
      <button class="btn btn-sm btn-outline" onclick="editService(${service.id})">Editar</button>
      <button class="btn btn-sm btn-danger" onclick="deleteService(${service.id})">Excluir</button>
    </div>
  `;

  return card;
}

document.getElementById('addServiceBtn')?.addEventListener('click', () => {
  openServiceModal();
});

function openServiceModal(service = null) {
  const isEdit = service !== null;
  const title = isEdit ? 'Editar Serviço' : 'Adicionar Serviço';
  const features = service?.features ? service.features.join('\n') : '';

  const content = `
    <form id="serviceForm" class="modal-form">
      <div class="form-group">
        <label for="serviceTitle">Título</label>
        <input type="text" id="serviceTitle" name="title" value="${
          service?.title || ''
        }" required>
      </div>

      <div class="form-group">
        <label for="serviceDescription">Descrição</label>
        <textarea id="serviceDescription" name="description" required>${
          service?.description || ''
        }</textarea>
      </div>

      <div class="form-group">
        <label for="serviceIcon">SVG do Ícone (path)</label>
        <textarea id="serviceIcon" name="icon" placeholder="Ex: <circle cx='12' cy='12' r='10'></circle>">${
          service?.icon || ''
        }</textarea>
      </div>

      <div class="form-group">
        <label for="serviceFeatures">Características (uma por linha)</label>
        <textarea id="serviceFeatures" name="features" rows="4">${features}</textarea>
      </div>

      <div class="form-group">
        <label for="serviceOrder">Ordem</label>
        <input type="number" id="serviceOrder" name="order_position" value="${
          service?.order_position || 0
        }">
      </div>

      <div class="form-group">
        <label>
          <input type="checkbox" id="serviceActive" name="active" ${
            service?.active !== 0 ? 'checked' : ''
          }>
          Ativo
        </label>
      </div>

      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="closeModal()">Cancelar</button>
        <button type="submit" class="btn btn-primary">
          ${isEdit ? 'Atualizar' : 'Criar'}
        </button>
      </div>
    </form>
  `;

  openModal(title, content);

  document.getElementById('serviceForm').addEventListener('submit', e => {
    e.preventDefault();
    saveService(service?.id);
  });
}

async function saveService(id = null) {
  const form = document.getElementById('serviceForm');

  const featuresText = form.features.value;
  const featuresArray = featuresText.split('\n').filter(f => f.trim());

  const data = {
    title: form.title.value,
    description: form.description.value,
    icon: form.icon.value,
    features: featuresArray,
    order_position: parseInt(form.order_position.value),
    active: form.active.checked ? 1 : 0,
  };

  try {
    if (id) {
      await api.put(`/services/${id}`, data);
      showToast('Serviço atualizado com sucesso!', 'success');
    } else {
      await api.post('/services', data);
      showToast('Serviço criado com sucesso!', 'success');
    }

    closeModal();
    loadServices();
    loadDashboardStats();
  } catch (error) {
    showToast('Erro ao salvar serviço: ' + error.message, 'error');
  }
}

async function editService(id) {
  try {
    const response = await api.get(`/services/${id}`);
    openServiceModal(response.data);
  } catch (error) {
    showToast('Erro ao carregar serviço: ' + error.message, 'error');
  }
}

async function deleteService(id) {
  if (!confirm('Tem certeza que deseja excluir este serviço?')) return;

  try {
    await api.delete(`/services/${id}`);
    showToast('Serviço excluído com sucesso!', 'success');
    loadServices();
    loadDashboardStats();
  } catch (error) {
    showToast('Erro ao excluir serviço: ' + error.message, 'error');
  }
}

// ===== PORTFOLIO MANAGEMENT =====
async function loadPortfolio() {
  try {
    const response = await api.get('/portfolio');
    const clients = response.data || [];

    const container = document.getElementById('portfolioContent');
    container.innerHTML = '';

    if (clients.length === 0) {
      container.innerHTML =
        '<p style="grid-column: 1/-1; text-align: center; color: var(--text-secondary);">Nenhum cliente cadastrado</p>';
      return;
    }

    clients.forEach(client => {
      const card = createClientCard(client);
      container.appendChild(card);
    });
  } catch (error) {
    showToast('Erro ao carregar clientes: ' + error.message, 'error');
  }
}

function createClientCard(client) {
  const card = document.createElement('div');
  card.className = 'data-card';

  card.innerHTML = `
    <img src="${client.logo_url}" alt="${client.name}" class="data-card-image" style="object-fit: contain; background-color: #f9fafb;" onerror="this.src='https://via.placeholder.com/300x150?text=${client.name}'">
    <h3 class="data-card-title">${client.name}</h3>
    <div class="data-card-actions">
      <button class="btn btn-sm btn-outline" onclick="editClient(${client.id})">Editar</button>
      <button class="btn btn-sm btn-danger" onclick="deleteClient(${client.id})">Excluir</button>
    </div>
  `;

  return card;
}

document.getElementById('addClientBtn')?.addEventListener('click', () => {
  openClientModal();
});

function openClientModal(client = null) {
  const isEdit = client !== null;
  const title = isEdit ? 'Editar Cliente' : 'Adicionar Cliente';

  const content = `
    <form id="clientForm" class="modal-form">
      <div class="form-group">
        <label for="clientName">Nome do Cliente</label>
        <input type="text" id="clientName" name="name" value="${
          client?.name || ''
        }" required>
      </div>

      <div class="form-group">
        <label for="clientLogo">Logo</label>
        <div class="file-upload" onclick="document.getElementById('clientLogoInput').click()">
          <p>Clique para selecionar o logo</p>
          <input type="file" id="clientLogoInput" accept="image/*" onchange="previewImage(this, 'clientPreview')">
        </div>
        <div id="clientPreview" class="file-preview">
          ${
            client?.logo_url
              ? `<img src="${client.logo_url}" alt="Preview">`
              : ''
          }
        </div>
      </div>

      <div class="form-group">
        <label for="clientOrder">Ordem</label>
        <input type="number" id="clientOrder" name="order_position" value="${
          client?.order_position || 0
        }">
      </div>

      <div class="form-group">
        <label>
          <input type="checkbox" id="clientActive" name="active" ${
            client?.active !== 0 ? 'checked' : ''
          }>
          Ativo
        </label>
      </div>

      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="closeModal()">Cancelar</button>
        <button type="submit" class="btn btn-primary">
          ${isEdit ? 'Atualizar' : 'Criar'}
        </button>
      </div>
    </form>
  `;

  openModal(title, content);

  document.getElementById('clientForm').addEventListener('submit', e => {
    e.preventDefault();
    saveClient(client?.id);
  });
}

async function saveClient(id = null) {
  const form = document.getElementById('clientForm');
  const formData = new FormData();

  formData.append('name', form.name.value);
  formData.append('order_position', form.order_position.value);
  formData.append('active', form.active.checked ? 1 : 0);

  const logoFile = document.getElementById('clientLogoInput').files[0];
  if (logoFile) {
    formData.append('logo', logoFile);
  }

  try {
    if (id) {
      await api.upload(`/portfolio/${id}`, formData);
      showToast('Cliente atualizado com sucesso!', 'success');
    } else {
      await api.upload('/portfolio', formData);
      showToast('Cliente criado com sucesso!', 'success');
    }

    closeModal();
    loadPortfolio();
    loadDashboardStats();
  } catch (error) {
    showToast('Erro ao salvar cliente: ' + error.message, 'error');
  }
}

async function editClient(id) {
  try {
    const response = await api.get(`/portfolio/${id}`);
    openClientModal(response.data);
  } catch (error) {
    showToast('Erro ao carregar cliente: ' + error.message, 'error');
  }
}

async function deleteClient(id) {
  if (!confirm('Tem certeza que deseja excluir este cliente?')) return;

  try {
    await api.delete(`/portfolio/${id}`);
    showToast('Cliente excluído com sucesso!', 'success');
    loadPortfolio();
    loadDashboardStats();
  } catch (error) {
    showToast('Erro ao excluir cliente: ' + error.message, 'error');
  }
}

// ===== MESSAGES MANAGEMENT =====
async function loadMessages() {
  try {
    const response = await api.get('/contact');
    const messages = response.data || [];

    const container = document.getElementById('messagesContent');
    container.innerHTML = '';

    if (messages.length === 0) {
      container.innerHTML =
        '<p style="text-align: center; color: var(--text-secondary);">Nenhuma mensagem recebida</p>';
      return;
    }

    messages.forEach(message => {
      const card = createMessageCard(message);
      container.appendChild(card);
    });

    checkUnreadMessages();
  } catch (error) {
    showToast('Erro ao carregar mensagens: ' + error.message, 'error');
  }
}

function createMessageCard(message) {
  const card = document.createElement('div');
  card.className = `message-card ${message.read_status === 0 ? 'unread' : ''}`;

  const date = new Date(message.created_at).toLocaleString('pt-BR');

  card.innerHTML = `
    <div class="message-header">
      <div>
        <div class="message-sender">${message.name}</div>
        <div class="message-email">${message.email}</div>
        ${
          message.phone
            ? `<div class="message-email">${message.phone}</div>`
            : ''
        }
        ${
          message.company
            ? `<div class="message-email">${message.company}</div>`
            : ''
        }
      </div>
      <div class="message-date">${date}</div>
    </div>
    <div class="message-text">${message.message}</div>
    <div class="message-actions">
      ${
        message.read_status === 0
          ? `<button class="btn btn-sm btn-primary" onclick="markAsRead(${message.id})">Marcar como Lida</button>`
          : ''
      }
      <button class="btn btn-sm btn-danger" onclick="deleteMessage(${
        message.id
      })">Excluir</button>
    </div>
  `;

  return card;
}

async function markAsRead(id) {
  try {
    await api.request(`/contact/${id}/read`, { method: 'PATCH' });
    showToast('Mensagem marcada como lida!', 'success');
    loadMessages();
  } catch (error) {
    showToast('Erro ao marcar mensagem: ' + error.message, 'error');
  }
}

async function deleteMessage(id) {
  if (!confirm('Tem certeza que deseja excluir esta mensagem?')) return;

  try {
    await api.delete(`/contact/${id}`);
    showToast('Mensagem excluída com sucesso!', 'success');
    loadMessages();
    loadDashboardStats();
  } catch (error) {
    showToast('Erro ao excluir mensagem: ' + error.message, 'error');
  }
}

// ===== COMPANY INFO MANAGEMENT =====
async function loadCompanyInfo() {
  try {
    const response = await api.get('/company');
    const info = response.data || {};

    const form = document.getElementById('companyForm');
    form.innerHTML = `
      <h3 style="margin-bottom: 1.5rem;">Informações da Empresa</h3>

      <div class="form-group">
        <label for="companyName">Nome da Empresa</label>
        <input type="text" id="companyName" name="company_name" value="${
          info.company_name || ''
        }" required>
      </div>

      <div class="form-group">
        <label for="companyEmail">Email</label>
        <input type="email" id="companyEmail" name="email" value="${
          info.email || ''
        }" required>
      </div>

      <div class="form-group">
        <label for="companyPhone">Telefone</label>
        <input type="tel" id="companyPhone" name="phone" value="${
          info.phone || ''
        }" required>
      </div>

      <div class="form-group">
        <label for="companyLocation">Localização</label>
        <input type="text" id="companyLocation" name="location" value="${
          info.location || ''
        }" required>
      </div>

      <div class="form-group">
        <label for="companyAbout">Sobre a Empresa</label>
        <textarea id="companyAbout" name="about_text" rows="5" required>${
          info.about_text || ''
        }</textarea>
      </div>

      <button type="submit" class="btn btn-primary">Salvar Alterações</button>
    `;

    form.addEventListener('submit', saveCompanyInfo);
  } catch (error) {
    showToast('Erro ao carregar informações: ' + error.message, 'error');
  }
}

async function saveCompanyInfo(e) {
  e.preventDefault();

  const form = e.target;
  const data = {
    company_name: form.company_name.value,
    email: form.email.value,
    phone: form.phone.value,
    location: form.location.value,
    about_text: form.about_text.value,
  };

  try {
    await api.put('/company', data);
    showToast('Informações atualizadas com sucesso!', 'success');
  } catch (error) {
    showToast('Erro ao salvar informações: ' + error.message, 'error');
  }
}

// Image Preview Helper
function previewImage(input, previewId) {
  const preview = document.getElementById(previewId);

  if (input.files?.[0]) {
    const reader = new FileReader();

    reader.onload = function (e) {
      const result = e.target?.result;
      if (typeof result === 'string') {
        preview.innerHTML = `<img src="${result}" alt="Preview">`;
      }
    };

    reader.readAsDataURL(input.files[0]);
  }
}
