#!/bin/bash

# =============================================================================
# Script de Deploy - Site Novusio
# Sistema completo de instalação para VPS Ubuntu
# =============================================================================

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para exibir banner
show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              🚀 DEPLOY SITE NOVUSIO 🚀                      ║"
    echo "║                                                              ║"
    echo "║              Sistema de Instalação Automática                ║"
    echo "║              para VPS Ubuntu Server                          ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Função para log com timestamp
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Função para erro
error() {
    echo -e "${RED}[ERRO]${NC} $1" >&2
}

# Função para aviso
warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Função para info
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Verificar se é root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Este script não deve ser executado como root!"
        error "Execute com um usuário sudo e o script solicitará as permissões necessárias."
        exit 1
    fi
}

# Verificar se sudo está disponível
check_sudo() {
    if ! command -v sudo &> /dev/null; then
        error "sudo não está instalado. Instale sudo primeiro."
        exit 1
    fi
}

# Coletar informações do usuário
collect_info() {
    show_banner
    
    echo -e "${CYAN}📋 Coleta de Informações para Deploy${NC}"
    echo -e "${YELLOW}=============================================${NC}"
    echo ""
    
    # Solicitar domínio
    while true; do
        read -p "🌐 Digite o domínio (ex: exemplo.com): " DOMAIN
        if [[ -n "$DOMAIN" && "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]]; then
            break
        else
            error "Domínio inválido. Tente novamente."
        fi
    done
    
    # Solicitar usuário Linux
    while true; do
        read -p "👤 Digite o usuário Linux (atual: $(whoami)): " LINUX_USER
        if [[ -z "$LINUX_USER" ]]; then
            LINUX_USER=$(whoami)
            break
        elif id "$LINUX_USER" &>/dev/null; then
            break
        else
            error "Usuário '$LINUX_USER' não existe. Tente novamente."
        fi
    done
    
    # Solicitar repositório Git
    while true; do
        read -p "🔗 Digite a URL do repositório Git (HTTPS ou SSH): " GIT_REPO
        if [[ -n "$GIT_REPO" ]]; then
            break
        else
            error "URL do repositório é obrigatória."
        fi
    done
    
    # Solicitar porta (opcional)
    read -p "🔌 Digite a porta para o servidor (padrão: 3000): " SERVER_PORT
    if [[ -z "$SERVER_PORT" ]]; then
        SERVER_PORT=3000
    fi
    
    # Solicitar email para SSL
    read -p "📧 Digite seu email para certificados SSL (padrão: suporte@novusiopy.com): " SSL_EMAIL
    if [[ -z "$SSL_EMAIL" ]]; then
        SSL_EMAIL="suporte@novusiopy.com"
    fi
    
    # Definir caminhos
    PROJECT_PATH="/home/$LINUX_USER/site-novusio"
    NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
    NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
    SYSTEMD_SERVICE="/etc/systemd/system"
    
    # Confirmar informações
    echo ""
    echo -e "${CYAN}📋 Resumo das Configurações:${NC}"
    echo -e "${YELLOW}============================${NC}"
    echo "🌐 Domínio: $DOMAIN"
    echo "👤 Usuário: $LINUX_USER"
    echo "📁 Caminho: $PROJECT_PATH"
    echo "🔌 Porta: $SERVER_PORT"
    echo "📧 Email SSL: $SSL_EMAIL"
    echo "🔗 Repositório: $GIT_REPO"
    echo ""
    
    read -p "✅ Confirmar e continuar? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        info "Deploy cancelado pelo usuário."
        exit 0
    fi
}

# Instalar dependências do sistema
install_system_dependencies() {
    log "Instalando dependências do sistema..."
    
    sudo apt update
    
    # Instalar dependências essenciais
    sudo apt install -y \
        curl \
        wget \
        git \
        nginx \
        certbot \
        python3-certbot-nginx \
        nodejs \
        npm \
        sqlite3 \
        unzip \
        htop \
        ufw \
        fail2ban \
        supervisor
    
    log "Dependências do sistema instaladas com sucesso!"
}

# Configurar Node.js (versão LTS)
setup_nodejs() {
    log "Configurando Node.js..."
    
    # Verificar versão do Node.js
    NODE_VERSION=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || echo "0")
    
    if [[ "$NODE_VERSION" -lt 18 ]]; then
        log "Instalando Node.js LTS via NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        info "Node.js já está instalado (versão $(node --version))"
    fi
    
    # Verificar npm
    if ! command -v npm &> /dev/null; then
        sudo apt-get install -y npm
    fi
    
    log "Node.js configurado com sucesso!"
}

# Clonar repositório
clone_repository() {
    log "Clonando repositório do projeto..."
    
    # Remover diretório se existir
    if [[ -d "$PROJECT_PATH" ]]; then
        warning "Diretório $PROJECT_PATH já existe. Removendo..."
        sudo rm -rf "$PROJECT_PATH"
    fi
    
    # Clonar repositório
    sudo -u "$LINUX_USER" git clone "$GIT_REPO" "$PROJECT_PATH"
    
    # Definir permissões corretas
    sudo chown -R "$LINUX_USER:$LINUX_USER" "$PROJECT_PATH"
    sudo chmod -R 755 "$PROJECT_PATH"
    
    log "Repositório clonado com sucesso!"
}

# Instalar dependências do projeto
install_project_dependencies() {
    log "Instalando dependências do projeto..."
    
    cd "$PROJECT_PATH"
    
    # Instalar dependências do servidor
    sudo -u "$LINUX_USER" npm install
    
    # Instalar dependências do cliente
    cd "$PROJECT_PATH/client"
    sudo -u "$LINUX_USER" npm install
    
    log "Dependências do projeto instaladas com sucesso!"
}

# Criar arquivo .env para produção
create_env_file() {
    log "Criando arquivo .env para produção..."
    
    # Gerar JWT secret aleatório
    JWT_SECRET=$(openssl rand -base64 32)
    
    # Criar arquivo .env
    cat > "$PROJECT_PATH/.env" << EOF
# Configurações de Produção - Site Novusio
NODE_ENV=production
PORT=$SERVER_PORT

# JWT Configuration
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=24h

# Admin Configuration
ADMIN_EMAIL=admin@$DOMAIN
ADMIN_PASSWORD=$(openssl rand -base64 12)

# Database
DB_PATH=$PROJECT_PATH/database.sqlite

# Domain
DOMAIN=$DOMAIN
EOF
    
    # Definir permissões corretas
    sudo chown "$LINUX_USER:$LINUX_USER" "$PROJECT_PATH/.env"
    sudo chmod 600 "$PROJECT_PATH/.env"
    
    log "Arquivo .env criado com sucesso!"
}

# Construir projeto React
build_react_project() {
    log "Construindo projeto React..."
    
    cd "$PROJECT_PATH"
    
    # Fazer build do cliente
    sudo -u "$LINUX_USER" npm run build
    
    log "Projeto React construído com sucesso!"
}

# Inicializar banco de dados
init_database() {
    log "Inicializando banco de dados..."
    
    cd "$PROJECT_PATH"
    
    # Executar inicialização do banco
    sudo -u "$LINUX_USER" npm run init-db
    
    log "Banco de dados inicializado com sucesso!"
}

# Configurar Nginx
setup_nginx() {
    log "Configurando Nginx..."
    
    # Criar configuração do site
    cat > "/tmp/novusio.conf" << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Redirecionar www para não-www
    if (\$host = www.$DOMAIN) {
        return 301 http://$DOMAIN\$request_uri;
    }
    
    # Logs
    access_log /var/log/nginx/novusio_access.log;
    error_log /var/log/nginx/novusio_error.log;
    
    # Tamanho máximo de upload
    client_max_body_size 50M;
    
    # Timeout
    proxy_read_timeout 300s;
    proxy_connect_timeout 75s;
    
    # Proxy para aplicação Node.js
    location / {
        proxy_pass http://localhost:$SERVER_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Configurações específicas para API
    location /api/ {
        proxy_pass http://localhost:$SERVER_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # Mover configuração para sites-available
    sudo mv "/tmp/novusio.conf" "$NGINX_SITES_AVAILABLE/novusio"
    
    # Habilitar site
    sudo ln -sf "$NGINX_SITES_AVAILABLE/novusio" "$NGINX_SITES_ENABLED/"
    
    # Remover site padrão se existir
    sudo rm -f "$NGINX_SITES_ENABLED/default"
    
    # Testar configuração
    sudo nginx -t
    
    # Reiniciar Nginx
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    
    log "Nginx configurado com sucesso!"
}

# Configurar SSL com Certbot
setup_ssl() {
    if [[ -n "$SSL_EMAIL" ]]; then
        log "Configurando SSL com Certbot..."
        
        # Obter certificado SSL
        sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --email "$SSL_EMAIL" --agree-tos --non-interactive --redirect
        
        # Configurar renovação automática
        (sudo crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | sudo crontab -
        
        log "SSL configurado com sucesso!"
    else
        warning "Email SSL não fornecido. Pulando configuração SSL."
    fi
}

# Configurar serviço systemd
setup_systemd_service() {
    log "Configurando serviço systemd..."
    
    # Criar arquivo de serviço
    cat > "/tmp/novusio.service" << EOF
[Unit]
Description=Site Novusio - Node.js Application
After=network.target

[Service]
Type=simple
User=$LINUX_USER
WorkingDirectory=$PROJECT_PATH
Environment=NODE_ENV=production
ExecStart=/usr/bin/node server/server.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=novusio

# Configurações de segurança
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$PROJECT_PATH

[Install]
WantedBy=multi-user.target
EOF
    
    # Mover arquivo de serviço
    sudo mv "/tmp/novusio.service" "$SYSTEMD_SERVICE/"
    
    # Recarregar systemd e iniciar serviço
    sudo systemctl daemon-reload
    sudo systemctl enable novusio
    sudo systemctl start novusio
    
    log "Serviço systemd configurado com sucesso!"
}

# Configurar firewall
setup_firewall() {
    log "Configurando firewall (UFW)..."
    
    # Resetar firewall
    sudo ufw --force reset
    
    # Configurações padrão
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Permitir SSH
    sudo ufw allow ssh
    
    # Permitir HTTP e HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Ativar firewall
    sudo ufw --force enable
    
    log "Firewall configurado com sucesso!"
}

# Configurar Fail2ban
setup_fail2ban() {
    log "Configurando Fail2ban..."
    
    # Criar configuração para Nginx
    cat > "/tmp/nginx.conf" << EOF
[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/novusio_error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/novusio_access.log
maxretry = 10
EOF
    
    # Mover configuração
    sudo mv "/tmp/nginx.conf" "/etc/fail2ban/jail.d/nginx.conf"
    
    # Reiniciar Fail2ban
    sudo systemctl restart fail2ban
    sudo systemctl enable fail2ban
    
    log "Fail2ban configurado com sucesso!"
}

# Verificar instalação
verify_installation() {
    log "Verificando instalação..."
    
    # Aguardar serviço iniciar
    sleep 5
    
    # Verificar status do serviço
    if sudo systemctl is-active --quiet novusio; then
        log "✅ Serviço novusio está rodando"
    else
        error "❌ Serviço novusio não está rodando"
        sudo systemctl status novusio
        return 1
    fi
    
    # Verificar Nginx
    if sudo systemctl is-active --quiet nginx; then
        log "✅ Nginx está rodando"
    else
        error "❌ Nginx não está rodando"
        return 1
    fi
    
    # Testar conectividade
    if curl -f -s "http://localhost:$SERVER_PORT/api/health" > /dev/null; then
        log "✅ API está respondendo"
    else
        warning "⚠️  API não está respondendo corretamente"
    fi
    
    log "Verificação concluída!"
}

# Exibir informações finais
show_final_info() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              ✅ DEPLOY CONCLUÍDO COM SUCESSO! ✅             ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${CYAN}📋 Informações da Instalação:${NC}"
    echo -e "${YELLOW}============================${NC}"
    echo "🌐 Site: http://$DOMAIN"
    echo "👤 Usuário: $LINUX_USER"
    echo "📁 Projeto: $PROJECT_PATH"
    echo "🔌 Porta: $SERVER_PORT"
    echo ""
    
    echo -e "${CYAN}🔧 Comandos Úteis:${NC}"
    echo -e "${YELLOW}==================${NC}"
    echo "📊 Status do serviço: sudo systemctl status novusio"
    echo "🔄 Reiniciar serviço: sudo systemctl restart novusio"
    echo "📝 Ver logs: sudo journalctl -u novusio -f"
    echo "🌐 Status Nginx: sudo systemctl status nginx"
    echo "🔒 Status SSL: sudo certbot certificates"
    echo ""
    
    echo -e "${CYAN}📧 Credenciais de Acesso:${NC}"
    echo -e "${YELLOW}========================${NC}"
    echo "📧 Email: admin@$DOMAIN"
    echo "🔑 Senha: $(grep ADMIN_PASSWORD "$PROJECT_PATH/.env" | cut -d'=' -f2)"
    echo ""
    echo -e "${RED}⚠️  IMPORTANTE: Altere as credenciais após o primeiro login!${NC}"
    echo ""
    
    echo -e "${GREEN}🎉 Deploy concluído! Acesse http://$DOMAIN para ver seu site.${NC}"
}

# Função principal
main() {
    check_root
    check_sudo
    collect_info
    
    log "Iniciando processo de deploy..."
    
    install_system_dependencies
    setup_nodejs
    clone_repository
    install_project_dependencies
    create_env_file
    build_react_project
    init_database
    setup_nginx
    setup_ssl
    setup_systemd_service
    setup_firewall
    setup_fail2ban
    
    verify_installation
    show_final_info
}

# Executar função principal
main "$@"
