# Export PDF — rapport d’incident

L’export PDF permet au **technicien** (ou au flux prévu dans l’UI) de générer un **document formel** récapitulant un incident, utile pour archivage, transmission hiérarchique ou soutenance (preuve de fonctionnalité métier).

---

## 1. Technologies

- Package Flutter **`pdf`** : construction du document en mémoire (`pw.Document`, `pw.MultiPage`).
- **`printing`** (si utilisé ailleurs) peut servir à l’aperçu / impression depuis l’app — le cœur de la génération est dans **`IncidentPdfService`**.

---

## 2. Données d’entrée — `IncidentPdfPayload`

Le service reçoit un objet fortement typé regroupant :

- Titre, type, description, **statut** (libellé déjà traduit côté UI si besoin)
- **Dates** : création, résolution (nullable)
- **Noms** : employé déclarant, technicien assigné
- **Libellé de localisation** (texte)
- **URL d’image** incident (téléchargement HTTP pour intégration dans le PDF)
- **Texte de solution** (proposée / appliquée)

Cette couche **payload** sépare la **composition PDF** des détails Firestore : l’écran collecte les données et appelle `buildIncidentPdf`.

---

## 3. Contenu du PDF (structure)

1. **Logo OCP** — chargé depuis l’asset **`assets/images/OCP_LOGO.png`** (`rootBundle`). Si le fichier est absent, le PDF est quand même généré **sans** logo (robustesse).
2. **Titre central** : « RAPPORT D’INCIDENT INDUSTRIEL ».
3. **Section Informations incident** : tableau clé / valeur (titre, type, description, statut, dates).
4. **Employé déclarant** — paragraphe texte.
5. **Technicien assigné** — paragraphe texte.
6. **Localisation** — texte ou « Non renseignée ».
7. **Image incident** (optionnelle) : si le téléchargement réussit, image encadrée (`BoxFit.contain`).
8. **Solution technique appliquée** — paragraphe (ou « — » si vide).
9. **Pied de page** : mention de génération automatique par **Smart Incident Reporter**.

**Format** : A4, marges définies, style sobre (gris / bleu gris) pour un rendu « rapport ».

---

## 4. Téléchargement de l’image réseau

- La méthode privée **`_downloadNetworkImage`** effectue un `http.get` sur l’URL Cloudinary (ou autre) stockée dans l’incident.
- En cas d’échec (réseau, 404), le PDF **n’inclut pas** la section image — pas d’exception bloquante pour l’utilisateur.

---

## 5. Intégration côté UI

L’écran **détail technicien** compose le payload à partir des champs Firestore / utilisateurs et déclenche la génération ; le fichier peut ensuite être partagé ou ouvert via les APIs plateforme (selon implémentation bouton).

---

## 6. Intérêt métier (oral)

- **Traçabilité** : document unique exportable hors application.
- **Image + solution** : relie le terrain à l’action corrective.
- **Logo entreprise** : ancrage du rapport dans l’identité **OCP** du contexte de stage.

---

## 7. Limite honnête pour le jury

Le PDF est généré **côté client** : pour de très gros volumes ou modèles complexes, on pourrait déporter la génération sur un **Cloud Function** avec stockage dans Cloud Storage — hors scope actuel du PFE.
