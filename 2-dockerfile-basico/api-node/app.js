// API básica Node.js para capacitación Docker
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware para parsear JSON
app.use(express.json());

// Endpoint principal
app.get('/', (req, res) => {
  res.json({ 
    message: 'Hello World desde Docker!',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'production',
    timestamp: new Date().toISOString(),
    container_hostname: require('os').hostname()
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    timestamp: new Date().toISOString()
  });
});

// Info del sistema
app.get('/info', (req, res) => {
  res.json({
    node_version: process.version,
    platform: process.platform,
    architecture: process.arch,
    hostname: require('os').hostname(),
    environment: process.env.NODE_ENV || 'production',
    port: PORT
  });
});

// Endpoint para variables de entorno
app.get('/env', (req, res) => {
  res.json({
    NODE_ENV: process.env.NODE_ENV,
    PORT: process.env.PORT,
    HOSTNAME: process.env.HOSTNAME,
    // Solo mostrar variables que no sean sensibles
    env_count: Object.keys(process.env).length
  });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`Servidor ejecutándose en puerto ${PORT}`);
  console.log(`Entorno: ${process.env.NODE_ENV || 'production'}`);
  console.log(`Hostname: ${require('os').hostname()}`);
});

// Contenido pendiente de completar 