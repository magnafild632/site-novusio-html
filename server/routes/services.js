const express = require('express');
const router = express.Router();
const db = require('../config/database');
const authMiddleware = require('../middleware/auth');
const sanitizeSvgFragment = require('../utils/svgSanitizer');

const parseFeaturesFromDb = (rawFeatures, serviceId) => {
  if (!rawFeatures) {
    return [];
  }

  try {
    const parsed = JSON.parse(rawFeatures);

    if (!Array.isArray(parsed)) {
      throw new Error('formato inválido');
    }

    return parsed
      .map(item => (typeof item === 'string' ? item.trim() : String(item)))
      .filter(Boolean);
  } catch (error) {
    console.error(
      `Erro ao processar features do serviço ${serviceId || 'desconhecido'}:`,
      error.message,
    );
    throw new Error('Dados dos serviços corrompidos');
  }
};

const normalizeFeaturesInput = rawFeatures => {
  if (rawFeatures === undefined || rawFeatures === null || rawFeatures === '') {
    return [];
  }

  let processed = rawFeatures;

  if (typeof rawFeatures === 'string') {
    try {
      processed = JSON.parse(rawFeatures);
    } catch (error) {
      throw new Error(
        'Formato inválido para características. Envie um array de textos.',
      );
    }
  }

  if (!Array.isArray(processed)) {
    throw new Error(
      'Formato inválido para características. Envie um array de textos.',
    );
  }

  return processed
    .map(item => (typeof item === 'string' ? item.trim() : String(item)))
    .filter(Boolean);
};

const sanitizeIconInput = icon => {
  if (!icon) {
    return '';
  }

  return sanitizeSvgFragment(icon);
};

const sanitizeIconForOutput = icon => {
  try {
    return sanitizeIconInput(icon);
  } catch (error) {
    console.error('Ícone inválido encontrado no banco:', error.message);
    return '';
  }
};

const parseOrderPosition = value => {
  if (value === undefined || value === null || value === '') {
    return 0;
  }

  const parsed = parseInt(value, 10);

  if (Number.isNaN(parsed)) {
    throw new Error('Valor de ordem inválido');
  }

  return parsed;
};

const parseActiveFlag = value => {
  if (value === undefined || value === null || value === '') {
    return 1;
  }

  if (typeof value === 'string') {
    const normalized = value.toLowerCase();
    if (normalized === 'true' || normalized === '1') {
      return 1;
    }
    if (normalized === 'false' || normalized === '0') {
      return 0;
    }
  }

  return Number(value) ? 1 : 0;
};

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

    try {
      const servicesWithFeatures = rows.map(service => ({
        ...service,
        features: parseFeaturesFromDb(service.features, service.id),
        icon: sanitizeIconForOutput(service.icon),
      }));

      res.json({
        success: true,
        data: servicesWithFeatures,
      });
    } catch (processingError) {
      return res.status(500).json({
        success: false,
        message: 'Erro ao processar dados dos serviços',
      });
    }
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
        features: parseFeaturesFromDb(row.features, row.id),
        icon: sanitizeIconForOutput(row.icon),
      },
    });
  });
});

// Criar serviço (protegido)
router.post('/', authMiddleware, (req, res) => {
  const { title, description, icon, features, order_position, active } = req.body;

  if (!title || !description) {
    return res.status(400).json({
      success: false,
      message: 'Título e descrição são obrigatórios',
    });
  }

  let parsedFeatures;
  try {
    parsedFeatures = normalizeFeaturesInput(features);
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }

  let sanitizedIcon;
  try {
    sanitizedIcon = sanitizeIconInput(icon);
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: `Ícone inválido: ${error.message}`,
    });
  }

  let orderPositionValue = 0;
  try {
    orderPositionValue = parseOrderPosition(order_position);
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }

  const activeValue = parseActiveFlag(active);

  const query = `
    INSERT INTO services (title, description, icon, features, order_position, active)
    VALUES (?, ?, ?, ?, ?, ?)
  `;

  db.run(
    query,
    [
      title,
      description,
      sanitizedIcon,
      JSON.stringify(parsedFeatures),
      orderPositionValue,
      activeValue,
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
          icon: sanitizedIcon,
          features: parsedFeatures,
          order_position: orderPositionValue,
          active: activeValue,
        },
      });
    },
  );
});

// Atualizar serviço (protegido)
router.put('/:id', authMiddleware, (req, res) => {
  const { title, description, icon, features, order_position, active } = req.body;

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

      let updatedFeatures;
      if (features !== undefined) {
        try {
          updatedFeatures = normalizeFeaturesInput(features);
        } catch (error) {
          return res.status(400).json({
            success: false,
            message: error.message,
          });
        }
      } else {
        try {
          updatedFeatures = parseFeaturesFromDb(service.features, service.id);
        } catch (error) {
          updatedFeatures = [];
        }
      }

      let iconValue = service.icon;
      if (icon !== undefined) {
        try {
          iconValue = sanitizeIconInput(icon);
        } catch (error) {
          return res.status(400).json({
            success: false,
            message: `Ícone inválido: ${error.message}`,
          });
        }
      }

      let orderPositionValue = service.order_position;
      if (order_position !== undefined) {
        try {
          orderPositionValue = parseOrderPosition(order_position);
        } catch (error) {
          return res.status(400).json({
            success: false,
            message: error.message,
          });
        }
      }

      const activeValue =
        active !== undefined ? parseActiveFlag(active) : service.active;

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
          iconValue,
          JSON.stringify(updatedFeatures),
          orderPositionValue,
          activeValue,
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
