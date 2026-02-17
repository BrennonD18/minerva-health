# Minerva Health Backend

Node.js + TypeScript + Express API with Postgres (Prisma). Deploy to **Railway** only—no local run required.

---

## Deploy to Railway (only steps you need)

### 1. Push your code

Make sure the `backend` folder (and the rest of the repo) is pushed to GitHub (or another Git provider Railway supports).

### 2. Create a project and add Postgres

- Go to [railway.app](https://railway.app) and log in.
- **New Project** → **Add PostgreSQL** (or use your existing Postgres service).
- Note: Railway will create a `DATABASE_URL` variable for this database.

### 3. Add the backend service

- In the same project: **New** → **Deploy from GitHub** → select **BrennonD18/minerva-health** (and branch **main**).
- **Important:** In the new service, open **Settings** → **Source** (or **General**) and set **Root Directory** to:
  ```text
  Minerva Health/WomensHealthApp/WomensHealthApp/backend
  ```
  That way Railway builds only the Node backend (and uses the `Dockerfile` there), not the whole repo. If your repo layout is different, set it to the folder that contains `package.json` and `Dockerfile`.

### 4. Link Postgres and set variables

- In the **backend** service: **Variables** (or **Connect** to the Postgres service).
- Ensure **DATABASE_URL** is set (Railway usually adds it when you connect the Postgres service).
- Add:
  - **JWT_SECRET** – any long random string (e.g. 32+ characters). You can generate one at [randomkeygen.com](https://randomkeygen.com) or use a password generator.

### 5. Build (Dockerfile)

The backend folder includes a **Dockerfile**. Once **Root Directory** is set to the backend folder, Railway will detect it and build with Docker. No need to set custom build or start commands—the Dockerfile handles install, Prisma generate, build, and on start it runs `prisma db push` then the server.

If Railway does not use the Dockerfile automatically, in **Settings** → **Build** set **Builder** to **Dockerfile** (if available).

### 6. Deploy

- Click **Deploy** (or push to the connected branch). Railway will build and run the backend.
- When it’s live, open the **backend** service → **Settings** → **Networking** → **Generate Domain** to get a public URL like `https://minerva-backend-production.up.railway.app`.

### 7. Check it’s running

Open in a browser or with curl:

```text
https://YOUR-RAILWAY-URL/health
```

You should see: `{"status":"ok","service":"minerva-backend"}`.

---

## API (for your iOS app)

| Method | Path        | Description |
|--------|-------------|-------------|
| GET    | `/health`   | Health check (no auth). |
| POST   | `/auth/apple` | Sign in with Apple. Body: `{ "appleId": "…", "email?", "name?" }`. Returns `{ token, user }`. |
| GET    | `/me`       | Current user. Header: `Authorization: Bearer <token>`. |

Use your Railway backend URL as the base (e.g. `https://your-app.up.railway.app`) when calling these from the Minerva Health app.

---

## No local setup

You don’t need to run anything locally. Tables are created/updated on each deploy by `npx prisma db push` in the build command. If you ever want to run or debug locally, see `.env.example` and use `npm run dev` after setting `DATABASE_URL` and `JWT_SECRET`.
