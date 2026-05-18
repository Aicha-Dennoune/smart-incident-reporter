# Fonctionnalités d’intelligence artificielle

Ce document décrit **ce que fait l’IA** dans le projet, **comment** elle est appelée, et **pourquoi** des règles métier complètent le modèle.

---

## 1. Principe général

- Le **client Flutter** ne contient **pas** la clé API du fournisseur LLM.
- Les appels passent par le **backend Node.js** (`/ai/...`), qui invoque l’API **Groq** (format compatible OpenAI `chat/completions`).
- Le module serveur s’appelle historiquement **`gemini.js`** dans le dépôt, mais il implémente bien **Groq** (`https://api.groq.com/openai/v1/chat/completions`).

**Argument soutenance** : architecture **sécurisée et maintenable** (rotation de clé, changement de modèle, logs serveur).

---

## 2. Configuration côté Flutter

La classe **`AIService`** utilise :

- `AI_API_BASE_URL` — URL de base du backend (ex. `http://10.0.2.2:5000` en émulateur Android).
- `API_KEY` (optionnel) — en-tête `Authorization: Bearer ...` si le backend est protégé.

En l’absence d’URL configurée, les méthodes lèvent une exception explicite (évite des erreurs silencieuses).

---

## 3. Endpoints backend (`ai.routes.js`)

| Route | Corps typique | Réponse | Usage produit |
|-------|----------------|---------|----------------|
| `POST /ai/improve` | `{ "text": "..." }` | `{ "text": "..." }` | Reformulation / professionnalisation de la **description** d’incident |
| `POST /ai/suggest-type` | `{ "text": "..." }` | `{ "type": "..." }` | Suggestion de **catégorie** (Electricité, Mécanique, IT, Eau) |
| `POST /ai/suggest-solution` | `{ "text": "..." }` | `{ "solution": "..." }` | Proposition de **solution** pour le technicien |
| `POST /ai/classify-priority` | `{ "title", "description" }` ou `text` | `{ "priority": "Faible" \| "Moyenne" \| "Critique" }` | **Priorité** à l’enregistrement de l’incident |

---

## 4. Groq côté serveur (`gemini.js`)

- Variable **`GROQ_API_KEY`** obligatoire pour générer du texte.
- Variable **`GROQ_MODEL`** (défaut : `llama-3.1-8b-instant`).
- Envoi d’un message **user** unique avec le **prompt** construit dans la route.
- Extraction du contenu : `choices[0].message.content`.
- Journalisation basique (aperçu prompt / réponse, erreurs HTTP).

**Pourquoi Groq ?** Latence souvent faible, modèles adaptés au chat, API familière pour les développeurs habitués à OpenAI.

---

## 5. Classification automatique de la **priorité**

### 5.1 Flux

1. Le client appelle `/ai/classify-priority` avec **titre + description**.
2. Le serveur normalise un texte pour les **mots-clés** (minuscules, sans accents).
3. **`businessPriorityFromText`** est évaluée **avant** l’appel LLM si une règle s’applique.
4. Sinon, le prompt est envoyé à **Groq** ; la réponse est normalisée (`normalizePriority`).
5. Si la réponse est illisible : repli **`Moyenne`**.

### 5.2 Ordre des règles métier (sécurité opérationnelle)

1. **Critique** — mots-clés type incendie, fumée, explosion, électricité, danger, fuite gaz, court-circuit… (mots entiers ou expressions selon implémentation).
2. **Faible** — périphériques (imprimante, clavier, souris, scanner) — évalué **avant** « Moyenne » pour éviter qu’un mot comme « panne » ne masque un incident matériel simple.
3. **Moyenne** — serveur, réseau, application, panne, machine arrêtée / bloquée…
4. Sinon : **réponse IA**.

**Intérêt métier** : en milieu **industriel**, un LLM peut sous-estimer un danger ; les règles garantissent un **plancher** de criticité pour certains signaux.

### 5.3 Fallback côté mobile à la création

Dans **`IncidentService.createIncident`**, si l’appel `suggestPriority` échoue (réseau, timeout), la priorité par défaut est **`Moyenne`** et la création **n’est pas bloquée**.

---

## 6. Amélioration de description (`/ai/improve`)

- Prompt système : style professionnel, une seule phrase ou paragraphe, ajout de la **date du jour** en français, pas d’invention de faits.
- Utilisé depuis l’UI technicien / panneaux IA selon les écrans branchés.

---

## 7. Synthèse pour le jury

| Question | Réponse courte |
|----------|----------------|
| Pourquoi un backend pour l’IA ? | Protéger les clés, centraliser prompts et règles, journaliser. |
| L’IA remplace-elle le métier ? | Non : **règles déterministes** en priorité pour les cas critiques / évidents. |
| Que se passe-t-il sans Groq ? | Erreur serveur 503 si pas de clé ; côté app, priorité par défaut si l’appel échoue à la création. |
