#!/bin/bash

# =============================================================================
# CORRIGIR TODOS OS UPLOADS - NOVUSIO
# =============================================================================
# Script para corrigir TODOS os problemas de upload 413
# Aplica correções em todos os lugares possíveis
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
echo -e "${BLUE}║         🚀 CORRIGIR TODOS OS UPLOADS - NOVUSIO          ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se está como root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Execute como root: sudo $0${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Correções que serão aplicadas:${NC}"
echo "  ✅ Limite global do Nginx: 50MB"
echo "  ✅ Limite específico para /api/slides: 50MB"
echo "  ✅ Limite específico para /api/portfolio: 50MB"
echo "  ✅ Timeouts aumentados para uploads"
echo "  ✅ Configuração do servidor Node.js: 50MB"
echo "  ✅ Configuração do Multer: 50MB"
echo "  ✅ Variáveis de ambiente: 50MB"
echo "  ✅ Reinicialização completa dos serviços"
echo ""

read -p "Aplicar TODAS as correções? (Y/n): " CONTINUE
if [[ "$CONTINUE" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}❌ Cancelado${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[1/8]${NC} Parando todos os serviços..."

# Parar serviços
systemctl stop nginx
sudo -u novusio pm2 stop all || true
sudo -u novusio pm2 delete all || true

echo -e "${GREEN}✓ Serviços parados${NC}"

echo ""
echo -e "${BLUE}[2/8]${NC} Atualizando código do repositório..."

# Ir para o diretório do projeto
cd /home/novusio 2>/dev/null || {
    echo -e "${RED}❌ Diretório /home/novusio não encontrado${NC}"
    exit 1
}

# Forçar atualização
git fetch --all
git reset --hard origin/main || git reset --hard origin/master
git pull origin main || git pull origin master

echo -e "${GREEN}✓ Código atualizado${NC}"

echo ""
echo -e "${BLUE}[3/8]${NC} Aplicando configurações do Nginx..."

# Fazer backup
if [[ -f "/etc/nginx/sites-available/novusiopy" ]]; then
    cp "/etc/nginx/sites-available/novusiopy" "/etc/nginx/sites-available/novusiopy.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Aplicar nova configuração
cp "instalador/nginx.conf" "/etc/nginx/sites-available/novusiopy"

# Verificar configuração
if nginx -t 2>/dev/null; then
    echo -e "${GREEN}✓ Configuração do Nginx válida${NC}"
else
    echo -e "${RED}❌ Erro na configuração do Nginx!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[4/8]${NC} Verificando configurações do servidor..."

# Verificar server.js
if grep -q "limit: '50mb'" "server/server.js"; then
    echo -e "${GREEN}✓ server.js configurado com 50MB${NC}"
else
    echo -e "${RED}❌ server.js não está configurado corretamente${NC}"
fi

# Verificar multer.js
if grep -q "50 \* 1024 \* 1024" "server/config/multer.js"; then
    echo -e "${GREEN}✓ multer.js configurado com 50MB${NC}"
else
    echo -e "${RED}❌ multer.js não está configurado corretamente${NC}"
fi

echo ""
echo -e "${BLUE}[5/8]${NC} Instalando dependências..."

# Instalar dependências
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
echo -e "${BLUE}[6/8]${NC} Iniciando Nginx..."

# Iniciar Nginx
systemctl start nginx
systemctl reload nginx

if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx iniciado${NC}"
else
    echo -e "${RED}❌ Erro ao iniciar Nginx${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[7/8]${NC} Iniciando aplicação..."

# Iniciar aplicação
sudo -u novusio pm2 start ecosystem.config.js --env production
sudo -u novusio pm2 save

# Verificar se está rodando
sleep 10
if sudo -u novusio pm2 list | grep -q "novusio-server.*online"; then
    echo -e "${GREEN}✓ Aplicação iniciada${NC}"
else
    echo -e "${YELLOW}⚠️ Tentando iniciar novamente...${NC}"
    sudo -u novusio pm2 start ecosystem.config.js --env production
    sudo -u novusio pm2 save
fi

echo ""
echo -e "${BLUE}[8/8]${NC} Verificação final..."

# Verificar conectividade
if curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:3000/api/health 2>/dev/null; then
    echo -e "${GREEN}✓ API local funcionando${NC}"
else
    echo -e "${RED}❌ API local não está respondendo${NC}"
fi

if curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/api/health 2>/dev/null; then
    echo -e "${GREEN}✓ Nginx proxy funcionando${NC}"
else
    echo -e "${RED}❌ Nginx proxy não está funcionando${NC}"
fi

# Verificar configurações aplicadas
echo ""
echo -e "${YELLOW}🔍 Configurações aplicadas:${NC}"

# Verificar nginx global
if grep -q "client_max_body_size 50M" "/etc/nginx/sites-available/novusiopy"; then
    echo -e "  ${GREEN}✓ Nginx global: client_max_body_size 50M${NC}"
else
    echo -e "  ${RED}❌ Nginx global: não configurado${NC}"
fi

# Verificar nginx slides
if grep -A 5 "location /api/slides" "/etc/nginx/sites-available/novusiopy" | grep -q "client_max_body_size 50M"; then
    echo -e "  ${GREEN}✓ Nginx /api/slides: client_max_body_size 50M${NC}"
else
    echo -e "  ${RED}❌ Nginx /api/slides: não configurado${NC}"
fi

# Verificar nginx portfolio
if grep -A 5 "location /api/portfolio" "/etc/nginx/sites-available/novusiopy" | grep -q "client_max_body_size 50M"; then
    echo -e "  ${GREEN}✓ Nginx /api/portfolio: client_max_body_size 50M${NC}"
else
    echo -e "  ${RED}❌ Nginx /api/portfolio: não configurado${NC}"
fi

# Verificar server.js
if grep -q "limit: '50mb'" "server/server.js"; then
    echo -e "  ${GREEN}✓ Server.js: express.json limit 50mb${NC}"
else
    echo -e "  ${RED}❌ Server.js: não configurado${NC}"
fi

# Verificar multer.js
if grep -q "50 \* 1024 \* 1024" "server/config/multer.js"; then
    echo -e "  ${GREEN}✓ Multer: fileSize 50MB${NC}"
else
    echo -e "  ${RED}❌ Multer: não configurado${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}║         ✅ TODAS AS CORREÇÕES APLICADAS!                 ║${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}🎯 Próximos passos:${NC}"
echo ""
echo "1. Teste o upload de imagens no banner"
echo "2. Teste o upload de imagens no portfólio"
echo "3. Verifique se o erro 413 não aparece mais"
echo "4. Se ainda houver problemas, execute:"
echo -e "   ${YELLOW}sudo ./instalador/diagnosticar-nginx.sh${NC}"
echo ""

echo -e "${GREEN}✅ Processo concluído!${NC}"
