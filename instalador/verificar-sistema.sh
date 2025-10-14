#!/bin/bash

# 🔍 Verificador de Sistema - Site Novusio
# Script para verificar se tudo está funcionando corretamente

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_title() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                                ║${NC}"
    echo -e "${CYAN}║                    🔍 VERIFICADOR DE SISTEMA - SITE NOVUSIO                     ║${NC}"
    echo -e "${CYAN}║                                                                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

ERRORS=0
WARNINGS=0

# Função para verificar se um serviço está rodando
check_service() {
    local service_name=$1
    local display_name=$2
    
    if systemctl is-active --quiet $service_name; then
        print_success "✅ $display_name: RODANDO"
        return 0
    else
        print_error "❌ $display_name: PARADO"
        ((ERRORS++))
        return 1
    fi
}

# Função para verificar se uma porta está em uso
check_port() {
    local port=$1
    local service_name=$2
    
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        print_success "✅ Porta $port ($service_name): ATIVA"
        return 0
    else
        print_error "❌ Porta $port ($service_name): INATIVA"
        ((ERRORS++))
        return 1
    fi
}

# Função para verificar se um arquivo existe
check_file() {
    local file_path=$1
    local description=$2
    
    if [[ -f "$file_path" ]]; then
        print_success "✅ $description: ENCONTRADO"
        return 0
    else
        print_error "❌ $description: NÃO ENCONTRADO ($file_path)"
        ((ERRORS++))
        return 1
    fi
}

# Função para verificar se um diretório existe
check_directory() {
    local dir_path=$1
    local description=$2
    
    if [[ -d "$dir_path" ]]; then
        print_success "✅ $description: ENCONTRADO"
        return 0
    else
        print_error "❌ $description: NÃO ENCONTRADO ($dir_path)"
        ((ERRORS++))
        return 1
    fi
}

# Função para verificar permissões
check_permissions() {
    local path=$1
    local expected_user=$2
    local expected_group=$3
    
    if [[ -e "$path" ]]; then
        local actual_user=$(stat -c %U "$path" 2>/dev/null || echo "unknown")
        local actual_group=$(stat -c %G "$path" 2>/dev/null || echo "unknown")
        
        if [[ "$actual_user" == "$expected_user" && "$actual_group" == "$expected_group" ]]; then
            print_success "✅ Permissões de $path: CORRETAS ($expected_user:$expected_group)"
            return 0
        else
            print_warning "⚠️ Permissões de $path: INCORRETAS ($actual_user:$actual_group, esperado: $expected_user:$expected_group)"
            ((WARNINGS++))
            return 1
        fi
    else
        print_error "❌ $path: NÃO EXISTE"
        ((ERRORS++))
        return 1
    fi
}

# Função para testar conectividade
test_connectivity() {
    local url=$1
    local description=$2
    
    if curl -f -s --max-time 10 "$url" > /dev/null 2>&1; then
        print_success "✅ $description: RESPONDENDO"
        return 0
    else
        print_warning "⚠️ $description: NÃO RESPONDENDO"
        ((WARNINGS++))
        return 1
    fi
}

# Função principal de verificação
main_verification() {
    print_title
    
    print_status "🔍 Iniciando verificação completa do sistema..."
    echo ""
    
    # Verificar serviços
    print_status "🛠️ Verificando serviços..."
    check_service "novusio" "Aplicação Novusio"
    check_service "nginx" "Nginx"
    check_service "fail2ban" "Fail2ban"
    check_service "ufw" "Firewall UFW"
    echo ""
    
    # Verificar portas
    print_status "🌐 Verificando portas..."
    check_port "3000" "Aplicação"
    check_port "80" "HTTP"
    check_port "443" "HTTPS"
    echo ""
    
    # Verificar arquivos importantes
    print_status "📁 Verificando arquivos importantes..."
    check_file "/opt/novusio/.env" "Arquivo de configuração"
    check_file "/opt/novusio/app/database.sqlite" "Banco de dados"
    check_file "/etc/nginx/sites-available/novusio" "Configuração Nginx"
    check_file "/etc/systemd/system/novusio.service" "Serviço systemd"
    echo ""
    
    # Verificar diretórios importantes
    print_status "📂 Verificando diretórios importantes..."
    check_directory "/opt/novusio" "Diretório da aplicação"
    check_directory "/opt/novusio/app" "Código da aplicação"
    check_directory "/opt/novusio/backups" "Diretório de backups"
    check_directory "/var/log/novusio" "Diretório de logs"
    echo ""
    
    # Verificar permissões
    print_status "🔐 Verificando permissões..."
    check_permissions "/opt/novusio" "novusio" "novusio"
    check_permissions "/opt/novusio/.env" "novusio" "novusio"
    check_permissions "/opt/novusio/app" "novusio" "novusio"
    echo ""
    
    # Verificar SSL
    print_status "🔒 Verificando SSL..."
    if [[ -d "/etc/letsencrypt/live" ]]; then
        print_success "✅ Certificados SSL: ENCONTRADOS"
        
        # Verificar renovação automática
        if crontab -l 2>/dev/null | grep -q "certbot renew"; then
            print_success "✅ Renovação automática SSL: CONFIGURADA"
        else
            print_warning "⚠️ Renovação automática SSL: NÃO CONFIGURADA"
            ((WARNINGS++))
        fi
    else
        print_warning "⚠️ Certificados SSL: NÃO ENCONTRADOS"
        ((WARNINGS++))
    fi
    echo ""
    
    # Verificar conectividade
    print_status "🌐 Testando conectividade..."
    test_connectivity "http://localhost:3000/api/health" "API local"
    
    # Se .env estiver configurado, testar domínio
    if [[ -f "/opt/novusio/.env" ]]; then
        source /opt/novusio/.env 2>/dev/null || true
        if [[ -n "$DOMAIN" ]]; then
            test_connectivity "https://$DOMAIN" "Site HTTPS"
            test_connectivity "http://$DOMAIN" "Site HTTP"
        fi
    fi
    echo ""
    
    # Verificar logs de erro
    print_status "📋 Verificando logs de erro..."
    local error_count=$(sudo journalctl -u novusio --since "1 hour ago" | grep -i error | wc -l)
    if [[ $error_count -eq 0 ]]; then
        print_success "✅ Nenhum erro nos logs recentes"
    else
        print_warning "⚠️ $error_count erro(s) encontrado(s) nos logs recentes"
        ((WARNINGS++))
    fi
    echo ""
    
    # Verificar uso de recursos
    print_status "📊 Verificando uso de recursos..."
    
    # Uso de memória
    local memory_usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    if (( $(echo "$memory_usage < 80" | awk '{if($1 < 80) print 1; else print 0}') )); then
        print_success "✅ Uso de memória: ${memory_usage}% (OK)"
    else
        print_warning "⚠️ Uso de memória: ${memory_usage}% (ALTO)"
        ((WARNINGS++))
    fi
    
    # Uso de disco
    local disk_usage=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    if [[ $disk_usage -lt 80 ]]; then
        print_success "✅ Uso de disco: ${disk_usage}% (OK)"
    else
        print_warning "⚠️ Uso de disco: ${disk_usage}% (ALTO)"
        ((WARNINGS++))
    fi
    
    # Load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    if (( $(echo "$load_avg < 2.0" | awk '{if($1 < 2.0) print 1; else print 0}') )); then
        print_success "✅ Load average: $load_avg (OK)"
    else
        print_warning "⚠️ Load average: $load_avg (ALTO)"
        ((WARNINGS++))
    fi
    echo ""
    
    # Verificar backups
    print_status "💾 Verificando backups..."
    if [[ -d "/opt/novusio/backups" ]]; then
        local backup_count=$(find /opt/novusio/backups -name "*.tar.gz" | wc -l)
        if [[ $backup_count -gt 0 ]]; then
            print_success "✅ $backup_count backup(s) encontrado(s)"
            
            # Verificar backup mais recente
            local latest_backup=$(find /opt/novusio/backups -name "*.tar.gz" -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
            if [[ -n "$latest_backup" ]]; then
                local backup_age=$(($(date +%s) - $(stat -c %Y "$latest_backup")))
                local backup_age_hours=$((backup_age / 3600))
                
                if [[ $backup_age_hours -lt 25 ]]; then
                    print_success "✅ Backup mais recente: $backup_age_hours horas atrás"
                else
                    print_warning "⚠️ Backup mais recente: $backup_age_hours horas atrás"
                    ((WARNINGS++))
                fi
            fi
        else
            print_warning "⚠️ Nenhum backup encontrado"
            ((WARNINGS++))
        fi
    else
        print_warning "⚠️ Diretório de backups não encontrado"
        ((WARNINGS++))
    fi
    echo ""
    
    # Resumo final
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
        print_success "🎉 VERIFICAÇÃO CONCLUÍDA COM SUCESSO!"
        print_success "✅ Sistema funcionando perfeitamente"
        echo ""
        print_status "📊 Resumo:"
        echo "• Erros: $ERRORS"
        echo "• Avisos: $WARNINGS"
        echo "• Status: ✅ PERFEITO"
    elif [[ $ERRORS -eq 0 ]]; then
        print_warning "⚠️ VERIFICAÇÃO CONCLUÍDA COM AVISOS"
        print_success "✅ Sistema funcionando (com ressalvas)"
        echo ""
        print_status "📊 Resumo:"
        echo "• Erros: $ERRORS"
        echo "• Avisos: $WARNINGS"
        echo "• Status: ⚠️ ATENÇÃO NECESSÁRIA"
    else
        print_error "❌ VERIFICAÇÃO FALHOU"
        print_error "❌ Sistema com problemas críticos"
        echo ""
        print_status "📊 Resumo:"
        echo "• Erros: $ERRORS"
        echo "• Avisos: $WARNINGS"
        echo "• Status: ❌ AÇÃO NECESSÁRIA"
    fi
    
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Sugestões baseadas nos problemas encontrados
    if [[ $ERRORS -gt 0 ]]; then
        print_status "🔧 AÇÕES RECOMENDADAS:"
        echo ""
        echo "1. Verificar logs de erro: sudo journalctl -u novusio -f"
        echo "2. Reiniciar serviços: sudo systemctl restart novusio nginx"
        echo "3. Verificar configurações: sudo nginx -t"
        echo "4. Corrigir permissões: sudo chown -R novusio:novusio /opt/novusio"
        echo "5. Executar instalação: sudo ./instalador/install.sh"
    elif [[ $WARNINGS -gt 0 ]]; then
        print_status "🔧 MELHORIAS RECOMENDADAS:"
        echo ""
        echo "1. Configurar SSL: sudo ./instalador/setup-ssl.sh"
        echo "2. Verificar backups: ls -lh /opt/novusio/backups/"
        echo "3. Monitorar recursos: htop"
        echo "4. Configurar .env: sudo nano /opt/novusio/.env"
    fi
    
    echo ""
    
    # Retornar código de saída baseado nos erros
    if [[ $ERRORS -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Executar verificação principal
main_verification
