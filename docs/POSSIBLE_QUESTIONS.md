# Questions / réponses possibles — soutenance PFE

Document d’**entraînement** : formulations courtes à adapter selon votre jury. Restez factuel par rapport à ce qui est **réellement implémenté** dans le dépôt.

---

## A. Architecture & choix technologiques

**Q : Pourquoi Flutter ?**  
**R :** Un seul codebase pour Android / iOS / Web, UI réactive, intégration native avec les SDK Firebase ; cela réduit le temps de développement pour un PFE tout en donnant un rendu professionnel.

**Q : Pourquoi Firebase plutôt qu’une API REST classique pour tout ?**  
**R :** Les incidents et le chat sont fortement **temps réel** ; Firestore avec des streams évite de gérer nous-mêmes WebSockets et la synchronisation. Le backend Node sert surtout à l’**IA** et aux **e-mails**, où on veut cacher les clés et contrôler les appels.

**Q : Où est la « logique métier » ?**  
**R :** Une partie est dans les **services Dart** (affectation, statuts, notifications), une partie sur le **serveur** (règles de priorité avant Groq), et les règles de sécurité dans **Firestore** — c’est une répartition classique progressive pour un projet étudiant.

---

## B. Fonctionnel — parcours utilisateur

**Q : Que peut faire l’employé ?**  
**R :** Déclarer un incident (texte, type, localisation, photo), suivre ses dossiers, échanger avec le technicien, valider ou refuser une résolution selon les écrans prévus.

**Q : Que peut faire le technicien ?**  
**R :** Voir les incidents **assignés**, changer le statut, discuter dans le chat, utiliser les aides IA (description / solution / type selon UI), exporter un PDF de rapport.

**Q : Que peut faire l’admin ?**  
**R :** Tableau de bord avec KPI et graphiques, gestion des utilisateurs, affectation des incidents (manuel ou tour à la file), vue liste des incidents et priorités.

---

## C. Sécurité

**Q : Est-ce sécurisé ?**  
**R :** L’accès Firestore est conditionné à **`request.auth != null`** dans les règles fournies ; les clés **Groq** ne sont pas dans l’app. Pour un déploiement production, on durcirait les règles par rôle (admin seul peut modifier certains champs, etc.) et on activerait les **règles Storage** adaptées.

**Q : Les messages peuvent-ils être effacés ?**  
**R :** Dans les règles du projet, la **suppression** des messages est interdite — on privilégie l’**historique** et la traçabilité.

---

## D. Intelligence artificielle

**Q : Quel modèle utilisez-vous ?**  
**R :** Le backend appelle l’API **Groq** avec un modèle configurable (`GROQ_MODEL`, défaut type Llama instant). Le fichier serveur s’appelle `gemini.js` par historique mais le code est bien Groq.

**Q : Pourquoi des règles en plus du LLM pour la priorité ?**  
**R :** Un modèle peut se tromper sur un cas critique (incendie, fuite gaz). Les mots-clés métier forcent **Critique**, **Faible** ou **Moyenne** avant d’appeler l’IA, ce qui est plus **fiable** pour un site industriel.

**Q : Si l’IA est down ?**  
**R :** La création d’incident garde une **priorité par défaut** ; le serveur renvoie une erreur contrôlée si la clé Groq manque.

---

## E. Firebase & données

**Q : Comment sont structurés les messages ?**  
**R :** Sous-collection `incidents/{id}/messages` avec expéditeur, texte, date et tableau `readBy` pour savoir qui a lu.

**Q : Comment gérez-vous les notifications ?**  
**R :** Collection `notifications` avec `targetUserId`, type, lien incident optionnel ; l’UI admin peut afficher une timeline ; la cloche utilise les **non lus**.

---

## F. Performance & limites

**Q : Le dashboard ne ralentit-il pas l’app ?**  
**R :** Les calculs sont faits sur le **client** à partir du snapshot ; pour une grosse entreprise on pourrait pré-calculer des agrégats. Pour un PFE et des volumes de démo, c’est un bon compromis simplicité / temps réel.

**Q : Limites du projet ?**  
**R :** Règles Firestore simplifiées, pas de suite de tests automatisés exhaustive, dépendance à des services externes (Groq, Cloudinary, SMTP) à configurer pour la démo.

---

## G. Questions « piège » courtes

| Question | Réponse en une phrase |
|----------|------------------------|
| Pourquoi Node et pas uniquement Cloud Functions ? | Pour garder un serveur Express simple, facile à lancer en local et à montrer au jury avec des logs. |
| Pourquoi `readBy` en tableau ? | Modèle simple pour savoir quels utilisateurs ont vu le message sans table jointure. |
| Priorité « satisfaction » sur le dashboard ? | C’est un **indice** basé sur le taux de clôture, pas un questionnaire utilisateur — le nom pourrait être affiné en « taux de résolution » en entreprise. |

---

## H. Conclusion personnelle (à personnaliser)

> *« Le projet démontre une chaîne complète : déclaration terrain, priorisation assistée, affectation, collaboration temps réel, validation et export PDF, avec une séparation claire entre données Firebase et intelligence sur serveur. »*
