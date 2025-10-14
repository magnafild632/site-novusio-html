const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const REQUIRED_ENV_VARS = ['JWT_SECRET'];
const missingEnvVars = REQUIRED_ENV_VARS.filter(
  variable => !process.env[variable],
);

if (missingEnvVars.length > 0) {
  console.error(
    `❌ Variáveis de ambiente obrigatórias ausentes: ${missingEnvVars.join(
      ', ',
    )}`,
  );
  console.error(
    'Configure as variáveis exigidas e reinicie o servidor (arquivo .env ou variáveis de ambiente).',
  );
  process.exit(1);
}

if (!process.env.JWT_EXPIRES_IN) {
  process.env.JWT_EXPIRES_IN = '1h';
  console.warn(
    '⚠️  JWT_EXPIRES_IN não definido. Aplicando valor padrão de 1h.',
  );
}

const app = express();
const PORT = process.env.PORT || 3000;

// Inicializar banco de dados
const db = require('./config/database');

// Middleware
app.use(cors());
app.use(express.json({ 
    limit: '50mb',
    timeout: '300s'
}));
app.use(express.urlencoded({ 
    extended: true, 
    limit: '50mb',
    timeout: '300s'
}));

// Nota: Uploads agora são servidos do banco de dados via rotas específicas
// app.use('/uploads', express.static(path.join(__dirname, '../client/uploads')));

// Em produção, servir arquivos do React build
if (process.env.NODE_ENV === 'production') {
  app.use(express.static(path.join(__dirname, '../client/dist')));
}

// Rotas da API
app.use('/api/auth', require('./routes/auth'));
app.use('/api/slides', require('./routes/slides'));
app.use('/api/services', require('./routes/services'));
app.use('/api/portfolio', require('./routes/portfolio'));
app.use('/api/contact', require('./routes/contact'));
app.use('/api/company', require('./routes/company'));

// Nota: Upload genérico removido - usar rotas específicas do portfolio e slides
// que salvam no banco de dados

// Rota de health check
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'API funcionando corretamente',
    timestamp: new Date().toISOString(),
  });
});

// Em produção, todas as rotas não-API servem o React app
if (process.env.NODE_ENV === 'production') {
  app.get('*', (req, res) => {
    if (!req.path.startsWith('/api')) {
      res.sendFile(path.join(__dirname, '../client/dist/index.html'));
    }
  });
}

// Tratamento de erros 404
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Rota não encontrada',
  });
});

// Tratamento de erros gerais
app.use((err, req, res, next) => {
  console.error('❌ Erro no servidor:', err);
  console.error('Stack:', err.stack);
  
  // Tratamento específico para erros do Multer
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({
      success: false,
      message: 'Arquivo muito grande. O tamanho máximo permitido é 50MB.',
    });
  }
  
  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    return res.status(400).json({
      success: false,
      message: 'Campo de arquivo inesperado.',
    });
  }
  
  if (err.code === 'LIMIT_FILE_COUNT') {
    return res.status(400).json({
      success: false,
      message: 'Muitos arquivos enviados.',
    });
  }
  
  if (err.code === 'LIMIT_FIELD_KEY') {
    return res.status(400).json({
      success: false,
      message: 'Nome do campo muito longo.',
    });
  }
  
  if (err.code === 'LIMIT_FIELD_VALUE') {
    return res.status(400).json({
      success: false,
      message: 'Valor do campo muito longo.',
    });
  }
  
  if (err.code === 'LIMIT_FIELD_COUNT') {
    return res.status(400).json({
      success: false,
      message: 'Muitos campos enviados.',
    });
  }
  
  if (err.code === 'LIMIT_PART_COUNT') {
    return res.status(400).json({
      success: false,
      message: 'Muitas partes no formulário.',
    });
  }
  
  res.status(500).json({
    success: false,
    message: err.message || 'Erro interno do servidor',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════╗
║                                                ║
║        🚀 Servidor Novusio Iniciado!          ║
║                                                ║
║  Site Principal: http://localhost:${PORT}      ║
║  Painel Admin:   http://localhost:${PORT}/admin║
║  API:            http://localhost:${PORT}/api  ║
║                                                ║
║  Ambiente: ${process.env.NODE_ENV || 'development'}                        ║
║                                                ║
╚════════════════════════════════════════════════╝
  `);
});

module.exports = app;
