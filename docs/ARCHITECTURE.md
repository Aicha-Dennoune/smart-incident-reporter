# Architecture du projet — Smart Incident Reporter

Ce document présente l’architecture globale de l’application, les responsabilités de chaque couche et les choix structurants pour la soutenance.

---

## 1. Vue d’ensemble

Le système repose sur **trois blocs principaux** :

| Couche | Technologie | Rôle |
|--------|-------------|------|
| **Client mobile / web** | Flutter (Dart) | Interface utilisateur, navigation par rôle, appels Firestore en temps réel, appels HTTP vers l’API IA |
| **Backend temps réel & données** | Firebase (Auth, Firestore, éventuellement Storage) | Authentification, persistance des incidents, messages, utilisateurs, notifications |
| **Backend métier / IA** | Node.js (Express) | Routes REST (`/ai/...`), appel à **Groq** (API compatible OpenAI), envoi d’e-mails (ex. Mailtrap) |

**Choix métier** : séparer **données temps réel** (Firebase) et **traitement IA** (Node) permet de garder Firestore simple côté règles, tout en centralisant prompts, clés API et logique métier priorité sur le serveur.

---

## 2. Organisation des dossiers (repères)

```
projet_stage/
├── frontend/                 # Application Flutter
│   ├── lib/
│   │   ├── main.dart         # Point d’entrée, thème, AuthGate + routage par rôle
│   │   ├── firebase_options.dart
│   │   ├── screens/        # Écrans par persona (admin, employé, technicien, chat, login…)
│   │   ├── services/       # Logique accès données & intégrations (Firestore, HTTP, PDF…)
│   │   ├── widgets/        # Composants réutilisables (AppTopBar, dashboard, industriel…)
│   │   ├── theme/            # Tokens visuels (IndustrialTokens, AppColors)
│   │   └── utils/            # Aides (ex. erreurs Firestore)
│   └── assets/images/        # Ex. logo PDF (OCP)
├── backend/                  # API Node
│   └── src/
│       ├── index.js          # Express, CORS, routes /ai, santé, e-mail
│       ├── routes/ai.routes.js
│       └── services/gemini.js   # Nom historique : appels Groq (chat/completions)
├── firestore.rules           # Règles de sécurité Firestore (référence racine projet)
└── docs/                     # Documentation soutenance (ce dossier)
```

---

## 3. Rôle des services Flutter (logique applicative)

Les **écrans** restent orientés UI ; la logique métier et l’accès aux données sont surtout dans **`lib/services/`** :

| Service | Responsabilité principale |
|---------|---------------------------|
| **`IncidentService`** | CRUD incidents, affectation technicien, statuts, notifications associées, streams `watchIncidents` / `watchTechnicians`, utilitaires (`normStatus`, `assigneeKey`, tri par priorité/date, etc.) |
| **`ChatService`** | Sous-collection `incidents/{id}/messages`, envoi, lecture, `readBy` |
| **`NotificationService`** | Collection `notifications`, tri documents, compteur non lu, marquage lu |
| **`AIService`** | POST JSON vers le backend (`improve`, `suggest-type`, `suggest-solution`, `classify-priority`) via `AI_API_BASE_URL` |
| **`IncidentPdfService`** | Génération PDF (package `pdf`) pour rapport d’incident |
| **`AuthService`** | (si présent) flux d’authentification côté app |

**Intérêt pour la soutenance** : cette séparation facilite les tests, la lecture du code et l’évolution (ex. changer d’API IA sans toucher aux écrans).

---

## 4. Navigation et rôles

- **`main.dart`** : `StreamBuilder` sur `FirebaseAuth.instance.authStateChanges()` → utilisateur non connecté → écran d’accueil / login ; connecté → **`_RoleGate`**.
- **`_RoleGate`** : lecture du document `users/{uid}` (ou recherche par `email`) pour obtenir le champ **`role`** : `admin` | `technicien` | `employe`.
- Chaque rôle a une **racine d’interface dédiée** (`AdminDashboard`, `TechnicienHomePage`, `EmployeHomePage`) avec navigation interne (barres d’onglets, routes `MaterialPageRoute`, etc.).

**Choix technique** : pas de routeur nommé complexe au départ — navigation impérative claire pour un PFE et débogage rapide.

---

## 5. Gestion d’état et streams

L’application privilégie le **modèle réactif Firestore** plutôt qu’un state global type Redux :

- **`StreamBuilder`** / **`snapshots()`** sur les collections concernées (incidents, messages, notifications).
- **`includeMetadataChanges: true`** sur certains streams pour éviter les blocages d’UI liés au cache client.
- **Agrégations** (KPI dashboard admin) : calculs **côté client** à partir du snapshot incidents (`AdminDashboardMetrics`), sans Cloud Functions obligatoires — acceptable pour un volume PFE ; en production on pourrait déporter vers des agrégats serveur.

**Message pour le jury** : le choix « streams + calculs locaux » privilégie la **simplicité** et le **temps réel** au prix d’un peu de charge CPU sur le terminal lors du scroll du dashboard.

---

## 6. Structure Firestore (conceptuelle)

Les collections principales sont décrites en détail dans **`FIREBASE.md`**. En résumé :

- **`incidents`** : document par incident ; sous-collection **`messages`** pour le chat.
- **`users`** : profils et rôles (dont `specialite`, `score` pour les techniciens).
- **`notifications`** : événements ciblés par `targetUserId`.

---

## 7. Backend Node.js (rôle dans l’architecture)

- Expose **`/ai/*`** consommés par Flutter (`AIService`).
- Ne remplace pas Firebase pour les données métier : il **complète** Firebase pour l’IA et les e-mails.
- Variables d’environnement typiques : `GROQ_API_KEY`, `GROQ_MODEL`, configuration SMTP (Mailtrap), etc.

---

## 8. Synthèse « phrase de soutenance »

> *« Nous avons une application Flutter multi-rôles branchée sur Firebase pour le temps réel et la persistance, et un petit serveur Node qui encapsule l’IA Groq et l’envoi de mails, ce qui nous permet de garder les clés API hors du client et d’ajouter des règles métier côté serveur, notamment pour la priorité des incidents. »*
