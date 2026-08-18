-- Restore the owner's historical wildcard authorization contract.
-- The license tab is guarded by Auth user_metadata.isOwner.
-- The general permission engine honors permissions=["*"].

UPDATE public.users
SET permissions = '["*"]'::jsonb,
    updated_at = now()
WHERE lower(email) = lower('owner@alrawae.com');

UPDATE auth.users
SET raw_user_meta_data = jsonb_build_object(
  'email', email,
  'name', 'المالك العام',
  'role', 'مدير النظام',
  'isOwner', true,
  'permissions', jsonb_build_array('*'),
  'email_verified', true,
  'restored_at', COALESCE(raw_user_meta_data->>'restored_at', now()::text)
),
updated_at = now()
WHERE lower(email) = lower('owner@alrawae.com');
