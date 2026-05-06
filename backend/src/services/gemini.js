const axios = require("axios");

const GROQ_API_KEY = process.env.GROQ_API_KEY;

async function generateText(prompt) {
  if (!GROQ_API_KEY) {
    const err = new Error("GROQ_API_KEY is not configured");
    err.statusCode = 503;
    throw err;
  }

  try {
    const response = await axios.post(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        model: "llama-3.1-8b-instant",
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

    return response.data.choices[0].message.content.trim();
  } catch (e) {
    const err = new Error(
      e.response?.data?.error?.message || "Groq request failed"
    );
    err.statusCode = 500;
    throw err;
  }
}

module.exports = { generateText };