#!/bin/bash

# Script para verificar se os arquivos estão prontos para commit

echo "🔍 Verificando arquivos antes do commit..."
echo "=========================================="

cd instalador

# Verificar formato dos arquivos
echo ""
echo "📝 Verificando formato dos arquivos..."
for file in *.sh; do
    if file "$file" | grep -q "CRLF"; then
        echo "  ❌ $file - Formato Windows (CRLF) - PRECISA CORRIGIR!"
        exit 1
    elif file "$file" | grep -q "ASCII\|UTF-8"; then
        echo "  ✅ $file - Formato correto"
    else
        echo "  ⚠️  $file - Formato desconhecido"
    fi
done

# Verificar permissões
echo ""
echo "🔐 Verificando permissões..."
for file in *.sh; do
    if [ -x "$file" ]; then
        echo "  ✅ $file - Executável"
    else
        echo "  ❌ $file - SEM permissão de execução"
        chmod +x "$file"
        echo "     → Corrigido!"
    fi
done

# Verificar shebang
echo ""
echo "📋 Verificando shebang..."
for file in *.sh; do
    first_line=$(head -1 "$file")
    if [[ "$first_line" == "#!/bin/bash"* ]]; then
        echo "  ✅ $file - Shebang correto"
    else
        echo "  ⚠️  $file - Shebang: $first_line"
    fi
done

echo ""
echo "=========================================="
echo "✅ Verificação concluída!"
echo ""
echo "Próximos passos:"
echo "1. git add ."
echo "2. git commit -m 'Sistema completo de deploy corrigido'"
echo "3. git push origin main"

