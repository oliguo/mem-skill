# Test Plan: 10-security-scan

## Objective
Ensure no secrets, credentials, or dangerous patterns exist in skill files.

## Test Cases

| # | Case | Expected Result |
|---|------|-----------------|
| 10.1 | No hardcoded API keys | No matches for common key patterns |
| 10.2 | No passwords in code | No "password=" or "passwd" strings |
| 10.3 | No private keys | No "BEGIN.*PRIVATE KEY" |
| 10.4 | No IP addresses | No hardcoded IPs |
| 10.5 | No eval() or exec() in scripts | No dangerous execution |
| 10.6 | No .env files tracked | .env in .gitignore or absent |
| 10.7 | package.json has no install scripts | No preinstall/postinstall hooks |
