# Supabase Backup (Quick Commands)
Run this to create a full **read-only backup** of your Supabase project.
## 1. Login
```bash
supabase login

2. Go to backup folder

cd ~/Desktop/FitUp-Supabase-Backups
mkdir -p 2026-04-26-pre-testflight
cd 2026-04-26-pre-testflight

3. Link project

supabase link --project-ref uushejbizmlxzxonkuki

4. Dump database (READ-ONLY)

supabase db dump -f roles.sql --role-only
supabase db dump -f schema.sql
supabase db dump -f data.sql --use-copy --data-only -x "storage.buckets_vectors" -x "storage.vector_indexes"

5. (Optional) Copy edge functions

cp -R /path/to/FitUp-App/supabase/functions ./edge-functions

6. Commit backup

cd ..
git add 2026-04-26-pre-testflight
git commit -m "Supabase backup"
git push

⸻

Notes

* These commands do NOT modify your database
* Repo should be private
* This is a snapshot backup (not migrations)

**Tidbit:** You can rerun just `schema.sql` dump anytime after making schema/RLS changes—it’s the fastest way to keep an up-to-date safety net without re-exporting all data.