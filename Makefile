# EVREN LLM gateway launchers. See README.md.
#
#   make junie DIR=~/code/some-project
#   make opencode DIR=~/code/some-project
#   make quota

SHELL := /bin/bash

# Settings come from .env in this folder (see .env.example). Values there
# override the shell environment. Write them without quotes.
-include .env
export EVREN_API_KEY

API   := https://evren-llmapi.ssyz.org.tr
DIR   ?= $(CURDIR)
# The shell does not expand "~" in DIR=~/x, so do it here.
override DIR := $(patsubst ~%,$(HOME)%,$(DIR))
MODEL ?= glm-5.3
FAST  ?= qwen3.8-flash-next
PROMPT ?= Reply with exactly: OK

# Junie's bundled JVM does not trust the root CA behind the gateway's
# certificate; the system Java truststore does.
JUNIE_JAVA_OPTS := -Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts -Djavax.net.ssl.trustStorePassword=changeit

# Junie profile names live in ~/.junie/models/<name>.json
JUNIE_PROFILE_glm-5.3             := evren-glm
JUNIE_PROFILE_deepseek-v4.1-flash := evren-deepseek
JUNIE_PROFILE := $(JUNIE_PROFILE_$(MODEL))

CURL := curl -sS -m 30 -H "X-API-Key: $$EVREN_API_KEY"
JSON := python3 -m json.tool --no-ensure-ascii

.DEFAULT_GOAL := help
.PHONY: help check-key junie junie-deepseek opencode opencode-ask claude \
        quota models terms test

help: ## Show this list
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | \
		awk -F':.*## ' '{printf "  make %-16s %s\n", $$1, $$2}'
	@echo
	@echo "  Variables: DIR=<project folder>  MODEL=glm-5.3|deepseek-v4.1-flash  PROMPT=\"...\""

check-key:
	@[ -n "$$EVREN_API_KEY" ] || { echo "EVREN_API_KEY is not set: copy .env.example to .env and fill it in"; exit 1; }

# --- coding tools ----------------------------------------------------------

junie: check-key ## Open Junie on DIR with MODEL
	@[ -n "$(JUNIE_PROFILE)" ] || { echo "No Junie profile for MODEL=$(MODEL)"; exit 1; }
	JAVA_TOOL_OPTIONS='$(JUNIE_JAVA_OPTS)' junie --model custom:$(JUNIE_PROFILE) --project "$(DIR)"

junie-deepseek: ## Open Junie on DIR with deepseek-v4.1-flash
	@$(MAKE) --no-print-directory junie MODEL=deepseek-v4.1-flash DIR="$(DIR)"

opencode: check-key ## Open opencode on DIR (pick the evren model with /models)
	opencode --standalone "$(DIR)"

opencode-ask: check-key ## One-shot opencode run in DIR: PROMPT="..." MODEL=...
	cd "$(DIR)" && opencode run --standalone -m evren/$(MODEL) "$(PROMPT)"

claude: check-key ## Open Claude Code on DIR, pointed at EVREN (not Claude models)
	cd "$(DIR)" && \
	ANTHROPIC_BASE_URL="$(API)" \
	ANTHROPIC_AUTH_TOKEN="$$EVREN_API_KEY" \
	ANTHROPIC_MODEL="$(MODEL)" \
	ANTHROPIC_DEFAULT_OPUS_MODEL="$(MODEL)" \
	ANTHROPIC_DEFAULT_SONNET_MODEL="$(MODEL)" \
	ANTHROPIC_DEFAULT_HAIKU_MODEL="$(FAST)" \
	CLAUDE_CODE_SUBAGENT_MODEL="$(MODEL)" \
	CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
	claude

# --- gateway checks --------------------------------------------------------

quota: check-key ## Show remaining daily tokens and limits
	@$(CURL) "$(API)/v1/quota" | $(JSON)

models: check-key ## List model ids available to the key
	@$(CURL) "$(API)/v1/models" | \
		python3 -c 'import json,sys; [print(m["id"]) for m in json.load(sys.stdin)["data"]]'

terms: check-key ## Show terms-of-service acceptance status
	@$(CURL) "$(API)/v1/terms/status" | $(JSON)

test: check-key ## Send one tiny request to MODEL through the raw API
	@$(CURL) "$(API)/v1/chat/completions" -H "Content-Type: application/json" \
		-d '{"model":"$(MODEL)","max_tokens":2048,"messages":[{"role":"user","content":"Reply with exactly: OK"}]}' | \
		python3 -c 'import json,sys; r=json.load(sys.stdin); print(r["choices"][0]["message"]["content"] if "choices" in r else r)'
