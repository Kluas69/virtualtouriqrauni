import { defineConfig } from 'vite';

export default defineConfig({
  base: './',
  publicDir: 'public',
  build: {
    outDir: '../../build/web/threejs',
    assetsDir: 'assets',
    sourcemap: false,
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          'three-core': ['three'],
          'three-loaders': [
            'three/examples/jsm/loaders/GLTFLoader.js',
            'three/examples/jsm/loaders/DRACOLoader.js'
          ],
          'three-controls': [
            'three/examples/jsm/controls/PointerLockControls.js'
          ],
          'three-utils': [
            'three/examples/jsm/utils/BufferGeometryUtils.js'
          ]
        }
      }
    },
    terserOptions: {
      compress: {
        drop_console: false,
        drop_debugger: true
      }
    }
  },
  server: {
    port: 3000,
    cors: true,
    host: true,
    fs: {
      allow: ['..']
    },
    middlewareMode: false,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }
  },
  optimizeDeps: {
    include: ['three', 'stats.js']
  },
  define: {
    __DEV__: JSON.stringify(process.env.NODE_ENV === 'development')
  },
  assetsInclude: ['**/*.glb', '**/*.gltf'],
  plugins: [
    {
      name: 'configure-server',
      configureServer(server) {
        server.middlewares.use('/assets', (req, res, next) => {
          if (req.url.endsWith('.glb')) {
            res.setHeader('Content-Type', 'application/octet-stream');
          } else if (req.url.endsWith('.gltf')) {
            res.setHeader('Content-Type', 'application/json');
          }
          next();
        });
      }
    }
  ]
});