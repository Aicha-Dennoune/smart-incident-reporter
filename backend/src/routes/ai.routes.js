const express = require("express");
const { generateText } = require("../services/gemini");

const router = express.Router();

function readTextBody(req) {
  const text = req.body?.text;
  if (text === undefined || text === null || String(text).trim() === "") {
    return null;
  }
  return String(text).trim();
}

/** Normalise la réponse type vers les codes attendus par le client Flutter. */
function normalizeIncidentType(raw) {
  if (!raw) return null;
  const t = String(raw)
    .trim()
    .split(/\r?\n/)[0]
    .replace(/^["']|["']$/g, "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");

  if (t.includes("electric")) return "Electricite";
  if (t.includes("meca")) return "Mecanique";
  if (t.includes("eau") || t.includes("water")) return "Eau";
  if (t === "it" || t.includes("info") || t.includes("informatique")) return "IT";
  return null;
}

router.post("/improve", async (req, res) => {
  try {
    const text = readTextBody(req);
    if (!text) {
      return res.status(400).json({ error: "Missing or empty field: text" });
    }
const today = new Date().toLocaleDateString('fr-FR');
const prompt = `
Améliore uniquement la description suivante d’un incident industriel.

Règles :
- Ne pas ajouter de sections (pas de titre, pas de listes)
- Ne pas ajouter de champs à remplir (pas de "insérez")
- Ne pas inventer d’informations
- Garder un seul paragraphe
- Corriger les fautes et rendre le texte professionnel
-Ne dis PAS "il n'y a pas assez d'informations"

ajouter Date de l'incident : ${today}

Texte :
${text}
`;
    const improved = await generateText(prompt);

    return res.json({ text: improved });
  } catch (e) {
    console.error("[AI/improve]", e.message);
    const status = e.statusCode || 500;
    return res.status(status).json({
      error: e.message || "Gemini request failed",
    });
  }
});

router.post("/suggest-type", async (req, res) => {
  try {
    const text = readTextBody(req);
    if (!text) {
      return res.status(400).json({ error: "Missing or empty field: text" });
    }

    const prompt = `Classe cet incident dans UNE seule catégorie parmi : Electricité, Mécanique, IT, Eau. Répond uniquement par le type.

Texte de l'incident :
${text}`;

    const raw = await generateText(prompt);
    const type = normalizeIncidentType(raw) || raw.trim().split(/\r?\n/)[0];

    return res.json({ type });
  } catch (e) {
    console.error("[AI/suggest-type]", e.message);
    const status = e.statusCode || 500;
    return res.status(status).json({
      error: e.message || "Gemini request failed",
    });
  }
});

router.post("/suggest-solution", async (req, res) => {
  try {
    const text = readTextBody(req);
    if (!text) {
      return res.status(400).json({ error: "Missing or empty field: text" });
    }

    const prompt = `Propose une solution technique claire et professionnelle pour cet incident : ${text}`;
    const solution = await generateText(prompt);

    return res.json({ solution });
  } catch (e) {
    console.error("[AI/suggest-solution]", e.message);
    const status = e.statusCode || 500;
    return res.status(status).json({
      error: e.message || "Gemini request failed",
    });
  }
});

module.exports = router;
