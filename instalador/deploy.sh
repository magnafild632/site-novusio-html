#!/bin/bash

# 🚀 Script de Deploy - Site Novusio
# Deploy automático para produção

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

# Configurações
APP_DIR="/opt/novusio"
BACKUP_DIR="/opt/novusio/backups"
LOG_DIR="/var/log/novusio"
DEPLOY_USER="novusio"

# Verificar se está rodando como usuário correto
if [[ "$(whoami)" != "$DEPLOY_USER" ]]; then
    print_error "Este script deve ser executado como usuário '$DEPLOY_USER'"
    exit 1
fi

print_status "🚀 Iniciando deploy do Site Novusio..."

# Criar backup antes do deploy
print_status "💾 Criando backup antes do deploy..."
BACKUP_FILE="$BACKUP_DIR/backup-pre-deploy-$(date +%Y%m%d-%H%M%S).tar.gz"
mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_FILE" \
    -C "$APP_DIR" \
    app/database.sqlite \
    app/client/uploads \
    .env \
    logs 2>/dev/null || true

print_success "Backup criado: $BACKUP_FILE"

# Parar aplicação
print_status "⏹️ Parando aplicação..."
sudo systemctl stop novusio || true

# Atualizar código
print_status "📥 Atualizando código..."
cd "$APP_DIR/app"

# Se for um repositório Git, fazer pull
if [[ -d ".git" ]]; then
    print_status "🔄 Atualizando via Git..."
    git fetch origin
    git reset --hard origin/main
    git clean -fd
else
    print_warning "⚠️ Não é um repositório Git. Atualize o código manualmente."
fi

# Instalar/atualizar dependências
print_status "📦 Instalando dependências..."
npm install --production

# Instalar dependências do cliente
print_status "📦 Instalando dependências do cliente..."
cd client
npm install
npm run build
cd ..

# Verificar arquivo .env
print_status "⚙️ Verificando configuração..."
if [[ ! -f "$APP_DIR/.env" ]]; then
    print_error "Arquivo .env não encontrado em $APP_DIR/.env"
    print_error "Configure o arquivo .env antes de continuar"
    exit 1
fi

# Verificar se as variáveis necessárias estão definidas
source "$APP_DIR/.env"
if [[ -z "$JWT_SECRET" ]]; then
    print_error "JWT_SECRET não está definido no arquivo .env"
    exit 1
fi

if [[ -z "$DOMAIN" ]]; then
    print_warning "DOMAIN não está definido no arquivo .env"
fi

# Executar migrações do banco (se houver)
print_status "🗄️ Verificando migrações do banco..."
if [[ -f "server/migrate-to-blob.js" ]]; then
    print_status "Executando migração do banco..."
    NODE_ENV=production node server/migrate-to-blob.js || true
fi

# Inicializar banco se necessário
print_status "🗄️ Verificando banco de dados..."
if [[ ! -f "database.sqlite" ]]; then
    print_status "Inicializando banco de dados..."
    NODE_ENV=production npm run init-db
fi

# Verificar permissões
print_status "🔐 Verificando permissões..."
sudo chown -R $DEPLOY_USER:$DEPLOY_USER "$APP_DIR"
sudo chmod -R 755 "$APP_DIR"
sudo chmod 600 "$APP_DIR/.env"

# Testar configuração do Nginx
print_status "🌐 Testando configuração do Nginx..."
if sudo nginx -t; then
    print_success "Configuração do Nginx válida"
else
    print_error "Erro na configuração do Nginx"
    exit 1
fi

# Recarregar configuração do Nginx
print_status "🔄 Recarregando Nginx..."
sudo systemctl reload nginx

# Iniciar aplicação
print_status "🚀 Iniciando aplicação..."
sudo systemctl start novusio

# Aguardar aplicação inicializar
print_status "⏳ Aguardando aplicação inicializar..."
sleep 10

# Verificar se aplicação está rodando
print_status "🔍 Verificando status da aplicação..."
if sudo systemctl is-active --quiet novusio; then
    print_success "✅ Aplicação iniciada com sucesso"
else
    print_error "❌ Falha ao iniciar aplicação"
    print_error "Verifique os logs: sudo journalctl -u novusio -f"
    exit 1
fi

# Testar saúde da aplicação
print_status "🏥 Testando saúde da aplicação..."
if curl -f -s http://localhost:3000/api/health > /dev/null; then
    print_success "✅ API respondendo corretamente"
else
    print_warning "⚠️ API pode não estar respondendo corretamente"
fi

# Verificar logs de erro
print_status "📋 Verificando logs recentes..."
if sudo journalctl -u novusio --since "5 minutes ago" | grep -i error > /dev/null; then
    print_warning "⚠️ Erros encontrados nos logs recentes"
    print_warning "Verifique: sudo journalctl -u novusio -f"
else
    print_success "✅ Nenhum erro encontrado nos logs recentes"
fi

# Limpeza de backups antigos
print_status "🧹 Limpando backups antigos..."
find "$BACKUP_DIR" -name "backup-*.tar.gz" -mtime +7 -delete 2>/dev/null || true

# Estatísticas do deploy
print_status "📊 Estatísticas do deploy..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_success "🎉 Deploy concluído com sucesso!"
echo ""
print_status "📋 Informações do deploy:"
echo "• Data/Hora: $(date)"
echo "• Backup: $BACKUP_FILE"
echo "• Status: $(sudo systemctl is-active novusio)"
echo "• Logs: sudo journalctl -u novusio -f"
echo ""
print_status "🔧 Comandos úteis:"
echo "• Status: sudo systemctl status novusio"
echo "• Logs: sudo journalctl -u novusio -f"
echo "• Restart: sudo systemctl restart novusio"
echo "• Nginx: sudo systemctl status nginx"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Notificar sucesso
print_success "✅ Deploy finalizado! Aplicação está rodando em produção."
