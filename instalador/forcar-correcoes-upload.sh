#!/bin/bash

# =============================================================================
# FORÇAR CORREÇÕES DE UPLOAD - NOVUSIO
# =============================================================================
# Script para FORÇAR a aplicação de todas as correções de upload
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
echo -e "${BLUE}║       🔥 FORÇAR CORREÇÕES DE UPLOAD - NOVUSIO           ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se está como root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Execute como root: sudo $0${NC}"
    exit 1
fi

echo -e "${RED}⚠️  ATENÇÃO: Este script irá FORÇAR todas as correções!${NC}"
echo ""
echo -e "${YELLOW}📋 O que será feito:${NC}"
echo "  🔄 Atualizar código com força"
echo "  🛑 PARAR completamente Nginx e PM2"
echo "  📝 Aplicar configuração nginx.conf"
echo "  🔧 Verificar e corrigir TODAS as configurações"
echo "  🚀 Reiniciar todos os serviços"
echo "  ✅ Verificar se tudo está funcionando"
echo ""

read -p "Continuar com força total? (Y/n): " CONTINUE
if [[ "$CONTINUE" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}❌ Cancelado${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[1/10]${NC} Atualizando código do repositório..."

# Ir para o diretório do projeto
cd /home/novusio 2>/dev/null || {
    echo -e "${RED}❌ Diretório /home/novusio não encontrado${NC}"
    exit 1
}

# Forçar atualização
git fetch --all
git reset --hard origin/main || git reset --hard origin/master
git pull origin main || git pull origin master

echo -e "${GREEN}✓ Código atualizado com força${NC}"

echo ""
echo -e "${BLUE}[2/10]${NC} PARANDO todos os serviços..."

# Parar TUDO
systemctl stop nginx
sudo -u novusio pm2 stop all || true
sudo -u novusio pm2 delete all || true
sudo -u novusio pm2 kill || true

echo -e "${GREEN}✓ Todos os serviços parados${NC}"

echo ""
echo -e "${BLUE}[3/10]${NC} Aplicando configuração do Nginx..."

# Fazer backup
if [[ -f "/etc/nginx/sites-available/novusiopy" ]]; then
    cp "/etc/nginx/sites-available/novusiopy" "/etc/nginx/sites-available/novusiopy.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}✓ Backup criado${NC}"
fi

# Aplicar configuração
if [[ -f "instalador/nginx.conf" ]]; then
    cp "instalador/nginx.conf" "/etc/nginx/sites-available/novusiopy"
    echo -e "${GREEN}✓ Configuração copiada${NC}"
else
    echo -e "${RED}❌ Arquivo nginx.conf não encontrado!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[4/10]${NC} Verificando configurações do Nginx..."

# Verificar configuração global
if grep -q "client_max_body_size 50M" "/etc/nginx/sites-available/novusiopy"; then
    echo -e "${GREEN}✓ Configuração global de 50MB encontrada${NC}"
else
    echo -e "${RED}❌ Configuração global de 50MB NÃO encontrada!${NC}"
    echo "Adicionando configuração global..."
    sed -i '1i client_max_body_size 50M;' "/etc/nginx/sites-available/novusiopy"
fi

# Verificar configuração para /api/slides
if grep -A 10 "location /api/slides" "/etc/nginx/sites-available/novusiopy" | grep -q "client_max_body_size 50M"; then
    echo -e "${GREEN}✓ Configuração /api/slides de 50MB encontrada${NC}"
else
    echo -e "${RED}❌ Configuração /api/slides de 50MB NÃO encontrada!${NC}"
fi

# Verificar configuração para /api/portfolio
if grep -A 10 "location /api/portfolio" "/etc/nginx/sites-available/novusiopy" | grep -q "client_max_body_size 50M"; then
    echo -e "${GREEN}✓ Configuração /api/portfolio de 50MB encontrada${NC}"
else
    echo -e "${RED}❌ Configuração /api/portfolio de 50MB NÃO encontrada!${NC}"
fi

echo ""
echo -e "${BLUE}[5/10]${NC} Testando configuração do Nginx..."

# Testar configuração
if nginx -t 2>/dev/null; then
    echo -e "${GREEN}✓ Configuração do Nginx válida${NC}"
else
    echo -e "${RED}❌ Erro na configuração do Nginx!${NC}"
    echo "Mostrando erro:"
    nginx -t
    exit 1
fi

echo ""
echo -e "${BLUE}[6/10]${NC} Verificando configurações do servidor Node.js..."

# Verificar server.js
if [[ -f "server/server.js" ]]; then
    if grep -q "limit: '50mb'" "server/server.js"; then
        echo -e "${GREEN}✓ server.js configurado com 50MB${NC}"
    else
        echo -e "${RED}❌ server.js NÃO configurado com 50MB!${NC}"
        echo "Corrigindo server.js..."
        sed -i "s/limit: '[^']*'/limit: '50mb'/g" "server/server.js"
    fi
fi

# Verificar multer.js
if [[ -f "server/config/multer.js" ]]; then
    if grep -q "50 \* 1024 \* 1024" "server/config/multer.js"; then
        echo -e "${GREEN}✓ multer.js configurado com 50MB${NC}"
    else
        echo -e "${RED}❌ multer.js NÃO configurado com 50MB!${NC}"
        echo "Corrigindo multer.js..."
        sed -i "s/fileSize: [0-9]* \* 1024 \* 1024/fileSize: 50 * 1024 * 1024/g" "server/config/multer.js"
    fi
fi

echo ""
echo -e "${BLUE}[7/10]${NC} Instalando dependências..."

# Limpar e reinstalar dependências
rm -rf node_modules package-lock.json
npm ci --production

if [[ -d "client" ]]; then
    cd client
    rm -rf node_modules package-lock.json dist
    npm ci
    npm run build
    cd ..
fi

echo -e "${GREEN}✓ Dependências instaladas${NC}"

echo ""
echo -e "${BLUE}[8/10]${NC} Iniciando Nginx..."

# Iniciar Nginx
systemctl start nginx
sleep 3
systemctl reload nginx

if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx iniciado e funcionando${NC}"
else
    echo -e "${RED}❌ Erro ao iniciar Nginx${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[9/10]${NC} Iniciando aplicação..."

# Iniciar aplicação
sudo -u novusio pm2 start ecosystem.config.js --env production
sudo -u novusio pm2 save

# Verificar se está rodando
sleep 10
if sudo -u novusio pm2 list | grep -q "novusio-server.*online"; then
    echo -e "${GREEN}✓ Aplicação iniciada e funcionando${NC}"
else
    echo -e "${YELLOW}⚠️ Tentando iniciar novamente...${NC}"
    sudo -u novusio pm2 start ecosystem.config.js --env production
    sudo -u novusio pm2 save
    sleep 5
fi

echo ""
echo -e "${BLUE}[10/10]${NC} Verificação final completa..."

# Verificar conectividade
echo -e "${YELLOW}🌐 Testando conectividade:${NC}"

# Teste 1: API local
if curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:3000/api/health 2>/dev/null | grep -q "200"; then
    echo -e "${GREEN}✓ API local funcionando (200)${NC}"
else
    echo -e "${RED}❌ API local não está respondendo${NC}"
fi

# Teste 2: Nginx proxy
if curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/api/health 2>/dev/null | grep -q "200"; then
    echo -e "${GREEN}✓ Nginx proxy funcionando (200)${NC}"
else
    echo -e "${RED}❌ Nginx proxy não está funcionando${NC}"
fi

# Verificação final das configurações
echo ""
echo -e "${YELLOW}🔍 Verificação final das configurações:${NC}"

# Verificar nginx global
if grep -q "client_max_body_size 50M" "/etc/nginx/sites-available/novusiopy"; then
    echo -e "  ${GREEN}✓ Nginx global: 50MB${NC}"
else
    echo -e "  ${RED}❌ Nginx global: NÃO configurado${NC}"
fi

# Verificar nginx slides
if grep -A 5 "location /api/slides" "/etc/nginx/sites-available/novusiopy" | grep -q "client_max_body_size 50M"; then
    echo -e "  ${GREEN}✓ Nginx /api/slides: 50MB${NC}"
else
    echo -e "  ${RED}❌ Nginx /api/slides: NÃO configurado${NC}"
fi

# Verificar nginx portfolio
if grep -A 5 "location /api/portfolio" "/etc/nginx/sites-available/novusiopy" | grep -q "client_max_body_size 50M"; then
    echo -e "  ${GREEN}✓ Nginx /api/portfolio: 50MB${NC}"
else
    echo -e "  ${RED}❌ Nginx /api/portfolio: NÃO configurado${NC}"
fi

# Verificar server.js
if grep -q "limit: '50mb'" "server/server.js"; then
    echo -e "  ${GREEN}✓ Server.js: 50MB${NC}"
else
    echo -e "  ${RED}❌ Server.js: NÃO configurado${NC}"
fi

# Verificar multer.js
if grep -q "50 \* 1024 \* 1024" "server/config/multer.js"; then
    echo -e "  ${GREEN}✓ Multer: 50MB${NC}"
else
    echo -e "  ${RED}❌ Multer: NÃO configurado${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}║        🔥 CORREÇÕES FORÇADAS APLICADAS!                  ║${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}🎯 TESTE AGORA:${NC}"
echo ""
echo "1. Acesse o admin do site"
echo "2. Tente fazer upload de uma imagem no banner"
echo "3. Tente fazer upload de uma imagem no portfólio"
echo "4. Verifique se o erro 413 não aparece mais"
echo ""

echo -e "${YELLOW}📊 Status dos serviços:${NC}"
echo "Nginx: $(systemctl is-active nginx)"
echo "PM2: $(sudo -u novusio pm2 list | grep novusio-server | awk '{print $10}' || echo 'Não encontrado')"
echo ""

echo -e "${GREEN}✅ Processo concluído com força total!${NC}"
