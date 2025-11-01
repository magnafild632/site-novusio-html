const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

const dbPath = path.resolve(__dirname, '../database.sqlite');
const db = new sqlite3.Database(dbPath);

console.log('🔄 Iniciando migração para BLOB...');

// Função para ler arquivo e converter para buffer
function readFileToBuffer(filePath) {
  try {
    if (fs.existsSync(filePath)) {
      return fs.readFileSync(filePath);
    }
  } catch (error) {
    console.error(`Erro ao ler arquivo ${filePath}:`, error.message);
  }
  return null;
}

// Migrar portfolio_clients
console.log('📁 Migrando portfolio_clients...');
db.all('SELECT * FROM portfolio_clients', [], (err, rows) => {
  if (err) {
    console.error('Erro ao buscar portfolio_clients:', err);
    return;
  }

  rows.forEach((client, index) => {
    if (client.logo_url && client.logo_url.startsWith('/uploads/')) {
      const filePath = path.resolve(__dirname, '..', client.logo_url);
      const imageData = readFileToBuffer(filePath);
      
      if (imageData) {
        // Detectar mimetype baseado na extensão
        const ext = path.extname(client.logo_url).toLowerCase();
        let mimetype = 'image/png';
        if (ext === '.jpg' || ext === '.jpeg') mimetype = 'image/jpeg';
        else if (ext === '.gif') mimetype = 'image/gif';
        else if (ext === '.webp') mimetype = 'image/webp';

        const filename = path.basename(client.logo_url);

        db.run(
          'UPDATE portfolio_clients SET logo_data = ?, logo_mimetype = ?, logo_filename = ? WHERE id = ?',
          [imageData, mimetype, filename, client.id],
          function(err) {
            if (err) {
              console.error(`Erro ao migrar cliente ${client.id}:`, err);
            } else {
              console.log(`✅ Cliente ${client.id} migrado com sucesso`);
            }
          }
        );
      } else {
        console.log(`⚠️  Arquivo não encontrado para cliente ${client.id}: ${client.logo_url}`);
      }
    }
  });
});

// Migrar hero_slides
console.log('🖼️  Migrando hero_slides...');
db.all('SELECT * FROM hero_slides', [], (err, rows) => {
  if (err) {
    console.error('Erro ao buscar hero_slides:', err);
    return;
  }

  rows.forEach((slide, index) => {
    if (slide.image_url && slide.image_url.startsWith('/uploads/')) {
      const filePath = path.resolve(__dirname, '..', slide.image_url);
      const imageData = readFileToBuffer(filePath);
      
      if (imageData) {
        // Detectar mimetype baseado na extensão
        const ext = path.extname(slide.image_url).toLowerCase();
        let mimetype = 'image/png';
        if (ext === '.jpg' || ext === '.jpeg') mimetype = 'image/jpeg';
        else if (ext === '.gif') mimetype = 'image/gif';
        else if (ext === '.webp') mimetype = 'image/webp';

        const filename = path.basename(slide.image_url);

        db.run(
          'UPDATE hero_slides SET image_data = ?, image_mimetype = ?, image_filename = ? WHERE id = ?',
          [imageData, mimetype, filename, slide.id],
          function(err) {
            if (err) {
              console.error(`Erro ao migrar slide ${slide.id}:`, err);
            } else {
              console.log(`✅ Slide ${slide.id} migrado com sucesso`);
            }
          }
        );
      } else {
        console.log(`⚠️  Arquivo não encontrado para slide ${slide.id}: ${slide.image_url}`);
      }
    }
  });
});

// Fechar banco após um tempo
setTimeout(() => {
  db.close((err) => {
    if (err) {
      console.error('Erro ao fechar banco:', err);
    } else {
      console.log('\n🎉 Migração concluída!');
      console.log('\n📝 Próximos passos:');
      console.log('1. Reinicie o servidor');
      console.log('2. Teste o upload de novas imagens');
      console.log('3. Verifique se as imagens antigas estão sendo servidas corretamente');
    }
  });
}, 3000);
