#!/bin/bash

# 🔐 Gerador de Secrets - Site Novusio
# Script para gerar chaves seguras para produção

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para gerar string aleatória
generate_random_string() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Função para gerar UUID
generate_uuid() {
    python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || \
    cat /proc/sys/kernel/random/uuid 2>/dev/null || \
    generate_random_string 32
}

print_status "🔐 Gerando secrets seguros para produção..."

# Verificar se openssl está disponível
if ! command -v openssl &> /dev/null; then
    print_error "OpenSSL não está instalado. Instale com: sudo apt install openssl"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔐 SECRETS GERADOS PARA PRODUÇÃO"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Gerar JWT Secret
JWT_SECRET=$(generate_random_string 64)
echo "JWT_SECRET=$JWT_SECRET"

# Gerar Session Secret
SESSION_SECRET=$(generate_random_string 64)
echo "SESSION_SECRET=$SESSION_SECRET"

# Gerar Database Secret
DB_SECRET=$(generate_random_string 32)
echo "DB_SECRET=$DB_SECRET"

# Gerar API Key
API_KEY=$(generate_uuid)
echo "API_KEY=$API_KEY"

# Gerar Admin Password (hash)
ADMIN_PASSWORD=$(generate_random_string 16)
echo "ADMIN_PASSWORD=$ADMIN_PASSWORD"

# Gerar Encryption Key
ENCRYPTION_KEY=$(generate_random_string 32)
echo "ENCRYPTION_KEY=$ENCRYPTION_KEY"

# Gerar CSRF Secret
CSRF_SECRET=$(generate_random_string 32)
echo "CSRF_SECRET=$CSRF_SECRET"

# Gerar Backup Key
BACKUP_KEY=$(generate_random_string 32)
echo "BACKUP_KEY=$BACKUP_KEY"

# Gerar Monitoring Token
MONITORING_TOKEN=$(generate_uuid)
echo "MONITORING_TOKEN=$MONITORING_TOKEN"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

print_warning "⚠️ IMPORTANTE:"
echo ""
echo "1. Copie estes valores para seu arquivo .env"
echo "2. NUNCA compartilhe estes secrets"
echo "3. Mantenha-os em local seguro"
echo "4. Faça backup dos secrets"
echo ""

print_status "📝 Para aplicar estes secrets:"
echo ""
echo "1. Edite o arquivo .env:"
echo "   sudo nano /opt/novusio/.env"
echo ""
echo "2. Substitua os valores pelos gerados acima"
echo ""
echo "3. Reinicie a aplicação:"
echo "   sudo systemctl restart novusio"
echo ""

# Perguntar se quer salvar em arquivo
read -p "Deseja salvar estes secrets em um arquivo? (y/N): " SAVE_FILE

if [[ "$SAVE_FILE" == "y" || "$SAVE_FILE" == "Y" ]]; then
    SECRETS_FILE="/opt/novusio/secrets-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$SECRETS_FILE" << EOF
# Secrets gerados em $(date)
# NUNCA compartilhe este arquivo!

JWT_SECRET=$JWT_SECRET
SESSION_SECRET=$SESSION_SECRET
DB_SECRET=$DB_SECRET
API_KEY=$API_KEY
ADMIN_PASSWORD=$ADMIN_PASSWORD
ENCRYPTION_KEY=$ENCRYPTION_KEY
CSRF_SECRET=$CSRF_SECRET
BACKUP_KEY=$BACKUP_KEY
MONITORING_TOKEN=$MONITORING_TOKEN
EOF
    
    # Definir permissões seguras
    chmod 600 "$SECRETS_FILE"
    chown novusio:novusio "$SECRETS_FILE"
    
    print_success "Secrets salvos em: $SECRETS_FILE"
    print_warning "⚠️ Remova este arquivo após copiar os valores!"
fi

echo ""
print_success "✅ Secrets gerados com sucesso!"
