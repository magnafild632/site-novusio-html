#!/bin/bash

# =============================================================================
# REGENERAR SECRETS - NOVUSIO
# =============================================================================
# Script para regenerar JWT_SECRET e SESSION_SECRET
# Use este script se precisar atualizar os secrets de segurança
# =============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verificar se está como root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Execute como root: sudo $0${NC}"
    exit 1
fi

echo -e "${BLUE}🔐 Regenerar Secrets de Segurança - Novusio${NC}"
echo "=============================================="
echo ""
echo -e "${YELLOW}⚠️ ATENÇÃO: Esta ação irá gerar novos secrets!${NC}"
echo -e "${YELLOW}   Isso fará com que todos os usuários precisem fazer login novamente.${NC}"
echo ""
read -p "Tem certeza que deseja continuar? (y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}✅ Operação cancelada${NC}"
    exit 0
fi

# Diretório do projeto
PROJECT_DIR="/home/novusio"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo -e "${RED}❌ Projeto não encontrado em $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

if [[ ! -f ".env" ]]; then
    echo -e "${RED}❌ Arquivo .env não encontrado${NC}"
    exit 1
fi

# Fazer backup do .env atual
BACKUP_FILE=".env.backup-$(date +%Y%m%d_%H%M%S)"
echo -e "${BLUE}📋 Criando backup: $BACKUP_FILE${NC}"
cp .env "$BACKUP_FILE"

# Gerar novos secrets
echo -e "${BLUE}🔐 Gerando novos secrets...${NC}"
NEW_JWT_SECRET=$(openssl rand -base64 48 | tr -d '\n')
NEW_SESSION_SECRET=$(openssl rand -base64 32 | tr -d '\n')

echo -e "${GREEN}✓ Novo JWT Secret gerado: ${NEW_JWT_SECRET:0:10}... (48 bytes)${NC}"
echo -e "${GREEN}✓ Novo Session Secret gerado: ${NEW_SESSION_SECRET:0:10}... (32 bytes)${NC}"

# Atualizar arquivo .env
echo -e "${BLUE}📝 Atualizando arquivo .env...${NC}"

# Verificar se as variáveis existem
if grep -q "^JWT_SECRET=" .env; then
    # Atualizar JWT_SECRET existente
    sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$NEW_JWT_SECRET|" .env
else
    # Adicionar JWT_SECRET
    echo "JWT_SECRET=$NEW_JWT_SECRET" >> .env
fi

if grep -q "^SESSION_SECRET=" .env; then
    # Atualizar SESSION_SECRET existente
    sed -i "s|^SESSION_SECRET=.*|SESSION_SECRET=$NEW_SESSION_SECRET|" .env
else
    # Adicionar SESSION_SECRET
    echo "SESSION_SECRET=$NEW_SESSION_SECRET" >> .env
fi

# Salvar secrets em arquivo seguro
SECRETS_FILE=".secrets-regenerated-$(date +%Y%m%d_%H%M%S).txt"
cat > "$SECRETS_FILE" << EOF
# SECRETS REGENERADOS - NOVUSIO
# Gerado em: $(date)
# IMPORTANTE: Guarde este arquivo em local seguro e delete do servidor!

JWT_SECRET=$NEW_JWT_SECRET
SESSION_SECRET=$NEW_SESSION_SECRET

# Backup anterior salvo em: $BACKUP_FILE
EOF

chmod 400 "$SECRETS_FILE"
chown novusio:novusio "$SECRETS_FILE"

echo -e "${GREEN}✓ Arquivo .env atualizado${NC}"
echo -e "${GREEN}✓ Backup dos novos secrets: $SECRETS_FILE${NC}"

# Reiniciar aplicação
echo -e "${BLUE}🔄 Reiniciando aplicação...${NC}"
sudo -u novusio pm2 restart novusio-server

echo ""
echo -e "${GREEN}✅ Secrets regenerados com sucesso!${NC}"
echo ""
echo -e "${YELLOW}📋 INFORMAÇÕES IMPORTANTES:${NC}"
echo "  - Backup do .env anterior: $PROJECT_DIR/$BACKUP_FILE"
echo "  - Backup dos novos secrets: $PROJECT_DIR/$SECRETS_FILE"
echo "  - Todos os usuários precisarão fazer login novamente"
echo "  - Guarde o arquivo de secrets em local seguro"
echo "  - Delete o arquivo de secrets do servidor após salvar"
echo ""
echo -e "${BLUE}🔧 Comandos úteis:${NC}"
echo "  - Ver backup anterior: cat $PROJECT_DIR/$BACKUP_FILE"
echo "  - Ver novos secrets: cat $PROJECT_DIR/$SECRETS_FILE"
echo "  - Deletar backup: rm $PROJECT_DIR/$BACKUP_FILE"
echo "  - Deletar secrets: rm $PROJECT_DIR/$SECRETS_FILE"
echo ""
