#!/bin/bash

# =============================================================================
# DEPLOY RÁPIDO - NOVUSIO
# =============================================================================
# Script simplificado para deploy rápido em VPS
# Use este script se você já tem um servidor configurado
# =============================================================================

set -e

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Deploy Rápido - Novusio${NC}"
echo "=================================="

# Verificar se está como root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Execute como root: sudo $0${NC}"
    exit 1
fi

# Coletar informações básicas
read -p "🌐 Domínio: " DOMAIN
read -p "🔗 Repositório Git: " GIT_REPO

# Configurações padrão
USERNAME="novusio"
PROJECT_DIR="/home/novusio"
APP_PORT="3000"

echo -e "${YELLOW}📦 Instalando dependências...${NC}"

# Atualizar sistema
apt-get update -y

# Instalar Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs nginx certbot python3-certbot-nginx git

# Instalar PM2
npm install -g pm2

echo -e "${YELLOW}👤 Criando usuário...${NC}"
useradd -m -s /bin/bash $USERNAME 2>/dev/null || true
usermod -aG sudo $USERNAME

echo -e "${YELLOW}📥 Clonando repositório...${NC}"
rm -rf $PROJECT_DIR
mkdir -p $PROJECT_DIR
git clone $GIT_REPO $PROJECT_DIR
chown -R $USERNAME:$USERNAME $PROJECT_DIR

echo -e "${YELLOW}🔨 Fazendo build...${NC}"
cd $PROJECT_DIR
npm ci
if [[ -d "client" ]]; then
    cd client && npm ci && npm run build && cd ..
fi

echo -e "${YELLOW}📁 Preparando uploads...${NC}"
mkdir -p "$PROJECT_DIR/uploads"
mkdir -p "/home/$USERNAME/uploads"
if [[ -d "$PROJECT_DIR/uploads" ]]; then
    rsync -a --ignore-existing "$PROJECT_DIR/uploads/" "/home/$USERNAME/uploads/" || true
    chown -R $USERNAME:$USERNAME "/home/$USERNAME/uploads"
fi

echo -e "${YELLOW}⚙️ Configurando PM2...${NC}"
cp instalador/ecosystem.config.js .
sudo -u $USERNAME pm2 start ecosystem.config.js
sudo -u $USERNAME pm2 save
sudo -u $USERNAME pm2 startup systemd -u $USERNAME --hp /home/$USERNAME

echo -e "${YELLOW}🌐 Configurando Nginx...${NC}"
cp instalador/nginx.conf /etc/nginx/sites-available/novusio
sed -i "s/novusio.com/$DOMAIN/g" /etc/nginx/sites-available/novusio
ln -sf /etc/nginx/sites-available/novusio /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

echo -e "${YELLOW}🔒 Configurando SSL...${NC}"
systemctl reload nginx
certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email suporte@novusiopy.com --redirect

echo -e "${YELLOW}🔥 Configurando firewall...${NC}"
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo -e "${GREEN}✅ Deploy concluído!${NC}"
echo "=================================="
echo -e "🌐 Site: ${GREEN}https://$DOMAIN${NC}"
echo -e "👤 Usuário: ${GREEN}$USERNAME${NC}"
echo -e "📁 Diretório: ${GREEN}$PROJECT_DIR${NC}"
echo ""
echo -e "${YELLOW}🔐 Próximos passos:${NC}"
echo "1. Acesse https://$DOMAIN/admin"
echo "2. Faça login com credenciais padrão"
echo "3. Configure suas informações"
echo "4. Altere a senha do admin"
echo ""
echo -e "${GREEN}🎉 Site online e funcionando!${NC}"
