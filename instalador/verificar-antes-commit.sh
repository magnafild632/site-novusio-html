#!/bin/bash

# 🔍 Verificador Pré-Deploy - Site Novusio
# Script para verificar se tudo está pronto para deploy

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

ERRORS=0
WARNINGS=0

print_status "🔍 Verificando projeto antes do deploy..."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar se está no diretório correto
if [[ ! -f "package.json" ]]; then
    print_error "❌ package.json não encontrado. Execute este script na raiz do projeto."
    exit 1
fi

# Verificar estrutura de arquivos
print_status "📁 Verificando estrutura de arquivos..."

REQUIRED_FILES=(
    "package.json"
    "server/server.js"
    "client/package.json"
    "client/src/App.jsx"
    "instalador/install.sh"
    "instalador/nginx.conf"
    "instalador/ecosystem.config.js"
    "instalador/novusio.service"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        print_success "✅ $file"
    else
        print_error "❌ $file (obrigatório)"
        ((ERRORS++))
    fi
done

# Verificar se os scripts são executáveis
print_status "🔧 Verificando permissões dos scripts..."

SCRIPTS=(
    "instalador/install.sh"
    "instalador/setup-ssl.sh"
    "instalador/deploy.sh"
    "instalador/backup.sh"
    "instalador/novusio-manager.sh"
    "instalador/regenerate-secrets.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        if [[ -x "$script" ]]; then
            print_success "✅ $script (executável)"
        else
            print_warning "⚠️ $script (não executável)"
            ((WARNINGS++))
        fi
    fi
done

# Verificar dependências do Node.js
print_status "📦 Verificando dependências..."

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_success "✅ Node.js: $NODE_VERSION"
    
    # Verificar se a versão é compatível
    if [[ "$NODE_VERSION" =~ v1[8-9]\. ]] || [[ "$NODE_VERSION" =~ v2[0-9]\. ]]; then
        print_success "✅ Versão do Node.js compatível"
    else
        print_warning "⚠️ Versão do Node.js pode ser incompatível (recomendado: 18+)"
        ((WARNINGS++))
    fi
else
    print_error "❌ Node.js não instalado"
    ((ERRORS++))
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    print_success "✅ NPM: $NPM_VERSION"
else
    print_error "❌ NPM não instalado"
    ((ERRORS++))
fi

# Verificar se as dependências estão instaladas
print_status "📦 Verificando instalação de dependências..."

if [[ -d "node_modules" ]]; then
    print_success "✅ Dependências do servidor instaladas"
else
    print_warning "⚠️ Dependências do servidor não instaladas"
    ((WARNINGS++))
fi

if [[ -d "client/node_modules" ]]; then
    print_success "✅ Dependências do cliente instaladas"
else
    print_warning "⚠️ Dependências do cliente não instaladas"
    ((WARNINGS++))
fi

# Verificar build do cliente
print_status "🏗️ Verificando build do cliente..."

if [[ -d "client/dist" ]]; then
    print_success "✅ Build do cliente encontrado"
else
    print_warning "⚠️ Build do cliente não encontrado (será criado durante deploy)"
    ((WARNINGS++))
fi

# Verificar banco de dados
print_status "🗄️ Verificando banco de dados..."

if [[ -f "database.sqlite" ]]; then
    print_success "✅ Banco de dados encontrado"
else
    print_warning "⚠️ Banco de dados não encontrado (será criado durante deploy)"
    ((WARNINGS++))
fi

# Verificar arquivo .env
print_status "⚙️ Verificando configuração..."

if [[ -f ".env" ]]; then
    print_success "✅ Arquivo .env encontrado"
    
    # Verificar variáveis obrigatórias
    source .env 2>/dev/null || true
    
    if [[ -n "$JWT_SECRET" ]]; then
        print_success "✅ JWT_SECRET configurado"
    else
        print_warning "⚠️ JWT_SECRET não configurado"
        ((WARNINGS++))
    fi
    
    if [[ -n "$DOMAIN" ]]; then
        print_success "✅ DOMAIN configurado: $DOMAIN"
    else
        print_warning "⚠️ DOMAIN não configurado"
        ((WARNINGS++))
    fi
else
    print_warning "⚠️ Arquivo .env não encontrado (será criado durante instalação)"
    ((WARNINGS++))
fi

# Verificar configurações do Nginx
print_status "🌐 Verificando configuração do Nginx..."

if [[ -f "instalador/nginx.conf" ]]; then
    # Verificar se o domínio placeholder está presente
    if grep -q "your-domain.com" "instalador/nginx.conf"; then
        print_warning "⚠️ Domínio placeholder não substituído em nginx.conf"
        ((WARNINGS++))
    else
        print_success "✅ Configuração do Nginx parece válida"
    fi
fi

# Verificar configurações do PM2
print_status "⚡ Verificando configuração do PM2..."

if [[ -f "instalador/ecosystem.config.js" ]]; then
    print_success "✅ Configuração do PM2 encontrada"
else
    print_error "❌ Configuração do PM2 não encontrada"
    ((ERRORS++))
fi

# Verificar configurações do systemd
print_status "🔄 Verificando configuração do systemd..."

if [[ -f "instalador/novusio.service" ]]; then
    print_success "✅ Configuração do systemd encontrada"
else
    print_error "❌ Configuração do systemd não encontrada"
    ((ERRORS++))
fi

# Verificar configurações de segurança
print_status "🛡️ Verificando configurações de segurança..."

if [[ -f "instalador/fail2ban.conf" ]]; then
    print_success "✅ Configuração do Fail2ban encontrada"
else
    print_warning "⚠️ Configuração do Fail2ban não encontrada"
    ((WARNINGS++))
fi

# Verificar se há arquivos sensíveis no repositório
print_status "🔒 Verificando arquivos sensíveis..."

SENSITIVE_FILES=(
    ".env"
    "database.sqlite"
    "*.key"
    "*.pem"
    "*.p12"
    "secrets.txt"
    "passwords.txt"
)

for pattern in "${SENSITIVE_FILES[@]}"; do
    if find . -name "$pattern" -not -path "./instalador/*" | grep -q .; then
        print_error "❌ Arquivos sensíveis encontrados: $pattern"
        ((ERRORS++))
    fi
done

# Verificar tamanho dos arquivos
print_status "📊 Verificando tamanho dos arquivos..."

TOTAL_SIZE=$(du -sh . | cut -f1)
print_success "✅ Tamanho total do projeto: $TOTAL_SIZE"

# Verificar se há arquivos muito grandes
LARGE_FILES=$(find . -type f -size +50M -not -path "./node_modules/*" -not -path "./.git/*" | wc -l)
if [[ $LARGE_FILES -gt 0 ]]; then
    print_warning "⚠️ $LARGE_FILES arquivo(s) maior(es) que 50MB encontrado(s)"
    ((WARNINGS++))
fi

# Resumo final
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    print_success "🎉 Verificação concluída com sucesso!"
    print_success "✅ Projeto pronto para deploy"
    echo ""
    print_status "🚀 Próximos passos:"
    echo "1. Faça upload dos arquivos para o servidor"
    echo "2. Execute: sudo ./instalador/install.sh"
    echo "3. Configure: sudo ./instalador/setup-ssl.sh"
    echo "4. Inicie: sudo systemctl start novusio"
elif [[ $ERRORS -eq 0 ]]; then
    print_warning "⚠️ Verificação concluída com $WARNINGS aviso(s)"
    print_success "✅ Projeto pode ser deployado (com ressalvas)"
    echo ""
    print_status "🔧 Resolva os avisos antes do deploy para melhor experiência"
else
    print_error "❌ Verificação falhou com $ERRORS erro(s) e $WARNINGS aviso(s)"
    print_error "❌ Corrija os erros antes de fazer deploy"
    echo ""
    print_status "🔧 Erros que devem ser corrigidos:"
    echo "- Verifique a estrutura de arquivos"
    echo "- Instale dependências necessárias"
    echo "- Configure variáveis de ambiente"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Retornar código de saída baseado nos erros
if [[ $ERRORS -gt 0 ]]; then
    exit 1
else
    exit 0
fi
