const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Статические файлы отключены - их раздаёт Nginx
// app.use(express.static(path.join(__dirname)));

// Инициализация SQLite БД
const db = new sqlite3.Database('./courier_applications.db', (err) => {
  if (err) {
    console.error('Ошибка при подключении к БД:', err.message);
  } else {
    console.log('✅ Подключение к SQLite успешно');
    initializeDatabase();
  }
});

// Создание таблицы если её нет
function initializeDatabase() {
  db.run(`
    CREATE TABLE IF NOT EXISTS courier_applications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT NOT NULL,
      citizenship TEXT NOT NULL,
      messenger TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      submitted_at TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `, (err) => {
    if (err) {
      console.error('Ошибка при создании таблицы:', err.message);
    } else {
      console.log('✅ Таблица готова');
    }
  });
}

// API endpoint для сохранения заявки
app.post('/api/courier-application', (req, res) => {
  const { name, phone, citizenship, messenger, timestamp, submittedAt } = req.body;

  // Валидация
  if (!name || !phone || !citizenship || !messenger) {
    return res.status(400).json({ 
      success: false, 
      message: 'Заполните все обязательные поля' 
    });
  }

  // Сохранение в БД
  db.run(
    `INSERT INTO courier_applications (name, phone, citizenship, messenger, timestamp, submitted_at) 
     VALUES (?, ?, ?, ?, ?, ?)`,
    [name, phone, citizenship, messenger, timestamp, submittedAt],
    function(err) {
      if (err) {
        console.error('Ошибка при сохранении:', err.message);
        return res.status(500).json({ 
          success: false, 
          message: 'Ошибка при сохранении заявки' 
        });
      }

      console.log(`✅ Заявка сохранена (ID: ${this.lastID}, Имя: ${name}, Телефон: ${phone})`);
      res.json({ 
        success: true, 
        message: 'Заявка успешно сохранена',
        id: this.lastID 
      });
    }
  );
});

// API endpoint для получения всех заявок (для администратора)
app.get('/api/applications', (req, res) => {
  db.all(
    `SELECT * FROM courier_applications ORDER BY created_at DESC`,
    (err, rows) => {
      if (err) {
        return res.status(500).json({ 
          success: false, 
          message: 'Ошибка при получении данных' 
        });
      }
      res.json({ 
        success: true, 
        count: rows.length,
        applications: rows 
      });
    }
  );
});

// API endpoint для получения одной заявки
app.get('/api/applications/:id', (req, res) => {
  const { id } = req.params;
  
  db.get(
    `SELECT * FROM courier_applications WHERE id = ?`,
    [id],
    (err, row) => {
      if (err) {
        return res.status(500).json({ 
          success: false, 
          message: 'Ошибка при получении данных' 
        });
      }
      if (!row) {
        return res.status(404).json({ 
          success: false, 
          message: 'Заявка не найдена' 
        });
      }
      res.json({ 
        success: true, 
        application: row 
      });
    }
  );
});

// Главная страница отключена - её раздаёт Nginx
// app.get('/', (req, res) => {
//   res.sendFile(path.join(__dirname, 'index.html'));
// });

// Запуск сервера только на localhost (безопасность!)
app.listen(PORT, '127.0.0.1', () => {
  console.log(`\n╔════════════════════════════════════════╗`);
  console.log(`║  🚀 Сервер запущен успешно!           ║`);
  console.log(`║  URL: http://127.0.0.1:${PORT}         ║`);
  console.log(`║  БД: courier_applications.db          ║`);
  console.log(`╚════════════════════════════════════════╝\n`);
});

// Обработка ошибок
process.on('SIGINT', () => {
  console.log('\n\n📊 Закрытие БД...');
  db.close((err) => {
    if (err) {
      console.error(err.message);
    }
    console.log('✅ БД закрыта');
    process.exit(0);
  });
});