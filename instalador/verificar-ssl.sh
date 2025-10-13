#!/bin/bash

# Script para verificar configuração SSL

echo "🔍 Verificando configuração SSL do Novusio..."
echo "============================================="

# Verificar se está no servidor
if [ ! -d "/opt/novusio" ]; then
    echo "❌ Diretório /opt/novusio não encontrado"
    echo "Execute este script no servidor após o deploy"
    exit 1
fi

# Verificar Nginx
echo ""
echo "🌐 Verificando Nginx..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx está rodando"
    
    # Listar sites habilitados
    echo ""
    echo "📋 Sites habilitados:"
    ls -1 /etc/nginx/sites-enabled/ | while read site; do
        echo "  • $site"
    done
else
    echo "❌ Nginx não está rodando"
fi

# Verificar certificados SSL
echo ""
echo "🔒 Verificando certificados SSL..."
if command -v certbot &> /dev/null; then
    echo "✅ Certbot instalado"
    
    # Listar certificados
    certbot certificates 2>/dev/null | grep -A 5 "Certificate Name"
    
    if [ $? -eq 0 ]; then
        echo "✅ Certificados SSL encontrados"
    else
        echo "⚠️ Nenhum certificado SSL encontrado"
        echo ""
        echo "Para configurar SSL, execute:"
        echo "  sudo certbot --nginx -d seu-dominio.com -d www.seu-dominio.com --email seu-email@gmail.com --redirect"
    fi
else
    echo "❌ Certbot não instalado"
    echo ""
    echo "Para instalar, execute:"
    echo "  sudo apt-get install -y certbot python3-certbot-nginx"
fi

# Verificar renovação automática
echo ""
echo "⏰ Verificando renovação automática..."
if crontab -l 2>/dev/null | grep -q certbot; then
    echo "✅ Renovação automática configurada"
    echo ""
    echo "Cron jobs:"
    crontab -l 2>/dev/null | grep certbot
else
    echo "⚠️ Renovação automática não configurada"
    echo ""
    echo "Para configurar, execute:"
    echo "  (crontab -l 2>/dev/null; echo '0 12 * * * /usr/bin/certbot renew --quiet && systemctl reload nginx') | crontab -"
fi

# Verificar configuração Nginx
echo ""
echo "📝 Verificando configuração Nginx..."
NGINX_CONFIGS=$(ls /etc/nginx/sites-available/ 2>/dev/null)
if [ -n "$NGINX_CONFIGS" ]; then
    echo "✅ Configurações encontradas:"
    for config in $NGINX_CONFIGS; do
        echo ""
        echo "  📄 $config:"
        
        # Verificar SSL
        if grep -q "ssl_certificate" "/etc/nginx/sites-available/$config" 2>/dev/null; then
            echo "    ✅ SSL configurado"
        else
            echo "    ⚠️ SSL não configurado"
        fi
        
        # Verificar redirect
        if grep -q "return 301 https" "/etc/nginx/sites-available/$config" 2>/dev/null; then
            echo "    ✅ Redirect HTTP → HTTPS configurado"
        else
            echo "    ⚠️ Redirect HTTP → HTTPS não configurado"
        fi
        
        # Verificar upstream
        if grep -q "proxy_pass" "/etc/nginx/sites-available/$config" 2>/dev/null; then
            echo "    ✅ Proxy reverso configurado"
        else
            echo "    ⚠️ Proxy reverso não configurado"
        fi
    done
fi

# Testar HTTPS
echo ""
echo "🧪 Testando HTTPS..."
DOMAINS=$(certbot certificates 2>/dev/null | grep "Domains:" | awk '{print $2}' | head -1)
if [ -n "$DOMAINS" ]; then
    echo "Testando: $DOMAINS"
    if curl -I -s "https://$DOMAINS" | grep -q "HTTP"; then
        echo "✅ HTTPS funcionando!"
        curl -I "https://$DOMAINS" 2>&1 | head -5
    else
        echo "⚠️ HTTPS não está respondendo"
    fi
else
    echo "⚠️ Nenhum domínio configurado para testar"
fi

# Resumo
echo ""
echo "============================================="
echo "📊 RESUMO"
echo "============================================="

CHECKS_PASSED=0
CHECKS_TOTAL=5

systemctl is-active --quiet nginx && ((CHECKS_PASSED++))
command -v certbot &> /dev/null && ((CHECKS_PASSED++))
certbot certificates 2>/dev/null | grep -q "Certificate Name" && ((CHECKS_PASSED++))
crontab -l 2>/dev/null | grep -q certbot && ((CHECKS_PASSED++))
ls /etc/nginx/sites-enabled/ 2>/dev/null | grep -q "." && ((CHECKS_PASSED++))

echo "$CHECKS_PASSED de $CHECKS_TOTAL verificações passaram"

if [ $CHECKS_PASSED -eq $CHECKS_TOTAL ]; then
    echo "✅ SSL totalmente configurado!"
elif [ $CHECKS_PASSED -ge 3 ]; then
    echo "⚠️ SSL parcialmente configurado"
else
    echo "❌ SSL não configurado"
    echo ""
    echo "Para configurar SSL, execute no servidor:"
    echo "  cd ~/site-novusio-html/instalador"
    echo "  sudo ./deploy.sh"
    echo "  # Escolha opção 1 e siga as instruções"
fi

echo ""

