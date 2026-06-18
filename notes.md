# 🚀 GitHub Actions — CI/CD Pipeline Complete Notes

> **Chai aur Code Style** | Hinglish | Node.js + Docker + VPS Deploy

---

## 🤔 Problem Statement — Manual Deployment ka Dard

Typical deployment flow without CI/CD:

```
Developer          GitHub           VPS Server
    │                │                   │
    │── git push ───►│                   │
    │                │                   │
    │                │     SSH karo      │
    │────────────────────────────────────►│
    │                │     git pull      │
    │────────────────────────────────────►│
    │                │  docker compose   │
    │────────────────────────────────────►│
    │                │      up -d        │
```

**Problem:** Har baar code push karne pe yeh saare steps manually repeat karne padte hain!

```
Har push ke baad:
  1. Server pe SSH karo
  2. git pull karo
  3. docker compose up --build -d karo
  → BAR BAR, MANUAL, BORING, ERROR-PRONE 😤
```

---

## ✅ Solution — GitHub Actions (CI/CD)

> **CI/CD = Continuous Integration / Continuous Deployment**

Ek YAML file likho jisme steps define karo → GitHub khud apne servers pe yeh steps run kar dega jab bhi tum push karo.

```
Developer          GitHub           GitHub Runner      VPS Server
    │                │                   │                  │
    │── git push ───►│                   │                  │
    │                │── Trigger ────────►│                  │
    │                │   Action          │── SSH ──────────►│
    │                │                   │── git pull ─────►│
    │                │                   │── docker up ────►│
    │                │                   │                  │
    │                │◄── Done ──────────│                  │
```

**Tumhara kaam sirf:** Code likho + `git push` karo. Baaki sab GitHub handle karega!

---

## 🏗️ Complete Project Structure

```
my-node-app/
├── index.js              ← Express app
├── package.json
├── Dockerfile            ← Docker image instructions
├── docker-compose.yaml   ← Container orchestration
├── .gitignore
└── .github/
    └── workflows/
        └── deploy.yaml   ← GitHub Actions CI/CD pipeline ⭐
```

---

## 1️⃣ Node.js App — Express Setup

```js
// index.js
import express from 'express';

const app = express();
const PORT = process.env.PORT || 8080;

app.get('/', (req, res) => {
  return res.json({ message: 'Hello from the server V1' });
});

app.listen(PORT, () => {
  console.log(`Server is up and running on port ${PORT}`);
});
```

```json
// package.json (relevant parts)
{
  "type": "module",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.x.x"
  },
  "devDependencies": {
    "@types/express": "^4.x.x"
  }
}
```

---

## 2️⃣ Dockerfile — App ko Dockerize Karo

```dockerfile
# Dockerfile
FROM node:22-alpine        ← Alpine = lightweight image

WORKDIR /app

# Layer caching: pehle package files copy karo
COPY package*.json ./
RUN npm install

# Baaki saari files copy karo
COPY . .

EXPOSE 8080

CMD ["node", "index.js"]
```

> 💡 **Layer Caching Trick:** `package.json` alag copy karte hain taaki `npm install` sirf tab re-run ho jab dependencies change ho — code changes pe skip hoga. Build fast hota hai!

**Test karo locally:**
```bash
docker build -t api .
docker run --rm -it -p 8080:8080 api
curl http://localhost:8080   # → {"message":"Hello from the server V1"}
```

---

## 3️⃣ Docker Compose — Production ke liye

```yaml
# docker-compose.yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: api
    restart: unless-stopped      ← Crash pe auto-restart!
    ports:
      - "8080:8080"             ← host:container port mapping
```

**Run karo:**
```bash
docker compose up -d            # detached mode (background)
curl http://localhost:8080      # test
docker compose down             # band karo
```

---

## 4️⃣ VPS Server Setup (One Time)

### Step 1: Docker Install karo Server pe

```bash
# Server pe SSH karo (ya browser terminal use karo)
sudo apt-get update
sudo apt-get upgrade -y

# Docker install (official docs se commands copy karo)
# https://docs.docker.com/engine/install/ubuntu/
```

```bash
# Verify
docker --version   # → Docker version XX.X
```

### Step 2: Code Clone karo

```bash
cd /root
git clone https://github.com/your-username/your-repo.git
cd your-repo

# Manually test karo pehle
docker compose up -d
curl http://YOUR_SERVER_IP:8080   # → Hello from server
```

---

## 5️⃣ GitHub Actions — CI/CD Pipeline ⭐

### Folder Structure (MUST follow exactly)

```
.github/
└── workflows/
    └── deploy.yaml     ← Yeh exact naam/structure chahiye
```

> ⚠️ Folder ka naam `.github` hona CHAHIYE — kuch aur nahi chalega!

---

### deploy.yaml — Complete File

```yaml
name: Deploy Node.js Application to Hostinger

on:
  push:
    branches:
      - main              # Sirf main branch push pe trigger ho

jobs:
  deployer:
    runs-on: ubuntu-latest    # GitHub ka runner server

    steps:
      # Step 1: Code checkout karo (GitHub ka built-in action)
      - name: Checkout Code
        uses: actions/checkout@v4

      # Step 2: SSH karke server pe deploy karo
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.SSH_HOST }}         # Server IP
          username: root                          # SSH username
          key: ${{ secrets.SSH_KEY }}            # Private SSH key
          script: |
            cd /root/nodejs-app-deploy-gh-actions
            git pull
            docker compose up -d --build
```

---

### YAML File ka Plain English Matlab

```
1. "deploy.yaml" naam ki workflow hai
2. Main branch pe koi bhi push aaye toh trigger ho
3. GitHub ke Ubuntu server pe ek job chalao: "deployer"
4. Steps:
   a. Code checkout karo (apna latest code GitHub runner pe lao)
   b. Mere VPS server pe SSH karo
   c. Project folder mein jao (cd)
   d. Latest code pull karo (git pull)
   e. Docker rebuild karo aur start karo (docker compose up -d --build)
```

---

## 🔐 GitHub Secrets — Sensitive Data Handle Karo

**GitHub Secrets kya hote hain?**
Sensitive values (IP, SSH keys, passwords) jo tum YAML mein hard-code nahi karna chahte. GitHub inhe securely store karta hai.

### Secrets kaise add karo:

```
GitHub Repo → Settings → Secrets and Variables → Actions → New Repository Secret
```

| Secret Name | Value | Kahan se milega |
|------------|-------|----------------|
| `SSH_HOST` | `157.xxx.xxx.xxx` | VPS Dashboard se IP |
| `SSH_KEY` | Private key content | `ssh-keygen` se generate |

### YAML mein use karna:
```yaml
host: ${{ secrets.SSH_HOST }}
key:  ${{ secrets.SSH_KEY }}
```

---

## 🔑 SSH Key Setup — One Time Process

**Concept:**

```
Public Key  → Server pe daalo (authorized_keys mein)
Private Key → GitHub Secrets mein daalo (SSH_KEY)

GitHub Runner → Private Key use karke → Server authenticate karta hai
```

### Step 1: Key Generate karo (local machine pe)

```bash
ssh-keygen -t rsa -b 4096 -C "hostinger@yourname.dev"
# Jab path puche: /path/to/private  (custom path do)
# Passphrase: Enter (khaali rakho)

# Result:
# /path/to/private      ← PRIVATE key
# /path/to/private.pub  ← PUBLIC key
```

### Step 2: Public Key → Server mein daalo

```bash
# Server pe (SSH terminal mein):
ls -a                    # .ssh folder dekho
cd .ssh
cat authorized_keys      # existing keys

# Public key ka content copy karo
# aur authorized_keys mein paste karo:
nano authorized_keys
# paste karke Ctrl+O save, Ctrl+X exit
```

> ⚠️ **Dhyan rakho:** PUBLIC key (.pub wali) server mein jaati hai. PRIVATE key GitHub Secrets mein jaati hai. Kabhi bhi ulta mat karna!

### Step 3: Private Key → GitHub Secrets mein daalo

```
GitHub → Settings → Secrets → New Secret
Name: SSH_KEY
Value: [private key file ka poora content paste karo — BEGIN RSA PRIVATE KEY se END tak]
```

### Step 4: Keys Delete karo local machine se

```bash
# Commit mat karo inhe kabhi!
rm /path/to/private
rm /path/to/private.pub
# Ya .gitignore mein add karo
```

---

## ▶️ Full Flow — Ek Baar Dekho

```
1. Developer: code mein change karo
        ↓
2. git add . && git commit -m "changes" && git push
        ↓
3. GitHub: Push detect kiya → deploy.yaml trigger hua
        ↓
4. GitHub Runner (ubuntu-latest):
   - Code checkout kiya
   - SSH_HOST aur SSH_KEY secrets padhe
   - VPS server pe SSH kiya
        ↓
5. VPS Server pe automatically:
   - cd /root/project-folder
   - git pull  (latest code aaya)
   - docker compose up -d --build  (rebuild + restart)
        ↓
6. User ko latest code mil gaya! 🎉
```

---

## 📊 Manual vs CI/CD — Comparison

| Cheez | Manual Deploy | GitHub Actions |
|-------|--------------|----------------|
| Har push ke baad | Server pe manually SSH karo | Automatic 🤖 |
| Git pull | Manually karo | Automatic |
| Docker rebuild | Manually karo | Automatic |
| Human error chance | High | Near zero |
| Time lagta hai | 5-10 minutes | 0 (background) |
| Scalability | Painful | Easy |

---

## 🎯 Interview Prep — Key Points

> **Q: CI/CD kya hota hai?**
> CI = Continuous Integration (code merge pe automatic test/build). CD = Continuous Deployment (automatic production deploy). GitHub Actions dono automate karta hai.

> **Q: GitHub Actions mein `runs-on` kya hota hai?**
> Woh machine/OS specify karta hai jis pe GitHub Action run karta hai. `ubuntu-latest` = GitHub ka Ubuntu server. Tum `windows-latest`, `macos-latest` bhi use kar sakte ho.

> **Q: `uses` vs `run` mein kya fark hai YAML mein?**
> `uses` = kisi aur ki pre-built action use karo (jaise `actions/checkout@v4`). `run` = direct shell command likho.

> **Q: GitHub Secrets kyun use karte hain?**
> IP address, SSH keys, passwords YAML mein hard-code karna dangerous hai — public repo mein expose ho jaata hai. Secrets encrypted store hote hain aur `${{ secrets.NAME }}` se access hote hain.

> **Q: `on: push: branches: [main]` ka matlab?**
> Sirf `main` branch pe push hone pe trigger ho. Feature branches pe push karne pe action run nahi hoga.

> **Q: Docker Compose mein `restart: unless-stopped` kyun?**
> Server reboot pe ya crash pe container automatically restart ho — manually start nahi karna padega.

> **Q: SSH key pair mein public aur private key kahan jaati hai?**
> Public key → Server ke `~/.ssh/authorized_keys` mein. Private key → GitHub Secrets mein (`SSH_KEY`). GitHub Action private key use karke server pe authenticate karta hai.

---

## 📌 Summary — Ek Nazar Mein

```
GitHub Actions CI/CD Pipeline
├── Trigger: main branch pe push
├── Runner: GitHub ka ubuntu server
└── Steps:
    ├── 1. Code Checkout (actions/checkout@v4)
    └── 2. SSH Deploy (appleboy/ssh-action)
                ├── host  = ${{ secrets.SSH_HOST }}
                ├── user  = root
                ├── key   = ${{ secrets.SSH_KEY }}
                └── script:
                        cd /project
                        git pull
                        docker compose up -d --build

Secrets (GitHub → Settings → Secrets):
├── SSH_HOST  → VPS ka IP address
└── SSH_KEY   → Private SSH key content

SSH Keys:
├── Public Key  → VPS ~/.ssh/authorized_keys
└── Private Key → GitHub Secret (SSH_KEY)
```

---

## ⚠️ Common Gotchas

```
❌ .github folder ka naam galat karna  → .github hona chahiye (dot ke saath)
❌ workflows folder miss karna         → .github/workflows/ exact path
❌ Public/Private key ulti karna       → Public = server, Private = GitHub
❌ Keys ko git commit karna            → KABHI MAT KARO! .gitignore mein daalo
❌ SSH_KEY mein sirf file name dena    → Poora key content paste karo
❌ docker compose up ke baad --build   → Bina --build ke purana image use hoga
```

---

*Notes by: Chai aur Code Series — GitHub Actions CI/CD*
*Stack: Node.js + Express + Docker + GitHub Actions + VPS*