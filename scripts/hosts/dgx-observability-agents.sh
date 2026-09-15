#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# DGX Spark (gx10-4b61 / homelab-zrh-inference) — observability agents
#
# Setup artifact for the one host in the fleet that is neither NixOS nor a
# Taskmill compose host: an Ubuntu 24.04 aarch64 box running LM Studio, ComfyUI
# and the DGX dashboard. It has to emit the same three signals as every other
# node (TODO 28-23), so this installs, as systemd units:
#
#   node_exporter        :9100   host metrics
#   nvidia_gpu_exporter  :9835   GPU metrics (nvidia-smi scraped; DCGM has no
#                                GB10/Grace-Blackwell build)
#   cadvisor (docker)    :8081   container metrics  (:8080 is the DGX dashboard)
#   alloy                        journal + container logs -> Loki on the ops node
#
# Everything binds the tailnet address only. Run it on the DGX, or from the dev
# machine:  ssh microdots@gx10-4b61 'bash -s' < dgx-observability-agents.sh
#
# Idempotent: re-running re-downloads nothing that is already at the pinned
# version and rewrites the units and the Alloy config in place.
#
# Runbook: ai-dev-workflow/docs/dev/observability.md
# -----------------------------------------------------------------------------
set -euo pipefail

NODE_EXPORTER_VERSION="${NODE_EXPORTER_VERSION:-1.12.1}"
GPU_EXPORTER_VERSION="${GPU_EXPORTER_VERSION:-1.15.1}"
ALLOY_VERSION="${ALLOY_VERSION:-1.19.2}"
CADVISOR_IMAGE="${CADVISOR_IMAGE:-ghcr.io/google/cadvisor:v0.60.5}"

LOKI_PUSH_URL="${LOKI_PUSH_URL:-http://100.121.73.79:3100/loki/api/v1/push}"
HOST_LABEL="${HOST_LABEL:-$(hostname)}"

# Exporters bind the tailnet address, never 0.0.0.0: this box has no host
# firewall and sits on a residential network.
BIND_ADDR="${BIND_ADDR:-$(tailscale ip -4 2>/dev/null | head -1)}"
if [[ -z "${BIND_ADDR}" ]]; then
  echo "error: no tailscale IPv4 address; refusing to bind exporters to 0.0.0.0" >&2
  exit 1
fi

ARCH="$(uname -m)"
case "${ARCH}" in
  aarch64) GOARCH=arm64 ;;
  x86_64)  GOARCH=amd64 ;;
  *) echo "error: unsupported architecture ${ARCH}" >&2; exit 1 ;;
esac

log() { printf '\n==> %s\n' "$*"; }

SUDO=sudo
[[ "$(id -u)" -eq 0 ]] && SUDO=""

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

# --------------------------------------------------------------------------
# node_exporter
# --------------------------------------------------------------------------
install_node_exporter() {
  if [[ "$(/usr/local/bin/node_exporter --version 2>&1 | head -1 | awk '{print $3}')" == "${NODE_EXPORTER_VERSION}" ]]; then
    log "node_exporter ${NODE_EXPORTER_VERSION} already installed"
  else
    log "installing node_exporter ${NODE_EXPORTER_VERSION}"
    local tarball="node_exporter-${NODE_EXPORTER_VERSION}.linux-${GOARCH}"
    curl -fsSL -o "${TMP}/ne.tar.gz" \
      "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${tarball}.tar.gz"
    tar -xzf "${TMP}/ne.tar.gz" -C "${TMP}"
    ${SUDO} install -m 0755 "${TMP}/${tarball}/node_exporter" /usr/local/bin/node_exporter
  fi

  id -u node_exporter &>/dev/null || ${SUDO} useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter

  ${SUDO} tee /etc/systemd/system/node_exporter.service >/dev/null <<UNIT
[Unit]
Description=Prometheus node exporter
Documentation=https://github.com/prometheus/node_exporter
# The bind address only exists once tailscaled has brought the interface up.
After=network-online.target tailscaled.service
Wants=network-online.target

[Service]
User=node_exporter
Group=node_exporter
# --no-collector.cpufreq is REQUIRED on this box, not a preference.
# Reading /sys/devices/system/cpu/cpufreq/policy*/scaling_cur_freq on the GB10
# goes through a firmware round-trip that intermittently never returns. Go's
# blocking read is not cancellable, so each scrape leaks one goroutine holding
# node_exporter's concurrency slot; after 40 of them /metrics answers
# "Limit of concurrent requests reached (40)" with a 503 and the target is
# simply down. It is invisible in the exporter's log — the symptom is a
# connect that succeeds and headers that never arrive. Diagnosed from
# /debug/pprof/goroutine?debug=2, which keeps answering while /metrics hangs.
ExecStart=/usr/local/bin/node_exporter \\
  --web.listen-address=${BIND_ADDR}:9100 \\
  --no-collector.cpufreq \\
  --collector.systemd \\
  --collector.processes
Restart=always
RestartSec=5s
NoNewPrivileges=true
ProtectHome=yes
ProtectSystem=strict

[Install]
WantedBy=multi-user.target
UNIT
}

# --------------------------------------------------------------------------
# nvidia_gpu_exporter
#
# DCGM (and so dcgm-exporter) has no build for GB10 / Grace-Blackwell on
# aarch64; this exporter shells out to nvidia-smi, which the driver provides
# everywhere, and exports every field it prints as a gauge.
# --------------------------------------------------------------------------
install_gpu_exporter() {
  command -v nvidia-smi >/dev/null || { echo "error: nvidia-smi not found" >&2; exit 1; }

  if [[ "$(/usr/local/bin/nvidia_gpu_exporter --version 2>&1 | head -1 | awk '{print $3}')" == "${GPU_EXPORTER_VERSION}" ]]; then
    log "nvidia_gpu_exporter ${GPU_EXPORTER_VERSION} already installed"
  else
    log "installing nvidia_gpu_exporter ${GPU_EXPORTER_VERSION}"
    curl -fsSL -o "${TMP}/gpu.tar.gz" \
      "https://github.com/utkuozdemir/nvidia_gpu_exporter/releases/download/v${GPU_EXPORTER_VERSION}/nvidia_gpu_exporter_${GPU_EXPORTER_VERSION}_linux_${GOARCH}.tar.gz"
    tar -xzf "${TMP}/gpu.tar.gz" -C "${TMP}"
    ${SUDO} install -m 0755 "${TMP}/nvidia_gpu_exporter" /usr/local/bin/nvidia_gpu_exporter
  fi

  # Runs as root: nvidia-smi needs the device nodes, and the exporter is a
  # read-only query wrapper.
  ${SUDO} tee /etc/systemd/system/nvidia_gpu_exporter.service >/dev/null <<UNIT
[Unit]
Description=NVIDIA GPU exporter (nvidia-smi -> Prometheus)
Documentation=https://github.com/utkuozdemir/nvidia_gpu_exporter
After=network-online.target tailscaled.service nvidia-persistenced.service
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/nvidia_gpu_exporter \\
  --web.listen-address=${BIND_ADDR}:9835
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
UNIT
}

# --------------------------------------------------------------------------
# cAdvisor — container metrics. :8080 is the DGX dashboard, so :8081.
# --------------------------------------------------------------------------
install_cadvisor() {
  command -v docker >/dev/null || { echo "error: docker not found" >&2; exit 1; }
  log "installing cadvisor unit (${CADVISOR_IMAGE})"
  ${SUDO} tee /etc/systemd/system/cadvisor.service >/dev/null <<UNIT
[Unit]
Description=cAdvisor container metrics
After=docker.service tailscaled.service
Requires=docker.service

[Service]
ExecStartPre=-/usr/bin/docker rm -f cadvisor
ExecStart=/usr/bin/docker run --rm --name cadvisor \\
  -p ${BIND_ADDR}:8081:8080 \\
  -v /:/rootfs:ro -v /var/run:/var/run:ro -v /sys:/sys:ro \\
  -v /var/lib/docker/:/var/lib/docker:ro -v /dev/disk/:/dev/disk:ro \\
  --privileged --device=/dev/kmsg \\
  ${CADVISOR_IMAGE}
ExecStop=/usr/bin/docker stop cadvisor
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
UNIT
}

# --------------------------------------------------------------------------
# Alloy — journal + container logs to the ops Loki.
#
# The `deployment` label names one deployed unit, never a host class
# (user ruling 2026-09-15); on this box that is lmstudio / comfyui /
# dgx-dashboard / cc-mesh. Units that are the OS itself carry no `deployment`
# label at all — they are the host, and `host` already says which.
# --------------------------------------------------------------------------
install_alloy() {
  if [[ "$(/usr/local/bin/alloy --version 2>&1 | head -1 | awk '{print $3}')" == "v${ALLOY_VERSION}" ]]; then
    log "alloy ${ALLOY_VERSION} already installed"
  else
    log "installing alloy ${ALLOY_VERSION}"
    curl -fsSL -o "${TMP}/alloy.zip" \
      "https://github.com/grafana/alloy/releases/download/v${ALLOY_VERSION}/alloy-linux-${GOARCH}.zip"
    ${SUDO} apt-get install -y unzip >/dev/null 2>&1 || true
    unzip -oq "${TMP}/alloy.zip" -d "${TMP}"
    ${SUDO} install -m 0755 "${TMP}/alloy-linux-${GOARCH}" /usr/local/bin/alloy
  fi

  id -u alloy &>/dev/null || ${SUDO} useradd --system --no-create-home --shell /usr/sbin/nologin alloy
  ${SUDO} usermod -aG systemd-journal,docker alloy
  ${SUDO} mkdir -p /etc/alloy /var/lib/alloy
  ${SUDO} chown alloy:alloy /var/lib/alloy

  ${SUDO} tee /etc/alloy/config.alloy >/dev/null <<ALLOYCFG
// Generated by dev-env/scripts/hosts/dgx-observability-agents.sh (TODO 28-23).
logging {
  level = "info"
}

loki.write "ops" {
  endpoint {
    url = "${LOKI_PUSH_URL}"
  }
  external_labels = {
    host = "${HOST_LABEL}",
  }
}

// --- systemd journal ---
loki.relabel "journal" {
  forward_to = []
  rule {
    source_labels = ["__journal__systemd_unit"]
    target_label  = "unit"
  }
  rule {
    source_labels = ["__journal_syslog_identifier"]
    target_label  = "app"
  }
  // \`job\` from a rule, not the \`labels\` argument: since Alloy 1.19 the
  // journal source's own default ("loki.source.journal.<name>") wins over
  // \`labels\`, so the argument silently stopped taking effect.
  rule {
    target_label = "job"
    replacement  = "node-logs"
  }

  // deployment: one deployed unit, never a host class.
  rule {
    source_labels = ["__journal__systemd_unit"]
    regex         = "lmstudio\\\\.service|lms-dashboard\\\\.service"
    target_label  = "deployment"
    replacement   = "lmstudio"
  }
  rule {
    source_labels = ["__journal__systemd_unit"]
    regex         = "comfyui\\\\.service"
    target_label  = "deployment"
    replacement   = "comfyui"
  }
  rule {
    source_labels = ["__journal__systemd_unit"]
    regex         = "dgx-dashboard\\\\.service|dgx-dashboard-admin\\\\.service"
    target_label  = "deployment"
    replacement   = "dgx-dashboard"
  }
}

loki.source.journal "host" {
  forward_to    = [loki.write.ops.receiver]
  relabel_rules = loki.relabel.journal.rules
}

// --- docker containers ---
discovery.docker "local" {
  host             = "unix:///var/run/docker.sock"
  refresh_interval = "15s"
}

discovery.relabel "local" {
  targets = discovery.docker.local.targets
  rule {
    source_labels = ["__meta_docker_container_name"]
    regex         = "/(.*)"
    target_label  = "container"
  }
  rule {
    source_labels = ["__meta_docker_container_label_com_docker_compose_service"]
    target_label  = "service"
  }
  rule {
    source_labels = ["__meta_docker_container_name"]
    regex         = "/claude-mesh.*"
    target_label  = "deployment"
    replacement   = "cc-mesh"
  }
  rule {
    source_labels = ["__meta_docker_container_name"]
    regex         = "/open-webui"
    target_label  = "deployment"
    replacement   = "open-webui"
  }
}

loki.source.docker "local" {
  host       = "unix:///var/run/docker.sock"
  targets    = discovery.relabel.local.output
  forward_to = [loki.write.ops.receiver]
  labels     = {
    job = "docker",
  }
}
ALLOYCFG

  ${SUDO} tee /etc/systemd/system/alloy.service >/dev/null <<UNIT
[Unit]
Description=Grafana Alloy (journal + container logs -> ops Loki)
After=network-online.target tailscaled.service docker.service
Wants=network-online.target

[Service]
User=alloy
Group=alloy
SupplementaryGroups=systemd-journal docker
ExecStart=/usr/local/bin/alloy run /etc/alloy/config.alloy \\
  --storage.path=/var/lib/alloy \\
  --server.http.listen-addr=127.0.0.1:12345
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
UNIT
}

install_node_exporter
install_gpu_exporter
install_cadvisor
install_alloy

log "reloading systemd and starting units"
${SUDO} systemctl daemon-reload
${SUDO} systemctl enable --now node_exporter.service nvidia_gpu_exporter.service cadvisor.service alloy.service
${SUDO} systemctl restart node_exporter.service nvidia_gpu_exporter.service cadvisor.service alloy.service

log "status"
${SUDO} systemctl --no-pager --lines=0 status \
  node_exporter.service nvidia_gpu_exporter.service cadvisor.service alloy.service || true

log "scrape targets for the ops node's Prometheus"
printf '  node_exporter        %s:9100\n  nvidia_gpu_exporter  %s:9835\n  cadvisor             %s:8081\n' \
  "${BIND_ADDR}" "${BIND_ADDR}" "${BIND_ADDR}"
