# Obsidian → Vercel Course Notes Publish

Automatically publishes selected directories from an Obsidian vault as a static
site on Vercel via [Quartz 5](https://quartz.jzhao.xyz). Runs on a schedule
(every 6h) plus manual triggers.

## How it works

1. **Sync + build happen in GitHub Actions.** `.github/workflows/publish.yml`
   runs on a cron + `workflow_dispatch`, clones your *private vault repo* with a
   PAT, copies only the whitelisted directories into `content/` (via
   `scripts/sync.sh`), and builds the static site with Quartz.
2. **The build runs on GitHub's large VMs, not Vercel.** This matters: your
   vault's ~100 MB of media needs ~7 GB of memory to build, but Vercel's Hobby
   sandbox only allows 3 GB — building on Vercel directly would crash.
3. **Vercel only receives the finished `public/` folder** via the CLI
   (`vercel deploy --prod --prebuilt`). No heavy content is ever committed to
   this repo.

So the notes repo is small (just the Quartz scaffold + scripts), your full vault
and its 50 MB PDFs never leave GitHub, and Vercel never touches a build it
can't fit in memory.

## What gets published

Only the directories listed in `VAULT_DIRS` inside `scripts/sync.sh`. It already
drops hidden junk (`.obsidian`, `.trash`, `Thumbs.db`, `.DS_Store`) and builds a
`content/index.md` hub page that links to each notebook. Edit that list to
change what's public.

## One-time setup

### 1. Push your vault to a private GitHub repo
```bash
cd "/c/Users/tharl/Document/Obsidian Vault"
git init
git add -A
git commit -m "Initial vault import"
# create a PRIVATE repo on GitHub, then:
git remote add origin git@github.com:<you>/obsidian-vault.git
git push -u origin main
```
If you installed the **Obsidian Git** plugin, enable *auto commit/push* in its
settings so the vault keeps itself in sync without manual pushes.

### 2. Create a fine-grained PAT for the vault repo
GitHub → Settings → Developer settings → Personal access tokens → Fine-grained
tokens → New token. Scope: **Read access** to just `obsidian-vault`. Copy the
token.

### 3. Add secrets to this repo
Repo → Settings → Secrets and variables → Actions → New repository secret:
- `VAULT_REPO` → `https://github.com/<you>/obsidian-vault`
- `VAULT_PAT` → the fine-grained token from step 2
- `VERCEL_TOKEN` → Vercel → Settings → Tokens → Create (copy the token)
- `VERCEL_ORG_ID` / `VERCEL_PROJECT_ID` → get both by running `npx vercel link`
  once locally (it writes a `.vercel/project.json`), then copy the `teamId`
  and `projectId` values.

### 4. Set your site URL (do this before the first deploy)
Open `quartz.config.yaml` and change `baseUrl` (currently `notes.example.com`)
to your real Vercel URL, e.g. `https://<project>.vercel.app`.

### 5. Push this repo and trigger a deploy
1. Create an empty GitHub repo (public or private).
2. `git remote set-url origin git@github.com:<you>/notes.git`
3. `git push -u origin v5`
4. In the GitHub Actions tab, run the **"Build notes & deploy to Vercel"**
   workflow manually (`Run workflow`) to verify end-to-end before relying on the
   cron.

## Manual / local usage
```bash
# Stage the latest notes into content/ (uses your local vault by default)
bash scripts/sync.sh

# Install plugins, then build locally to preview
npm ci
npm run install-plugins
npx quartz build

# Preview at localhost:8080
npx quartz build --serve
```

## Add a directory
Edit `scripts/sync.sh` → add a line to `VAULT_DIRS`, commit, push. The cron and
Vercel handle the rest.

## Change the schedule
Edit the `cron:` line in `.github/workflows/publish.yml`. GitHub uses UTC.