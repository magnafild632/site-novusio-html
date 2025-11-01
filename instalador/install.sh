#!/bin/bash

# =============================================================================
# Script de Inicialização - Site Novusio
# Prepara todos os scripts para execução
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Função para erro
error() {
    echo -e "${RED}[ERRO]${NC} $1" >&2
}

# Função para aviso
warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Função para info
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Banner
show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              🛠️  PREPARAÇÃO DOS SCRIPTS 🛠️                 ║"
    echo "║                                                              ║"
    echo "║              Site Novusio - Sistema de Deploy               ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Verificar se estamos na pasta correta
check_directory() {
    if [[ ! -f "deploy.sh" ]] || [[ ! -f "menu.sh" ]]; then
        error "Este script deve ser executado na pasta 'instalador/'"
        error "Arquivos necessários não encontrados!"
        exit 1
    fi
}

# Dar permissões de execução
set_permissions() {
    log "Configurando permissões de execução..."
    
    # Lista de scripts executáveis
    SCRIPTS=(
        "deploy.sh"
        "menu.sh"
        "setup-ssl.sh"
        "backup.sh"
        "verificar-sistema.sh"
    )
    
    for script in "${SCRIPTS[@]}"; do
        if [[ -f "$script" ]]; then
            chmod +x "$script"
            log "✅ $script configurado"
        else
            warning "⚠️  $script não encontrado"
        fi
    done
}

# Verificar dependências básicas
check_dependencies() {
    log "Verificando dependências básicas..."
    
    # Verificar se estamos no Ubuntu/Debian
    if [[ ! -f /etc/debian_version ]]; then
        warning "⚠️  Este sistema foi testado apenas em Ubuntu/Debian"
        warning "Pode haver problemas em outras distribuições"
    else
        log "✅ Sistema Ubuntu/Debian detectado"
    fi
    
    # Verificar sudo
    if command -v sudo &> /dev/null; then
        log "✅ sudo disponível"
    else
        error "❌ sudo não está instalado"
        error "Instale sudo primeiro: apt install sudo"
        exit 1
    fi
    
    # Verificar git
    if command -v git &> /dev/null; then
        log "✅ git disponível"
    else
        warning "⚠️  git não está instalado"
        info "Será instalado automaticamente durante o deploy"
    fi
    
    # Verificar curl
    if command -v curl &> /dev/null; then
        log "✅ curl disponível"
    else
        warning "⚠️  curl não está instalado"
        info "Será instalado automaticamente durante o deploy"
    fi
}

# Mostrar informações do sistema
show_system_info() {
    echo -e "${CYAN}📋 Informações do Sistema${NC}"
    echo -e "${YELLOW}========================${NC}"
    
    # Sistema operacional
    if [[ -f /etc/os-release ]]; then
        OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
        echo "🖥️  Sistema: $OS_NAME"
    fi
    
    # Kernel
    KERNEL=$(uname -r)
    echo "🔧 Kernel: $KERNEL"
    
    # Usuário atual
    USER=$(whoami)
    echo "👤 Usuário: $USER"
    
    # Memória
    MEMORY=$(free -h | grep "Mem:" | awk '{print $2}')
    echo "💾 Memória: $MEMORY"
    
    # Espaço em disco
    DISK=$(df -h / | tail -1 | awk '{print $2}')
    echo "💽 Disco: $DISK"
    
    echo ""
}

# Mostrar próximos passos
show_next_steps() {
    echo -e "${CYAN}🚀 Próximos Passos${NC}"
    echo -e "${YELLOW}==================${NC}"
    echo ""
    echo "1. 🚀 Instalar o projeto:"
    echo "   ./deploy.sh"
    echo ""
    echo "2. 🎛️  Gerenciar o sistema:"
    echo "   ./menu.sh"
    echo ""
    echo "3. 🔍 Verificar o sistema:"
    echo "   ./verificar-sistema.sh"
    echo ""
    echo "4. 💾 Fazer backup:"
    echo "   ./backup.sh"
    echo ""
    echo -e "${GREEN}📚 Para mais informações, consulte o README.md${NC}"
    echo ""
}

# Verificar se o usuário tem privilégios sudo
check_sudo_privileges() {
    if ! sudo -n true 2>/dev/null; then
        warning "⚠️  Você precisará fornecer sua senha sudo durante a instalação"
        info "O script de deploy solicitará permissões quando necessário"
    else
        log "✅ Privilégios sudo confirmados"
    fi
}

# Função principal
main() {
    show_banner
    
    check_directory
    check_dependencies
    check_sudo_privileges
    show_system_info
    set_permissions
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              ✅ PREPARAÇÃO CONCLUÍDA! ✅                    ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    show_next_steps
    
    # Perguntar se quer executar o deploy
    read -p "Deseja executar o deploy agora? (y/N): " RUN_DEPLOY
    
    if [[ "$RUN_DEPLOY" =~ ^[Yy]$ ]]; then
        log "Iniciando deploy..."
        ./deploy.sh
    else
        log "Deploy não executado. Execute './deploy.sh' quando estiver pronto."
    fi
}

# Executar função principal
main "$@"
