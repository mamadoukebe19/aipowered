# 🚀 CI/CD Pipeline Demo — GitHub → Amazon EC2

> **Webinar Demo** — How to use AI tools to build a CI/CD pipeline that automatically deploys your code from GitHub to an Amazon EC2 Ubuntu instance using GitHub Actions.

---

## 📁 Project Structure

```
.
├── index.html                    # The web app (HTML)
├── style.css                     # Styling (CSS)
├── apache.conf                   # Apache virtual host config (reference)
├── scripts/
│   └── ec2-setup.sh              # One-time EC2 server setup script
├── .github/
│   └── workflows/
│       └── deploy.yml            # GitHub Actions CI/CD pipeline
└── README.md                     # This file
```

---

## 🏗️ Architecture Overview

```
Developer Machine          GitHub                    Amazon EC2 (Ubuntu)
──────────────────         ──────────────────        ──────────────────────
  git push origin main ──► triggers workflow ──────► SSH in, git pull
                           (GitHub Actions)           Apache serves the app
                                                              │
                                                              ▼
                                                     http://YOUR_EC2_IP
```

**Flow:**
1. You push code to the `main` branch
2. GitHub Actions automatically detects the push
3. A runner SSHs into your EC2 instance using a stored private key
4. It runs `git pull` inside `/var/www/html` (Apache's web root)
5. Apache serves the updated site immediately

---

## ✅ Prerequisites

| Tool | Where |
|------|-------|
| GitHub account | github.com |
| AWS account | aws.amazon.com |
| EC2 instance (Ubuntu 22.04 LTS) | AWS Console → EC2 |
| EC2 key pair (.pem file) | Downloaded when creating EC2 |
| Git installed locally | git-scm.com |

---

## 🖥️ Part 1 — Set Up the EC2 Instance

### 1.1 Launch an EC2 Instance

In the AWS Console:

1. Go to **EC2 → Launch Instance**
2. Choose **Ubuntu Server 22.04 LTS** (Free Tier eligible)
3. Instance type: `t2.micro` (free tier)
4. Create or select a **Key Pair** — download the `.pem` file
5. Under **Security Group**, allow inbound:
   - Port **22** (SSH) — from your IP (for setup)
   - Port **80** (HTTP) — from anywhere (`0.0.0.0/0`)
6. Click **Launch Instance**

### 1.2 Connect to Your EC2 Instance

```bash
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

### 1.3 Run the Setup Script

Upload or paste the contents of `scripts/ec2-setup.sh` on the EC2 instance, then run it:

```bash
bash ec2-setup.sh
```

The script will:
- Update system packages
- Remove Nginx if present
- Install Git and **Apache2**
- Clone your repository directly into `/var/www/html` (Apache's default web root)
- Enable `mod_rewrite` and start Apache
- Enable Apache on boot

After it finishes, open `http://YOUR_EC2_IP` — you should see your app, not the Apache default page.

---

## 🔑 Part 2 — Configure GitHub Secrets

GitHub Actions needs credentials to SSH into your EC2 instance. These are stored as **encrypted secrets** in your repository — never in the code.

### 2.1 Add Secrets to GitHub

Go to your repo on GitHub:  
**Settings → Secrets and variables → Actions → New repository secret**

Add these three secrets:

| Secret Name | Value |
|---|---|
| `EC2_SSH_PRIVATE_KEY` | Full contents of your `.pem` file (including `-----BEGIN...-----` lines) |
| `EC2_HOST` | Your EC2 public IP address (e.g. `54.123.45.67`) |
| `EC2_USER` | `ubuntu` (default user for Ubuntu AMIs) |

### 2.2 How to Copy Your .pem Key Content

```bash
# On your local machine
cat your-key.pem
```

Copy the entire output and paste it as the value for `EC2_SSH_PRIVATE_KEY`.

---

## ⚙️ Part 3 — The GitHub Actions Pipeline

The workflow file lives at `.github/workflows/deploy.yml`.

```yaml
name: Deploy to EC2

on:
  push:
    branches:
      - main       # ← fires on every push to main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Deploy to EC2 via SSH
        env:
          PRIVATE_KEY: ${{ secrets.EC2_SSH_PRIVATE_KEY }}
          HOST: ${{ secrets.EC2_HOST }}
          USER: ${{ secrets.EC2_USER }}
        run: |
          echo "$PRIVATE_KEY" > private_key.pem
          chmod 600 private_key.pem
          ssh -o StrictHostKeyChecking=no -i private_key.pem ${USER}@${HOST} << 'EOF'
            cd /var/www/html
            git pull origin main
            sudo systemctl restart apache2
            echo "✅ Deployment successful!"
          EOF

      - name: Cleanup
        if: always()
        run: rm -f private_key.pem
```

**Key points:**
- `on: push: branches: [main]` — only triggers on `main` pushes
- Apache serves from `/var/www/html` — that's where we `git pull`
- `sudo systemctl restart apache2` — ensures Apache picks up changes
- `if: always()` on cleanup — the `.pem` is deleted even if deploy fails

---

## 🌐 Part 4 — Apache Configuration

Apache2 on Ubuntu already serves `/var/www/html` by default — no custom config needed for a static HTML/CSS app. The `apache.conf` file in this repo is provided as a reference for future customization.

The key difference from Nginx: **Apache's default site already points to `/var/www/html`**, so cloning your repo there is all that's needed.

To verify Apache is running on your EC2:

```bash
sudo systemctl status apache2
```

---

## 🎬 Part 5 — Trigger Your First Deployment

With everything configured, a single git push deploys your app:

```bash
git add .
git commit -m "initial deploy"
git push origin main
```

Then watch the magic:

1. Go to your repo on GitHub
2. Click the **Actions** tab
3. You'll see the **"Deploy to EC2"** workflow running
4. Green checkmark = deployed ✅
5. Open `http://YOUR_EC2_IP` in your browser — your app is live

---

## 🔄 Part 6 — Making a Change (Live Demo Moment)

This is the best part to show in a webinar. Edit a line, push, and the live site updates automatically:

```bash
# Edit any text in index.html, then:
git add index.html
git commit -m "update hero text"
git push origin main
```

Switch to the **Actions** tab on GitHub and watch the pipeline run. Refresh the browser — your change is live.

---

## 🔒 Security Notes

- **Never commit your `.pem` file** — it is already in `.gitignore`
- GitHub Secrets are encrypted and never shown in logs
- In production, restrict SSH access (port 22) to specific IPs only
- Add `HTTPS` with Let's Encrypt (`certbot`) for production sites:

```bash
sudo apt install -y certbot python3-certbot-apache
sudo certbot --apache -d yourdomain.com
```

---

## 🛠️ Troubleshooting

| Problem | Fix |
|---|---|
| Still see Apache default page after setup | The setup script removes `/var/www/html` and clones fresh — re-run it |
| `Permission denied (publickey)` | Check `EC2_SSH_PRIVATE_KEY` has the exact `.pem` content |
| Site doesn't update after push | SSH in and run `cd /var/www/html && git pull` manually to see errors |
| Apache not running | Run `sudo systemctl start apache2` on EC2 |
| Can't reach port 80 | Check EC2 Security Group inbound rules — HTTP (port 80) must allow `0.0.0.0/0` |
| `git pull` fails on EC2 | The repo may be owned by root — run `sudo chown -R ubuntu:ubuntu /var/www/html` |

---

## 📚 Further Reading

- [GitHub Actions documentation](https://docs.github.com/en/actions)
- [Amazon EC2 User Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/)
- [Apache2 on Ubuntu](https://ubuntu.com/tutorials/install-and-configure-apache)
- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Let's Encrypt with Apache](https://certbot.eff.org/instructions?serveros=ubuntufocal&webserver=apache)

---

*Built for the AI-Powered DevOps Webinar — demonstrating how AI tools can scaffold a complete CI/CD pipeline from scratch.*
