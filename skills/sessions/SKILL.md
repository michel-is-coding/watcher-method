---
name: sessions
description: >-
  Vue d'ensemble en lecture seule des sessions d'agents ouvertes (Orca, Claude, Codex) : un tableau, une ligne par session, sans proposition ni action. À utiliser pour « sessions », « quelles sessions tournent », « vue d'ensemble des agents », « l'architecture en cours ». Pour les suites à donner, les fusions et le ménage, c'est /watcher.
license: MIT
---

# Sessions

Tu relèves, tu affiches, tu t'arrêtes. Aucune proposition, aucune action, aucune question. Aucun tiret cadratin (—) dans ce que tu écris : virgule, deux-points ou parenthèses à la place.

**Règles personnelles.** Si `~/.config/matthieu-skills/regles.md` existe, lis-le d'abord : ce qu'il dit passe avant ce fichier. S'il n'existe pas, continue sans rien demander.

## Dépendances

| Dépendance | Rôle | Si elle manque |
|---|---|---|
| [Orca](https://onorca.dev), application ouverte, CLI `orca` dans le PATH | liste des terminaux, état des agents, lecture de la fin du fil | relève seulement les agents vus par `ps` (dossier par `lsof`, sujet par la dernière transcription), laisse les colonnes État et Contexte à « inconnu », et dis en une ligne qu'Orca est absent ou fermé |
| `ps`, `lsof`, `grep` (macOS ou Linux) | agents lancés hors d'Orca | le tableau ne couvre que les sessions Orca : dis-le |

Fonctionne sous Claude Code et sous Codex. Rien à configurer.

## 1. Relever

```sh
orca terminal list --json      # handle complet, worktreePath, branch, title, agentIdentity, orphaned, tabId, leafId
orca worktree ps --json        # agents[] : state (working, done...), prompt, lastAssistantMessage ; paneKey = "<tabId>:<leafId>"
ps -ax -o pid,lstart,command | grep -E '(^| )(claude|codex)( |$)' | grep -v grep   # tous les agents du Mac, Orca compris ; l'argv donne le brief lu, --resume, le modèle
orca terminal read --terminal <handle complet> --limit 60 --json   # fin du fil ; la ligne de statut donne le modèle et « ctx N % »
```

- Ta propre session est `$ORCA_TERMINAL_HANDLE` : ne la lis pas, mais garde-lui une ligne, marquée « (cette session) ».
- Les terminaux `orphaned: true` se listent sans être lus.
- Un agent qui tourne hors d'Orca (pid sans terminal) : son dossier par `lsof -a -d cwd -p <pid> -Fn`, son sujet par la dernière transcription (`~/.claude/projects/<dossier>/*.jsonl`, ligne `ai-title` ; `~/.codex/sessions/`).
- `state: working` avec `workingMode: monitoring` : la session est au repos mais garde un shell en fond. La fin du fil tranche (« done … · 1 shell still running »).
- Une question sortie de l'écran (« Jump to bottom ») ne se voit pas par `orca terminal read`. Lis-la dans la transcription : `jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="AskUserQuestion") | .input.questions[].question' <transcription>.jsonl | tail -4`.
- Une fin de fil « You've reached your … limit » : la session est bloquée par la limite de son modèle. État « attend l'utilisateur », avec ces mots.

## 2. Afficher

Un seul tableau, en texte dans la réponse, jamais seulement dans une question. Ordre : en cours, attend l'utilisateur, terminée, orpheline.

| Session | Dossier | Sujet | État | Contexte | Origine |

- **Session** : le titre Orca sans son glyphe, ou le pid pour un agent hors Orca. Précise « Codex » quand ce n'est pas Claude.
- **Dossier** : le dernier segment du worktreePath, et la branche si ce n'est pas master ou main.
- **Sujet** : une ligne, ce qu'elle fait ou vient de rendre (lastAssistantMessage, fin du fil).
- **État** : en cours (state working), attend l'utilisateur (une question ou une permission en suspens : laquelle, en quelques mots ; « handoff en attente » pour une liste « Handoff vers une fenêtre fraîche »), terminée (done, rien n'attend), orpheline.
- **Contexte** : « ctx N % » de la ligne de statut, et le modèle.
- **Origine** : le brief de handoff cité dans l'argv (nom du fichier, sans le chemin), « reprise » pour un `--resume`, « à la main » sinon. C'est la filiation : quelle session a été ouverte par quel brief.

Sous le tableau, une seule ligne : N sessions ouvertes, dont X en cours et Y qui attendent l'utilisateur. Rien d'autre : pas de suite proposée, pas de fusion, pas de fermeture. Ça, c'est `/watcher`.
