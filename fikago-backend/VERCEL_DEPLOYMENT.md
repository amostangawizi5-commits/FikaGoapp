# Ku-host FikaGo kwenye Vercel

Backend ya FikaGo ni Express na PostgreSQL. Vercel inaweza kuendesha Express kama Function; PostgreSQL itaunganishwa kupitia Neon Marketplace, na picha zitahifadhiwa Vercel Blob.

**Kumbuka:** Vercel Hobby ya bure ni kwa matumizi binafsi yasiyo ya kibiashara. Kwa FikaGo ikitumika kama biashara ya delivery, Vercel inahitaji Pro; Neon na Blob free limits haziondoi masharti hayo. [Vercel Hobby plan](https://vercel.com/docs/plans/hobby)

## 1. Tuma code GitHub

Kutoka kwenye folder kuu la repo:

```sh
git add README.md fikago-backend/.env.example fikago-backend/.vercelignore fikago-backend/VERCEL_DEPLOYMENT.md fikago-backend/config/db.js fikago-backend/package.json fikago-backend/package-lock.json fikago-backend/routes/upload.js fikago-backend/server.js fikago-backend/scripts/prepareDb.js fikago_customer/lib/config/api_config.dart
git commit -m "Prepare FikaGo backend for Vercel"
git push
```

Usiweke `.env.development` au siri nyingine GitHub.

## 2. Unda Vercel project

1. Vercel Dashboard → **Add New** → **Project** → chagua GitHub repo ya FikaGo.
2. Weka **Root Directory** kuwa `fikago-backend`.
3. Acha Vercel itambue Node.js/Express. Entry point `server.js` inau-export Express app na inatambulika na Vercel.
4. Deploy mara ya kwanza.

Express kwenye Vercel huwa Function moja; usiweke server ya background ndani ya `npm start`. [Express on Vercel](https://vercel.com/docs/frameworks/backend/express)

## 3. Unganisha PostgreSQL ya Neon

1. Kwenye project ya Vercel, fungua **Storage/Marketplace** na uchague **Neon Postgres**.
2. Tengeneza database na uunganishe kwenye project.
3. Hakikisha Vercel ina environment variable `DATABASE_URL` yenye **pooled connection string**. Integration inaweza kuiweka yenyewe; ikikosekana, ongeza kutoka Neon kwenye **Settings → Environment Variables** kwa Production, Preview na Development.

Vercel Postgres mpya haitolewi tena kama bidhaa yake; PostgreSQL mpya inaunganishwa kupitia Marketplace. Neon ina free tier yenye vikomo vya matumizi, na limits zinaweza kubadilika. [Vercel Marketplace storage](https://vercel.com/docs/marketplace-storage) · [Neon free tier](https://neon.com/blog/neon-free-plan-1-gb-per-project)

## 4. Hamisha schema na data, kisha endesha migrations

Repository ina migrations za kuongeza mabadiliko, lakini haina schema ya msingi ya kuunda tables zote. Kama una database ya FikaGo iliyopo, hamisha kwanza kutoka kompyuta yako kwenda Neon ukitumia connection strings za source na Neon:

```sh
export SOURCE_DATABASE_URL='URL_YA_DATABASE_YAKO_ILIYOPO'
export DATABASE_URL='DIRECT_NEON_URL'
pg_dump "$SOURCE_DATABASE_URL" --no-owner --no-privileges > /tmp/fikago.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f /tmp/fikago.sql
```

Kisha, ukiwa `fikago-backend`, endesha migrations zote mara moja:

```sh
for file in migrations/*.sql; do
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file" || exit 1
done
DATABASE_URL="$DATABASE_URL" npm run db:prepare
```

Tumia connection string ya moja kwa moja ya Neon kwa `pg_dump` na migrations; weka pooled URL kwenye Vercel kwa API. Migrations zisikimbizwe kila Function inapoanza. Kama huna database ya zamani, utahitaji kuandaa schema ya msingi kabla ya API kuweza kutumia database tupu.

## 5. Weka variables na Blob storage

Kwenye **Settings → Environment Variables**, weka:

- `DATABASE_URL` — Neon pooled connection string
- `JWT_SECRET` — siri ndefu na ya kipekee
- `JWT_EXPIRES_IN=7d`
- `GOOGLE_MAPS_API_KEY` — ikiwa unatumia Google geocoding
- `SELCOM_API_KEY`, `SELCOM_API_SECRET`, `SELCOM_VENDOR_ID`, `SELCOM_ENVIRONMENT`
- `OTP_EXPIRY_MINUTES=5`

Kwenye **Storage/Marketplace**, tengeneza **Vercel Blob** yenye access ya **Public** na uiunganishe na project kwa Production. Vercel itaongeza `BLOB_READ_WRITE_TOKEN`. Upload endpoint imewekewa kikomo cha 4 MB kwa sababu Vercel Functions ina payload limit ya 4.5 MB. [Vercel Blob](https://vercel.com/docs/vercel-blob) · [Function limits](https://vercel.com/docs/functions/limitations)

Picha za zamani zilizohifadhiwa kwenye `fikago-backend/uploads` hazitahamia zenyewe. Zipandishe Blob na usasishe URLs zake kwenye database ikiwa unazo.

## 6. Deploy na angalia API

Redeploy project, kisha fungua:

```text
https://JINA-LA-PROJECT.vercel.app/api/health
```

Inapaswa kurudisha `healthy`. Kagua **Deployments → Functions/Logs** ikiwa kuna hitilafu.

## 7. Tumia API URL kwenye Flutter

```sh
cd fikago_customer
flutter build apk --dart-define=API_BASE_URL=https://JINA-LA-PROJECT.vercel.app
```
