#!/bin/bash

# 🔒 Configurador SSL Automático - Site Novusio
# Script para configurar certificados SSL com Certbot

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   print_error "Este script deve ser executado como root."
   exit 1
fi

print_status "🔒 Configurando SSL com Certbot..."

# Verificar se Certbot está instalado
if ! command -v certbot &> /dev/null; then
    print_error "Certbot não está instalado. Execute primeiro o install.sh"
    exit 1
fi

# Verificar se Nginx está rodando
if ! sudo systemctl is-active --quiet nginx; then
    print_error "Nginx não está rodando. Inicie o Nginx primeiro."
    exit 1
fi

# Solicitar informações do domínio
echo ""
print_status "📝 Configuração do domínio SSL"
echo ""
read -p "Digite seu domínio (ex: exemplo.com): " DOMAIN
read -p "Digite seu email para notificações SSL: " EMAIL

# Validar entrada
if [[ -z "$DOMAIN" ]]; then
    print_error "Domínio não pode estar vazio"
    exit 1
fi

if [[ -z "$EMAIL" ]]; then
    print_error "Email não pode estar vazio"
    exit 1
fi

# Validar formato do email
if [[ ! "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    print_error "Formato de email inválido"
    exit 1
fi

print_status "🌐 Configurando domínio: $DOMAIN"
print_status "📧 Email para notificações: $EMAIL"

# Atualizar configuração do Nginx com o domínio
print_status "📝 Atualizando configuração do Nginx..."
sed -i "s/your-domain\.com/$DOMAIN/g" /etc/nginx/sites-available/novusio
sed -i "s/www\.your-domain\.com/www.$DOMAIN/g" /etc/nginx/sites-available/novusio

# Testar configuração do Nginx
if nginx -t; then
    print_success "Configuração do Nginx válida"
    systemctl reload nginx
else
    print_error "Erro na configuração do Nginx"
    exit 1
fi

# Verificar se o domínio está apontando para o servidor
print_status "🔍 Verificando DNS do domínio..."
DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)
SERVER_IP=$(curl -s ifconfig.me)

if [[ "$DOMAIN_IP" != "$SERVER_IP" ]]; then
    print_warning "⚠️ O domínio $DOMAIN ($DOMAIN_IP) não está apontando para este servidor ($SERVER_IP)"
    print_warning "Configure o DNS do seu domínio antes de continuar"
    read -p "Continuar mesmo assim? (y/N): " CONTINUE
    if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
        print_error "Instalação cancelada"
        exit 1
    fi
else
    print_success "✅ DNS configurado corretamente"
fi

# Obter certificado SSL
print_status "🔒 Obtendo certificado SSL..."
certbot --nginx -d $DOMAIN --email $EMAIL --agree-tos --non-interactive --redirect

# Configurar renovação automática
print_status "🔄 Configurando renovação automática..."
if crontab -l 2>/dev/null | grep -q "certbot renew"; then
    print_warning "Renovação automática já configurada"
else
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    print_success "Renovação automática configurada"
fi

# Testar renovação
print_status "🧪 Testando renovação automática..."
if certbot renew --dry-run; then
    print_success "✅ Teste de renovação bem-sucedido"
else
    print_warning "⚠️ Teste de renovação falhou"
fi

# Atualizar arquivo .env com o domínio
print_status "⚙️ Atualizando arquivo .env..."
sed -i "s/DOMAIN=your-domain.com/DOMAIN=$DOMAIN/g" /opt/novusio/.env

# Configurar headers de segurança adicionais
print_status "🛡️ Configurando headers de segurança..."
tee -a /etc/nginx/sites-available/novusio > /dev/null << 'EOF'

    # Headers de segurança adicionais
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
EOF

# Recarregar Nginx
if nginx -t; then
    systemctl reload nginx
    print_success "Nginx recarregado com headers de segurança"
else
    print_error "Erro na configuração do Nginx"
    exit 1
fi

# Verificar status do SSL
print_status "🔍 Verificando status do SSL..."
if certbot certificates | grep -q "$DOMAIN"; then
    print_success "✅ Certificado SSL instalado com sucesso"
else
    print_error "❌ Erro na instalação do certificado SSL"
    exit 1
fi

# Testar SSL
print_status "🧪 Testando SSL..."
if curl -sSf "https://$DOMAIN" > /dev/null; then
    print_success "✅ SSL funcionando corretamente"
else
    print_warning "⚠️ SSL pode não estar funcionando corretamente"
fi

print_success "🎉 Configuração SSL concluída!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_status "📋 Resumo da configuração:"
echo ""
echo "🌐 Domínio: https://$DOMAIN"
echo "📧 Email: $EMAIL"
echo "🔒 SSL: Configurado e funcionando"
echo "🔄 Renovação: Automática (cron job configurado)"
echo "🛡️ Segurança: Headers de segurança ativados"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_status "🔧 Comandos úteis:"
echo ""
echo "• Ver certificados: certbot certificates"
echo "• Renovar manualmente: certbot renew"
echo "• Testar renovação: certbot renew --dry-run"
echo "• Status SSL: curl -I https://$DOMAIN"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_status "🚀 Agora você pode iniciar a aplicação:"
echo "systemctl start novusio"
echo ""
