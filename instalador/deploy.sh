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
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}           DEPLOY COMPLETO - PASSO A PASSO${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${CYAN}[1/15]${NC} Coletando informações..."
    collect_info
    
    echo -e "${CYAN}[2/15]${NC} Verificando DNS..."
    check_dns
    
    echo -e "${CYAN}[3/15]${NC} Atualizando sistema..."
    update_system
    
    echo -e "${CYAN}[4/15]${NC} Instalando pacotes..."
    install_packages
    
    echo -e "${CYAN}[5/15]${NC} Configurando firewall..."
    setup_firewall
    
    echo -e "${CYAN}[6/15]${NC} Criando usuário..."
    create_user
    
    echo -e "${CYAN}[7/15]${NC} Clonando repositório..."
    clone_repository
    
    echo -e "${CYAN}[8/15]${NC} Fazendo build da aplicação..."
    build_application
    
    echo -e "${CYAN}[9/15]${NC} Configurando variáveis de ambiente..."
    setup_environment
    
    echo -e "${CYAN}[10/15]${NC} Configurando PM2..."
    setup_pm2
    
    echo ""
    echo -e "${YELLOW}⏩ Continuando com configuração do servidor web...${NC}"
    sleep 1
    
    echo ""
    echo -e "${CYAN}[11/15]${NC} Configurando Nginx..."
    setup_nginx
    
    echo ""
    echo -e "${YELLOW}⏩ Próximo: Configuração SSL...${NC}"
    sleep 1
    
    echo ""
    echo -e "${CYAN}[12/15]${NC} Configurando SSL/HTTPS..."
    setup_ssl
    
    echo -e "${CYAN}[13/15]${NC} Configurando backup automático..."
    setup_backup
    
    echo -e "${CYAN}[14/15]${NC} Configurando monitoramento..."
    setup_monitoring
    
    setup_logrotate
    
    echo -e "${CYAN}[15/15]${NC} Inicializando banco de dados..."
    init_database
    
    restart_services
    verify_installation
    
    # Verificação final do SSL
    echo ""
    echo -e "${BLUE}🔍 Verificação Final do SSL...${NC}"
    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        echo -e "${GREEN}✅ Certificado SSL instalado e funcionando!${NC}"
        echo "  • Certificado: /etc/letsencrypt/live/$DOMAIN/"
        
        # Mostrar data de expiração
        EXPIRY=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" 2>/dev/null | cut -d= -f2)
        if [[ -n "$EXPIRY" ]]; then
            echo "  • Expira em: $EXPIRY"
        fi
    else
        echo -e "${YELLOW}⚠️ Certificado SSL NÃO foi instalado!${NC}"
        echo ""
        echo "Para configurar SSL agora, execute:"
        echo "  sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --redirect"
        echo ""
    fi
    
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
    read -p "📧 Email para SSL (Let's Encrypt) [suporte@novusiopy.com]: " EMAIL
    EMAIL=${EMAIL:-suporte@novusiopy.com}
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
    
    # Verificar se diretório existe e não está vazio
    if [[ -d "$PROJECT_DIR" ]] && [[ -n "$(ls -A $PROJECT_DIR 2>/dev/null)" ]]; then
        warning "⚠️ Diretório $PROJECT_DIR já existe e não está vazio"
        
        # Verificar se é um repositório git
        if [[ -d "$PROJECT_DIR/.git" ]]; then
            log "📥 Repositório Git detectado, atualizando..."
            cd $PROJECT_DIR
            
            # Salvar mudanças locais se houver
            if [[ -n "$(git status --porcelain)" ]]; then
                warning "⚠️ Existem mudanças locais, fazendo stash..."
                git stash
            fi
            
            # Atualizar código
            git pull origin main || git pull origin master
            log "✓ Repositório atualizado"
        else
            # Não é um repositório git, fazer backup e clonar
            warning "⚠️ Não é um repositório Git, fazendo backup..."
            BACKUP_DIR="${PROJECT_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
            mv $PROJECT_DIR $BACKUP_DIR
            log "✓ Backup salvo em: $BACKUP_DIR"
            
            # Criar diretório e clonar
            mkdir -p $PROJECT_DIR
            cd $PROJECT_DIR
            git clone $GIT_REPO .
            log "✓ Repositório clonado em $PROJECT_DIR"
        fi
    else
        # Diretório não existe ou está vazio
        mkdir -p $PROJECT_DIR
        cd $PROJECT_DIR
        git clone $GIT_REPO .
        log "✓ Repositório clonado em $PROJECT_DIR"
    fi
    
    # Configurar permissões
    chown -R $USERNAME:$USERNAME $PROJECT_DIR
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
    autorestart: true,
    watch: false,
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
    min_uptime: '10s',
    kill_timeout: 5000,
    listen_timeout: 3000
  }]
};
EOF
    
    # Criar diretório de logs
    mkdir -p /var/log/novusio
    chown $USERNAME:$USERNAME /var/log/novusio
    
    # Iniciar aplicação com PM2
    log "🚀 Iniciando aplicação com PM2..."
    sudo -u $USERNAME pm2 start ecosystem.config.js
    sudo -u $USERNAME pm2 save
    
    # Configurar PM2 para iniciar no boot
    log "⚙️ Configurando PM2 para iniciar automaticamente no boot..."
    
    # Obter o comando de startup
    STARTUP_CMD=$(sudo -u $USERNAME pm2 startup systemd -u $USERNAME --hp /home/$USERNAME | grep "sudo env" | tail -1)
    
    if [[ -n "$STARTUP_CMD" ]]; then
        log "📝 Executando comando de startup do PM2..."
        eval $STARTUP_CMD
        log "✓ PM2 startup configurado"
    else
        # Executar diretamente
        env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USERNAME --hp /home/$USERNAME
    fi
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ PM2 CONFIGURADO COM SUCESSO!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "  ✓ Aplicação iniciada em modo cluster"
    echo "  ✓ Logs configurados em /var/log/novusio/"
    echo "  ✓ Auto-restart habilitado"
    echo "  ✓ Startup no boot configurado"
    echo ""
    
    # Verificar status
    sudo -u $USERNAME pm2 list
    
    echo ""
    sleep 2
}

# Configurar Nginx
setup_nginx() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🌐 CONFIGURAÇÃO NGINX${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Configurações que serão aplicadas:"
    echo "  • Domínio: $DOMAIN"
    echo "  • Porta da aplicação: $APP_PORT"
    echo "  • Proxy reverso: localhost:$APP_PORT"
    echo "  • Rate limiting: Sim"
    echo "  • Compressão Gzip: Sim"
    echo "  • Headers de segurança: Sim"
    echo ""
    
    # NÃO remover configuração padrão se houver outros sites
    if [[ $(ls -A /etc/nginx/sites-enabled/ 2>/dev/null | wc -l) -gt 1 ]]; then
        warning "⚠️ Existem outros sites configurados. Mantendo configuração padrão."
    else
        # Remover configuração padrão apenas se for o único site
        log "🗑️ Removendo configuração padrão do Nginx..."
        rm -f /etc/nginx/sites-enabled/default
    fi
    
    # Criar configuração do site com nome específico do domínio
    # IMPORTANTE: Configuração inicial SEM SSL (será adicionado pelo Certbot)
    log "📝 Criando configuração inicial para $DOMAIN (sem SSL)..."
    cat > /etc/nginx/sites-available/$DOMAIN << 'NGINX_CONFIG_EOF'
# Rate limiting
limit_req_zone $binary_remote_addr zone=api_3000:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login_3000:10m rate=1r/s;

# Upstream para a aplicação
upstream novusio_backend_3000 {
    server 127.0.0.1:3000;
    keepalive 32;
}

# Configuração HTTP (Certbot irá adicionar HTTPS depois)
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER www.DOMAIN_PLACEHOLDER;
    
    # Root do React
    root PROJECT_DIR_PLACEHOLDER/client/dist;
    index index.html;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Certbot challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Arquivos estáticos do React
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Cache de assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # API routes com rate limiting
    location /api/ {
        limit_req zone=api_3000 burst=20 nodelay;
        
        proxy_pass http://novusio_backend_3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # Admin login com rate limiting rigoroso
    location /api/auth/login {
        limit_req zone=login_3000 burst=5 nodelay;
        
        proxy_pass http://novusio_backend_3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Upload files
    location /uploads/ {
        alias PROJECT_DIR_PLACEHOLDER/uploads/;
        expires 1y;
        add_header Cache-Control "public";
        
        # Security - bloquear scripts
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
NGINX_CONFIG_EOF
    
    # Substituir placeholders
    sed -i "s|DOMAIN_PLACEHOLDER|$DOMAIN|g" /etc/nginx/sites-available/$DOMAIN
    sed -i "s|PROJECT_DIR_PLACEHOLDER|$PROJECT_DIR|g" /etc/nginx/sites-available/$DOMAIN
    
    # Habilitar site com nome específico
    log "🔗 Habilitando site $DOMAIN..."
    ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    
    # Testar configuração
    log "🧪 Testando configuração do Nginx..."
    if nginx -t 2>&1 | tee /tmp/nginx-test.log; then
        log "✓ Configuração do Nginx válida!"
        
        # Recarregar Nginx
        log "🔄 Recarregando Nginx..."
        systemctl reload nginx
        
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ NGINX CONFIGURADO COM SUCESSO!${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "✓ Configuração criada: /etc/nginx/sites-available/$DOMAIN"
        echo "✓ Site habilitado em: /etc/nginx/sites-enabled/$DOMAIN"
        echo "✓ Proxy reverso: http://localhost:$APP_PORT"
        echo "✓ Site temporário: http://$DOMAIN (HTTP)"
        echo ""
        echo -e "${BLUE}ℹ️  Nota: SSL/HTTPS será configurado no próximo passo!${NC}"
        echo ""
        
    else
        error "❌ Erro na configuração do Nginx!"
        cat /tmp/nginx-test.log
        warning "Revertendo alterações..."
        rm -f /etc/nginx/sites-available/$DOMAIN
        rm -f /etc/nginx/sites-enabled/$DOMAIN
        exit 1
    fi
}

# Configurar SSL com Certbot
setup_ssl() {
    log "🔒 Configurando SSL com Let's Encrypt..."
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔐 CONFIGURAÇÃO SSL/HTTPS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Vamos configurar SSL gratuito com Let's Encrypt para:"
    echo "  • Domínio: $DOMAIN"
    echo "  • www.$DOMAIN"
    echo "  • Email: $EMAIL"
    echo ""
    echo "O que será feito:"
    echo "  ✓ Instalar Certbot"
    echo "  ✓ Emitir certificado SSL gratuito"
    echo "  ✓ Configurar redirect automático HTTP → HTTPS"
    echo "  ✓ Configurar renovação automática (cron)"
    echo ""
    read -p "Deseja configurar SSL agora? (Y/n): " SETUP_SSL
    
    if [[ "$SETUP_SSL" =~ ^[Nn]$ ]]; then
        warning "⚠️ SSL não configurado. Você pode configurar depois executando:"
        warning "   sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --redirect"
        return
    fi
    
    # Criar diretório para challenge do Certbot
    log "📁 Criando diretório para validação SSL..."
    mkdir -p /var/www/html
    
    # Instalar Certbot
    log "📦 Instalando Certbot..."
    apt-get install -y certbot python3-certbot-nginx
    
    # Garantir que Nginx está rodando
    log "🔄 Garantindo que Nginx está rodando..."
    if ! systemctl is-active --quiet nginx; then
        log "🚀 Iniciando Nginx..."
        systemctl start nginx
    else
        systemctl reload nginx || systemctl restart nginx
    fi
    
    # Verificar se porta 80 está acessível
    log "🔍 Verificando porta 80..."
    if ! netstat -tuln 2>/dev/null | grep -q ":80 " && ! ss -tuln 2>/dev/null | grep -q ":80 "; then
        warning "⚠️ Porta 80 não está acessível. SSL pode falhar."
    fi
    
    # Obter certificado SSL
    log "🔐 Obtendo certificado SSL para $DOMAIN e www.$DOMAIN..."
    log "📧 Email para notificações: $EMAIL"
    echo ""
    echo -e "${YELLOW}⏳ Aguarde... Isso pode levar alguns minutos...${NC}"
    echo ""
    
    if certbot --nginx \
        -d $DOMAIN \
        -d www.$DOMAIN \
        --non-interactive \
        --agree-tos \
        --email $EMAIL \
        --redirect; then
        
        log "✓ Certificado SSL obtido com sucesso!"
        
        # Configurar renovação automática
        log "⏰ Configurando renovação automática..."
        (crontab -l 2>/dev/null | grep -v certbot; echo "0 12 * * * /usr/bin/certbot renew --quiet && systemctl reload nginx") | crontab -
        
        log "✓ Renovação automática configurada (diariamente ao meio-dia)"
        
        # Testar renovação
        log "🔍 Testando renovação..."
        certbot renew --dry-run
        
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ SSL/HTTPS CONFIGURADO COM SUCESSO!${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "✓ Seu site agora está disponível em:"
        echo "  • https://$DOMAIN"
        echo "  • https://www.$DOMAIN"
        echo ""
        echo "✓ Redirect automático HTTP → HTTPS ativo"
        echo "✓ Renovação automática configurada"
        echo ""
        
    else
        error "❌ Falha ao obter certificado SSL"
        warning "Possíveis causas:"
        warning "  • DNS não está apontando para este servidor"
        warning "  • Porta 80 ou 443 bloqueada"
        warning "  • Domínio inválido"
        echo ""
        warning "Você pode tentar manualmente depois:"
        warning "  sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --redirect"
    fi
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
    
    echo ""
    
    # Verificar se aplicação está rodando
    if sudo -u $USERNAME pm2 list 2>/dev/null | grep -q "novusio-server.*online"; then
        log "✓ Aplicação rodando no PM2"
    else
        warning "⚠️ Verificação PM2 inconclusiva (aplicação pode estar rodando)"
        # Não parar o script, apenas avisar
    fi
    
    # Verificar Nginx
    if systemctl is-active --quiet nginx; then
        log "✓ Nginx ativo"
    else
        warning "⚠️ Nginx não está ativo"
    fi
    
    # Verificar SSL (não é erro fatal se não tiver)
    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        log "✓ Certificado SSL instalado"
    else
        warning "⚠️ Certificado SSL não encontrado (pode ser configurado depois)"
    fi
    
    # Testar acesso HTTP primeiro
    log "🌐 Testando acesso ao site..."
    
    # Testar HTTP
    if curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN 2>/dev/null | grep -q "200\|301\|302"; then
        log "✓ Site acessível via HTTP"
    fi
    
    # Testar HTTPS se SSL estiver configurado
    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN 2>/dev/null | grep -q "200\|301\|302"; then
            log "✓ Site acessível via HTTPS"
        else
            warning "⚠️ HTTPS pode não estar acessível ainda (aguarde propagação DNS)"
        fi
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
