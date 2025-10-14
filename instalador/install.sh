#!/bin/bash

# 🚀 Instalador Automático - Site Novusio
# Script completo para instalação em VPS Ubuntu/Debian

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   print_error "Este script deve ser executado como root."
   exit 1
fi

# Definir comandos baseados no usuário
if [[ $EUID -eq 0 ]]; then
    SUDO_CMD=""
    USER_CMD=""
else
    SUDO_CMD="sudo "
    USER_CMD="sudo -u novusio "
fi

# Função para gerar string aleatória
generate_random_string() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length 2>/dev/null || \
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1
}

# Função para configurar .env automaticamente
configure_env_automatically() {
    print_status "Configurando arquivo .env automaticamente..."
    
    # Solicitar informações básicas
    echo ""
    print_status "📝 Configuração do domínio e email"
    echo ""
    
    # DOMAIN
    while true; do
        read -p "Digite seu domínio (ex: exemplo.com): " DOMAIN
        if [[ -n "$DOMAIN" ]]; then
            if [[ $DOMAIN =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
                break
            else
                print_error "Formato de domínio inválido"
            fi
        else
            print_warning "Domínio é obrigatório"
        fi
    done
    
    # EMAIL
    while true; do
        read -p "Digite seu email para notificações: " EMAIL
        if [[ -n "$EMAIL" ]]; then
            if [[ $EMAIL =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                break
            else
                print_error "Formato de email inválido"
            fi
        else
            print_warning "Email é obrigatório"
        fi
    done
    
    # Gerar secrets
    print_status "Gerando secrets seguros..."
    JWT_SECRET=$(generate_random_string 64)
    SESSION_SECRET=$(generate_random_string 64)
    
    # Criar arquivo .env
    tee /opt/novusio/.env > /dev/null << EOF
# 🔧 Configuração de Produção - Site Novusio
# Gerado automaticamente em $(date)

# Configurações do servidor
NODE_ENV=production
PORT=3000

# Configurações do domínio
DOMAIN=$DOMAIN
EMAIL=$EMAIL

# Configurações de autenticação JWT
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=1h

# Configurações do banco de dados
DB_PATH=/opt/novusio/app/database.sqlite

# Configurações de upload
MAX_FILE_SIZE=52428800
UPLOAD_PATH=/opt/novusio/app/client/uploads

# Configurações de segurança
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Configurações de logs
LOG_LEVEL=info
LOG_FILE=/var/log/novusio/app.log

# Configurações de backup
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30

# Configurações de monitoramento
HEALTH_CHECK_ENABLED=true
METRICS_ENABLED=true

# Configurações de cache
CACHE_ENABLED=true
CACHE_TTL=3600

# Configurações de CORS
CORS_ORIGIN=https://$DOMAIN
CORS_CREDENTIALS=true

# Configurações de sessão
SESSION_SECRET=$SESSION_SECRET
SESSION_MAX_AGE=86400000

# Configurações de rate limiting
RATE_LIMIT_API=100
RATE_LIMIT_LOGIN=5
RATE_LIMIT_ADMIN=20

# Configurações de SSL
SSL_ENABLED=true
SSL_REDIRECT=true

# Configurações de backup automático
AUTO_BACKUP_ENABLED=true
AUTO_BACKUP_TIME=02:00
AUTO_BACKUP_RETENTION=7

# Configurações de notificações
NOTIFICATIONS_ENABLED=true
NOTIFICATION_EMAIL=$EMAIL

# Configurações de manutenção
MAINTENANCE_MODE=false
MAINTENANCE_MESSAGE=Site em manutenção. Volte em breve.

# Configurações de debug (manter false em produção)
DEBUG=false
VERBOSE_LOGGING=false

# Configurações de performance
CLUSTER_MODE=false
WORKER_PROCESSES=1
MAX_MEMORY=1073741824

# Configurações de timeout
REQUEST_TIMEOUT=30000
CONNECTION_TIMEOUT=5000

# Configurações de compressão
COMPRESSION_ENABLED=true
COMPRESSION_LEVEL=6

# Configurações de segurança adicional
SECURITY_HEADERS=true
XSS_PROTECTION=true
CSRF_PROTECTION=true
EOF
    
    # Definir permissões
    chown novusio:novusio /opt/novusio/.env
    chmod 600 /opt/novusio/.env
    
    print_success "Arquivo .env configurado automaticamente"
    print_success "Domínio: $DOMAIN"
    print_success "Email: $EMAIL"
    echo ""
}

print_status "🚀 Iniciando instalação do Site Novusio..."

# Atualizar sistema
print_status "📦 Atualizando sistema..."
apt update && apt upgrade -y

# Instalar dependências básicas
print_status "🔧 Instalando dependências básicas..."
apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Instalar Node.js 18
print_status "📦 Instalando Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Verificar versão do Node.js
NODE_VERSION=$(node --version)
print_success "Node.js instalado: $NODE_VERSION"

# Instalar PM2 globalmente
print_status "⚡ Instalando PM2..."
npm install -g pm2

# Instalar Nginx
print_status "🌐 Instalando Nginx..."
apt install -y nginx

# Instalar Certbot
print_status "🔒 Instalando Certbot..."
apt install -y certbot python3-certbot-nginx

# Instalar Fail2ban
print_status "🛡️ Instalando Fail2ban..."
apt install -y fail2ban

# Instalar UFW Firewall
print_status "🔥 Configurando Firewall UFW..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'

# Criar usuário para aplicação
print_status "👤 Configurando usuário da aplicação..."
if ! id "novusio" &>/dev/null; then
    useradd -r -s /bin/false -d /opt/novusio novusio
    print_success "Usuário 'novusio' criado"
else
    print_warning "Usuário 'novusio' já existe"
fi

# Criar diretório da aplicação
print_status "📁 Criando estrutura de diretórios..."
mkdir -p /opt/novusio
mkdir -p /opt/novusio/logs
mkdir -p /opt/novusio/backups
mkdir -p /var/log/novusio

# Definir permissões
chown -R novusio:novusio /opt/novusio
chown -R novusio:novusio /var/log/novusio

# Copiar arquivos da aplicação
print_status "📋 Copiando arquivos da aplicação..."
cp -r . /opt/novusio/app/
chown -R novusio:novusio /opt/novusio/app

# Instalar dependências da aplicação
print_status "📦 Instalando dependências da aplicação..."
cd /opt/novusio/app
su -s /bin/bash novusio -c "npm install"
su -s /bin/bash novusio -c "npm run client:install"
su -s /bin/bash novusio -c "npm run build"

# Configurar .env automaticamente
print_status "⚙️ Configurando variáveis de ambiente..."
configure_env_automatically

# Configurar Nginx
print_status "🌐 Configurando Nginx..."
cp instalador/nginx.conf /etc/nginx/sites-available/novusio
ln -sf /etc/nginx/sites-available/novusio /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Testar configuração do Nginx
if nginx -t; then
    print_success "Configuração do Nginx válida"
    systemctl reload nginx
else
    print_error "Erro na configuração do Nginx"
    exit 1
fi

# Configurar Fail2ban
print_status "🛡️ Configurando Fail2ban..."
cp instalador/fail2ban.conf /etc/fail2ban/jail.local
cp instalador/fail2ban-filters.conf /etc/fail2ban/filter.d/novusio.conf

# Configurar PM2
print_status "⚡ Configurando PM2..."
cp instalador/ecosystem.config.js /opt/novusio/
chown novusio:novusio /opt/novusio/ecosystem.config.js

# Configurar systemd
print_status "🔄 Configurando systemd..."
cp instalador/novusio.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable novusio

# Configurar backup automático
print_status "💾 Configurando backup automático..."
cp instalador/backup.sh /opt/novusio/
chmod +x /opt/novusio/backup.sh
chown novusio:novusio /opt/novusio/backup.sh

# Adicionar cron job para backup
(crontab -u novusio -l 2>/dev/null; echo "0 2 * * * /opt/novusio/backup.sh") | crontab -u novusio -

# Inicializar banco de dados
print_status "🗄️ Inicializando banco de dados..."
cd /opt/novusio/app
su -s /bin/bash novusio -c "NODE_ENV=production npm run init-db"

# Iniciar serviços
print_status "🚀 Iniciando serviços..."
systemctl start fail2ban
systemctl enable fail2ban
systemctl start nginx
systemctl enable nginx

# Iniciar aplicação
print_status "🚀 Iniciando aplicação..."
systemctl start novusio

# Aguardar aplicação inicializar
print_status "⏳ Aguardando aplicação inicializar..."
sleep 5

# Verificar se aplicação está rodando
if systemctl is-active --quiet novusio; then
    print_success "✅ Aplicação iniciada com sucesso"
else
    print_warning "⚠️ Aplicação pode não ter iniciado corretamente"
    print_status "Verifique os logs: journalctl -u novusio -f"
fi

# Criar script de gerenciamento
print_status "📝 Criando script de gerenciamento..."
cp instalador/novusio-manager.sh /usr/local/bin/novusio-manager
chmod +x /usr/local/bin/novusio-manager

print_success "🎉 Instalação concluída com sucesso!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_status "📋 Próximos passos:"
echo ""
echo "1. 🔒 Configure SSL com Certbot:"
echo "   ./instalador/setup-ssl.sh"
echo ""
echo "2. 📊 Verificar status:"
echo "   systemctl status novusio"
echo ""
echo "3. 🔍 Verificar sistema completo:"
echo "   ./instalador/verificar-sistema.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_status "🔧 Comandos úteis:"
echo ""
echo "• Gerenciar aplicação: novusio-manager [start|stop|restart|status|logs]"
echo "• Ver logs: journalctl -u novusio -f"
echo "• Backup manual: /opt/novusio/backup.sh"
echo "• Status Nginx: systemctl status nginx"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_success "✅ Arquivo .env já foi configurado automaticamente!"
print_status "📝 Para editar configurações: nano /opt/novusio/.env"
echo ""
