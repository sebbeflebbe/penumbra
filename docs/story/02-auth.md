# Chapter 02 — Auth

Methods: passkey, BankID, Google, GitHub, magic link, password. English layout leads with passkeys (eIDAS 2 / WebAuthn); Swedish layout leads with BankID (ADR-008). On the cloud path passkeys are real WebAuthn against Supabase Auth (`auth.passkey`); the relying party ID must match `PENUMBRA_ORIGIN`. The in-memory studio still fakes passkey and BankID sessions. Passwords are last and must be twelve characters.

OAuth identity providers are independent controllers. OAuth and passkey users receive a twelve-word recovery phrase to wrap the DEK when WebAuthn PRF is unavailable. That tradeoff is documented rather than hidden. Enable Passkeys in the Frankfurt Supabase Auth settings or the button fails honestly.
