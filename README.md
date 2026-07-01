# AI FAQ Chatbot — Dental Clinic (n8n)

A production-grade AI chatbot for a dental clinic's Telegram support, built end-to-end in n8n with Google Gemini, PostgreSQL, and Airtable. Unlike a basic FAQ bot, it distinguishes medical-risk messages from routine questions and escalates the former to staff instead of letting the AI guess — while routine questions get instant, FAQ-grounded answers in the patient's own language.

---

## Architecture

![System overview]([docs/system-overview.png](https://github.com/aldar000405-a11y/AI-FAQ-Chatbot-Dental-Clinic-n8n-/tree/main/main-flow-diagram.png))

The system is three connected workflows sharing one PostgreSQL database:

| Workflow | Trigger | Purpose |
|---|---|---|
| Telegram FAQ Chatbot | Telegram message | Core patient-facing bot — intent detection, FAQ-grounded answers, escalation |
| Daily Report Digest | Schedule (8:20 AM daily) | Summarizes usage, errors, and cost to Slack + email |
| Global Error Monitor | Any workflow error (account-wide) | Instant IT alert if any workflow fails, anywhere |

![Main flow](full-architecture-board.png)

---

## Key design decisions

- **Grounded, not generative** — the AI only answers from an approved FAQ dataset (Airtable); it cannot invent clinic policy, pricing, or medical guidance.
- **Risk-aware by design** — messages mentioning pain, bleeding, medication, or emergencies are detected and escalated to a human before the AI ever attempts an answer.
- **Cost-controlled** — a per-patient daily token budget cap prevents runaway AI spend, checked before every AI call.
- **Conversational memory** — the last 8 messages per patient are pulled from PostgreSQL so the bot has real context, not just single-turn replies.
- **Multilingual out of the box** — language is detected from the incoming message and the reply matches it automatically, with no separate translation step.
- **Self-monitoring** — a dedicated error-handling branch catches AI/HTTP failures, logs them, emails IT, and still sends the patient a graceful apology instead of silence.

## Tech stack

n8n · Google Gemini 2.5 Flash · Telegram Bot API · PostgreSQL (Neon) · Airtable · Gmail · Slack

---

## Database setup (Neon / any Postgres)

This project runs on [Neon](https://neon.tech) — free-tier serverless Postgres — but any standard Postgres instance works the same way.

**Step 1 — Get your connection details.** Create a Neon project, then open the Neon dashboard and copy the connection string from **Connection Details**. It looks like:
```
postgresql://username:password@host.neon.tech/dbname?sslmode=require
```

**Step 2 — Create the tables.** Open the file `database-setup.sql` in this repo, copy its entire contents, paste it into Neon's **SQL Editor** (or any Postgres client connected to your database), and run it once. Copy it exactly as written — every column name, spelling, and order matches what the n8n workflow expects, so nothing should be changed.

This creates four tables:
- `chat_sessions` — stores each message so the bot can recall the last 8 messages per patient
- `unanswered_questions` — stores escalated questions along with why they were escalated
- `ai_errors` — stores failure details whenever the AI step breaks
- `user_token_usage` — stores token counts and cost per message, used for the daily spending cap and cost reports

**Step 3 — Connect n8n to it.** In n8n, create a new Postgres credential using the host, database name, username, and password from Step 1 (SSL must be enabled — Neon requires it). Use this credential in every Postgres node across all three workflows.

---

## Airtable setup (the FAQ knowledge base)

The bot answers only from Airtable — nothing is hardcoded into the AI prompt, so clinic staff can update answers without touching the automation.

1. Create an Airtable base with one table.
2. Add exactly two columns, named precisely `question` and `answer` (case-sensitive, both as text fields) — the workflow reads these two field names literally.
3. Add one row per FAQ item.
4. In n8n's Airtable node, connect a personal access token (create one at airtable.com/create/tokens) and select your base and table.

---

## Other credentials to connect

- **Google Gemini** — get a free key at aistudio.google.com/apikey. In the HTTP Request node that calls Gemini, replace the placeholder API key with your own.
- **Telegram** — create a bot via @BotFather in Telegram, get the bot token, and connect it as a Telegram credential in n8n.
- **Gmail** — connect your own Gmail account via OAuth in n8n, and set your own notification email address in the email nodes.
- **Slack** — connect a Slack credential and point the alert node at your own channel.

---

## Setup order

1. Set up the Neon database first (tables must exist before the bot runs)
2. Set up Airtable
3. Import and configure the core chatbot workflow, reconnecting all credentials
4. Import and configure the daily report workflow
5. Import and configure the global error monitor

## License

Shared for portfolio and reference purposes. Feel free to study the architecture — please don't redistribute as your own template without attribution.
