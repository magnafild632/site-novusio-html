#!/bin/bash

# =============================================================================
# DIAGNÓSTICO NGINX - NOVUSIO
# =============================================================================
# Script para diagnosticar problemas de upload e configuração do Nginx
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
echo -e "${BLUE}║           🔍 DIAGNÓSTICO NGINX - NOVUSIO                ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se está como root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Execute como root: sudo $0${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Verificações que serão feitas:${NC}"
echo "  ✅ Status do Nginx"
echo "  ✅ Configurações ativas"
echo "  ✅ Limites de upload"
echo "  ✅ Teste de configuração"
echo "  ✅ Logs de erro recentes"
echo ""

read -p "Continuar com o diagnóstico? (Y/n): " CONTINUE
if [[ "$CONTINUE" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}❌ Cancelado${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[1/8]${NC} Verificando status do Nginx..."

# Status do Nginx
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx está ativo${NC}"
    systemctl status nginx --no-pager -l | head -10
else
    echo -e "${RED}❌ Nginx não está ativo${NC}"
    systemctl status nginx --no-pager -l | head -10
fi

echo ""
echo -e "${BLUE}[2/8]${NC} Verificando configurações ativas..."

# Verificar configurações ativas
echo -e "${YELLOW}📁 Sites habilitados:${NC}"
ls -la /etc/nginx/sites-enabled/ 2>/dev/null || echo "Nenhum site encontrado"

echo ""
echo -e "${YELLOW}📁 Sites disponíveis:${NC}"
ls -la /etc/nginx/sites-available/ 2>/dev/null || echo "Nenhum site encontrado"

echo ""
echo -e "${BLUE}[3/8]${NC} Verificando limites de upload..."

# Verificar configurações de upload
echo -e "${YELLOW}🔍 Procurando configurações de client_max_body_size:${NC}"
grep -r "client_max_body_size" /etc/nginx/ 2>/dev/null || echo "Nenhuma configuração encontrada"

echo ""
echo -e "${YELLOW}🔍 Verificando configuração específica do Novusio:${NC}"
if [[ -f "/etc/nginx/sites-available/novusiopy" ]]; then
    echo -e "${GREEN}✓ Arquivo de configuração encontrado${NC}"
    echo "Conteúdo relacionado a uploads:"
    grep -A 5 -B 5 "client_max_body_size\|/api/\|/uploads/" /etc/nginx/sites-available/novusiopy || echo "Nenhuma configuração de upload encontrada"
else
    echo -e "${RED}❌ Arquivo de configuração não encontrado${NC}"
    echo "Procurando arquivos similares..."
    find /etc/nginx/sites-available/ -name "*novusio*" -o -name "*novus*" 2>/dev/null || echo "Nenhum arquivo relacionado encontrado"
fi

echo ""
echo -e "${BLUE}[4/8]${NC} Testando configuração do Nginx..."

# Testar configuração
echo -e "${YELLOW}🧪 Testando configuração...${NC}"
if nginx -t 2>&1; then
    echo -e "${GREEN}✓ Configuração do Nginx está válida${NC}"
else
    echo -e "${RED}❌ Erro na configuração do Nginx${NC}"
fi

echo ""
echo -e "${BLUE}[5/8]${NC} Verificando logs de erro recentes..."

# Verificar logs de erro
echo -e "${YELLOW}📝 Últimas 20 linhas do log de erro do Nginx:${NC}"
tail -20 /var/log/nginx/error.log 2>/dev/null || echo "Log de erro não encontrado"

echo ""
echo -e "${YELLOW}📝 Logs de acesso recentes (últimas 10 linhas):${NC}"
tail -10 /var/log/nginx/access.log 2>/dev/null || echo "Log de acesso não encontrado"

echo ""
echo -e "${BLUE}[6/8]${NC} Verificando configuração global do Nginx..."

# Verificar configuração global
echo -e "${YELLOW}🌐 Verificando nginx.conf principal:${NC}"
if [[ -f "/etc/nginx/nginx.conf" ]]; then
    echo "Configurações relevantes:"
    grep -A 3 -B 3 "client_max_body_size\|http {" /etc/nginx/nginx.conf || echo "Nenhuma configuração relevante encontrada"
else
    echo -e "${RED}❌ Arquivo nginx.conf principal não encontrado${NC}"
fi

echo ""
echo -e "${BLUE}[7/8]${NC} Verificando status da aplicação..."

# Verificar PM2
echo -e "${YELLOW}🚀 Status do PM2:${NC}"
if command -v pm2 &> /dev/null; then
    pm2 list 2>/dev/null || echo "PM2 não está rodando"
else
    echo "PM2 não instalado"
fi

echo ""
echo -e "${BLUE}[8/8]${NC} Testando conectividade..."

# Testar conectividade
echo -e "${YELLOW}🌐 Testando conectividade local:${NC}"
if curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:3000/api/health 2>/dev/null; then
    echo -e "${GREEN}✓ API local está respondendo${NC}"
else
    echo -e "${RED}❌ API local não está respondendo${NC}"
fi

echo ""
echo -e "${YELLOW}🌐 Testando através do Nginx:${NC}"
if curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/api/health 2>/dev/null; then
    echo -e "${GREEN}✓ Nginx está proxyando corretamente${NC}"
else
    echo -e "${RED}❌ Nginx não está proxyando corretamente${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}║              📊 DIAGNÓSTICO CONCLUÍDO!                  ║${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}🔧 Próximos passos recomendados:${NC}"
echo ""
echo "1. Se o Nginx não está ativo:"
echo -e "   ${YELLOW}sudo systemctl start nginx${NC}"
echo ""
echo "2. Se há erro na configuração:"
echo -e "   ${YELLOW}sudo nano /etc/nginx/sites-available/novusiopy${NC}"
echo ""
echo "3. Para aplicar mudanças:"
echo -e "   ${YELLOW}sudo systemctl reload nginx${NC}"
echo -e "   ${YELLOW}sudo systemctl restart nginx${NC}"
echo ""
echo "4. Para forçar atualização completa:"
echo -e "   ${YELLOW}sudo ./instalador/atualizar-correcoes.sh${NC}"
echo ""
echo "5. Para verificar logs em tempo real:"
echo -e "   ${YELLOW}sudo tail -f /var/log/nginx/error.log${NC}"
echo ""

echo -e "${GREEN}✅ Diagnóstico finalizado!${NC}"
