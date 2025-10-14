#!/bin/bash

# =============================================================================
# CORRIGIR NGINX - Servir Arquivos React Corretamente
# =============================================================================

set -e

echo "🔧 Corrigindo configuração do Nginx..."
echo "======================================"

# Verificar se está como root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Execute como root: sudo $0"
    exit 1
fi

# Detectar domínio
DOMAIN=$(ls /etc/nginx/sites-available/ | grep -v default | head -1)

if [[ -z "$DOMAIN" ]]; then
    echo "❌ Domínio não encontrado!"
    echo "Execute este script após o deploy"
    exit 1
fi

echo "📋 Domínio detectado: $DOMAIN"
echo ""

# Fazer backup
echo "💾 Fazendo backup da configuração atual..."
cp /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-available/$DOMAIN.backup-$(date +%Y%m%d_%H%M%S)

# Corrigir o root para apontar para o dist do React
echo "📝 Corrigindo caminho do root..."

sed -i 's|root /var/www/html;|# root /var/www/html;|g' /etc/nginx/sites-available/$DOMAIN
sed -i 's|location / {|location / {\n        root /home/novusio/client/dist;|g' /etc/nginx/sites-available/$DOMAIN

echo "🧪 Testando configuração..."
if nginx -t; then
    echo "✅ Configuração válida!"
    
    echo "🔄 Recarregando Nginx..."
    systemctl reload nginx
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ NGINX CORRIGIDO!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Seus arquivos CSS e JS agora serão carregados corretamente!"
    echo ""
    echo "Teste acessando:"
    echo "  https://$DOMAIN"
    echo ""
else
    echo "❌ Erro na configuração!"
    echo "Revertendo..."
    mv /etc/nginx/sites-available/$DOMAIN.backup-* /etc/nginx/sites-available/$DOMAIN
    exit 1
fi

