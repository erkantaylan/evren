# evren

Launchers for using the EVREN LLM gateway (Savunma Sanayii Başkanlığı's AI
platform, <https://evren.ssyz.org.tr>) from coding tools on this machine:
Junie CLI, opencode and Claude Code.

EVREN hosts open-weight models (GLM, DeepSeek, Qwen, Gemma) on its own GPU
cluster in Türkiye. It does not serve Claude models. The tools are the same;
the model behind them is different.

## Usage

Run from this folder, and point `DIR` at the project you want to work on:

```bash
make junie DIR=~/code/my-project
make opencode DIR=~/code/my-project
make claude DIR=~/code/my-project
```

Without `DIR` the tool opens on this folder.

| Target | What it does |
|---|---|
| `make junie` | Junie with `glm-5.3` |
| `make junie-deepseek` | Junie with `deepseek-v4.1-flash` |
| `make opencode` | opencode TUI; choose an `evren/...` model with `/models` |
| `make opencode-ask PROMPT="..."` | One-shot opencode run, prints the answer |
| `make claude` | Claude Code talking to EVREN instead of Anthropic |
| `make quota` | Remaining daily tokens and limits |
| `make models` | Model ids the key can use |
| `make terms` | Terms-of-service acceptance status |
| `make test` | One tiny request through the raw API |

`MODEL=deepseek-v4.1-flash` switches the model for `junie`, `opencode-ask`,
`claude` and `test`. The default is `glm-5.3`.

## Setup on this machine

- **API key**: `EVREN_API_KEY` is exported from `~/.zshenv`. Keys are created
  at <https://evren.ssyz.org.tr/api-keys>. The key is not stored in this folder.
- **opencode**: provider `evren` in `~/.config/opencode/opencode.json`
  (models `glm-5.3`, `deepseek-v4.1-flash`, `qwen3.8-flash-next`).
- **Junie**: profiles `~/.junie/models/evren-glm.json` and
  `evren-deepseek.json`, selected as `custom:evren-glm` / `custom:evren-deepseek`.
- **Claude Code**: no config file; `make claude` sets the `ANTHROPIC_*`
  variables for that one process only. Do not export them globally, or the
  normal Claude subscription gets redirected too.

## Why the launchers are not plain commands

- **Junie** fails with an SSL error on its own: its bundled Java truststore
  does not include the root CA the gateway's certificate chains to. The
  Makefile points it at the system truststore through `JAVA_TOOL_OPTIONS`.
- **opencode** normally talks to a long-running background service. If that
  service started before `EVREN_API_KEY` existed it reports "API anahtarı
  eksik". The Makefile uses `--standalone`, which starts a private server that
  inherits the current environment. Restarting the service also fixes it.

## Limits

- 15,000,000 tokens per day per account, across all keys and models. Resets
  at 03:00 Türkiye time. Unused quota does not carry over.
- Input served from the prefix cache counts at 3% towards the quota.
- 8 concurrent requests on this account (the website advertises 32).
- All inference is free until **1 December 2026**. After that it is billed in
  platform credits (CR); the per-token price has not been published.
- The API key expires on 1 January 2027.

## Things to know

- Reasoning models share `max_tokens` between thinking and the answer. If
  answers come back empty or cut off, raise it, or turn thinking off for the
  key on the API keys page.
- HTTP 429 means a quota or rate limit (see `Retry-After`); 503 means the
  model fleet is full, retry shortly.
- Prompts and completions are processed and logged on EVREN's servers under
  its terms of service (v1 accepted on 20 November 2026). The terms do not say
  clearly whether prompts may be used in a corpus, so keep confidential code
  and customer data out of it.

## Not yet tested

- `make claude` (the settings come from EVREN's own documentation).
- `make junie-deepseek` (same profile shape as the working `glm` one).
- The interactive `make opencode` and `make junie` sessions; only one-shot
  runs of both were verified.

## References

- API docs: <https://evren.ssyz.org.tr/llm/models>
- Usage and quota: <https://evren.ssyz.org.tr/llm/usage>
- Junie custom models: <https://junie.jetbrains.com/docs/custom-llm-models.html>
