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

  if (!req.file && !req.body.logo_url) {
    return res.status(400).json({
      success: false,
      message: 'Logo é obrigatória',
    });
  }

  // Se tem arquivo, salvar no banco; senão, usar URL externa
  const logo_url = req.body.logo_url || null;
  const logo_data = req.file ? req.file.buffer : null;
  const logo_mimetype = req.file ? req.file.mimetype : null;
  const logo_filename = req.file ? req.file.originalname : null;

  const query = `
    INSERT INTO portfolio_clients (name, logo_url, logo_data, logo_mimetype, logo_filename, order_position, active)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `;

  db.run(
    query,
    [
      name,
      logo_url,
      logo_data,
      logo_mimetype,
      logo_filename,
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
          logo_url: logo_url || `/api/portfolio/${this.lastID}/logo`,
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

      // Preparar dados para atualização
      const logo_url = req.body.logo_url || client.logo_url;
      const logo_data = req.file ? req.file.buffer : client.logo_data;
      const logo_mimetype = req.file ? req.file.mimetype : client.logo_mimetype;
      const logo_filename = req.file ? req.file.originalname : client.logo_filename;

      const query = `
      UPDATE portfolio_clients 
      SET name = ?, logo_url = ?, logo_data = ?, logo_mimetype = ?, logo_filename = ?, order_position = ?, active = ?
      WHERE id = ?
    `;

      db.run(
        query,
        [
          name || client.name,
          logo_url,
          logo_data,
          logo_mimetype,
          logo_filename,
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

// Servir logo do cliente (público)
router.get('/:id/logo', (req, res) => {
  db.get(
    'SELECT logo_data, logo_mimetype, logo_filename FROM portfolio_clients WHERE id = ? AND active = 1',
    [req.params.id],
    (err, row) => {
      if (err || !row || !row.logo_data) {
        return res.status(404).json({
          success: false,
          message: 'Logo não encontrada',
        });
      }

      res.set({
        'Content-Type': row.logo_mimetype || 'image/png',
        'Content-Disposition': `inline; filename="${row.logo_filename || 'logo.png'}"`,
        'Cache-Control': 'public, max-age=31536000', // 1 ano
      });

      res.send(row.logo_data);
    },
  );
});

module.exports = router;
