# Système de discussion (chat) incident

Le chat permet l’échange **textuel** autour d’un **incident donné**, principalement entre **employé** et **technicien**, avec synchronisation **temps réel** via Firestore.

---

## 1. Modèle de données

- **Chemin Firestore** : `incidents/{incidentId}/messages/{messageId}`
- Chaque message est un document avec notamment :
  - **`senderId`** — UID de l’expéditeur
  - **`senderName`** — nom affiché (lu depuis `users` côté client au moment de l’envoi)
  - **`senderRole`** — rôle au moment de l’envoi (`employe`, `technicien`, etc.)
  - **`text`** — contenu du message (trim côté serveur client)
  - **`createdAt`** — `FieldValue.serverTimestamp()`
  - **`readBy`** — tableau d’UID ; initialisé avec **`[senderId]`** à la création

**Choix métier** : sous-collection **par incident** pour isoler les conversations et simplifier les règles de sécurité et les requêtes.

---

## 2. Service `ChatService`

Responsabilités principales :

| Méthode | Description |
|---------|-------------|
| `watchMessages(incidentId)` | Stream ordonné par `createdAt` croissant — alimente la liste de bulles |
| `watchLatestMessage(incidentId)` | Dernier message (aperçu dans listes technicien) |
| `sendMessage(...)` | Ajout d’un document message avec `readBy` contenant l’expéditeur |
| `markAllAsRead(incidentId, currentUserId)` | Parcourt les messages ; pour chaque message **non écrit par** l’utilisateur courant et **sans** son UID dans `readBy`, fait un `arrayUnion` sur `readBy` |

**Remarque** : `markAllAsRead` utilise un **batch** Firestore pour limiter les allers-retours réseau.

---

## 3. Interface `IncidentChatPage`

- **`StreamSubscription`** sur `watchMessages` : à chaque émission, appelle **`markAllAsRead`** puis fait défiler la liste vers le bas (`ScrollController`).
- Envoi : récupération du nom utilisateur via **`users/{currentUserId}`**, puis `sendMessage`.
- L’écran reçoit `incidentId`, titre, IDs et rôles pour contextualiser la discussion.

**Intérêt UX** : ouvrir le chat = considérer les messages **lus** pour l’utilisateur courant (logique « boîte de réception » simplifiée).

---

## 4. Temps réel avec `StreamBuilder`

Les listes de messages ou d’aperçus utilisent des **`StreamBuilder<QuerySnapshot>`** branchés sur les streams du `ChatService`, ce qui :

- met à jour l’UI **sans polling** ;
- reste cohérent avec le modèle **réactif** du reste de l’app (incidents, notifications).

---

## 5. Notifications liées au chat

Les **notifications push/in-app** pour d’autres événements (affectation, résolution…) sont gérées par **`NotificationService`** et **`IncidentService`** (création de documents `notifications` avec `targetUserId`, `type`, etc.). Le chat lui-même repose sur l’**écriture directe** des messages ; des extensions possibles seraient : notifier le destinataire à chaque nouveau message via Cloud Function.

---

## 6. Sécurité (Firestore)

Les règles typiques autorisent `read` / `create` / `update` sur `messages` pour un utilisateur authentifié, et **interdisent la suppression** pour garder une **trace auditable** — pertinent en contexte industriel / traçabilité.

---

## 7. Phrase de conclusion (soutenance)

> *« Le chat est une sous-collection Firestore par incident, avec un champ readBy pour savoir qui a lu quoi ; le StreamBuilder met l’interface à jour en temps réel et on marque les messages comme lus à l’arrivée sur l’écran de conversation. »*
