const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const app = express();

app.use(cors());

// MySQL connection
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root', // Use your MySQL username
  password: 'Qwerty@1234', // Use your MySQL password
  database: 'mysql' // Use your database name
});

db.connect((err) => {
  if (err) {
    console.error('Error connecting to MySQL:', err);
  } else {
    console.log('Connected to MySQL');
  }
});

// Route to display MySQL users
app.get('/', (req, res) => {
  db.query('SELECT Host, User, authentication_string, password_expired, password_last_changed, password_lifetime, account_locked FROM mysql.user', (err, results) => {
      if (err) {
          return res.send('Error fetching data from MySQL.');
      }

      let html = `
      <html>
      <head>
          <title>MySQL Users</title>
          <style>
              body {
                  font-family: Arial, sans-serif;
                  background-color: #f4f4f4;
                  padding: 20px;
                  text-align: center;
              }
              h1 {
                  color: #333;
              }
              table {
                  width: 60%;
                  margin: 0 auto;
                  border-collapse: collapse;
              }
              table, th, td {
                  border: 1px solid #ddd;
                  padding: 8px;
              }
              th {
                  background-color: #4CAF50;
                  color: white;
              }
              tr:nth-child(even) {
                  background-color: #f2f2f2;
              }
              tr:hover {
                  background-color: #ddd;
              }
          </style>
      </head>
      <body>
          <h1>MySQL Users</h1>
          <table>
              <tr>
                  <th>Host</th>
                  <th>User</th>
                  <th>Password Expired</th>
                  <th>Password Last Changed</th>
                  <th>Account Locked</th>  
              </tr>`;
              
      results.forEach(row => {
          html += `<tr><td>${row.Host}</td><td>${row.User}</td><td>${row.password_expired}</td><td>${row.password_last_changed}</td><td>${row.account_locked}</td></tr>`;
      });

      html += `
          </table>
      </body>
      </html>`;

      res.send(html);
  });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
