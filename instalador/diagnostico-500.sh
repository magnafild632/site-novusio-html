#!/bin/bash

# Script para diagnosticar erro 500

echo "🔍 Diagnóstico de Erro 500 - Novusio"
echo "===================================="
echo ""

# Verificar se PM2 está rodando
echo "📊 Status PM2:"
sudo -u novusio pm2 list

echo ""
echo "📝 Últimos logs de erro (20 linhas):"
sudo -u novusio pm2 logs novusio-server --err --lines 20

echo ""
echo "📝 Logs completos recentes:"
tail -50 /var/log/novusio/error.log

echo ""
echo "🔍 Verificar se porta 3000 está respondendo:"
curl -v http://localhost:3000 2>&1 | head -20

echo ""
echo "📋 Variáveis de ambiente (.env):"
if [ -f "/opt/novusio/.env" ]; then
    echo "✅ Arquivo .env existe"
    echo "Verificando variáveis críticas:"
    grep -E "NODE_ENV|PORT|JWT_SECRET|DB_PATH" /opt/novusio/.env | sed 's/=.*/=***/'
else
    echo "❌ Arquivo .env NÃO existe!"
fi

echo ""
echo "📂 Verificar estrutura de arquivos:"
ls -la /opt/novusio/server/server.js
ls -la /opt/novusio/database.sqlite
ls -la /opt/novusio/client/dist/

echo ""
echo "🔧 Comandos para corrigir:"
echo "  1. Ver logs detalhados: sudo -u novusio pm2 logs"
echo "  2. Reiniciar aplicação: sudo -u novusio pm2 restart novusio-server"
echo "  3. Verificar .env: cat /opt/novusio/.env"
echo "  4. Reinicializar DB: cd /opt/novusio && sudo -u novusio npm run init-db"


