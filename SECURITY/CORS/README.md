# 🔐 CORS Strategy for White-Label Multi-Tenant CRM (MERN Stack)

> Because `cors({ origin: "*" })` on a CRM is not a strategy — it's a resignation letter.

---

## 📌 The Problem

A typical CRM SaaS serving multiple organizations needs to handle **three types of origins** simultaneously:

| Type | Example | Challenge |
|---|---|---|
| Root domain | `crm.com` | Easy |
| Tenant subdomains | `myapp.crm.com`, `demo1.crm.com` | Regex |
| White-label custom domains | `mycrm.com` → CNAME → `crm.com` | Hard |

A single `cors()` call handles none of this gracefully. So here's the full strategy.

---

## 🏗️ Architecture Overview

```
Incoming Request
      ↓
Is origin *.crm.com?   → YES → ✅ Allow
      ↓ NO
Redis cache hit?        → YES → ✅ / ❌ based on cached value
      ↓ MISS
DB lookup (verified     → YES → ✅ Allow + cache result
custom domain?)
      ↓ NO
❌ Block. Log it.
```

---

## ✅ The CORS Middleware

```js
import cors from "cors";
import { isWhiteLabelDomain } from "./utils/domainValidator.js";

const YOUR_BASE_DOMAIN = "crm.com";

const isAllowedOrigin = async (origin) => {
  if (!origin) return true; // server-to-server / Postman

  try {
    const { hostname } = new URL(origin);

    // Case 1 & 2: Your own root + subdomains
    if (hostname === YOUR_BASE_DOMAIN || hostname.endsWith(`.${YOUR_BASE_DOMAIN}`)) {
      return true;
    }

    // Case 3: White-label custom domains
    return await isWhiteLabelDomain(hostname);

  } catch {
    return false;
  }
};

app.use(cors({
  origin: (origin, callback) => {
    isAllowedOrigin(origin)
      .then(allowed => allowed
        ? callback(null, true)
        : callback(new Error(`CORS Rejected: ${origin}`))
      );
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
  allowedHeaders: ["Content-Type", "Authorization"],
}));
```

---

## ⚡ White-Label Domain Lookup — Do It Right

CORS fires on **every single preflight request**. That means your domain validation runs constantly.

### ❌ DON'T do this — DB call on EVERY request = you hate yourself

```js
const isWhiteLabelDomain = async (hostname) => {
  return await db.Organization.findOne({ customDomain: hostname });
};
```

### ✅ DO this — Cache it. Redis preferred.

```js
import redis from "./redisClient.js";

const isWhiteLabelDomain = async (hostname) => {
  const cacheKey = `whitelabel:${hostname}`;

  // Check cache first
  const cached = await redis.get(cacheKey);
  if (cached !== null) return cached === "1";

  // Miss → hit DB
  const org = await db.Organization.findOne({
    customDomain: hostname,
    status: "active"  // don't allow suspended orgs
  });

  const allowed = !!org;

  // Cache for 10 mins — TTL handles domain removal eventually
  await redis.setex(cacheKey, 600, allowed ? "1" : "0");

  return allowed;
};
```

### 📊 Why This Matters

| Approach | Latency | At 10,000 req/min |
|---|---|---|
| DB on every request | ~20–50ms | 💀 DB melts |
| Redis cache | ~0.1–1ms | 😴 Boring. Good. |
| In-memory Map | ~0.01ms | ✅ Single server only |

**DB only gets hit once every 10 minutes per domain.** Not per request.

---

## 🗄️ Organization Schema

```js
const OrganizationSchema = new Schema({
  name: { type: String, required: true },

  // Context-based routing: myapp.crm.com
  subdomain: {
    type: String,
    unique: true,
    lowercase: true,
    trim: true,
    required: true
  },

  // White-label: mycrm.com (CNAME → crm.com)
  customDomain: {
    type: String,
    unique: true,
    sparse: true,       // null for orgs without white-label
    lowercase: true
  },

  // Never trust a domain without verifying the CNAME first
  domainVerified: {
    type: Boolean,
    default: false
  },

  status: {
    type: String,
    enum: ["active", "suspended", "trial"],
    default: "trial"
  }
});
```

---

## 🔍 CNAME Verification Flow

Before any custom domain is trusted, **verify the client actually owns it**.

```js
import dns from "dns/promises";

const verifyCNAME = async (customDomain) => {
  try {
    const records = await dns.resolveCname(customDomain);
    const pointsToCRM = records.some(r => r.endsWith("crm.com"));

    if (pointsToCRM) {
      await db.Organization.updateOne(
        { customDomain },
        { domainVerified: true }
      );

      // Warm the cache immediately after verification
      await redis.setex(`whitelabel:${customDomain}`, 600, "1");
      return true;
    }

    return false;
  } catch {
    return false; // DNS lookup failed = not verified
  }
};
```

**Why verify?** Without this, any user could claim `google.com` or a competitor's domain as their own. You'd be handing out VIP passes to strangers at your own party.

---

## 🏠 Fallback: No Redis Yet? (MVP Mode)

Single-server in-memory cache. Gets the job done until you scale.

```js
const domainCache = new Map();

const isWhiteLabelDomain = async (hostname) => {
  const now = Date.now();
  const cached = domainCache.get(hostname);

  if (cached && (now - cached.ts) < 600_000) {
    return cached.allowed;
  }

  const org = await db.Organization.findOne({
    customDomain: hostname,
    domainVerified: true
  });

  domainCache.set(hostname, { allowed: !!org, ts: now });
  return !!org;
};
```

> ⚠️ **Warning:** Dies on server restart. Doesn't sync across multiple instances. Fine for MVP. Migrate to Redis when you scale horizontally.

---

## 🔒 Full Security Checklist

```
✅ CORS — dynamic origin validation (this repo)
✅ credentials: true — required for auth cookies / JWT headers
✅ Helmet.js — secure HTTP response headers
✅ express-rate-limit — brute force protection
✅ JWT / session validation — CORS is a bouncer, not a vault
✅ HTTPS only in production — non-negotiable
✅ CNAME verification — before trusting ANY custom domain
✅ Redis TTL — auto-expires removed/suspended domains
```

> **CORS is your first line of defense, not your only one.** Treating it as a security silver bullet is how you end up on HackerNews for the wrong reasons.

---

## 📦 Dependencies

```bash
npm install cors redis dns
```

```json
{
  "cors": "^2.8.5",
  "redis": "^4.x",
  "mongoose": "^7.x"
}
```

---

## 📁 Suggested File Structure

```
src/
├── middleware/
│   └── cors.middleware.js       # Main CORS config
├── utils/
│   ├── domainValidator.js       # isWhiteLabelDomain()
│   └── cnameVerifier.js         # verifyCNAME()
├── models/
│   └── Organization.model.js    # Schema with customDomain fields
└── config/
    └── redisClient.js           # Redis connection
```

---

## 🤝 Contributing

Open a PR. Write tests. Don't push `origin: "*"` to main or you will be judged — silently, permanently, and justifiably.

---

## 📄 License

MIT — use freely, configure responsibly.
