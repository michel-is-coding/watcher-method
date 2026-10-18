#!/usr/bin/env bash
# Garde-fou « un seul agent écrit dans un dépôt à la fois », pour le pré-vol du handoff.
#   writers.sh <repo>   <repo> = nom du dépôt tel qu'Orca l'affiche (souvent le nom du dossier)
# Liste les worktrees Orca VIVANTS de ce dépôt, hors worktree courant, dont un agent
# n'est pas « done » et qui ont bougé depuis moins de HANDOFF_FRESH_SECS (défaut 1800 s).
# Source : `orca worktree ps --json`. Angle mort : un agent lancé hors d'Orca n'y figure pas.
# Sortie : une ligne « writer concurrent » par worktree, ou « libre ». Code 0 dans les deux
# cas ; code 1 si la vérification n'a pas pu se faire (ne vaut PAS « libre »).
set -uo pipefail

ORCA="${ORCA_BIN:-orca}"
FRESH="${HANDOFF_FRESH_SECS:-1800}"
want="${1:?usage: writers.sh <repo>}"

command -v "$ORCA" >/dev/null 2>&1 || { echo "vérification impossible : CLI orca introuvable ($ORCA)" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "vérification impossible : jq introuvable" >&2; exit 1; }
PS="$("$ORCA" worktree ps --json 2>/dev/null)" || PS=""
[ -n "$PS" ] || { echo "vérification impossible : runtime Orca injoignable (app fermée ?)" >&2; exit 1; }

out="$(printf '%s' "$PS" | jq -r --arg want "$want" --arg me "${ORCA_WORKTREE_ID:-}" --argjson fresh "$FRESH" '
  (now * 1000) as $nowms
  | .result.worktrees[]
  | select(.repo == $want and .worktreeId != $me and .liveTerminalCount > 0)
  | select((($nowms - .lastActivityAt) / 1000) < $fresh)
  | . as $w
  | [ .agents[]? | select(.state != "done") ] as $busy
  | select(($busy | length) > 0)
  | "⚠️  writer concurrent : \($w.repo)@\($w.branch | sub("^refs/heads/"; ""))  (\($busy[0].state), \((($nowms - $w.lastActivityAt) / 1000) | floor)s)  \($w.path)"')" \
  || { echo "vérification impossible : réponse Orca illisible" >&2; exit 1; }
if [ -n "$out" ]; then printf '%s\n' "$out"; else
  echo "✓ $want : libre (aucun writer Orca concurrent vivant)"
fi
