#!/usr/bin/env bash
# Orca : ouvre un NOUVEL onglet terminal lançant `claude` (lecture+exécution d'un brief), dans --dir.
# Par défaut, c'est le NOUVEAU terminal qui ferme l'ancien (ciblé par son handle Orca) une fois
# démarré — fiable, car non-enfant de l'appel d'outil (donc non reap par le harness).
# Pur exécuteur : la session initiatrice décide --dir / --effort / --model / --mode / --ultracode.
#
# Flags :
#   --brief <path>   brief à lire+exécuter (REQUIS)
#   --dir <path>     cwd nouvelle session              (défaut : dossier courant)
#   --mode <mode>    plan|auto|default|acceptEdits|bypassPermissions (défaut plan)
#   --effort <lvl>   low|medium|high|xhigh             (optionnel)
#   --model <m>      opus|sonnet|haiku|...             (optionnel)
#   --ultracode      préfixe "ultracode." dans l'argv (workflow multi-agent)
#   --title <nom>    nom de l'onglet (optionnel ; sans lui, Orca garde son titre automatique)
#   --safe           désactive le YOLO : lance avec --permission-mode "$MODE" (demande les perms)
#   --no-close       NE PAS fermer l'ancien terminal
#   --dry-run        imprime la commande, n'exécute rien
# Override de la cible à fermer : exporter ORCA_TERMINAL_HANDLE=<handle> avant l'appel (tests).
# Dépendances : Orca (CLI `orca` dans le PATH, ou ORCA_BIN=/chemin/orca), `claude`, `jq`, bash.
set -uo pipefail

ORCA="${ORCA_BIN:-orca}"
BRIEF=""; DIR="$PWD"; MODE="plan"; EFFORT=""; MODEL=""; TITLE=""; ULTRA=0; CLOSE=1; DRY=0; YOLO=1
while [ $# -gt 0 ]; do
  case "$1" in
    --brief)     BRIEF="${2:-}"; shift 2;;
    --dir)       DIR="${2:-}"; shift 2;;
    --mode)      MODE="${2:-}"; shift 2;;
    --effort)    EFFORT="${2:-}"; shift 2;;
    --model)     MODEL="${2:-}"; shift 2;;
    --title)     TITLE="${2:-}"; shift 2;;
    --ultracode) ULTRA=1; shift;;
    --no-close)  CLOSE=0; shift;;
    --safe)      YOLO=0; shift;;
    --dry-run)   DRY=1; shift;;
    *) echo "arg inconnu: $1" >&2; exit 2;;
  esac
done

[ -n "$BRIEF" ] || { echo "--brief requis" >&2; exit 2; }
[ -f "$BRIEF" ] || { echo "brief introuvable: $BRIEF" >&2; exit 1; }
[ -d "$DIR" ]   || { echo "dir introuvable: $DIR" >&2; exit 1; }

# argv claude : ultracode DOIT être dans l'argv (le trigger scanne le message soumis, pas le fichier)
PREFIX=""; [ "$ULTRA" = 1 ] && PREFIX="ultracode. "
LAUNCH="${PREFIX}Lis INTEGRALEMENT et execute a la lettre ce brief, sans le reformuler : ${BRIEF}"
# YOLO par défaut : nouvelle fenêtre ouverte en --dangerously-skip-permissions (aucune demande).
# --safe rebascule sur --permission-mode "$MODE" (filet plan/acceptEdits pour migrations sensibles).
if [ "$YOLO" = 1 ]; then
  CMD=(claude --dangerously-skip-permissions)
else
  CMD=(claude --permission-mode "$MODE")
fi
[ -n "$EFFORT" ] && CMD+=(--effort "$EFFORT")
[ -n "$MODEL" ]  && CMD+=(--model "$MODEL")
CMD+=("$LAUNCH")
CLAUDE_STR=$(printf '%q ' "${CMD[@]}")

OLD_TERM="${ORCA_TERMINAL_HANDLE:-}"

# Robustesse (anti-529 / anti-crash) — exécuté PAR LE NOUVEAU TERMINAL :
#  - SENT : sentinelle "claude encore vivant", créée au démarrage, supprimée à sa sortie.
#  - WATCH : ferme l'ANCIEN terminal seulement si claude tient ≥3s (SENT présent). Un crash
#    instantané (mauvais flag, binaire KO) laisse donc l'ancien terminal INTACT → contexte sauf.
#    Un API 529 ne fait PAS sortir claude (il reste interactif) → fermeture normale, prompt
#    resoumettable par ↑+Entrée.
#  - Fallback : on n'`exec` pas claude ; à sa sortie (crash OU /quit) le terminal retombe sur un
#    shell de login dans --dir, avec une fonction `retry` qui relance le brief. Rien n'est perdu.
# Le script de démarrage est écrit sur disque : `orca terminal create --command` prend UNE
# chaîne, et imbriquer ce shell dedans transformerait le quoting en champ de mines.
# Fichier jetable dans $TMPDIR : il se supprime lui-même quand claude quitte.
WATCH=""
if [ "$CLOSE" = 1 ] && [ -n "$OLD_TERM" ]; then
  WATCH="( sleep 3; [ -f \"\$SENT\" ] && \"$ORCA\" terminal close --terminal $OLD_TERM >/dev/null 2>&1; ) & disown 2>/dev/null; "
fi
BOOT="$(mktemp "${TMPDIR:-/tmp}/handoff-boot.XXXXXX")"   # gabarit explicite : portable macOS et Linux
cat > "$BOOT" <<EOF
cd $(printf '%q' "$DIR") || exit 1
SENT=\$(mktemp "\${TMPDIR:-/tmp}/handoff-alive.XXXXXX"); trap 'rm -f "\$SENT"' EXIT
${WATCH}${CLAUDE_STR}
ec=\$?; rm -f "\$SENT"
retry(){ ${CLAUDE_STR}; }; export -f retry 2>/dev/null
printf '\n\033[33m[handoff] claude a quitté (code %s) — le brief n_est PAS perdu.\033[0m\n' "\$ec"
printf 'API 529 / overload / crash ? Tape \033[1mretry\033[0m pour relancer le brief (ou ↑+Entrée si claude tourne encore).\n\n'
rm -f "$BOOT"
exec bash -l
EOF

if [ "$DRY" = 1 ]; then
  echo "DRY-RUN  $ORCA terminal create --worktree path:$DIR${TITLE:+ --title \"$TITLE\"} --command \"bash -l $BOOT\" --focus"
  echo "--- $BOOT ---"; cat "$BOOT"
  rm -f "$BOOT"
  exit 0
fi

command -v "$ORCA" >/dev/null 2>&1 || { echo "CLI orca introuvable ($ORCA) : terminal courant CONSERVÉ, abandon" >&2; rm -f "$BOOT"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq introuvable : terminal courant CONSERVÉ, abandon" >&2; rm -f "$BOOT"; exit 1; }
command -v claude >/dev/null 2>&1 || { echo "CLI claude introuvable : terminal courant CONSERVÉ, abandon" >&2; rm -f "$BOOT"; exit 1; }
"$ORCA" repo add --path "$DIR" >/dev/null 2>&1 || true

NEW=$("$ORCA" terminal create --worktree "path:$DIR" ${TITLE:+--title "$TITLE"} --command "bash -l $BOOT" --focus --json 2>/dev/null \
      | jq -r '.result.handle // .result.terminal.handle // empty') || NEW=""
[ -n "$NEW" ] || { echo "échec ouverture du nouveau terminal Orca — terminal courant CONSERVÉ" >&2; rm -f "$BOOT"; exit 1; }

echo "Nouveau terminal Orca (cwd=$DIR): $NEW"
echo "  ${CMD[*]}"
if [ -n "$WATCH" ]; then
  echo "→ l'ancien terminal ($OLD_TERM) sera fermé seulement si claude tient ≥3s (crash instantané = ancien conservé)"
else
  echo "→ terminal courant conservé (--no-close)"
fi
