# What Happens When a User Visits Your App (with SSL)

## 1. The big picture

```
   USER'S BROWSER                    AWS                          YOUR APP
   ───────────────                   ───                          ────────

   "I want https://
    sample-app.533266955893
    .realhandsonlabs.net"
            │
            │  ① DNS: "Where is sample-app....?"
            ├──────────────────────────►  Route 53 (your hosted zone)
            │                              │
            │  ② "It's at the ALB"         │  A record: sample-app.... → ALB
            │◄────────────────────────────┘
            │
            │  ③ Connect to ALB on port 443 (HTTPS)
            ├──────────────────────────►  Application Load Balancer
            │                              │  • Presents SSL cert (*.533266955893...)
            │  ④ TLS handshake             │  • Browser checks: trusted? name match? valid?
            │  ⑤ Encrypted tunnel          │  • If OK → padlock, encrypted traffic
            │◄─────────────────────────────┤
            │                              │
            │  ⑥ HTTP request (inside encrypted tunnel)
            │                              ├──────────────────────────►  Nginx (in EKS)
            │  ⑦ Response (HTML)           │◄───────────────────────────
            │◄─────────────────────────────┘
```

---

## 2. Two separate steps (DNS vs SSL)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  STEP A: DNS (Route 53)                                                      │
│  "Which server should I talk to?"                                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   User types: sample-app.533266955893.realhandsonlabs.net                    │
│        │                                                                      │
│        ▼                                                                      │
│   ┌─────────┐      "Where is that?"       ┌──────────────┐                    │
│   │ Browser │ ──────────────────────────► │  Route 53    │                    │
│   │         │                              │  (DNS)      │                    │
│   │         │ ◄──────────────────────────  │              │                    │
│   └─────────┘   "It's at this ALB:"       │  A record:   │                    │
│        │         k8s-mygroup-xxx.elb...    │  sample-app  │                    │
│        │                                  │  → ALB       │                    │
│        ▼                                  └──────────────┘                    │
│   Browser now knows the ALB's address.                                       │
│   (No encryption yet – this is just "finding" the server.)                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  STEP B: SSL/TLS (at the ALB)                                                │
│  "Prove who you are and encrypt the traffic."                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Browser connects to ALB on port 443 (HTTPS)                                │
│        │                                                                      │
│        ▼                                                                      │
│   ┌─────────┐    "Here is my certificate     ┌──────────────┐                │
│   │ Browser │     for *.533266955893..."      │  ALB         │                │
│   │         │ ◄───────────────────────────── │              │                │
│   │         │                                │  Uses your   │                │
│   │         │  Browser checks:               │  ACM cert     │                │
│   │         │  • Cert from Amazon? ✓         │  (once you    │                │
│   │         │  • Name matches? ✓             │   run        │                │
│   │         │  • Not expired? ✓              │   run-with-  │                │
│   │         │                                │   ssl.sh)     │                │
│   │         │  → Show padlock, encrypt       └───────┬───────┘                │
│   │         │    all traffic                         │                         │
│   └─────────┘                                       │                         │
│        │                                             ▼                         │
│        └──────── Encrypted tunnel ─────────►  Your app (Nginx in EKS)         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Your certificate’s role

```
   ACM Certificate: *.533266955893.realhandsonlabs.net
   ───────────────────────────────────────────────────

   Status: Issued  ✓     In use: No  (until ALB uses it)

   What it covers:
   ┌────────────────────────────────────────────────────────┐
   │  *.533266955893.realhandsonlabs.net                    │
   │  ├── sample-app.533266955893.realhandsonlabs.net  ✓   │
   │  ├── api.533266955893.realhandsonlabs.net          ✓   │
   │  └── anything.533266955893.realhandsonlabs.net    ✓   │
   └────────────────────────────────────────────────────────┘

   When you run run-with-ssl.sh:
   • The Load Balancer Controller finds this cert in ACM (by hostname).
   • It attaches the cert to the ALB’s HTTPS (443) listener.
   • Then "In use" becomes Yes, and the flow in the diagrams above works.
```

---

## 4. One-line flow (simplest)

```
USER  →  DNS (Route 53): "Where?"  →  "ALB"  →  USER  →  ALB: HTTPS + cert  →  Encrypted  →  App (Nginx)
         ─────────────────────────               ─────────────────────────────
         Just an address lookup                   SSL: prove identity + encrypt
```

You can open this file in VS Code; if you have a Mermaid or Markdown preview extension, the diagrams will show clearly.
