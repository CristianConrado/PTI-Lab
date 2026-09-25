const express = require('express')
const app = express()
const port = 8080
const fs = require('fs');
const filepath = 'rentals.json'

const jwt = require('jsonwebtoken')   //added 
const JWT_SECRET = 'secret-key'    //key to sign the JWT

const path = require('path');
app.use(express.static(path.join(__dirname, 'frontend')));
app.use(express.json());

const USERS = [
  { username: 'alice', password: 'pass123', role: 'user' },
  { username: 'admin', password: 'admin123', role: 'admin' }
]

// Authentication check

function verifyToken(req, res, next) {
  const authHeader = req.headers['authorization']
  const token = authHeader && authHeader.split(' ')[1] // expect: Bearer <token>
  if (!token) return res.status(401).json({ error: 'Missing token' })
  jwt.verify(token, JWT_SECRET, (err, payload) => {
    if (err) return res.status(403).json({ error: 'Invalid or expired token' })
    req.user = payload
    next()
  })
}

function requireAdmin(req, res, next) {
  if (req.user.role !== 'admin')
    return res.status(403).json({ error: 'Admin role required' })
  next()
}

// /login  returns a JWT
app.post('/login', (req, res) => {
  const { username, password } = req.body
  const user = USERS.find(u => u.username === username && u.password === password)
  if (!user) return res.status(401).json({ error: 'Invalid credentials' })
  const token = jwt.sign({ username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '1h' })
  res.json({ token })
})

app.get("/users", verifyToken, (req, res, next) => {
    res.json({ USERS });
});

app.post('/newUsers', verifyToken, requireAdmin, (req, res, next) => {
    console.log(req.body.name);
    USERS.push(req.body)
    res.status(201).end();
}) 



app.post('/newrental', verifyToken, requireAdmin,(req, res, next) => {
    const {engine,co2_rating, days, units, discount} = req.body;
    console.log(req.body);

    let rentalsJSON;

    if (!fs.existsSync(filepath)) {
        //Create an empty JSON document in memory and save it to a file (students.json)
        rentalsJSON = {"rentals":[]};
        fs.writeFileSync(filepath, JSON.stringify(rentalsJSON));
    } else {
    //The file exists, let's read the JSON document into memory
    rentalsFileRawData = fs.readFileSync(filepath);
    rentalsJSON = JSON.parse(rentalsFileRawData);
    }
    //Add something to the (in memory) JSON document (in your endpoint you must replace the constants appropriately)
    rentalsJSON['rentals'].push({"engine": engine, "co2_rating": co2_rating, "days": days, "units": units, "discount": discount});

    //Write the (modified) JSON document into a file
    fs.writeFileSync(filepath, JSON.stringify(rentalsJSON));
    res.status(201);
    res.end();
}) 
app.get('/rentals',verifyToken,  (req, res, next) => {
    if (!fs.existsSync(filepath)) {
        //Create an empty JSON document in memory and save it to a file (students.json)
        rentalsJSON = {"rentals":[]};
        fs.writeFileSync(filepath, JSON.stringify(rentalsJSON));
    } else {
    //The file exists, let's read the JSON document into memory
    rentalsFileRawData = fs.readFileSync(filepath);
    rentalsJSON = JSON.parse(rentalsFileRawData);
    }
    res.json(rentalsJSON);
    res.end();
}) 
app.listen(port, () => {
  console.log(`PTI HTTP Server listening at http://localhost:${port}`)
})

