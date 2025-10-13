# ⚛️ Sitio Web Novusio - React + Panel Admin 🇵🇾

Sistema completo desarrollado en **React** con panel administrativo, backend Node.js, base de datos SQLite y gestión completa de contenido.

**Adaptado para Paraguay** con información local, formato de teléfono paraguayo (+595) y ubicación en Asunción.

## 🆕 Versión React

Este proyecto ahora usa **React 18** con Vite para una experiencia de desarrollo moderna y ultra-rápida.

## ✨ Características - Sistema React

- ⚛️ **React 18**: Framework moderno con componentes reutilizables
- ⚡ **Vite**: Build ultra-rápido y Hot Module Replacement
- 🛣️ **React Router**: SPA con navegación sin recargas
- 🎨 **Panel Admin Completo**: Interfaz moderna en React
- 🔐 **Autenticación JWT**: Context API para estado global
- 📤 **Carga de Imágenes**: Gestión desde el panel
- 🔄 **API RESTful**: Backend Node.js con Express
- 💾 **Base de Datos**: SQLite para contenido
- 📊 **Dashboard**: Estadísticas en tiempo real
- 📧 **Gestión de Mensajes**: Sistema completo de contacto
- 🇵🇾 **Adaptado a Paraguay**: +595, Asunción

## 🚀 Características del Sitio

- **Diseño Responsivo**: Funciona perfectamente en desktop, tablet y mobile
- **Carrusel Interactivo**: Hero section con navegación automática y manual
- **Formulario de Contacto**: Validación y envío de mensajes (integrado con API)
- **Navegación Suave**: Scroll suave entre secciones
- **Animaciones**: Efectos de fade-in y hover
- **Performance Optimizado**: Carga rápida y eficiente
- **Contenido Dinámico**: Integrado con API para contenido editable
- **Idioma**: 100% en español para el mercado paraguayo

## 📁 Estrutura do Projeto

```
Site Novusio/
├── index.html          # Página principal
├── styles.css          # Estilos CSS
├── script.js           # Funcionalidades JavaScript
└── README.md           # Este arquivo
```

## 🎨 Seções do Site

1. **Navegação**: Menu responsivo com logo e links
2. **Hero**: Carrossel com 4 slides principais
3. **Serviços**: Grid de serviços oferecidos
4. **Portfólio**: Galeria de clientes
5. **Sobre Nós**: Informações da empresa e valores
6. **Contato**: Formulário e informações de contato
7. **Rodapé**: Links úteis e redes sociais

## 🛠️ Tecnologias Utilizadas

- **HTML5**: Estrutura semântica
- **CSS3**: Estilos modernos com Flexbox e Grid
- **JavaScript ES6+**: Funcionalidades interativas
- **Google Fonts**: Tipografia Inter
- **SVG Icons**: Ícones vetoriais escaláveis

## 🚀 Inicio Rápido

### Instalación y Configuración

1. **Instalar TODAS las dependencias (Backend + Frontend React):**

```bash
npm run install:all
```

2. **Verificar archivo `.env`:**

El archivo `.env` ya debe estar creado. Si no existe:

```bash
cp .env.example .env
```

3. **Inicializar base de datos:**

```bash
npm run init-db
```

4. **Iniciar en modo desarrollo (Backend + Frontend):**

```bash
npm run dev
```

Esto inicia:

- **Backend API:** http://localhost:3000
- **Frontend React:** http://localhost:5173

5. **Acceder:**

- **Sitio Web React:** http://localhost:5173
- **Panel Admin React:** http://localhost:5173/admin
- **API Backend:** http://localhost:3000/api

### Credenciales Por Defecto del Admin

- **Email:** admin@novusiopy.com
- **Contraseña:** Admin123!

⚠️ **¡Cambie estas credenciales después del primer inicio de sesión!**

---

## ⚡ Scripts Disponibles

```bash
# Desarrollo (Backend + Frontend simultáneo)
npm run dev

# Solo Backend
npm run server:dev

# Solo Frontend React
npm run client

# Build para producción
npm run build

# Iniciar en producción
npm start
```

---

## 📚 Documentación Completa

- **[README-REACT.md](README-REACT.md)** - 📘 Guía completa del sistema React
- **[COMO-EXECUTAR-REACT.md](COMO-EXECUTAR-REACT.md)** - 🚀 Cómo ejecutar paso a paso

## 📱 Funcionalidades

### Carrossel Hero

- Navegação automática a cada 5 segundos
- Botões de navegação anterior/próximo
- Indicadores de pontos
- Pausa no hover
- Navegação por teclado (setas)

### Menu Mobile

- Hamburger menu responsivo
- Animações suaves
- Fechamento automático ao clicar em links

### Formulário de Contato

- Validação de campos obrigatórios
- Validação de email
- Feedback visual durante envio
- Reset automático após envio

### Animações

- Fade-in nas seções ao fazer scroll
- Efeitos hover nos cards
- Transições suaves
- Animações de carregamento

## 🎯 Otimizações

- **Performance**: Imagens otimizadas e lazy loading
- **SEO**: Meta tags e estrutura semântica
- **Acessibilidade**: Navegação por teclado e ARIA labels
- **Responsividade**: Design mobile-first
- **Compatibilidade**: Suporte a navegadores modernos

## 📊 Información de la Empresa

**Novusio Paraguay** es una empresa especializada en soluciones digitales innovadoras:

- **Chatbots con IA**: Automatización de atención 24/7
- **Desarrollo de Sistemas**: Software personalizado
- **Seguridad Cibernética**: Protección de datos
- **Sitios Web & E-commerce**: Presencia digital

### Contacto 🇵🇾

- **Email**: contacto@novusiopy.com
- **Teléfono**: +595 981 234 567
- **Ubicación**: Asunción, Paraguay

## 🔧 Personalização

Para personalizar o site:

1. **Cores**: Edite as variáveis CSS no arquivo `styles.css`
2. **Conteúdo**: Modifique o texto diretamente no `index.html`
3. **Imagens**: Substitua as URLs das imagens do Unsplash
4. **Funcionalidades**: Adicione novas features no `script.js`

## 📄 Licença

Este projeto foi desenvolvido para a empresa Novusio. Todos os direitos reservados.

## 🤝 Soporte

Para dudas o soporte técnico, entre en contacto a través del formulario en el sitio web o por email: contacto@novusiopy.com

---

**Desarrollado con ❤️ para Novusio Paraguay 🇵🇾**
