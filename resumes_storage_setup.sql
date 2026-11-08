-- Bayani Recruits — keep original resume PDFs
-- Run this in the Supabase SQL Editor BEFORE deploying the new index.html.
-- (The admin list now selects resume_path/resume_name, so the columns must exist first.)

-- 1) Where each applicant's PDF lives
alter table public.applicants
  add column if not exists resume_path text,
  add column if not exists resume_name text;

-- 2) Storage bucket for the PDFs (same model as the "voices" bucket:
--    files are named <applicant uuid>.pdf and opened by direct link)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('resumes', 'resumes', true, 8388608, array['application/pdf'])
on conflict (id) do nothing;

-- 3) Let the apply form upload. Insert-only: no SELECT policy is added,
--    so nobody can list the bucket through the API — a file can only be
--    opened by someone who already has its UUID link (the admin dashboard).
drop policy if exists "resumes: apply form can upload" on storage.objects;
create policy "resumes: apply form can upload"
  on storage.objects for insert
  to anon, authenticated
  with check (bucket_id = 'resumes');

-- Optional: if you want "Delete applicant" to also remove the PDF, Supabase
-- needs SELECT + DELETE on the bucket. Leaving it out keeps the bucket
-- unlistable; orphaned PDFs can be cleaned up from the Storage UI instead.
-- create policy "resumes: admin delete" on storage.objects for delete to anon using (bucket_id = 'resumes');
-- create policy "resumes: admin select" on storage.objects for select to anon using (bucket_id = 'resumes');
