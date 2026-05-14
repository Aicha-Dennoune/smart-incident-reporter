const axios = require("axios");

const GROQ_API_KEY = process.env.GROQ_API_KEY;
const GROQ_MODEL = process.env.GROQ_MODEL || "llama-3.1-8b-instant";

async function generateText(prompt) {
  if (!GROQ_API_KEY) {
    const err = new Error("GROQ_API_KEY is not configured");
    err.statusCode = 503;
    throw err;
  }

  try {
    const promptPreview = String(prompt).replace(/\s+/g, " ").slice(0, 180);
    console.log("[GROQ] Request", {
      model: GROQ_MODEL,
      promptPreview,
    });

    const response = await axios.post(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        model: GROQ_MODEL,
        messages: [
          {
            role: "user",
            content: prompt,
          },
        ],
      },
      {
        headers: {
          Authorization: `Bearer ${GROQ_API_KEY}`,
          "Content-Type": "application/json",
        },
      }
    );

    const raw = response.data?.choices?.[0]?.message?.content;
    const output = (raw || "").toString().trim();
    console.log("[GROQ] Response", {
      hasChoices: Boolean(response.data?.choices?.length),
      outputPreview: output.slice(0, 120),
    });
    return output;
  } catch (e) {
    console.error("[GROQ] Error", {
      status: e.response?.status,
      message: e.response?.data?.error?.message || e.message,
    });
    const err = new Error(
      e.response?.data?.error?.message || "Groq request failed"
    );
    err.statusCode = 500;
    throw err;
  }
}

module.exports = { generateText };