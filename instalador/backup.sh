#!/bin/bash

# 💾 Script de Backup - Site Novusio
# Backup automático da aplicação e dados

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
BACKUP_USER="novusio"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="novusio-backup-$TIMESTAMP"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME.tar.gz"

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script deve ser executado como root."
    exit 1
fi

print_status "💾 Iniciando backup do Site Novusio..."

# Criar diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

# Criar diretório temporário para backup
TEMP_DIR="/tmp/novusio-backup-$TIMESTAMP"
mkdir -p "$TEMP_DIR"

# Parar aplicação temporariamente para backup consistente
print_status "⏹️ Parando aplicação para backup consistente..."
systemctl stop novusio

# Aguardar aplicação parar completamente
sleep 5

# Backup do banco de dados
print_status "🗄️ Fazendo backup do banco de dados..."
if [[ -f "$APP_DIR/app/database.sqlite" ]]; then
    cp "$APP_DIR/app/database.sqlite" "$TEMP_DIR/"
    print_success "Banco de dados copiado"
else
    print_warning "Banco de dados não encontrado"
fi

# Backup dos uploads
print_status "📁 Fazendo backup dos uploads..."
if [[ -d "$APP_DIR/app/client/uploads" ]]; then
    cp -r "$APP_DIR/app/client/uploads" "$TEMP_DIR/"
    print_success "Uploads copiados"
else
    print_warning "Diretório de uploads não encontrado"
fi

# Backup do arquivo .env
print_status "⚙️ Fazendo backup da configuração..."
if [[ -f "$APP_DIR/.env" ]]; then
    cp "$APP_DIR/.env" "$TEMP_DIR/"
    print_success "Configuração copiada"
else
    print_warning "Arquivo .env não encontrado"
fi

# Backup dos logs
print_status "📋 Fazendo backup dos logs..."
if [[ -d "$LOG_DIR" ]]; then
    cp -r "$LOG_DIR" "$TEMP_DIR/logs"
    print_success "Logs copiados"
else
    print_warning "Diretório de logs não encontrado"
fi

# Backup da configuração do Nginx
print_status "🌐 Fazendo backup da configuração do Nginx..."
if [[ -f "/etc/nginx/sites-available/novusio" ]]; then
    cp "/etc/nginx/sites-available/novusio" "$TEMP_DIR/nginx-novusio.conf"
    print_success "Configuração do Nginx copiada"
else
    print_warning "Configuração do Nginx não encontrada"
fi

# Backup da configuração do SSL
print_status "🔒 Fazendo backup dos certificados SSL..."
if [[ -d "/etc/letsencrypt" ]]; then
    cp -r "/etc/letsencrypt" "$TEMP_DIR/letsencrypt"
    print_success "Certificados SSL copiados"
else
    print_warning "Certificados SSL não encontrados"
fi

# Backup da configuração do Fail2ban
print_status "🛡️ Fazendo backup da configuração do Fail2ban..."
if [[ -f "/etc/fail2ban/jail.local" ]]; then
    cp "/etc/fail2ban/jail.local" "$TEMP_DIR/fail2ban-jail.conf"
    print_success "Configuração do Fail2ban copiada"
else
    print_warning "Configuração do Fail2ban não encontrada"
fi

# Criar arquivo de informações do backup
print_status "📝 Criando arquivo de informações..."
cat > "$TEMP_DIR/backup-info.txt" << EOF
Backup do Site Novusio
=====================
Data/Hora: $(date)
Versão: $(cd "$APP_DIR/app" && git rev-parse HEAD 2>/dev/null || echo "N/A")
Sistema: $(uname -a)
Usuário: $(whoami)
Diretório: $APP_DIR
Tamanho estimado: $(du -sh "$TEMP_DIR" 2>/dev/null | cut -f1 || echo "N/A")

Arquivos incluídos:
- database.sqlite (banco de dados)
- uploads/ (arquivos enviados)
- .env (configuração)
- logs/ (logs da aplicação)
- nginx-novusio.conf (configuração Nginx)
- letsencrypt/ (certificados SSL)
- fail2ban-jail.conf (configuração Fail2ban)

Para restaurar:
1. Extrair: tar -xzf $BACKUP_NAME.tar.gz
2. Parar aplicação: systemctl stop novusio
3. Restaurar arquivos
4. Reiniciar aplicação: systemctl start novusio
EOF

# Criar arquivo de hash para verificação
print_status "🔐 Calculando hash do backup..."
find "$TEMP_DIR" -type f -exec md5sum {} \; > "$TEMP_DIR/backup-checksums.md5"

# Criar arquivo compactado
print_status "📦 Compactando backup..."
cd "$TEMP_DIR"
tar -czf "$BACKUP_FILE" . 2>/dev/null

# Verificar integridade do backup
print_status "🔍 Verificando integridade do backup..."
if [[ -f "$BACKUP_FILE" ]]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    print_success "Backup criado com sucesso: $BACKUP_FILE ($BACKUP_SIZE)"
else
    print_error "Falha ao criar backup"
    exit 1
fi

# Limpar diretório temporário
rm -rf "$TEMP_DIR"

# Reiniciar aplicação
print_status "🚀 Reiniciando aplicação..."
systemctl start novusio

# Aguardar aplicação inicializar
sleep 10

# Verificar se aplicação está rodando
if systemctl is-active --quiet novusio; then
    print_success "✅ Aplicação reiniciada com sucesso"
else
    print_error "❌ Falha ao reiniciar aplicação"
    print_error "Verifique os logs: journalctl -u novusio -f"
fi

# Limpeza de backups antigos
print_status "🧹 Limpando backups antigos..."
# Manter apenas os últimos 30 backups
find "$BACKUP_DIR" -name "novusio-backup-*.tar.gz" -type f -printf '%T@ %p\n' | \
sort -rn | tail -n +31 | cut -d' ' -f2- | xargs rm -f 2>/dev/null || true

# Estatísticas do backup
print_status "📊 Estatísticas do backup..."
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "novusio-backup-*.tar.gz" | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_success "🎉 Backup concluído com sucesso!"
echo ""
print_status "📋 Informações do backup:"
echo "• Arquivo: $BACKUP_FILE"
echo "• Tamanho: $BACKUP_SIZE"
echo "• Data/Hora: $(date)"
echo "• Total de backups: $BACKUP_COUNT"
echo "• Espaço total usado: $TOTAL_SIZE"
echo ""
print_status "🔧 Comandos úteis:"
echo "• Listar backups: ls -lh $BACKUP_DIR/"
echo "• Verificar integridade: tar -tzf $BACKUP_FILE"
echo "• Restaurar backup: ./restore.sh $BACKUP_FILE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Notificar sucesso
print_success "✅ Backup finalizado! Arquivo salvo em: $BACKUP_FILE"
