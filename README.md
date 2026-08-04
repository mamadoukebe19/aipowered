# 🚀 CI/CD Pipeline Demo — GitHub → Amazon EC2

> **Webinar Demo** — How to use AI tools to build a CI/CD pipeline that automatically deploys your code from GitHub to an Amazon EC2 Ubuntu instance using GitHub Actions.

---

## 📁 Project Structure

```
.
├── index.html                    # The web app (HTML)
├── style.css                     # Styling (CSS)
├── nginx.conf                    # Nginx server configuration
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
                           (GitHub Actions)           Nginx serves the app
                                                              │
                                                              ▼
                                                     http://YOUR_EC2_IP
```

**Flow:**
1. You push code to the `main` branch
2. GitHub Actions automatically detects the push
3. A runner SSHs into your EC2 instance using a stored private key
4. It runs `git pull` to fetch the latest files
5. Nginx serves the updated site immediately

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

Once connected, run the one-time setup script.  
First, edit `scripts/ec2-setup.sh` and replace `YOUR_USERNAME/YOUR_REPO` with your actual GitHub repo URL, then:

```bash
# On your EC2 instance
bash <(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/scripts/ec2-setup.sh)
```

Or copy-paste the script content directly. The script will:
- Update system packages
- Install Git and Nginx
- Clone your repository to `/var/www/demo-app`
- Configure Nginx to serve your app
- Enable Nginx on boot

---

## 🔑 Part 2 — Configure GitHub Secrets

GitHub Actions needs credentials to SSH into your EC2 instance. These are stored as **encrypted secrets** in your repository — never in the code.

### 2.1 Add Secrets to GitHub

Go to your repo on GitHub:  
**Settings → Secrets and variables → Actions → New repository secret**

Add these three secrets:

| Secret Name | Value |
|---|---|
| `EC2_SSH_PRIVATE_KEY` | Contents of your `.pem` file (the entire file, including `-----BEGIN...-----`) |
| `EC2_HOST` | Your EC2 public IP address (e.g. `54.123.45.67`) |
| `EC2_USER` | `ubuntu` (default user for Ubuntu AMIs) |

### 2.2 How to Copy Your .pem Key Content

```bash
# On your local machine
cat your-key.pem
```

Copy the entire output — from `-----BEGIN RSA PRIVATE KEY-----` to `-----END RSA PRIVATE KEY-----` — and paste it as the value for `EC2_SSH_PRIVATE_KEY`.

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
            cd /var/www/demo-app
            git pull origin main
            sudo systemctl reload nginx
            echo "✅ Deployment successful!"
          EOF

      - name: Cleanup
        if: always()
        run: rm -f private_key.pem
```

**Key points:**
- `on: push: branches: [main]` — only triggers on `main` pushes
- `actions/checkout@v4` — checks out repo code on the runner
- Secrets are injected as environment variables — never visible in logs
- `StrictHostKeyChecking=no` — avoids interactive host verification on first connect
- `if: always()` on cleanup — the `.pem` file is deleted even if the deploy fails

---

## 🌐 Part 4 — Nginx Configuration

The `nginx.conf` file tells Nginx where to find your files and how to serve them.

```nginx
server {
    listen 80;
    server_name YOUR_EC2_PUBLIC_IP;

    root /var/www/demo-app;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

To apply it on EC2:

```bash
sudo cp nginx.conf /etc/nginx/sites-available/demo-app
sudo ln -s /etc/nginx/sites-available/demo-app /etc/nginx/sites-enabled/demo-app
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t       # test the config
sudo systemctl reload nginx
```

---

## 🎬 Part 5 — Trigger Your First Deployment

With everything configured, a single git push deploys your app:

```bash
# On your local machine
git add .
git commit -m "initial deploy"
git push origin main
```

Then watch the magic:

1. Go to your repo on GitHub
2. Click the **Actions** tab
3. You'll see the **"Deploy to EC2"** workflow running
4. Green checkmark = deployed ✅
5. Open `http://YOUR_EC2_IP` in your browser

---

## 🔄 Part 6 — Making a Change (Live Demo Moment)

This is the best part to show in a webinar. Edit a line, push, and the live site updates automatically:

```bash
# Edit the page title or any text in index.html
# Then:
git add index.html
git commit -m "update hero text"
git push origin main
```

Switch to the **Actions** tab on GitHub and watch the pipeline run. Refresh the browser — your change is live.

---

## 🔒 Security Notes

- **Never commit your `.pem` file** — add it to `.gitignore`
- GitHub Secrets are encrypted and never shown in logs
- In production, restrict SSH access (port 22) to specific IPs
- Consider using **IAM roles** instead of key-based auth for advanced setups
- Add `HTTPS` with Let's Encrypt (`certbot`) for production sites

---

## 🛠️ Troubleshooting

| Problem | Fix |
|---|---|
| `Permission denied (publickey)` | Check that `EC2_SSH_PRIVATE_KEY` secret has the exact content of the `.pem` file |
| Workflow runs but site doesn't update | SSH into EC2 and run `git pull` manually to check for errors |
| `nginx: configuration file test failed` | Run `sudo nginx -t` on EC2 to see the exact error |
| Site shows "Welcome to nginx" | The default site is still enabled — run `sudo rm /etc/nginx/sites-enabled/default` |
| EC2 not reachable on port 80 | Check the EC2 Security Group inbound rules allow HTTP (port 80) |

---

## 📚 Further Reading

- [GitHub Actions documentation](https://docs.github.com/en/actions)
- [Amazon EC2 User Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/)
- [Nginx Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html)
- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

---

*Built for the AI-Powered DevOps Webinar — demonstrating how AI tools can scaffold a complete CI/CD pipeline from scratch.*
