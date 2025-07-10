const express = require('express');
const app = express();

app.get('/', (req, res) => {
    res.json({
        message: 'Security Demo App',
        user_id: process.getuid(),
        group_id: process.getgid(),
        user_name: process.env.USER || 'unknown',
        working_directory: process.cwd(),
        node_version: process.version
    });
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Running as UID: ${process.getuid()}, GID: ${process.getgid()}`);
}); 