#!/bin/bash

# =============================================================================
# Script de Configuração SSL - Site Novusio
# Configura certificados SSL com Let's Encrypt via Certbot
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para log
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
    if [[ $EUID -ne 0 ]]; then
        error "Este script deve ser executado como root!"
        error "Use: sudo ./setup-ssl.sh"
        exit 1
    fi
}

# Verificar se Certbot está instalado
check_certbot() {
    if ! command -v certbot &> /dev/null; then
        error "Certbot não está instalado!"
        log "Instalando Certbot..."
        apt update
        apt install -y certbot python3-certbot-nginx
    fi
}

# Coletar informações
collect_info() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              🔒 CONFIGURAÇÃO SSL - NOVUSIO 🔒               ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${CYAN}📋 Configuração de Certificados SSL${NC}"
    echo -e "${YELLOW}===================================${NC}"
    echo ""
    
    # Solicitar domínio
    while true; do
        read -p "🌐 Digite o domínio principal (ex: exemplo.com): " DOMAIN
        if [[ -n "$DOMAIN" && "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]]; then
            break
        else
            error "Domínio inválido. Tente novamente."
        fi
    done
    
    # Solicitar email
    while true; do
        read -p "📧 Digite seu email para notificações SSL (padrão: suporte@novusiopy.com): " EMAIL
        if [[ -z "$EMAIL" ]]; then
            EMAIL="suporte@novusiopy.com"
            break
        elif [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            error "Email inválido. Tente novamente."
        fi
    done
    
    # Confirmar configuração
    echo ""
    echo -e "${CYAN}📋 Resumo da Configuração SSL:${NC}"
    echo -e "${YELLOW}=============================${NC}"
    echo "🌐 Domínio: $DOMAIN"
    echo "📧 Email: $EMAIL"
    echo "🔗 Domínios incluídos: $DOMAIN, www.$DOMAIN"
    echo ""
    
    read -p "✅ Confirmar e continuar? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        info "Configuração SSL cancelada."
        exit 0
    fi
}

# Verificar se o domínio está apontando para o servidor
verify_domain() {
    log "Verificando se o domínio está apontando para este servidor..."
    
    # Obter IP público do servidor
    SERVER_IP=$(curl -s ifconfig.me)
    DOMAIN_IP=$(dig +short "$DOMAIN" | tail -n1)
    
    if [[ "$SERVER_IP" == "$DOMAIN_IP" ]]; then
        log "✅ Domínio $DOMAIN está apontando corretamente para este servidor"
    else
        warning "⚠️  Domínio $DOMAIN pode não estar apontando para este servidor"
        warning "IP do servidor: $SERVER_IP"
        warning "IP do domínio: $DOMAIN_IP"
        echo ""
        read -p "Continuar mesmo assim? (y/N): " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            info "Configuração SSL cancelada."
            exit 0
        fi
    fi
}

# Configurar Nginx temporariamente para validação
setup_nginx_temp() {
    log "Configurando Nginx temporariamente para validação SSL..."
    
    # Criar configuração temporária
    cat > /etc/nginx/sites-available/novusio-temp << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # Habilitar site temporário
    ln -sf /etc/nginx/sites-available/novusio-temp /etc/nginx/sites-enabled/
    
    # Testar e recarregar Nginx
    nginx -t
    systemctl reload nginx
    
    log "Nginx configurado temporariamente!"
}

# Obter certificado SSL
obtain_certificate() {
    log "Obtendo certificado SSL com Let's Encrypt..."
    
    # Parar Nginx temporariamente
    systemctl stop nginx
    
    # Obter certificado usando standalone
    certbot certonly \
        --standalone \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" \
        --domains "$DOMAIN,www.$DOMAIN" \
        --expand
    
    # Reiniciar Nginx
    systemctl start nginx
    
    log "Certificado SSL obtido com sucesso!"
}

# Configurar Nginx com SSL
setup_nginx_ssl() {
    log "Configurando Nginx com SSL..."
    
    # Criar configuração SSL
    cat > /etc/nginx/sites-available/novusio << EOF
# Redirecionar HTTP para HTTPS
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Redirecionar www para não-www
    if (\$host = www.$DOMAIN) {
        return 301 http://$DOMAIN\$request_uri;
    }
    
    # Redirecionar para HTTPS
    return 301 https://\$server_name\$request_uri;
}

# Servidor HTTPS
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # Redirecionar www para não-www
    if (\$host = www.$DOMAIN) {
        return 301 https://$DOMAIN\$request_uri;
    }
    
    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # Configurações SSL modernas
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Logs
    access_log /var/log/nginx/novusio_access.log;
    error_log /var/log/nginx/novusio_error.log;
    
    # Tamanho máximo de upload
    client_max_body_size 50M;
    
    # Proxy para aplicação Node.js
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Configurações específicas para API
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # Remover configuração temporária
    rm -f /etc/nginx/sites-enabled/novusio-temp
    rm -f /etc/nginx/sites-available/novusio-temp
    
    # Habilitar configuração SSL
    ln -sf /etc/nginx/sites-available/novusio /etc/nginx/sites-enabled/
    
    # Remover site padrão
    rm -f /etc/nginx/sites-enabled/default
    
    # Testar configuração
    nginx -t
    
    # Recarregar Nginx
    systemctl reload nginx
    
    log "Nginx configurado com SSL!"
}

# Configurar renovação automática
setup_auto_renewal() {
    log "Configurando renovação automática de certificados..."
    
    # Criar script de renovação
    cat > /etc/cron.daily/certbot-renew << 'EOF'
#!/bin/bash
/usr/bin/certbot renew --quiet --post-hook "systemctl reload nginx"
EOF
    
    # Dar permissão de execução
    chmod +x /etc/cron.daily/certbot-renew
    
    # Testar renovação
    certbot renew --dry-run
    
    log "Renovação automática configurada!"
}

# Verificar configuração SSL
verify_ssl() {
    log "Verificando configuração SSL..."
    
    # Aguardar propagação
    sleep 5
    
    # Testar HTTPS
    if curl -f -s "https://$DOMAIN" > /dev/null; then
        log "✅ HTTPS está funcionando corretamente"
    else
        error "❌ HTTPS não está funcionando"
        return 1
    fi
    
    # Verificar certificado
    CERT_INFO=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -dates)
    if [[ -n "$CERT_INFO" ]]; then
        log "✅ Certificado SSL válido"
        echo "$CERT_INFO"
    else
        error "❌ Certificado SSL inválido"
        return 1
    fi
    
    log "Verificação SSL concluída!"
}

# Exibir informações finais
show_final_info() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              ✅ SSL CONFIGURADO COM SUCESSO! ✅              ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${CYAN}🔒 Informações SSL:${NC}"
    echo -e "${YELLOW}===================${NC}"
    echo "🌐 Site HTTPS: https://$DOMAIN"
    echo "📧 Email: $EMAIL"
    echo "📅 Próxima renovação: $(certbot certificates | grep -A 3 "$DOMAIN" | grep "Expiry Date" | cut -d: -f2-)"
    echo ""
    
    echo -e "${CYAN}🔧 Comandos Úteis:${NC}"
    echo -e "${YELLOW}==================${NC}"
    echo "📊 Status dos certificados: certbot certificates"
    echo "🔄 Renovar certificados: certbot renew"
    echo "🧪 Testar renovação: certbot renew --dry-run"
    echo "📝 Ver logs SSL: tail -f /var/log/letsencrypt/letsencrypt.log"
    echo ""
    
    echo -e "${GREEN}🎉 SSL configurado com sucesso! Seu site agora é seguro com HTTPS.${NC}"
}

# Função principal
main() {
    check_root
    check_certbot
    collect_info
    verify_domain
    setup_nginx_temp
    obtain_certificate
    setup_nginx_ssl
    setup_auto_renewal
    verify_ssl
    show_final_info
}

# Executar função principal
main "$@"
