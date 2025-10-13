const express = require('express');
const router = express.Router();
const db = require('../config/database');
const authMiddleware = require('../middleware/auth');

// Listar todas as informações (público)
router.get('/', (req, res) => {
  db.all('SELECT * FROM company_info', [], (err, rows) => {
    if (err) {
      return res.status(500).json({
        success: false,
        message: 'Erro ao buscar informações',
      });
    }

    // Converter para objeto {key: value}
    const info = {};
    rows.forEach(row => {
      info[row.key] = row.value;
    });

    res.json({
      success: true,
      data: info,
    });
  });
});

// Atualizar informação específica (protegido)
router.put('/:key', authMiddleware, (req, res) => {
  const { value } = req.body;
  const { key } = req.params;

  if (!value) {
    return res.status(400).json({
      success: false,
      message: 'Valor é obrigatório',
    });
  }

  const query = `
    INSERT INTO company_info (key, value, updated_at)
    VALUES (?, ?, CURRENT_TIMESTAMP)
    ON CONFLICT(key) DO UPDATE SET 
      value = excluded.value,
      updated_at = CURRENT_TIMESTAMP
  `;

  db.run(query, [key, value], function (err) {
    if (err) {
      return res.status(500).json({
        success: false,
        message: 'Erro ao atualizar informação',
      });
    }

    res.json({
      success: true,
      message: 'Informação atualizada com sucesso',
    });
  });
});

// Atualizar múltiplas informações (protegido)
router.put('/', authMiddleware, (req, res) => {
  const updates = req.body;

  if (!updates || Object.keys(updates).length === 0) {
    return res.status(400).json({
      success: false,
      message: 'Nenhuma informação para atualizar',
    });
  }

  const stmt = db.prepare(`
    INSERT INTO company_info (key, value, updated_at)
    VALUES (?, ?, CURRENT_TIMESTAMP)
    ON CONFLICT(key) DO UPDATE SET 
      value = excluded.value,
      updated_at = CURRENT_TIMESTAMP
  `);

  let errorOccurred = false;

  Object.entries(updates).forEach(([key, value]) => {
    stmt.run([key, value], err => {
      if (err) errorOccurred = true;
    });
  });

  stmt.finalize(err => {
    if (err || errorOccurred) {
      return res.status(500).json({
        success: false,
        message: 'Erro ao atualizar informações',
      });
    }

    res.json({
      success: true,
      message: 'Informações atualizadas com sucesso',
    });
  });
});

module.exports = router;
