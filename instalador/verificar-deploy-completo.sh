#!/bin/bash

# =============================================================================
# VERIFICAÇÃO COMPLETA DO DEPLOY - NOVUSIO
# =============================================================================

echo "🔍 VERIFICAÇÃO COMPLETA DO SISTEMA DE DEPLOY"
echo "=============================================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CHECKS_PASSED=0
CHECKS_FAILED=0

check() {
    if eval "$2"; then
        echo -e "  ${GREEN}✅ $1${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "  ${RED}❌ $1${NC}"
        ((CHECKS_FAILED++))
    fi
}

echo -e "${BLUE}📋 1. VERIFICANDO FUNÇÕES PRINCIPAIS${NC}"
echo "────────────────────────────────────────"

# Verificar funções críticas no deploy.sh
cd /Users/mac/Documents/GitHub/site-novusio-html/instalador

check "deploy_complete existe" "grep -q '^deploy_complete()' deploy.sh"
check "update_application existe" "grep -q '^update_application()' deploy.sh"
check "remove_project existe" "grep -q '^remove_project()' deploy.sh"
check "setup_nginx existe" "grep -q '^setup_nginx()' deploy.sh"
check "setup_ssl existe" "grep -q '^setup_ssl()' deploy.sh"
check "setup_pm2 existe" "grep -q '^setup_pm2()' deploy.sh"
check "setup_environment existe" "grep -q '^setup_environment()' deploy.sh"
check "setup_firewall existe" "grep -q '^setup_firewall()' deploy.sh"
check "setup_backup existe" "grep -q '^setup_backup()' deploy.sh"
check "setup_monitoring existe" "grep -q '^setup_monitoring()' deploy.sh"

echo ""
echo -e "${BLUE}📋 2. VERIFICANDO CONFIGURAÇÃO NGINX${NC}"
echo "────────────────────────────────────────"

check "Nginx tem root correto" "grep -q 'root.*client/dist' deploy.sh"
check "Nginx tem try_files para React Router" "grep -q 'try_files.*index.html' deploy.sh"
check "Nginx tem proxy para API" "grep -q 'location /api/' deploy.sh"
check "Nginx tem rate limiting" "grep -q 'limit_req_zone' deploy.sh"
check "Nginx tem gzip" "grep -q 'gzip on' deploy.sh"
check "Nginx tem cache de assets" "grep -q 'expires 1y' deploy.sh"
check "Nginx tem upstream" "grep -q 'upstream novusio_backend' deploy.sh"

echo ""
echo -e "${BLUE}📋 3. VERIFICANDO CONFIGURAÇÃO SSL${NC}"
echo "────────────────────────────────────────"

check "SSL pergunta confirmação" "grep -q 'Deseja configurar SSL' deploy.sh"
check "SSL instala Certbot" "grep -q 'apt-get install.*certbot' deploy.sh"
check "SSL usa --redirect" "grep -q '\--redirect' deploy.sh"
check "SSL configura renovação" "grep -q 'certbot renew' deploy.sh"
check "SSL testa renovação" "grep -q 'certbot renew --dry-run' deploy.sh"

echo ""
echo -e "${BLUE}📋 4. VERIFICANDO GERAÇÃO DE SECRETS${NC}"
echo "────────────────────────────────────────"

check "JWT_SECRET é gerado" "grep -q 'openssl rand -base64 48' deploy.sh"
check "SESSION_SECRET é gerado" "grep -q 'openssl rand -base64 32' deploy.sh"
check "Secrets salvos em .env" "grep -q 'JWT_SECRET=\$JWT_SECRET' deploy.sh"
check "Backup de secrets criado" "grep -q '.secrets-backup' deploy.sh"
check "Permissões do .env corretas" "grep -q 'chmod 600 .env' deploy.sh"

echo ""
echo -e "${BLUE}📋 5. VERIFICANDO PM2${NC}"
echo "────────────────────────────────────────"

check "PM2 usa cluster mode" "grep -q \"exec_mode: 'cluster'\" deploy.sh"
check "PM2 usa max instances" "grep -q \"instances: 'max'\" deploy.sh"
check "PM2 tem auto restart" "grep -q \"autorestart: true\" deploy.sh"
check "PM2 tem logs configurados" "grep -q 'error_file.*novusio' deploy.sh"
check "PM2 startup configurado" "grep -q 'pm2 startup' deploy.sh"

echo ""
echo -e "${BLUE}📋 6. VERIFICANDO BACKUP E MONITORAMENTO${NC}"
echo "────────────────────────────────────────"

check "Script de backup criado" "grep -q 'novusio-backup.sh' deploy.sh"
check "Script de monitor criado" "grep -q 'novusio-monitor.sh' deploy.sh"
check "Cron de backup configurado" "grep -q '0 2 \* \* \*' deploy.sh"
check "Logrotate configurado" "grep -q 'setup_logrotate' deploy.sh"

echo ""
echo -e "${BLUE}📋 7. VERIFICANDO FIREWALL${NC}"
echo "────────────────────────────────────────"

check "Firewall não reseta se ativo" "grep -q 'if ufw status.*active' deploy.sh"
check "Firewall permite SSH" "grep -q 'ufw allow.*ssh' deploy.sh"
check "Firewall permite 80" "grep -q 'ufw allow 80' deploy.sh"
check "Firewall permite 443" "grep -q 'ufw allow 443' deploy.sh"

echo ""
echo -e "${BLUE}📋 8. VERIFICANDO VALIDAÇÕES DE SEGURANÇA${NC}"
echo "────────────────────────────────────────"

check "Valida se é root" "grep -q 'check_root' deploy.sh"
check "Valida DNS" "grep -q 'check_dns' deploy.sh"
check "Valida diretório existente" "grep -q 'ls -A.*PROJECT_DIR' deploy.sh"
check "Valida porta em uso" "grep -q 'netstat.*APP_PORT\|ss.*APP_PORT' deploy.sh"
check "Valida domínio Nginx existente" "grep -q 'sites-available/\$DOMAIN' deploy.sh"

echo ""
echo -e "${BLUE}📋 9. VERIFICANDO MENU INTERATIVO${NC}"
echo "────────────────────────────────────────"

check "Menu existe" "grep -q '^show_menu()' deploy.sh"
check "Deploy completo no menu" "grep -q 'deploy_complete' deploy.sh"
check "Update no menu" "grep -q 'update_application' deploy.sh"
check "Remove no menu" "grep -q 'remove_project' deploy.sh"
check "Status no menu" "grep -q 'show_system_status' deploy.sh"
check "Loop do menu" "grep -q 'while true' deploy.sh"

echo ""
echo -e "${BLUE}📋 10. VERIFICANDO ARQUIVOS AUXILIARES${NC}"
echo "────────────────────────────────────────"

check "backup.sh existe" "[ -f backup.sh ]"
check "monitor.sh existe" "[ -f monitor.sh ]"
check "novusio-cli.sh existe" "[ -f novusio-cli.sh ]"
check "ecosystem.config.js existe" "[ -f ecosystem.config.js ]"
check "nginx.conf existe" "[ -f nginx.conf ]"
check "env.production.template existe" "[ -f env.production.template ]"

echo ""
echo -e "${BLUE}📋 11. VERIFICANDO PERMISSÕES${NC}"
echo "────────────────────────────────────────"

check "deploy.sh é executável" "[ -x deploy.sh ]"
check "backup.sh é executável" "[ -x backup.sh ]"
check "monitor.sh é executável" "[ -x monitor.sh ]"
check "novusio-cli.sh é executável" "[ -x novusio-cli.sh ]"
check "quick-deploy.sh é executável" "[ -x quick-deploy.sh ]"

echo ""
echo -e "${BLUE}📋 12. VERIFICANDO FORMATO DOS ARQUIVOS${NC}"
echo "────────────────────────────────────────"

for script in *.sh; do
    if file "$script" | grep -q "CRLF"; then
        echo -e "  ${RED}❌ $script - Formato Windows (PRECISA CORRIGIR)${NC}"
        ((CHECKS_FAILED++))
    else
        echo -e "  ${GREEN}✅ $script - Formato Unix correto${NC}"
        ((CHECKS_PASSED++))
    fi
done

echo ""
echo "=============================================="
echo -e "${BLUE}📊 RESULTADO DA VERIFICAÇÃO${NC}"
echo "=============================================="
echo ""
echo -e "${GREEN}✅ Verificações passaram: $CHECKS_PASSED${NC}"
echo -e "${RED}❌ Verificações falharam: $CHECKS_FAILED${NC}"
echo ""

TOTAL=$((CHECKS_PASSED + CHECKS_FAILED))
PERCENTAGE=$((CHECKS_PASSED * 100 / TOTAL))

echo "Taxa de sucesso: $PERCENTAGE%"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 SISTEMA DE DEPLOY 100% VERIFICADO!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "✅ Pronto para fazer commit e usar em produção!"
    echo ""
elif [ $PERCENTAGE -ge 90 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️ Sistema quase pronto ($PERCENTAGE%)${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Revise os itens que falharam acima"
    echo ""
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ Sistema precisa de correções${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Execute: bash fix-scripts.sh"
    echo ""
fi

