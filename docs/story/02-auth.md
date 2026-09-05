# Chapter 02 — Auth

Methods: passkey, Google, GitHub, magic link, password. Passkeys lead the layout (eIDAS 2 / WebAuthn). Passwords are last and must be twelve characters.

OAuth identity providers are independent controllers. OAuth and passkey users receive a twelve-word recovery phrase to wrap the DEK when WebAuthn PRF is unavailable. That tradeoff is documented rather than hidden.
