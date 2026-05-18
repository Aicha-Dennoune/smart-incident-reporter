# Firebase — données, règles et authentification

Document de référence pour la partie **Firebase** du projet (Firestore + Auth). Les noms de champs ci-dessous correspondent au code actuel ; tout champ optionnel peut évoluer selon les besoins métier.

---

## 1. Authentification Firebase

- **Firebase Auth** gère la connexion des utilisateurs (email/mot de passe selon l’implémentation écran login).
- Après connexion, l’application lit le **profil** dans Firestore (`users`) pour déterminer le **rôle** (`admin`, `technicien`, `employe`) et afficher le bon espace (`main.dart`, `_RoleGate`).
- **Choix** : le rôle dans Firestore permet à un administrateur de **modifier les droits** sans recréer de compte Auth.

---

## 2. Collections Firestore utilisées

### 2.1 `users/{userId}`

Profils applicatifs, typiquement :

| Champ (exemples) | Usage |
|-------------------|--------|
| `role` | `admin` \| `technicien` \| `employe` |
| `email` | Corrélation si le rôle n’est pas sur le doc `uid` |
| `nom`, `prenom` | Affichage, chat, PDF |
| `specialite` | Filtrage techniciens (ex. Electricite, Mecanique…) pour l’affectation |
| `score` | Gamification / classement dashboard |
| `uid` | Parfois redondant avec l’id du document |
| `lastAssignedAt` | File d’attente pour l’affectation **round-robin** |

### 2.2 `incidents/{incidentId}`

Document central du métier. Champs fréquents (d’après `IncidentService` et les écrans) :

| Champ | Description |
|-------|-------------|
| `title`, `description` | Contenu saisi par l’employé |
| `type` | Catégorie : `IT`, `Electricite`, `Mecanique`, `Eau` |
| `priority` | `Faible`, `Moyenne`, `Critique` (IA + règles serveur à la création) |
| `status` | Voir section statuts |
| `createdBy` | Identifiant déclarant (uid ou email selon stockage) |
| `assignedTo` | UID technicien affecté (ou null) |
| `location` | `GeoPoint` optionnel |
| `imageUrl` | URL Cloudinary après upload |
| `createdAt` | Horodatage serveur |
| `resolvedAt`, `closedAt`, `updatedAt` | Suivi du cycle de vie (utile PDF et stats délai) |

**Statuts normalisés** (`IncidentService.normStatus`) :

- `open` — ouvert, non pris en charge ou en attente d’affectation selon contexte.
- `in_progress` — technicien assigné, traitement en cours.
- `resolved_pending_validation` — résolution proposée, en attente de validation employé/admin.
- `closed` — incident clôturé.

### 2.3 `incidents/{incidentId}/messages/{messageId}`

Sous-collection pour le **chat** lié à l’incident (voir `CHAT_SYSTEM.md`).

Champs typiques :

- `senderId`, `senderName`, `senderRole`
- `text`
- `createdAt`
- `readBy` — liste d’UID ayant lu le message

### 2.4 `notifications/{id}`

Notifications in-app (voir `NotificationService`) :

- `targetUserId` — destinataire
- `title`, `message`
- `type` — chaîne discriminant l’événement (affectation, validation, etc.)
- `incidentId` — lien optionnel
- `isRead`, `createdAt`

---

## 3. Règles de sécurité Firestore

Le fichier **`firestore.rules`** (à la racine du dépôt, et copie possible sous `frontend/`) définit une politique **simple et pédagogique** :

- Utilisateur **authentifié** (`request.auth != null`) pour lire/écrire `incidents`, `users`, `notifications`.
- Sous-collection **`messages`** : lecture / création / mise à jour autorisées si authentifié ; **suppression interdite** (`delete: false`) pour conserver l’historique.

**Limite assumée pour un PFE** : les règles ne distinguent pas encore finement admin vs employé sur chaque champ. En entreprise, on affinerait avec des **custom claims** ou des tests sur `request.auth.uid` et le contenu du document.

---

## 4. Stockage (images)

Les photos d’incident peuvent transiter par **Cloudinary** (upload depuis le client avec preset), l’URL étant stockée dans `imageUrl`. Les **`storage.rules`** Flutter peuvent exister pour un usage Storage natif — à aligner avec le déploiement réel.

---

## 5. Bonnes pratiques évoquables à l’oral

- **Streams** avec gestion d’erreur UI (`firestore_debug`, messages utilisateur).
- **Batch** Firestore pour les mises à jour groupées (ex. marquage `readBy`).
- **Séparation** : Auth = identité ; Firestore = profil métier et données opérationnelles.
