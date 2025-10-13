const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');

// Login
router.post('/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Email e senha são obrigatórios',
    });
  }

  db.get('SELECT * FROM users WHERE email = ?', [email], (err, user) => {
    if (err) {
      return res.status(500).json({
        success: false,
        message: 'Erro ao buscar usuário',
      });
    }

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Credenciais inválidas',
      });
    }

    // Verificar senha
    bcrypt.compare(password, user.password, (err, isMatch) => {
      if (err || !isMatch) {
        return res.status(401).json({
          success: false,
          message: 'Credenciais inválidas',
        });
      }

      // Gerar token JWT
      const token = jwt.sign(
        {
          id: user.id,
          email: user.email,
          role: user.role,
        },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN },
      );

      res.json({
        success: true,
        message: 'Login realizado com sucesso',
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
        },
      });
    });
  });
});

// Alterar senha
router.post('/change-password', (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Token não fornecido',
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Senhas são obrigatórias',
      });
    }

    db.get('SELECT * FROM users WHERE id = ?', [decoded.id], (err, user) => {
      if (err || !user) {
        return res.status(404).json({
          success: false,
          message: 'Usuário não encontrado',
        });
      }

      bcrypt.compare(currentPassword, user.password, (err, isMatch) => {
        if (err || !isMatch) {
          return res.status(401).json({
            success: false,
            message: 'Senha atual incorreta',
          });
        }

        bcrypt.hash(newPassword, 10, (err, hash) => {
          if (err) {
            return res.status(500).json({
              success: false,
              message: 'Erro ao alterar senha',
            });
          }

          db.run(
            'UPDATE users SET password = ? WHERE id = ?',
            [hash, decoded.id],
            err => {
              if (err) {
                return res.status(500).json({
                  success: false,
                  message: 'Erro ao alterar senha',
                });
              }

              res.json({
                success: true,
                message: 'Senha alterada com sucesso',
              });
            },
          );
        });
      });
    });
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Token inválido',
    });
  }
});

module.exports = router;
