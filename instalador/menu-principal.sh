#!/bin/bash

# 🎛️ Menu Principal - Site Novusio
# Script interativo para instalação e configuração

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Função para imprimir título
print_title() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                                ║${NC}"
    echo -e "${CYAN}║                    🚀 SITE NOVUSIO - INSTALADOR AUTOMÁTICO                    ║${NC}"
    echo -e "${CYAN}║                                                                                ║${NC}"
    echo -e "${CYAN}║                        Sistema de Deploy para VPS                               ║${NC}"
    echo -e "${CYAN}║                                                                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Função para imprimir mensagens coloridas
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

print_menu() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}📋 OPÇÕES DISPONÍVEIS:${NC}"
    echo ""
echo -e "${GREEN}1.${NC} 🆕 ${YELLOW}Instalação Completa (Do Zero)${NC}"
echo -e "   • Configurar domínio, email e Git"
echo -e "   • Instalar Node.js, Nginx, PM2, Fail2ban"
echo -e "   • Configurar firewall e segurança"
echo -e "   • Configurar .env automaticamente"
    echo ""
    echo -e "${GREEN}2.${NC} 🔄 ${YELLOW}Atualizar Aplicação${NC}"
    echo -e "   • Atualizar código da aplicação"
    echo -e "   • Reinstalar dependências"
    echo -e "   • Reiniciar serviços"
    echo ""
    echo -e "${GREEN}3.${NC} ⚙️  ${YELLOW}Configurar Sistema${NC}"
    echo -e "   • Configurar domínio, email e Git"
    echo -e "   • Editar variáveis de ambiente"
    echo -e "   • Gerar novos secrets"
    echo ""
    echo -e "${GREEN}4.${NC} 🔒 ${YELLOW}Configurar SSL${NC}"
    echo -e "   • Instalar certificados SSL"
    echo -e "   • Configurar renovação automática"
    echo ""
    echo -e "${GREEN}5.${NC} 💾 ${YELLOW}Backup/Restore${NC}"
    echo -e "   • Criar backup manual"
    echo -e "   • Restaurar backup"
    echo -e "   • Listar backups disponíveis"
    echo ""
    echo -e "${GREEN}6.${NC} 🛠️  ${YELLOW}Gerenciar Serviços${NC}"
    echo -e "   • Iniciar/Parar aplicação"
    echo -e "   • Ver status dos serviços"
    echo -e "   • Ver logs em tempo real"
    echo ""
    echo -e "${GREEN}7.${NC} 🔍 ${YELLOW}Verificar Sistema${NC}"
    echo -e "   • Verificar status da aplicação"
    echo -e "   • Verificar configurações"
    echo -e "   • Testar conectividade"
    echo ""
    echo -e "${GREEN}8.${NC} 🔧 ${YELLOW}Diagnóstico e Correção${NC}"
    echo -e "   • Diagnosticar problemas"
    echo -e "   • Corrigir locks do APT"
    echo -e "   • Verificar sistema"
    echo ""
    echo -e "${GREEN}9.${NC} 🆘 ${YELLOW}Suporte e Logs${NC}"
    echo -e "   • Ver logs de erro"
    echo -e "   • Informações de sistema"
    echo -e "   • Comandos de diagnóstico"
    echo ""
    echo -e "${GREEN}0.${NC} ❌ ${RED}Sair${NC}"
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Função para verificar se está rodando como root
check_user() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script deve ser executado como root."
        exit 1
    fi
}

# Função para verificar dependências
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v wget &> /dev/null; then
        missing_deps+=("wget")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_warning "Dependências faltando: ${missing_deps[*]}"
        read -p "Instalar dependências automaticamente? (y/N): " install_deps
        
        if [[ "$install_deps" == "y" || "$install_deps" == "Y" ]]; then
            print_status "Instalando dependências..."
            apt update
            apt install -y "${missing_deps[@]}"
            print_success "Dependências instaladas"
        else
            print_error "Dependências necessárias não instaladas"
            exit 1
        fi
    fi
}

# Função para instalação completa
install_complete() {
    print_title
    echo -e "${YELLOW}🆕 INSTALAÇÃO COMPLETA (DO ZERO)${NC}"
    echo ""
    
    print_warning "⚠️ Esta opção irá:"
    echo "• Instalar Node.js, Nginx, PM2, Certbot, Fail2ban"
    echo "• Configurar firewall e segurança"
    echo "• Criar usuário e estrutura de diretórios"
    echo "• Configurar serviços do systemd"
    echo ""
    
    read -p "Continuar com a instalação completa? (y/N): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        print_status "Iniciando instalação completa..."
        
        if [[ -f "./install.sh" ]]; then
            ./install.sh
        else
            print_error "Script de instalação não encontrado: install.sh"
            return 1
        fi
        
        print_success "Instalação completa finalizada!"
        echo ""
        print_status "Próximos passos:"
        echo "1. Configure SSL (opção 4)"
        echo "2. Inicie a aplicação (opção 6)"
        echo "3. Verifique o sistema (opção 7)"
    else
        print_status "Instalação cancelada"
    fi
}

# Função para atualizar aplicação
update_app() {
    print_title
    echo -e "${YELLOW}🔄 ATUALIZAR APLICAÇÃO${NC}"
    echo ""
    
    print_status "Esta opção irá:"
    echo "• Fazer backup da aplicação atual"
    echo "• Atualizar código da aplicação"
    echo "• Reinstalar dependências"
    echo "• Reiniciar serviços"
    echo ""
    
    read -p "Continuar com a atualização? (y/N): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        print_status "Iniciando atualização..."
        
        if [[ -f "./deploy.sh" ]]; then
            ./deploy.sh
        else
            print_error "Script de deploy não encontrado: deploy.sh"
            return 1
        fi
        
        print_success "Atualização finalizada!"
    else
        print_status "Atualização cancelada"
    fi
}

# Função para configurar sistema
configure_system() {
    print_title
    echo -e "${YELLOW}⚙️ CONFIGURAR SISTEMA${NC}"
    echo ""
    
    echo "1. 🔧 Configurar Domínio, Email e Git"
    echo "2. 📝 Editar arquivo .env manualmente"
    echo "3. 🔐 Gerar novos secrets"
    echo "0. 🚪 Voltar"
    echo ""
    read -p "Opção: " config_option
    
    case $config_option in
        1)
            print_status "Executando gerenciador de configurações..."
            if [[ -f "./config-manager.sh" ]]; then
                chmod +x ./config-manager.sh
                ./config-manager.sh
            else
                print_error "Gerenciador de configurações não encontrado"
            fi
            ;;
        2)
            print_status "Editando arquivo .env existente..."
            nano /opt/novusio/.env
            ;;
        3)
            print_status "Gerando novos secrets..."
            if [[ -f "./regenerate-secrets.sh" ]]; then
                ./regenerate-secrets.sh
            else
                print_warning "Script de geração de secrets não encontrado"
            fi
            ;;
        0)
            return
            ;;
        *)
            print_error "Opção inválida"
            ;;
    esac
}

# Função para configurar SSL
configure_ssl() {
    print_title
    echo -e "${YELLOW}🔒 CONFIGURAR SSL${NC}"
    echo ""
    
    print_status "Esta opção irá:"
    echo "• Instalar certificados SSL com Certbot"
    echo "• Configurar renovação automática"
    echo "• Configurar redirecionamento HTTPS"
    echo ""
    
    read -p "Continuar com a configuração SSL? (y/N): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        print_status "Iniciando configuração SSL..."
        
        if [[ -f "./setup-ssl.sh" ]]; then
            ./setup-ssl.sh
        else
            print_error "Script de SSL não encontrado: setup-ssl.sh"
            return 1
        fi
        
        print_success "Configuração SSL finalizada!"
    else
        print_status "Configuração SSL cancelada"
    fi
}

# Função para backup/restore
backup_restore() {
    print_title
    echo -e "${YELLOW}💾 BACKUP/RESTORE${NC}"
    echo ""
    
    echo "Escolha uma opção:"
    echo "1. Criar backup manual"
    echo "2. Listar backups disponíveis"
    echo "3. Restaurar backup"
    echo "0. Voltar ao menu principal"
    echo ""
    
    read -p "Opção: " backup_option
    
    case $backup_option in
        1)
            print_status "Criando backup manual..."
            if [[ -f "./backup.sh" ]]; then
                ./backup.sh
            else
                print_error "Script de backup não encontrado: backup.sh"
            fi
            ;;
        2)
            print_status "Listando backups disponíveis..."
            if [[ -d "/opt/novusio/backups" ]]; then
                ls -lh /opt/novusio/backups/
            else
                print_warning "Diretório de backups não encontrado"
            fi
            ;;
        3)
            print_warning "Funcionalidade de restore será implementada em breve"
            ;;
        0)
            return
            ;;
        *)
            print_error "Opção inválida"
            ;;
    esac
}

# Função para gerenciar serviços
manage_services() {
    print_title
    echo -e "${YELLOW}🛠️ GERENCIAR SERVIÇOS${NC}"
    echo ""
    
    echo "Escolha uma opção:"
    echo "1. Iniciar aplicação"
    echo "2. Parar aplicação"
    echo "3. Reiniciar aplicação"
    echo "4. Ver status dos serviços"
    echo "5. Ver logs em tempo real"
    echo "0. Voltar ao menu principal"
    echo ""
    
    read -p "Opção: " service_option
    
    case $service_option in
        1)
            print_status "Iniciando aplicação..."
            systemctl start novusio
            print_success "Aplicação iniciada"
            ;;
        2)
            print_status "Parando aplicação..."
            systemctl stop novusio
            print_success "Aplicação parada"
            ;;
        3)
            print_status "Reiniciando aplicação..."
            systemctl restart novusio
            print_success "Aplicação reiniciada"
            ;;
        4)
            print_status "Status dos serviços:"
            systemctl status novusio nginx fail2ban --no-pager
            ;;
        5)
            print_status "Logs em tempo real (Ctrl+C para sair):"
            journalctl -u novusio -f
            ;;
        0)
            return
            ;;
        *)
            print_error "Opção inválida"
            ;;
    esac
}

# Função para diagnóstico e correção
diagnose_and_fix() {
    print_title
    echo -e "${YELLOW}🔧 DIAGNÓSTICO E CORREÇÃO${NC}"
    echo ""
    
    echo "1. 🔍 Diagnosticar problemas"
    echo "2. 🔒 Corrigir locks do APT"
    echo "3. 📦 Verificar pacotes essenciais"
    echo "4. 🔄 Reiniciar serviços"
    echo "0. 🚪 Voltar"
    echo ""
    read -p "Opção: " diag_option
    
    case $diag_option in
        1)
            print_status "Executando diagnóstico..."
            if [[ -f "./diagnostico.sh" ]]; then
                chmod +x ./diagnostico.sh
                ./diagnostico.sh
            else
                print_error "Script de diagnóstico não encontrado"
            fi
            ;;
        2)
            print_status "Corrigindo locks do APT..."
            if [[ -f "./fix-apt-lock.sh" ]]; then
                chmod +x ./fix-apt-lock.sh
                ./fix-apt-lock.sh
            else
                print_error "Script de correção não encontrado"
            fi
            ;;
        3)
            print_status "Verificando pacotes essenciais..."
            apt update
            apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release nodejs npm nginx certbot python3-certbot-nginx fail2ban
            print_success "Pacotes verificados"
            ;;
        4)
            print_status "Reiniciando serviços..."
            systemctl restart nginx
            systemctl restart fail2ban
            if systemctl list-unit-files | grep -q "^novusio.service"; then
                systemctl restart novusio
            fi
            print_success "Serviços reiniciados"
            ;;
        0)
            return
            ;;
        *)
            print_error "Opção inválida"
            ;;
    esac
}

# Função para verificar sistema
verify_system() {
    print_title
    echo -e "${YELLOW}🔍 VERIFICAR SISTEMA${NC}"
    echo ""
    
    print_status "Verificando status da aplicação..."
    
    # Status da aplicação
    if systemctl is-active --quiet novusio; then
        print_success "✅ Aplicação: RODANDO"
    else
        print_error "❌ Aplicação: PARADA"
    fi
    
    # Status do Nginx
    if systemctl is-active --quiet nginx; then
        print_success "✅ Nginx: RODANDO"
    else
        print_error "❌ Nginx: PARADO"
    fi
    
    # Status do Fail2ban
    if systemctl is-active --quiet fail2ban; then
        print_success "✅ Fail2ban: ATIVO"
    else
        print_warning "⚠️ Fail2ban: INATIVO"
    fi
    
    # Status do SSL
    if [[ -d "/etc/letsencrypt/live" ]]; then
        print_success "✅ SSL: CONFIGURADO"
    else
        print_warning "⚠️ SSL: NÃO CONFIGURADO"
    fi
    
    # Portas
    echo ""
    print_status "Verificando portas..."
    if netstat -tlnp 2>/dev/null | grep -q ":3000"; then
        print_success "✅ Porta 3000: ATIVA"
    else
        print_error "❌ Porta 3000: INATIVA"
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q ":80"; then
        print_success "✅ Porta 80: ATIVA"
    else
        print_error "❌ Porta 80: INATIVA"
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q ":443"; then
        print_success "✅ Porta 443: ATIVA"
    else
        print_error "❌ Porta 443: INATIVA"
    fi
    
    # Teste de conectividade
    echo ""
    print_status "Testando conectividade..."
    if curl -f -s http://localhost:3000/api/health > /dev/null; then
        print_success "✅ API respondendo"
    else
        print_warning "⚠️ API não respondendo"
    fi
}

# Função para suporte e logs
support_logs() {
    print_title
    echo -e "${YELLOW}🆘 SUPORTE E LOGS${NC}"
    echo ""
    
    echo "Escolha uma opção:"
    echo "1. Ver logs de erro recentes"
    echo "2. Ver informações do sistema"
    echo "3. Verificar espaço em disco"
    echo "4. Verificar uso de memória"
    echo "5. Comandos de diagnóstico"
    echo "0. Voltar ao menu principal"
    echo ""
    
    read -p "Opção: " support_option
    
    case $support_option in
        1)
            print_status "Logs de erro recentes:"
            journalctl -u novusio --since "1 hour ago" | grep -i error | tail -20
            ;;
        2)
            print_status "Informações do sistema:"
            echo "OS: $(lsb_release -d | cut -f2)"
            echo "Kernel: $(uname -r)"
            echo "Uptime: $(uptime -p)"
            echo "Node.js: $(node --version 2>/dev/null || echo 'Não instalado')"
            echo "NPM: $(npm --version 2>/dev/null || echo 'Não instalado')"
            ;;
        3)
            print_status "Espaço em disco:"
            df -h
            ;;
        4)
            print_status "Uso de memória:"
            free -h
            ;;
        5)
            print_status "Comandos de diagnóstico úteis:"
            echo "• Logs da aplicação: journalctl -u novusio -f"
            echo "• Logs do Nginx: tail -f /var/log/nginx/error.log"
            echo "• Status dos serviços: systemctl status novusio nginx"
            echo "• Testar Nginx: nginx -t"
            echo "• Verificar SSL: certbot certificates"
            ;;
        0)
            return
            ;;
        *)
            print_error "Opção inválida"
            ;;
    esac
}

# Função principal
main() {
    # Verificar usuário
    check_user
    
    # Verificar dependências
    check_dependencies
    
    while true; do
        print_title
        print_menu
        
        read -p "Digite sua opção (0-8): " choice
        
        case $choice in
            1)
                install_complete
                ;;
            2)
                update_app
                ;;
        3)
            configure_system
            ;;
            4)
                configure_ssl
                ;;
            5)
                backup_restore
                ;;
            6)
                manage_services
                ;;
            7)
                verify_system
                ;;
            8)
                diagnose_and_fix
                ;;
            9)
                support_logs
                ;;
            0)
                print_success "Saindo do instalador..."
                echo ""
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${GREEN}✅ Obrigado por usar o instalador do Site Novusio!${NC}"
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""
                exit 0
                ;;
            *)
                print_error "Opção inválida. Digite um número de 0 a 9."
                ;;
        esac
        
        echo ""
        read -p "Pressione Enter para continuar..."
    done
}

# Executar função principal
main
