const express = require('express');
const router = express.Router();
const db = require('../config/database');
const authMiddleware = require('../middleware/auth');
const upload = require('../config/multer');

// Listar todos os slides (público)
router.get('/', (req, res) => {
  const query = `
    SELECT * FROM hero_slides 
    WHERE active = 1 
    ORDER BY order_position ASC
  `;

  db.all(query, [], (err, rows) => {
    if (err) {
      return res.status(500).json({
        success: false,
        message: 'Erro ao buscar slides',
      });
    }

    res.json({
      success: true,
      data: rows,
    });
  });
});

// Buscar slide por ID (público)
router.get('/:id', (req, res) => {
  db.get(
    'SELECT * FROM hero_slides WHERE id = ?',
    [req.params.id],
    (err, row) => {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Erro ao buscar slide',
        });
      }

      if (!row) {
        return res.status(404).json({
          success: false,
          message: 'Slide não encontrado',
        });
      }

      res.json({
        success: true,
        data: row,
      });
    },
  );
});

// Criar slide (protegido)
router.post('/', authMiddleware, upload.single('image'), (req, res) => {
  const { title, subtitle, order_position, active } = req.body;

  if (!title || !subtitle) {
    return res.status(400).json({
      success: false,
      message: 'Título e subtítulo são obrigatórios',
    });
  }

  const image_url = req.file ? `/uploads/${req.file.filename}` : '';

  if (!image_url && !req.body.image_url) {
    return res.status(400).json({
      success: false,
      message: 'Imagem é obrigatória',
    });
  }

  const finalImageUrl = image_url || req.body.image_url;

  const query = `
    INSERT INTO hero_slides (title, subtitle, image_url, order_position, active)
    VALUES (?, ?, ?, ?, ?)
  `;

  db.run(
    query,
    [
      title,
      subtitle,
      finalImageUrl,
      order_position || 0,
      active !== undefined ? active : 1,
    ],
    function (err) {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Erro ao criar slide',
        });
      }

      res.status(201).json({
        success: true,
        message: 'Slide criado com sucesso',
        data: {
          id: this.lastID,
          title,
          subtitle,
          image_url: finalImageUrl,
          order_position: order_position || 0,
          active: active !== undefined ? active : 1,
        },
      });
    },
  );
});

// Atualizar slide (protegido)
router.put('/:id', authMiddleware, upload.single('image'), (req, res) => {
  const { title, subtitle, order_position, active } = req.body;
  const image_url = req.file
    ? `/uploads/${req.file.filename}`
    : req.body.image_url;

  // Verificar se o slide existe
  db.get(
    'SELECT * FROM hero_slides WHERE id = ?',
    [req.params.id],
    (err, slide) => {
      if (err || !slide) {
        return res.status(404).json({
          success: false,
          message: 'Slide não encontrado',
        });
      }

      const query = `
      UPDATE hero_slides 
      SET title = ?, subtitle = ?, image_url = ?, order_position = ?, active = ?
      WHERE id = ?
    `;

      db.run(
        query,
        [
          title || slide.title,
          subtitle || slide.subtitle,
          image_url || slide.image_url,
          order_position !== undefined ? order_position : slide.order_position,
          active !== undefined ? active : slide.active,
          req.params.id,
        ],
        err => {
          if (err) {
            return res.status(500).json({
              success: false,
              message: 'Erro ao atualizar slide',
            });
          }

          res.json({
            success: true,
            message: 'Slide atualizado com sucesso',
          });
        },
      );
    },
  );
});

// Deletar slide (protegido)
router.delete('/:id', authMiddleware, (req, res) => {
  db.run(
    'DELETE FROM hero_slides WHERE id = ?',
    [req.params.id],
    function (err) {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Erro ao deletar slide',
        });
      }

      if (this.changes === 0) {
        return res.status(404).json({
          success: false,
          message: 'Slide não encontrado',
        });
      }

      res.json({
        success: true,
        message: 'Slide deletado com sucesso',
      });
    },
  );
});

module.exports = router;
