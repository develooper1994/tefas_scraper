#!/bin/bash
# TEFAS Scraper Gemini CLI Extension Installer

set -e

echo "🚀 TEFAS Scraper Extension Installer"
echo "======================================"

# Determine extension directory
EXTENSION_DIR="$HOME/.gemini/extensions/tefas-scraper"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get absolute path to mcp_server.py
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MCP_SERVER_PATH="$REPO_ROOT/mcp_server.py"
VENV_PYTHON="$REPO_ROOT/venv/bin/python"

# Check if virtual environment exists
if [ ! -f "$VENV_PYTHON" ]; then
    echo "❌ Error: Virtual environment not found at $REPO_ROOT/venv"
    echo "Please run: cd $REPO_ROOT && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
    exit 1
fi

# Check if mcp_server.py exists
if [ ! -f "$MCP_SERVER_PATH" ]; then
    echo "❌ Error: mcp_server.py not found at $MCP_SERVER_PATH"
    exit 1
fi

# Create extension directory
echo "📁 Creating extension directory..."
mkdir -p "$EXTENSION_DIR"

# Copy extension files
echo "📋 Copying extension files..."
cp "$SCRIPT_DIR/gemini-extension.json.template" "$EXTENSION_DIR/gemini-extension.json"
cp "$SCRIPT_DIR/GEMINI.md" "$EXTENSION_DIR/GEMINI.md"
cp "$SCRIPT_DIR/EXTENSION_README.md" "$EXTENSION_DIR/README.md"

# Update paths in gemini-extension.json
echo "🔧 Updating paths in gemini-extension.json..."
sed -i "s|VENV_PYTHON_PATH|$VENV_PYTHON|g" "$EXTENSION_DIR/gemini-extension.json"
sed -i "s|MCP_SERVER_PATH|$MCP_SERVER_PATH|g" "$EXTENSION_DIR/gemini-extension.json"

echo ""
echo "✅ Installation complete!"
echo ""
echo "Extension installed to: $EXTENSION_DIR"
echo ""
echo "📝 Verify installation:"
echo "   gemini extensions list | grep tefas"
echo ""
echo "🧪 Test it:"
echo "   gemini \"TLY fonu için son 1 aylık analiz verilerini getir\" -y"
echo ""
