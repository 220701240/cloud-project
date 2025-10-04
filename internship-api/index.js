// ---------- AUTH MIDDLEWARE ----------
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });
  jwt.verify(token, process.env.JWT_SECRET || 'secretkey', (err, user) => {
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

// ---------- AUTH ROUTES ----------
// Register
app.post('/api/register', async (req, res) => {
  const { username, password, fullName, role, email } = req.body;
  if (!username || !password || !fullName || !role) return res.status(400).json({ error: 'Missing fields' });
  try {
    const pool = await getPool();
    const hash = await bcrypt.hash(password, 10);
    await pool.request()
      .input('username', sql.NVarChar, username)
      .input('passwordHash', sql.NVarChar, hash)
      .input('fullName', sql.NVarChar, fullName)
      .input('role', sql.NVarChar, role)
      .input('email', sql.NVarChar, email)
      .query('INSERT INTO Users (Username, PasswordHash, FullName, Role, Email) VALUES (@username, @passwordHash, @fullName, @role, @email)');
    res.json({ message: 'User registered' });
  } catch (err) {
    if (err.message && err.message.includes('UNIQUE')) {
      res.status(409).json({ error: 'Username already exists' });
    } else {
      res.status(500).json({ error: err.message });
    }
  }
});

// Login
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
    const token = jwt.sign({ userId: user.UserID, role: user.Role, username: user.Username, fullName: user.FullName }, process.env.JWT_SECRET || 'secretkey', { expiresIn: '2h' });
    res.json({ token, role: user.Role, fullName: user.FullName, userId: user.UserID });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get current user info
app.get('/api/me', authenticateToken, async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request()
      .input('userId', sql.Int, req.user.userId)
      .query('SELECT UserID, Username, FullName, Role, Email FROM Users WHERE UserID=@userId');
    res.json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import express from "express";
import bodyParser from "body-parser";
import sql from "mssql";
import {
  BlobServiceClient,
  StorageSharedKeyCredential,
  BlobSASPermissions,
  generateBlobSASQueryParameters
} from "@azure/storage-blob";
import path from "path";
import dotenv from "dotenv";
import fetch from "node-fetch";
import nodemailer from "nodemailer";
// ---------- EMAIL CONFIG ----------
const transporter = nodemailer.createTransport({
  service: process.env.SMTP_SERVICE || 'gmail',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
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

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// ---------- MIDDLEWARE ----------
app.use(bodyParser.json({ limit: "10mb" }));
app.use(bodyParser.urlencoded({ extended: true, limit: "10mb" }));
app.use(express.static(path.join(process.cwd(), "..", "frontend"))); // serve static files

// ---------- DB CONFIG ----------
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

// Connect to SQL
async function getPool() {
  return await sql.connect(dbConfig);
}

// ================= QnA Chatbot Route =================
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
        // knowledgeBaseId: "YOUR_KB_ID" // add if needed
      })
    });
    const data = await response.json();
    res.json({ answer: data.answers?.[0]?.answer || "No answer found." });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ================= STUDENT ROUTES =================

// Get all students
app.get("/api/students", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query("SELECT * FROM Students");
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// Add student
app.post("/api/students", async (req, res) => {
  const { rollNumber, firstName, lastName, email, resumeFileName, resumeContent } = req.body;

  try {
    if (!resumeFileName || typeof resumeFileName !== "string") {
      return res.status(400).json({ error: "Missing or invalid resume file name" });
    }
    if (!resumeContent || typeof resumeContent !== "string") {
      return res.status(400).json({ error: "Missing or invalid resume file content" });
    }

    // Convert to Buffer
    const buffer = Buffer.from(resumeContent, "base64");

    // Azure Blob
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

    // Generate SAS URL for the uploaded resume
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

    // Insert into DB
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
// ================= FILE UPLOAD (RESUMES) =================
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

    // Create BlobServiceClient
    const sharedKey = new StorageSharedKeyCredential(accountName, accountKey);
    const blobServiceClient = new BlobServiceClient(
      `https://${accountName}.blob.core.windows.net`,
      sharedKey
    );

    const containerClient = blobServiceClient.getContainerClient(containerName);

    // Convert Base64 -> Buffer
    const buffer = Buffer.from(fileContent, "base64");

    // Upload file
    const blockBlobClient = containerClient.getBlockBlobClient(fileName);
    await blockBlobClient.uploadData(buffer);

    // Generate SAS URL for the uploaded file
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

// ================= FACULTY ROUTES =================
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

// ================= INTERNSHIP ROUTES =================
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

// ================= PLACEMENT ROUTES =================
// ================= COMPANY ROUTES =================
// Create company
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

// Get all companies
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

// Update company
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

// Delete company
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

// ================= AI RECOMMENDATIONS =================
// ================= APPLICATIONS ROUTES =================
// Student applies for internship/placement
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

// Admin/faculty: list all applications (with student & company info)
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

// Student: view their own applications
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

// Admin/faculty: review/update application status (with email notification)
app.put("/api/applications/:id", async (req, res) => {
  const { id } = req.params;
  const { status, reviewedBy, comments } = req.body;
  try {
    const pool = await getPool();
    // Update application
    await pool.request()
      .input("id", sql.Int, id)
      .input("status", sql.NVarChar, status)
      .input("reviewedBy", sql.NVarChar, reviewedBy)
      .input("comments", sql.NVarChar, comments)
      .query(`UPDATE Applications SET Status=@status, ReviewedAt=GETDATE(), ReviewedBy=@reviewedBy, Comments=@comments WHERE ApplicationID=@id`);

    // Get student email and application details
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

// ================= AI KEY PHRASE EXTRACTION (Azure Text Analytics) =================
// ================= ANALYTICS & REPORTS ROUTES =================
// Placement stats: Placed vs Not Placed
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

// Internship stats: Approved internships by status
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

// Company-wise placements: Number of approved placements per company
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
import * as aiService from "./aiService.js";
app.post("/api/keyphrases", async (req, res) => {
  const { text } = req.body;
  if (!text) return res.status(400).json({ error: "Text is required" });
  try {
    const keyPhrases = await aiService.extractKeyPhrases(text);
    res.json({ keyPhrases });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ================= FRONTEND ROUTES =================

// ================= START SERVER =================
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});