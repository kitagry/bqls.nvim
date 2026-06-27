#!/bin/sh
set -e

case "$(uname -s)" in
  Darwin)
    case "$(uname -m)" in
      arm64)   PLATFORM="darwin_arm64" ;;
      x86_64)  PLATFORM="darwin_amd64" ;;
      *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
    esac
    ;;
  Linux)
    case "$(uname -m)" in
      x86_64)  PLATFORM="linux_amd64" ;;
      aarch64) PLATFORM="linux_arm64" ;;
      *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
    esac
    ;;
  *) echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

for dep in curl tar; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "ERROR: $dep is required"
    exit 1
  fi
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Fetching latest bqls release..."
TAG=$(curl -fsSL "https://api.github.com/repos/kitagry/bqls/releases/latest" \
  | grep '"tag_name"' \
  | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

if [ -z "$TAG" ]; then
  echo "ERROR: Failed to fetch latest release tag"
  exit 1
fi

VERSION="${TAG#v}"
URL="https://github.com/kitagry/bqls/releases/download/${TAG}/bqls_${VERSION}_${PLATFORM}.tar.gz"
TMPFILE="$(mktemp)"

echo "Downloading bqls ${TAG} for ${PLATFORM}..."
curl -fsSL "$URL" -o "$TMPFILE"

mkdir -p "$SCRIPT_DIR/bin"
tar -xzf "$TMPFILE" -C "$SCRIPT_DIR/bin" bqls
chmod +x "$SCRIPT_DIR/bin/bqls"
rm -f "$TMPFILE"

echo "bqls ${TAG} installed to $SCRIPT_DIR/bin/bqls"
