#!/usr/bin/env bash
# Install helm and eksctl for use in AWS CloudShell or any environment where they are missing.
# In CloudShell, installs to $HOME/bin so binaries persist across sessions.

set -e
BIN_DIR="${BIN_DIR:-$HOME/bin}"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

echo "Installing prerequisites to $BIN_DIR (add to PATH if needed: export PATH=\"$BIN_DIR:\$PATH\")"

# Install eksctl
if ! command -v eksctl >/dev/null 2>&1; then
  echo "Installing eksctl..."
  EKSCTL_ARCH=amd64
  [ "$(uname -m)" = "aarch64" ] && EKSCTL_ARCH=arm64
  curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_${EKSCTL_ARCH}.tar.gz" | tar xz -C /tmp
  mv /tmp/eksctl "$BIN_DIR/"
  chmod +x "$BIN_DIR/eksctl"
  echo "  eksctl installed."
else
  echo "eksctl already installed: $(command -v eksctl)"
fi

# Install helm
if ! command -v helm >/dev/null 2>&1; then
  echo "Installing helm..."
  HELM_ARCH=amd64
  [ "$(uname -m)" = "aarch64" ] && HELM_ARCH=arm64
  HELM_VER="v3.16.3"
  curl -sL "https://get.helm.sh/helm-${HELM_VER}-linux-${HELM_ARCH}.tar.gz" | tar xz -C /tmp
  mv /tmp/linux-${HELM_ARCH}/helm "$BIN_DIR/"
  chmod +x "$BIN_DIR/helm"
  echo "  helm installed."
else
  echo "helm already installed: $(command -v helm)"
fi

echo ""
echo "Done. Ensure PATH includes $BIN_DIR:"
echo "  export PATH=\"$BIN_DIR:\$PATH\""
echo ""
echo "Then re-run your chapter script (e.g. ./scripts-by-chapter/chapter-2.sh)."
