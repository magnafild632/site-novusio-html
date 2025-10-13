# 🔧 Solução para Erros 404 e 500 no Deploy

## ❌ Erros Identificados

```
/favicon.ico:1  Failed to load resource: the server responded with a status of 404 (Not Found)
(index):1  Failed to load resource: the server responded with a status of 500 (Internal Server Error)
```

---

## ✅ Correções Aplicadas

### 1. **Erro 500 - Internal Server Error**

**Problema:** Servidor buscando build no caminho errado

**Solução:**
```javascript
// server/server.js - ANTES (errado)
app.use(express.static(path.join(__dirname, '../dist')));

// server/server.js - DEPOIS (correto)
app.use(express.static(path.join(__dirname, '../client/dist')));
```

**Também corrigido:**
```javascript
// client/vite.config.js - ANTES
outDir: '../dist',

// client/vite.config.js - DEPOIS
outDir: 'dist',  // Build fica em client/dist/
```

### 2. **Erro 404 - Favicon**

**Solução:**
- ✅ Criado `client/public/favicon.svg`
- ✅ Atualizado `client/index.html` para usar `/favicon.svg`
- ✅ Vite copia automaticamente arquivos de `public/` para o build

### 3. **Email SSL Configurado**

- ✅ Email padrão: `suporte@novusiopy.com`
- ✅ Configurado em todos os scripts de deploy

---

## 🚀 Como Aplicar as Correções

### Opção 1: Script Automático (Recomendado)

No servidor, execute:

```bash
cd /opt/novusio
chmod +x instalador/atualizar-correcoes.sh
sudo ./instalador/atualizar-correcoes.sh
```

### Opção 2: Manual

```bash
# 1. Ir para o diretório do projeto
cd /opt/novusio

# 2. Atualizar código do repositório
git pull origin main

# 3. Limpar builds antigos
rm -rf client/dist
rm -rf dist

# 4. Instalar dependências
npm ci --production
cd client && npm ci && cd ..

# 5. Fazer novo build
npm run build

# 6. Verificar se build foi criado corretamente
ls -la client/dist/
# Deve conter: index.html, favicon.svg, assets/

# 7. Reiniciar aplicação
sudo -u novusio pm2 restart novusio-server

# 8. Verificar logs
sudo -u novusio pm2 logs novusio-server --lines 50
```

---

## 🔍 Verificação Pós-Deploy

### 1. Verificar Build

```bash
# Build deve estar em client/dist/
ls -la client/dist/

# Deve conter:
# - index.html (arquivo principal)
# - favicon.svg (ícone do site)
# - assets/ (JS e CSS compilados)
```

### 2. Verificar Servidor Rodando

```bash
# Status PM2
pm2 status

# Deve mostrar:
# novusio-server | online | 0 | ...

# Logs (não deve ter erros)
pm2 logs novusio-server --lines 20
```

### 3. Testar API

```bash
curl http://localhost:3000/api/health

# Resposta esperada:
# {"success":true,"message":"API funcionando corretamente",...}
```

### 4. Testar no Browser

Acesse o site e verifique:
- ✅ Site carrega sem erro 500
- ✅ Favicon aparece na aba do navegador
- ✅ Console do browser (F12) sem erros

---

## 🐛 Troubleshooting

### Se ainda houver erro 500:

1. **Verificar se o build existe:**
```bash
ls -la client/dist/index.html
# Se não existir, fazer build novamente
```

2. **Verificar logs detalhados:**
```bash
pm2 logs novusio-server --err --lines 100
```

3. **Verificar permissões:**
```bash
sudo chown -R novusio:novusio /opt/novusio
sudo chmod -R 755 /opt/novusio
```

4. **Reiniciar tudo:**
```bash
pm2 stop novusio-server
pm2 delete novusio-server
pm2 start ecosystem.config.js
pm2 save
```

### Se ainda houver erro 404 do favicon:

1. **Verificar arquivo:**
```bash
ls -la client/public/favicon.svg
ls -la client/dist/favicon.svg
```

2. **Refazer build:**
```bash
cd client
npm run build
ls -la dist/favicon.svg
```

3. **Limpar cache do browser:**
- Ctrl + Shift + Del
- Marcar "Imagens e arquivos em cache"
- Limpar dados

### Verificar configuração Nginx:

```bash
# Testar configuração
sudo nginx -t

# Ver configuração do site
cat /etc/nginx/sites-available/novusio

# Recarregar Nginx
sudo systemctl reload nginx
```

---

## 📝 Arquivos Modificados

### Backend
- ✅ `server/server.js` - Caminhos corrigidos + melhor logging

### Frontend  
- ✅ `client/vite.config.js` - Build em `dist/`
- ✅ `client/index.html` - Favicon atualizado
- ✅ `client/public/favicon.svg` - Ícone criado

### Deploy
- ✅ `instalador/deploy.sh` - Email SSL padrão
- ✅ `instalador/quick-deploy.sh` - Email SSL padrão
- ✅ `instalador/env.production.template` - Emails configurados
- ✅ E outros arquivos de documentação

---

## ✅ Checklist Final

Antes de considerar resolvido:

- [ ] `git pull` feito com sucesso
- [ ] Build criado em `client/dist/`
- [ ] Favicon existe em `client/dist/favicon.svg`
- [ ] PM2 mostra app como "online"
- [ ] API responde: `curl http://localhost:3000/api/health`
- [ ] Site carrega sem erro 500
- [ ] Favicon aparece no browser
- [ ] Console do browser sem erros
- [ ] Nginx configurado corretamente

---

## 📧 Suporte

**Email:** suporte@novusiopy.com

---

## 🎯 Resumo Rápido

```bash
# Em 3 comandos:
cd /opt/novusio
git pull origin main && npm run build
sudo -u novusio pm2 restart novusio-server
```

Depois acesse o site e verifique se tudo está funcionando! ✅

