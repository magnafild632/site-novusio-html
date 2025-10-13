const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const path = require('path');
require('dotenv').config();

const dbPath = path.resolve(__dirname, '../database.sqlite');
const db = new sqlite3.Database(dbPath);

console.log('🔧 Inicializando banco de dados...');

// Datos predeterminados
const defaultSlides = [
  {
    title: 'Chatbots Inteligentes',
    subtitle: 'Automatiza tu atención al cliente 24/7 con IA avanzada',
    image_url:
      'https://images.unsplash.com/photo-1531746790731-6c087fecd65a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
    order: 1,
  },
  {
    title: 'Desarrollo de Sistemas',
    subtitle: 'Soluciones personalizadas para tu empresa',
    image_url:
      'https://images.unsplash.com/photo-1551288049-bebda4e38f71?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
    order: 2,
  },
  {
    title: 'Seguridad Cibernética',
    subtitle: 'Protege tu negocio de amenazas digitales',
    image_url:
      'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
    order: 3,
  },
  {
    title: 'Sitios Web & E-commerce',
    subtitle: 'Impulsa tu presencia digital',
    image_url:
      'https://images.unsplash.com/photo-1460925895917-afdab827c52f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
    order: 4,
  },
];

const companyData = [
  { key: 'company_name', value: 'Novusio' },
  { key: 'email', value: 'contacto@novusiopy.com' },
  { key: 'phone', value: '+595 981 234 567' },
  { key: 'location', value: 'Asunción, Paraguay' },
  {
    key: 'about_text',
    value:
      'Somos una empresa especializada en soluciones digitales innovadoras. Combinamos tecnología de vanguardia con experiencia en desarrollo para crear productos que transforman negocios.',
  },
];

db.serialize(() => {
  // Crear tablas
  db.run(
    `CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT DEFAULT 'admin',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`,
    err => {
      if (err) console.error('Erro ao criar tabela users:', err);
      else console.log('✅ Tabela users criada');
    },
  );

  db.run(
    `CREATE TABLE IF NOT EXISTS hero_slides (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      subtitle TEXT NOT NULL,
      image_url TEXT NOT NULL,
      order_position INTEGER DEFAULT 0,
      active INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`,
    err => {
      if (err) console.error('Erro ao criar tabela hero_slides:', err);
      else console.log('✅ Tabela hero_slides criada');
    },
  );

  db.run(
    `CREATE TABLE IF NOT EXISTS services (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      icon TEXT NOT NULL,
      features TEXT NOT NULL,
      order_position INTEGER DEFAULT 0,
      active INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`,
    err => {
      if (err) console.error('Erro ao criar tabela services:', err);
      else console.log('✅ Tabela services criada');
    },
  );

  db.run(
    `CREATE TABLE IF NOT EXISTS portfolio_clients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      logo_url TEXT NOT NULL,
      order_position INTEGER DEFAULT 0,
      active INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`,
    err => {
      if (err) console.error('Erro ao criar tabela portfolio_clients:', err);
      else console.log('✅ Tabela portfolio_clients criada');
    },
  );

  db.run(
    `CREATE TABLE IF NOT EXISTS company_info (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT UNIQUE NOT NULL,
      value TEXT NOT NULL,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`,
    err => {
      if (err) console.error('Erro ao criar tabela company_info:', err);
      else console.log('✅ Tabela company_info criada');
    },
  );

  db.run(
    `CREATE TABLE IF NOT EXISTS contact_messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      phone TEXT,
      company TEXT,
      message TEXT NOT NULL,
      read_status INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`,
    err => {
      if (err) console.error('Erro ao criar tabela contact_messages:', err);
      else console.log('✅ Tabela contact_messages criada');
    },
  );

  // Inserir slides padrão
  const insertSlide = db.prepare(
    `INSERT OR IGNORE INTO hero_slides (title, subtitle, image_url, order_position) VALUES (?, ?, ?, ?)`,
  );

  defaultSlides.forEach(slide => {
    insertSlide.run(slide.title, slide.subtitle, slide.image_url, slide.order);
  });
  insertSlide.finalize();
  console.log('✅ Slides padrão inseridos');

  // Inserir informações da empresa
  const insertInfo = db.prepare(
    `INSERT OR IGNORE INTO company_info (key, value) VALUES (?, ?)`,
  );

  companyData.forEach(item => {
    insertInfo.run(item.key, item.value);
  });
  insertInfo.finalize();
  console.log('✅ Informações da empresa inseridas');

  // Inserir serviços padrão
  const defaultServices = [
    {
      title: 'Chatbots con IA',
      description: 'Desarrollamos chatbots inteligentes que automatizan tu atención al cliente.',
      icon: '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>',
      features: ['Respuestas automáticas 24/7', 'Integración con WhatsApp', 'IA conversacional avanzada', 'Análisis de conversaciones'],
      order: 1
    },
    {
      title: 'Desarrollo de Sistemas',
      description: 'Creamos sistemas personalizados para optimizar tus procesos de negocio.',
      icon: '<polyline points="16,18 22,12 16,6"></polyline><polyline points="8,6 2,12 8,18"></polyline>',
      features: ['Software a medida', 'Integración de APIs', 'Arquitectura escalable', 'Soporte técnico continuo'],
      order: 2
    },
    {
      title: 'Seguridad Cibernética',
      description: 'Protegemos tu información con las mejores prácticas de seguridad.',
      icon: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>',
      features: ['Auditorías de seguridad', 'Protección de datos', 'Certificados SSL', 'Monitoreo continuo'],
      order: 3
    },
    {
      title: 'Sitios Web & E-commerce',
      description: 'Diseñamos y desarrollamos sitios web modernos y tiendas online.',
      icon: '<circle cx="12" cy="12" r="10"></circle><line x1="2" y1="12" x2="22" y2="12"></line><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>',
      features: ['Diseño responsive', 'SEO optimizado', 'Pasarelas de pago', 'Panel administrativo'],
      order: 4
    }
  ];

  const insertService = db.prepare(
    `INSERT OR IGNORE INTO services (title, description, icon, features, order_position) VALUES (?, ?, ?, ?, ?)`,
  );

  defaultServices.forEach(service => {
    insertService.run(
      service.title,
      service.description,
      service.icon,
      JSON.stringify(service.features),
      service.order
    );
  });
  insertService.finalize();
  console.log('✅ Serviços padrão inseridos');

  // Inserir clientes padrão do portfólio
  const defaultClients = [
    { name: 'Cliente 1', logo_url: 'https://images.unsplash.com/photo-1622465911368-72162f8da3e2?w=300', order: 1 },
    { name: 'Cliente 2', logo_url: 'https://images.unsplash.com/photo-1661347998423-b15d37d6f61e?w=300', order: 2 },
    { name: 'Cliente 3', logo_url: 'https://images.unsplash.com/photo-1590102426028-bf1ed6b354f5?w=300', order: 3 },
    { name: 'Cliente 4', logo_url: 'https://images.unsplash.com/photo-1595409583957-5d1ec5869de9?w=300', order: 4 }
  ];

  const insertClient = db.prepare(
    `INSERT OR IGNORE INTO portfolio_clients (name, logo_url, order_position) VALUES (?, ?, ?)`,
  );

  defaultClients.forEach(client => {
    insertClient.run(client.name, client.logo_url, client.order);
  });
  insertClient.finalize();
  console.log('✅ Clientes padrão inseridos');
});

// Inserir usuário admin (fora do serialize para aguardar hash)
const adminEmail = process.env.ADMIN_EMAIL || 'admin@novusiopy.com';
const adminPassword = process.env.ADMIN_PASSWORD || 'Admin123!';

bcrypt.hash(adminPassword, 10, (err, hash) => {
  if (err) {
    console.error('Erro ao criar hash da senha:', err);
    db.close();
    return;
  }

  db.run(
    `INSERT OR IGNORE INTO users (name, email, password, role) VALUES (?, ?, ?, ?)`,
    ['Administrador', adminEmail, hash, 'admin'],
    err => {
      if (err) {
        console.error('Erro ao criar admin:', err);
      } else {
        console.log('✅ Usuário admin criado');
      }

      // Fechar banco APÓS todas as operações
      db.close(err => {
        if (err) {
          console.error('Erro ao fechar banco:', err);
        } else {
          console.log('\n✅ Base de datos inicializada con éxito!');
          console.log('\n📝 Credenciales de acceso:');
          console.log(`   Email: ${adminEmail}`);
          console.log(`   Contraseña: ${adminPassword}`);
          console.log(
            '\n⚠️  IMPORTANTE: ¡Cambie estas credenciales después del primer inicio de sesión!\n',
          );
        }
      });
    },
  );
});
