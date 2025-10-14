#!/bin/bash

# ⚙️ Configurador de .env - Site Novusio
# Script interativo para configurar variáveis de ambiente em produção

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

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

print_title() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                                ║${NC}"
    echo -e "${CYAN}║                    ⚙️ CONFIGURADOR DE .ENV - SITE NOVUSIO                       ║${NC}"
    echo -e "${CYAN}║                                                                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Função para gerar string aleatória
generate_random_string() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length 2>/dev/null || \
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1
}

# Função para validar email
validate_email() {
    local email=$1
    if [[ $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Função para validar domínio
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Função para criar arquivo .env
create_env_file() {
    local env_file="/opt/novusio/.env"
    
    print_status "Criando arquivo .env..."
    
    # Verificar se já existe
    if [[ -f "$env_file" ]]; then
        print_warning "Arquivo .env já existe"
        read -p "Sobrescrever arquivo existente? (y/N): " overwrite
        
        if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
            print_status "Mantendo arquivo existente"
            return 0
        fi
    fi
    
    # Criar backup do arquivo existente
    if [[ -f "$env_file" ]]; then
        sudo cp "$env_file" "$env_file.backup.$(date +%Y%m%d-%H%M%S)"
        print_success "Backup do .env criado"
    fi
    
    # Criar novo arquivo .env
    sudo tee "$env_file" > /dev/null << EOF
# 🔧 Configuração de Produção - Site Novusio
# Gerado automaticamente em $(date)

# Configurações do servidor
NODE_ENV=production
PORT=3000

# Configurações do domínio
DOMAIN=
EMAIL=

# Configurações de autenticação JWT
JWT_SECRET=
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
CORS_ORIGIN=
CORS_CREDENTIALS=true

# Configurações de sessão
SESSION_SECRET=
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
NOTIFICATION_EMAIL=

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
    sudo chown novusio:novusio "$env_file"
    sudo chmod 600 "$env_file"
    
    print_success "Arquivo .env criado: $env_file"
}

# Função para configurar variáveis básicas
configure_basic_vars() {
    local env_file="/opt/novusio/.env"
    
    print_status "Configurando variáveis básicas..."
    echo ""
    
    # DOMAIN
    while true; do
        read -p "Digite o domínio (ex: exemplo.com): " domain
        if [[ -n "$domain" ]]; then
            if validate_domain "$domain"; then
                sudo sed -i "s/DOMAIN=/DOMAIN=$domain/g" "$env_file"
                print_success "Domínio configurado: $domain"
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
        read -p "Digite o email para notificações: " email
        if [[ -n "$email" ]]; then
            if validate_email "$email"; then
                sudo sed -i "s/EMAIL=/EMAIL=$email/g" "$env_file"
                sudo sed -i "s/NOTIFICATION_EMAIL=/NOTIFICATION_EMAIL=$email/g" "$env_file"
                print_success "Email configurado: $email"
                break
            else
                print_error "Formato de email inválido"
            fi
        else
            print_warning "Email é obrigatório"
        fi
    done
    
    # CORS_ORIGIN
    sudo sed -i "s/CORS_ORIGIN=/CORS_ORIGIN=https:\/\/$domain/g" "$env_file"
    print_success "CORS configurado para: https://$domain"
}

# Função para gerar secrets
generate_secrets() {
    local env_file="/opt/novusio/.env"
    
    print_status "Gerando secrets seguros..."
    
    # JWT_SECRET
    local jwt_secret=$(generate_random_string 64)
    sudo sed -i "s/JWT_SECRET=/JWT_SECRET=$jwt_secret/g" "$env_file"
    print_success "JWT_SECRET gerado"
    
    # SESSION_SECRET
    local session_secret=$(generate_random_string 64)
    sudo sed -i "s/SESSION_SECRET=/SESSION_SECRET=$session_secret/g" "$env_file"
    print_success "SESSION_SECRET gerado"
    
    print_success "Secrets gerados com sucesso"
}

# Função para configurar opções avançadas
configure_advanced() {
    local env_file="/opt/novusio/.env"
    
    print_status "Configurando opções avançadas..."
    echo ""
    
    # SMTP (opcional)
    read -p "Configurar SMTP para envio de emails? (y/N): " configure_smtp
    if [[ "$configure_smtp" == "y" || "$configure_smtp" == "Y" ]]; then
        read -p "Host SMTP (ex: smtp.gmail.com): " smtp_host
        read -p "Porta SMTP (ex: 587): " smtp_port
        read -p "Usuário SMTP: " smtp_user
        read -s -p "Senha SMTP: " smtp_pass
        echo ""
        
        if [[ -n "$smtp_host" ]]; then
            echo "SMTP_HOST=$smtp_host" | sudo tee -a "$env_file" > /dev/null
            echo "SMTP_PORT=$smtp_port" | sudo tee -a "$env_file" > /dev/null
            echo "SMTP_USER=$smtp_user" | sudo tee -a "$env_file" > /dev/null
            echo "SMTP_PASS=$smtp_pass" | sudo tee -a "$env_file" > /dev/null
            print_success "SMTP configurado"
        fi
    fi
    
    # Redis (opcional)
    read -p "Configurar Redis para cache? (y/N): " configure_redis
    if [[ "$configure_redis" == "y" || "$configure_redis" == "Y" ]]; then
        read -p "Host Redis (ex: localhost): " redis_host
        read -p "Porta Redis (ex: 6379): " redis_port
        
        if [[ -n "$redis_host" ]]; then
            echo "REDIS_ENABLED=true" | sudo tee -a "$env_file" > /dev/null
            echo "REDIS_HOST=$redis_host" | sudo tee -a "$env_file" > /dev/null
            echo "REDIS_PORT=$redis_port" | sudo tee -a "$env_file" > /dev/null
            print_success "Redis configurado"
        fi
    fi
    
    # CDN (opcional)
    read -p "Configurar CDN? (y/N): " configure_cdn
    if [[ "$configure_cdn" == "y" || "$configure_cdn" == "Y" ]]; then
        read -p "URL do CDN (ex: https://cdn.exemplo.com): " cdn_url
        
        if [[ -n "$cdn_url" ]]; then
            echo "CDN_ENABLED=true" | sudo tee -a "$env_file" > /dev/null
            echo "CDN_URL=$cdn_url" | sudo tee -a "$env_file" > /dev/null
            print_success "CDN configurado"
        fi
    fi
}

# Função para validar configuração
validate_config() {
    local env_file="/opt/novusio/.env"
    
    print_status "Validando configuração..."
    
    # Verificar variáveis obrigatórias
    local required_vars=("DOMAIN" "EMAIL" "JWT_SECRET")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^$var=" "$env_file" || grep -q "^$var=$" "$env_file"; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        print_error "Variáveis obrigatórias faltando: ${missing_vars[*]}"
        return 1
    fi
    
    # Verificar formato do domínio
    local domain=$(grep "^DOMAIN=" "$env_file" | cut -d'=' -f2)
    if ! validate_domain "$domain"; then
        print_error "Formato de domínio inválido: $domain"
        return 1
    fi
    
    # Verificar formato do email
    local email=$(grep "^EMAIL=" "$env_file" | cut -d'=' -f2)
    if ! validate_email "$email"; then
        print_error "Formato de email inválido: $email"
        return 1
    fi
    
    # Verificar JWT_SECRET
    local jwt_secret=$(grep "^JWT_SECRET=" "$env_file" | cut -d'=' -f2)
    if [[ ${#jwt_secret} -lt 32 ]]; then
        print_error "JWT_SECRET muito curto (mínimo 32 caracteres)"
        return 1
    fi
    
    print_success "Configuração válida!"
    return 0
}

# Função para mostrar resumo
show_summary() {
    local env_file="/opt/novusio/.env"
    
    print_status "Resumo da configuração:"
    echo ""
    
    echo "🌐 Domínio: $(grep "^DOMAIN=" "$env_file" | cut -d'=' -f2)"
    echo "📧 Email: $(grep "^EMAIL=" "$env_file" | cut -d'=' -f2)"
    echo "🔒 JWT Secret: $(grep "^JWT_SECRET=" "$env_file" | cut -d'=' -f2 | cut -c1-10)..."
    echo "📁 Arquivo: $env_file"
    echo ""
}

# Função principal
main() {
    print_title
    
    # Verificar se está rodando como usuário correto
    if [[ $EUID -eq 0 ]]; then
        print_error "Este script não deve ser executado como root diretamente."
        print_status "Execute como usuário normal e use sudo quando necessário."
        exit 1
    fi
    
    # Verificar se o diretório da aplicação existe
    if [[ ! -d "/opt/novusio" ]]; then
        print_error "Diretório da aplicação não encontrado: /opt/novusio"
        print_status "Execute primeiro a instalação completa."
        exit 1
    fi
    
    print_status "Configurando variáveis de ambiente para produção..."
    echo ""
    
    # Criar arquivo .env
    create_env_file
    
    # Configurar variáveis básicas
    configure_basic_vars
    
    # Gerar secrets
    generate_secrets
    
    # Configurar opções avançadas
    configure_advanced
    
    # Validar configuração
    if validate_config; then
        print_success "✅ Configuração validada com sucesso!"
    else
        print_error "❌ Configuração inválida"
        exit 1
    fi
    
    # Mostrar resumo
    show_summary
    
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    print_success "🎉 Configuração do .env concluída com sucesso!"
    echo ""
    print_status "Próximos passos:"
    echo "1. Configurar SSL: sudo ./instalador/setup-ssl.sh"
    echo "2. Iniciar aplicação: sudo systemctl start novusio"
    echo "3. Verificar status: sudo systemctl status novusio"
    echo ""
    print_status "Para editar manualmente: sudo nano /opt/novusio/.env"
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Executar função principal
main
