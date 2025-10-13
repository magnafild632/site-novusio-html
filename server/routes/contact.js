const express = require('express');
const router = express.Router();
const db = require('../config/database');
const authMiddleware = require('../middleware/auth');

// Enviar mensagem de contato (público)
router.post('/', (req, res) => {
  const { name, email, phone, company, message } = req.body;

  if (!name || !email || !message) {
    return res.status(400).json({
      success: false,
      message: 'Nome, email e mensagem são obrigatórios',
    });
  }

  const query = `
    INSERT INTO contact_messages (name, email, phone, company, message)
    VALUES (?, ?, ?, ?, ?)
  `;

  db.run(
    query,
    [name, email, phone || '', company || '', message],
    function (err) {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Erro ao enviar mensagem',
        });
      }

      res.status(201).json({
        success: true,
        message:
          'Mensagem enviada com sucesso! Entraremos em contato em breve.',
        data: {
          id: this.lastID,
        },
      });
    },
  );
});

// Listar todas as mensagens (protegido)
router.get('/', authMiddleware, (req, res) => {
  const query = 'SELECT * FROM contact_messages ORDER BY created_at DESC';

  db.all(query, [], (err, rows) => {
    if (err) {
      return res.status(500).json({
        success: false,
        message: 'Erro ao buscar mensagens',
      });
    }

    res.json({
      success: true,
      data: rows,
    });
  });
});

// Buscar mensagem por ID (protegido)
router.get('/:id', authMiddleware, (req, res) => {
  db.get(
    'SELECT * FROM contact_messages WHERE id = ?',
    [req.params.id],
    (err, row) => {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Erro ao buscar mensagem',
        });
      }

      if (!row) {
        return res.status(404).json({
          success: false,
          message: 'Mensagem não encontrada',
        });
      }

      res.json({
        success: true,
        data: row,
      });
    },
  );
});

// Marcar mensagem como lida (protegido)
router.patch('/:id/read', authMiddleware, (req, res) => {
  db.run(
    'UPDATE contact_messages SET read_status = 1 WHERE id = ?',
    [req.params.id],
    function (err) {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Erro ao atualizar mensagem',
        });
      }

      if (this.changes === 0) {
        return res.status(404).json({
          success: false,
          message: 'Mensagem não encontrada',
        });
      }

      res.json({
        success: true,
        message: 'Mensagem marcada como lida',
      });
    },
  );
});

// Deletar mensagem (protegido)
router.delete('/:id', authMiddleware, (req, res) => {
  db.run(
    'DELETE FROM contact_messages WHERE id = ?',
    [req.params.id],
    function (err) {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Erro ao deletar mensagem',
        });
      }

      if (this.changes === 0) {
        return res.status(404).json({
          success: false,
          message: 'Mensagem não encontrada',
        });
      }

      res.json({
        success: true,
        message: 'Mensagem deletada com sucesso',
      });
    },
  );
});

// Contar mensagens não lidas (protegido)
router.get('/stats/unread', authMiddleware, (req, res) => {
  db.get(
    'SELECT COUNT(*) as count FROM contact_messages WHERE read_status = 0',
    [],
    (err, row) => {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Erro ao contar mensagens',
        });
      }

      res.json({
        success: true,
        data: {
          unread_count: row.count,
        },
      });
    },
  );
});

module.exports = router;
