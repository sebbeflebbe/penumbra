# Risk assessment (STRIDE, condensed)

| Asset | Spoof | Tamper | Repudiate | Info disc. | DoS | Elevation |
| --- | --- | --- | --- | --- | --- | --- |
| Auth | Passkeys preferred; password rate-limited | — | Security events | Session XSS residual | Vendor pause | RLS |
| Canvas DEK | Recovery phrase phishing | GCM MAC | — | Phrase shoulder-surf | Lost phrase | — |
| CI | OIDC tokens | Lockfile + OSV | Actions log | No service role in client | — | — |
| CDN | HTTPS | Integrity of build artifact | — | Headers | Free-tier pause | — |
