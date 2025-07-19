#!/usr/bin/env python3
"""
JSON Task Tree Editor Startup Script
"""

import http.server
import socketserver
import webbrowser
import os
import sys
from pathlib import Path

def start_server(port=8000):
    """Start HTTP server"""
    
    # Get current script directory
    current_dir = Path(__file__).parent.absolute()
    
    # Change to json_editor directory
    os.chdir(current_dir)
    
    # Create HTTP server
    handler = http.server.SimpleHTTPRequestHandler
    
    try:
        with socketserver.TCPServer(("", port), handler) as httpd:
            print(f"🚀 JSON Task Tree Editor started!")
            print(f"📁 Service directory: {current_dir}")
            print(f"🌐 Access URL: http://localhost:{port}")
            print(f"📝 Press Ctrl+C to stop server")
            print("-" * 50)
            
            # Auto open browser
            webbrowser.open(f'http://localhost:{port}')
            
            # Start server
            httpd.serve_forever()
            
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"❌ Port {port} is already in use, trying port {port + 1}")
            start_server(port + 1)
        else:
            print(f"❌ Failed to start server: {e}")
            sys.exit(1)
    except KeyboardInterrupt:
        print("\n👋 Server stopped")
        sys.exit(0)

if __name__ == "__main__":
    print("🎯 JSON Task Tree Editor")
    print("=" * 50)
    start_server() 