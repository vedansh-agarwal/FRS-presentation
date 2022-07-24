const mysql = require("mysql2");

const db = mysql.createConnection({
  user: "root",
  host: "localhost",
  password: "password" /* "password" "sudu_1000" */,
  database: "FRS-test",
});

module.exports = db;
