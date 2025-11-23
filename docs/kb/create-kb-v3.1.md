```markdown
---
id: anthropic-billing-v1.0
topic: anthropic-billing
file_role: documentation
profile: compact
difficulty_level: intermediate
kb_version: 1.0
prerequisites: []
related_topics: ['llm-cost-optimization', 'api-billing-models']
embedding_keywords: [anthropic, claude, api, billing, credits, limits, usage, auto-reload]
last_reviewed: 2025-11-17
---

# Anthropic / Claude Billing & Credits – KB (Compact)

## 1. Purpose & Scope

This doc explains how **Anthropic / Claude billing** works for:

- Claude API
- Workbench
- Claude Code (when backed by Console credits)

and how **credits, limits, and usage** interact.

It is provider-specific but project-agnostic and aligns with Anthropic’s own billing and limits documentation (see Section 10 for URLs).

---

## 2. Mental Model: Three Dials

Anthropic’s billing can be thought of as three separate “dials”:

1. **Credits (Money Pool)**
   Prepaid “usage credits” bought through the Claude Console, shared across **API, Workbench, and Claude Code**.

2. **Limits (How Hard You Can Hit It)**
   - **Rate limits**: tokens per minute (TPM) and requests per minute (RPM) per tier.
   - **Spend limits**: optional caps on monthly spend in the Console.

3. **Usage Allowances (Plan Budgets)**
   - For Claude Pro / Max and Claude Code subscriptions, Anthropic also tracks “usage limits” or conversation budgets over time.

A request only succeeds when all three are in a good state:

> Enough credits left
> + Under rate limits
> + Under any plan/usage caps

---

## 3. Credits: Prepaid Usage Pool

### 3.1 What Credits Are

- Claude API and Workbench are billed via **prepaid credits**.
- Credits are purchased **before** usage and are consumed by successful API calls at the published per-token prices.
- Credits from a single Console organization are shared by:
  - Claude API calls
  - Workbench jobs
  - Claude Code configured to use that org’s key

The current credit balance is visible on the Console **Billing** page.

### 3.2 Buying Credits

In the Claude Console:

1. Go to **Settings → Billing**.
2. Click **“Buy credits”**.
3. Enter the amount and complete the Stripe/Link payment flow.
4. Once processed, credits become available immediately in that organization.

Reference:
- “How do I pay for my Claude API usage?” – `https://support.claude.com/en/articles/8977456-how-do-i-pay-for-my-claude-api-usage`

### 3.3 Auto-Reload

Anthropic supports **auto-reload**:

- Toggle auto-reload in **Settings → Billing**.
- Configure:
  - A **minimum balance** threshold, and
  - A **reload amount** to purchase when that threshold is hit.

This prevents surprise outages from “credit balance too low” during long-running jobs.

### 3.4 Credit Expiration & Refunds

Key rules for credits:

- Purchased credits **expire 1 year after purchase**.
- The expiration date **cannot be extended**.
- Credit purchases are **non-refundable** and are subject to Anthropic’s Credit Terms.

Reference:
- Same billing article as above and linked “Credit Terms”.

Operationally: treat credits like a **working float**, not long-term storage. Keep balances modest and rely on auto-reload instead of giant one-time deposits.

---

## 4. Limits: Rate & Spend

Even with credits available, requests can be throttled or blocked by **limits**.

### 4.1 Rate Limits (TPM / RPM)

Anthropic enforces **organization-level rate limits**:

- **Tokens per minute (TPM)** and **requests per minute (RPM)** per model.
- Limits are tied to **usage tiers**; higher spend unlocks higher limits.

You can see your current limits on:

- Claude docs: `https://docs.claude.com/en/api/rate-limits`
- Console: **Settings → Limits**

Reference article for approach to rate limits:

- “Our approach to rate limits for the Claude API” – `https://support.claude.com/en/articles/8243635-our-approach-to-rate-limits-for-the-claude-api`

If you exceed these limits, the API returns 429-style responses until the window resets.

### 4.2 Spend Limits (Monthly Caps)

In addition to prepaid credits, you can configure a **monthly spend limit**:

- Acts as a hard ceiling on billable usage per month.
- Can prevent credit purchases or new usage if the combination of:
  - Existing charges + proposed new credits
  would exceed the set limit.

Use spend limits as the **safety brake** on top of the credit float.

---

## 5. Usage Limits: Plan Budgets

For **Claude Pro / Max** and **Claude Code** subscriptions, Anthropic defines **usage limits**:

- These govern how much you can use Claude over a time period (e.g., daily or weekly).
- They are separate from API credits and rate limits.
- When usage caps are hit, you may need to:
  - Wait for the reset window, or
  - Change plans / purchase additional usage if available.

Official explanation:

- “Understanding Usage and Length Limits” – `https://support.claude.com/en/articles/11647753-understanding-usage-and-length-limits`

Important distinction:

- **Usage limits** = “How much can I chat / code this week/month?”
- **Credits** = “Do we have money left to bill these requests?”
- **Rate limits** = “Are we within per-minute throughput bounds?”

---

## 6. Failure Modes: What Happens When Things Run Out

### 6.1 Credits Hit Zero

When your org’s credit balance is depleted:

- API calls using that org’s key fail with billing-related errors (e.g., “credit balance too low” messages in client tooling).
- Workbench jobs stop running.
- Any dependent tools (including Claude Code) fail until new credits are purchased.

Recovery steps:

1. Confirm the balance on **Settings → Billing**.
2. Purchase additional credits, staying within any spend limit.
3. Ensure the transaction completes successfully (no payment errors).
4. Retry failed operations.

### 6.2 Rate Limits Exceeded

When TPM/RPM caps are hit:

- API returns 429 (or similar rate-limit responses).
- Recommended patterns:
  - Implement backoff + retry with jitter.
  - Batch operations where possible.
  - If consistently constrained, request higher limits or grow into a higher tier.

References:

- Docs rate-limit page – `https://docs.claude.com/en/api/rate-limits`
- Support article on rate-limit approach – `https://support.claude.com/en/articles/8243635-our-approach-to-rate-limits-for-the-claude-api`

### 6.3 Plan Usage Exhausted

Under Pro / Max / Claude Code:

- You may see app-side messages about usage caps, even if API credits remain.
- Resolution is usually:
  - Wait for reset,
  - Upgrade plan, or
  - Shift heavy workloads to API-only, credit-backed usage where appropriate.

Reference:

- Usage and length limits – `https://support.claude.com/en/articles/11647753-understanding-usage-and-length-limits`

---

## 7. Claude Code & Billing

When Claude Code is configured to use a Console API key (BYOK):

- Every operation that hits the Claude API (repo scans, test runs, multi-agent workflows) **burns credits** from that org.
- Those calls also count toward **API rate limits** and any configured spend limits.

Practical implications:

- Treat Claude Code as a **high-intensity API client**.
- Monitor:
  - Console Billing (credits, spend)
  - Console Limits (rate limits)
  - In-tool usage / weekly budget indicators

If you see errors like **“Credit balance too low. Add funds.”** in Claude Code:

1. Verify the Console credit balance.
2. Check whether a monthly spend limit is blocking new purchases.
3. Add credits or adjust limits as needed.

---

## 8. Operational Runbook (Minimal)

### 8.1 Initial Setup

1. Create or select a Claude Console organization: `https://console.anthropic.com/`
2. Add a **small initial credit block** via **Settings → Billing → Buy credits**.
3. Configure:
   - Auto-reload with a safe minimum threshold and reload amount.
   - A monthly spend limit aligned to your actual budget.

### 8.2 Monitoring

- Use **Settings → Billing** to track:
  - Current credit balance
  - Recent charges and invoices
- Use **Settings → Limits** to track:
  - Current org tier
  - Per-model TPM/RPM caps

For Pro / Max / Claude Code usage:

- Watch usage meters and limits described in the **Usage and Length Limits** article.

### 8.3 Handling “Credit Balance Too Low”

When systems encounter this error:

1. Confirm credits are depleted in the Console.
2. Check if a spend limit or payment failure is blocking new credits.
3. Purchase credits within the spend cap and confirm the transaction.
4. Ensure services retry with sensible backoff rather than hard-crashing.

### 8.4 Design Patterns for Reliability & Cost

- **Auto-reload** + modest spend limits → avoid outages without runaway costs.
- Prefer cheaper models for:
  - Routing
  - Simple classification
  - Lightweight tooling
- Reserve more expensive models for:
  - Deep reasoning passes
  - Large-context jobs
- Add a **pre-flight Anthropic health check** in any long pipeline:
  - If billing or rate-limit errors appear, fail fast with clear logs and operator instructions.

---

## 9. Quick Reference Table

| Dimension        | What It Controls                                   | Where to View / Edit                                             |
|-----------------|-----------------------------------------------------|------------------------------------------------------------------|
| Credits         | Whether Anthropic can bill requests                 | Console → Settings → Billing                                     |
| Rate Limits     | Per-minute tokens / requests per model              | `https://docs.claude.com/en/api/rate-limits`, Console → Limits   |
| Spend Limits    | Max monthly billed usage                            | Console → Settings → Billing                                     |
| Usage Limits    | Plan-level usage budgets (Pro/Max/Code)            | Plan docs & “Usage and Length Limits” help article               |
| Auto-Reload     | Automatic credit top-ups                            | Console → Settings → Billing → Edit auto-reload                  |

---

## 10. Official Anthropic URLs (Reference)

These URLs are the primary sources this KB is aligned to:

- Claude docs home:
  - `https://docs.claude.com/`
- API rate limits (docs):
  - `https://docs.claude.com/en/api/rate-limits`
- Rate-limit policy (support article):
  - `https://support.claude.com/en/articles/8243635-our-approach-to-rate-limits-for-the-claude-api`
- Usage & length limits (support article):
  - `https://support.claude.com/en/articles/11647753-understanding-usage-and-length-limits`
- API billing / credits / auto-reload (support article):
  - `https://support.claude.com/en/articles/8977456-how-do-i-pay-for-my-claude-api-usage`
- Anthropic Console (for Billing & Limits pages):
  - `https://console.anthropic.com/`

This file is intended to live at `docs/kb/anthropic-billing.md` as a compact, provider-specific reference for how Claude billing, credits, limits, and usage interact in real systems.
```

Here are the main official sources this KB is based on, with citations:

* Anthropic “How do I pay for my Claude API usage?” (credits, auto-reload, expiration).
* Anthropic docs “Rate limits” (TPM/RPM and tiers).
* Anthropic support “Our approach to rate limits for the Claude API”.
* Anthropic support “Understanding Usage and Length Limits”.
