---
name: watcher
description: >-
  Fait le point sur toutes les sessions d'agents en cours (Orca, Claude, Codex) : d'abord les décisions qui attendent l'utilisateur, handoffs compris, puis une ligne par session avec la suite à donner, les fusions possibles et les fenêtres à fermer. Donne d'abord un nom court à chaque onglet et range les onglets, sans demander. Pour le reste, lecture seule, puis agit seulement sur accord. À utiliser pour « watcher », « où en sont mes sessions », « qu'est-ce qui tourne », « qu'est-ce qui m'attend », « quels handoffs attendent », « fais le ménage dans les conversations », « renomme les sessions », « range les onglets ».
license: MIT
---

# Watcher

Tu observes, tu proposes, tu n'agis qu'avec l'accord de l'utilisateur. Seule exception : nommer et ranger les onglets (étape 2), que tu fais sans demander. Reste bref. Aucun tiret cadratin (—) dans ce que tu écris : virgule, deux-points ou parenthèses à la place.

**Règles personnelles.** Avant l'étape 1, lis `~/.config/matthieu-skills/regles.md` : ce qu'il dit passe avant ce fichier. S'il n'existe pas, lance d'abord le skill `regles` si l'utilisateur est là pour répondre ; sinon (boucle, session lancée par un agent, skill `regles` absent) continue avec les règles de ce fichier, sans rien écrire.

## Dépendances

| Dépendance | Rôle | Si elle manque |
|---|---|---|
| Le skill `sessions`, installé à côté de celui-ci (`../sessions/SKILL.md`) | le relevé et le tableau de base | arrête-toi et demande de l'installer : ne reconstruis pas le relevé de mémoire |
| Le skill `handoff`, installé à côté de celui-ci (`../handoff/SKILL.md`), sous Claude Code | faire passer une session à une fenêtre fraîche ; ses propositions t'arrivent en attente | propose une nouvelle session à la main (dossier, effort, trois lignes de brief) et dis en une ligne que `handoff` le ferait d'une case cochée |
| [Orca](https://onorca.dev), application ouverte, CLI `orca` dans le PATH | lire les sessions, leur écrire, les nommer, les fermer | rends le tableau réduit prévu par `sessions`, sans proposer de fusion ni de fermeture : sans Orca, aucune action n'est possible |
| `scripts/reorder-tabs.sh`, dans le dossier de ce skill | ranger les onglets | si le script échoue, rien n'a bougé : donne l'ordre voulu en une ligne et continue |
| `scripts/retours.py`, Python 3 et `gh` connecté | envoyer un retour de méthode (voir « Retours ») | donne le chemin du fichier et dis d'ouvrir l'issue à la main |
| Une liste à cocher (`AskUserQuestion` sous Claude Code) | validation des handoffs, des fusions et des fermetures | pose la question en texte, une action par ligne numérotée, et attends les numéros retenus |

## Le skill handoff

`/handoff` fait passer une session à une fenêtre fraîche. La session écrit elle-même un brief (objectif, décisions déjà prises et leur raison, fichiers, interdits, critères de fin), ouvre un nouvel onglet Orca où un `claude` neuf lit ce brief, puis ferme son propre onglet. Elle seule a le contexte : tu ne composes jamais un brief à sa place.

- **Quand tu le proposes** : dans la colonne Suite, quand une session dépasse 60 % de contexte, ou quand la suite de son travail change de dossier, d'effort ou de niveau de risque.
- **Quand il attend l'utilisateur** : la fin du fil d'une session montre une liste « Handoff vers une fenêtre fraîche », ou la session propose un handoff en texte, ou elle t'a envoyé un message « Handoff en attente ». Un tel message reçu entre deux passages va dans le lot des décisions : montre le lot aussitôt, sans refaire le relevé.
- **Quand tu l'exécutes** : seulement sur le mot de l'utilisateur, à l'étape 5.

## 1. Relever

Le relevé et le tableau de base sont ceux de `/sessions` (`../sessions/SKILL.md`, dans le dossier voisin de celui-ci) : mêmes commandes, mêmes colonnes, même définition des états. Lis-le et applique-le d'abord.

## 2. Nommer et ranger, sans demander

Les titres automatiques d'Orca sont flous et changent en cours de route. À chaque passage, donne un nom aux onglets qui n'en ont pas et remets les onglets en ordre. Aucune validation : les deux gestes se défont en une commande.

```sh
orca terminal list --include-visual-layouts --json   # .result.visualLayouts[] : un worktree ; .root.tabs[] dans l'ordre affiché
```

Pour chaque onglet, `.title` est le titre affiché et `.panes.title` celui que l'agent se donne. S'ils sont identiques au glyphe près, aucun nom n'a été posé.

**Nom** : 2 à 4 mots, le projet d'abord, puis l'objet. Ni article, ni ponctuation, ni symbole, ni date. On doit comprendre le sujet sans rien lire d'autre (« Site accueil », « Compta relances », « Notes coordinateur »). Deux sessions sur le même objet : un mot de plus pour les distinguer. Tire le nom de ce que la session fait vraiment (ses derniers échanges, sa transcription), pas de son premier message.

**Renomme peu.** Pose un nom seulement dans trois cas :

- aucun nom n'a été posé ;
- le nom posé sort de la règle (plus de 4 mots, ponctuation, date) ;
- la session a changé de projet ou d'objet. Le signe : le titre de l'agent ne partage plus aucun mot avec le nom posé. Lis alors la session avant de trancher.

Un nom posé qui respecte la règle reste, même si tu en aurais choisi un autre. Ne lis pas une session dont le nom reste. Un terminal sans agent (« Terminal 1 ») garde son titre. Ta propre session se nomme « WATCHER » : `/handoff` cherche d'abord ce titre exact, puis seulement un titre qui contient le mot. Une session qui travaille sur le skill watcher ne porte donc pas ce mot.

`orca terminal rename --terminal <h> --title "<nom>" --json`

**Ordre**, dans chaque worktree qui a plusieurs onglets : la session qui coordonne les autres d'abord, puis les sessions groupées par projet (projets par ordre alphabétique, la plus ancienne d'abord dans un projet), les terminaux sans agent à la fin. L'état ne compte pas : le glyphe de l'onglet le montre déjà, et un tri par état ferait bouger les onglets à chaque passage.

`scripts/reorder-tabs.sh <worktreePath> <tabId> [<tabId>...]`

Le script répond « rangé » ou « déjà en ordre ». `--dry-run` en premier argument affiche l'ordre sans l'appliquer.

**Vérifie** : relis la liste, puis dis en une ligne ce qui a changé (« 3 onglets renommés, site rangé »). Si rien n'a changé, ne dis rien.

**`/watcher range`** s'arrête ici : ni tableau, ni question. Seule exception, les handoffs en attente : une ligne chacun, pour qu'aucun ne reste des heures dans une liste que personne ne voit.

## 3. Rendre le point

Dans cet ordre, en texte dans ta réponse.

**Ce qui attend l'utilisateur**, d'abord, réuni en un seul lot : une ligne par décision (quelle session, ce qu'elle propose, ce que la réponse déclenche). Les handoffs en attente en tête, puis les relais « bloqué » restés sans réponse (reçus par toi, ou à la fin du fil de la coordinatrice), puis les autres questions et permissions en suspens. Si rien n'attend, une ligne : « rien ne t'attend ».

**Le tableau** de `/sessions`, plus une colonne. La colonne Session donne le nom posé à l'étape 2.

| Session | Dossier | Sujet | État | Contexte | Origine | Suite proposée |

- **Suite proposée** : une seule action concrète. Relancer avec telle question, lui passer un relais, handoff (voir plus haut), ou fermer.
- **Rebond** : si une session a fini un travail, donne en une ligne ce qu'il rend possible ensuite. Ne l'invente pas : sans suite évidente, n'écris rien.

**Le ménage**, sous le tableau :
- **Fusions** : les sessions qui écrivent les mêmes fichiers ou suivent le même chantier. Celle qui a le plus de marge de contexte absorbe les autres.
- **À fermer** : les orphelins, et les sessions terminées où rien n'attend.

**Retours**, une seule fois, et seulement si l'utilisateur est là pour répondre (pas en boucle). Si `regles.md` a été écrit il y a plus de dix jours (sa date en tête) et n'a pas de section « Retours », ajoute une ligne sous le ménage : « Dix jours d'usage : tes changements de méthode peuvent servir la prochaine version. Je prépare le retour ? ». Sa réponse, oui ou non, s'écrit dans `regles.md` : section « ## Retours », « Rappel fait le <date>. ». Sur un oui, écris `~/.config/matthieu-skills/retours/<sujet>.md` au format de [RETOURS.md](https://github.com/94-hermes/matthieu-skills/blob/main/RETOURS.md), avec seulement ce qui change la méthode : les règles écrites avec ses mots et les sections qu'il a ajoutées. Une option déjà proposée par `regles` n'est pas un retour. Rien de `contexte.md`, aucun nom, contenu ni chemin. Montre le texte, puis, sur son mot : `scripts/retours.py <fichier>`. Le script refuse un texte qui garde un e-mail, un chemin, un lien ou un nom tiré de `contexte.md` ; sinon il crée son fork au besoin, y dépose le retour et ouvre l'issue chez 94-hermes.

## 4. Faire valider

Affiche d'abord le point de l'étape 3 en texte, dans ta réponse : la liste à cocher masque l'écran, et un résumé d'une phrase ne remplace pas le tableau. Ensuite seulement, présente les actions dans une liste à cocher (sous Claude, `AskUserQuestion` en `multiSelect`), dans le même ordre : les handoffs en attente d'abord, puis les fusions et les fermetures. Chaque option dit ce qui se passe concrètement. Aucun handoff, aucune fusion ni fermeture ne part sans une case cochée.

## 5. Exécuter

- **Handle complet** toujours : `term_xxxxxxxx-...`. Un handle court renvoie `terminal_handle_stale`.
- **Avant tout envoi**, relis l'écran : une liste à cocher ouverte (« Enter to select ») prend ton texte pour une réponse. N'envoie rien, attends qu'elle se ferme ou dis-le.
- **Session bloquée par la limite de son modèle**, sur le mot de l'utilisateur : `/model <autre modèle>` (réponds « 1 » si « Switch model? » s'affiche), `/effort <niveau>`, puis « Reprends exactement là où l'erreur t'a arrêté, sans refaire ce qui est fait. ». Effort haut pour les décisions qui engagent, moyen ou bas pour le reste. Ces deux commandes changent aussi le réglage par défaut des nouvelles sessions : dis-le.
- **Handoff en attente** : relis la fin du fil juste avant d'agir (`orca terminal read --terminal <h> --limit 30 --json`).
  - La liste « Handoff vers une fenêtre fraîche » est ouverte, curseur sur la première option : envoie une Entrée seule. Elle valide l'option recommandée, toujours la première.
    `orca terminal send --terminal <h> --enter --json`
  - La session a proposé le handoff en texte, sans liste : réponds à sa place « Oui, exécute le handoff. », par SendMessage si elle a une boîte de réception (sous Claude Code, son nom dans ListAgents), sinon par `orca terminal send --terminal <h> --text "Oui, exécute le handoff." --enter --json`.
  - La liste a changé (autre question, curseur déplacé) : n'envoie rien, dis-le.
- **Handoff que tu proposes** : envoie à la session « Lance /handoff : <la suite en une ligne>. », de la même façon. Elle écrit son brief ; si elle a un doute, sa liste revient au passage suivant.
- **Après un handoff**, vérifie : `orca terminal wait --terminal <h> --for exit --timeout-ms 60000 --json`, puis `orca terminal list --json`. L'ancien onglet est fermé (sauf s'il devait être gardé) et un nouvel onglet, absent du relevé, est ouvert. Donne son nom en une ligne (« Site accueil : handoff fait, nouvel onglet Site refonte »). Si rien n'a bougé après une minute, dis-le et ne relance rien.
- **Fusion** : envoie le fil à la session qui absorbe (où c'en était, fichiers touchés, ce qui attend), en finissant par « réponds seulement "fil repris" ».
  `orca terminal send --terminal <h> --text "..." --enter --wait-submit 15 --json`
  puis `orca terminal wait --terminal <h> --for tui-idle --timeout-ms 90000 --json`, puis lis sa réponse. Ferme la session absorbée seulement après ce « fil repris ».
- **Fermer** : `orca terminal close --terminal <h> --json`. Ça arrête le process et efface la reprise dans Orca ; les fichiers et les transcriptions restent. Un onglet épinglé refuse (`terminal_tab_pinned`) : demande à l'utilisateur de le désépingler.
- Ne ferme jamais une session `working`, ni une session dont un sous-agent tourne encore. Ne ferme ni ne fusionne un worker qu'une orchestration Orca supervise encore (son handle figure dans `orca orchestration worker-list --json`, `.result.workers[].agentTerminalHandle`, avec un `dispatchStatus` autre que `completed`) : il appartient à son coordinateur, qui le libère.

Pour un watcher récurrent : `/loop 1h /watcher`, dans son propre onglet. Ne signale alors que ce qui a changé depuis le passage précédent, plus tout ce qui attend encore l'utilisateur. Pour garder seulement les noms et l'ordre à jour en arrière-plan : `/loop 1h /watcher range`.
