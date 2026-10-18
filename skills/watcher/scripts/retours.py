#!/usr/bin/env python3
"""Envoie un retour de méthode anonymisé : copie dans le fork de l'utilisateur, puis issue chez 94-hermes.

Usage : retours.py <retour.md> [--dry-run]   |   retours.py --self-check
Refuse l'envoi (code 1) si le texte contient un e-mail, un chemin de la machine, un lien hors de
94-hermes, ou un nom propre tiré de ~/.config/matthieu-skills/contexte.md.
"""
import base64, os, re, subprocess, sys, time
from datetime import datetime

UP = "94-hermes/session-skills"
CONTEXTE = os.path.expanduser("~/.config/matthieu-skills/contexte.md")


def noms_propres(contexte):
    """Mots à majuscule qui n'ouvrent pas une phrase : clients, personnes, projets."""
    noms = set()
    for phrase in re.split(r"[.!?:\n]+", contexte):
        for mot in re.findall(r"[\w'-]+", phrase)[1:]:
            if len(mot) >= 3 and mot[0].isupper():
                noms.add(mot)
    return noms


def fuites(texte, contexte=""):
    """Ce qui ne doit pas quitter la machine, une ligne par fuite."""
    trouve = re.findall(r"[\w.+-]+@[\w-]+\.[\w.]+", texte)
    trouve += re.findall(r"(?:/Users/|/home/|[A-Z]:\\)\S*", texte)
    trouve += [p for p in re.findall(r"~/\S+", texte) if not p.startswith(("~/.config/matthieu-skills", "~/.claude"))]
    trouve += [u for u in re.findall(r"https?://\S+", texte) if not u.startswith("https://github.com/94-hermes/")]
    trouve += [n for n in noms_propres(contexte) if re.search(rf"\b{re.escape(n)}\b", texte, re.I)]
    return sorted({t.rstrip(".,;:)") for t in trouve})


def gh(*args):
    return subprocess.run(["gh", *args], check=True, capture_output=True, text=True).stdout.strip()


def envoyer(chemin, texte):
    moi = gh("api", "user", "--jq", ".login")
    gh("repo", "fork", UP, "--clone=false")  # sans effet si le fork existe déjà
    fork = ""
    for _ in range(10):  # un fork neuf met quelques secondes à apparaître
        fork = gh("api", f"repos/{UP}/forks", "--jq", f'.[] | select(.owner.login == "{moi}") | .full_name')
        if fork:
            break
        time.sleep(3)
    if not fork:
        sys.exit("fork introuvable : relance dans une minute")
    nom = datetime.now().strftime("%Y-%m-%d-%H%M%S-") + os.path.basename(chemin)
    gh("api", "-X", "PUT", f"repos/{fork}/contents/retours/{nom}",
       "-f", f"message=Retours de méthode {nom}",
       "-f", "content=" + base64.b64encode(texte.encode()).decode())
    titre = texte.splitlines()[0].lstrip("# ").strip() if texte.startswith("# ") else f"Retours de méthode {nom}"
    lien = f"https://github.com/{fork}/blob/HEAD/retours/{nom}"
    print(gh("issue", "create", "-R", UP, "--title", titre, "--body", f"{texte}\n\nCopie dans le fork : {lien}"))


def self_check():
    ctx = "Je suis consultante. Je suis Acme et Bernard au quotidien."
    assert noms_propres(ctx) == {"Acme", "Bernard"}, noms_propres(ctx)
    assert fuites("Le watcher range par projet.", ctx) == []
    assert fuites("Lis ~/.config/matthieu-skills/regles.md et https://github.com/94-hermes/x", ctx) == []
    assert fuites("Relance acme le lundi.", ctx) == ["Acme"]
    assert fuites("Écris à a.b@c.fr depuis /Users/a/x ou ~/Documents/y, voir https://plane.so") == \
        sorted(["a.b@c.fr", "/Users/a/x", "~/Documents/y", "https://plane.so"])
    print("ok")


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-check"]:
        self_check()
        sys.exit()
    if not sys.argv[1:]:
        sys.exit(__doc__)
    chemin = sys.argv[1]
    texte = open(chemin, encoding="utf-8").read()
    contexte = open(CONTEXTE, encoding="utf-8").read() if os.path.exists(CONTEXTE) else ""
    if f := fuites(texte, contexte):
        print("Envoi refusé, à anonymiser :", *f, sep="\n- ")
        sys.exit(1)
    if "--dry-run" in sys.argv:
        print(f"Anonymisation ok. Partirait vers le fork de l'utilisateur, puis en issue sur {UP}.")
    else:
        envoyer(chemin, texte)
