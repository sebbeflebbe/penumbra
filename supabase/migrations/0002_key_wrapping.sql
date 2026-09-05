-- Client-held wrapping material for the data-encryption key.
-- The wrapping secret (password or recovery phrase) never lands here.

alter table public.profiles
  add column if not exists wrap_salt text,
  add column if not exists wrapped_dek text;
