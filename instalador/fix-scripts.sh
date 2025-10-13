#!/bin/bash

# =============================================================================
# CORRETOR DE SCRIPTS - NOVUSIO
# =============================================================================
# Este script corrige problemas de formato e permissões
# Use se encontrar erro "cannot execute: required file not found"
# =============================================================================

echo "🔧 Corrigindo scripts do Novusio..."
echo "=================================="

# Converter line endings (Windows -> Unix)
echo "📝 Convertendo formato de linha..."
if command -v dos2unix &> /dev/null; then
    dos2unix *.sh 2>/dev/null || true
elif command -v sed &> /dev/null; then
    for file in *.sh; do
        if [ -f "$file" ]; then
            sed -i 's/\r$//' "$file" 2>/dev/null || sed -i '' 's/\r$//' "$file" 2>/dev/null || true
            echo "  ✓ $file"
        fi
    done
fi

# Dar permissão de execução
echo ""
echo "🔐 Configurando permissões..."
chmod +x *.sh 2>/dev/null || true
for file in *.sh; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    fi
done

echo ""
echo "✅ Scripts corrigidos com sucesso!"
echo ""
echo "Agora execute:"
echo "  sudo ./deploy.sh"

