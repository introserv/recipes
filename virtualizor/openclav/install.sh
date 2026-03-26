#!/bin/bash

hostname='app.introserv.cloud'
ip=$(hostname -I| cut -d " " -f 1)
email='admin@email.local'
tmp=$(mktemp -d)
DEBIAN_FRONTEND=noninteractive
apt -qq update; apt -y -qq install curl caddy
curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash -s -- --no-onboard --prefix /opt/openclaw --version latest
export PATH="/opt/openclaw/bin:$PATH"
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
mkdir -p /root/.config/systemd/user/

cat > ~/.config/systemd/user/openclaw-gateway.service <<'EOF'
[Unit]
Description=OpenClaw Gateway (v2026.3.23-2)
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/opt/openclaw/tools/node-v22.22.0/bin/node /opt/openclaw/lib/node_modules/openclaw/dist/entry.js gateway --port 18789
Restart=always
RestartSec=5
TimeoutStopSec=30
TimeoutStartSec=30
SuccessExitStatus=0 143
KillMode=control-group
Environment=HOME=/root
Environment=TMPDIR=/tmp
Environment=PATH=/opt/openclaw/tools/node-v22.22.0/bin:/root/.local/bin:/root/.npm-global/bin:/root/bin:/root/.volta/bin:/root/.asdf/shims:/root/.bun/bin:/root/.nvm/current/bin:/root/.fnm/current/bin:/root/.local/share/pnpm:/usr/local/bin:/usr/bin:/bin
Environment=OPENCLAW_GATEWAY_PORT=18789
Environment=OPENCLAW_SYSTEMD_UNIT=openclaw-gateway.service
Environment="OPENCLAW_WINDOWS_TASK_NAME=OpenClaw Gateway"
Environment=OPENCLAW_SERVICE_MARKER=openclaw
Environment=OPENCLAW_SERVICE_KIND=gateway
Environment=OPENCLAW_SERVICE_VERSION=2026.3.23-2

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload && systemctl --user enable --now openclaw-gateway.service
#openclaw config set gateway.bind loopback
#openclaw gateway restart

exit 0
