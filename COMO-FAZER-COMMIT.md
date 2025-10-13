# 📋 Como Fazer Commit e Deploy

## ✅ Scripts Corrigidos Localmente!

Todos os scripts foram corrigidos no seu computador e agora estão prontos para serem enviados ao servidor.

---

## 🚀 Passo a Passo

### **1️⃣ Fazer Commit no Git**

```bash
cd /Users/mac/Documents/GitHub/site-novusio-html

# Adicionar todos os arquivos
git add .

# Fazer commit
git commit -m "Sistema completo de deploy com scripts corrigidos para Unix"

# Enviar para GitHub
git push origin main
```

---

### **2️⃣ No Servidor VPS**

#### **A. Limpar instalação anterior (se existir)**

```bash
# Conectar ao servidor
ssh root@seu-servidor.com

# Remover pasta antiga
rm -rf ~/instalador
rm -rf ~/site-novusio-html

# Ou se já instalou em /opt/novusio
# Use o menu de remoção se necessário
```

#### **B. Clonar repositório novamente**

```bash
# Clonar
git clone https://github.com/seu-usuario/site-novusio-html.git

# Entrar na pasta
cd site-novusio-html/instalador

# Listar arquivos
ls -la
```

#### **C. Executar deploy**

```bash
# AGORA vai funcionar!
sudo ./deploy.sh
```

---

## 🎯 O Que Foi Corrigido

✅ Todos os scripts convertidos para formato Unix (LF)
✅ Permissões de execução configuradas (755)
✅ Shebang correto (#!/bin/bash)
✅ Formato de arquivo verificado

---

## 📝 Arquivos Corrigidos

- ✅ `backup.sh`
- ✅ `deploy.sh`
- ✅ `fix-scripts.sh`
- ✅ `monitor.sh`
- ✅ `novusio-cli.sh`
- ✅ `quick-deploy.sh`
- ✅ `regenerate-secrets.sh`

---

## ⚠️ IMPORTANTE

**NÃO** precisa mais executar `fix-scripts.sh` no servidor!

Os scripts já estão corrigidos e prontos para uso.

Apenas execute:

```bash
sudo ./deploy.sh
```

---

## 🔍 Verificação

Se quiser verificar no servidor que está tudo OK:

```bash
# Ver tipo dos arquivos
file deploy.sh
# Deve mostrar: Bourne-Again shell script text executable, ASCII text

# Ver permissões
ls -la *.sh
# Todos devem ter: -rwxr-xr-x

# Testar execução
./deploy.sh --help 2>&1 | head -5
# Não deve dar erro de "file not found"
```

---

## 🎉 Pronto!

Agora você pode:

1. ✅ Fazer commit e push
2. ✅ Clonar no servidor
3. ✅ Executar `sudo ./deploy.sh` diretamente

**Problema resolvido! 🚀**
