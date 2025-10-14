#!/bin/bash

# Script para corrigir configuração do Nginx

echo "🔧 Corrigindo configuração do Nginx..."

# Parar Nginx
echo "⏹️ Parando Nginx..."
systemctl stop nginx

# Remover todas as configurações do Novusio
echo "🗑️ Removendo configurações antigas..."
rm -f /etc/nginx/sites-enabled/novusiopy*
rm -f /etc/nginx/sites-available/novusiopy*

# Restaurar configuração padrão se necessário
if [[ ! -f /etc/nginx/sites-enabled/default ]]; then
    echo "📝 Restaurando configuração padrão..."
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
fi

# Copiar nossa configuração corrigida
echo "📋 Aplicando configuração corrigida..."
if [[ -f "instalador/nginx.conf" ]]; then
    cp "instalador/nginx.conf" "/etc/nginx/sites-available/novusiopy"
    ln -sf "/etc/nginx/sites-available/novusiopy" "/etc/nginx/sites-enabled/"
    echo "✅ Configuração aplicada"
else
    echo "❌ Arquivo nginx.conf não encontrado!"
    exit 1
fi

# Testar configuração
echo "🧪 Testando configuração..."
if nginx -t; then
    echo "✅ Configuração válida!"
    
    # Iniciar Nginx
    echo "🚀 Iniciando Nginx..."
    systemctl start nginx
    systemctl status nginx --no-pager -l
    
    echo "✅ Nginx corrigido e funcionando!"
else
    echo "❌ Configuração inválida!"
    nginx -t
    exit 1
fi
