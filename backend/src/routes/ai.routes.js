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

function readIncidentText(req) {
  const title = req.body?.title;
  const description = req.body?.description;
  const text = req.body?.text;

  const t = title == null ? "" : String(title).trim();
  const d = description == null ? "" : String(description).trim();
  const s = text == null ? "" : String(text).trim();

  if (!t && !d && !s) return null;
  if (s) return s;
  return `${t}\n${d}`.trim();
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

/** Normalise priorité: Faible | Moyenne | Critique */
function normalizePriority(raw) {
  if (!raw) return null;
  const t = String(raw)
    .trim()
    .split(/\r?\n/)[0]
    .replace(/^["']|["']$/g, "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");

  if (t.includes("crit")) return "Critique";
  if (t.includes("moy")) return "Moyenne";
  if (t.includes("faib")) return "Faible";
  return null;
}

/** Minuscules + sans accents pour matching mots-clés. */
function normalizeTextForKeywords(str) {
  return String(str || "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
}

/** Mot entier (évite ex. « panne » dans « panneau », « danger » dans « dangereux »). */
function textHasWholeWord(haystackAscii, wordAscii) {
  const esc = String(wordAscii).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp(`\\b${esc}\\b`, "i").test(haystackAscii);
}

/** Sous-chaîne (expressions à plusieurs mots ou tiret). */
function textHasPhrase(haystackAscii, phraseAscii) {
  return haystackAscii.includes(phraseAscii);
}

/**
 * Règles métier priorité (contexte industriel). Ordre : Critique > Faible > Moyenne.
 * Sinon null → fallback IA.
 */
function businessPriorityFromText(asciiLower) {
  if (!asciiLower || !asciiLower.trim()) return null;
  const s = asciiLower;

  const criticalPhrases = ["court-circuit", "court circuit", "fuite gaz"];
  const criticalWords = [
    "incendie",
    "feu",
    "fumee",
    "brule",
    "explosion",
    "danger",
    "electrique",
  ];
  if (
    criticalPhrases.some((p) => textHasPhrase(s, p)) ||
    criticalWords.some((w) => textHasWholeWord(s, w))
  ) {
    return "Critique";
  }

  const lowWords = ["imprimante", "clavier", "souris", "scanner"];
  if (lowWords.some((w) => textHasWholeWord(s, w))) return "Faible";

  const mediumPhrases = [
    "machine arretee",
    "machine bloquee",
    "machine arret",
    "machine bloque",
  ];
  const mediumWords = ["serveur", "reseau", "application", "panne"];
  if (
    mediumPhrases.some((p) => textHasPhrase(s, p)) ||
    mediumWords.some((w) => textHasWholeWord(s, w))
  ) {
    return "Moyenne";
  }

  return null;
}

/** Texte titre + description (ou champ text seul) pour règles métier. */
function combinedTextForBusinessRules(req) {
  const title = req.body?.title == null ? "" : String(req.body.title).trim();
  const description =
    req.body?.description == null ? "" : String(req.body.description).trim();
  const text = req.body?.text == null ? "" : String(req.body.text).trim();
  if (title || description) {
    return [title, description].filter(Boolean).join(" ");
  }
  return text;
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

router.post("/classify-priority", async (req, res) => {
  try {
    const text = readIncidentText(req);
    if (!text) {
      return res
        .status(400)
        .json({ error: "Missing incident content (title/description/text)" });
    }
    console.log("[AI/classify-priority] Incoming", {
      titlePreview: String(req.body?.title || "").slice(0, 80),
      descriptionPreview: String(req.body?.description || "").slice(0, 120),
      combinedPreview: text.replace(/\s+/g, " ").slice(0, 180),
    });

    const forRules = normalizeTextForKeywords(combinedTextForBusinessRules(req));
    const businessPriority = businessPriorityFromText(forRules);
    if (businessPriority) {
      console.log("[AI/classify-priority] Business rules", {
        source: "business_rules",
        matchedOn: forRules.replace(/\s+/g, " ").slice(0, 200),
        finalPriority: businessPriority,
      });
      return res.json({ priority: businessPriority });
    }

    const prompt = `Analyse l'incident suivant et classe sa priorité dans UNE seule valeur parmi : Faible, Moyenne, Critique.
Réponds uniquement par le mot exact: Faible ou Moyenne ou Critique.

Incident:
${text}`;

    const raw = await generateText(prompt);
    const normalized = normalizePriority(raw);
    const usedFallback = !normalized;
    const priority = normalized || "Moyenne";
    console.log("[AI/classify-priority] Parsed", {
      source: "groq",
      rawResponse: raw,
      normalizedPriority: normalized,
      finalPriority: priority,
      usedFallback,
    });

    return res.json({ priority });
  } catch (e) {
    console.error("[AI/classify-priority]", e.message);
    const status = e.statusCode || 500;
    return res.status(status).json({
      error: e.message || "Groq request failed",
    });
  }
});

module.exports = router;
