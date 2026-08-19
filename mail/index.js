const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

const nodemailer = require("nodemailer");

// ✅ BREVO SMTP
const transporter = nodemailer.createTransport({
  host: "smtp-relay.brevo.com",
  port: 587,
  secure: false,
  auth: {
    user: "infopushpraj343@gmail.com",
    pass: process.env.BREVO_SMTP_PASS || "YOUR_BREVO_SMTP_PASS",
  },
});

// ✅ SEND MAIL FUNCTION
exports.sendMail = onRequest(async (req, res) => {
  try {

    const {to, subject, text} = req.body;

    await transporter.sendMail({
      from: '"SCCR Coaching" <infopushpraj343@gmail.com>',
      to: to,
      subject: subject,
      text: text,
    });

    res.status(200).send("Email Sent");

  } catch (e) {

    logger.error(e);

    res.status(500).send(e.toString());
  }
});