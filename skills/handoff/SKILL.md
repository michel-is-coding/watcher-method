---
name: handoff
description: Compose un brief de handoff, ouvre un nouvel onglet terminal Orca avec claude au bon dossier et au bon niveau d'effort, puis ferme l'onglet courant. À utiliser pour « handoff », « passe la main », « continue dans une nouvelle session », quand la suite du travail change de dossier, de worktree, d'effort, de modèle ou de niveau de risque. Pas pour une tâche annexe (sous-agent, /fork) ni pour alléger le contexte sans changer d'environnement (/compact). Demande Claude Code et Orca.
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/spawn-claude.sh:*), Bash(bash ${CLAUDE_SKILL_DIR}/scripts/spawn-claude.sh:*), Bash(${CLAUDE_SKILL_DIR}/scripts/writers.sh:*), Bash(bash ${CLAUDE_SKILL_DIR}/scripts/writers.sh:*), Bash(git -C * status:*), Bash(git status:*), Bash(orca worktree ps:*), Bash(orca terminal list:*), Bash(grep:*), SendMessage, Write
license: MIT
---

Tâche à passer à la prochaine fenêtre de contexte : **$ARGUMENTS**

**Règles personnelles.** Avant le triage, lis `~/.config/matthieu-skills/regles.md` : ce qu'il dit (organisation des sessions, nom de l'onglet, autonomie de la nouvelle session, onglet courant gardé ou fermé, forme des questions et des textes) passe avant ce fichier. S'il n'existe pas, lance d'abord le skill `regles` si l'utilisateur est là pour répondre ; sinon (session lancée par un agent, skill `regles` absent) continue avec les règles de ce fichier, sans rien écrire.

## Dépendances et réglages

`<skill-dir>` désigne le dossier de ce `SKILL.md` (`${CLAUDE_SKILL_DIR}` sous Claude Code, que le skill soit installé en plugin ou dans `~/.claude/skills/handoff`). Les chemins de `allowed-tools` dans l'en-tête s'appuient dessus.

| Dépendance | Rôle | Si elle manque |
|---|---|---|
| Claude Code (`claude` dans le PATH) | la session enfant est un `claude` ; le skill utilise `$ARGUMENTS`, `/fork`, `/compact`, `AskUserQuestion` | pas de handoff possible : ce skill ne fonctionne pas sous Codex |
| [Orca](https://onorca.dev), application ouverte, CLI `orca` dans le PATH (ou `ORCA_BIN=/chemin/orca`) | ouvrir le nouvel onglet, fermer l'ancien, repérer les sessions concurrentes | `spawn-claude.sh` s'arrête avant d'ouvrir quoi que ce soit et conserve l'onglet courant. Écris quand même le brief, donne son chemin et la commande `claude` à lancer à la main, ne ferme rien |
| `jq`, `git`, `bash` | lecture des réponses Orca, pré-vol | même arrêt, onglet courant conservé |

Réglages, tous facultatifs :

- `ORCA_BIN` : chemin du CLI `orca` s'il n'est pas dans le PATH.
- `HANDOFF_FRESH_SECS` (défaut `1800`) : au-delà de ce délai sans activité, une session ne compte plus comme concurrente.
- `HANDOFF_NOTIFY_CMD` : commande que la session enfant lance en fin de tâche pour prévenir l'utilisateur (son, notification). Sans ce réglage, aucune notification.
- Les briefs sont écrits dans `~/.claude/handoffs/`, créé au besoin. Ils sont jetables : purge le dossier quand tu veux.

## Principes (lis d'abord)
- **Action destructive unique** : à la fin, l'onglet terminal Orca COURANT est **fermé** → son historique de session est perdu. Tout le reste (brief, fichiers projet) est conservé.
- **Sécurités déjà en place** : le nouveau terminal ne ferme l'ancien que si `claude` tient ≥3s (crash instantané = ancien conservé) ; échec d'ouverture = ancien conservé ; le brief reste sur disque dans `~/.claude/handoffs/` et `retry` le relance.
- **Confirmation HYBRIDE** : si le pré-vol est 100 % vert (tout commité, tout poussé, aucun doute, rien d'autre à capter de la discussion) → exécution **AUTO** (ouvre le nouveau terminal, ferme l'ancien) sans demander, en **annonçant** d'abord ce qui se passe. Au moindre doute (gate AUTO-GO, étape finale) → confirmation explicite obligatoire. Jamais de fermeture auto si un signal de pré-vol est rouge.

## 0. TRIAGE — est-ce vraiment un handoff ? (avant tout)
Un handoff FERME cette session (destructif) et re-bootstrap un contexte à froid. Sa **seule** valeur non-redondante = **re-router l'environnement** (dossier / worktree / effort / modèle / risque) vers une session interactive fraîche, **à une frontière de phase**. Si le besoin est autre, un outil natif est moins cher — propose-le AU LIEU du handoff :
- **Tâche FERMÉE qui rend un résultat** (audit, recherche, mapping) → **sous-agent (`Task`)** : contexte isolé, résultat distillé re-injecté, cette session intacte. Pas de handoff.
- **Tâche annexe sans quitter cette session** (digression, garder le fil) → **`/fork`**.
- **Même tâche, passé propre, même dossier/effort** → **`/compact` ou continue**. Brief seulement si la fidélité prime sur le coût (l'auto-compact est lossy).
- **Exploratoire où le *chemin* parcouru compte** (le tacite n'est pas épuisé) → **`/resume`** (garde tout l'historique brut).
- **Changement d'environnement + frontière de phase** → **`/handoff`** (suite ci-dessous).

Tu es la session INITIATRICE. À toi de JUGER (depuis le contexte de cette conversation), ne demande pas si évident :

1. **Dossier cible** (`--dir`) : où la tâche doit s'exécuter.
2. **Niveau de réflexion** — matrice par défaut, surchargeable :
   - lookup / petit fix → `--effort low` (modèle sonnet/haiku)
   - dev normal → `--effort medium`
   - analyse / archi → `--effort high --model opus`
   - mapping massif / multi-agent → `--effort xhigh --model opus --ultracode`
   - **Permissions — axe RISQUE (juge en parallèle de l'effort)** : défaut = **pleine autonomie** (`--dangerously-skip-permissions`) pour lecture / analyse / écriture locale réversible — ne pas contourner, ne pas avertir. Bascule en `--safe` + ajoute au brief « demande confirmation avant l'action X » **UNIQUEMENT** pour le sous-ensemble **sortant/irréversible** : deploy, paiement/transfert, `rm` large, migration prod/DB, publication externe, **force-push · push sur `main`/branche protégée · réécriture d'historique partagé**. Le **git courant** (commit, `git pull --rebase`, push d'une branche feature ou worktree) **n'est PAS dangereux** = autonome. En cas de doute, montre-le dans la confirmation finale.
3. **Nom de l'onglet** (`--title`) : 2 à 4 mots, le projet d'abord, puis l'objet. Ni article, ni ponctuation, ni symbole, ni date (« Site accueil », « Compta relances »). Sans ce nom, l'onglet affiche le début de la commande de lancement.
4. **Skills à mobiliser** : regarde le panel de skills réellement disponibles dans cette session et nomme dans le brief le(s) plus pertinent(s) pour la session enfant (elle fera aussi sa propre sélection). Tâche triviale → aucun.

5. **Brief — CONTRAT, scalé sur l'effort** : écris un brief AUTONOME dans `~/.claude/handoffs/<slug>.md` (jetable). **Slug UNIQUE obligatoire** : suffixe-le d'un horodatage **à la seconde** (`<slug>-AAAAMMJJ-HHMMSS.md`) — ne JAMAIS réutiliser un nom existant (sinon tu écrases un trail intention→issue pas encore lu = perte de données). La fenêtre suivante n'a PAS notre historique : le brief est sa SEULE source.

   **Deux paliers selon l'effort** (le contrat scale avec la tâche) :
   - **EXPRESS** — `--effort low` / reload / lecture seule / commande unique → **3 champs suffisent** : **Objectif**, **Fichiers/chemins clés**, **Critères de fin**. Section ISSUE facultative ; la gate finale (véracité incluse) ne porte que sur ces 3 champs — pas de passe d'auto-critique approfondie. N'invente pas de remplissage pour les autres champs.
   - **COMPLET** — `--effort medium`/`high`/`xhigh` → tous les champs ci-dessous. Chacun rempli ; un champ réellement **sans objet** pour CETTE tâche peut être `N/A` + un mot de raison ; seul le **vide-par-paresse** (sauter un champ qui a du contenu) est interdit.
     - **Objectif** : but final mesurable.
     - **Contraintes** : invariants/limites à préserver (le « ne pas casser »). Les interdits d'ACTION vont dans **Forbidden Actions**, pas ici.
     - **Forbidden Actions** : la liste NÉGATIVE explicite des ACTIONS interdites — ce que la session enfant ne doit ABSOLUMENT pas faire (ex. « ne pas déployer », « ne pas toucher `site/**` », « ne pas push »). Concentre les interdits ICI au lieu de les disperser.
     - **Required from User** : toute info/décision à OBTENIR de l'humain pour pouvoir finir (sinon le successeur reste bloqué). Vide si rien.
     - **Fichiers / chemins / docs clés** : pointeurs concrets (refs `fichier:ligne` quand utile).
     - **DÉCISIONS déjà prises + leur POURQUOI** : ← champ critique, LE delta entre passation et résumé. Toute option écartée, tout choix d'archi/d'approche déjà tranché dans CETTE conversation, avec la raison. Sans ça la session enfant re-débat ou reprend un chemin déjà rejeté.
     - **État courant** : fait / en cours / pas commencé.
     - **Git autonome** (section dédiée — 3 points testables) : (a) **nomme la branche cible** explicitement ; (b) instruis un **`git checkout` / vérification de branche AVANT le 1er commit** ; (c) **commite le WIP aux points logiques même si le push est différé** (ne laisse pas un livrable multi-fichiers non commité). La session enfant gère le versionnage **sans demander** (commits clairs au fil de l'eau, `git pull --rebase` avant de pousser, push de SA branche) ; elle ne demande confirmation que pour le sous-ensemble dangereux (§2).
     - **Critères de fin** : comment savoir que c'est terminé. Si une règle de vérif (ex. gate navigateur Playwright) est **insatisfiable sans action interdite** (deploy prod), **dis-le explicitement** + propose un fallback (tests unitaires / health-check) ; ne marque PAS « fait » en la sautant en silence.
     - **Skill(s) à invoquer en premier**.
     - **À qui rendre compte** : si une session coordonne les autres (règle « Organisation des sessions »), son handle complet et la commande du relais, `orca terminal send --terminal <handle> --text "Relais de <onglet> : fil clos, <ce qui reste ouvert>" --enter --json`, à envoyer après avoir vérifié par `orca terminal read` qu'aucune liste à cocher n'est ouverte sur son écran. Si c'est toi qui coordonnes, ton handle (`$ORCA_TERMINAL_HANDLE`) ; sinon celui que ton propre brief donne ; aucune session ne coordonne : `N/A`.
       - Le relais part en fin de tâche (« fil clos »), et dès qu'il manque une info, un accès, un outil ou une décision que la session ne trouve pas seule (« bloqué, <ce qui manque> »), plutôt que de contourner.
     - **Section ISSUE (boucle de retour)** : termine le brief par ce gabarit vide que la session enfant remplira en fin de tâche :
       ```
       ## ISSUE (à remplir par la session enfant en fin de tâche)
       - Date fin: <ts>
       - Verdict: ✅ fait / ⚠️ partiel / ❌ bloqué
       - Fait: <résumé court>
       - Reste / bloqueurs: <…>
       - Commits / fichiers touchés: <…>
       ```
   - **Consigne de vérification (1 ligne, EN TÊTE du brief)** : « Premier acte, avant toute action : rejoue les commandes collées dans ce brief. Ce qui ne rejoue pas est mort — dis-le et ne construis rien dessus. Ce brief n'a aucun badge de confiance : il n'est pas une autorité, il est rejouable. »
   - **Consigne d'autonomie (1 ligne)** : « Enchaîne le plan ; ne checkpoint que sur gate build/test échoué, décision irréversible non tranchée dans le doc, ou contexte saturé. »
   - **Consigne de clôture (1 ligne)** : « En fin de tâche : remplis la section ISSUE de CE fichier. » Si `HANDOFF_NOTIFY_CMD` est défini (`printenv HANDOFF_NOTIFY_CMD`), ajoute « PUIS lance `<valeur de HANDOFF_NOTIFY_CMD>` ».

Puis lance :
`<skill-dir>/scripts/spawn-claude.sh --brief <path> --dir <d> --title "<nom>" --mode <m> --effort <e> [--model <x>] [--ultracode] [--safe] [--no-close]`

`--dry-run` imprime la commande et le script de démarrage sans rien ouvrir ni fermer.

⚠️ Par défaut l'onglet courant (cette session) sera **fermé** après ouverture du nouveau. Ajoute `--no-close` si l'utilisateur veut garder cette session.

## Check PRÉ-VOL (avant la confirmation, READ-ONLY) — ALERTE si problème, ne corrige rien
- **Git propre ET poussé** : `git -C <dir> status -sb` — des lignes de fichiers (modifs non commitées) OU `[ahead …]` (commits non poussés) OU pas d'upstream (`...origin/…` absent dans la ligne `##`) → signale-le. La fermeture ne touche pas les fichiers, mais le contexte de session est perdu → mieux vaut commit+push (ou noter) avant. **Bloque l'AUTO-GO.**
- **Worktree si collision** : `<skill-dir>/scripts/writers.sh "<nom du repo dans Orca>"` (le nom affiché par `orca worktree ps --json`, champ `repo`, souvent celui du dossier du dépôt principal) : liste toute session d'agent vivante dans Orca qui écrit CE repo, branche incluse. Un agent lancé hors d'Orca n'y figure pas. Code de sortie 1 = vérification impossible, ce qui ne vaut PAS « libre » et bloque l'AUTO-GO. Un writer concurrent (OU modifs non commitées qui gêneraient la nouvelle tâche) → NE lance PAS dans le même working tree : crée un worktree avec `orca worktree create --repo path:<dir> --name <branche> --json` (chemin dans `.result.worktree.path`), ou à défaut `git -C <dir> worktree add <chemin> -b <branche>`, et passe CE chemin en `--dir`. Montre worktree vs en-place + nom de branche dans la confirmation.
- **Job en fond tué** : un serveur/dev-server lancé dans CET onglet serait **tué** à la fermeture. Si tu en as démarré un dans cette session → préviens, propose `--no-close` ou de le relancer côté nouvelle session.
- Risque détecté → montre-le dans la confirmation pour que l'utilisateur tranche en connaissance de cause.

## Étape finale — DÉCISION : AUTO-GO ou CONFIRMATION
Avant TOUT lancement de `spawn-claude.sh` :
0. **Gate de complétude & véracité (= la passe d'auto-critique, faite ici une seule fois)** : relis le brief en te demandant « un agent SANS notre historique peut-il finir avec SEULEMENT ça, sans deviner ni me redemander ? ». (a) **Complétude** : comble chaque champ vide/creux du palier retenu (EXPRESS ou COMPLET). (b) **Véracité — joins la pièce, ne porte pas de badge** : tout claim factuel porteur (un fichier existe, la valeur X est dans Y, le champ Z est peuplé, la taille/scope est N) part avec **la commande qui le rejoue, collée avec sa sortie**. Pas de commande → le claim ne part pas, ou part marqué « NON vérifié ». Trois pièges qui ont chacun produit un faux dans un vrai brief :
   - **Une prose trouvée écrite n'est pas une preuve.** Lire un document qui affirme X vérifie que le document le dit, pas que X est vrai. La source est primaire (le système de fichiers, la sortie de commande) — jamais une note qui décrit le système de fichiers, jamais la sortie d'un autre agent.
   - **N'écris jamais `[VERIFIE]` ni aucun badge auto-déclaré.** Il est produit par le processus même qui produit le claim : un brief qui invente un fait invente avec le même aplomb le badge qui l'atteste. Le lecteur ne peut pas contrôler un badge ; il peut rejouer une commande.
   - **Une commande peut mentir.** Un `grep` qui rate, un daemon éteint dont les valeurs par défaut ressemblent à une mesure : **une absence de résultat ne prouve rien**. Si le claim porte sur une absence, contrôle l'instrument (fais-le matcher sur un cas connu) avant de conclure.

   Si un champ reste vide/creux OU un claim porteur n'a pas sa commande → corrige d'abord (ce qui bloque l'AUTO-GO tant que non résolu).
1. Le brief est écrit dans `~/.claude/handoffs/<slug>.md` (section ISSUE vide en pied pour le palier COMPLET).
2. **Gate AUTO-GO** — évalue ces conditions ; **TOUTES vraies = exécution auto**, sinon → confirmation (étape 4) :
   - **tout commité ET poussé** (pré-vol git vert : pas de modif, pas de `[ahead]`, upstream présent) ;
   - **aucun writer concurrent** (`<skill-dir>/scripts/writers.sh <repo>` répond « libre », code 0) ;
   - **aucun job/serveur** lancé dans CET onglet qui serait tué à la fermeture ;
   - **autonomie pleine** : la tâche ne déclenche PAS `--safe` / action sortante-irréversible (§2 risque) ;
   - **rien d'autre à capter de la discussion** : `Required from User` vide, aucune question/décision en suspens dans cette conversation, gate 0 passée sans claim « NON vérifié » ;
   - l'utilisateur n'a pas demandé `--no-close` ni une confirmation explicite.
3. **Si AUTO-GO (toutes vraies)** : **annonce** en clair (chemin du brief + ligne `dir=… effort=… mode=… [ultracode]`), PUIS lance `spawn-claude.sh` directement (sans `--no-close`) — ouvre le nouvel onglet, ferme l'ancien. Pas de prompt bloquant.
4. **Sinon (≥1 doute)** : montre en clair les **signaux rouges** + le **chemin du brief** + la ligne `dir=… effort=… mode=… [ultracode] [no-close]` + le **niveau de risque** retenu (autonomie vs `--safe`). Puis :
   - **Préviens le watcher**, pour qu'il range ce handoff avec les autres décisions qui attendent l'utilisateur. Son onglet s'appelle « WATCHER », ou à défaut porte ce mot : la commande prend d'abord le titre exact, sinon ceux qui contiennent le mot, et donne leur nom pour SendMessage (aucune ligne : pas de watcher, passe) :
     ```sh
     for h in $(orca terminal list --json | jq -r --arg me "$ORCA_TERMINAL_HANDLE" '[.result.terminals[] | select(.handle != $me) | {handle, t: ((.title // "") | sub("^\\W+"; ""))}] | (map(select(.t | test("^watcher$"; "i"))) | select(length > 0)) // map(select(.t | test("watcher"; "i"))) | .[].handle'); do
       for f in ~/.claude/sessions/*.json; do ps eww -p "$(jq -r .pid "$f")" 2>/dev/null | grep -q "ORCA_TERMINAL_HANDLE=$h" && jq -r .name "$f" || true; done
     done
     ```
     Envoie à chaque nom, par SendMessage, une ligne : « Handoff en attente : <onglet courant> vers <nom du nouvel onglet>, brief <chemin>, <signal rouge principal>. »
   - **Confirmation via l'UI à cases à cocher** (outil `AskUserQuestion`), JAMAIS un simple [y/N] texte. Les questions d'ajustement (effort, mode, modèle, ultracode), s'il y en a, partent d'abord, dans leur propre appel. La question d'action part seule et en dernier, toujours sous cette forme, pour que le watcher la reconnaisse et la valide d'une Entrée sur le mot de l'utilisateur :
     - question : « Handoff vers une fenêtre fraîche : <nom du nouvel onglet>, dans <dir>. Exécuter ? »
     - options, dans cet ordre : **Exécuter (ferme cet onglet) (Recommandé)** / **Exécuter en gardant cet onglet** (`--no-close`) / **Annuler**. Si la règle « Onglet courant après un handoff » dit de garder l'onglet, « Exécuter en gardant cet onglet » passe en premier et porte « (Recommandé) ».
   - N'exécute `spawn-claude.sh` QUE sur un choix « Exécuter » explicite ; « Annuler » ou réponse vide → ne ferme rien, attends instructions.
