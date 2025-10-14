const express = require('express');
const router = express.Router();
const db = require('../config/database');
const authMiddleware = require('../middleware/auth');
const upload = require('../config/multer');

// Listar todos os clientes (público)
router.get('/', (req, res) => {
  const query = `
    SELECT * FROM portfolio_clients 
    WHERE active = 1 
    ORDER BY order_position ASC
  `;

  db.all(query, [], (err, rows) => {
    if (err) {
      return res.status(500).json({
        success: false,
        message: 'Erro ao buscar clientes',
      });
    }

    res.json({
      success: true,
      data: rows,
    });
  });
});

// Buscar cliente por ID (público)
router.get('/:id', (req, res) => {
  db.get(
    'SELECT * FROM portfolio_clients WHERE id = ?',
    [req.params.id],
    (err, row) => {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Erro ao buscar cliente',
        });
      }

      if (!row) {
        return res.status(404).json({
          success: false,
          message: 'Cliente não encontrado',
        });
      }

      res.json({
        success: true,
        data: row,
      });
    },
  );
});

// Criar cliente (protegido)
router.post('/', authMiddleware, upload.single('logo'), (req, res) => {
  console.log('📁 Portfolio upload request:', {
    hasFile: !!req.file,
    fileSize: req.file?.size,
    fileMimetype: req.file?.mimetype,
    fileName: req.file?.originalname,
    body: req.body
  });

  const { name, order_position, active } = req.body;

  if (!name) {
    return res.status(400).json({
      success: false,
      message: 'Nome é obrigatório',
    });
  }

  const logo_url = req.file ? `/uploads/${req.file.filename}` : '';

  if (!logo_url && !req.body.logo_url) {
    return res.status(400).json({
      success: false,
      message: 'Logo é obrigatória',
    });
  }

  const finalLogoUrl = logo_url || req.body.logo_url;

  const query = `
    INSERT INTO portfolio_clients (name, logo_url, order_position, active)
    VALUES (?, ?, ?, ?)
  `;

  db.run(
    query,
    [
      name,
      finalLogoUrl,
      order_position || 0,
      active !== undefined ? active : 1,
    ],
    function (err) {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Erro ao criar cliente',
        });
      }

      res.status(201).json({
        success: true,
        message: 'Cliente criado com sucesso',
        data: {
          id: this.lastID,
          name,
          logo_url: finalLogoUrl,
          order_position: order_position || 0,
          active: active !== undefined ? active : 1,
        },
      });
    },
  );
});

// Atualizar cliente (protegido)
router.put('/:id', authMiddleware, upload.single('logo'), (req, res) => {
  const { name, order_position, active } = req.body;
  const logo_url = req.file
    ? `/uploads/${req.file.filename}`
    : req.body.logo_url;

  db.get(
    'SELECT * FROM portfolio_clients WHERE id = ?',
    [req.params.id],
    (err, client) => {
      if (err || !client) {
        return res.status(404).json({
          success: false,
          message: 'Cliente não encontrado',
        });
      }

      const query = `
      UPDATE portfolio_clients 
      SET name = ?, logo_url = ?, order_position = ?, active = ?
      WHERE id = ?
    `;

      db.run(
        query,
        [
          name || client.name,
          logo_url || client.logo_url,
          order_position !== undefined ? order_position : client.order_position,
          active !== undefined ? active : client.active,
          req.params.id,
        ],
        err => {
          if (err) {
            return res.status(500).json({
              success: false,
              message: 'Erro ao atualizar cliente',
            });
          }

          res.json({
            success: true,
            message: 'Cliente atualizado com sucesso',
          });
        },
      );
    },
  );
});

// Deletar cliente (protegido)
router.delete('/:id', authMiddleware, (req, res) => {
  db.run(
    'DELETE FROM portfolio_clients WHERE id = ?',
    [req.params.id],
    function (err) {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Erro ao deletar cliente',
        });
      }

      if (this.changes === 0) {
        return res.status(404).json({
          success: false,
          message: 'Cliente não encontrado',
        });
      }

      res.json({
        success: true,
        message: 'Cliente deletado com sucesso',
      });
    },
  );
});

module.exports = router;
