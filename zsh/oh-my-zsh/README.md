# Readme

## Useful Commands

### Set env var from mac keychain

```bash
export ENV_VAR_NAME=$(security find-generic-password -gs keychain-record-name -w)
```
