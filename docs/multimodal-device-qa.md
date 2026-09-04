# Multimodal device QA checklist

Manual verification for the on-device multimodal chat epic (`#18`). `flutter test`
verifies plumbing (domain models, chat template routing, RAM-threshold math, prompt
assembly); only a real device can verify actual image-grounded generation quality,
timing, and memory behavior. Run this checklist before cutting a release that includes
multimodal changes.

**Scope:** Gemma 4 E2B / E4B only. Bonsai 27B (`#23`) is deferred to v1.3.0 and isn't in
the catalog yet — skip any step below that doesn't apply once it lands.

**Known limitations** — not bugs, don't re-file these:

- First response after attaching an image can take **1–5 minutes** before the first
token appears. Vision encoding runs CPU-only (no GPU backend enabled) and took ~186s
for one image on a mid-range test device (`#57` tracks speeding this up). The
composer gives no progress indication during this wait beyond "nothing streaming yet"
— that's expected today, not a hang.
- Tapping Stop (or hitting the timeout) during that vision-encoding window does **not**
actually interrupt it — `#58` tracks this; native has no cancellation hook in that
code path yet. The app remains responsive, but the encode keeps running to
completion in the background.
- ~~If a `send()` fails *after* the message was already persisted..., the composer may
restore the just-sent image as a pending attachment~~ — fixed. `send()` now throws a
distinct `SendFailedAfterPersistException` for this case, and the composer clears its
text/attachment instead of restoring them, since the message already went through.
Originally found as a related bug: the text field wasn't clearing after a vision send
whose post-persist step failed. If either symptom reappears, it's a real regression —
file a fresh issue.



## Setup

- [x] A device with **<6 GB RAM** available (or use Settings/adb to simulate — see
  ```
  `RamCheckService`, thresholds are: no warning under ~2 GB combined model+mmproj
  size, no warning if device RAM ≥ 6 GB, otherwise the "High Memory Usage" dialog).
  Needed for the RAM-warning steps below.
  ```
- [x] A device with **≥6 GB RAM**, to confirm the warning correctly does *not* fire
  ```
  there.
  ```
- [x] Wi-Fi, to download Gemma 4 E2B (~3.1 GB) or E4B (~5.0 GB) plus their mmproj files
  ```
  (~1 GB each).
  ```



## 1. Catalog, download, and load

- [x] Models tab shows "Gemma 4 E2B IT (Vision)" and "Gemma 4 E4B IT (Vision)" in the
  ```
  catalog (fresh install and existing install — the catalog seed-merges new entries
  into an existing DB, it doesn't require a reinstall).
  ```
- [x] Downloading one fetches **both** the base model and its mmproj file, with combined
  ```
  progress shown as a single percentage (not two separate downloads to watch).
  ```
- [x] Tapping Load shows the full-screen loading overlay (pulsing animation + the
  ```
  model's name) — confirm the rest of the screen is genuinely locked: other rows'
  buttons, the Settings icon, and the Sideload button don't respond to taps while it
  loads. (The bottom nav bar can still switch tabs — that's expected, not a bug.)
  ```
- [x] Load completes successfully; a SnackBar confirms " loaded — ready to chat".
- [x] Retry-after-failure: if a load ever fails (e.g. force-quit mid-load once, then
  ```
  reopen), the model shows a **"Retry load"** action if the file is already fully
  downloaded (not "Retry download" — that would needlessly re-fetch multiple GB).
  ```



## 2. RAM warning

- [x] On the **<6 GB RAM** device: tapping Load on Gemma 4 E2B/E4B shows the "High
  ```
  Memory Usage" dialog, and its text specifically calls out the vision component's
  RAM contribution separately from the base model (not just a single combined
  number) — e.g. "This model (3.1 GB) plus its vision component (0.9 GB) requires
  approximately 4.0 GB of RAM...". It should **not** suggest "use Gemma 3 270M" as a
  fallback (that model can't do vision — recommending it would defeat the point).
  ```
- [x] Tapping "Load Anyway" proceeds; tapping "Cancel" leaves the model `downloaded`
  ```
  (not stuck in a weird state).
  ```
- [x] On the **≥6 GB RAM** device: loading the same model shows **no** warning dialog at
  ```
  all.
  ```
- [x] A text-only model under ~2 GB (Gemma 3 270M) never shows the warning on any
  ```
  device.
  ```



## 3. Image-grounded generation (plain chat)

- [x] With a vision model loaded, the image-attach button appears in the chat composer.
  ```
  Switch to a **text-only** model (e.g. Phi-3 Mini) — the button disappears/disables
  (gated on both the catalog flag *and* the native `supportsVision` check, not just
  one).
  ```
- [x] Attach a photo, send a text prompt referencing it (e.g. "what's in this image?").
  ```
  After the wait described in Known Limitations above, confirm the response is
  actually **grounded in the image content** — not a generic "I can't see any
  image" refusal (that exact failure mode is what `#24` fixed; if it reappears,
  that's a real regression, not a known limitation).
  ```
- [x] Send a **follow-up text-only message** in the same conversation (no new image).
  ```
  Confirm it doesn't hang, error, or re-attach the old image — only the turn that
  actually had an image attached should ever include it in generation.
  ```
- [x] Start a **new conversation**, send a **text-only** message with the same vision
  ```
  model loaded. Confirm behavior is identical to before this epic — no marker text
  leaking into the visible response, no latency regression versus a text-only model.
  ```



## 4. Agent mode + image

- [x] Enable tool-calling (agent mode) for a conversation on an agent-capable vision
  ```
  model. Attach an image, send a prompt that should trigger a tool call *and*
  reference the image (e.g. "look at this receipt and calculate the total").
  Confirm both the tool call and the final answer are grounded in the image — the
  image should still be considered on every agent-loop iteration for that turn, not
  just the first.
  ```
- [x] Expect this to be **slower** than a single-turn vision response — each agent
  ```
  iteration currently re-runs vision encoding from scratch (no KV-cache reuse
  across `generate()` calls). Multiply the single-response wait by however many
  tool-call iterations the turn takes. This is documented, not a bug to file.
  ```



## 5. RAG + image (if applicable)

- [ ] With RAG enabled and a vision model loaded, attach an image and send a query that
  ```
  would also retrieve document context. Confirm both the image and the retrieved
  context are reflected in the response (RAG folds into the prompt independently of
  the image marker — verify they don't clobber each other in the final prompt).
  ```



## 6. Failure paths

- [x] Attach an image, then delete the underlying file from device storage (e.g. via a
  ```
  file manager) before sending. Confirm `send()` shows a clean "Attached image is no
  longer available" error — not a native crash or cryptic platform exception.
  ```
- [x] Attempt to tap Load on a second model while a load is already in flight (fast
  ```
  double-tap, or via accessibility tooling). Confirm a "Another model is already
  loading" message appears rather than two loads racing each other.
  ```
- [x] With TalkBack (or VoiceOver) on, confirm you cannot navigate to and activate a
  ```
  model row's button while the loading overlay is showing — the overlay should
  block screen-reader focus, not just visual taps.
  ```
- [ ] Send a normal (successful) message with an image attached to a vision model.
  Confirm the composer's text field and image thumbnail both clear immediately after
  tapping send — not just eventually, and not only for text-only sends.



## 7. Regression: existing (non-multimodal) flows

- [x] Text-only chat, RAG, agent mode, conversation export, TTS read-aloud, and document
  ```
  ingestion all still work exactly as before with a text-only model loaded — none of
  this epic's changes should have touched their behavior.
  ```

