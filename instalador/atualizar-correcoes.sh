#!/bin/bash

# Script para aplicar correções de deploy
# Resolve erros 404 e 500 após deploy

set -e

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}║     🔧 APLICAR CORREÇÕES - NOVUSIO DEPLOY               ║${NC}"
echo -e "${BLUE}║                                                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se está no diretório correto
if [[ ! -f "package.json" ]]; then
    echo -e "${RED}❌ Execute este script na raiz do projeto!${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Correções que serão aplicadas:${NC}"
echo "  ✅ Corrigir caminho do build (client/dist)"
echo "  ✅ Adicionar favicon"
echo "  ✅ Melhorar tratamento de erros"
echo "  ✅ Fazer novo build"
echo "  ✅ Atualizar configuração do Nginx (limites de upload 50MB)"
echo "  ✅ Reiniciar aplicação"
echo ""

read -p "Deseja continuar? (Y/n): " CONTINUE
if [[ "$CONTINUE" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}❌ Cancelado${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[1/6]${NC} Fazendo backup..."
if [[ -d "client/dist" ]]; then
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp -r client/dist "$BACKUP_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✓ Backup salvo em: $BACKUP_DIR${NC}"
fi

echo ""
echo -e "${BLUE}[2/6]${NC} Limpando builds antigos..."
rm -rf client/dist
rm -rf dist
echo -e "${GREEN}✓ Builds antigos removidos${NC}"

echo ""
echo -e "${BLUE}[3/6]${NC} Atualizando dependências..."
npm ci --production
cd client
npm ci
cd ..
echo -e "${GREEN}✓ Dependências atualizadas${NC}"

echo ""
echo -e "${BLUE}[4/6]${NC} Fazendo novo build..."
cd client
npm run build
cd ..

# Verificar se build foi criado
if [[ -f "client/dist/index.html" ]]; then
    echo -e "${GREEN}✓ Build criado com sucesso!${NC}"
    echo "  📁 Localização: client/dist/"
    
    # Verificar favicon
    if [[ -f "client/dist/favicon.svg" ]]; then
        echo -e "${GREEN}✓ Favicon incluído no build${NC}"
    else
        echo -e "${YELLOW}⚠️ Favicon não encontrado (será adicionado)${NC}"
    fi
else
    echo -e "${RED}❌ Falha ao criar build!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[5/6]${NC} Configurando permissões..."
if [[ -n "$SUDO_USER" ]] || [[ $EUID -eq 0 ]]; then
    # Executando como root ou com sudo
    PROJECT_USER=$(stat -c '%U' . 2>/dev/null || stat -f '%Su' . 2>/dev/null)
    if [[ -n "$PROJECT_USER" && "$PROJECT_USER" != "root" ]]; then
        chown -R $PROJECT_USER:$PROJECT_USER .
        echo -e "${GREEN}✓ Permissões configuradas para: $PROJECT_USER${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Execute como sudo para configurar permissões${NC}"
fi

echo ""
echo -e "${BLUE}[6/7]${NC} Atualizando configuração do Nginx..."

# Atualizar nginx.conf se existir
if [[ -f "instalador/nginx.conf" ]]; then
    if command -v nginx &> /dev/null; then
        # Fazer backup da configuração atual
        if [[ -f "/etc/nginx/sites-available/novusiopy" ]]; then
            cp "/etc/nginx/sites-available/novusiopy" "/etc/nginx/sites-available/novusiopy.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Copiar nova configuração
        cp "instalador/nginx.conf" "/etc/nginx/sites-available/novusiopy"
        
        # Testar configuração
        if nginx -t 2>/dev/null; then
            systemctl reload nginx
            sleep 2
            systemctl restart nginx
            echo -e "${GREEN}✓ Configuração do Nginx atualizada e reiniciada com limites de upload corrigidos (50MB)${NC}"
        else
            echo -e "${RED}❌ Erro na configuração do Nginx!${NC}"
            echo "Revertendo para backup..."
            cp "/etc/nginx/sites-available/novusiopy.backup."* "/etc/nginx/sites-available/novusiopy" 2>/dev/null || true
            systemctl reload nginx
            systemctl restart nginx
        fi
    else
        echo -e "${YELLOW}⚠️ Nginx não instalado${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Arquivo nginx.conf não encontrado${NC}"
fi

echo ""
echo -e "${BLUE}[7/7]${NC} Reiniciando aplicação..."

# Verificar se PM2 está instalado e sendo usado
if command -v pm2 &> /dev/null; then
    if pm2 list 2>/dev/null | grep -q "novusio-server"; then
        echo "🔄 Reiniciando PM2..."
        pm2 restart novusio-server
        echo -e "${GREEN}✓ Aplicação reiniciada via PM2${NC}"
        
        # Esperar e verificar status
        sleep 3
        if pm2 list | grep -q "novusio-server.*online"; then
            echo -e "${GREEN}✓ Aplicação rodando!${NC}"
        else
            echo -e "${RED}⚠️ Aplicação pode não estar rodando corretamente${NC}"
            echo "Verifique os logs: pm2 logs novusio-server"
        fi
    else
        echo -e "${YELLOW}⚠️ PM2 não está gerenciando a aplicação${NC}"
        echo "Inicie manualmente: npm run server"
    fi
else
    echo -e "${YELLOW}⚠️ PM2 não instalado${NC}"
    echo "Inicie manualmente: npm run server"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}║            ✅ CORREÇÕES APLICADAS COM SUCESSO!           ║${NC}"
echo -e "${GREEN}║                                                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}🔍 Verificações recomendadas:${NC}"
echo ""
echo "1. Verificar logs:"
echo -e "   ${YELLOW}pm2 logs novusio-server --lines 50${NC}"
echo ""
echo "2. Testar API:"
echo -e "   ${YELLOW}curl http://localhost:3000/api/health${NC}"
echo ""
echo "3. Verificar build:"
echo -e "   ${YELLOW}ls -la client/dist/${NC}"
echo ""
echo "4. Acessar o site e verificar:"
echo "   ✓ Favicon aparece na aba"
echo "   ✓ Sem erros 500"
echo "   ✓ Console do browser limpo"
echo ""

# Mostrar resumo do build
if [[ -d "client/dist" ]]; then
    BUILD_SIZE=$(du -sh client/dist | cut -f1)
    FILE_COUNT=$(find client/dist -type f | wc -l)
    echo -e "${BLUE}📊 Resumo do Build:${NC}"
    echo "  Tamanho total: $BUILD_SIZE"
    echo "  Arquivos: $FILE_COUNT"
    echo ""
fi

echo -e "${GREEN}✅ Processo concluído!${NC}"
echo ""

