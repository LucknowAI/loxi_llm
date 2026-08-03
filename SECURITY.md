# Security Policy

## Supported versions

Security fixes are applied to the latest release on `main`. Older releases
receive fixes at maintainer discretion.

| Version | Supported |
| ------- | --------- |
| 1.1.x   | ✅        |
| 1.0.x   | ❌        |
| < 1.0   | ❌        |

## Reporting a vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Report them privately so we can assess and patch before disclosure:

1. Open a [GitHub Security Advisory](https://github.com/LucknowAI/loxi_llm/security/advisories/new)
   (preferred), or
2. Contact the maintainers through a private channel if you cannot use GitHub
   advisories.

Include as much detail as you can:

- Description of the issue and potential impact
- Steps to reproduce
- Affected version(s)
- Proof of concept, if available

## What we consider in scope

- Memory-safety or crash issues in the app's native inference path
  (`llama_engine` / llama.cpp integration)
- Issues that could expose user data off-device contrary to
  [PRIVACY.md](PRIVACY.md) (e.g. unintended network exfiltration of chats,
  documents, or embeddings)
- Path traversal or unsafe file handling during document import
- Dependency vulnerabilities with a demonstrated impact on Loki LLM

## Out of scope

- Vulnerabilities in third-party models downloaded from Hugging Face (report to
  the model publisher)
- Issues in upstream [llama.cpp](https://github.com/ggml-org/llama.cpp) unless
  they are exploitable through Loki LLM's integration — consider reporting
  upstream as well
- Social engineering, physical device access, or attacks requiring a compromised
  host OS outside the app's threat model
- Denial-of-service from loading extremely large models on low-RAM devices
  (expected resource limits)

## Response timeline

| Stage | Target |
| ----- | ------ |
| Acknowledgement | Within 72 hours |
| Initial assessment | Within 7 days |
| Fix or mitigation plan | Depends on severity; critical issues prioritized |

We will coordinate disclosure with you and credit reporters in the release
notes unless you prefer to remain anonymous.

## Secure development

Contributors should:

- Never commit API keys, tokens, or private model URLs
- Run `fvm flutter analyze` and tests before opening PRs
- Follow [CONTRIBUTING.md](CONTRIBUTING.md) for the branching and review process
