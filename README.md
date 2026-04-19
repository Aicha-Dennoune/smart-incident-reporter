# Projet Mobile - Flutter + Node.js + Firebase

Structure separee frontend/backend pour demarrer rapidement le developpement.

## Structure

- `frontend/` : application mobile Flutter
- `backend/` : API Node.js (Express) + Firebase Admin

## 1) Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

## 2) Backend (Node.js)

```bash
cd backend
npm install
copy .env.example .env
npm run dev
```

API test:
- `GET http://localhost:5000/api/health`

## 3) Firebase (Backend)

1. Creer un projet Firebase
2. Generer une cle de compte de service (JSON)
3. Mettre le fichier dans `backend/serviceAccountKey.json`
4. Dans `backend/.env`, verifier:

```env
FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
```

Ensuite relancer:

```bash
npm run dev
```
