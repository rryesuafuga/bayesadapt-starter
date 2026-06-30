#!/usr/bin/env bash
set -euo pipefail

echo ">> Installing Claude Code (native installer, no Node.js required)..."
curl -fsSL https://claude.ai/install.sh | bash \
  || echo "!! Claude Code install skipped. Install later with: curl -fsSL https://claude.ai/install.sh | bash"

# Make the claude binary available on PATH for this and future shells
if ! grep -q '.local/bin' "${HOME}/.bashrc" 2>/dev/null; then
  echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> "${HOME}/.bashrc"
fi

if [ -f renv.lock ]; then
  echo ">> Restoring R packages from renv.lock..."
  R -q -e 'renv::restore(prompt = FALSE)'
else
  echo ">> No renv.lock yet - Claude Code will create it when it scaffolds the golem package."
fi

echo ""
echo "============================================================"
echo " Codespace ready."
echo "  - RStudio Server : open the forwarded port 8787"
echo "  - Claude Code    : run 'claude' (first run opens browser auth)"
echo "  - Then tell Claude Code:  Scaffold the golem MVP per CLAUDE.md"
echo "============================================================"
