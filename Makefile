# Shortcuts for the incident lab. Run `make` to list them.
COMPOSE := docker compose -f incident/docker-compose.yml
BASE    := https://localhost:8444
OSCTRL_USER ?= admin
OSCTRL_PASS ?= conand
CERT    := incident/osctrl.crt
N       ?= linux-01
S       ?=
NODES   ?= 100

.DEFAULT_GOAL := help
.PHONY: help up down reset ps logs osqueryi offline online plant fake fake-stop cert env results clean

help: ## List the available commands
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-10s %s\n", $$1, $$2}'

up: ## Build and start the lab (osctrl + linux-01..03)
	$(COMPOSE) up -d --build
	@echo "UI: $(BASE)  user: $(OSCTRL_USER)  password: $(OSCTRL_PASS)  env: conand"

down: ## Stop the lab, keeping its data
	$(COMPOSE) down

reset: ## Wipe everything and start from scratch
	$(COMPOSE) --profile fake down -v
	$(COMPOSE) up -d --build

ps: ## Show the status of every service
	$(COMPOSE) ps -a

logs: ## Follow logs (all, or one service: make logs S=linux-01)
	$(COMPOSE) logs -f $(S)

osqueryi: ## Open osqueryi on a node (make osqueryi N=linux-02)
	$(COMPOSE) exec $(N) osqueryi

offline: ## Demo 2: take linux-03 offline
	$(COMPOSE) stop linux-03

online: ## Ending: bring linux-03 back
	$(COMPOSE) start linux-03

plant: ## Demo 3: start /tmp/conand-demo-2 on linux-02
	$(COMPOSE) exec -d linux-02 sh -c 'cp /bin/sleep /tmp/conand-demo-2 && exec /tmp/conand-demo-2 7200'

fake: ## Add simulated nodes with fake_news_go (make fake NODES=100)
	FAKE_NODES=$(NODES) $(COMPOSE) --profile fake up -d fake-nodes
	@echo "Enrolling $(NODES) fake nodes. Progress: make logs S=fake-nodes"

fake-stop: ## Stop the simulated nodes
	$(COMPOSE) --profile fake stop fake-nodes

cert: ## Copy the lab TLS certificate to incident/osctrl.crt
	@$(COMPOSE) cp osctrl-nginx:/tls/osctrl.crt $(CERT) >/dev/null 2>&1

env: cert ## Demo 4: print API exports (use: eval "$(make -s env)")
	@echo 'export CURL_CA_BUNDLE="$(CURDIR)/$(CERT)"'
	@echo 'export BASE=$(BASE)'
	@echo "export TOKEN=$$(curl -s --cacert $(CERT) -X POST $(BASE)/api/v1/login/conand \
		-d '{"username":"$(OSCTRL_USER)","password":"$(OSCTRL_PASS)","exp_hours":2}' | jq -r .token)"

results: cert ## Demo 4: download results (make results Q=query_xxx)
	@test -n "$(Q)" || { echo "Usage: make results Q=query_xxx"; exit 1; }
	@TOKEN=$$(curl -s --cacert $(CERT) -X POST $(BASE)/api/v1/login/conand \
		-d '{"username":"$(OSCTRL_USER)","password":"$(OSCTRL_PASS)","exp_hours":2}' | jq -r .token) && \
	curl --fail --silent --show-error --cacert $(CERT) \
		-H "Authorization: Bearer $$TOKEN" \
		"$(BASE)/api/v1/queries/conand/results/$(Q)" -o incident/resultados.json && \
	jq -r '.items[] | "\(.uuid)\t\(.data | fromjson | .result | length) filas"' incident/resultados.json

clean: ## Wipe the lab and remove local files
	$(COMPOSE) --profile fake down -v
	rm -f $(CERT) incident/resultados.json
