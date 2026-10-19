# Education ERP — Complete Handover Document

**Machine:** MacBook, macOS 26.7.1 (Tahoe), Intel x86_64
**Repo:** `/Users/prathameshkasbe/Downloads/education-develop`
**Goal:** Get the Frappe Education ERP running locally at `http://education.localhost:8000`

---

## PART 1 — What Is This Project?

**Frappe Education** is an open-source Education Management System.
It is a **Frappe Framework app** — a plugin that runs on top of ERPNext.
It is **NOT a standalone app**. It requires a full infrastructure stack to run.

### What it manages:
- Student admissions, enrollment, batches
- Academic calendar (years, terms, programs, courses, subjects)
- Attendance tracking
- Assessment & grading (grade books, grading scales)
- Fee management + Razorpay online payments
- Student portal (Vue 3 SPA at `/student-portal`)
- LMS content (articles, quizzes, topics)
- ERPNext accounting integration (students = customers, fees = sales invoices)

### Tech stack:
| Layer | Tech |
|---|---|
| Backend | Python 3.14, Frappe Framework ≥17, ERPNext |
| Database | MariaDB 11.8 |
| Cache/Queue | Redis |
| Frontend | Vue 3 + Pinia + Frappe UI + Tailwind CSS 3 + Vite |
| Tooling | yarn, uv, frappe-bench CLI |

---

## PART 2 — All Bugs Found and Fixed

**All fixes are already applied to the repo. Do NOT git pull or reset.**

### CRITICAL — Would have prevented the app from running at all

| File | Bug | Fix |
|---|---|---|
| `frontend/src/router.js:46` | `next` is never declared — `ReferenceError` crashes navigation for every unauthenticated user | Replaced `return await next(false)` with `return false` |
| `frontend/src/pages/Login.vue` | `import { session } from '@/stores/session'` — `session` is `undefined`, login completely broken | Changed to `import { sessionStore }` + `const session = sessionStore()` |
| `frontend/src/stores/session.js` | `sessionUser.reload()` called on a plain function after login — `TypeError` thrown on every login | Removed the dead `.reload()` call |
| `education/education/billing.py` | `get_payment_entry` imported from `test_payment_entry` (a test file) — payments break in production | Fixed to import from production `payment_entry` module |

### HIGH — Broken features

| File | Bug | Fix |
|---|---|---|
| `frontend/src/pages/Schedule.vue` | `classSchedule.instructor` field doesn't exist — API returns `faculty_name` — instructor always blank | Changed to `classSchedule.faculty_name` |
| `frontend/src/pages/Attendance.vue` | `allStudentGroups.value[0].label` crashes if student groups haven't loaded yet | Added null/empty array guard before accessing index 0 |
| `frontend/src/pages/Leaves.vue` | Pure `<div>Leaves</div>` placeholder — completely non-functional page | Fully implemented: leave history list + Apply Leave dialog |
| `education/education/doctype/fee_schedule/fee_schedule.py` | `on_cancel` hook was commented out — cancelling a Fee Schedule didn't update its status | Restored the `on_cancel` hook |

### MEDIUM — Data/logic issues

| File | Bug | Fix |
|---|---|---|
| `frontend/src/pages/Grades.vue` | `transform: () => {}` returns `undefined` — grades table always empty | Changed to `transform: (data) => data` |
| `frontend/src/utils/index.js` | `groupBy` used `Object.keys()` on arrays — fragile and incorrect for array inputs | Rewrote to handle both arrays and objects |
| `education/hooks.py` | `global_search_doctypes` listed `Video`, `Announcement`, `Assessment Code`, `Discussion` — none of these doctype folders exist | Removed all 4 non-existent doctypes; fixed duplicate index numbers |

### LOW — Stubs / dead code

| File | Bug | Fix |
|---|---|---|
| `education/education/doctype/article/article.py` | `get_article()` method was just `pass` | Implemented to return title, content, author |
| `education/api/session.py` | Entire file was just `import frappe` — empty stub | Implemented `get_session_user()` and `logout()` helpers |

### Also added:
- `/leaves` route added to `frontend/src/router.js`
- Leaves link added to `frontend/src/components/Sidebar.vue`
- `docker/init.sh` updated to use local repo instead of pulling from GitHub and added `./env/bin/pip install -e apps/education`
- `frontend/vite.config.js` fixed: `outDir` now explicitly targets `../education/public/frontend` instead of dynamic parent folder basename
- `frontend/src/pages/Leaves.vue` fixed: corrected field name (`total_leave_days`), document status mapping (`docstatus`), and Student ID reference
- `education/education/api.py` fixed: `apply_leave` now handles string JSON payloads and persists the `Student Leave Application` record in DB
- Removed dead placeholder files: `frontend/src/components/Home.vue`, `frontend/src/pages/Home.vue`, `frontend/src/pages/SchoolDiary.vue`, and empty `doctype/program_course`
- `pyproject.toml` updated: broadened frappe dependency to `>=15.0.0` to allow running on Frappe v15/v16/v17
- Restored complete Frappe Education `README.md` documentation

---

## PART 3 — Attempting to Run the Website

### Attempt 1: Docker (FAILED)

The repo ships with `docker/docker-compose.yml` that starts MariaDB, Redis, and a frappe/bench container.

**Problem:** Turbo VPN was blocking all outbound TCP from Docker containers.
The `frappe/bench` container got stuck downloading `pip` from PyPI.

**Exact error:**
```
error: Failed to install seed packages into virtual environment
  Caused by: Failed to download pip==26.2.1
  Caused by: Request failed after 5 retries in 128.8s — operation timed out
```

**Root cause:** VPN (Turbo VPN) was active. It blocks TCP from Docker's network bridge (172.17.0.0/16).
ICMP/ping worked but all HTTP/HTTPS was blocked.

**Fix attempted:** Added `8.8.8.8` DNS to `~/.docker/daemon.json`. Disconnected VPN. Host internet worked.
Docker was still slow for bench init, so switched to native install.

---

### Attempt 2: Native macOS install (IN PROGRESS)

**Why brew is slow:** macOS 26 (Tahoe) is too new. Homebrew has no pre-built bottles for Intel x86_64 on macOS 26.
Every `brew install` compiles from source, requiring Rust (566MB) + LLVM (179MB) first. Takes 20–40 min per package.

---

## PART 4 — Current Installation State

| Dependency | Required | Status | Location |
|---|---|---|---|
| Homebrew | any | ✅ v7.0.9 | `/usr/local/bin/brew` |
| git | any | ✅ v2.50.1 | system |
| Node.js | 24 | ⚠️ v25.8.1 installed | system |
| yarn | 1.22+ | ✅ v1.22.22 | via npm |
| uv | any | ✅ v0.10.2 | `~/.local/bin/uv` |
| Python 3.14 | 3.14 | ✅ 3.14.3 | `~/.local/bin/python3.14` |
| Redis | 6+ | ✅ v8.10.2 | `/usr/local/bin/redis-server` |
| **MariaDB 11.8** | **11.8** | ❌ **NOT INSTALLED** | — |
| bench CLI | any | ✅ v5.31.0 | `~/.local/bin/bench` |
| frappe app | v15 | ✅ cloned | `~/frappe/my-bench/apps/frappe` |
| erpnext app | v15 | ❌ not installed | — |
| education app | develop | ❌ not installed | — |
| Site | — | ❌ not created | — |

### Key file locations:
- `uv` → `~/.local/bin/uv`
- `bench` → `~/.local/bin/bench`
- `python3.14` → `~/.local/bin/python3.14`
- `redis-server` → `/usr/local/bin/redis-server`
- `frappe-bench` → `~/frappe/my-bench/`
- Project repo → `/Users/prathameshkasbe/Downloads/education-develop`

### What exists in `~/frappe/my-bench/`:
```
Procfile
apps/
  frappe/        ← only this is cloned, erpnext and education are NOT yet
config/
env/
logs/
sites/
  common_site_config.json   ← no actual site created yet
```

---

## PART 5 — Exact Steps to Complete Setup (Run in Order)

### Step 1 — Install MariaDB (THE ONLY MISSING DEPENDENCY)

```bash
NONINTERACTIVE=1 HOMEBREW_NO_AUTO_UPDATE=1 brew install mariadb@11.8 pkg-config mariadb-connector-c
```

⚠️ Takes 20–40 minutes on macOS 26 — compiles from source. Let it run, don't interrupt.

Once done:
```bash
# Add to PATH permanently
echo 'export PATH="/usr/local/opt/mariadb@11.8/bin:$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Start MariaDB service
brew services start mariadb@11.8

# Secure it — set root password to 'root' when prompted
sudo mariadb-secure-installation
```

### Step 2 — Start Redis

```bash
redis-server --daemonize yes --logfile /tmp/redis.log
```

### Step 3 — Install ERPNext into bench

```bash
export PATH="/usr/local/opt/mariadb@11.8/bin:$HOME/.local/bin:$PATH"
cd ~/frappe/my-bench

bench get-app erpnext --branch version-15
```

Takes ~10 minutes.

### Step 4 — Install Education app from local repo

```bash
cd ~/frappe/my-bench

# IMPORTANT: use LOCAL path — NOT GitHub — so all bug fixes are included
bench get-app /Users/prathameshkasbe/Downloads/education-develop
```

### Step 5 — Create the site

```bash
cd ~/frappe/my-bench

bench new-site education.localhost \
  --mariadb-root-password root \
  --admin-password admin

bench --site education.localhost install-app erpnext
bench --site education.localhost install-app education
bench --site education.localhost set-config developer_mode 1
bench --site education.localhost enable-scheduler
bench use education.localhost
```

### Step 6 — Build the Vue frontend

```bash
cd ~/frappe/my-bench/apps/education/frontend
yarn install
yarn build
```

### Step 7 — Start the server

```bash
cd ~/frappe/my-bench
bench start
```

**Site is live at:** `http://education.localhost:8000`
**Login:** `Administrator` / `admin`
**Student portal:** `http://education.localhost:8000/student-portal`

---

## PART 6 — Important Notes

1. **Always set PATH before any bench command:**
   ```bash
   export PATH="/usr/local/opt/mariadb@11.8/bin:$HOME/.local/bin:$PATH"
   ```

2. **Node v25 vs v24:** Frappe officially needs v24. If there are node errors, install v24:
   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
   # restart terminal, then:
   nvm install 24 && nvm use 24 && nvm alias default 24
   ```

3. **VPN must be OFF** during any install or download. Turbo VPN blocks TCP connections.

4. **macOS 26 = slow brew.** Every `brew install` compiles from source. Normal — just wait.

5. **All bug fixes are already in the repo.** Do NOT `git pull` or reset — it will overwrite all fixes.

6. **bench get-app for education MUST use local path:**
   ```bash
   bench get-app /Users/prathameshkasbe/Downloads/education-develop
   # NOT: bench get-app education  ← that pulls unfixed code from GitHub
   ```

7. **`~/frappe/my-bench` already exists** — do NOT run `bench init` again.
   Start from Step 3 (get-app erpnext) directly.

8. **If `bench new-site` fails** with MariaDB connection error:
   ```bash
   # Check MariaDB is running
   brew services list | grep mariadb
   # Check it's on PATH
   which mariadb
   ```

---

## PART 7 — Verify Everything Works

After `bench start` is running:

```bash
# Server health check
curl -s -o /dev/null -w "%{http_code}" http://education.localhost:8000
# expected: 200 or 302

# Education API check
curl http://education.localhost:8000/api/method/education.education.api.get_school_abbr_logo
# expected: {"message": {...}}

# Open in browser
open http://education.localhost:8000
# Login: Administrator / admin

# Student portal
open http://education.localhost:8000/student-portal
```
