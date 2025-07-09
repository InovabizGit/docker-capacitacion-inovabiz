const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const { Pool } = require('pg');
const redis = require('redis');
const client = require('prom-client');

const app = express();

// Middleware de seguridad y optimización
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(morgan('combined'));

// Configuración de métricas Prometheus
const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
  registers: [register]
});

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

const activeConnections = new client.Gauge({
  name: 'active_connections',
  help: 'Number of active connections',
  registers: [register]
});

// Configuración de base de datos
const dbPool = new Pool({
  host: process.env.DB_HOST || 'database',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'prodapp',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  max: parseInt(process.env.PROD_DB_POOL_SIZE) || 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Configuración de Redis
let redisClient;
try {
  redisClient = redis.createClient({
    url: process.env.REDIS_URL || 'redis://cache:6379',
    retry_strategy: (options) => {
      if (options.error && options.error.code === 'ECONNREFUSED') {
        return new Error('Redis server refused connection');
      }
      if (options.total_retry_time > 1000 * 60 * 60) {
        return new Error('Retry time exhausted');
      }
      return Math.min(options.attempt * 100, 3000);
    }
  });
  redisClient.connect().catch(console.error);
} catch (error) {
  console.warn('Redis connection failed:', error.message);
}

// Middleware para métricas
app.use((req, res, next) => {
  const start = Date.now();
  activeConnections.inc();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route?.path || req.path;
    
    httpRequestDuration
      .labels(req.method, route, res.statusCode.toString())
      .observe(duration);
    
    httpRequestsTotal
      .labels(req.method, route, res.statusCode.toString())
      .inc();
    
    activeConnections.dec();
  });
  
  next();
});

// Health check endpoint
app.get('/health', async (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    server: process.env.HOSTNAME || 'unknown',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    services: {}
  };

  // Check database
  try {
    await dbPool.query('SELECT 1');
    health.services.database = 'healthy';
  } catch (error) {
    health.services.database = 'unhealthy';
    health.status = 'degraded';
  }

  // Check Redis
  try {
    if (redisClient && redisClient.isReady) {
      await redisClient.ping();
      health.services.redis = 'healthy';
    } else {
      health.services.redis = 'disconnected';
    }
  } catch (error) {
    health.services.redis = 'unhealthy';
  }

  const statusCode = health.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(health);
});

// Endpoint de métricas para Prometheus
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  const metrics = await register.metrics();
  res.end(metrics);
});

// API endpoints
app.get('/api/users', async (req, res) => {
  try {
    // Intentar obtener desde cache
    let users;
    if (redisClient && redisClient.isReady) {
      const cached = await redisClient.get('users');
      if (cached) {
        users = JSON.parse(cached);
      }
    }

    // Si no hay cache, obtener de BD
    if (!users) {
      const result = await dbPool.query('SELECT id, name, email FROM users ORDER BY id');
      users = result.rows;
      
      // Guardar en cache por 5 minutos
      if (redisClient && redisClient.isReady) {
        await redisClient.setEx('users', 300, JSON.stringify(users));
      }
    }

    res.json({
      users: users,
      server: process.env.HOSTNAME || 'unknown',
      cached: !!cached,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      server: process.env.HOSTNAME || 'unknown'
    });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const { name, email } = req.body;
    
    if (!name || !email) {
      return res.status(400).json({ error: 'Name and email are required' });
    }

    const result = await dbPool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [name, email]
    );

    // Invalidar cache
    if (redisClient && redisClient.isReady) {
      await redisClient.del('users');
    }

    res.status(201).json({
      user: result.rows[0],
      server: process.env.HOSTNAME || 'unknown'
    });
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      server: process.env.HOSTNAME || 'unknown'
    });
  }
});

app.get('/api/info', (req, res) => {
  res.json({
    name: 'Production API',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    server: process.env.HOSTNAME || 'unknown',
    timestamp: new Date().toISOString(),
    features: ['metrics', 'health-checks', 'caching', 'database']
  });
});

// Simulador de carga para testing
app.get('/api/stress', (req, res) => {
  const duration = parseInt(req.query.duration) || 100;
  const start = Date.now();
  
  while (Date.now() - start < duration) {
    // Simular trabajo CPU intensivo
    Math.random() * Math.random();
  }
  
  res.json({
    message: 'Stress test completed',
    duration: duration,
    server: process.env.HOSTNAME || 'unknown'
  });
});

// Error handler
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    error: 'Internal server error',
    server: process.env.HOSTNAME || 'unknown'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not found',
    path: req.originalUrl,
    server: process.env.HOSTNAME || 'unknown'
  });
});

// Inicialización
const PORT = process.env.PORT || 3000;

// Inicializar base de datos
async function initDatabase() {
  try {
    await dbPool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Insertar datos de ejemplo si no existen
    const result = await dbPool.query('SELECT COUNT(*) FROM users');
    if (parseInt(result.rows[0].count) === 0) {
      await dbPool.query(`
        INSERT INTO users (name, email) VALUES 
        ('Admin User', 'admin@example.com'),
        ('Test User', 'test@example.com'),
        ('Demo User', 'demo@example.com')
      `);
    }
    
    console.log('✅ Database initialized');
  } catch (error) {
    console.error('❌ Database initialization failed:', error.message);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully...');
  
  if (redisClient) {
    await redisClient.quit();
  }
  
  await dbPool.end();
  process.exit(0);
});

// Iniciar servidor
app.listen(PORT, async () => {
  console.log(`🚀 API server running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🏥 Health check: http://localhost:${PORT}/health`);
  console.log(`📈 Metrics: http://localhost:${PORT}/metrics`);
  
  await initDatabase();
});

module.exports = app; 