# Tableau de bord administrateur

Le **dashboard admin** regroupe indicateurs, graphiques et listes pour donner une **vue opérationnelle** des incidents. Les calculs sont réalisés **côté client** à partir d’un snapshot Firestore des incidents (et d’autres streams pour techniciens / notifications).

---

## 1. Source des données

- **Incidents** : `FirebaseFirestore.instance.collection('incidents').snapshots(includeMetadataChanges: true)`.
- **Techniciens** : `IncidentService.watchTechnicians()`.
- **Activité (timeline)** : `NotificationService.watchForUser(uid)` pour l’admin connecté, documents triés avec `sortedNotificationDocs`, limités aux entrées récentes.

**Choix** : pas d’agrégation Cloud Function dans cette version — adapté à un volume modéré (PFE / démo) ; documenter la **limite** à l’oral si on augmente fortement le nombre d’incidents.

---

## 2. KPI (indicateurs clés)

La classe **`AdminDashboardMetrics`** agrège les documents incidents. Indicateurs présentés dans l’UI (cartes avec progression animée) :

| KPI | Calcul (logique) |
|-----|------------------|
| **Total incidents** | Nombre de documents |
| **Résolus** | `status` normalisé = `closed` |
| **En cours** | `in_progress` |
| **Non affectés** | `open` **et** `assignedTo` (clé tolérante) vide |
| **En validation** | `resolved_pending_validation` |
| **Satisfaction (indice)** | `(résolus / total) * 100` arrondi, borné 0–100 — **indicateur synthétique** de taux de clôture, pas un sondage utilisateur |

Les barres de progression sur les cartes utilisent des ratios du type « part sur le total » ou « satisfaction / 100 » pour un rendu visuel immédiat.

---

## 3. Jauges circulaires

- **Taux de résolution** : `résolus / total` en pourcentage (jauge animée).
- **Temps moyen de résolution** : moyenne des durées **(date fin − date création)** en heures, pour les incidents **fermés**, en utilisant les champs horodatage disponibles (`closedAt`, `resolvedAt`, `updatedAt` selon ce qui est présent).  
  - Affichage en **heures** ou **minutes** si &lt; 1 h.  
  - Jauge normalisée sur une échelle (ex. 72 h max) pour l’angle visuel.

---

## 4. Graphiques (`fl_chart`)

| Graphique | Contenu |
|-----------|---------|
| **Donut** | Répartition par `type` : IT, Electricite, Mecanique, Eau ; segment **Autre** si des incidents ont un type hors liste |
| **Barres (7 jours)** | Nombre d’incidents **créés** par jour sur une fenêtre glissante de 7 jours ; tooltips au toucher |
| **Sparkline (30 jours)** | Même principe sur 30 jours ; courbe lissée avec dégradé sous la courbe |

Les libellés d’axes temporels peuvent utiliser **`intl`** (locale française).

---

## 5. Top techniciens

- Données : snapshot **`users`** avec `role == technicien`, tri par **`score`** décroissant.
- **Podium** : top 3 avec hauteurs différenciées (1er au centre).
- **Liste top 5** : rang, étoile, nom formaté, spécialité, **nombre d’incidents critiques résolus** (comptage incidents `closed` + priorité critique + `assignedTo` = UID technicien).

**Valeur métier** : mettre en avant les **bons répondeurs** sur les urgences, pas seulement le score global.

---

## 6. Incidents critiques récents

- Filtre : priorité contenant la notion **critique** (aligné sur le champ `priority`).
- Tri par **`createdAt`** décroissant.
- Carte avec badges **priorité** et **statut** (couleurs rouge / orange / violet selon statut).

---

## 7. Bannière et badge « urgents »

- **Bannière** : affichée si le nombre d’incidents **ouverts non affectés** &gt; 0 — message d’action pour l’administrateur.
- **Badge AppBar** : compteur animé (même métrique), cohérent avec le thème **`IndustrialTokens`** à côté de la cloche de notifications.

---

## 8. Rafraîchissement

- **`RefreshIndicator`** sur le scroll principal : déclenche un `get()` sur la collection `incidents` pour forcer une resynchronisation avec le serveur (comportement « pull to refresh »).

---

## 9. Point à mentionner en soutenance

> *« Le dashboard ne duplique pas la vérité dans une autre base : il lit Firestore en direct et calcule les KPI à la volée, ce qui garantit la cohérence avec les écrans incidents, au prix d’un peu de calcul sur le terminal. »*
