# Skills

Cinq skills pour agents de code, à installer dans Claude Code ou dans Codex. Un skill est un dossier qui contient un `SKILL.md` (quand et comment l'agent s'en sert) et, parfois, des scripts.

## Commencer

Ces skills répondent à trois questions : qu'est-ce que je suis en train de faire, qu'est-ce qui se passe, où mettre mon attention. Rien de plus. Cinq minutes pour les prendre en main.

**1. Installe les quatre skills de travail ensemble.** `sessions`, `watcher`, `handoff` et `regles` se répondent : le watcher lit le relevé de `sessions`, présente et exécute les handoffs, suit tes règles. Depuis le dossier qui contient ce README, clone du dépôt ou paquet décompressé :

```sh
mkdir -p ~/.claude/skills
for s in sessions watcher handoff regles; do ln -sfn "$PWD/$s" ~/.claude/skills/$s; done
```

Il te faut aussi [Orca](https://onorca.dev) ouvert, son CLI `orca` dans le PATH, et `jq`. Une session ouverte avant l'installation ne voit pas ces skills : relance-la, sinon le « Lance /handoff » du watcher tombe dans le vide. Sous Codex, lie `sessions`, `watcher` et `regles` dans `~/.codex/skills` : `handoff` demande Claude Code.

**2. Réponds aux questions.** Ouvre une session et lance `/regles` : tu racontes ton métier en quelques phrases, puis dix questions, trois minutes, pour que les skills travaillent à ta façon. Les quatre premières fixent ta méthode :

- **Organisation des sessions** : qui coordonne, qui rend compte à qui.
- **Rôle du coordinateur** : ce qu'il fait, ce qu'il ne fait jamais.
- **Implication du watcher** : observer, proposer, ou agir.
- **Forme des textes** : comment les skills t'écrivent.

Les six suivantes règlent les onglets, la forme des questions et le handoff. Chaque question propose d'abord l'option que ton récit désigne, sinon la pratique qui a fait ses preuves. Si aucune option ne te va, réponds avec tes mots : ta phrase devient la règle. Tes réponses vont dans `~/.config/matthieu-skills/regles.md`, ton récit dans `contexte.md` à côté, hors du dépôt ; relance `/regles` ou modifie le fichier pour changer d'avis.

**3. Organise tes sessions en trois rôles.** C'est le réglage par défaut, tes réponses peuvent le changer.

- **Une session coordonne.** Elle ouvre les sessions de travail par `/handoff`, reçoit leurs relais, réunit tes décisions en lot et veille à ce que chaque session écrive dans son seul dossier. Elle ne fait jamais la tâche elle-même et ne pousse rien sans ton accord. Ce rôle n'a pas de skill : pour le donner à une session, dis-lui « Tu coordonnes. Lis `~/.config/matthieu-skills/regles.md`. » Ce qui a fait ses preuves :
  - Elle vérifie chaque relais dans les fichiers avant de le transmettre, et finit chaque message par « réponds seulement "reçu" ».
  - Quand des décisions s'impliquent les unes les autres, elle regroupe leurs sessions sous une session maître par grappe. Une session absorbée se ferme après « fil repris », une fois ses résultats écrits.
  - Elle tient un journal léger : trois à six lignes par jour, chaque ligne un lien vers ce qui fait foi.
  - Elle relit l'horloge avant chaque réponse, pour suivre la journée en heures.
  - Un chiffre que personne ne publie se demande par un appel ou un courriel, pas par une recherche de plus.
- **Des sessions de travail.** Chacune tient une tâche, dans son dossier, à partir d'un brief. En fin de tâche, elle envoie à la coordinatrice un relais « fil clos » avec ce qui reste ouvert ; s'il lui manque une info, un accès, un outil ou une décision, un relais « bloqué » tout de suite. Elles ne s'écrivent pas entre elles.
- **Plusieurs agents en parallèle sous supervision**, avec des questions bloquantes et une attente des résultats : c'est le skill `orchestration` d'Orca, qui le fait déjà avec une file de messages qui ne se perd pas. `/handoff` reste pour passer la main sans surveiller.
- **Un watcher**, dans son propre onglet, nommé « WATCHER » : c'est ainsi que `/handoff` le trouve. Il observe tout et ne décide rien.

**4. Au quotidien.**

- `/sessions` montre le tableau des sessions ouvertes, en lecture seule.
- `/watcher` commence par ce qui t'attend : les handoffs proposés, puis les questions en suspens. Viennent ensuite le tableau avec une suite par session, puis les fusions et les fermetures. Il nomme et range les onglets sans demander ; tout le reste part sur une case cochée. `/loop 1h /watcher` le relance chaque heure.
- `/handoff` sert quand une session change de dossier, d'effort ou de niveau de risque, ou dépasse 60 % de contexte. Elle écrit un brief et continue dans un onglet neuf. En cas de doute, elle te pose la liste « Handoff vers une fenêtre fraîche » et prévient le watcher, qui te la présente avec tes autres décisions et l'exécute sur ton mot.

## Les skills

| Skill | Ce qu'il fait | Agents | Dépendances |
|---|---|---|---|
| [sessions](sessions/) | Affiche un tableau des sessions d'agents ouvertes, en lecture seule. | Claude Code, Codex | Orca |
| [watcher](watcher/) | Commence par ce qui t'attend (handoffs proposés, questions en suspens), nomme et range les onglets sans demander, propose la suite, les fusions et les fermetures, agit sur accord. | Claude Code, Codex | Orca, le skill `sessions` ; le skill `handoff` pour les handoffs |
| [handoff](handoff/) | Écrit un brief, ouvre une nouvelle session Claude dans un onglet Orca, ferme l'onglet courant ; en cas de doute, demande et prévient le watcher. | Claude Code seulement | Orca, `claude`, `jq`, `git` |
| [regles](regles/) | Te fait raconter ton métier, pose dix questions sur ta façon de travailler et écrit ton fichier de règles personnelles, que `watcher`, `sessions` et `handoff` suivent ensuite. | Claude Code, Codex | aucune |
| [wake-up](wake-up/) | La boucle de la journée : le soir, chaque session ouverte écrit le brief de sa reprise ; le matin, les briefs sont repris et chaque travail retenu rouvert dans une fenêtre neuve. | Claude Code, Codex | Orca, les skills `sessions`, `handoff` et `watcher` |

Chaque `SKILL.md` détaille ses dépendances, ses réglages et ce qui se passe quand une dépendance manque.

[Orca](https://onorca.dev) est l'application qui gère les worktrees et les terminaux des agents ; son CLI `orca` doit être dans le PATH. Sur macOS, le reste s'installe avec Homebrew :

```sh
brew install jq
```

## Installer

En plugin, les cinq skills s'installent d'un coup, et les mises à jour suivent :

```sh
/plugin marketplace add michel-is-coding/watcher-method   # Claude Code, dans une session
/plugin install matthieu@watcher-method
codex plugin marketplace add michel-is-coding/watcher-method   # Codex, dans le terminal
codex plugin add matthieu@watcher-method
```

Sous Claude Code, un skill installé ainsi s'appelle `/matthieu:<nom>` (par exemple `/matthieu:watcher`).

À la main, récupère le dépôt, puis copie ou lie le dossier du skill. Le nom du dossier doit rester celui du skill.

Par lien symbolique, pour suivre les mises à jour avec un simple `git pull` :

```sh
git clone https://github.com/michel-is-coding/watcher-method.git ~/watcher-method
mkdir -p ~/.claude/skills ~/.codex/skills
ln -s ~/watcher-method/skills/watcher ~/.claude/skills/watcher   # Claude Code
ln -s ~/watcher-method/skills/watcher ~/.codex/skills/watcher    # Codex
```

Par copie, pour une version figée que tu peux modifier :

```sh
cp -R ~/watcher-method/skills/watcher ~/.claude/skills/
cp -R ~/watcher-method/skills/watcher ~/.codex/skills/
```

Remplace `watcher` par le skill voulu. Les quatre skills de travail (`sessions`, `watcher`, `handoff`, `regles`) s'installent ensemble : voir [Commencer](#commencer). Ouvre ensuite une nouvelle session : le skill s'appelle par `/nom` sous Claude Code, par `$nom` sous Codex, ou se déclenche seul quand la demande correspond à sa description.

Pour vérifier une installation :

```sh
~/.claude/skills/handoff/scripts/spawn-claude.sh --brief <un fichier> --dry-run
~/.claude/skills/watcher/scripts/reorder-tabs.sh --dry-run <un worktree> <un tabId>
python3 ~/.claude/skills/watcher/scripts/retours.py --self-check
```

Aucune de ces commandes ne crée de worktree, n'ouvre de terminal ni ne transcrit quoi que ce soit.

## Tes règles

Les skills arrivent avec les habitudes de l'auteur. Les tiennes vivent dans un fichier à toi, `~/.config/matthieu-skills/regles.md`, hors de ce dépôt : une mise à jour des skills ne l'écrase pas, et il ne se publie jamais. Si tes règles sont encore dans `~/.config/golems/`, l'ancien nom, relance `/regles` : il les déplace.

Méthode, règles et contexte ne se mêlent pas : voir [regles](regles/SKILL.md). Après dix jours d'usage, le watcher te propose une fois de pousser tes changements de méthode, anonymisés, vers la communauté 94 : voir [RETOURS.md](../RETOURS.md).

À la première utilisation de `watcher` ou de `handoff`, le skill `regles` te fait raconter ton métier, te pose dix questions, trois minutes en tout, puis écrit ce fichier. Les quatre premières portent sur ta méthode de travail. Tu peux répondre avec tes mots : ta phrase devient la règle. Si tu n'as pas le temps, il garde les valeurs par défaut et ne redemande pas. Pour changer d'avis : `/regles` sous Claude Code, `$regles` sous Codex, ou modifie le fichier à la main.

Les dix règles, leurs valeurs par défaut et les autres choix sont dans [regles/SKILL.md](regles/SKILL.md#les-règles).

Une session sans utilisateur (boucle, session lancée par un agent) ne pose aucune question : elle suit ton fichier s'il existe, les valeurs par défaut sinon.


Les autres réglages (chemins, délais, commande de notification) sont des variables d'environnement décrites dans le `SKILL.md` de chaque skill.

## Licence et provenance

- `handoff`, `watcher`, `sessions`, `regles` et `wake-up` sont de Matthieu E., sous licence MIT. Chaque dossier contient son fichier `LICENSE`, pour qu'un skill copié seul garde sa licence.
