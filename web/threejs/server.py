#!/usr/bin/env python3
"""
Simple HTTP Server for Three.js Classroom Viewer Testing
Serves files with proper CORS headers and MIME types
"""

import http.server
import socketserver
import os
import sys
from urllib.parse import urlparse

class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP Request Handler with CORS support"""
    
    def end_headers(self):
        """Add CORS headers to all responses"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        super().end_headers()
    
    def do_OPTIONS(self):
        """Handle preflight OPTIONS requests"""
        self.send_response(200)
        self.end_headers()
    
    def guess_type(self, path):
        """Enhanced MIME type guessing"""
        # Custom MIME types for Three.js files
        if path.endswith('.glb'):
            return 'model/gltf-binary'
        elif path.endswith('.gltf'):
            return 'model/gltf+json'
        elif path.endswith('.js'):
            return 'application/javascript'
        elif path.endswith('.mjs'):
            return 'application/javascript'
        elif path.endswith('.wasm'):
            return 'application/wasm'
        
        # Fall back to default behavior
        return super().guess_type(path)
    
    def log_message(self, format, *args):
        """Enhanced logging with color coding"""
        message = format % args
        
        # Color coding for different request types (Windows-safe)
        if 'GET' in message:
            if '.glb' in message or '.gltf' in message:
                print(f"[MODEL] {message}")  # Models
            elif '.js' in message:
                print(f"[SCRIPT] {message}")  # Scripts
            elif '.html' in message:
                print(f"[PAGE] {message}")  # HTML
            else:
                print(f"[FILE] {message}")  # Other files
        elif 'OPTIONS' in message:
            print(f"[CORS] {message}")  # CORS
        else:
            print(f"[WEB] {message}")

def find_available_port(start_port=3000, max_attempts=10):
    """Find an available port starting from start_port"""
    import socket
    
    for port in range(start_port, start_port + max_attempts):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('localhost', port))
                return port
        except OSError:
            continue
    
    raise RuntimeError(f"Could not find available port in range {start_port}-{start_port + max_attempts}")

def main():
    """Main server function"""
    # Change to the web/threejs directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    # Find available port
    try:
        port = find_available_port(3000)
    except RuntimeError as e:
        print(f"ERROR: {e}")
        sys.exit(1)
    
    # Create server
    handler = CORSHTTPRequestHandler
    httpd = socketserver.TCPServer(("", port), handler)
    
    print("Three.js Classroom Viewer Development Server")
    print("=" * 50)
    print(f"Server running at: http://localhost:{port}")
    print(f"Serving directory: {os.getcwd()}")
    print()
    print("Available Test Pages:")
    print(f"   * Simple Viewer:  http://localhost:{port}/simple.html")
    print(f"   * Full Viewer:    http://localhost:{port}/index.html")
    print()
    print("Model Paths (will be tested automatically):")
    print("   * ./assets/models/classroom.glb")
    print("   * ../assets/models/classroom.glb")
    print("   * ../../assets/models/classroom.glb")
    print()
    print("Controls:")
    print("   * WASD: Move around")
    print("   * Mouse: Look around")
    print("   * Click: Lock pointer for first-person view")
    print("   * ESC: Unlock pointer")
    print("   * Space: Jump")
    print("   * Shift: Run")
    print()
    print("Special Features:")
    print("   * Bee Mode: 2mm wide character (fits through any gap)")
    print("   * Ant Mode: 1mm wide character (microscopic navigation)")
    print("   * Smart model loading with multiple path fallbacks")
    print("   * Comprehensive error handling and fallback scenes")
    print()
    print("Press Ctrl+C to stop the server")
    print("=" * 50)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
        httpd.shutdown()

if __name__ == "__main__":
    main()