import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import sql from "mssql";
import multer from 'multer';
const upload = multer({ dest: 'uploads/' });
import fs from 'fs';
import * as pdfParse from 'pdf-parse';
import path from 'path';
import { fileURLToPath } from 'url';

// Get __dirname equivalent for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
// pdf-parse v2.x exports PDFParse class, not a default function
import { TextAnalyticsClient, AzureKeyCredential } from "@azure/ai-text-analytics";

const client = new TextAnalyticsClient(
  process.env.AZURE_LANGUAGE_ENDPOINT,
  new AzureKeyCredential(process.env.AZURE_LANGUAGE_KEY)
);

// Application Insights (lightweight instrumentation)
// Avoid top-level await; initialize asynchronously without blocking startup.
try {
  (async () => {
    const mod = await import('applicationinsights');
    const ai = mod.default || mod;

    const connStr = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
    const ikey = process.env.APPINSIGHTS_INSTRUMENTATIONKEY;

    // Prefer connection string if provided; else use instrumentation key
    if (connStr) {
      // applicationinsights reads connection string from env var
      process.env.APPLICATIONINSIGHTS_CONNECTION_STRING = connStr;
      ai.setup()
        .setAutoCollectRequests(true)
        .setAutoCollectPerformance(true)
        .setAutoCollectExceptions(true)
        .setAutoCollectDependencies(true)
        .setSendLiveMetrics(true)
        .start();
    } else if (ikey) {
      ai.setup(ikey)
        .setAutoCollectRequests(true)
        .setAutoCollectPerformance(true)
        .setAutoCollectExceptions(true)
        .setAutoCollectDependencies(true)
        .setSendLiveMetrics(true)
        .start();
    } else {
      console.warn('App Insights: no connection string or instrumentation key set.');
      return;
    }

    // Optional: set role name for clearer grouping in Azure Portal
    try {
      const client = ai.defaultClient;
      const { cloudRole } = client.context.keys;
      client.context.tags[cloudRole] = 'internship-api';
      client.trackEvent({ name: 'server_start' });
    } catch {}

    console.log('Application Insights started');
  })().catch(err => console.warn('App Insights init failed:', err.message || err));
} catch (err) {
  // do not block startup if appinsights is unavailable
  console.warn('App Insights not initialized:', err.message || err);
}

import {
  BlobServiceClient,
  StorageSharedKeyCredential,
  BlobSASPermissions,
  generateBlobSASQueryParameters
} from "@azure/storage-blob";
import dotenv from "dotenv";
import fetch from "node-fetch";
import nodemailer from "nodemailer";
dotenv.config();

// Centralized JWT secret handling
const JWT_SECRET = process.env.JWT_SECRET || (process.env.NODE_ENV === 'development' ? 'dev-secret' : undefined);
if (!JWT_SECRET) {
  console.error('FATAL: JWT_SECRET is not set. Refusing to start in non-development environment.');
  process.exit(1);
}

const app = express();
const PORT = process.env.PORT || 3000;
// Running behind Azure Container Apps ingress
app.set('trust proxy', true);
const transporter = nodemailer.createTransport({
  service: process.env.SMTP_SERVICE || 'gmail',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid token' });
    req.user = user;
    next();
  });
}

function authorizeRoles(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Forbidden: insufficient role' });
    }
    next();
  };
}

// Setup middleware BEFORE routes
app.use(cors({
  origin: process.env.FRONTEND_ORIGIN || '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));
app.use(express.static(path.join(__dirname, "frontend"))); // serve static files from container

// Test endpoint to verify middleware is working
app.post('/api/test', (req, res) => {
  console.log('Test endpoint hit, req.body:', req.body);
  res.json({ message: 'Test successful', body: req.body });
});

app.post('/api/register', async (req, res) => {
  console.log('Register endpoint hit, req.body:', req.body);
  console.log('Raw body type:', typeof req.body);
  const { username, password, fullName, email, role } = req.body;
  if (!username || !password || !fullName || !email || !role) return res.status(400).json({ error: 'Missing fields' });
  try {
    const pool = await getPool();
    const hash = await bcrypt.hash(password, 10);
    await pool.request()
      .input('username', sql.NVarChar, username)
      .input('passwordHash', sql.NVarChar, hash)
      .input('fullname', sql.NVarChar, fullName)
      .input('email', sql.NVarChar, email)
      .input('role', sql.NVarChar, role)
      .query('INSERT INTO Users (Username, PasswordHash, Fullname, Email, Role) VALUES (@username, @passwordHash, @fullname, @email, @role)');
    res.json({ message: 'User registered successfully' });
  } catch (err) {
    if (err.message && err.message.includes('UNIQUE')) {
      res.status(409).json({ error: 'Username already exists' });
    } else {
      res.status(500).json({ error: err.message });
    }
  }
});


app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ error: 'Missing fields' });
  try {
    const pool = await getPool();
    const result = await pool.request()
      .input('username', sql.NVarChar, username)
      .query('SELECT * FROM Users WHERE Username=@username');
    const user = result.recordset[0];
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });
    const match = await bcrypt.compare(password, user.PasswordHash);
    if (!match) return res.status(401).json({ error: 'Invalid credentials' });
  const token = jwt.sign({ userId: user.UserID, role: user.Role, username: user.Username, fullName: user.Fullname }, JWT_SECRET, { expiresIn: '2h' });
    res.json({ token, role: user.Role, fullName: user.Fullname, userId: user.UserID });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/me', authenticateToken, async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request()
      .input('userId', sql.Int, req.user.userId)
      .query('SELECT UserID, Username, Fullname, Role, Email FROM Users WHERE UserID=@userId');
    res.json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

async function sendStatusEmail(to, subject, text) {
  try {
    await transporter.sendMail({
      from: process.env.SMTP_USER,
      to,
      subject,
      text
    });
  } catch (err) {
    console.error('Email send error:', err);
  }
}



// Security & hardening middleware
// app.use(helmet()); // Temporarily disabled - package not in current image

const dbConfig = {
  user: process.env.AZURE_SQL_USER,
  password: process.env.AZURE_SQL_PASSWORD,
  database: process.env.AZURE_SQL_DATABASE,
  server: process.env.AZURE_SQL_SERVER,
  options: {
    encrypt: true,
    trustServerCertificate: false,
  },
};

async function getPool() {
  return await sql.connect(dbConfig);
}

app.post("/api/qna", async (req, res) => {
  const { question } = req.body;
  if (!question) return res.status(400).json({ error: "Question required" });

  try {
    const endpoint = process.env.AZURE_LANGUAGE_ENDPOINT;
    const key = process.env.AZURE_LANGUAGE_KEY;
    const response = await fetch(`${endpoint}/language/:query-knowledgebases?api-version=2021-10-01`, {
      method: "POST",
      headers: {
        "Ocp-Apim-Subscription-Key": key,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        question,
        top: 1
      })
    });
    const data = await response.json();
    res.json({ answer: data.answers?.[0]?.answer || "No answer found." });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


app.get("/api/students", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query("SELECT * FROM Students");
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
app.post("/api/students", async (req, res) => {
  const { rollNumber, firstName, lastName, email, resumeFileName, resumeContent } = req.body;

  try {
    if (!resumeFileName || typeof resumeFileName !== "string") {
      return res.status(400).json({ error: "Missing or invalid resume file name" });
    }
    if (!resumeContent || typeof resumeContent !== "string") {
      return res.status(400).json({ error: "Missing or invalid resume file content" });
    }

    const buffer = Buffer.from(resumeContent, "base64");

    const accountName = process.env.AZURE_STORAGE_ACCOUNT;
    const accountKey = process.env.AZURE_STORAGE_KEY;
    const containerName = "resumes";

    if (!accountName || typeof accountName !== "string") {
      return res.status(500).json({ error: "Azure Storage Account name is missing or invalid in environment variables." });
    }
    if (!accountKey || typeof accountKey !== "string") {
      return res.status(500).json({ error: "Azure Storage Account key is missing or invalid in environment variables." });
    }

    const sharedKey = new StorageSharedKeyCredential(accountName, accountKey);
    const blobServiceClient = new BlobServiceClient(
      `https://${accountName}.blob.core.windows.net`,
      sharedKey
    );

    const containerClient = blobServiceClient.getContainerClient(containerName);
    const blockBlobClient = containerClient.getBlockBlobClient(resumeFileName);

    await blockBlobClient.uploadData(buffer);

    const sasToken = generateBlobSASQueryParameters(
      {
        containerName,
        blobName: resumeFileName,
        permissions: BlobSASPermissions.parse("r"),
        startsOn: new Date(),
        expiresOn: new Date(Date.now() + 60 * 60 * 1000), // 1 hour
      },
      sharedKey
    ).toString();
    const resumeUrl = `${blockBlobClient.url}?${sasToken}`;

    const pool = await getPool();
    await pool
      .request()
      .input("rollNumber", sql.NVarChar, rollNumber)
      .input("firstName", sql.NVarChar, firstName)
      .input("lastName", sql.NVarChar, lastName)
      .input("email", sql.NVarChar, email)
      .input("resumeUrl", sql.NVarChar, resumeUrl)
      .query(
        `INSERT INTO Students (RollNumber, FirstName, LastName, Email, ResumeUrl)
         VALUES (@rollNumber, @firstName, @lastName, @email, @resumeUrl)`
      );

    res.json({ message: "Student added successfully", resumeUrl });
  } catch (err) {
    console.error("Insert student error:", err);
    res.status(500).json({ error: err.message });
  }
});
app.post("/api/upload", async (req, res) => {
  try {
    const { fileName, fileContent } = req.body; // Base64 string from frontend
    if (!fileName || typeof fileName !== "string") {
      return res.status(400).json({ error: "Missing or invalid file name" });
    }
    if (!fileContent || typeof fileContent !== "string") {
      return res.status(400).json({ error: "Missing or invalid file content" });
    }
    const accountName = process.env.AZURE_STORAGE_ACCOUNT;
    const accountKey = process.env.AZURE_STORAGE_KEY;
    const containerName = "resumes";

    if (!accountName || typeof accountName !== "string") {
      return res.status(500).json({ error: "Azure Storage Account name is missing or invalid in environment variables." });
    }
    if (!accountKey || typeof accountKey !== "string") {
      return res.status(500).json({ error: "Azure Storage Account key is missing or invalid in environment variables." });
    }

    const sharedKey = new StorageSharedKeyCredential(accountName, accountKey);
    const blobServiceClient = new BlobServiceClient(
      `https://${accountName}.blob.core.windows.net`,
      sharedKey
    );

    const containerClient = blobServiceClient.getContainerClient(containerName);

    const buffer = Buffer.from(fileContent, "base64");

    const blockBlobClient = containerClient.getBlockBlobClient(fileName);
    await blockBlobClient.uploadData(buffer);

    const sasToken = generateBlobSASQueryParameters(
      {
        containerName,
        blobName: fileName,
        permissions: BlobSASPermissions.parse("r"),
        startsOn: new Date(),
        expiresOn: new Date(Date.now() + 60 * 60 * 1000), // 1 hour
      },
      sharedKey
    ).toString();
    const fileUrl = `${blockBlobClient.url}?${sasToken}`;
    res.json({ url: fileUrl });
  } catch (err) {
    console.error("Upload error:", err);
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/faculty", async (req, res) => {
  const { name, email, department } = req.body;
  try {
    let pool = await sql.connect(dbConfig);
    await pool
      .request()
      .input("name", sql.NVarChar, name)
      .input("email", sql.NVarChar, email)
      .input("department", sql.NVarChar, department)
      .query(
        "INSERT INTO Faculty (Name, Email, Department) VALUES (@name, @email, @department)"
      );
    res.json({ message: "Faculty inserted successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "DB insert failed" });
  }
});

app.get("/api/faculty", async (req, res) => {
  try {
    let pool = await sql.connect(dbConfig);
    let result = await pool.request().query("SELECT * FROM Faculty");
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch faculty" });
  }
});

app.post("/api/internships", async (req, res) => {
  const { studentId, company, role, startDate, endDate } = req.body;
  try {
    const pool = await getPool();
    await pool
      .request()
      .input("studentId", sql.Int, studentId)
      .input("company", sql.NVarChar, company)
      .input("role", sql.NVarChar, role)
      .input("startDate", sql.Date, startDate)
      .input("endDate", sql.Date, endDate)
      .query(
        `INSERT INTO Internships (StudentID, Company, Role, StartDate, EndDate) 
         VALUES (@studentId, @company, @role, @startDate, @endDate)`
      );
    res.json({ message: "Internship added successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/internships", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT i.InternshipID, i.Company, i.Role, i.StartDate, i.EndDate, 
             s.RollNumber, s.FirstName, s.LastName
      FROM Internships i
      JOIN Students s ON i.StudentID = s.StudentID
    `);
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});


app.post("/api/companies", async (req, res) => {
  const { name, industry, location, website, description } = req.body;
  try {
    const pool = await getPool();
    await pool.request()
      .input("name", sql.NVarChar, name)
      .input("industry", sql.NVarChar, industry)
      .input("location", sql.NVarChar, location)
      .input("website", sql.NVarChar, website)
      .input("description", sql.NVarChar, description)
      .query(`INSERT INTO Companies (Name, Industry, Location, Website, Description)
              VALUES (@name, @industry, @location, @website, @description)`);
    res.json({ message: "Company added successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/companies", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query("SELECT * FROM Companies");
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.put("/api/companies/:id", async (req, res) => {
  const { id } = req.params;
  const { name, industry, location, website, description } = req.body;
  try {
    const pool = await getPool();
    await pool.request()
      .input("id", sql.Int, id)
      .input("name", sql.NVarChar, name)
      .input("industry", sql.NVarChar, industry)
      .input("location", sql.NVarChar, location)
      .input("website", sql.NVarChar, website)
      .input("description", sql.NVarChar, description)
      .query(`UPDATE Companies SET Name=@name, Industry=@industry, Location=@location, Website=@website, Description=@description WHERE CompanyID=@id`);
    res.json({ message: "Company updated successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.delete("/api/companies/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const pool = await getPool();
    await pool.request()
      .input("id", sql.Int, id)
      .query("DELETE FROM Companies WHERE CompanyID=@id");
    res.json({ message: "Company deleted successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});
app.post("/api/placements", async (req, res) => {
  const { studentId, company, packageAmount, status } = req.body;
  try {
    const pool = await getPool();
    await pool
      .request()
      .input("studentId", sql.Int, studentId)
      .input("company", sql.NVarChar, company)
      .input("packageAmount", sql.Decimal(18, 2), packageAmount)
      .input("status", sql.NVarChar, status)
      .query(
        `INSERT INTO Placements (StudentID, Company, Package, Status) 
         VALUES (@studentId, @company, @packageAmount, @status)`
      );
    res.json({ message: "Placement added successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/placements", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT p.PlacementID, p.Company, p.Package, p.Status,
             s.RollNumber, s.FirstName, s.LastName
      FROM Placements p
      JOIN Students s ON p.StudentID = s.StudentID
    `);
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});


app.post("/api/applications", async (req, res) => {
  const { studentId, companyId, role, type } = req.body;
  try {
    const pool = await getPool();
    await pool.request()
      .input("studentId", sql.Int, studentId)
      .input("companyId", sql.Int, companyId)
      .input("role", sql.NVarChar, role)
      .input("type", sql.NVarChar, type)
      .query(`INSERT INTO Applications (StudentID, CompanyID, Role, Type) VALUES (@studentId, @companyId, @role, @type)`);
    res.json({ message: "Application submitted" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/applications", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT a.ApplicationID, a.Status, a.Type, a.Role, a.AppliedAt, a.ReviewedAt, a.Comments,
             s.StudentID, s.RollNumber, s.FirstName, s.LastName,
             c.CompanyID, c.Name AS CompanyName
      FROM Applications a
      JOIN Students s ON a.StudentID = s.StudentID
      JOIN Companies c ON a.CompanyID = c.CompanyID
      ORDER BY a.AppliedAt DESC
    `);
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/applications/:studentId", async (req, res) => {
  const { studentId } = req.params;
  try {
    const pool = await getPool();
    const result = await pool.request()
      .input("studentId", sql.Int, studentId)
      .query(`
        SELECT a.ApplicationID, a.Status, a.Type, a.Role, a.AppliedAt, a.ReviewedAt, a.Comments,
               c.CompanyID, c.Name AS CompanyName
        FROM Applications a
        JOIN Companies c ON a.CompanyID = c.CompanyID
        WHERE a.StudentID = @studentId
        ORDER BY a.AppliedAt DESC
      `);
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.put("/api/applications/:id", async (req, res) => {
  const { id } = req.params;
  const { status, reviewedBy, comments } = req.body;
  try {
    const pool = await getPool();
    await pool.request()
      .input("id", sql.Int, id)
      .input("status", sql.NVarChar, status)
      .input("reviewedBy", sql.NVarChar, reviewedBy)
      .input("comments", sql.NVarChar, comments)
      .query(`UPDATE Applications SET Status=@status, ReviewedAt=GETDATE(), ReviewedBy=@reviewedBy, Comments=@comments WHERE ApplicationID=@id`);

    const result = await pool.request()
      .input("id", sql.Int, id)
      .query(`SELECT a.Role, a.Type, a.Status, a.Comments, s.Email, s.FirstName, s.LastName, c.Name AS CompanyName
              FROM Applications a
              JOIN Students s ON a.StudentID = s.StudentID
              JOIN Companies c ON a.CompanyID = c.CompanyID
              WHERE a.ApplicationID = @id`);
    const app = result.recordset[0];
    if (app && app.Email) {
      const subject = `Your application status for ${app.CompanyName} (${app.Type})`;
      const text = `Hello ${app.FirstName} ${app.LastName},\n\nYour application for the role of ${app.Role} at ${app.CompanyName} (${app.Type}) has been updated to: ${app.Status}.\n\nComments: ${app.Comments || 'None'}\n\nRegards,\nPlacement Cell`;
      sendStatusEmail(app.Email, subject, text);
    }
    res.json({ message: "Application updated and email sent (if possible)" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});
app.get("/api/recommendations", async (req, res) => {
  try {
    if (process.env.OPENAI_API_KEY) {
      const response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4o-mini",
          messages: [
            {
              role: "system",
              content:
                "Suggest 5 internship or placement opportunities for CS students",
            },
          ],
        }),
      });

      const data = await response.json();
      const text = data.choices[0].message.content;
      res.json({ recommendations: text.split("\n").filter((x) => x) });
    } else {
      res.json({
        recommendations: [
          "Software Engineer Intern at Google",
          "Data Analyst Intern at Microsoft",
          "Full Stack Developer Intern at Infosys",
          "AI/ML Intern at TCS",
          "Cybersecurity Analyst Intern at Wipro",
        ],
      });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


app.get('/api/analytics/placement', async (req, res) => {
  try {
    const pool = await getPool();
    const placed = await pool.request().query(`SELECT COUNT(DISTINCT StudentID) AS Placed FROM Applications WHERE Type='Placement' AND Status='Approved'`);
    const students = await pool.request().query(`SELECT COUNT(*) AS Total FROM Students`);
    res.json({ placed: placed.recordset[0].Placed, total: students.recordset[0].Total });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/analytics/internship', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT Status, COUNT(*) AS Count
      FROM Applications
      WHERE Type='Internship' AND Status IN ('Approved','Completed','Dropped','Ongoing')
      GROUP BY Status
    `);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/analytics/company-placements', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT c.Name AS Company, COUNT(*) AS Count
      FROM Applications a
      JOIN Companies c ON a.CompanyID = c.CompanyID
      WHERE a.Type='Placement' AND a.Status='Approved'
      GROUP BY c.Name
    `);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
import aiService from "./aiService.js";
app.post('/api/keyphrases/file', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No file uploaded" });
    const ext = path.extname(req.file.originalname).toLowerCase();
    let text = '';
    if (ext === '.pdf') {
      const dataBuffer = fs.readFileSync(req.file.path);
      const parser = new pdfParse.PDFParse({ data: dataBuffer });
      const result = await parser.getText();
      text = result.text;
      await parser.destroy();
    } else if (ext === '.txt') {
      text = fs.readFileSync(req.file.path, 'utf8');
    } else {
      return res.status(400).json({ error: 'Unsupported file type. Only PDF and TXT are supported.' });
    }
    const keyPhrases = await aiService.extractKeyPhrases(text);
    fs.unlinkSync(req.file.path); // delete temp file
    res.json({ keyPhrases });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/keyphrases', async (req, res) => {
  try {
    const text = req.body.text;
    if (!text) return res.status(400).json({ error: "No text provided" });

    const [result] = await client.extractKeyPhrases([text]);
    res.json({ keyPhrases: result.keyPhrases });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});

// Lightweight health endpoint for readiness/liveness checks
app.get('/healthz', (req, res) => {
  res.status(200).json({ status: 'ok' });
});
