const express = require('express');
const router = express.Router();
const db = require('../config/database');
const authMiddleware = require('../middleware/auth');

// Listar todos os serviços (público)
router.get('/', (req, res) => {
  const query = `
    SELECT * FROM services 
    WHERE active = 1 
    ORDER BY order_position ASC
  `;

  db.all(query, [], (err, rows) => {
    if (err) {
      return res.status(500).json({
        success: false,
        message: 'Erro ao buscar serviços',
      });
    }

    // Parse das features (JSON string para array)
    const servicesWithFeatures = rows.map(service => ({
      ...service,
      features: JSON.parse(service.features),
    }));

    res.json({
      success: true,
      data: servicesWithFeatures,
    });
  });
});

// Buscar serviço por ID (público)
router.get('/:id', (req, res) => {
  db.get('SELECT * FROM services WHERE id = ?', [req.params.id], (err, row) => {
    if (err) {
      return res.status(500).json({
        success: false,
        message: 'Erro ao buscar serviço',
      });
    }

    if (!row) {
      return res.status(404).json({
        success: false,
        message: 'Serviço não encontrado',
      });
    }

    res.json({
      success: true,
      data: {
        ...row,
        features: JSON.parse(row.features),
      },
    });
  });
});

// Criar serviço (protegido)
router.post('/', authMiddleware, (req, res) => {
  const { title, description, icon, features, order_position, active } =
    req.body;

  console.log('Dados recebidos:', req.body);

  if (!title || !description) {
    return res.status(400).json({
      success: false,
      message: 'Título e descrição são obrigatórios',
    });
  }

  const featuresJson = JSON.stringify(features || []);
  const iconValue = icon || '';

  const query = `
    INSERT INTO services (title, description, icon, features, order_position, active)
    VALUES (?, ?, ?, ?, ?, ?)
  `;

  db.run(
    query,
    [
      title,
      description,
      iconValue,
      featuresJson,
      order_position || 0,
      active !== undefined ? active : 1,
    ],
    function (err) {
      if (err) {
        console.error('Erro ao criar serviço:', err);
        return res.status(500).json({
          success: false,
          message: 'Erro ao criar serviço: ' + err.message,
        });
      }

      res.status(201).json({
        success: true,
        message: 'Serviço criado com sucesso',
        data: {
          id: this.lastID,
          title,
          description,
          icon: iconValue,
          features,
          order_position: order_position || 0,
          active: active !== undefined ? active : 1,
        },
      });
    },
  );
});

// Atualizar serviço (protegido)
router.put('/:id', authMiddleware, (req, res) => {
  const { title, description, icon, features, order_position, active } =
    req.body;

  db.get(
    'SELECT * FROM services WHERE id = ?',
    [req.params.id],
    (err, service) => {
      if (err || !service) {
        return res.status(404).json({
          success: false,
          message: 'Serviço não encontrado',
        });
      }

      const featuresJson = features
        ? JSON.stringify(features)
        : service.features;

      const query = `
      UPDATE services 
      SET title = ?, description = ?, icon = ?, features = ?, order_position = ?, active = ?
      WHERE id = ?
    `;

      db.run(
        query,
        [
          title || service.title,
          description || service.description,
          icon || service.icon,
          featuresJson,
          order_position !== undefined
            ? order_position
            : service.order_position,
          active !== undefined ? active : service.active,
          req.params.id,
        ],
        err => {
          if (err) {
            return res.status(500).json({
              success: false,
              message: 'Erro ao atualizar serviço',
            });
          }

          res.json({
            success: true,
            message: 'Serviço atualizado com sucesso',
          });
        },
      );
    },
  );
});

// Deletar serviço (protegido)
router.delete('/:id', authMiddleware, (req, res) => {
  db.run('DELETE FROM services WHERE id = ?', [req.params.id], function (err) {
    if (err) {
      return res.status(500).json({
        success: false,
        message: 'Erro ao deletar serviço',
      });
    }

    if (this.changes === 0) {
      return res.status(404).json({
        success: false,
        message: 'Serviço não encontrado',
      });
    }

    res.json({
      success: true,
      message: 'Serviço deletado com sucesso',
    });
  });
});

module.exports = router;
