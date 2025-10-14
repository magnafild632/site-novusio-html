#!/bin/bash

# =============================================================================
# CORRIGIR PERMISSÕES GIT - NOVUSIO
# =============================================================================
# Script para corrigir problemas de permissão do Git
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
echo -e "${BLUE}║         🔧 CORRIGIR PERMISSÕES GIT - NOVUSIO           ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se está como root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Execute como root: sudo $0${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Correções que serão aplicadas:${NC}"
echo "  ✅ Configurar Git safe.directory para /home/novusio"
echo "  ✅ Corrigir permissões do diretório do projeto"
echo "  ✅ Configurar Git para o usuário novusio"
echo "  ✅ Verificar se as correções foram aplicadas"
echo ""

read -p "Aplicar correções de permissão? (Y/n): " CONTINUE
if [[ "$CONTINUE" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}❌ Cancelado${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[1/6]${NC} Configurando Git safe.directory..."

# Configurar Git safe.directory para root
git config --global --add safe.directory /home/novusio
echo -e "${GREEN}✓ Git safe.directory configurado para root${NC}"

# Configurar Git safe.directory para o usuário novusio
sudo -u novusio git config --global --add safe.directory /home/novusio
echo -e "${GREEN}✓ Git safe.directory configurado para usuário novusio${NC}"

echo ""
echo -e "${BLUE}[2/6]${NC} Corrigindo permissões do diretório..."

# Ir para o diretório do projeto
cd /home/novusio

# Corrigir permissões
chown -R novusio:novusio /home/novusio
chmod -R 755 /home/novusio
chmod -R 644 /home/novusio/.git/* 2>/dev/null || true
chmod 755 /home/novusio/.git 2>/dev/null || true

echo -e "${GREEN}✓ Permissões corrigidas${NC}"

echo ""
echo -e "${BLUE}[3/6]${NC} Configurando Git para o usuário novusio..."

# Configurar Git básico para o usuário novusio
sudo -u novusio git config --global user.name "Novusio Server" 2>/dev/null || true
sudo -u novusio git config --global user.email "server@novusio.com" 2>/dev/null || true
sudo -u novusio git config --global init.defaultBranch main 2>/dev/null || true

echo -e "${GREEN}✓ Git configurado para usuário novusio${NC}"

echo ""
echo -e "${BLUE}[4/6]${NC} Testando acesso ao Git..."

# Testar se o Git funciona
if sudo -u novusio git status >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Git funcionando para usuário novusio${NC}"
else
    echo -e "${YELLOW}⚠️ Git ainda pode ter problemas, mas continuando...${NC}"
fi

echo ""
echo -e "${BLUE}[5/6]${NC} Configurando variáveis de ambiente..."

# Configurar variáveis de ambiente para Git
echo 'export GIT_CONFIG_GLOBAL="/home/novusio/.gitconfig"' >> /home/novusio/.bashrc
echo 'export GIT_CONFIG_SYSTEM="/etc/gitconfig"' >> /home/novusio/.bashrc

echo -e "${GREEN}✓ Variáveis de ambiente configuradas${NC}"

echo ""
echo -e "${BLUE}[6/6]${NC} Verificação final..."

# Verificar configurações
echo -e "${YELLOW}🔍 Configurações aplicadas:${NC}"

# Verificar safe.directory
if git config --global --get-all safe.directory | grep -q "/home/novusio"; then
    echo -e "  ${GREEN}✓ Git safe.directory configurado para root${NC}"
else
    echo -e "  ${RED}❌ Git safe.directory NÃO configurado para root${NC}"
fi

# Verificar safe.directory para usuário novusio
if sudo -u novusio git config --global --get-all safe.directory 2>/dev/null | grep -q "/home/novusio"; then
    echo -e "  ${GREEN}✓ Git safe.directory configurado para novusio${NC}"
else
    echo -e "  ${RED}❌ Git safe.directory NÃO configurado para novusio${NC}"
fi

# Verificar permissões
if [[ $(stat -c %U /home/novusio) == "novusio" ]]; then
    echo -e "  ${GREEN}✓ Proprietário do diretório: novusio${NC}"
else
    echo -e "  ${RED}❌ Proprietário do diretório incorreto${NC}"
fi

# Teste final
if sudo -u novusio git status >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓ Teste final do Git: OK${NC}"
else
    echo -e "  ${YELLOW}⚠️ Teste final do Git: pode ter problemas${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}║        ✅ PERMISSÕES GIT CORRIGIDAS!                     ║${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}🎯 Próximos passos:${NC}"
echo ""
echo "1. Execute novamente a atualização da aplicação"
echo "2. O erro de 'dubious ownership' não deve mais aparecer"
echo "3. Se ainda houver problemas, execute:"
echo -e "   ${YELLOW}sudo ./instalador/deploy.sh${NC}"
echo "   ${YELLOW}Escolha a opção 2 (Atualizar Aplicação)${NC}"
echo ""

echo -e "${GREEN}✅ Processo concluído!${NC}"
