# 🍕 The Complete NGINX Guide (Explained with Pizza)

> **Reading time:** ~20 minutes  
> **Level:** Fresher → Job-ready  
> **Vibe:** You will never look at a web request the same way again

---

## Table of Contents

1. [What Even Is a Web Server?](#1-what-even-is-a-web-server)
2. [NGINX vs Apache — The Pizza Shop Wars](#2-nginx-vs-apache--the-pizza-shop-wars)
3. [Installing & Basic Commands](#3-installing--basic-commands)
4. [Config File Structure — The Kitchen Blueprint](#4-config-file-structure--the-kitchen-blueprint)
5. [www-data User — The Delivery Boy with No Keys](#5-www-data-user--the-delivery-boy-with-no-keys)
6. [sites-available vs sites-enabled — Menu vs Active Menu](#6-sites-available-vs-sites-enabled--menu-vs-active-menu)
7. [Virtual Hosts — Multiple Pizza Chains, One Kitchen](#7-virtual-hosts--multiple-pizza-chains-one-kitchen)
8. [Ports — Which Counter Does What](#8-ports--which-counter-does-what)
9. [Reverse Proxy — The Order Manager](#9-reverse-proxy--the-order-manager)
10. [Path-Based Routing — Different Sections of the Restaurant](#10-path-based-routing--different-sections-of-the-restaurant)
11. [HTTPS / SSL — The Sealed Pizza Box](#11-https--ssl--the-sealed-pizza-box)
12. [Domain Redirects — One Address, One Menu](#12-domain-redirects--one-address-one-menu)
13. [Performance — Making the Kitchen Faster](#13-performance--making-the-kitchen-faster)
14. [Security — The Bouncer at the Door](#14-security--the-bouncer-at-the-door)
15. [Load Balancing — Multiple Kitchens, One Brand](#15-load-balancing--multiple-kitchens-one-brand)
16. [Logs — The Security Camera Footage](#16-logs--the-security-camera-footage)
17. [Common Mistakes — The Wall of Shame](#17-common-mistakes--the-wall-of-shame)
18. [Final Project — Build the Whole Restaurant](#18-final-project--build-the-whole-restaurant)

---

## 1. What Even Is a Web Server?

### The Problem First

You built a website. It's sitting on your computer. Your friend in another city wants to see it.

He types your IP address. Nothing happens.

Why? Because there's nobody at the door to answer. Your friend knocked. No one opened.

**A web server is the person who opens the door.**

It listens for incoming requests (HTTP/HTTPS) and decides what to send back — HTML files, images, JSON from your backend, whatever.

### The Pizza Metaphor

Think of the internet like a city full of hungry people (users/browsers).

Your **web server is a pizza shop**.

- Customer walks in (browser sends request)
- Staff takes the order (server receives request)
- Kitchen prepares the pizza (server fetches the file/data)
- Pizza is delivered to table (server sends response)

Without a web server running, your pizza shop's shutters are down. Lights off. Customers leave.

**NGINX is one of the most popular pizza shop setups in the world.**

---

## 2. NGINX vs Apache — The Pizza Shop Wars

### The Problem First

There were two main web servers: **Apache** (old, reliable) and **NGINX** (new, fast). People needed to choose.

### Apache's Way — One Chef Per Customer

Apache works like a pizza shop where **one dedicated chef handles each customer from start to finish**.

- Customer A arrives → Chef 1 is assigned → waits while pizza bakes → serves → done
- Customer B arrives → Chef 2 is assigned → same process

This is fine when you have 10 customers. What happens with 10,000 simultaneous customers?

You need 10,000 chefs. Your building explodes. Apache struggles here — it runs out of memory and threads.

### NGINX's Way — One Smart Manager, Many Workers

NGINX works differently. It's **event-driven** and **asynchronous**.

Think of it like a pizza shop with **one very efficient order manager** and a small team of workers.

- Manager takes all orders at once (non-blocking)
- Workers process them in parallel
- When a pizza is ready, it gets delivered — no chef is "waiting" doing nothing

Result: NGINX can handle **tens of thousands of simultaneous connections** with very little memory.

**In short:**
- Apache = dedicated chef per customer (fine for small load)
- NGINX = smart event-driven manager (excellent for high traffic)

This is why almost every high-traffic site uses NGINX.

---

## 3. Installing & Basic Commands

```bash
# Install NGINX
sudo apt install nginx -y

# Start it
sudo systemctl start nginx

# Check if it's running
sudo systemctl status nginx

# Enable it to auto-start on boot (important for production)
sudo systemctl enable nginx
```

### The Golden Rule 🔴

```
ALWAYS reload. NEVER restart. In production.
```

Why? Think about it:

- **Restart** = close the pizza shop, kick everyone out, reopen. Active customers get disconnected.
- **Reload** = change the menu board while the shop stays open. Nobody notices.

```bash
# ✅ The right way
sudo systemctl reload nginx

# ❌ The wrong way (in production)
sudo systemctl restart nginx
```

### Test Before You Reload

Always test config before reloading. One typo can take down your entire server.

```bash
sudo nginx -t
```

If it says `syntax is ok` — you're good. If not, fix the error before reloading.

---

## 4. Config File Structure — The Kitchen Blueprint

### The Problem First

NGINX needs to know: *where are the files? which domain? which port?*

All of this lives in config files. Understanding where these files are is step one.

### The Kitchen Blueprint Metaphor

Imagine a big restaurant chain.

- There's a **main operations manual** → `nginx.conf`
- Each **branch has its own rulebook** → individual site config files
- There's a **folder of branch rulebooks** ready to use → `sites-available`
- The **currently open branches** → `sites-enabled`

```
/etc/nginx/
├── nginx.conf              ← Main config (the head office manual)
├── sites-available/        ← All site configs (all rulebooks)
│   └── myapp.conf
├── sites-enabled/          ← Active sites (symlinks to live ones)
│   └── myapp.conf → ../sites-available/myapp.conf
├── conf.d/                 ← Extra global configs (auto-included)
└── modules-enabled/        ← NGINX modules (rarely touched)
```

### The Main `nginx.conf`

You rarely touch this deeply. It sets global things like:
- How many workers to spawn
- How to handle connections
- Where to look for additional configs (it `include`s sites-enabled)

### A Typical Site Config

```nginx
server {
    listen 80;                    # Which port to listen on
    server_name example.com;      # Which domain

    root /var/www/myapp;          # Where are the files?
    index index.html;             # Which file to serve by default

    location / {
        try_files $uri $uri/ =404;
    }
}
```

That's it. NGINX sees a request for `example.com` → finds the files in `/var/www/myapp` → serves them.

---

## 5. www-data User — The Delivery Boy with No Keys

### The Problem First

Web servers need to read files on your system. But what if a hacker exploits your website? If NGINX runs as `root`, the hacker now **owns your entire server**. Game over.

### The Solution

Linux has a pre-built user called **`www-data`** — a low-privilege account specifically for web servers.

### The Pizza Metaphor

Imagine you hire a delivery boy. You give him:
- ✅ Access to the delivery bag (website files)
- ✅ Access to the car (nginx process)
- ❌ NOT the key to your house
- ❌ NOT your bank card
- ❌ NOT your admin password

If something bad happens and the delivery boy is compromised — the attacker can deliver pizzas but can't rob your house.

**`www-data` is that delivery boy.**

```bash
# Check who nginx is running as
ps aux | grep nginx

# Give www-data proper access to your app files
chown -R www-data:www-data /var/www/myapp/storage
chmod -R 755 /var/www/myapp/storage
```

### The Golden Rule for Permissions

```
Code         → read-only  for www-data  (nobody should change code via web)
Storage      → writable   by www-data   (uploads, user files)
Cache/Logs   → writable   by www-data   (nginx needs to write logs)
Secrets      → NEVER writable by www-data
```

### Common Paths by Framework

| Framework | Storage Path | Cache Path |
|-----------|-------------|------------|
| Laravel   | `/var/www/myapp/storage` | `/var/www/myapp/bootstrap/cache` |
| Node.js   | `/var/www/myapp/uploads` | `/var/www/myapp/tmp` |

---

## 6. sites-available vs sites-enabled — Menu vs Active Menu

### The Problem First

You might have configs for 10 different websites on one server. You don't want all of them live at once — maybe some are in testing, some are old, some are for future projects.

How do you manage this cleanly?

### The Pizza Metaphor

Imagine a big pizza chain's **corporate menu**. It lists every pizza variant ever created — seasonal, experimental, regional.

But your local branch only **activates a few items** from that master menu.

- `sites-available` = the full corporate menu (all configs, not necessarily live)
- `sites-enabled` = your branch's active menu (only live sites)

NGINX only reads from `sites-enabled`. It doesn't care about `sites-available` at all.

### How It Works — Symlinks

Instead of copying files (which would become a maintenance nightmare), `sites-enabled` contains **symlinks** (soft links) pointing to configs in `sites-available`.

```bash
# Enable a site (create a symlink)
sudo ln -s /etc/nginx/sites-available/myapp.conf /etc/nginx/sites-enabled/

# Disable a site (remove the symlink — original config stays safe)
sudo rm /etc/nginx/sites-enabled/myapp.conf

# Then reload
sudo systemctl reload nginx
```

**The original config is never deleted.** You just point to it or stop pointing. Like activating/deactivating a menu item without destroying the recipe.

### One-Line Rule

```
Edit in : sites-available
Activate via : sites-enabled (symlink)
```

---

## 7. Virtual Hosts — Multiple Pizza Chains, One Kitchen

### The Problem First

You have one server (one physical machine). You want to host:
- `pizzaplace.com` → serves a pizza website
- `burgerspot.com` → serves a burger website

Both use port 80. How does NGINX know which website to show for which domain?

### The Solution — Server Blocks (Virtual Hosts)

NGINX uses **server blocks** — separate configs for each domain. When a request comes in, NGINX checks the `server_name` and routes to the right block.

### The Pizza Metaphor

One building. Two restaurant brands inside it. Same address.

When you call and say "I want a pizza" → goes to the pizza counter.  
When you call and say "I want a burger" → goes to the burger counter.

The receptionist (NGINX) routes based on what you said (the `Host` header in the request).

```nginx
# Config for pizzaplace.com
server {
    listen 80;
    server_name pizzaplace.com www.pizzaplace.com;
    root /var/www/pizzaplace;
    index index.html;
}

# Config for burgerspot.com
server {
    listen 80;
    server_name burgerspot.com www.burgerspot.com;
    root /var/www/burgerspot;
    index index.html;
}
```

Two separate config files in `sites-available`, both symlinked to `sites-enabled`. NGINX serves each domain correctly from the same machine.

> ⚠️ **Never use the same `server_name` in two different blocks.** NGINX will get confused and pick arbitrarily. That's a fun bug to debug at 3 AM.

---

## 8. Ports — Which Counter Does What

### The Problem First

Your server is like a big building with thousands of windows. Each window has a number (port). Different services listen on different windows.

Without knowing which port your app is on, connections go nowhere.

### The Most Important Ports

| Port | What uses it |
|------|-------------|
| 80   | HTTP (normal unencrypted web) |
| 443  | HTTPS (encrypted web) |
| 22   | SSH (you connect to your server via this) |
| 3306 | MySQL |
| 5432 | PostgreSQL |
| 5000 | Node/Python backend (commonly) |
| 3000 | React/Node dev server |

### The Problem with Backend Ports Being Exposed

Your Node.js app runs on port 5000. NGINX forwards traffic to it. But what if someone directly hits `yourserver.com:5000`? They bypass NGINX completely — no security, no rate limiting, no logging.

**Solution: Block backend ports from the internet.**

```bash
# UFW = Uncomplicated Firewall
# Block direct access to port 5000 from internet
sudo ufw deny 5000

# But NGINX (running on the same server) can still access it internally
# because UFW only blocks external traffic
```

### Check What's Running on a Port

```bash
# "Show me what program is listening on port 80"
sudo lsof -i :80

# lsof = list open files (in Linux, ports are also "files")
# -i = network connections
```

> ⚠️ If you run Apache and NGINX at the same time, both will try to use port 80. They will fight. One will lose. Your site will die. Classic beginner mistake.

---

## 9. Reverse Proxy — The Order Manager

### The Problem First

Your Node.js app runs on `localhost:5000`. Users can't (and shouldn't) access this directly.

You want users to go to `yoursite.com` and have NGINX invisibly forward the request to your Node app, get the response, and send it back.

**This is a reverse proxy.**

### The Pizza Metaphor

Customers walk into the restaurant's **front counter** (NGINX on port 80/443).

They don't go into the kitchen themselves. Instead, the front counter manager (NGINX) takes the order, **goes to the kitchen** (your Node/Python/Java app), brings back the food, and hands it to the customer.

The customer never sees the kitchen. They never know the kitchen exists. From their perspective, the front counter made the pizza.

This is what a **reverse proxy** does.

```nginx
server {
    listen 80;
    server_name yoursite.com;

    location / {
        proxy_pass http://127.0.0.1:5000/;

        # These headers tell your app who the real client is
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Why Reverse Proxy Exists

- **Security** — backend ports are hidden from the world
- **SSL termination** — NGINX handles HTTPS, backend doesn't need to care
- **Multiple apps, one domain** — route `/api` to one app, `/` to another
- **Load balancing** — spread traffic across multiple backend instances
- **Logging and rate limiting** — one place to control everything

### ⚠️ The Trailing Slash Rule (This Will Bite You)

This is one of the most common nginx mistakes ever made. Pay attention.

```nginx
# ✅ CORRECT — trailing slash after the upstream address
location /api/ {
    proxy_pass http://127.0.0.1:5000/;
}
```

With the trailing slash, NGINX **strips** `/api/` from the path before forwarding.

```
User requests:   /api/users
NGINX forwards:  /users     ← backend receives this (correct!)
```

```nginx
# ❌ WRONG — no trailing slash
location /api/ {
    proxy_pass http://127.0.0.1:5000;
}
```

Without it, NGINX **keeps** `/api/` in the path.

```
User requests:   /api/users
NGINX forwards:  /api/users  ← backend receives this (broken!)
```

Your backend expects `/users` but gets `/api/users`. Result: 404 everywhere. Chaos. Confusion. You questioning your life choices.

**One-line rule:**
```
proxy_pass with trailing slash → strips the location prefix (correct)
proxy_pass without slash       → keeps the full path (usually broken)
```

---

## 10. Path-Based Routing — Different Sections of the Restaurant

### The Problem First

You have one domain. You have multiple apps. You don't want separate subdomains for each one.

You want:
- `yoursite.com/` → React frontend
- `yoursite.com/api` → Node.js backend
- `yoursite.com/admin` → Admin panel

### The Pizza Metaphor

One pizza restaurant. Different sections.

- Front door → regular dining area (frontend)
- Staff door marked `/api` → kitchen orders system (backend API)
- Manager's office door marked `/admin` → only management goes here

NGINX reads the URL path and routes to the correct destination.

```nginx
server {
    listen 80;
    server_name yoursite.com;

    # Frontend — served as static files
    location / {
        root /var/www/frontend;
        try_files $uri $uri/ /index.html;
    }

    # Backend API — forwarded to Node.js
    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Admin panel — forwarded to separate app
    location /admin/ {
        proxy_pass http://127.0.0.1:4000/;
        proxy_set_header Host $host;
    }
}
```

### Subdomains vs Paths — When to Use Which

| Approach | Use When |
|----------|----------|
| `yoursite.com/api` (path-based) | Small apps, simpler setup, early stage |
| `api.yoursite.com` (subdomain) | Big apps, separate teams, better scaling |

```
Small apps  → paths     (/api, /admin)
Big/real apps → subdomains  (api.example.com, admin.example.com)
```

Subdomains give you better security isolation, separate SSL certs, easier scaling, and cleaner cookie/auth handling.

---

## 11. HTTPS / SSL — The Sealed Pizza Box

### The Problem First

Without HTTPS, every request and response travels as **plain text** over the internet.

Your username. Your password. Your auth token. All visible to anyone on the same network, to your ISP, and to any server in between.

It's like delivering a pizza in a transparent box with the customer's address, credit card number, and house key written on the lid.

Browsers now mark HTTP sites as "Not Secure." Google penalises them in SEO rankings. Users don't trust them.

**HTTPS encrypts everything. It's mandatory.**

### The Pizza Metaphor

HTTPS is like putting your pizza in a **sealed, tamper-evident box**.

Only the customer has the key to open it. Even if someone intercepts the delivery, they see a locked box. They can't read the order, access the payment, or modify the pizza inside.

### How SSL/TLS Works (Simple Version)

```
Browser → "I want to talk securely"
Server  → "Here's my certificate (proof of identity)"
Browser → "Verified. Here's an encrypted session key"
Both    → communicate encrypted from here on
```

All the scary math (RSA, AES, handshakes) happens in milliseconds. You don't need to understand it deeply to use it.

### Let's Encrypt + Certbot — Free SSL

Let's Encrypt gives you **free, trusted SSL certificates**. Certbot is the tool that automates getting and renewing them.

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate (it modifies your nginx config automatically)
sudo certbot --nginx -d example.com -d www.example.com

# Test renewal (so you're not caught off-guard when it expires in 90 days)
sudo certbot renew --dry-run
```

Certbot auto-renews before expiry. You get HTTPS for free, forever, without thinking about it.

### What Certbot Does to Your Config

After running certbot, your nginx config gets updated to something like this:

```nginx
server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # Strong SSL settings (add these manually for better security grade)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    # HSTS — tells browsers to always use HTTPS
    add_header Strict-Transport-Security "max-age=31536000" always;

    root /var/www/myapp;
    index index.html;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name example.com;
    return 301 https://example.com$request_uri;
}
```

> ⚠️ **Never run certbot before your site is working on HTTP.** Certbot needs to verify you own the domain by making an HTTP request to it. If nginx is misconfigured or the domain doesn't point to your server yet, certbot will fail.

---

## 12. Domain Redirects — One Address, One Menu

### The Problem First

These are two different URLs:
```
http://example.com
https://www.example.com
```

Search engines treat them as different pages. If both return the same content, Google sees duplicate pages and penalises your SEO. Users land on inconsistent URLs. It looks unprofessional.

**You must pick ONE canonical domain and redirect everything else to it.**

### The Pizza Metaphor

Your pizza shop is at **"26, Main Street"** officially.

But some customers say "26 Main" (no street). Some say "main street 26". Some go to the back entrance.

You put signs on every entrance: **"Main entrance is this way →"**

That's a redirect. One official address. Everything else points there.

### Modern Choice: non-www (recommended)

Most modern sites use `example.com` without the `www`. It's cleaner.

```nginx
# Redirect www → non-www (and HTTP → HTTPS)
server {
    listen 80;
    listen 443 ssl;
    server_name www.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    return 301 https://example.com$request_uri;
}

# The real server block
server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    root /var/www/myapp;
    index index.html;
}
```

### Redirect All HTTP → HTTPS (Catch-All)

```nginx
server {
    listen 80;
    server_name _;       # _ means "any domain"
    return 301 https://$host$request_uri;
}
```

This catches every HTTP request to every domain on the server and redirects to HTTPS. Clean, universal.

### Always Use 301, Not 302

- **301 = Permanent redirect** (SEO-friendly, browsers cache it)
- **302 = Temporary redirect** (browsers don't cache, search engines don't pass link equity)

Unless you specifically need temporary, always use **301**.

> ⚠️ Never redirect both directions. Pick one canonical domain. If you redirect `www → non-www` AND `non-www → www`, you've created an infinite redirect loop. Your browser will cry.

---

# 13. Performance — Making the Kitchen Faster

##  `client_max_body_size` — The Pizza Size Limit
 
### The Problem First
 
You build a profile page. User uploads a photo. You get this:
 
```
413 Request Entity Too Large
```
 
Your backend didn't even see the request. NGINX rejected it before it reached your app.
 
Why? Because by default, NGINX only allows **1MB** request body. A single phone photo is 3-5MB. A PDF is 10MB. A video is forget it.
 
### The Pizza Metaphor
 
Imagine your pizza shop has a rule:
 
> "We only accept orders that fit on one notepad page."
 
Customer calls and orders 10 pizzas with custom toppings. Order is too long. Receptionist hangs up before the kitchen even hears about it.
 
That's NGINX with a small `client_max_body_size`. It hangs up on large requests at the door.
 
### The Fix
 
```nginx
# In your server block (or http block for global)
server {
    listen 80;
    server_name example.com;
 
    client_max_body_size 50M;   # Allow up to 50MB request body
 
    location / {
        proxy_pass http://127.0.0.1:3000/;
    }
}
```
 
### Where to Put It
 
| Location | Effect |
|----------|--------|
| Inside `http {}` in `nginx.conf` | Applies to ALL sites on the server |
| Inside `server {}` block | Applies to that one site only |
| Inside `location {}` block | Applies to that one route only |
 
**Recommended:** Put it in the `server {}` block. Global is too broad, per-location is overkill.
 
### What Value to Use
 
| Use Case | Recommended Value |
|----------|------------------|
| Basic forms, JSON APIs | `1M` (default, fine) |
| Profile photos, small images | `10M` |
| Document uploads (PDF, Word) | `50M` |
| Video uploads | `200M` or higher |
| No uploads at all | Keep default |
 
### The Golden Rule
 
```
If your app accepts file uploads → set client_max_body_size
If you don't set it → you will hit 413 → you will waste an hour → you will feel dumb
```
 
Everyone hits this once. Now you won't.
---

### Cache Static Files

Why re-make the same pizza every single time? For files that don't change (images, CSS, JS), tell the browser to cache them.

```nginx
location ~* \.(css|js|png|jpg|ico|gif|woff|woff2)$ {
    expires 30d;                         # Cache for 30 days
    add_header Cache-Control "public";
}
```

Users' browsers save these files locally. Next visit? Files are already there. Your server does less work. Pages load faster.

### Enable Gzip Compression

Compress responses before sending. Less data = faster delivery.

```nginx
# Add to nginx.conf inside the http block
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml;
gzip_min_length 1000;    # Only compress files > 1000 bytes
```

This can reduce file sizes by 60-80%. Huge win for slow connections.

### Prevent API Caching

You DO NOT want API responses cached. User data changes. Cache them and users see stale data.

```nginx
location /api {
    proxy_no_cache 1;
    proxy_cache_bypass 1;
    proxy_pass http://127.0.0.1:5000;
}
```

### Keepalive Connections

Without keepalive, every request opens a new TCP connection. With it, connections stay open and reuse. Much faster for users making multiple requests.

```nginx
# Add to nginx.conf
keepalive_timeout 65;    # Keep connections open for 65 seconds
```

### DNS Records (Must Know)

When your domain points to your server, DNS is what makes it work.

| Type | What It Does |
|------|-------------|
| A    | `example.com` → IPv4 address of your server |
| AAAA | `example.com` → IPv6 address |
| CNAME | `www.example.com` → alias for `example.com` |
| MX   | Email routing |
| TXT  | Domain verification (Google, SSL) |

**Real DNS flow:**
```
Your browser
    → ISP DNS server (checks cache)
    → Root DNS (.)
    → TLD DNS (.com)
    → Authoritative DNS (example.com's nameserver)
    → Returns IP address
    → Browser connects to that IP
```

All of this happens in milliseconds. DNS propagation (when you update records) takes minutes to 48 hours.

---

## 14. Security — The Bouncer at the Door

### Basic Auth — Password Protecting a Route

Sometimes you want to lock down a route (like `/admin`) with a simple username/password.

```bash
# Install the tool to create password files
sudo apt install apache2-utils -y

# Create a password file
sudo htpasswd -c /etc/nginx/.htpasswd admin
```

```nginx
location /admin {
    auth_basic "Restricted Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://127.0.0.1:4000/;
}
```

Now `/admin` prompts for a username and password before anything loads.

### IP Allowlist — Only Let Trusted IPs In

```nginx
location /admin {
    allow 192.168.1.100;   # Your office IP
    allow 10.0.0.0/8;      # Internal network
    deny all;              # Block everyone else
}
```

Only requests from those IPs get through. Everyone else gets a 403 Forbidden. The digital bouncer.

### Security Headers

These headers tell browsers how to behave with your site's content. They prevent entire classes of attacks.

```nginx
add_header X-Frame-Options "SAMEORIGIN";          # Prevents clickjacking
add_header X-Content-Type-Options "nosniff";       # Prevents MIME sniffing
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;   # Forces HTTPS
add_header X-XSS-Protection "1; mode=block";       # XSS protection
```

Add these to your server block. Low effort, high security improvement.

### Catch-All Block — Block Unknown Domains

If someone hits your server's IP directly (not through a domain), you don't want them seeing your site.

```nginx
# First server block — catches unmatched requests
server {
    listen 80 default_server;
    server_name _;
    return 444;    # 444 = nginx-specific code that closes connection without response
}
```

This blocks scrapers and bots that scan IP ranges. They get nothing.

---

## 15. Load Balancing — Multiple Kitchens, One Brand

### The Problem First

Your app is getting popular. One server can't handle all the requests. It's slow. Sometimes it crashes.

You need more servers. But users shouldn't know there are multiple. They just use `example.com`.

### The Pizza Metaphor

Dominos has one phone number. They have hundreds of kitchens.

When you call, they route your order to the nearest/least-busy kitchen. You don't know or care which one makes your pizza. You just get pizza.

**NGINX is the call center routing orders to multiple kitchens.**

### Round Robin (Default)

Sends each request to the next server in the list, cycling through them.

```nginx
upstream myapp {
    server 192.168.1.10:5000;
    server 192.168.1.11:5000;
    server 192.168.1.12:5000;
}

server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://myapp;
    }
}
```

Request 1 → server 1. Request 2 → server 2. Request 3 → server 3. Request 4 → server 1 again.

### Least Connections

Send to whichever server currently has the fewest active connections. Smarter than round robin for uneven workloads.

```nginx
upstream myapp {
    least_conn;
    server 192.168.1.10:5000;
    server 192.168.1.11:5000;
}
```

### Remove a Dead Server Automatically

```nginx
upstream myapp {
    server 192.168.1.10:5000 max_fails=3 fail_timeout=30s;
    server 192.168.1.11:5000 max_fails=3 fail_timeout=30s;
}
```

If a server fails 3 times in 30 seconds, NGINX stops sending to it. When it recovers, NGINX starts using it again. Automatic failover. Zero manual intervention.

---

# 16. Logs — The Security Camera Footage


##  `journalctl -u nginx` — The Full Error Story
 
### The Problem First
 
Your nginx fails to start or reload. You run:
 
```bash
sudo systemctl status nginx
```
 
You get something like:
 
```
● nginx.service - A high performance web server
   Loaded: loaded
   Active: failed
   ...
nginx: [emerg] unknown directive "servver_name" in /etc/nginx/.../myapp.conf:3
```
 
Sometimes it's clear. Sometimes `systemctl status` gives you only 3 lines and cuts off right before the useful part.
 
That's where `journalctl` comes in.
 
### What is journalctl?
 
`journalctl` is the log reader for **systemd** — the system that manages all services on Linux.
 
Every service (nginx, mysql, ssh, etc.) sends its logs to systemd's journal. `journalctl` lets you read them.
 
### The Commands You Actually Need
 
```bash
# See all nginx logs (opens in a pager, scroll with arrow keys, q to quit)
journalctl -u nginx
 
# See nginx logs in real time (like tail -f but for systemd)
journalctl -u nginx -f
 
# See only the last 50 lines (most useful for quick debugging)
journalctl -u nginx -n 50
 
# See logs since last boot (useful after a crash/reboot)
journalctl -u nginx -b
 
# See logs with timestamps, last 20 lines, no pager (paste into chat with senior)
journalctl -u nginx -n 20 --no-pager
```
 
### When to Use Which
 
| Situation | Command |
|-----------|---------|
| Nginx won't start, need to see why | `journalctl -u nginx -n 50` |
| Watching nginx live while testing | `journalctl -u nginx -f` |
| Server crashed, checking what happened | `journalctl -u nginx -b` |
| Copying logs to share with someone | `journalctl -u nginx -n 20 --no-pager` |
 
### journalctl vs nginx logs — What's the Difference?
 
| Log Type | Location | What It Shows |
|----------|----------|---------------|
| `journalctl -u nginx` | systemd journal | Startup errors, crashes, service failures |
| `/var/log/nginx/access.log` | nginx file log | Every HTTP request that came in |
| `/var/log/nginx/error.log` | nginx file log | Runtime errors (404, 502, permission denied) |
 
**Rule of thumb:**
- nginx **won't start** → use `journalctl`
- nginx **is running but broken** → use `error.log`
- nginx **is running, checking traffic** → use `access.log`
 
### The Pizza Metaphor
 
Your pizza shop has two types of records:
 
- **Security camera footage** (`journalctl`) — records everything from the moment the shop tried to open. If the shop couldn't open at all (broken door, key missing), this camera caught it.
- **Order history** (`access.log` / `error.log`) — records every order that came in once the shop was open.
 
If the shop never opened, the order history is empty. You need the security footage.
 
### Quick Debug Workflow
 
```bash
# Step 1 — test the config
sudo nginx -t
 
# Step 2 — if test passes but reload fails, check systemd
journalctl -u nginx -n 30
 
# Step 3 — if nginx is running but requests fail, check error log
tail -f /var/log/nginx/error.log
```
 
That's the full debugging chain. Start at `-t`, go deeper with `journalctl`, then `error.log`.
 
---


### Access Log

Every request that hits NGINX is logged.

```bash
tail -f /var/log/nginx/access.log
```

Sample output:
```
192.168.1.1 - - [01/Jan/2026:12:00:01 +0000] "GET /index.html HTTP/1.1" 200 1024
```

Translation: IP `192.168.1.1` requested `/index.html`, got a `200 OK`, response was `1024` bytes.

### Error Log

When things break, this is where the truth lives.

```bash
tail -f /var/log/nginx/error.log
```

**Rule:** Before panicking when your server breaks, check the error log. The answer is almost always there.

### Per-Site Logs (Recommended)

For multiple sites, keep logs separate:

```nginx
server {
    server_name example.com;
    access_log /var/log/nginx/example.com.access.log;
    error_log  /var/log/nginx/example.com.error.log;
}
```

### Common HTTP Status Codes

| Code | Meaning | Common Cause |
|------|---------|-------------|
| 200  | OK — everything fine | — |
| 301  | Permanent redirect | Intentional redirect |
| 403  | Forbidden | Wrong file permissions, `www-data` can't read files |
| 404  | Not Found | Wrong `root` path, file doesn't exist |
| 502  | Bad Gateway | Backend app is down, not running |
| 504  | Gateway Timeout | Backend is running but too slow to respond |

**503 tip:** If you see 502s, your Node/Python app probably crashed. Check its logs, not NGINX's.

---

## 17. Common Mistakes — The Wall of Shame

These mistakes are made by every single developer at least once. You're not special. You'll make them too. But now you'll know why.

### ❌ Restart instead of Reload

```bash
# Wrong
sudo systemctl restart nginx   # Kills active connections

# Right
sudo systemctl reload nginx    # Zero downtime
```

### ❌ Edit config without testing

```bash
# Always test before reload
sudo nginx -t

# If it says error → fix it
# If it says OK → reload
sudo systemctl reload nginx
```

### ❌ Wrong root path

```nginx
# Wrong — directory doesn't exist or is wrong
root /var/www/myap;   # typo — missing 'p'

# Check if path exists:
ls /var/www/myapp
```

### ❌ 403 Forbidden due to permissions

```bash
# NGINX (running as www-data) can't read your files
# Fix:
chown -R www-data:www-data /var/www/myapp
chmod -R 755 /var/www/myapp
```

### ❌ Same server_name twice

```nginx
# Two blocks with same domain = confusion
server { server_name example.com; ... }
server { server_name example.com; ... }   # Bad!
```

NGINX will pick one arbitrarily. Hard to debug. Don't do this.

### ❌ Forgetting to enable the site

```bash
# Config exists in sites-available but NOT symlinked to sites-enabled
# Nginx doesn't see it. Nothing works. You panic for 20 minutes.

sudo ln -s /etc/nginx/sites-available/myapp.conf /etc/nginx/sites-enabled/
```

### ❌ proxy_pass trailing slash mistake

Already covered but worth repeating — it's that common.

```nginx
# ✅ Strips /api/ from path
proxy_pass http://127.0.0.1:5000/;

# ❌ Keeps /api/ in path — breaks your backend routes
proxy_pass http://127.0.0.1:5000;
```

### ❌ Running Apache and NGINX simultaneously

Both want port 80. They fight. One wins, one crashes. Check with:

```bash
sudo lsof -i :80
```

If you see both `apache2` and `nginx` — stop one of them.

---

## 18. Final Project — Build the Whole Restaurant

This is your mandatory capstone. Build this and you'll have a real thing to put on your resume.

### Goal

Host 2 different apps on the same server with:
- HTTPS
- Correct reverse proxy
- Path-based or subdomain routing
- Proper permissions
- Logs configured

### Architecture

```
                    Internet
                       |
                   [NGINX]
                  Port 80/443
                  /         \
            /app1/          /app2/
               |               |
         Node.js app      Python Flask app
         Port 3000          Port 5000
```

### Step-by-Step

**Step 1: Set up both backend apps**
```bash
# App 1 — Node.js running on port 3000
# App 2 — Python Flask running on port 5000
# Make sure both run and respond locally

curl http://localhost:3000   # Should return something
curl http://localhost:5000   # Should return something
```

**Step 2: Block backend ports from the internet**
```bash
sudo ufw deny 3000
sudo ufw deny 5000
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 22    # Don't lock yourself out of SSH
sudo ufw enable
```

**Step 3: Create the NGINX config**
```bash
sudo nano /etc/nginx/sites-available/myproject.conf
```

```nginx
server {
    listen 80;
    server_name example.com;

    # App 1 — at root path
    location / {
        proxy_pass http://127.0.0.1:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # App 2 — at /api path
    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Logs
    access_log /var/log/nginx/myproject.access.log;
    error_log  /var/log/nginx/myproject.error.log;
}
```

**Step 4: Enable the site**
```bash
sudo ln -s /etc/nginx/sites-available/myproject.conf /etc/nginx/sites-enabled/
sudo nginx -t          # Test config
sudo systemctl reload nginx
```

**Step 5: Add HTTPS**
```bash
sudo certbot --nginx -d example.com
```

**Step 6: Verify everything**
```bash
curl https://example.com        # Should hit App 1
curl https://example.com/api/   # Should hit App 2
sudo tail -f /var/log/nginx/myproject.access.log  # Watch live requests
```

You now have a production-grade setup. Both apps running behind NGINX, HTTPS enabled, ports locked down, logs flowing.

---

## Quick Reference Cheatsheet

### File Locations

```
/etc/nginx/nginx.conf              ← Main config
/etc/nginx/sites-available/        ← All site configs (edit here)
/etc/nginx/sites-enabled/          ← Active symlinks (don't edit directly)
/var/log/nginx/access.log          ← All requests
/var/log/nginx/error.log           ← All errors
/etc/letsencrypt/live/             ← SSL certificates
```

### Essential Commands

```bash
sudo nginx -t                      # Test config syntax
sudo systemctl reload nginx        # Apply config (safe, no downtime)
sudo systemctl restart nginx       # Hard restart (avoid in production)
sudo systemctl status nginx        # Check if running
sudo systemctl enable nginx        # Auto-start on boot

tail -f /var/log/nginx/access.log  # Watch live traffic
tail -f /var/log/nginx/error.log   # Watch live errors

sudo lsof -i :80                   # What's using port 80?
sudo ufw deny 5000                 # Block port from internet
sudo ufw allow 80                  # Allow port from internet

# Enable a site
sudo ln -s /etc/nginx/sites-available/myapp.conf /etc/nginx/sites-enabled/

# SSL
sudo certbot --nginx -d example.com -d www.example.com
sudo certbot renew --dry-run
```

### The 5 Rules to Tattoo on Your Brain

```
1. Always test (nginx -t) before reload
2. Always RELOAD, never restart in production
3. Edit in sites-available, activate via sites-enabled
4. www-data needs read access to code, write access to storage
5. proxy_pass needs a trailing slash to strip the location prefix
```

---

*Built from real notes, real pain, and too many 2 AM debugging sessions.  
May your 502s be few and your reloads always succeed. 🍕*
