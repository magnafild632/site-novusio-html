#!/bin/bash

# =============================================================================
# FORÇAR ATUALIZAÇÃO COMPLETA - NOVUSIO
# =============================================================================
# Script para forçar atualização completa e corrigir problemas de upload
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
echo -e "${BLUE}║         🔥 FORÇAR ATUALIZAÇÃO COMPLETA - NOVUSIO        ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se está como root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Execute como root: sudo $0${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  ATENÇÃO: Este script irá forçar a atualização completa!${NC}"
echo ""
echo -e "${YELLOW}📋 O que será feito:${NC}"
echo "  🔄 Atualizar código do repositório"
echo "  🔨 Fazer novo build da aplicação"
echo "  🌐 FORÇAR substituição da configuração do Nginx"
echo "  🛠️  Aplicar correções de upload (50MB)"
echo "  🔄 Reiniciar TODOS os serviços"
echo "  ✅ Verificar se tudo está funcionando"
echo ""

read -p "Continuar com a atualização forçada? (Y/n): " CONTINUE
if [[ "$CONTINUE" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}❌ Atualização cancelada${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[1/8]${NC} Atualizando código do repositório..."

# Ir para o diretório do projeto
cd /home/novusio 2>/dev/null || {
    echo -e "${RED}❌ Diretório /home/novusio não encontrado${NC}"
    exit 1
}

# Fazer pull forçado
git fetch --all
git reset --hard origin/main || git reset --hard origin/master
git pull origin main || git pull origin master

echo -e "${GREEN}✓ Código atualizado com força${NC}"

echo ""
echo -e "${BLUE}[2/8]${NC} Instalando dependências..."

# Instalar dependências
npm ci --production

if [[ -d "client" ]]; then
    cd client
    npm ci
    cd ..
fi

echo -e "${GREEN}✓ Dependências atualizadas${NC}"

echo ""
echo -e "${BLUE}[3/8]${NC} Fazendo novo build..."

# Build da aplicação
if [[ -d "client" ]]; then
    cd client
    rm -rf dist
    npm run build
    cd ..
    echo -e "${GREEN}✓ Build criado${NC}"
else
    echo -e "${YELLOW}⚠️ Diretório client não encontrado${NC}"
fi

echo ""
echo -e "${BLUE}[4/8]${NC} Forçando atualização da configuração do Nginx..."

# Forçar atualização do Nginx
if [[ -f "instalador/nginx.conf" ]]; then
    # Parar nginx
    systemctl stop nginx
    echo -e "${YELLOW}✓ Nginx parado${NC}"
    
    # Backup da configuração atual
    if [[ -f "/etc/nginx/sites-available/novusiopy" ]]; then
        cp "/etc/nginx/sites-available/novusiopy" "/etc/nginx/sites-available/novusiopy.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}✓ Backup criado${NC}"
    fi
    
    # Copiar nova configuração
    cp "instalador/nginx.conf" "/etc/nginx/sites-available/novusiopy"
    
    # Verificar configuração
    if nginx -t 2>/dev/null; then
        echo -e "${GREEN}✓ Configuração válida${NC}"
        
        # Verificar se tem os limites corretos
        if grep -q "client_max_body_size 50M" "/etc/nginx/sites-available/novusiopy"; then
            echo -e "${GREEN}✓ Limite de 50MB confirmado${NC}"
        else
            echo -e "${RED}❌ Limite de 50MB NÃO encontrado!${NC}"
        fi
        
        # Iniciar nginx
        systemctl start nginx
        sleep 3
        systemctl reload nginx
        
        if systemctl is-active --quiet nginx; then
            echo -e "${GREEN}✓ Nginx reiniciado com sucesso${NC}"
        else
            echo -e "${RED}❌ Erro ao reiniciar Nginx${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Erro na configuração do Nginx!${NC}"
        # Tentar restaurar backup
        if ls /etc/nginx/sites-available/novusiopy.backup.* 1> /dev/null 2>&1; then
            cp /etc/nginx/sites-available/novusiopy.backup.* /etc/nginx/sites-available/novusiopy 2>/dev/null || true
            systemctl start nginx
            echo -e "${YELLOW}⚠️ Restaurado backup da configuração${NC}"
        fi
        exit 1
    fi
else
    echo -e "${RED}❌ Arquivo nginx.conf não encontrado!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[5/8]${NC} Verificando configuração do servidor Node.js..."

# Verificar server.js
if [[ -f "server/server.js" ]]; then
    if grep -q "limit: '50mb'" "server/server.js"; then
        echo -e "${GREEN}✓ server.js configurado com limite de 50MB${NC}"
    else
        echo -e "${YELLOW}⚠️ server.js pode precisar de atualização${NC}"
    fi
fi

# Verificar multer.js
if [[ -f "server/config/multer.js" ]]; then
    if grep -q "50 \* 1024 \* 1024" "server/config/multer.js"; then
        echo -e "${GREEN}✓ multer.js configurado com limite de 50MB${NC}"
    else
        echo -e "${YELLOW}⚠️ multer.js pode precisar de atualização${NC}"
    fi
fi

echo ""
echo -e "${BLUE}[6/8]${NC} Reiniciando aplicação..."

# Reiniciar PM2
if command -v pm2 &> /dev/null; then
    if pm2 list 2>/dev/null | grep -q "novusio-server"; then
        pm2 stop novusio-server
        sleep 2
        pm2 start ecosystem.config.js --env production
        pm2 save
        echo -e "${GREEN}✓ Aplicação reiniciada via PM2${NC}"
        
        # Verificar status
        sleep 5
        if pm2 list | grep -q "novusio-server.*online"; then
            echo -e "${GREEN}✓ Aplicação rodando${NC}"
        else
            echo -e "${RED}❌ Aplicação pode não estar rodando corretamente${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ PM2 não está gerenciando a aplicação${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ PM2 não instalado${NC}"
fi

echo ""
echo -e "${BLUE}[7/8]${NC} Verificando conectividade..."

# Testar conectividade
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

echo ""
echo -e "${BLUE}[8/8]${NC} Verificação final das configurações..."

# Verificar configurações finais
echo -e "${YELLOW}🔍 Configurações aplicadas:${NC}"

# Verificar nginx
if grep -q "client_max_body_size 50M" "/etc/nginx/sites-available/novusiopy"; then
    echo -e "  ${GREEN}✓ Nginx: client_max_body_size 50M${NC}"
else
    echo -e "  ${RED}❌ Nginx: limite não configurado${NC}"
fi

# Verificar server.js
if grep -q "limit: '50mb'" "server/server.js"; then
    echo -e "  ${GREEN}✓ Server.js: express.json limit 50mb${NC}"
else
    echo -e "  ${RED}❌ Server.js: limite não configurado${NC}"
fi

# Verificar multer.js
if grep -q "50 \* 1024 \* 1024" "server/config/multer.js"; then
    echo -e "  ${GREEN}✓ Multer: fileSize 50MB${NC}"
else
    echo -e "  ${RED}❌ Multer: limite não configurado${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}║          ✅ ATUALIZAÇÃO FORÇADA CONCLUÍDA!              ║${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}🔍 Próximos passos:${NC}"
echo ""
echo "1. Teste o upload novamente no site"
echo "2. Verifique se o erro 413 não aparece mais"
echo "3. Se ainda houver problemas, execute:"
echo -e "   ${YELLOW}sudo ./instalador/diagnosticar-nginx.sh${NC}"
echo ""

echo -e "${GREEN}✅ Processo concluído!${NC}"
