# Security Triage

Treat an issue as security-related when it has a label such as `security`, `sec`, `vulnerability`, `cve`, `rce`, `xss`, `sqli`, `injection`, `auth-bypass`, or `secret`, or when its title or body describes a concrete vulnerability such as remote code execution, cross-site scripting, SQL injection, authentication or authorization bypass, privilege escalation, secret exposure, or insecure deserialization.

Do not classify an issue as security only because it says "security team", "security meeting", "security group", or discusses a product security feature without a vulnerability.

When uncertain, preserve the issue context and state the reason for the classification. Security fixes require structural mitigations, no secret handling in logs or commits, and a residual-risk report.
