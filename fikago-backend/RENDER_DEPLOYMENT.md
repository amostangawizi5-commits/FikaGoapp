# Ku-host FikaGo backend kwenye Render

Backend ya FikaGo ni Node.js/Express na PostgreSQL. Render Web Service inaiendesha kama server ya kawaida.

## 1. Tengeneza Web Service

Kwenye Render, chagua repository ya FikaGo na tumia mipangilio hii:

- **Root Directory:** `fikago-backend`
- **Build Command:** `npm ci`
- **Start Command:** `npm start`
- **Health Check Path:** `/api/health`
- Chagua region moja kwa API na PostgreSQL.

Render itaweka `PORT` yenyewe; API tayari inasikiliza `0.0.0.0` na kutumia variable hiyo.

## 2. Tengeneza PostgreSQL na hamisha schema

Tengeneza Render PostgreSQL kwenye region ileile na Web Service. Weka internal connection URL ya database kwenye environment variable `DATABASE_URL` ya Web Service.

Database mpya haina tables za msingi za FikaGo: repository hii ina migrations za kuongeza/ku-update schema, lakini haina migration ya kuunda schema yote ya mwanzo. Kama una database ya FikaGo iliyopo, hamisha schema na data yake kwanza kutoka kwenye kompyuta yako:

```sh
pg_dump "$SOURCE_DATABASE_URL" --no-owner --no-privileges > fikago-db.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f fikago-db.sql
```

Baada ya schema ya msingi kuwepo, endesha migrations zilizopo na maandalizi ya ziada mara moja dhidi ya database ya Render:

```sh
for file in migrations/*.sql; do
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file" || exit 1
done
npm run db:prepare
```

Amri hizo zinaendeshwa ukiwa ndani ya `fikago-backend`, ukiwa na `DATABASE_URL` ya database lengwa kwenye mazingira ya terminal. Usiziweke kwenye `npm start`; Function/server ikianza haipaswi kubadilisha schema kila deploy.

## 3. Weka environment variables

Ongeza kwenye Render → Web Service → **Environment**:

- `NODE_ENV=production`
- `DATABASE_URL` — internal URL ya PostgreSQL ya Render
- `JWT_SECRET` — siri ndefu na ya kipekee kwa production
- `JWT_EXPIRES_IN=7d`
- `GOOGLE_MAPS_API_KEY` — ikiwa geocoding ya Google itatumika
- `SELCOM_API_KEY`, `SELCOM_API_SECRET`, `SELCOM_VENDOR_ID`, `SELCOM_ENVIRONMENT`
- `OTP_EXPIRY_MINUTES=5`
- `UPLOADS_DIR=/var/data/uploads`

## 4. Hifadhi picha zinazopakiwa

Uploads zinahitaji filesystem ya kudumu. Render filesystem ya kawaida husafishwa kwenye redeploy/restart; persistent disk inapatikana kwa paid Web Service. Unganisha disk yenye **mount path** `/var/data`, na weka `UPLOADS_DIR=/var/data/uploads` kwenye environment. Bila disk, picha zilizopakiwa zinaweza kupotea baada ya restart au deploy.

## 5. Unganisha app ya Flutter

Tumia URL ya Web Service ya Render unapojenga app, badala ya URL ya `localhost`:

```sh
flutter build apk --dart-define=API_BASE_URL=https://JINA-LA-SERVICE.onrender.com
```

API ya kuangalia baada ya deploy: `https://JINA-LA-SERVICE.onrender.com/api/health`.
