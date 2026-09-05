# Incident runbook

1. Detect (security events, user report, GitHub advisory).
2. Contain (rotate anon key if leaked; take Pages offline if supply-chain).
3. GDPR Art. 33: if personal data likely at risk, notify the competent DPA within 72 hours (placeholder: IMY for a Swedish controller).
4. CRA-style playbook (not filed from this interview app): 24h early warning / 72h / 14-day final if this were a product on the EEA market.
5. Notify affected users with mitigation (export, rotate passkey, new recovery phrase).
6. Write the post-mortem into `docs/tdd/`.
