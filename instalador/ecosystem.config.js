// =============================================================================
// CONFIGURAÇÃO PM2 PARA PRODUÇÃO - NOVUSIO
// =============================================================================
// Este arquivo configura o PM2 para gerenciar a aplicação em produção
// Inclui: clustering, monitoramento, logs, restart automático
// =============================================================================

module.exports = {
  apps: [
    {
      // Nome da aplicação
      name: 'novusio-server',

      // Script principal
      script: 'server/server.js',

      // Diretório de trabalho
      cwd: '/opt/novusio',

      // Configurações de instâncias
      instances: 'max', // Usar todos os cores disponíveis
      exec_mode: 'cluster', // Modo cluster para melhor performance

      // Variáveis de ambiente
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
        NODE_OPTIONS: '--max-old-space-size=2048',
      },

      // Configurações de desenvolvimento (se necessário)
      env_development: {
        NODE_ENV: 'development',
        PORT: 3000,
        NODE_OPTIONS: '--max-old-space-size=1024',
      },

      // Arquivos de log
      error_file: '/var/log/novusio/error.log',
      out_file: '/var/log/novusio/out.log',
      log_file: '/var/log/novusio/combined.log',

      // Configurações de log
      time: true, // Adicionar timestamp nos logs
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,

      // Configurações de memória e CPU
      max_memory_restart: '1G', // Reiniciar se usar mais de 1GB
      node_args: '--max-old-space-size=2048', // Limite de memória do Node.js

      // Configurações de restart
      restart_delay: 4000, // Delay entre restarts (4 segundos)
      max_restarts: 10, // Máximo de restarts em 15 minutos
      min_uptime: '10s', // Tempo mínimo de uptime antes de considerar estável

      // Configurações de monitoramento
      watch: false, // Não assistir arquivos em produção
      ignore_watch: ['node_modules', 'logs', 'uploads', '*.log'],

      // Configurações de uptime
      autorestart: true, // Reiniciar automaticamente se crashar

      // Configurações de kill
      kill_timeout: 5000, // Tempo para aguardar antes de matar o processo
      listen_timeout: 3000, // Tempo para aguardar o processo escutar na porta

      // Configurações de cron (para restart periódico - opcional)
      // cron_restart: '0 2 * * *', // Reiniciar todos os dias às 2h da manhã

      // Configurações de health check
      health_check_grace_period: 3000, // Período de graça para health check

      // Configurações de interpolação
      instance_var: 'INSTANCE_ID',

      // Configurações de source map (para debugging)
      source_map_support: true,

      // Configurações de buffer
      max_stdout_log_size: '10M',
      max_stderr_log_size: '10M',

      // Configurações de compressão de logs
      log_type: 'json',

      // Configurações de ambiente específicas
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
        NODE_OPTIONS: '--max-old-space-size=2048',
      },

      // Configurações de variáveis de ambiente adicionais
      env_file: '.env',

      // Configurações de plugins (se necessário)
      // pmx: true, // Habilitar monitoramento avançado

      // Configurações de segurança
      uid: 'novusio', // Executar como usuário específico
      gid: 'novusio', // Executar como grupo específico

      // Configurações de timeout
      timeout: 30000, // Timeout para operações

      // Configurações de retry
      retry_delay: 4000, // Delay entre tentativas de restart
    },
  ],

  // Configurações de deploy (opcional)
  deploy: {
    production: {
      user: 'novusio',
      host: ['seu-servidor.com'],
      ref: 'origin/main',
      repo: 'https://github.com/seu-usuario/site-novusio-html.git',
      path: '/opt/novusio',
      'pre-deploy-local': '',
      'post-deploy':
        'npm ci && npm run build && pm2 reload ecosystem.config.js --env production',
      'pre-setup': '',
    },
  },
};
