# watcher-method

Cinq skills pour travailler à plusieurs sessions d'agents dans Claude Code et Codex :
`sessions`, `watcher`, `handoff`, `regles`, `wake-up`. Extrait public des skills de Matthieu E. (`michel-is-coding`).

## Installer

```sh
/plugin marketplace add 94-hermes/watcher-method   # Claude Code, dans une session
/plugin install matthieu@watcher-method
codex plugin marketplace add 94-hermes/watcher-method   # Codex, dans le terminal
codex plugin add matthieu@watcher-method
```

À la main : clone, puis lie les cinq dossiers de `skills/` dans `~/.claude/skills`.

## Commencer

Lance `/matthieu:regles` (ton métier, dix questions), puis `/matthieu:watcher`.
Le mode d'emploi complet est dans [skills/README.md](skills/README.md#commencer).

## Licence

MIT, un fichier `LICENSE` par skill.
