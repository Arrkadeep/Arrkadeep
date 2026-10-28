#!/usr/bin/env bash
# Installs open-source OSINT tools under $OSINT_HOME (default: ~/osint).
# Requires: python3, git, curl, go. theHarvester also needs uv (installed via pip if missing).
set -euo pipefail

OSINT_HOME="${OSINT_HOME:-$HOME/osint}"
VENV="$OSINT_HOME/venv"
BIN="$OSINT_HOME/bin"
mkdir -p "$OSINT_HOME" "$BIN"

# Python tools: maigret, sherlock, holehe, h8mail
python3 -m venv "$VENV"
for pkg in maigret sherlock-project holehe h8mail; do
  "$VENV/bin/pip" install -q "$pkg"
done

# SpiderFoot (not on PyPI). Relax the lxml pin so it installs on newer Python.
[ -d "$OSINT_HOME/spiderfoot" ] || git clone -q --depth 1 https://github.com/smicallef/spiderfoot "$OSINT_HOME/spiderfoot"
sed 's/^lxml.*/lxml/' "$OSINT_HOME/spiderfoot/requirements.txt" > "$OSINT_HOME/sf-req.txt"
"$VENV/bin/pip" install -q -r "$OSINT_HOME/sf-req.txt"

# Recon-ng
[ -d "$OSINT_HOME/recon-ng" ] || git clone -q --depth 1 https://github.com/lanmaster53/recon-ng "$OSINT_HOME/recon-ng"
"$VENV/bin/pip" install -q -r "$OSINT_HOME/recon-ng/REQUIREMENTS"

# theHarvester (requires Python >= 3.14, installed through uv)
command -v uv >/dev/null || python3 -m pip install -q uv
[ -d "$OSINT_HOME/theHarvester" ] || git clone -q --depth 1 https://github.com/laramies/theHarvester "$OSINT_HOME/theHarvester"
uv tool install --python 3.14 "$OSINT_HOME/theHarvester"

# Amass
GOBIN="$BIN" go install github.com/owasp-amass/amass/v4/...@latest

# PhoneInfoga (release binary)
mkdir -p "$OSINT_HOME/phoneinfoga"
curl -sL https://github.com/sundowndev/phoneinfoga/releases/latest/download/phoneinfoga_Linux_x86_64.tar.gz \
  | tar -xz -C "$OSINT_HOME/phoneinfoga"

cat <<EOF

Installed under $OSINT_HOME
  maigret / sherlock / holehe / h8mail : $VENV/bin/<tool>
  spiderfoot : cd $OSINT_HOME/spiderfoot && $VENV/bin/python sf.py -l 127.0.0.1:5001
  recon-ng   : cd $OSINT_HOME/recon-ng && $VENV/bin/python recon-ng
  theHarvester : theHarvester -d <domain> -b all   (uv tools dir: ~/.local/bin)
  amass      : $BIN/amass
  phoneinfoga: $OSINT_HOME/phoneinfoga/phoneinfoga

Not scripted: Maltego CE (GUI, needs account), HIBP / Shodan / Censys (API keys).
EOF
