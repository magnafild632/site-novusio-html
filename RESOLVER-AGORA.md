# ⚡ Resolver Problema Atual no Servidor

## 🎯 Situação Atual

Você está no meio do deploy e recebeu o erro:

```
fatal: destination path '.' already exists and is not an empty directory.
```

---

## ✅ Solução Rápida

### **Opção 1: Remover e Reinstalar (RECOMENDADO)**

```bash
# No servidor, execute:

# 1. Sair do script atual (se ainda estiver rodando)
Ctrl+C

# 2. Remover diretório
rm -rf /opt/novusio

# 3. Voltar e executar deploy novamente
cd ~/site-novusio-html/instalador
sudo ./deploy.sh

# Escolha opção 1 (Deploy Completo)
# Preencha as informações novamente
```

---

### **Opção 2: Continuar com Código Existente**

Se já existe código em `/opt/novusio`:

```bash
# 1. Sair do script atual
Ctrl+C

# 2. Atualizar o código existente
cd /opt/novusio
git pull origin main

# 3. Continuar instalação manualmente:

# Instalar dependências
npm ci --production

# Build do cliente
cd client
npm ci
npm run build
cd ..

# Criar .env
sudo ./instalador/deploy.sh
# Escolha opção 2 (Atualizar Aplicação)
```

---

### **Opção 3: Usar o Script Atualizado**

```bash
# 1. Atualizar o repositório instalador
cd ~/site-novusio-html
git pull origin main

# 2. Executar deploy novamente
cd instalador
sudo ./deploy.sh

# Agora o script vai detectar automaticamente que o diretório existe
# e vai perguntar se você quer atualizar ou fazer backup
```

---

## 🔄 Depois de Resolver

### Fazer Commit do Script Corrigido

**No seu computador:**

```bash
cd /Users/mac/Documents/GitHub/site-novusio-html

# Adicionar mudanças
git add .

# Commit
git commit -m "Corrigido clone de repositório para lidar com diretório existente"

# Push
git push origin main
```

### No Servidor (após push):

```bash
# Atualizar código
cd ~/site-novusio-html
git pull origin main

# Executar deploy com script atualizado
cd instalador
sudo ./deploy.sh
```

---

## 📋 O Que Foi Corrigido

O script `deploy.sh` agora:

✅ **Detecta se o diretório existe**
✅ **Verifica se é um repositório Git**
✅ **Faz backup** se necessário
✅ **Atualiza código** se for repositório existente
✅ **Clona novo** se diretório vazio

---

## 🎯 Escolha sua opção e continue!

**Recomendação:** Use a **Opção 1** (remover e reinstalar) para garantir uma instalação limpa.

```bash
rm -rf /opt/novusio
cd ~/site-novusio-html/instalador
sudo ./deploy.sh
```

É rápido e garante que tudo será instalado corretamente! 🚀
