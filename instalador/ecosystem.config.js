// ⚡ Configuração PM2 - Site Novusio
// Gerenciador de processos para produção

module.exports = {
  apps: [{
    name: 'novusio',
    script: 'server/server.js',
    cwd: '/opt/novusio/app',
    instances: 1, // Usar 1 instância para SQLite (não suporta cluster)
    exec_mode: 'fork', // Fork mode para SQLite
    
    // Configurações de ambiente
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    
    // Configurações de restart
    autorestart: true,
    watch: false, // Não assistir arquivos em produção
    max_memory_restart: '1G', // Restart se usar mais de 1GB
    
    // Configurações de logs
    log_file: '/var/log/novusio/combined.log',
    out_file: '/var/log/novusio/out.log',
    error_file: '/var/log/novusio/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // Configurações de restart
    min_uptime: '10s', // Tempo mínimo antes de considerar como "stable"
    max_restarts: 10, // Máximo de restarts em 1 minuto
    
    // Configurações de performance
    node_args: [
      '--max-old-space-size=1024' // Limitar uso de memória a 1GB
    ],
    
    // Configurações de timeout
    kill_timeout: 5000, // 5 segundos para kill graceful
    
    // Configurações de cron
    cron_restart: '0 4 * * *', // Restart diário às 4:00 AM
    
    // Configurações de merge logs
    merge_logs: true,
    
    // Configurações de user
    user: 'novusio',
    
    // Configurações de source map
    source_map_support: true,
    
    // Configurações de monitoramento
    monitoring: false, // Desabilitar PM2 Plus
    
    // Configurações de cluster (se usar PostgreSQL/MySQL no futuro)
    // instances: 'max', // Usar todos os cores disponíveis
    // exec_mode: 'cluster', // Cluster mode para bancos que suportam
    
    // Configurações de graceful shutdown
    listen_timeout: 10000, // 10 segundos
    shutdown_with_message: true,
    
    // Configurações de ignore
    ignore_watch: [
      'node_modules',
      'logs',
      '*.log',
      '.git',
      'client/dist',
      'uploads'
    ],
    
    // Configurações de error handling
    error_handlers: {
      'EADDRINUSE': {
        action: 'restart',
        delay: 5000
      },
      'ECONNRESET': {
        action: 'restart',
        delay: 1000
      }
    }
  }],
  
  // Configurações de deploy (opcional)
  deploy: {
    production: {
      user: 'novusio',
      host: 'localhost',
      ref: 'origin/main',
      repo: 'git@github.com:seu-usuario/site-novusio-html.git',
      path: '/opt/novusio',
      'pre-deploy-local': '',
      'post-deploy': 'npm install && npm run build && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
};
