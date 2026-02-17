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

- In the same project: **New** → **GitHub Repo** (or **Empty Service** if you’ll connect repo later).
- If you deploy from a **monorepo** (e.g. Minerva Health repo with an Xcode app + `backend` folder):
  - Select the repo and branch.
  - In the backend service: **Settings** → **Root Directory** → set to **`Minerva Health/WomensHealthApp/WomensHealthApp/backend`** (or wherever your `backend` folder lives relative to the repo root). Adjust the path if your repo layout is different.
- If the **whole repo is only the backend** (e.g. you copied `backend` into its own repo), leave Root Directory blank.

### 4. Link Postgres and set variables

- In the **backend** service: **Variables** (or **Connect** to the Postgres service).
- Ensure **DATABASE_URL** is set (Railway usually adds it when you connect the Postgres service).
- Add:
  - **JWT_SECRET** – any long random string (e.g. 32+ characters). You can generate one at [randomkeygen.com](https://randomkeygen.com) or use a password generator.

### 5. Build and start commands

In the backend service → **Settings**:

- **Build Command:**
  ```bash
  npm install && npx prisma generate && npx prisma db push && npm run build
  ```
  This installs deps, generates Prisma client, creates/updates tables in Postgres, and compiles TypeScript.

- **Start Command:**
  ```bash
  npm start
  ```

- **Watch Paths** (optional): set to `backend` or the path to your backend folder so only backend changes trigger a redeploy.

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
