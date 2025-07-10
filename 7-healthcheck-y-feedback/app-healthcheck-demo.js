const express = require('express');
const app = express();

// Estado de la aplicación
let isHealthy = true;
let dbConnected = true;
let startTime = Date.now();

// Middleware para parsing JSON
app.use(express.json());

// Endpoint principal
app.get('/', (req, res) => {
    res.json({ 
        message: 'API de demostración de healthchecks funcionando',
        timestamp: new Date().toISOString(),
        uptime: Math.floor((Date.now() - startTime) / 1000)
    });
});

// Endpoint de health completo
app.get('/health', (req, res) => {
    const uptime = Math.floor((Date.now() - startTime) / 1000);
    const memUsage = process.memoryUsage();
    
    // Verificaciones múltiples
    const checks = {
        application: {
            status: isHealthy ? 'healthy' : 'unhealthy',
            uptime: uptime
        },
        database: {
            status: dbConnected ? 'healthy' : 'unhealthy',
            connection: dbConnected
        },
        memory: {
            status: memUsage.heapUsed < (100 * 1024 * 1024) ? 'healthy' : 'warning',
            heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + 'MB',
            heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + 'MB'
        },
        startup: {
            status: uptime > 5 ? 'healthy' : 'starting',
            gracePeriod: uptime <= 5
        }
    };
    
    // Determinar estado general
    const allHealthy = Object.values(checks).every(check => 
        check.status === 'healthy'
    );
    
    const hasWarnings = Object.values(checks).some(check => 
        check.status === 'warning'
    );
    
    const hasUnhealthy = Object.values(checks).some(check => 
        check.status === 'unhealthy'
    );
    
    let overallStatus = 'healthy';
    let statusCode = 200;
    
    if (hasUnhealthy) {
        overallStatus = 'unhealthy';
        statusCode = 503;
    } else if (hasWarnings) {
        overallStatus = 'degraded';
        statusCode = 200; // 200 para degraded, 503 para unhealthy
    }
    
    res.status(statusCode).json({
        status: overallStatus,
        timestamp: new Date().toISOString(),
        uptime: uptime,
        version: '1.0.0',
        environment: process.env.NODE_ENV || 'development',
        checks: checks
    });
});

// Endpoint de health simple (para healthcheck básico)
app.get('/health/simple', (req, res) => {
    if (isHealthy && dbConnected) {
        res.status(200).json({ status: 'healthy' });
    } else {
        res.status(503).json({ status: 'unhealthy' });
    }
});

// Endpoints para simular problemas (solo para testing)
app.post('/break', (req, res) => {
    isHealthy = false;
    console.log('[DEMO] Simulando fallo de aplicación');
    res.json({ 
        message: 'Aplicación marcada como unhealthy - healthcheck fallará',
        timestamp: new Date().toISOString()
    });
});

app.post('/break/db', (req, res) => {
    dbConnected = false;
    console.log('[DEMO] Simulando fallo de base de datos');
    res.json({ 
        message: 'Conexión a base de datos simulada como rota',
        timestamp: new Date().toISOString()
    });
});

app.post('/fix', (req, res) => {
    isHealthy = true;
    dbConnected = true;
    console.log('[DEMO] Restaurando funcionamiento normal');
    res.json({ 
        message: 'Aplicación restaurada - healthcheck volverá a pasar',
        timestamp: new Date().toISOString()
    });
});

// Endpoint de información del sistema
app.get('/info', (req, res) => {
    res.json({
        pid: process.pid,
        platform: process.platform,
        nodeVersion: process.version,
        memory: process.memoryUsage(),
        uptime: process.uptime(),
        startTime: new Date(startTime).toISOString()
    });
});

// Middleware de manejo de errores
app.use((err, req, res, next) => {
    console.error('[ERROR]', err.message);
    res.status(500).json({ 
        status: 'error',
        message: 'Error interno del servidor',
        timestamp: new Date().toISOString()
    });
});

// Configuración del servidor
const port = process.env.PORT || 3000;
const host = process.env.HOST || '0.0.0.0';

app.listen(port, host, () => {
    console.log(`[DEMO] Aplicación de healthcheck demo iniciada`);
    console.log(`[DEMO] Servidor escuchando en http://${host}:${port}`);
    console.log(`[DEMO] Endpoints disponibles:`);
    console.log(`[DEMO]   GET  / - Endpoint principal`);
    console.log(`[DEMO]   GET  /health - Healthcheck completo`);
    console.log(`[DEMO]   GET  /health/simple - Healthcheck simple`);
    console.log(`[DEMO]   GET  /info - Información del sistema`);
    console.log(`[DEMO]   POST /break - Simular fallo general`);
    console.log(`[DEMO]   POST /break/db - Simular fallo de DB`);
    console.log(`[DEMO]   POST /fix - Restaurar funcionamiento`);
    console.log(`[DEMO] Listo para demostraciones de healthcheck`);
}); 