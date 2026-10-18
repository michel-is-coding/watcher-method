#!/usr/bin/env bash
# Range les onglets d'un worktree Orca dans l'ordre donné.
#   reorder-tabs.sh [--dry-run] <chemin du worktree> <tabId> [<tabId>...]
# Les tabId viennent de `orca terminal list --include-visual-layouts --json`
# (.result.visualLayouts[].root.tabs[].tabId). Les onglets non cités gardent leur
# ordre actuel, à la suite des onglets cités. --dry-run affiche l'ordre sans l'appliquer.
# Sortie : « rangé », « déjà en ordre », ou code 1 avec la raison : dans ce cas rien
# n'a bougé, donne l'ordre voulu à l'utilisateur pour qu'il le fasse à la main.
#
# ponytail: passe par la méthode privée `session.tabs.move` du runtime Orca, faute de
# commande publique. Elle peut disparaître à une mise à jour d'Orca ; à remplacer par
# `orca terminal move` le jour où le CLI l'expose.
# Dépendances : Orca (CLI `orca` dans le PATH, ou ORCA_BIN=/chemin/orca), application ouverte.
set -uo pipefail

ORCA="${ORCA_BIN:-orca}"
bin="$(command -v "$ORCA" 2>/dev/null)" || { echo "rangement impossible : CLI orca introuvable ($ORCA)" >&2; exit 1; }
while [ -h "$bin" ]; do
  dir="$(cd -P "$(dirname "$bin")" && pwd)"; bin="$(readlink "$bin")"
  [[ "$bin" != /* ]] && bin="$dir/$bin"
done
res="$(cd -P "$(dirname "$bin")/.." && pwd)"
export ORCA_CLI_DIR="${ORCA_CLI_DIR:-$res/app.asar.unpacked/out/cli}"
ELECTRON="${ORCA_ELECTRON:-$res/../MacOS/Orca}"
[ -f "$ORCA_CLI_DIR/runtime-client.js" ] || { echo "rangement impossible : client Orca introuvable ($ORCA_CLI_DIR)" >&2; exit 1; }
[ -x "$ELECTRON" ] || { echo "rangement impossible : binaire Orca introuvable ($ELECTRON)" >&2; exit 1; }

ELECTRON_RUN_AS_NODE=1 exec "$ELECTRON" - "$@" <<'EOF'
const args = process.argv.slice(2)
const dry = args[0] === '--dry-run'
if (dry) args.shift()
const [path, ...wanted] = args
const fail = (why) => { console.error(`rangement impossible : ${why}`); process.exit(1) }
if (!path || wanted.length === 0) fail('usage: reorder-tabs.sh [--dry-run] <worktree> <tabId>...')
if (new Set(wanted).size !== wanted.length) fail('un tabId est cité deux fois')

const { RuntimeClient } = require(process.env.ORCA_CLI_DIR + '/runtime-client.js')
const client = new RuntimeClient(undefined, 15000, null, null)
const worktree = `path:${path}`

;(async () => {
  const { result } = await client.call('session.tabs.list', { worktree })
  const group = (result.tabGroups ?? []).find((g) => g.tabOrder.includes(wanted[0]))
  if (!group) fail(`onglet ${wanted[0]} absent de ${path}`)
  const stray = wanted.filter((id) => !group.tabOrder.includes(id))
  if (stray.length) fail(`onglets hors du groupe : ${stray.join(', ')}`)
  // Le runtime refuse un ordre qui cite un onglet qu'il ne publie pas : on ne garde que ceux-là.
  const published = new Set(result.tabs.map((t) => (t.type === 'terminal' ? t.parentTabId : t.id)))
  const current = group.tabOrder.filter((id) => published.has(id))
  const tabOrder = [...wanted, ...current.filter((id) => !wanted.includes(id))]
  if (tabOrder.join() === current.join()) return console.log('déjà en ordre')
  if (dry) return console.log(`ordre prévu : ${tabOrder.join(' ')}`)
  await client.call('session.tabs.move', {
    worktree, tabId: wanted[0], targetGroupId: group.id, kind: 'reorder', tabOrder
  })
  console.log('rangé')
})().catch((e) => fail(e.message))
EOF
