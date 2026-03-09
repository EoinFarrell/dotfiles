#!/usr/bin/env bash
# Watches plaintext secret files and re-encrypts + commits on change.
#
# Usage: sops-watch.sh "plaintext:encrypted:type" [...]
#   type: binary | yaml | dotenv | json
#
# Example:
#   sops-watch.sh \
#     "/path/to/npmrc:/path/to/npmrc.enc:binary" \
#     "/path/to/.env:/path/to/.env.enc:dotenv"

log() { echo "[sops-watch] $*"; }

reencrypt() {
    local plaintext encrypted type
    IFS=: read -r plaintext encrypted type <<< "$1"

    log "Re-encrypting $plaintext..."
    if sops encrypt --input-type "$type" --output-type "$type" \
        "$plaintext" > "$encrypted"; then
        local repo_root
        repo_root="$(git -C "$(dirname "$encrypted")" rev-parse --show-toplevel)"
        local rel_enc="${encrypted#${repo_root}/}"
        git -C "$repo_root" add "$rel_enc"
        git -C "$repo_root" commit -m "chore: re-encrypt $rel_enc" && \
            log "Committed $rel_enc" || log "Nothing new to commit for $rel_enc"
    else
        log "ERROR: sops encryption failed for $plaintext"
    fi
}

if [ $# -eq 0 ]; then
    echo "Usage: sops-watch.sh \"plaintext:encrypted:type\" ..." >&2
    exit 1
fi

watch_files=()
for spec in "$@"; do
    plaintext="${spec%%:*}"
    if [ -f "$plaintext" ]; then
        watch_files+=("$plaintext")
    else
        log "Skipping (not found): $plaintext"
    fi
done

if [ ${#watch_files[@]} -eq 0 ]; then
    log "No plaintext files found to watch."
    exit 0
fi

log "Watching ${#watch_files[@]} file(s)..."
fswatch -0 --event Updated "${watch_files[@]}" | \
    while IFS= read -r -d '' changed; do
        for spec in "$@"; do
            if [[ "${spec%%:*}" == "$changed" ]]; then
                reencrypt "$spec"
                break
            fi
        done
    done
