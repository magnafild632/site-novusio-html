#!/bin/bash

# =============================================================================
# CORRIGIR UPLOAD - NOVUSIO
# =============================================================================
# Script para corrigir problemas de upload 413 (Request Entity Too Large)
# =============================================================================

set -e

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║           🔧 CORRIGIR UPLOAD - NOVUSIO                  ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se está como root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Execute como root: sudo $0${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Correções que serão aplicadas:${NC}"
echo "  ✅ Atualizar nginx.conf com limites de 50MB"
echo "  ✅ Verificar configuração do servidor Node.js"
echo "  ✅ Reiniciar Nginx"
echo "  ✅ Reiniciar aplicação"
echo ""

read -p "Continuar com as correções? (Y/n): " CONTINUE
if [[ "$CONTINUE" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}❌ Cancelado${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[1/6]${NC} Fazendo backup da configuração atual..."

# Backup da configuração atual
if [[ -f "/etc/nginx/sites-available/novusiopy" ]]; then
    cp "/etc/nginx/sites-available/novusiopy" "/etc/nginx/sites-available/novusiopy.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✓ Backup criado${NC}"
else
    echo -e "${YELLOW}⚠️ Arquivo de configuração não encontrado${NC}"
fi

echo ""
echo -e "${BLUE}[2/6]${NC} Atualizando configuração do Nginx..."

# Atualizar nginx.conf
if [[ -f "instalador/nginx.conf" ]]; then
    cp "instalador/nginx.conf" "/etc/nginx/sites-available/novusiopy"
    echo -e "${GREEN}✓ Configuração atualizada${NC}"
    
    # Verificar se a configuração está correta
    if grep -q "client_max_body_size 50M" "/etc/nginx/sites-available/novusiopy"; then
        echo -e "${GREEN}✓ Limite de upload de 50MB confirmado${NC}"
    else
        echo -e "${RED}❌ Limite de upload não encontrado na configuração${NC}"
    fi
else
    echo -e "${RED}❌ Arquivo nginx.conf não encontrado${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[3/6]${NC} Testando configuração do Nginx..."

# Testar configuração
if nginx -t 2>/dev/null; then
    echo -e "${GREEN}✓ Configuração válida${NC}"
else
    echo -e "${RED}❌ Erro na configuração!${NC}"
    echo "Revertendo para backup..."
    cp "/etc/nginx/sites-available/novusiopy.backup."* "/etc/nginx/sites-available/novusiopy" 2>/dev/null || true
    exit 1
fi

echo ""
echo -e "${BLUE}[4/6]${NC} Reiniciando Nginx..."

# Reiniciar nginx
systemctl reload nginx
sleep 2
systemctl restart nginx

if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx reiniciado com sucesso${NC}"
else
    echo -e "${RED}❌ Erro ao reiniciar Nginx${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[5/6]${NC} Verificando configuração do servidor Node.js..."

# Verificar se o servidor tem os limites corretos
if [[ -f "server/server.js" ]]; then
    if grep -q "limit: '50mb'" "server/server.js"; then
        echo -e "${GREEN}✓ Servidor Node.js configurado com limite de 50MB${NC}"
    else
        echo -e "${YELLOW}⚠️ Servidor Node.js pode precisar de atualização${NC}"
    fi
fi

if [[ -f "server/config/multer.js" ]]; then
    if grep -q "50 \* 1024 \* 1024" "server/config/multer.js"; then
        echo -e "${GREEN}✓ Multer configurado com limite de 50MB${NC}"
    else
        echo -e "${YELLOW}⚠️ Multer pode precisar de atualização${NC}"
    fi
fi

echo ""
echo -e "${BLUE}[6/6]${NC} Reiniciando aplicação..."

# Reiniciar aplicação
if command -v pm2 &> /dev/null; then
    if pm2 list 2>/dev/null | grep -q "novusio-server"; then
        pm2 restart novusio-server
        echo -e "${GREEN}✓ Aplicação reiniciada via PM2${NC}"
        
        # Verificar status
        sleep 3
        if pm2 list | grep -q "novusio-server.*online"; then
            echo -e "${GREEN}✓ Aplicação rodando${NC}"
        else
            echo -e "${RED}⚠️ Aplicação pode não estar rodando corretamente${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ PM2 não está gerenciando a aplicação${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ PM2 não instalado${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}║            ✅ CORREÇÕES APLICADAS COM SUCESSO!           ║${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}🔍 Verificações finais:${NC}"
echo ""
echo "1. Teste o upload novamente no site"
echo "2. Verifique se o erro 413 não aparece mais"
echo "3. Se ainda houver problemas, execute:"
echo -e "   ${YELLOW}sudo ./instalador/diagnosticar-nginx.sh${NC}"
echo ""

echo -e "${GREEN}✅ Processo concluído!${NC}"
