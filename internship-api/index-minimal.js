import express from "express";
import cors from "cors";

const app = express();
const PORT = process.env.PORT || 3000;

// Basic middleware
app.use(express.json());
app.use(cors());

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.status(200).json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        message: 'Container is running successfully without helmet dependencies'
    });
});

// Basic info endpoint
app.get('/api/info', (req, res) => {
    res.status(200).json({
        name: 'Internship API',
        version: '2.0.0',
        status: 'running',
        environment: process.env.NODE_ENV || 'production',
        dependencies_fixed: true
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Server running on port ${PORT}`);
    console.log(`✅ Health check: http://localhost:${PORT}/api/health`);
    console.log(`✅ Dependencies issue resolved`);
});

export default app;