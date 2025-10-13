# ✅ Correções Aplicadas - Erros de Deploy

## 🐛 Problemas Identificados e Corrigidos

### 1. **Erro 500 - Internal Server Error**
**Causa:** Caminho incorreto para o build do React em produção

**Correção:**
- ✅ Atualizado `server/server.js` para buscar build em `client/dist`
- ✅ Atualizado `client/vite.config.js` para gerar build em `dist` (dentro de client)
- ✅ Adicionado melhor tratamento de erros com stack trace em desenvolvimento

### 2. **Erro 404 - Favicon não encontrado**
**Causa:** Favicon não existia como arquivo físico

**Correção:**
- ✅ Criada pasta `client/public/`
- ✅ Adicionado `favicon.svg` com logo Novusio
- ✅ Atualizado `client/index.html` para usar `/favicon.svg`

### 3. **Erro SSL - Email padrão configurado**
**Correção:**
- ✅ Email padrão configurado: `suporte@novusiopy.com`
- ✅ Atualizado em todos os scripts de deploy

---

## 📋 Arquivos Modificados

### Server (Backend)
- ✅ `server/server.js` - Caminho do build corrigido + melhor tratamento de erros

### Client (Frontend)
- ✅ `client/vite.config.js` - Build configurado para `dist/`
- ✅ `client/index.html` - Favicon atualizado
- ✅ `client/public/favicon.svg` - Favicon criado

### Deploy (Instalação)
- ✅ `instalador/deploy.sh` - Email padrão SSL
- ✅ `instalador/quick-deploy.sh` - Email padrão SSL
- ✅ `instalador/env.production.template` - Emails de contato
- ✅ `instalador/verificar-ssl.sh` - Email no exemplo
- ✅ `instalador/TROUBLESHOOTING.md` - Email atualizado
- ✅ `instalador/INICIO-RAPIDO.md` - Email padrão

---

## 🚀 Como Testar as Correções

### 1. **Em Desenvolvimento (Local)**

```bash
# Limpar builds anteriores
rm -rf client/dist

# Fazer novo build
npm run build

# Iniciar em modo produção local
NODE_ENV=production npm run server
```

Acesse: http://localhost:3000

### 2. **No Servidor (Deploy)**

```bash
# SSH no servidor
ssh usuario@seu-servidor

# Ir para o diretório do projeto
cd /opt/novusio

# Fazer backup
sudo /usr/local/bin/novusio-backup.sh

# Atualizar código
git pull origin main

# Instalar dependências
npm ci --production
cd client && npm ci && cd ..

# Fazer build
npm run build

# Reiniciar aplicação
sudo -u novusio pm2 restart novusio-server

# Verificar logs
sudo -u novusio pm2 logs novusio-server
```

---

## 🔍 Verificar se Tudo Está Funcionando

### 1. **Verificar Build**
```bash
# Deve existir a pasta client/dist/
ls -la client/dist/

# Deve conter:
# - index.html
# - favicon.svg
# - assets/
```

### 2. **Verificar Servidor**
```bash
# Logs do PM2
pm2 logs novusio-server --lines 50

# Não deve ter erros 500
# Deve mostrar: ✅ Conectado ao banco de dados SQLite
```

### 3. **Verificar no Browser**
- ✅ Site carrega sem erro 500
- ✅ Favicon aparece na aba do navegador
- ✅ Console do browser sem erros

### 4. **Testar API**
```bash
curl http://localhost:3000/api/health
# Deve retornar: {"success":true,"message":"API funcionando corretamente",...}
```

---

## 🛠️ Troubleshooting

### Se ainda houver erro 500:

1. **Verificar se o build existe:**
```bash
ls -la client/dist/index.html
```

2. **Verificar permissões:**
```bash
sudo chown -R novusio:novusio /opt/novusio
```

3. **Verificar logs detalhados:**
```bash
pm2 logs novusio-server --lines 100 --err
```

4. **Testar build manualmente:**
```bash
cd client
npm run build
ls -la dist/
```

### Se ainda houver erro 404 no favicon:

1. **Verificar se o arquivo existe:**
```bash
ls -la client/public/favicon.svg
```

2. **Verificar se foi copiado no build:**
```bash
ls -la client/dist/favicon.svg
```

3. **Limpar cache do browser:**
- Ctrl + Shift + Del
- Limpar cache e cookies

---

## ✅ Checklist Final

Antes de fazer deploy em produção:

- [ ] Build funciona localmente: `npm run build`
- [ ] Servidor funciona em modo produção local: `NODE_ENV=production npm run server`
- [ ] Favicon aparece corretamente
- [ ] API responde: `/api/health`
- [ ] Banco de dados conecta
- [ ] Logs sem erros
- [ ] SSL configurado com `suporte@novusiopy.com`

---

## 📧 Contato

Para suporte: **suporte@novusiopy.com**

---

**Última atualização:** 13/10/2025

