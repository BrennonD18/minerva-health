# Push Minerva Health to GitHub

Follow these steps to create a GitHub repo and push your project.

---

## Step 1: Create a new repository on GitHub

1. Go to **https://github.com/new**
2. **Repository name:** e.g. `minerva-health` or `Minerva-Health`
3. **Description (optional):** e.g. "Women's health tracking app with Luna AI"
4. Choose **Private** or **Public**
5. **Do not** check "Add a README", ".gitignore", or "License" (you already have code)
6. Click **Create repository**

---

## Step 2: Add the remote and push (in Terminal)

GitHub will show you commands. Use these from your project folder.

**If you're in the Minerva Health project folder** (the one that contains `Minerva Health.xcodeproj` and the `Minerva Health` folder):

```bash
# Add GitHub as the remote (replace YOUR_USERNAME and YOUR_REPO with your actual GitHub repo)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Stage and commit all current work
git add -A
git status   # optional: check what will be committed
git commit -m "Add Minerva Health app, backend, and HealthKit"

# Push to GitHub (main branch)
git push -u origin main
```

**Example** if your repo is `https://github.com/brennondoman/minerva-health`:

```bash
git remote add origin https://github.com/brennondoman/minerva-health.git
git add -A
git commit -m "Add Minerva Health app, backend, and HealthKit"
git push -u origin main
```

---

## Step 3: Use the repo in Railway

In Railway: **New** → **Deploy from GitHub** → select **minerva-health** (or whatever you named it). Set the **Root Directory** to your backend folder (e.g. `Minerva Health/WomensHealthApp/WomensHealthApp/backend`).

Done.
