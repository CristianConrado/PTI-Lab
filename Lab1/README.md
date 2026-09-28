# Lab1 — Web APIs

## Objective

Build a REST API for a car rental service using Node.js and Express, secured with
JWT-based authentication and role-based authorization (`user` vs `admin`), and
package it as a Docker container.

The app (`myapp`) exposes endpoints to:

- `POST /login` — authenticate with a username/password and receive a JWT.
- `GET /users` — list users (requires a valid token).
- `POST /newUsers` — create a user (requires `admin` role).
- `POST /newrental` — create a rental entry, persisted to `rentals.json` (requires `admin` role).
- `GET /rentals` — list rentals (requires a valid token).

A static frontend (`frontend/index.html`, `list.html`, `new.html`) is served from the same app.

## How to run

### Locally with Node.js

```bash
cd myapp
npm install
node server.js
```

The server listens on `http://localhost:8080`.

### With Docker

```bash
cd myapp
docker build -t myapp .
docker run -p 8080:8080 myapp
```

### Try it out

```bash
# Log in as admin
curl -X POST http://localhost:8080/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Use the returned token to list rentals
curl http://localhost:8080/rentals \
  -H "Authorization: Bearer <token>"
```
