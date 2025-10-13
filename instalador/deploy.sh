#!/bin/bash

# =============================================================================
# NOVUSIO - SCRIPT DE DEPLOY AUTOMÁTICO PARA VPS
# =============================================================================
# Este script instala e configura automaticamente o sistema Novusio em um VPS
# Inclui: Nginx, PM2, SSL, Firewall, Backup e Monitoramento
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

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Banner
show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              🚀 NOVUSIO DEPLOY AUTOMÁTICO 🚀                ║"
    echo "║                                                              ║"
    echo "║              Deploy completo para VPS Ubuntu/Debian          ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Menu principal
show_menu() {
    echo -e "${CYAN}📋 MENU PRINCIPAL - NOVUSIO${NC}"
    echo "=================================="
    echo "1. 🚀 Deploy Completo (Nova Instalação)"
    echo "2. 🔄 Atualizar Aplicação"
    echo "3. 🗑️  Remover Projeto Completamente"
    echo "4. 📊 Status do Sistema"
    echo "5. 🔧 Manutenção Rápida"
    echo "6. 📝 Logs e Monitoramento"
    echo "7. ❌ Sair"
    echo ""
    read -p "Escolha uma opção [1-7]: " MENU_CHOICE
}

# Deploy completo (função existente)
deploy_complete() {
    log "🚀 Iniciando deploy completo..."
    collect_info
    check_dns
    update_system
    install_packages
    setup_firewall
    create_user
    clone_repository
    build_application
    setup_environment
    setup_pm2
    setup_nginx
    setup_ssl
    setup_backup
    setup_monitoring
    setup_logrotate
    init_database
    restart_services
    verify_installation
    show_final_info
}

# Atualizar aplicação
update_application() {
    echo -e "${CYAN}🔄 ATUALIZAÇÃO DA APLICAÇÃO${NC}"
    echo "=================================="
    
    # Verificar se o projeto existe
    if [[ ! -d "/opt/novusio" ]]; then
        error "❌ Projeto não encontrado em /opt/novusio"
    fi
    
    log "🔄 Iniciando atualização da aplicação..."
    
    cd /opt/novusio
    
    # Backup antes da atualização
    log "💾 Criando backup antes da atualização..."
    /usr/local/bin/novusio-backup.sh 2>/dev/null || true
    
    # Parar aplicação
    log "⏹️ Parando aplicação..."
    sudo -u novusio pm2 stop novusio-server || true
    
    # Atualizar código
    log "📥 Atualizando código do repositório..."
    git pull origin main
    
    # Instalar dependências
    log "📦 Instalando dependências..."
    npm ci --production
    
    if [[ -d "client" ]]; then
        log "📦 Instalando dependências do cliente..."
        cd client
        npm ci
        npm run build
        cd ..
    fi
    
    # Verificar configurações
    if [[ ! -f ".env" ]]; then
        warning "⚠️ Arquivo .env não encontrado, gerando novo..."
        
        # Gerar secrets seguros
        JWT_SECRET=$(openssl rand -base64 48 | tr -d '\n')
        SESSION_SECRET=$(openssl rand -base64 32 | tr -d '\n')
        
        log "✓ JWT Secret gerado: ${JWT_SECRET:0:10}..."
        log "✓ Session Secret gerado: ${SESSION_SECRET:0:10}..."
        
        # Detectar domínio da configuração Nginx
        DOMAIN=$(grep -h "server_name" /etc/nginx/sites-available/* 2>/dev/null | grep -v "www" | awk '{print $2}' | sed 's/;//' | head -1)
        [[ -z "$DOMAIN" ]] && DOMAIN="localhost"
        
        # Criar arquivo .env
        cat > .env << EOF
# Configurações geradas durante atualização
NODE_ENV=production
PORT=3000
JWT_SECRET=$JWT_SECRET
SESSION_SECRET=$SESSION_SECRET
DB_PATH=/opt/novusio/database.sqlite
UPLOAD_PATH=/opt/novusio/uploads
DOMAIN=$DOMAIN
BASE_URL=https://$DOMAIN
EOF
        
        chown novusio:novusio .env
        chmod 600 .env
        
        log "✓ Arquivo .env criado com secrets seguros"
        warning "⚠️ Revise e configure o arquivo .env conforme necessário!"
    fi
    
    # Reiniciar aplicação
    log "🔄 Reiniciando aplicação..."
    sudo -u novusio pm2 start ecosystem.config.js --env production
    sudo -u novusio pm2 save
    
    # Verificar status
    log "✅ Verificando status da aplicação..."
    sleep 5
    
    if pm2 list | grep -q "novusio-server.*online"; then
        log "✅ Aplicação atualizada e rodando com sucesso!"
    else
        error "❌ Falha ao iniciar a aplicação após atualização"
    fi
    
    echo -e "${GREEN}🎉 Atualização concluída com sucesso!${NC}"
}

# Remover projeto completamente
remove_project() {
    echo -e "${RED}🗑️ REMOÇÃO COMPLETA DO PROJETO${NC}"
    echo "=================================="
    echo -e "${YELLOW}⚠️ ATENÇÃO: Esta ação irá remover completamente o projeto Novusio!${NC}"
    echo -e "${YELLOW}   Isso inclui:${NC}"
    echo -e "${YELLOW}   - Aplicação e código fonte${NC}"
    echo -e "${YELLOW}   - Banco de dados${NC}"
    echo -e "${YELLOW}   - Arquivos de upload${NC}"
    echo -e "${YELLOW}   - Configurações${NC}"
    echo -e "${YELLOW}   - Logs${NC}"
    echo ""
    read -p "Tem certeza que deseja continuar? Digite 'CONFIRMAR' para prosseguir: " CONFIRMATION
    
    if [[ "$CONFIRMATION" != "CONFIRMAR" ]]; then
        echo -e "${GREEN}✅ Operação cancelada${NC}"
        return
    fi
    
    log "🗑️ Iniciando remoção completa do projeto..."
    
    # Parar aplicação
    log "⏹️ Parando aplicação..."
    sudo -u novusio pm2 stop novusio-server 2>/dev/null || true
    sudo -u novusio pm2 delete novusio-server 2>/dev/null || true
    
    # Remover PM2 do startup
    sudo -u novusio pm2 unstartup systemd 2>/dev/null || true
    
    # Remover configurações do Nginx - usar variável de domínio se disponível
    log "🌐 Removendo configurações do Nginx..."
    
    # Tentar encontrar a configuração do Novusio
    NGINX_CONFIG=$(find /etc/nginx/sites-available/ -name "*.conf" -o -name "novusio*" 2>/dev/null | head -1)
    if [[ -z "$NGINX_CONFIG" ]]; then
        # Buscar por configurações que contenham "novusio" no conteúdo
        NGINX_CONFIG=$(grep -l "novusio" /etc/nginx/sites-available/* 2>/dev/null | head -1)
    fi
    
    if [[ -n "$NGINX_CONFIG" ]]; then
        NGINX_FILENAME=$(basename "$NGINX_CONFIG")
        rm -f "/etc/nginx/sites-enabled/$NGINX_FILENAME"
        rm -f "/etc/nginx/sites-available/$NGINX_FILENAME"
        log "✓ Configuração Nginx removida: $NGINX_FILENAME"
    else
        warning "⚠️ Configuração Nginx do Novusio não encontrada"
    fi
    
    # Testar e recarregar Nginx
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
    else
        warning "⚠️ Erro ao recarregar Nginx, mas continuando remoção..."
    fi
    
    # Remover certificados SSL (opcional)
    read -p "Deseja remover os certificados SSL? (y/N): " REMOVE_SSL
    if [[ "$REMOVE_SSL" =~ ^[Yy]$ ]]; then
        log "🔒 Removendo certificados SSL..."
        certbot delete --cert-name $(cat /etc/nginx/sites-available/novusio 2>/dev/null | grep server_name | head -1 | awk '{print $2}' | sed 's/;//') --non-interactive 2>/dev/null || true
    fi
    
    # Remover diretórios e arquivos
    log "🗑️ Removendo arquivos do projeto..."
    rm -rf /opt/novusio
    rm -rf /var/log/novusio
    rm -rf /opt/backups/novusio
    
    # Remover scripts de sistema
    log "🔧 Removendo scripts de sistema..."
    rm -f /usr/local/bin/novusio-backup.sh
    rm -f /usr/local/bin/novusio-monitor.sh
    rm -f /etc/systemd/system/novusio.service
    
    # Remover usuário (opcional)
    read -p "Deseja remover o usuário 'novusio'? (y/N): " REMOVE_USER
    if [[ "$REMOVE_USER" =~ ^[Yy]$ ]]; then
        log "👤 Removendo usuário novusio..."
        userdel -r novusio 2>/dev/null || true
    fi
    
    # Remover crontabs
    log "⏰ Removendo tarefas agendadas..."
    crontab -l 2>/dev/null | grep -v novusio | crontab - 2>/dev/null || true
    
    # Remover configurações do Fail2ban
    log "🛡️ Removendo configurações do Fail2ban..."
    rm -f /etc/fail2ban/jail.d/novusio.conf
    rm -f /etc/fail2ban/filter.d/novusio-*.conf
    systemctl reload fail2ban 2>/dev/null || true
    
    log "✅ Projeto removido completamente!"
    echo -e "${GREEN}🎉 Remoção concluída com sucesso!${NC}"
}

# Status do sistema
show_system_status() {
    echo -e "${CYAN}📊 STATUS DO SISTEMA${NC}"
    echo "=================================="
    
    # Status da aplicação
    echo -e "${BLUE}🔄 Status da Aplicação:${NC}"
    if pm2 list | grep -q "novusio-server.*online"; then
        echo -e "  ${GREEN}✅ Aplicação rodando${NC}"
        pm2 list | grep novusio-server
    else
        echo -e "  ${RED}❌ Aplicação não está rodando${NC}"
    fi
    
    echo ""
    
    # Status dos serviços
    echo -e "${BLUE}🌐 Status dos Serviços:${NC}"
    services=("nginx" "fail2ban")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "  ${GREEN}✅ $service ativo${NC}"
        else
            echo -e "  ${RED}❌ $service inativo${NC}"
        fi
    done
    
    echo ""
    
    # Recursos do sistema
    echo -e "${BLUE}💻 Recursos do Sistema:${NC}"
    echo "  Memória: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
    echo "  Disco: $(df -h / | awk 'NR==2{print $5}') usado"
    echo "  CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
    
    echo ""
    
    # SSL
    echo -e "${BLUE}🔒 Certificado SSL:${NC}"
    if [[ -f "/etc/letsencrypt/live/*/fullchain.pem" ]]; then
        DOMAIN=$(ls /etc/letsencrypt/live/ | head -1)
        EXPIRY=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" 2>/dev/null | cut -d= -f2)
        if [[ -n "$EXPIRY" ]]; then
            echo -e "  ${GREEN}✅ Certificado válido até: $EXPIRY${NC}"
        else
            echo -e "  ${YELLOW}⚠️ Certificado encontrado mas não foi possível verificar expiração${NC}"
        fi
    else
        echo -e "  ${RED}❌ Certificado SSL não encontrado${NC}"
    fi
    
    echo ""
    
    # Último backup
    echo -e "${BLUE}💾 Último Backup:${NC}"
    if [[ -d "/opt/backups/novusio" ]]; then
        LAST_BACKUP=$(find /opt/backups/novusio -name "*.sqlite" -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        if [[ -n "$LAST_BACKUP" ]]; then
            BACKUP_DATE=$(stat -c %y "$LAST_BACKUP" 2>/dev/null || stat -f %Sm "$LAST_BACKUP" 2>/dev/null)
            echo -e "  ${GREEN}✅ $BACKUP_DATE${NC}"
        else
            echo -e "  ${YELLOW}⚠️ Nenhum backup encontrado${NC}"
        fi
    else
        echo -e "  ${RED}❌ Diretório de backup não existe${NC}"
    fi
}

# Manutenção rápida
quick_maintenance() {
    echo -e "${CYAN}🔧 MANUTENÇÃO RÁPIDA${NC}"
    echo "=================================="
    
    log "🔧 Iniciando manutenção rápida..."
    
    # Reiniciar aplicação
    log "🔄 Reiniciando aplicação..."
    cd /opt/novusio
    sudo -u novusio pm2 restart novusio-server
    
    # Recarregar Nginx
    log "🌐 Recarregando Nginx..."
    systemctl reload nginx
    
    # Limpar logs antigos
    log "🧹 Limpando logs antigos..."
    find /var/log/novusio -name "*.log" -mtime +30 -delete 2>/dev/null || true
    find /var/log/nginx -name "*.log.*" -mtime +30 -delete 2>/dev/null || true
    
    # Limpar cache do sistema
    log "🧹 Limpando cache do sistema..."
    apt-get autoremove -y 2>/dev/null || true
    apt-get autoclean 2>/dev/null || true
    
    # Verificar e corrigir permissões
    log "🔐 Verificando permissões..."
    if [[ -d "/opt/novusio" ]]; then
        chown -R novusio:novusio /opt/novusio
        chmod 600 /opt/novusio/.env 2>/dev/null || true
    fi
    
    log "✅ Manutenção rápida concluída!"
}

# Logs e monitoramento
show_logs() {
    echo -e "${CYAN}📝 LOGS E MONITORAMENTO${NC}"
    echo "=================================="
    echo "1. 📋 Logs da Aplicação (PM2)"
    echo "2. 🌐 Logs do Nginx"
    echo "3. 🛡️ Logs do Fail2ban"
    echo "4. 💾 Logs de Backup"
    echo "5. 📊 Logs de Monitoramento"
    echo "6. 🔍 Logs do Sistema"
    echo "7. ⬅️ Voltar"
    echo ""
    read -p "Escolha uma opção [1-7]: " LOG_CHOICE
    
    case $LOG_CHOICE in
        1)
            echo -e "${BLUE}📋 Logs da Aplicação (últimas 50 linhas):${NC}"
            sudo -u novusio pm2 logs --lines 50
            ;;
        2)
            echo -e "${BLUE}🌐 Logs do Nginx (últimas 50 linhas):${NC}"
            tail -50 /var/log/nginx/access.log
            echo ""
            echo -e "${BLUE}🌐 Logs de Erro do Nginx (últimas 20 linhas):${NC}"
            tail -20 /var/log/nginx/error.log
            ;;
        3)
            echo -e "${BLUE}🛡️ Status do Fail2ban:${NC}"
            fail2ban-client status
            ;;
        4)
            echo -e "${BLUE}💾 Logs de Backup (últimas 20 linhas):${NC}"
            tail -20 /var/log/novusio-backup.log 2>/dev/null || echo "Nenhum log de backup encontrado"
            ;;
        5)
            echo -e "${BLUE}📊 Logs de Monitoramento (últimas 20 linhas):${NC}"
            tail -20 /var/log/novusio-monitor.log 2>/dev/null || echo "Nenhum log de monitoramento encontrado"
            ;;
        6)
            echo -e "${BLUE}🔍 Logs do Sistema (últimas 30 linhas):${NC}"
            journalctl -u nginx -u fail2ban --lines 30 --no-pager
            ;;
        7)
            return
            ;;
        *)
            echo -e "${RED}❌ Opção inválida${NC}"
            ;;
    esac
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Verificar se está rodando como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este script deve ser executado como root. Use: sudo $0"
    fi
    log "✓ Executando como root"
}

# Coletar informações do usuário
collect_info() {
    echo -e "${CYAN}📋 CONFIGURAÇÃO INICIAL${NC}"
    echo "=================================="
    
    # Informações do sistema
    read -p "🌐 Domínio (ex: novusio.com): " DOMAIN
    read -p "📧 Email para SSL (Let's Encrypt): " EMAIL
    read -p "👤 Usuário do sistema (ex: novusio): " USERNAME
    read -p "🔧 Porta da aplicação [3000]: " APP_PORT
    APP_PORT=${APP_PORT:-3000}
    read -p "📁 Diretório do projeto [/opt/novusio]: " PROJECT_DIR
    PROJECT_DIR=${PROJECT_DIR:-/opt/novusio}
    read -p "🔗 Repositório Git: " GIT_REPO
    
    # Validações básicas
    if [[ -z "$DOMAIN" || -z "$EMAIL" || -z "$USERNAME" || -z "$GIT_REPO" ]]; then
        error "Todos os campos obrigatórios devem ser preenchidos!"
    fi
    
    # Validar formato do email
    if [[ ! "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        error "Email inválido!"
    fi
    
    # Validar formato do domínio
    if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$ ]]; then
        error "Domínio inválido!"
    fi
    
    # Verificar se o diretório já existe e não é vazio
    if [[ -d "$PROJECT_DIR" ]] && [[ "$(ls -A $PROJECT_DIR)" ]]; then
        warning "⚠️ O diretório $PROJECT_DIR já existe e não está vazio!"
        read -p "Deseja continuar mesmo assim? (y/N): " CONTINUE_DIR
        if [[ ! "$CONTINUE_DIR" =~ ^[Yy]$ ]]; then
            error "Deploy cancelado. Escolha um diretório diferente."
        fi
    fi
    
    # Verificar se a porta já está em uso
    if netstat -tuln 2>/dev/null | grep -q ":$APP_PORT " || ss -tuln 2>/dev/null | grep -q ":$APP_PORT "; then
        warning "⚠️ A porta $APP_PORT já está em uso por outro processo!"
        read -p "Deseja continuar mesmo assim? (y/N): " CONTINUE_PORT
        if [[ ! "$CONTINUE_PORT" =~ ^[Yy]$ ]]; then
            error "Deploy cancelado. Escolha uma porta diferente."
        fi
    fi
    
    # Verificar se o usuário já existe
    if id "$USERNAME" &>/dev/null; then
        warning "⚠️ O usuário $USERNAME já existe no sistema!"
        read -p "Deseja usar este usuário existente? (Y/n): " USE_EXISTING_USER
        if [[ "$USE_EXISTING_USER" =~ ^[Nn]$ ]]; then
            error "Deploy cancelado. Escolha um usuário diferente."
        fi
    fi
    
    # Verificar se já existe configuração Nginx para este domínio
    if [[ -f "/etc/nginx/sites-available/$DOMAIN" ]] || [[ -f "/etc/nginx/sites-enabled/$DOMAIN" ]]; then
        warning "⚠️ Já existe configuração Nginx para o domínio $DOMAIN!"
        read -p "Deseja sobrescrever? (y/N): " OVERWRITE_NGINX
        if [[ ! "$OVERWRITE_NGINX" =~ ^[Yy]$ ]]; then
            error "Deploy cancelado. O domínio já está configurado."
        fi
    fi
    
    log "✓ Informações coletadas e validadas com sucesso"
}

# Verificar DNS
check_dns() {
    log "🔍 Verificando DNS do domínio $DOMAIN..."
    
    # Verificar se o domínio aponta para este servidor
    SERVER_IP=$(curl -s ifconfig.me)
    DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)
    
    if [[ "$DOMAIN_IP" != "$SERVER_IP" ]]; then
        warning "⚠️  ATENÇÃO: O domínio $DOMAIN ($DOMAIN_IP) não aponta para este servidor ($SERVER_IP)"
        warning "   Certifique-se de que o DNS está configurado corretamente antes de continuar"
        read -p "   Deseja continuar mesmo assim? (y/N): " CONTINUE_DNS
        if [[ ! "$CONTINUE_DNS" =~ ^[Yy]$ ]]; then
            error "Deploy cancelado. Configure o DNS primeiro."
        fi
    else
        log "✓ DNS configurado corretamente"
    fi
}

# Atualizar sistema
update_system() {
    log "🔄 Atualizando sistema..."
    apt-get update -y
    apt-get upgrade -y
    log "✓ Sistema atualizado"
}

# Instalar pacotes essenciais
install_packages() {
    log "📦 Instalando pacotes essenciais..."
    
    # Pacotes básicos
    apt-get install -y \
        curl \
        git \
        nginx \
        ufw \
        snapd \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        unzip \
        htop \
        nano \
        vim \
        wget \
        jq \
        fail2ban
    
    # Instalar Node.js 18.x
    log "📦 Instalando Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    
    # Instalar PM2 globalmente
    npm install -g pm2
    
    log "✓ Pacotes instalados com sucesso"
}

# Configurar firewall
setup_firewall() {
    log "🔥 Configurando firewall (UFW)..."
    
    # Verificar se UFW já está ativo
    if ufw status | grep -q "Status: active"; then
        warning "⚠️ Firewall UFW já está ativo. Adicionando apenas regras necessárias..."
        
        # Não resetar - apenas adicionar regras
        ufw allow ssh 2>/dev/null || true
        ufw allow 22/tcp 2>/dev/null || true
        ufw allow 80/tcp 2>/dev/null || true
        ufw allow 443/tcp 2>/dev/null || true
        
        if [[ "$APP_PORT" != "80" && "$APP_PORT" != "443" ]]; then
            ufw allow $APP_PORT/tcp 2>/dev/null || true
        fi
    else
        # Configuração inicial do firewall
        log "🔥 Configurando firewall pela primeira vez..."
        
        # Políticas padrão
        ufw default deny incoming
        ufw default allow outgoing
        
        # Permitir SSH
        ufw allow ssh
        ufw allow 22/tcp
        
        # Permitir HTTP e HTTPS
        ufw allow 80/tcp
        ufw allow 443/tcp
        
        # Permitir porta da aplicação (se diferente de 80/443)
        if [[ "$APP_PORT" != "80" && "$APP_PORT" != "443" ]]; then
            ufw allow $APP_PORT/tcp
        fi
        
        # Habilitar firewall
        ufw --force enable
    fi
    
    log "✓ Firewall configurado"
}

# Criar usuário do sistema
create_user() {
    log "👤 Criando usuário $USERNAME..."
    
    # Verificar se usuário já existe
    if id "$USERNAME" &>/dev/null; then
        warning "Usuário $USERNAME já existe"
    else
        useradd -m -s /bin/bash $USERNAME
        usermod -aG sudo $USERNAME
        
        # Configurar SSH para o usuário
        mkdir -p /home/$USERNAME/.ssh
        chmod 700 /home/$USERNAME/.ssh
        chown $USERNAME:$USERNAME /home/$USERNAME/.ssh
        
        log "✓ Usuário $USERNAME criado"
    fi
}

# Clonar repositório
clone_repository() {
    log "📥 Clonando repositório $GIT_REPO..."
    
    # Criar diretório se não existir
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
    
    # Remover diretório se já existir
    if [[ -d ".git" ]]; then
        warning "Repositório já existe. Fazendo pull..."
        git pull origin main
    else
        git clone $GIT_REPO .
    fi
    
    # Configurar permissões
    chown -R $USERNAME:$USERNAME $PROJECT_DIR
    
    log "✓ Repositório clonado em $PROJECT_DIR"
}

# Instalar dependências e build
build_application() {
    log "🔨 Instalando dependências e fazendo build..."
    
    cd $PROJECT_DIR
    
    # Instalar dependências do servidor
    log "📦 Instalando dependências do servidor..."
    npm ci --production
    
    # Instalar dependências do cliente
    if [[ -d "client" ]]; then
        log "📦 Instalando dependências do cliente..."
        cd client
        npm ci
        cd ..
    fi
    
    # Build de produção
    log "🏗️  Fazendo build de produção..."
    
    # Configurar variáveis de ambiente para build
    export NODE_ENV=production
    export NODE_OPTIONS="--max-old-space-size=4096"
    
    # Build do cliente
    if [[ -d "client" ]]; then
        cd client
        npm run build
        cd ..
    fi
    
    log "✓ Build concluído com sucesso"
}

# Configurar variáveis de ambiente
setup_environment() {
    log "⚙️  Configurando variáveis de ambiente..."
    
    cd $PROJECT_DIR
    
    # Gerar secrets seguros
    log "🔐 Gerando secrets de segurança..."
    JWT_SECRET=$(openssl rand -base64 48 | tr -d '\n')
    SESSION_SECRET=$(openssl rand -base64 32 | tr -d '\n')
    
    log "✓ JWT Secret gerado: ${JWT_SECRET:0:10}... (48 bytes)"
    log "✓ Session Secret gerado: ${SESSION_SECRET:0:10}... (32 bytes)"
    
    # Criar arquivo .env se não existir
    if [[ ! -f ".env" ]]; then
        log "📝 Criando arquivo .env..."
        
        cp .env.example .env 2>/dev/null || cat > .env << EOF
# =============================================================================
# CONFIGURAÇÕES DE PRODUÇÃO - NOVUSIO
# =============================================================================
# Arquivo gerado automaticamente em: $(date)
# =============================================================================

# =============================================================================
# CONFIGURAÇÕES GERAIS
# =============================================================================
NODE_ENV=production
PORT=$APP_PORT
HOST=0.0.0.0

# =============================================================================
# CONFIGURAÇÕES DO BANCO DE DADOS
# =============================================================================
DB_PATH=$PROJECT_DIR/database.sqlite

# =============================================================================
# CONFIGURAÇÕES DE UPLOAD
# =============================================================================
UPLOAD_PATH=$PROJECT_DIR/uploads
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=jpg,jpeg,png,gif,pdf,doc,docx

# =============================================================================
# CONFIGURAÇÕES DE AUTENTICAÇÃO
# =============================================================================
# JWT Secret - Gerado automaticamente (NÃO compartilhe!)
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# Bcrypt salt rounds
BCRYPT_ROUNDS=12

# Session Secret - Gerado automaticamente
SESSION_SECRET=$SESSION_SECRET
SESSION_COOKIE_SECURE=true
SESSION_COOKIE_HTTP_ONLY=true
SESSION_COOKIE_SAME_SITE=strict

# =============================================================================
# CONFIGURAÇÕES DE EMAIL (Configure para envio de emails)
# =============================================================================
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_SECURE=false
EMAIL_USER=
EMAIL_PASS=

# Emails de contato
CONTACT_EMAIL=$EMAIL
ADMIN_EMAIL=$EMAIL

# =============================================================================
# CONFIGURAÇÕES DE DOMÍNIO E URL
# =============================================================================
DOMAIN=$DOMAIN
BASE_URL=https://$DOMAIN
API_URL=https://$DOMAIN/api
ADMIN_URL=https://$DOMAIN/admin

# =============================================================================
# CONFIGURAÇÕES DE SEGURANÇA
# =============================================================================
# CORS
CORS_ORIGIN=https://$DOMAIN
CORS_CREDENTIALS=true

# Rate limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# =============================================================================
# CONFIGURAÇÕES DE LOG
# =============================================================================
LOG_LEVEL=info
LOG_FILE=/var/log/novusio/app.log
LOG_MAX_SIZE=10m
LOG_MAX_FILES=5

# =============================================================================
# CONFIGURAÇÕES DE CACHE
# =============================================================================
CACHE_TTL=3600

# =============================================================================
# CONFIGURAÇÕES DE BACKUP
# =============================================================================
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30
BACKUP_PATH=/opt/backups/novusio

# =============================================================================
# CONFIGURAÇÕES ESPECÍFICAS DA APLICAÇÃO
# =============================================================================
# Tamanho máximo do body da requisição
MAX_BODY_SIZE=10mb

# Timeout das requisições
REQUEST_TIMEOUT=30000

# Número máximo de conexões simultâneas
MAX_CONNECTIONS=1000

# Configurações de upload específicas
ALLOWED_IMAGE_TYPES=jpg,jpeg,png,gif,webp
ALLOWED_DOCUMENT_TYPES=pdf,doc,docx,txt
MAX_IMAGE_SIZE=5242880
MAX_DOCUMENT_SIZE=10485760

# =============================================================================
# CONFIGURAÇÕES DE PERFORMANCE
# =============================================================================
# Cluster mode
CLUSTER_MODE=true
CLUSTER_WORKERS=auto

# Memory settings
NODE_OPTIONS=--max-old-space-size=2048

# =============================================================================
# CONFIGURAÇÕES DE MANUTENÇÃO
# =============================================================================
# Modo de manutenção
MAINTENANCE_MODE=false
MAINTENANCE_MESSAGE=Site em manutenção. Voltaremos em breve!

# =============================================================================
# CONFIGURAÇÕES DE SSL/TLS
# =============================================================================
SSL_ENABLED=true
SSL_REDIRECT=true
HSTS_ENABLED=true
HSTS_MAX_AGE=31536000

# =============================================================================
# FIM DAS CONFIGURAÇÕES
# =============================================================================
EOF
        
        log "✓ Arquivo .env criado com sucesso"
    else
        warning "⚠️ Arquivo .env já existe, não será sobrescrito"
        log "💡 Para regenerar secrets, delete o arquivo .env e execute novamente"
    fi
    
    # Configurar permissões
    chown $USERNAME:$USERNAME .env
    chmod 600 .env
    
    log "✓ Variáveis de ambiente configuradas com segurança"
    
    # Salvar secrets em arquivo seguro para referência
    SECRETS_FILE="$PROJECT_DIR/.secrets-backup-$(date +%Y%m%d_%H%M%S).txt"
    cat > "$SECRETS_FILE" << EOF
# BACKUP DE SECRETS - NOVUSIO
# Gerado em: $(date)
# IMPORTANTE: Guarde este arquivo em local seguro e delete do servidor!

JWT_SECRET=$JWT_SECRET
SESSION_SECRET=$SESSION_SECRET

# Para usar estes secrets novamente, adicione-os ao arquivo .env
EOF
    
    chown $USERNAME:$USERNAME "$SECRETS_FILE"
    chmod 400 "$SECRETS_FILE"
    
    info "📋 Backup dos secrets salvo em: $SECRETS_FILE"
    info "⚠️  IMPORTANTE: Salve este arquivo em local seguro e delete do servidor!"
}

# Configurar PM2
setup_pm2() {
    log "🔄 Configurando PM2..."
    
    cd $PROJECT_DIR
    
    # Criar arquivo de configuração PM2
    cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'novusio-server',
    script: 'server/server.js',
    cwd: '$PROJECT_DIR',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: $APP_PORT
    },
    error_file: '/var/log/novusio/error.log',
    out_file: '/var/log/novusio/out.log',
    log_file: '/var/log/novusio/combined.log',
    time: true,
    max_memory_restart: '1G',
    node_args: '--max-old-space-size=2048',
    restart_delay: 4000,
    max_restarts: 10,
    min_uptime: '10s'
  }]
};
EOF
    
    # Criar diretório de logs
    mkdir -p /var/log/novusio
    chown $USERNAME:$USERNAME /var/log/novusio
    
    # Iniciar aplicação com PM2
    sudo -u $USERNAME pm2 start ecosystem.config.js
    sudo -u $USERNAME pm2 save
    sudo -u $USERNAME pm2 startup systemd -u $USERNAME --hp /home/$USERNAME
    
    log "✓ PM2 configurado e aplicação iniciada"
}

# Configurar Nginx
setup_nginx() {
    log "🌐 Configurando Nginx..."
    
    # NÃO remover configuração padrão se houver outros sites
    if [[ $(ls -A /etc/nginx/sites-enabled/ | wc -l) -gt 1 ]]; then
        warning "⚠️ Existem outros sites configurados. Mantendo configuração padrão."
    else
        # Remover configuração padrão apenas se for o único site
        rm -f /etc/nginx/sites-enabled/default
    fi
    
    # Criar configuração do site com nome específico do domínio
    cat > /etc/nginx/sites-available/$DOMAIN << EOF
# Rate limiting
limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone \$binary_remote_addr zone=login:10m rate=1r/s;

# Upstream para a aplicação
upstream novusio_backend {
    server 127.0.0.1:$APP_PORT;
    keepalive 32;
}

# Redirecionamento HTTP para HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Certbot challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Redirecionar todo o resto para HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# Configuração HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Root directory
    root /var/www/html;
    index index.html index.htm;
    
    # Static files (React build)
    location / {
        try_files \$uri \$uri/ @backend;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Backend API
    location @backend {
        proxy_pass http://novusio_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # API routes with rate limiting
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://novusio_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # Admin login with strict rate limiting
    location /api/auth/login {
        limit_req zone=login burst=5 nodelay;
        
        proxy_pass http://novusio_backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Upload files
    location /uploads/ {
        alias $PROJECT_DIR/uploads/;
        expires 1y;
        add_header Cache-Control "public";
        
        # Security
        location ~ \.(php|jsp|asp|sh|cgi)$ {
            deny all;
        }
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.(env|config|sql|log)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
    
    # Habilitar site com nome específico
    ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    
    # Testar configuração
    if nginx -t; then
        log "✓ Nginx configurado com sucesso"
    else
        error "❌ Erro na configuração do Nginx. Revertendo..."
        rm -f /etc/nginx/sites-available/$DOMAIN
        rm -f /etc/nginx/sites-enabled/$DOMAIN
        exit 1
    fi
}

# Configurar SSL com Certbot
setup_ssl() {
    log "🔒 Configurando SSL com Let's Encrypt..."
    
    # Instalar Certbot
    apt-get install -y certbot python3-certbot-nginx
    
    # Obter certificado SSL
    certbot --nginx -d $DOMAIN -d www.$DOMAIN \
        --non-interactive --agree-tos --email $EMAIL \
        --redirect
    
    # Configurar renovação automática
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    log "✓ SSL configurado com sucesso"
}

# Configurar backup automático
setup_backup() {
    log "💾 Configurando backup automático..."
    
    # Criar script de backup
    cat > /usr/local/bin/novusio-backup.sh << EOF
#!/bin/bash
# Script de backup automático do Novusio

BACKUP_DIR="/opt/backups/novusio"
DATE=\$(date +%Y%m%d_%H%M%S)
PROJECT_DIR="$PROJECT_DIR"

# Criar diretório de backup
mkdir -p \$BACKUP_DIR

# Backup do banco de dados
if [[ -f "\$PROJECT_DIR/database.sqlite" ]]; then
    cp "\$PROJECT_DIR/database.sqlite" "\$BACKUP_DIR/database_\$DATE.sqlite"
fi

# Backup dos uploads
if [[ -d "\$PROJECT_DIR/uploads" ]]; then
    tar -czf "\$BACKUP_DIR/uploads_\$DATE.tar.gz" -C "\$PROJECT_DIR" uploads/
fi

# Backup do código (configurações importantes)
tar -czf "\$BACKUP_DIR/config_\$DATE.tar.gz" -C "\$PROJECT_DIR" .env ecosystem.config.js

# Manter apenas os últimos 7 backups
find \$BACKUP_DIR -name "*.sqlite" -mtime +7 -delete
find \$BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "\$(date): Backup concluído" >> /var/log/novusio-backup.log
EOF
    
    chmod +x /usr/local/bin/novusio-backup.sh
    
    # Configurar cron para backup diário às 2h da manhã
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/novusio-backup.sh") | crontab -
    
    log "✓ Backup automático configurado"
}

# Configurar monitoramento
setup_monitoring() {
    log "📊 Configurando monitoramento..."
    
    # Script de monitoramento
    cat > /usr/local/bin/novusio-monitor.sh << EOF
#!/bin/bash
# Script de monitoramento do Novusio

LOG_FILE="/var/log/novusio-monitor.log"
PROJECT_DIR="$PROJECT_DIR"

# Função de log
log_monitor() {
    echo "\$(date): \$1" >> \$LOG_FILE
}

# Verificar se PM2 está rodando
if ! pm2 list | grep -q "novusio-server"; then
    log_monitor "ERRO: Aplicação não está rodando, reiniciando..."
    cd \$PROJECT_DIR
    sudo -u $USERNAME pm2 restart ecosystem.config.js
fi

# Verificar uso de memória
MEMORY_USAGE=\$(pm2 jlist | jq -r '.[] | select(.name=="novusio-server") | .monit.memory / 1024 / 1024')
if (( \$(echo "\$MEMORY_USAGE > 800" | bc -l) )); then
    log_monitor "AVISO: Uso de memória alto: \${MEMORY_USAGE}MB"
fi

# Verificar espaço em disco
DISK_USAGE=\$(df / | awk 'NR==2 {print \$5}' | sed 's/%//')
if [ \$DISK_USAGE -gt 85 ]; then
    log_monitor "ERRO: Espaço em disco baixo: \${DISK_USAGE}%"
fi

log_monitor "Monitoramento executado com sucesso"
EOF
    
    chmod +x /usr/local/bin/novusio-monitor.sh
    
    # Configurar cron para monitoramento a cada 5 minutos
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/novusio-monitor.sh") | crontab -
    
    log "✓ Monitoramento configurado"
}

# Configurar logrotate
setup_logrotate() {
    log "📝 Configurando rotação de logs..."
    
    cat > /etc/logrotate.d/novusio << EOF
/var/log/novusio/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $USERNAME $USERNAME
    postrotate
        sudo -u $USERNAME pm2 reloadLogs
    endscript
}
EOF
    
    log "✓ Logrotate configurado"
}

# Inicializar banco de dados
init_database() {
    log "🗄️  Inicializando banco de dados..."
    
    cd $PROJECT_DIR
    
    # Executar inicialização do banco
    sudo -u $USERNAME npm run init-db
    
    log "✓ Banco de dados inicializado"
}

# Reiniciar serviços
restart_services() {
    log "🔄 Reiniciando serviços..."
    
    # Recarregar Nginx
    systemctl reload nginx
    
    # Reiniciar aplicação
    cd $PROJECT_DIR
    sudo -u $USERNAME pm2 restart ecosystem.config.js
    
    # Habilitar serviços
    systemctl enable nginx
    systemctl enable fail2ban
    
    log "✓ Serviços reiniciados"
}

# Verificar instalação
verify_installation() {
    log "✅ Verificando instalação..."
    
    # Verificar se aplicação está rodando
    if pm2 list | grep -q "novusio-server.*online"; then
        log "✓ Aplicação rodando no PM2"
    else
        error "❌ Aplicação não está rodando no PM2"
    fi
    
    # Verificar Nginx
    if systemctl is-active --quiet nginx; then
        log "✓ Nginx ativo"
    else
        error "❌ Nginx não está ativo"
    fi
    
    # Verificar SSL
    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        log "✓ Certificado SSL instalado"
    else
        error "❌ Certificado SSL não encontrado"
    fi
    
    # Testar acesso
    log "🌐 Testando acesso ao site..."
    if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN | grep -q "200\|301\|302"; then
        log "✓ Site acessível via HTTPS"
    else
        warning "⚠️  Site pode não estar acessível ainda"
    fi
}

# Mostrar informações finais
show_final_info() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║                    🎉 DEPLOY CONCLUÍDO! 🎉                  ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${CYAN}📋 INFORMAÇÕES DO DEPLOY:${NC}"
    echo "=================================="
    echo -e "🌐 Site: ${GREEN}https://$DOMAIN${NC}"
    echo -e "👤 Usuário: ${GREEN}$USERNAME${NC}"
    echo -e "📁 Diretório: ${GREEN}$PROJECT_DIR${NC}"
    echo -e "🔧 Porta: ${GREEN}$APP_PORT${NC}"
    echo ""
    
    echo -e "${CYAN}🔧 COMANDOS ÚTEIS:${NC}"
    echo "=================================="
    echo -e "📊 Status PM2: ${YELLOW}sudo -u $USERNAME pm2 status${NC}"
    echo -e "📝 Logs PM2: ${YELLOW}sudo -u $USERNAME pm2 logs${NC}"
    echo -e "🔄 Reiniciar: ${YELLOW}sudo -u $USERNAME pm2 restart novusio-server${NC}"
    echo -e "📋 Logs Nginx: ${YELLOW}tail -f /var/log/nginx/access.log${NC}"
    echo -e "🔒 Renovar SSL: ${YELLOW}certbot renew${NC}"
    echo ""
    
    echo -e "${CYAN}🔐 PRÓXIMOS PASSOS:${NC}"
    echo "=================================="
    echo "1. Acesse https://$DOMAIN/admin"
    echo "2. Faça login com as credenciais padrão"
    echo "3. Configure suas informações da empresa"
    echo "4. Altere a senha padrão do admin"
    echo "5. Configure backup e monitoramento"
    echo ""
    
    echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
    echo "=================================="
    echo "• Altere a senha padrão do admin imediatamente"
    echo "• Configure backup regular dos dados"
    echo "• Monitore os logs regularmente"
    echo "• Mantenha o sistema atualizado"
    echo ""
}

# Função principal com menu
main() {
    show_banner
    check_root
    
    # Loop do menu principal
    while true; do
        show_menu
        
        case $MENU_CHOICE in
            1)
                deploy_complete
                echo ""
                read -p "Pressione Enter para voltar ao menu..."
                ;;
            2)
                update_application
                echo ""
                read -p "Pressione Enter para voltar ao menu..."
                ;;
            3)
                remove_project
                echo ""
                read -p "Pressione Enter para voltar ao menu..."
                ;;
            4)
                show_system_status
                echo ""
                read -p "Pressione Enter para voltar ao menu..."
                ;;
            5)
                quick_maintenance
                echo ""
                read -p "Pressione Enter para voltar ao menu..."
                ;;
            6)
                show_logs
                ;;
            7)
                echo -e "${GREEN}👋 Até logo!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opção inválida. Escolha entre 1-7.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Executar função principal
main "$@"
