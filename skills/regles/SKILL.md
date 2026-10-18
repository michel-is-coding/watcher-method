---
name: regles
description: >-
  À utiliser au premier usage des skills sessions, watcher et handoff, ou quand l'utilisateur veut choisir ou changer sa façon de travailler avec eux (son métier, organisation des sessions, rôle du coordinateur, implication du watcher, forme des textes, noms et ordre des onglets, forme des questions, autonomie du handoff), ou quand un de ces skills ne trouve pas le fichier de règles personnelles ~/.config/matthieu-skills/regles.md. Déclencheurs : « règles », « mes réglages », « mes préférences », « initialise les skills », « onboarding », « change la façon de nommer les onglets ».
license: MIT
---

# Règles

Chacun a sa façon de travailler avec ses sessions d'agents. Ce skill la demande en premier, par des questions, et l'écrit dans un fichier à l'utilisateur : `~/.config/matthieu-skills/regles.md`. Les skills `watcher`, `sessions` et `handoff` le lisent avant d'agir, et ce qu'il dit passe avant leur texte. Le fichier vit hors du dépôt des skills : il ne se publie jamais avec eux.

Trois choses à ne pas mêler. La **méthode** est dans les skills : elle change par une release. Les **règles**, dans `regles.md`, sont les réglages de l'utilisateur sur cette méthode. Le **contexte**, dans `contexte.md`, dit son métier et ce qu'il mène en ce moment : il évolue, l'utilisateur le réécrit quand il veut, et il ne quitte jamais sa machine.

Fonctionne sous Claude Code et sous Codex. Aucune dépendance.

## Déroulé

1. Si `~/.config/golems/` existe (ancien nom du dossier), déplace dans `~/.config/matthieu-skills/` chaque fichier qui n'y est pas encore. Puis lis `~/.config/matthieu-skills/regles.md` s'il existe. Ce qu'il dit devient, dans chaque question, l'option marquée « (actuel) ».
2. Lis `~/.config/matthieu-skills/contexte.md`. S'il n'existe pas, demande en texte libre : « Raconte en quelques phrases ton métier et ce que tu mènes en ce moment. » Écris la réponse telle quelle dans ce fichier. Ce récit choisit, par la table « Orienter », l'option recommandée de chaque question.
3. Pose les dix questions du tableau, dans l'ordre, par lots de quatre au plus : d'abord les quatre sur la méthode de travail (organisation des sessions, rôle du coordinateur, implication du watcher, forme des textes), puis les onglets et les questions, puis le handoff. Liste à cocher (`AskUserQuestion` sous Claude Code) ; sans cet outil, en texte, options numérotées.
4. Écris le fichier (crée le dossier au besoin), affiche-le, puis dis en une ligne comment le changer : à la main, ou en relançant ce skill.

Si l'utilisateur ne veut pas répondre maintenant : écris le fichier avec « Par défaut. » dans chaque section. Les autres skills le trouveront et ne relanceront pas les questions.

## Une question

- La question dit ce que la règle change, et dans quel skill.
- Chaque option dit ce qui se passe si on la choisit, et à qui elle convient.
- La première option est la valeur par défaut, marquée « (par défaut) ». C'est la pratique qui a fait ses preuves : on ne réinvente pas, on décrit ce qui marche. Seule exception : l'option que désigne la table « Orienter » passe en premier, marquée « (recommandé pour toi) ».
- L'utilisateur peut toujours répondre avec ses mots : sa phrase devient la règle, recopiée telle quelle.

Exemple, pour la première règle :

> **Organisation des sessions.** Le watcher range les onglets et le handoff écrit ses briefs selon la façon dont tes sessions se parlent. Laquelle te ressemble ?
> 1. Une session coordonne, les autres lui rendent compte (par défaut) : elle ouvre les sessions de travail par `/handoff`, chacune lui envoie un relais « fil clos » en fin de tâche, un watcher observe l'ensemble. Pour qui mène plusieurs chantiers de front.
> 2. Des sessions indépendantes, sans coordinatrice : le watcher fait seul le lien. Pour qui tient deux ou trois sessions sur un seul projet.
> 3. Des sessions qui se passent le fil entre elles. Pour qui ne garde pas de coordinatrice ouverte ; le risque est que deux sessions écrivent le même fichier.

## Les règles

| Règle | Lue par | Par défaut | Autres choix |
|---|---|---|---|
| Organisation des sessions | watcher, handoff | une session coordonne ; les sessions de travail lui envoient un relais « bloqué » dès qu'il leur manque une info, un accès, un outil ou une décision, et « fil clos » en fin de tâche ; elles ne s'écrivent pas entre elles ; un watcher observe | pas de coordinatrice, le watcher fait le lien ; les sessions se passent le fil entre elles |
| Rôle du coordinateur | watcher, handoff | écrit les briefs, reçoit les relais, réunit les décisions en lot, veille à ce que chaque session écrive dans son seul dossier ; ne fait jamais la tâche lui-même, ne pousse rien sans accord | surveille aussi les sessions, à la place d'un watcher ; travaille aussi dans son propre dossier |
| Implication du watcher | watcher | nomme et range les onglets sans demander ; propose ; exécute handoffs, fusions et fermetures sur une case cochée | observe seulement, ne touche à rien ; ferme aussi seul les orphelins et les sessions terminées où rien n'attend |
| Forme des textes | watcher, sessions, handoff | court et concret : une ligne par chose, un seul tableau, français courant, sans abréviation ni tiret cadratin | une phrase de pourquoi sous chaque proposition ; concret et sans jargon technique ; télégraphique |
| Ce que le watcher propose en premier | watcher | les décisions qui attendent l'utilisateur, handoffs compris, réunies en lot, avant tout ménage | une suite par session d'abord, puis les fusions et les fermetures |
| Forme des questions | watcher, handoff | courte si la question est simple ; complexe, le contexte dans la question et dans chaque option, et une décision technique dite par ses effets sur ce que l'outil fera ; la recommandation toujours en première option | toujours courte ; toujours détaillée |
| Noms des onglets | watcher, handoff | 2 à 4 mots, le projet d'abord, puis l'objet | en capitales, le sujet seul |
| Ordre des onglets | watcher | la session qui coordonne, puis les sessions par projet, dans chaque worktree (la barre latérale d'Orca ne se range pas) | l'ordre que l'utilisateur dicte ; ne pas ranger |
| Autonomie de la session ouverte par handoff | handoff | pleine autonomie, sauf actions sortantes ou irréversibles | demander les permissions (`--safe`) |
| Onglet courant après un handoff | handoff | fermé | gardé (`--no-close`) |

Un fichier écrit avant ce tableau peut garder les sections « Nommer et ranger sans accord » et « Ponctuation » : elles valent toujours.

## Orienter

Lis le récit de `contexte.md`. Chaque ligne dont le signal y figure recommande une option. Aucun signal : les valeurs par défaut. Deux lignes qui recommandent deux options différentes pour la même question : la valeur par défaut pour cette question.

| Le récit dit | Option recommandée |
|---|---|
| plusieurs clients, projets ou chantiers menés de front | Organisation des sessions : une session coordonne |
| un seul projet, ou deux ou trois sessions à la fois | Organisation des sessions : pas de coordinatrice, le watcher fait le lien |
| pas technique, ou un métier hors du code (vente, conseil, design, gestion) | Forme des textes : concret et sans jargon technique ; Forme des questions : toujours détaillée |
| développeur, ou à l'aise dans un terminal | Forme des textes : télégraphique ; Forme des questions : toujours courte |

Quand le contexte change, modifie `contexte.md` à la main, puis relance ce skill : il repropose les options.

## Le fichier

Dix sections, celles du tableau, dans le même ordre. Chaque section tient en une à trois phrases à l'impératif, que les autres skills suivront à la lettre.

```markdown
# Mes règles

Écrit par le skill `regles` le 2026-09-30. Modifiable à la main.

## Organisation des sessions
Par défaut.

## Rôle du coordinateur
Par défaut.

…

## Noms des onglets
En capitales, le sujet seul, sans le projet devant : ACCUEIL, RELANCES. Un nom posé sous cette forme reste.
```

Une règle que l'utilisateur dicte en plus du tableau prend sa propre section, à la fin.
