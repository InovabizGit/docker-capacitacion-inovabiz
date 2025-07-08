// API optimizada Node.js para capacitación Docker
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware para parsear JSON
app.use(express.json());

// Endpoint principal con información de optimización
app.get('/', (req, res) => {
  res.json({ 
    message: 'Hello World desde Docker Optimizado!',
    version: '2.0.0',
    optimized: true,
    environment: process.env.NODE_ENV || 'production',
    timestamp: new Date().toISOString(),
    container_hostname: require('os').hostname(),
    process_info: {
      pid: process.pid,
      platform: process.platform,
      node_version: process.version
    }
  });
});

// Health check mejorado
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK',
    optimized: true,
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    timestamp: new Date().toISOString()
  });
});

// Info del sistema optimizado
app.get('/info', (req, res) => {
  res.json({
    api_version: '2.0.0',
    optimized: true,
    node_version: process.version,
    platform: process.platform,
    architecture: process.arch,
    hostname: require('os').hostname(),
    environment: process.env.NODE_ENV || 'production',
    port: PORT,
    user_info: {
      uid: process.getuid(),
      gid: process.getgid()
    }
  });
});

// Endpoint para métricas de optimización
app.get('/metrics', (req, res) => {
  res.json({
    optimizations: {
      base_image: 'node:18-alpine',
      multistage_build: true,
      non_root_user: true,
      production_deps_only: true
    },
    performance: {
      startup_time: process.uptime(),
      memory_usage: process.memoryUsage(),
      pid: process.pid
    },
    security: {
      user_id: process.getuid(),
      group_id: process.getgid(),
      non_root: process.getuid() !== 0
    }
  });
});

// Endpoint para variables de entorno (solo info no sensible)
app.get('/env', (req, res) => {
  res.json({
    NODE_ENV: process.env.NODE_ENV,
    PORT: process.env.PORT,
    HOSTNAME: process.env.HOSTNAME,
    npm_config: {
      loglevel: process.env.NPM_CONFIG_LOGLEVEL,
      fund: process.env.NPM_CONFIG_FUND,
      audit: process.env.NPM_CONFIG_AUDIT
    },
    env_count: Object.keys(process.env).length
  });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`Servidor optimizado ejecutándose en puerto ${PORT}`);
  console.log(`Entorno: ${process.env.NODE_ENV || 'production'}`);
  console.log(`Usuario: UID=${process.getuid()}, GID=${process.getgid()}`);
  console.log(`Hostname: ${require('os').hostname()}`);
});

// Contenido pendiente de completar 