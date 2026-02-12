#!/bin/bash
# Export Xochi to HTML5 for web testing

echo "🎮 Exporting Xochi to HTML5..."

# Create export directory
mkdir -p web_build

# Export to HTML5 (requires Godot export templates)
godot --headless --export-release "HTML5" web_build/index.html

if [ $? -eq 0 ]; then
    echo "✅ Export complete!"
    echo "📁 Files in: web_build/"
    echo ""
    echo "To test locally, run:"
    echo "  cd web_build"
    echo "  python3 -m http.server 8080"
    echo ""
    echo "Then open: http://localhost:8080"
else
    echo "❌ Export failed. Make sure HTML5 export templates are installed."
    echo ""
    echo "To install templates:"
    echo "1. Open Godot Editor"
    echo "2. Go to Editor → Manage Export Templates"
    echo "3. Download templates for your Godot version"
fi
