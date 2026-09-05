# Chapter 02 — Auth

Methods: passkey, Google, GitHub, magic link, password. Passkeys lead the layout (eIDAS 2 / WebAuthn). On the cloud path they are real WebAuthn against Supabase Auth (`auth.passkey`); the relying party ID must match `PENUMBRA_ORIGIN`. The in-memory studio still fakes a passkey session. Passwords are last and must be twelve characters.

OAuth identity providers are independent controllers. OAuth and passkey users receive a twelve-word recovery phrase to wrap the DEK when WebAuthn PRF is unavailable. That tradeoff is documented rather than hidden. Enable Passkeys in the Frankfurt Supabase Auth settings or the button fails honestly.
