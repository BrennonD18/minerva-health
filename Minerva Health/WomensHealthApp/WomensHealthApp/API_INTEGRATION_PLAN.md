# API & Integration Plan: Minerva Health

A prioritized plan to connect the right APIs and services so Minerva Health can compete as a best-in-class women’s health app—with a focus on **trust, accuracy, and differentiation**, not just “more APIs.”

---

## Tier 1: Must-have (core quality & trust)

### 1. **Apple HealthKit**
- **Why:** Single biggest trust and quality lever. Users expect period apps to read/write cycle and health data. “Syncs with Apple Health” is table stakes.
- **Use:**
  - **Read:** Menstruation, ovulation test results, sexual activity, symptoms (where available), basal body temperature if you add BBT.
  - **Write:** Period days, ovulation, and other cycle-related data from your app so one source of truth lives in Health.
- **Differentiator:** Proper HK metadata (source app, dates) and optional correlation with steps/sleep/HR for “cycle and wellness” insights.
- **Effort:** Medium (permissions, data mapping, background updates). No API key; Apple frameworks only.

### 2. **AI API for Luna (pick one and do it well)**
- **Why:** Luna is a differentiator. Right now she uses local fallbacks; a real model makes her actually helpful and “best on market.”
- **Options:**

  | Provider | Best for | Notes |
  |----------|----------|--------|
  | **OpenAI (GPT-4o / GPT-4o mini)** | Rich, nuanced answers | Strong instruction-following; use system prompt + cycle context. |
  | **Anthropic (Claude)** | Safety, long context | Good for sensitive health Q&A; long context for full cycle history. |
  | **Apple Foundation Models (on-device)** | Privacy-first, no server | When available in your deployment target; no API key, all local. |

- **Implementation:** Keep your existing `AICompanionManager` interface; swap in one provider (e.g. OpenAI or Anthropic) with a clear system prompt that includes cycle context (phase, symptoms, mood) and safety guidelines. Never send PII you don’t need; prefer anonymized cycle/symptom summaries.
- **Differentiator:** “Luna knows my cycle” (context-aware) + “Luna doesn’t judge” (tone in system prompt).

---

## Tier 2: High impact (better UX and retention)

### 3. **Push / local notifications**
- **Why:** You already have toggles for “period start” and “ovulation”; without delivery, the feature feels broken.
- **Options:**
  - **Apple Push Notification service (APNs):** For server-scheduled reminders (e.g. “Period likely tomorrow”). Requires a backend or a serverless function to schedule.
  - **Local notifications (UNUserNotificationCenter):** No backend. Schedule “Period reminder,” “Log your day,” “Ovulation window” from the app based on predicted dates. Best first step.
- **Differentiator:** Predictions based on *your* data (your cycles), not generic 28-day reminders; optional “gentle” vs “direct” wording.

### 4. **Secure cloud backup (and optional sync)**
- **Why:** “My data is only on this phone” is a risk; “backed up and restorable” is trust and retention.
- **Options:**
  - **iCloud (CloudKit):** Private, no extra auth for the user, works well for one user per device. Good for backup + optional sync across user’s devices.
  - **Firebase (Firestore + Auth):** If you later want accounts, Android, or web; more setup and privacy design.
- **Differentiator:** End-to-end encryption or at least “we don’t read your data” (e.g. CloudKit with user’s iCloud account).

---

## Tier 3: Differentiation (optional but “best on market”)

### 5. **Wearables / devices (via HealthKit or vendor SDKs)**
- **Why:** BBT and heart-rate variability (HRV) improve cycle and ovulation insights; some users already have the hardware.
- **Use:**
  - **HealthKit:** Read BBT, resting HR, HRV, sleep (already in Health from Apple Watch, Oura, etc.).
  - **Oura / Whoop / Garmin:** Only if you want app-specific integrations; often HealthKit is enough for “best on market” without extra SDKs.
- **Differentiator:** “Uses your Apple Watch / Oura data to refine predictions” without forcing a specific device.

### 6. **Evidence-based content or clinical logic**
- **Why:** Users and app stores care about accuracy and “not medical advice” boundaries.
- **Options:**
  - **No external API:** Partner with a clinician to turn your prediction and insight logic into documented, referenceable “methods” (e.g. “cycle length based on last 6 months, ovulation estimate per WHO guidelines”).
  - **Structured content API:** If you add articles or tips, use a CMS or a trusted health content provider (e.g. professional society licenses) so Luna and in-app copy stay aligned and citable.
- **Differentiator:** “Built with clinical input” and “we explain how we calculate” (transparency).

### 7. **Anonymous analytics (only if you need it)**
- **Why:** To improve flows and find bugs; not for “best on market” by itself.
- **Options:** Apple’s built-in analytics, or a privacy-focused product analytics tool with strict no-PII policies and compliance (e.g. EU/US health considerations).
- **Rule:** No health or cycle data in analytics; only generic events (e.g. “screen_view”, “log_saved”) and aggregates.

---

## What *not* to prioritize (for “best on market”)

- **Too many third-party trackers or ads:** Undermines trust in a health app.
- **Social or community APIs (until you have a strategy):** Moderation and safety are hard; not required for “best” in core tracking + Luna.
- **Telehealth or prescription APIs:** Only if you later decide to offer those services and have legal/clinical setup; out of scope for “connect APIs to be best on market” in v1.

---

## Suggested order of implementation

1. **Luna:** Connect one AI API (OpenAI or Anthropic), implement system prompt + cycle context, keep fallbacks for offline.
2. **Local notifications:** Implement “period reminder” and “ovulation window” (and optionally “log your day”) using your existing predictions.
3. **HealthKit:** Read/write menstruation and related cycle data; show “Connected to Apple Health” and optional “Insights use Health data.”
4. **Cloud backup:** Add iCloud backup (and optional sync) so data isn’t device-only.
5. **Refine:** Wearables via HealthKit, then content/clinical transparency and optional analytics.

---

## Quick reference: APIs to “connect”

| Priority | What | Type | Purpose |
|----------|------|------|---------|
| 1 | **Apple HealthKit** | SDK (no key) | Cycle + wellness data in/out; trust & accuracy |
| 2 | **OpenAI or Anthropic** | REST API | Luna: real AI, context-aware, safe |
| 3 | **Local Notifications** | iOS APIs | Reminders for period, ovulation, log |
| 4 | **iCloud / CloudKit** | Apple | Backup and optional sync |
| 5 | **HealthKit (extended)** | SDK | BBT, HR, HRV, sleep from wearables |

This plan keeps the app **private-first**, **accurate**, and **differentiated** (Luna + Health + predictions) without chasing every possible API.
