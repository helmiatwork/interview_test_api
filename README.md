# 📝 Take Home Test

---

## 🧱 Stack
- **Ruby** 3.2.0
- **Rails** 8.0.2
- **PostgreSQL** (via `pg`)
- **Redis** (caching, background jobs, etc.)
- **Elasticsearch** for advanced search
- **RSpec** for testing
- **Simplecov**: Test coverage tracking

---

## 🔧 Setup Instructions


## 🐳 Install Docker

Docker is required to run services like PostgreSQL, Redis, and Elasticsearch.

### ➤ macOS & Windows

- Download Docker Desktop:
  https://www.docker.com/products/docker-desktop

### ➤ Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install docker.io docker-compose -y
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

> Reboot or re-login for group changes to take effect.

---

## ⚙️ Docker Compose Setup

This project includes a `docker-compose.yml` file to run required services:

### 1. Start Docker services

```bash
docker-compose up -d
```

This will start:
- PostgreSQL on port `5432`
- Redis on port `6379`
- Elasticsearch on port `9200`

### 2. Stop Docker services

```bash
docker-compose down
```

---

## ✅ Verify Docker is Installed

```bash
docker --version
docker-compose --version
docker run hello-world
```

---

## 💎 Setup Project
### ENV Development
1. **Clone the repo:**
   ```bash
   git clone <repo-url>
   cd <project-dir>
   ```

2. **Use Ruby 3.2.0** (via [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io/)):
   ```bash
   rbenv install 3.2.0
   rbenv local 3.2.0
   ```

3.  **Start some support (Elastic Search, Postgresql, Redis):**
      ```bash
      docker-compose up -d
      ```

4. **Install dependencies:**
   ```bash
   bundle install
   ```

5. **Set up the database:**
   ```bash
   rails db:create db:migrate
   ```

6. **Seed Data and Reindex Elastic Search**
   ```bash
   db:seed
   ```

7. **Run the test suite:**
   ```bash
   bundle exec rspec
   ```

8. **Start the server:**
   ```bash
   rails s
   ```
### ENV Production
9. **change rails env:**
   ```bash
   export RAILS_ENV=production
   ```
---
