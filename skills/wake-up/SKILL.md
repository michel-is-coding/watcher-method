---
name: wake-up
description: >-
  La boucle de la journée, en deux gestes qui se répondent. Le soir (« /wake-up bonne-nuit ») : chaque session ouverte écrit le brief de sa reprise sans rien ouvrir, la journée est racontée en quelques lignes (ce qu'on a fait d'intéressant, ce qu'il faut garder en tête, comment le dire à quelqu'un), puis les sessions se ferment sur accord. Le matin (« /wake-up ») : reprend ces briefs et la synthèse, les croise avec le plan du jour et les sessions encore ouvertes, pose les deux ou trois questions qui comptent, puis rouvre chaque travail retenu dans une fenêtre neuve au bon effort. À utiliser pour « wake-up », « bonjour », « on commence la journée », « nouvelle journée », « bonne nuit », « on s'arrête pour aujourd'hui », « fin de journée », « prépare demain ».
license: MIT
---

# Wake up

Deux gestes, une seule boucle. Le soir, chaque session a encore son contexte en tête : c'est le moment où elle écrit le mieux sa reprise. Le matin, il ne reste qu'à croiser, demander et ouvrir. Ce que le soir écrit est exactement ce que le matin lit : si tu changes l'un, change l'autre dans ce même fichier.

**Quel geste.** `/wake-up bonne-nuit`, ou une demande du soir (« bonne nuit », « fin de journée ») : le soir. Sinon : le matin.

Reste bref. Aucun tiret cadratin (—) dans ce que tu écris.

**Règles personnelles.** Lis d'abord `~/.config/matthieu-skills/regles.md` : ce qu'il dit passe avant ce fichier. Servent ici « Plan du jour » (où sont les objectifs de la journée ; absente, ce que les sessions disent avoir visé, ou ta question du matin), « Synthèse du soir » (où la garder ; absente, dans ta réponse et dans le dossier de la nuit), « Noms des onglets », « Ordre des onglets », « Forme des questions », « Mise à jour de nuit » (le chemin de ton script de mise à jour de nuit, aucun n'est livré avec les skills ; absente, le soir ne met rien à jour).

**Dépendances** : les skills `sessions`, `handoff` et `watcher`, installés à côté de celui-ci, et Orca (CLI `orca`). Sans Orca, le soir s'arrête (aucune session ne peut recevoir de consigne) ; le matin rend le tableau avec une commande `claude` par ligne à lancer à la main.

## Ce que le soir laisse au matin

Le **dossier de la nuit** : `~/.claude/handoffs/nuit-AAAA-MM-JJ/` (date du soir). Il contient :

- un brief par session, au contrat du skill handoff (palier selon l'effort, nom horodaté à la seconde), dont la première ligne est la **ligne de reprise** :
  `<!-- reprise: --dir <dossier> --effort <niveau> --title "<nom de l'onglet>" [--model <modèle>] [--safe] -->`
- `synthese.md`, la journée racontée (le soir, étape 3).
- `maj.md`, le compte rendu de la mise à jour de nuit (le soir, étape 5), s'il y a une règle « Mise à jour de nuit ».

Le matin lit le dernier dossier (`ls -d ~/.claude/handoffs/nuit-* | tail -1`) et passe chaque ligne de reprise telle quelle à `spawn-claude.sh`.

## Le soir

### 1. Relever

Le relevé de `/sessions` (`../sessions/SKILL.md`) : mêmes commandes, handles complets. Garde les sessions d'agent, pas les orphelins ni les terminaux sans agent. Une session en cours (`working`) ne s'interrompt pas : elle aura sa ligne « encore en cours », et le matin la passera par handoff.

### 1 bis. Ce qui demande un mot de passe, tout de suite

Avec une règle « Mise à jour de nuit » seulement. Lance `<script> --check` : il liste les casks à jour qui demandent sudo. Liste vide : rien à faire. Sinon, une seule demande, maintenant, pendant que l'utilisateur est là : « Tape `! brew upgrade --cask <liste>` et ton mot de passe une fois. Après, la nuit tourne seule. » Ne le tape pas toi-même. S'il passe, ces casks restent pour le matin. Plus aucune question sur la mise à jour ensuite.

### 2. Faire écrire les briefs

Crée le dossier de la nuit. À chaque session retenue, relis d'abord son écran (`orca terminal read --terminal <h> --limit 20 --json`) : une liste à cocher ouverte (« Enter to select ») prendrait ton texte pour une réponse. Dans ce cas n'envoie rien et note-la. Sinon envoie :

> Bonne nuit. Écris le brief de ta reprise selon le contrat du skill handoff (palier selon l'effort, nom horodaté à la seconde), dans `<dossier de la nuit>/` et pas ailleurs. Première ligne du brief : `<!-- reprise: --dir <dossier> --effort <niveau> --title "<nom de l'onglet>" [--model <modèle>] [--safe] -->`. Ne lance pas spawn-claude.sh, n'ouvre et ne ferme rien. Puis réponds en trois lignes seulement : « Fait : … », « En plan : … », « Brief : <chemin> ».

`orca terminal send --terminal <h> --text "..." --enter --wait-submit 15 --json`

Envoie à toutes, puis attends chacune (`orca terminal wait --terminal <h> --for tui-idle --timeout-ms 300000 --json`) et lis ses trois lignes (`orca terminal read --terminal <h> --limit 40 --json`). Vérifie que le brief existe sur le disque. Sans fichier, la session garde son onglet : dis-le.

Si ta propre session a un travail à reprendre (par exemple elle coordonne les autres), écris aussi ton brief dans le dossier de la nuit, en dernier, après la synthèse.

### 3. Raconter la journée

Sources : les trois lignes de chaque session, le plan du jour, les commits du jour dans les dossiers touchés (`git -C <dossier> log --since=midnight --oneline`).

Pas de verdict sur les objectifs : ni « tenu », ni « pas tenu », ni score, ni pourcentage. Ça culpabilise et n'aide à rien. Le but est que la journée marque la mémoire et que l'utilisateur sache dire ce qu'il construit. Cinq parties, courtes :

- **Ce qu'on a fait d'intéressant** : trois à cinq lignes, chacune un fait et pourquoi il compte.
- **À garder en tête** : ce qu'on a appris, une décision prise, une surprise.
- **Avec le plan du jour** : une ou deux lignes neutres, ce qui a avancé sur les lignes prévues et ce qui est arrivé en dehors. Un constat, pas un jugement.
- **Ce que j'en dirais** : deux ou trois phrases que l'utilisateur pourrait dire demain à un client, un investisseur ou un partenaire pour expliquer ce qu'il est en train de construire. À la première personne, dans sa voix, sans jargon d'agent. Le matin commence par elles.
- **En plan** : ce que les sessions laissent ouvert. Le matin demandera pour chaque ligne : on continue, ou ça entre dans le plan.

Écris la synthèse dans `<dossier de la nuit>/synthese.md`, puis à l'endroit que donne la règle « Synthèse du soir », en suivant les règles d'écriture de ce dossier (son `AGENTS.md` ou `CLAUDE.md`). Montre-la dans ta réponse.

### 4. Fermer

Une liste à cocher (`AskUserQuestion` en `multiSelect`), une option par session dont le brief existe : « Fermer <onglet> : brief <fichier>, rouvert demain matin ». Ferme seulement les cases cochées (`orca terminal close --terminal <h> --json`). Ne ferme jamais une session en cours ni une session sans brief. Ta propre session reste : dis en une ligne que l'utilisateur peut la fermer.

### 5. Mettre à jour pendant la nuit

Avec une règle « Mise à jour de nuit » seulement, après la fermeture. Lance `<script> --launch <dossier de la nuit>` : launchd prend la suite, hors d'Orca et sans autorisation à demander. Il met tout à jour sans sudo, versions majeures comprises, quitte Orca en dernier pour le mettre à jour sans le relancer, et écrit `maj.md` dans le dossier de la nuit. Une ligne : « Mise à jour lancée, compte rendu demain dans maj.md. »

## Le matin

À lancer dans une fenêtre neuve. La routine ne change pas d'un matin à l'autre : rassembler, croiser, demander, ouvrir.

### 1. Rassembler, en lecture seule

- **La nuit** : le dernier dossier de la nuit, ses briefs, sa `synthese.md` et son `maj.md`. De `maj.md`, garde seulement la partie « Pour le matin » : une ligne dans le tableau de l'étape 2, et ce qui s'y fait d'un geste (casks sudo) entre dans les questions du jour. Pas de dossier daté d'hier ou d'avant-hier : il n'y a pas eu de bonne nuit, suis « Sans bonne nuit » plus bas.
- **Les sessions encore ouvertes** : le relevé de `/sessions`.
- **Le plan du jour** : à l'endroit que donne la règle. Sans règle, il viendra des questions de l'étape 3.

### 2. Croiser

D'abord, en trois lignes, « Ce que j'en dirais » de la synthèse : c'est par là que la journée commence.

Puis un seul tableau, en texte : | Travail | Brief ou session | Plan du jour | Proposition | Effort |

- **Brief et ligne du plan** : rouvrir.
- **Brief hors plan** (resté en plan hier) : le continuer aujourd'hui et l'ajouter au plan, ou le laisser dormir (le brief reste dans le dossier de la nuit).
- **Ligne du plan sans brief ni session** : nouvelle session. Écris toi-même un brief express dans le dossier de la nuit, avec sa ligne de reprise (objectif : la ligne ; fichiers : la note liée ; critère de fin) : aucun contexte ne se perd, il n'y en a pas encore.
- **Session encore ouverte, sans brief** (elle travaillait le soir, ou elle a échappé à la bonne nuit) : elle passe par `/handoff` elle-même, comme à l'étape 5 de `/watcher`. Ou elle reste telle quelle si elle sert encore.
- **Brief de la session qui coordonne** : c'est toi. Tu ne l'ouvres pas ailleurs, tu le liras à la fin pour tenir ce rôle.

L'effort vient de la ligne de reprise ; pour une nouvelle session, de la grille d'effort du skill handoff.

Le plan appartient à l'utilisateur : n'y écris rien sans sa réponse. Avec sa réponse, ajoute la ligne en suivant les règles d'écriture du dossier qui le porte (son `AGENTS.md` ou `CLAUDE.md`).

### 3. Les questions du jour

Trois au plus, et seulement celles dont la réponse change ce qui s'ouvre : ce qui est resté en plan hier, une ligne du plan qui n'a plus de sens, l'ordre de la journée. Dans la forme que donne la règle « Forme des questions ». Puis une liste à cocher (`AskUserQuestion` en `multiSelect`) des fenêtres à ouvrir, dans l'ordre de la règle « Ordre des onglets », chaque option avec son effort.

### 4. Ouvrir

Pour chaque case cochée, dans l'ordre :

`"${CLAUDE_SKILL_DIR}/../handoff/scripts/spawn-claude.sh" --brief <fichier> <ligne de reprise> --no-close`

`--no-close` est obligatoire : sans lui, le script ferme ta fenêtre. Ensuite, range les onglets comme `/watcher range`, puis relis `orca terminal list --json` pour vérifier que chaque fenêtre est ouverte. Une session encore ouverte dont le travail a maintenant sa fenêtre neuve se ferme sur une case cochée, jamais si elle est en cours.

Termine par une ligne : N fenêtres ouvertes, M travaux laissés à dormir. Si un brief de la session qui coordonne attendait, lis-le maintenant et tiens ce rôle.

### Sans bonne nuit

Même routine, mais les briefs s'écrivent ce matin : à chaque session retenue, envoie « Lance /handoff : <la suite en une ligne>. », comme à l'étape 5 de `/watcher`, et laisse-la ouvrir sa propre fenêtre. C'est plus lent et plus cher, chaque session relit tout son contexte, donc dis en une ligne que `/wake-up bonne-nuit` le soir évite ça.
