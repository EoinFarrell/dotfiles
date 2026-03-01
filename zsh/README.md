# Readme

## Useful Commands

### Set env var from mac keychain

```bash
export ENV_VAR_NAME=$(security find-generic-password -gs keychain-record-name -w)

# -a account
# -s service
# -w password
security add-generic-password -a test -s test -w test

security find-generic-password -s test
security find-generic-password -s test -w #password only

security delete-generic-password -a test -s test
```

## SOPS

```bash
sops encrypt --input-type dotenv .env > .env.enc
sops decrypt --input-type dotenv --output-type dotenv .env.enc > .env
```
