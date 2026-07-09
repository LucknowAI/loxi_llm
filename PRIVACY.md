# Privacy Policy — Loki LLM

_Last updated: 2026-07-07_

Loki LLM is a private, on-device AI application. This policy explains what data
the app handles and where it goes. In short: **your content stays on your
device. We do not collect, transmit, or sell any personal data.**

## Data the app stores on your device

All of the following is stored **only on your device** (in the app's private
storage) and is never uploaded to us or any third party:

- **Conversations** — the messages you send and the model's responses, plus a
  rolling summary used to keep long chats coherent.
- **Documents** — files you import for document Q&A (RAG), the text extracted
  from them, and on-device vector embeddings of that text.
- **Settings** — your preferences (e.g. chunk size, top-K, feature toggles).
- **Diagnostic logs** — app/runtime logs kept on-device to help diagnose
  crashes. Not transmitted anywhere.

You can delete this data at any time by deleting conversations/documents in the
app or by uninstalling the app.

## Model I/O logging (off by default)

The app has an optional **Model I/O logging** setting, **disabled by default**.
When you turn it on, the app writes the **full prompts and full responses** of
each generation to an unencrypted file **on your device** for debugging. This
data is never transmitted off the device. Because it stores your prompts and
outputs in plaintext, leave it off unless you are actively debugging, and clear
the log when finished.

## Network access

The app requests the `INTERNET` permission for **one purpose only**: downloading
the AI model files you choose, directly from Hugging Face's servers. Those
requests are subject to Hugging Face's own privacy policy. The app makes **no
other network requests** — no analytics, no telemetry, no crash-reporting of
your content, no advertising.

## AI processing

All AI inference (chat, document Q&A, tools, summarization) runs **locally on
your device**. Your prompts, documents, and conversations are **not** sent to
any cloud AI service.

## Data we collect

**None.** We do not collect, receive, or have access to any of your data. There
are no accounts, no servers operated by us, and no third-party data sharing.

## Children's privacy

The app is not directed at children and collects no data from anyone.

## Changes

If this policy changes, the updated version will be published with a new "last
updated" date.

## Contact

For questions about this policy, contact the developer through the app's store
listing.
