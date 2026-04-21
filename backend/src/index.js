const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const nodemailer = require("nodemailer");
const admin = require("firebase-admin");
const { initializeFirebaseAdmin } = require("./config/firebase");

dotenv.config();
initializeFirebaseAdmin();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

app.get("/api/health", (req, res) => {
  res.json({ status: "ok", message: "Backend is running" });
});

app.post("/api/send-email", async (req, res) => {
  const { to, nom, email, password, role } = req.body || {};

  console.log("[MAILTRAP] Incoming /api/send-email request", {
    to,
    email,
    role,
    hasPassword: Boolean(password),
  });

  if (!to || !email || !password || !role) {
    console.warn("[MAILTRAP] Missing required fields in request body");
    return res.status(400).json({
      message: "Missing fields: to, email, password, role",
    });
  }

  const smtpHost = process.env.MAILTRAP_HOST;
  const smtpPort = Number(process.env.MAILTRAP_PORT || 2525);
  const smtpUser = process.env.MAILTRAP_USER;
  const smtpPass = process.env.MAILTRAP_PASS;
  const from = process.env.MAILTRAP_FROM || "no-reply@smart-incident-reporter.local";

  if (!smtpHost || !smtpUser || !smtpPass) {
    console.error("[MAILTRAP] SMTP env variables are missing", {
      hasHost: Boolean(smtpHost),
      hasUser: Boolean(smtpUser),
      hasPass: Boolean(smtpPass),
      smtpPort,
    });
    return res.status(500).json({
      message: "SMTP is not configured correctly",
    });
  }

  try {
    const transporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: smtpPort === 465,
      auth: {
        user: smtpUser,
        pass: smtpPass,
      },
      requireTLS: false,
      tls: {
        rejectUnauthorized: false,
      },
    });

    console.log("[MAILTRAP] SMTP config summary", {
      host: smtpHost,
      port: smtpPort,
      secure: smtpPort === 465,
      userPreview: `${smtpUser.slice(0, 4)}***`,
      from,
    });

    await transporter.verify();
    console.log("[MAILTRAP] SMTP verify success");

    const subject = "Bienvenue - Smart Incident Reporter";
    const text = `Bonjour ${nom || ""},

Votre compte a ete cree.
Email : ${email}
Mot de passe : ${password}
Role : ${role}

Veuillez vous connecter a l'application.`;

    const info = await transporter.sendMail({
      from,
      to,
      subject,
      text,
    });

    console.log("[MAILTRAP] Email sent", {
      messageId: info.messageId,
      accepted: info.accepted,
      rejected: info.rejected,
      response: info.response,
    });

    return res.json({ message: "Email sent successfully" });
  } catch (error) {
    console.error("[MAILTRAP] Send email failed", {
      name: error.name,
      message: error.message,
      code: error.code,
      command: error.command,
      response: error.response,
      responseCode: error.responseCode,
    });
    return res.status(500).json({
      message: "Unable to send email",
      error: error.message,
    });
  }
});

app.post("/api/mailtrap-test", async (req, res) => {
  const smtpHost = process.env.MAILTRAP_HOST;
  const smtpPort = Number(process.env.MAILTRAP_PORT || 2525);
  const smtpUser = process.env.MAILTRAP_USER;
  const smtpPass = process.env.MAILTRAP_PASS;
  const to = req.body?.to || "test@example.com";
  const from = process.env.MAILTRAP_FROM || "no-reply@smart-incident-reporter.local";

  console.log("[MAILTRAP-TEST] Starting diagnostic test");
  console.log("[MAILTRAP-TEST] Env summary", {
    hasHost: Boolean(smtpHost),
    hasPort: Boolean(smtpPort),
    hasUser: Boolean(smtpUser),
    hasPass: Boolean(smtpPass),
    host: smtpHost,
    port: smtpPort,
    secure: smtpPort === 465,
    userPreview: smtpUser ? `${smtpUser.slice(0, 4)}***` : "missing",
    from,
    to,
  });

  if (!smtpHost || !smtpUser || !smtpPass) {
    return res.status(500).json({
      message: "SMTP env is incomplete",
    });
  }

  try {
    const transporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: smtpPort === 465,
      auth: {
        user: smtpUser,
        pass: smtpPass,
      },
      requireTLS: false,
      tls: { rejectUnauthorized: false },
    });

    await transporter.verify();
    console.log("[MAILTRAP-TEST] verify() success");

    const info = await transporter.sendMail({
      from,
      to,
      subject: "Mailtrap diagnostic",
      text: "SMTP diagnostic email from Smart Incident Reporter backend.",
    });

    console.log("[MAILTRAP-TEST] sendMail() success", {
      messageId: info.messageId,
      response: info.response,
      accepted: info.accepted,
      rejected: info.rejected,
    });

    return res.json({
      message: "Mailtrap test success",
      response: info.response,
      accepted: info.accepted,
      rejected: info.rejected,
    });
  } catch (error) {
    console.error("[MAILTRAP-TEST] failure", {
      name: error.name,
      message: error.message,
      code: error.code,
      command: error.command,
      response: error.response,
      responseCode: error.responseCode,
    });
    return res.status(500).json({
      message: "Mailtrap test failed",
      error: error.message,
      code: error.code,
      responseCode: error.responseCode,
      response: error.response,
    });
  }
});

app.delete("/api/users/:uid", async (req, res) => {
  const { uid } = req.params;
  if (!uid) {
    return res.status(400).json({ message: "uid is required" });
  }

  try {
    await admin.auth().deleteUser(uid);
    await admin.firestore().collection("users").doc(uid).delete();
    return res.json({ message: "User deleted successfully" });
  } catch (error) {
    return res.status(500).json({
      message: "Unable to delete user",
      error: error.message,
    });
  }
});

app.listen(PORT, () => {
  console.log(`Server started on http://localhost:${PORT}`);
});
