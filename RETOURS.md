# Tes retours

Après dix jours d'usage, tu as changé des choses dans ta façon de travailler avec les skills. Ce qui marche mieux sert aux prochaines versions : pousse-le vers la communauté 94.

Un retour ne porte que sur la méthode, jamais sur ton contexte (voir [méthode, règles et contexte](skills/regles/SKILL.md)).

## Comment ça part

Le watcher te le propose une fois et prépare le texte. Tu le relis. Sur ton mot, `skills/watcher/scripts/retours.py <fichier>` :

1. refuse le texte s'il garde un e-mail, un chemin de ta machine, un lien hors de 94-hermes ou un nom propre de ton `contexte.md` ;
2. crée ton fork de [94-hermes/session-skills](https://github.com/94-hermes/session-skills) s'il n'existe pas : les retours passent par lui ;
3. y dépose le retour, dans `retours/` ;
4. ouvre une issue chez 94-hermes/session-skills, avec le texte et le lien vers ton fork.

Sans watcher, écris le fichier toi-même au format ci-dessous, puis lance le script. `--dry-run` vérifie l'anonymisation sans rien envoyer.

## Le format

Un sujet par retour, en trois lignes :

1. Ce que fait le skill aujourd'hui.
2. Ce que tu fais à la place, et depuis quand.
3. Ce que ça remplace ou raccourcit.

Écris « un client », « l'outil de facturation », « mon dossier de pilotage » : jamais un nom, un contenu de mail, de fichier ou de réunion.

## Qui décide

Matthieu valide chaque changement. Une proposition qui ajoute un mécanisme sans rien remplacer a peu de chances d'entrer : les skills restent simples.

## Avant chaque release

Matthieu compare chaque release à la précédente (`git diff v<version précédente>..HEAD -- skills/`). Une ligne retirée ou affaiblie sans raison écrite dans le commit bloque la release : c'est ce qui évite de glisser, petit à petit, vers une version moins bonne. Une release part quand la version de `.claude-plugin/plugin.json` change sur `main`.
