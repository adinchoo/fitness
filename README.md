# Fitness AI Hub with Supabase

## 1. Prepare Supabase
1. Open Supabase Dashboard > SQL Editor.
2. Paste the complete contents of `supabase-schema.sql`.
3. Click Run once.
4. Open Authentication > URL Configuration.
5. Set Site URL to your GitHub Pages URL.
6. Add both your GitHub Pages URL and local test URL to Redirect URLs, for example:
   - `https://YOUR-USERNAME.github.io/fitness-ai-supabase/`
   - `http://localhost:8080/`
7. Under Authentication > Providers > Email, keep Email enabled. For easiest private testing, you may disable Confirm email. For normal use, keep confirmation enabled.

## 2. Get connection values
Open Project Settings or Connect dialog and copy:
- Project URL
- Publishable key, or legacy anon public key

Never use a service_role or secret key in browser code.

## 3. Test locally
Run in this folder:

```bash
python -m http.server 8080
```

Open `http://localhost:8080`.

The first screen securely asks for the project URL and publishable/anon key. They remain in this browser and are not hardcoded in GitHub.

## 4. Deploy to GitHub Pages
Upload all extracted files preserving folders. In repository Settings > Pages, deploy from `main` and `/(root)`.

## 5. Sign-up flow
The user enters account credentials and health profile details. Supabase Auth creates the account. The database trigger creates the protected profile and initial weight record. If email confirmation is enabled, confirm the email and then sign in.

## Security
Every health table has Row Level Security. Authenticated users can access only rows whose `user_id` equals their own authenticated user ID. The profile uses the Auth user ID as its primary key.
