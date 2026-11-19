"""Les 4 nains du village (Gaspard, Liesel, Brom, Margot), modélisés en détail.
Silhouette de nain : tête et mains fortes, torse en tonneau, jambes courtes, grosses bottes.
Objets « Nom_Groupe_Teinte » (Groupe = Corps | Buste | Tete) ; le jeu recolore selon la tenue.
Repère L : x = droite du perso, y = haut (pieds à 0), -z = devant.
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import math, random
import bmesh
from mathutils import Vector
from commun import *

APERCU = {
    "Gaspard": dict(Haut=(92, 40, 36), Bas=(60, 50, 44), Peau=(232, 190, 160), Cheveux=(160, 156, 150),
                    Barbe=(176, 172, 166), Chapeau=(70, 50, 36)),
    "Liesel": dict(Haut=(70, 96, 120), Bas=(64, 56, 48), Peau=(240, 202, 176), Cheveux=(176, 82, 40),
                   Tablier=(96, 66, 44)),
    "Brom": dict(Haut=(90, 70, 58), Bas=(48, 42, 38), Peau=(196, 150, 118), Cheveux=(150, 70, 36),
                 Barbe=(160, 72, 34), Tablier=(70, 46, 30)),
    "Margot": dict(Haut=(150, 110, 60), Bas=(80, 50, 60), Peau=(222, 176, 140), Cheveux=(92, 56, 34),
                   Tablier=(230, 220, 200), Foulard=(150, 60, 50)),
}
COMMUN = dict(Bottes=(64, 44, 30), Revers=(46, 32, 24), Semelle=(30, 22, 18), Ceinture=(62, 42, 30),
              Boucle=(214, 170, 70), Yeux=(244, 240, 232), Pupilles=(46, 34, 24), Bouche=(126, 62, 56),
              Bois=(110, 76, 48), Metal=(150, 154, 162), Couverture=(120, 36, 32), Pages=(236, 224, 196),
              Mousse=(246, 236, 210), Ruban=(40, 30, 24), Cuir=(92, 60, 38), Acier=(120, 124, 132),
              Verre=(150, 200, 220), Foulard=(150, 60, 50))

NAINS = {
    "Gaspard": dict(coiffure="couronne", chapeau=True, barbe="soignee", lunettes=True, manteau=True,
                    outil="registre", carrure=1.0),
    "Liesel": dict(coiffure="tresses", lunettesAtelier=True, tablier=True, outil="pioche", carrure=0.9,
                   femme=True, bracelets=True),
    "Brom": dict(coiffure="couronne", barbe="tressee", tablier=True, manchesCourtes=True, outil="marteau",
                 carrure=1.15, epauliere=True, bracelets=True),
    "Margot": dict(coiffure="chignon", foulard=True, tablier=True, outil="chope", carrure=0.95, femme=True,
                   jupe=True),
}

TETE = Vector((0, 3.85, 0))


def sombre(c, k=0.3):
    return tuple(int(v * (1 - k)) for v in c)


class Nain:
    def __init__(self, nom, o, decal):
        self.nom, self.o, self.decal = nom, o, decal
        cols = dict(COMMUN)
        cols.update(APERCU[nom])
        cols["Nez"] = cols["Peau"]
        cols["Joues"] = tuple(int(a * 0.7 + b * 0.3) for a, b in zip(cols["Peau"], (210, 90, 80)))
        cols["Barbe"] = cols.get("Barbe", cols["Cheveux"])
        cols["Sourcils"] = cols["Barbe"]
        cols["HautSombre"] = sombre(cols["Haut"])
        cols["Tablier"] = cols.get("Tablier", (80, 60, 40))
        cols["TablierSombre"] = sombre(cols["Tablier"], 0.18)
        cols["Chapeau"] = cols.get("Chapeau", (70, 50, 36))
        self.cols = cols
        self.pieces = {}

    def mat(self, teinte):
        metal = teinte in ("Metal", "Boucle", "Acier")
        return materiau(f"{self.nom}_{teinte}", self.cols[teinte], 0.35 if metal else 0.8, 1.0 if metal else 0.0)

    def ajout(self, groupe, teinte, ob):
        self.pieces.setdefault((groupe, teinte), []).append(ob)
        return ob

    def forme(self, groupe, teinte, bm, subdiv=0, biseau=0.0, epaisseur=0.0, segments=3):
        ob = objet(f"{self.nom}_tmp", bm, self.mat(teinte), decal=self.decal)
        if biseau:
            modif(ob, 'BEVEL', width=biseau, segments=segments, limit_method='NONE')
        if epaisseur:
            modif(ob, 'SOLIDIFY', thickness=epaisseur, offset=-1)
        if subdiv:
            modif(ob, 'SUBSURF', levels=subdiv, render_levels=subdiv)
        appliquer(ob)
        return self.ajout(groupe, teinte, ob)

    def membre(self, groupe, teinte, points, subdiv=1):
        return self.ajout(groupe, teinte, chaine(f"{self.nom}_tmp", points, self.mat(teinte), subdiv, self.decal))

    def sphere(self, groupe, teinte, pos, ech, rot=(0, 0, 0), subdiv=1, u=20, v=12):
        return self.forme(groupe, teinte, bm_sphere(T(pos, rot, ech), u, v), subdiv=subdiv)

    def tresse(self, groupe, teinte, depart, arrivee, rayon, n=7, anneau="Acier"):
        """Tresse : chapelet de boules qui s'affinent, anneau de métal au bout."""
        a, b = Vector(depart), Vector(arrivee)
        for i in range(n):
            t = i / (n - 1)
            p = a.lerp(b, t)
            r = rayon * (1 - 0.45 * t)
            self.sphere(groupe, teinte, p, (r, r * 1.25, r), rot=(0, 0, 0.35 if i % 2 else -0.35), subdiv=1, u=12, v=8)
        if anneau:
            self.forme(groupe, anneau, bm_tore(T(b + Vector((0, 0.08, 0))), R=rayon * 0.6, r=0.035, seg=14, segp=6))

    def finir(self):
        res = []
        for (groupe, teinte), objs in self.pieces.items():
            ob = fusionner(objs, f"{self.nom}_{groupe}_{teinte}")
            ob.data.materials.clear()
            ob.data.materials.append(self.mat(teinte))
            decimer(ob, 3000)
            dur = teinte in ("Metal", "Boucle", "Acier", "Couverture", "Pages", "Semelle", "Verre")
            lisse(ob, angle=50 if dur else None)
            centrer_origine(ob)
            res.append(ob)
        return res


# ---------------- morceaux ----------------

def profil_torse(c, femme):
    if femme:
        a = [(1.45, 1.05, 0.78), (1.9, 1.0, 0.74), (2.3, 0.98, 0.72), (2.7, 1.06, 0.76),
             (3.05, 1.06, 0.72), (3.28, 0.82, 0.56), (3.4, 0.4, 0.34)]
    else:
        a = [(1.45, 1.12, 0.82), (1.9, 1.16, 0.86), (2.3, 1.2, 0.88), (2.7, 1.22, 0.86),
             (3.05, 1.18, 0.8), (3.3, 0.9, 0.6), (3.42, 0.42, 0.36)]
    return [(y, rx * c, rz * (1 + (c - 1) * 0.6)) for (y, rx, rz) in a]


def rayon(profil, y):
    if y <= profil[0][0]:
        return profil[0][1], profil[0][2]
    for (y0, rx0, rz0), (y1, rx1, rz1) in zip(profil, profil[1:]):
        if y0 <= y <= y1:
            t = (y - y0) / (y1 - y0)
            return rx0 + (rx1 - rx0) * t, rz0 + (rz1 - rz0) * t
    return profil[-1][1], profil[-1][2]


def jambes(n):
    o = n.o
    c = o.get("carrure", 1)
    for s in (-1, 1):
        x = s * 0.5 * c
        # grosses bottes à bout renforcé
        n.forme("Corps", "Bottes", bm_loft([(0.12, 0.46, 0.6, x, -0.16), (0.42, 0.47, 0.56, x, -0.1),
                                            (0.68, 0.44, 0.46, x, -0.02), (0.82, 0.44, 0.44, x, 0)], seg=18), subdiv=2)
        n.sphere("Corps", "Bottes", (x, 0.3, -0.58), (0.44, 0.3, 0.38))
        n.sphere("Corps", "Acier", (x, 0.3, -0.72), (0.36, 0.24, 0.24), subdiv=1)
        n.forme("Corps", "Semelle", bm_loft([(0.0, 0.5, 0.64, x, -0.2), (0.14, 0.51, 0.65, x, -0.2)], seg=20),
                biseau=0.03, segments=2)
        n.forme("Corps", "Revers", bm_loft([(0.74, 0.5, 0.5, x, 0), (0.96, 0.52, 0.52, x, 0)], seg=18), subdiv=1)
        for y in (0.42, 0.6):  # lacets
            n.forme("Corps", "Cuir", bm_tore(T((x, y, -0.02)), R=0.47, rz=0.5, r=0.03, seg=18, segp=5))
        if not o.get("jupe"):
            n.membre("Corps", "Bas", [((x, 0.85, 0), 0.42), ((x * 1.02, 1.25, -0.02), 0.46), ((x * 0.85, 1.6, 0), 0.52)])
    if o.get("jupe"):
        n.forme("Corps", "Bas", bm_loft([(0.55, 1.3 * c, 1.1), (0.6, 1.32 * c, 1.12), (1.1, 1.22 * c, 1.0),
                                          (1.6, 1.08 * c, 0.86), (1.9, 1.0 * c, 0.76)], seg=28), subdiv=1)
        n.forme("Corps", "HautSombre", bm_tore(T((0, 0.6, 0)), R=1.32 * c, rz=1.12, r=0.05, seg=32, segp=6))


def buste(n):
    o = n.o
    c = o.get("carrure", 1)
    femme = o.get("femme", False)
    pr = profil_torse(c, femme)
    n.forme("Buste", "Haut", bm_loft(pr, seg=24), subdiv=2)
    # tunique ou manteau qui descend sur les cuisses
    bas_tunique = 0.75 if o.get("manteau") else 1.1
    if not o.get("jupe"):
        n.forme("Buste", "Haut", bm_loft([(bas_tunique, 1.26 * c, 0.96), (1.5, 1.16 * c, 0.86), (1.85, 1.15 * c, 0.85)],
                                         seg=24, bas=False, haut=False), subdiv=1, epaisseur=-0.06)
        n.forme("Buste", "HautSombre", bm_tore(T((0, bas_tunique + 0.02, 0)), R=1.26 * c, rz=0.96, r=0.05, seg=32, segp=6))
    if o.get("manteau"):  # boutons dorés
        for y in (1.2, 1.6, 2.0, 2.4, 2.8):
            rx, rz = rayon(pr, max(y, 1.45))
            n.sphere("Buste", "Boucle", (0, y, -rz - (0.12 if y < 1.45 else 0.02)), (0.07, 0.07, 0.04), subdiv=0, u=10, v=6)
    n.forme("Buste", "HautSombre", bm_tore(T((0, 3.34, -0.02)), R=0.5 * c, rz=0.42, r=0.1, seg=24, segp=8))

    # ceinture large, boucle dorée, rivets, bourses
    rx, rz = rayon(pr, 1.95)
    n.forme("Buste", "Ceinture", bm_loft([(1.8, rx + 0.04, rz + 0.04), (2.1, rx + 0.05, rz + 0.05)], seg=32,
                                         bas=False, haut=False), epaisseur=-0.06)
    n.forme("Buste", "Boucle", bm_cube(T((0, 1.95, -rz - 0.12), echelle=(0.46, 0.4, 0.08))), biseau=0.04)
    n.forme("Buste", "Cuir", bm_cube(T((0, 1.95, -rz - 0.16), echelle=(0.26, 0.2, 0.06))), biseau=0.02)
    for k in range(10):
        a = math.pi * (0.25 + 0.5 * k / 9) + math.pi
        n.sphere("Buste", "Acier", ((rx + 0.1) * math.cos(a), 1.95, (rz + 0.1) * math.sin(a)), (0.045, 0.045, 0.045),
                 subdiv=0, u=8, v=5)
    for s in (-1, 1):
        n.sphere("Buste", "Cuir", (s * (rx + 0.05), 1.6, -0.25), (0.2, 0.28, 0.22))
        n.forme("Buste", "Cuir", bm_cube(T((s * (rx + 0.08), 1.82, -0.28), echelle=(0.32, 0.08, 0.3))), biseau=0.03)

    # bras épais, mains fortes
    ep = 1.18 * c if not femme else 1.04 * c
    for s in (-1, 1):
        epaule, coude, poignet = (s * (ep - 0.12), 3.12, 0), (s * (ep + 0.22), 2.3, 0.05), (s * (ep + 0.3), 1.58, -0.05)
        r1, r2, r3 = 0.42 * c, 0.37 * c, 0.33 * c
        n.sphere("Buste", "Haut", (s * (ep - 0.2), 3.1, 0), (0.46 * c, 0.42, 0.5 * c))
        if o.get("manchesCourtes"):
            mi = (s * (ep + 0.05), 2.72, 0.02)
            n.membre("Buste", "Haut", [(epaule, r1 + 0.03), (mi, r1)])
            n.membre("Buste", "Peau", [((s * (ep + 0.04), 2.78, 0.02), r2 + 0.03), (coude, r2 + 0.04),
                                       ((s * (ep + 0.27), 1.95, -0.02), r2 + 0.05), (poignet, r3)])
        else:
            n.membre("Buste", "Haut", [(epaule, r1), (coude, r2), (poignet, r3)])
            n.forme("Buste", "HautSombre", bm_tore(T(poignet, (0, 0, -s * 0.12)), R=r3 + 0.03, r=0.08, seg=16, segp=6))
        if o.get("bracelets"):  # brassards de cuir cerclés d'acier
            m = Vector(coude).lerp(Vector(poignet), 0.55)
            n.forme("Buste", "Cuir", bm_loft([(m.y - 0.28, r3 + 0.025, r3 + 0.025, m.x, m.z), (m.y + 0.28, r2 + 0.02, r2 + 0.02, m.x, m.z)],
                                             seg=16, bas=False, haut=False), epaisseur=-0.05, subdiv=1)
            for dy in (-0.22, 0.22):
                n.forme("Buste", "Acier", bm_tore(T((m.x, m.y + dy, m.z)), R=r3 + 0.05, r=0.03, seg=16, segp=5))
        main = Vector((s * (ep + 0.34), 1.3, -0.1))
        n.sphere("Buste", "Peau", main, (0.3 * c, 0.33, 0.32))
        for k in range(4):  # doigts repliés
            n.sphere("Buste", "Peau", (main.x + s * 0.02 - s * 0.0, 1.18 - 0.02 * k, main.z - 0.2 + 0.13 * k),
                     (0.11, 0.12, 0.08), subdiv=0, u=10, v=6)
        n.membre("Buste", "Peau", [((main.x - s * 0.14, 1.42, -0.32), 0.09), ((main.x - s * 0.16, 1.28, -0.42), 0.08)], 1)

    if o.get("epauliere"):  # épaulière de cuir rivetée
        n.forme("Buste", "Cuir", bm_sphere(T((ep - 0.15, 3.25, 0), (0, 0, -0.35), (0.6, 0.32, 0.62)), 20, 10), subdiv=1)
        for a in range(5):
            t = -1 + a * 0.5
            n.sphere("Buste", "Acier", (ep - 0.15 + 0.45 * math.cos(t) * 0.8, 3.38 - 0.1 * abs(t), 0.5 * math.sin(t) - 0.0),
                     (0.05, 0.05, 0.05), subdiv=0, u=8, v=5)

    if o.get("tablier"):
        tablier(n, pr, c, o.get("jupe"))
    outil(n, o.get("outil"), ep)


def tablier(n, pr, c, long):
    bm = bmesh.new()
    bas = 0.55 if long else 0.75
    ys = [bas + i * (3.05 - bas) / 15 for i in range(16)]
    cols = 9
    lignes = []
    for y in ys:
        demi = 0.95 * c if y < 2.35 else 0.62 * c
        rx, rz = rayon(pr, max(y, 1.45))
        ligne = []
        for i in range(cols):
            x = -demi + 2 * demi * i / (cols - 1)
            u = min(abs(x) / (rx * 0.98), 0.98)
            z = -rz * math.sqrt(1 - u * u) - 0.08
            if 1.75 < y < 2.15:
                z -= 0.12  # par-dessus la ceinture
            if y < 1.75:
                z = min(z, -rz * math.sqrt(1 - u * u) - 0.2) - (1.75 - y) * 0.08
            ligne.append(bm.verts.new((x, y, z)))
        lignes.append(ligne)
    for a, b in zip(lignes, lignes[1:]):
        for i in range(cols - 1):
            bm.faces.new((a[i], b[i], b[i + 1], a[i + 1]))
    n.forme("Buste", "Tablier", bm, subdiv=1, epaisseur=-0.06)
    rx, rz = rayon(pr, 1.45)
    n.forme("Buste", "TablierSombre", bm_cube(T((0, 1.2, -rz - 0.45), echelle=(0.95 * c, 0.5, 0.06))), biseau=0.03)
    for s in (-1, 1):
        n.membre("Buste", "Tablier", [((s * 0.55 * c, 3.0, -0.72), 0.05), ((s * 0.58 * c, 3.36, -0.35), 0.05),
                                      ((s * 0.58 * c, 3.36, 0.3), 0.05), ((s * 0.5 * c, 2.8, 0.78), 0.05)], 1)


def outil(n, genre, ep):
    droite = Vector((ep + 0.34, 1.3, -0.1))
    gauche = Vector((-(ep + 0.34), 1.3, -0.1))
    if genre == "marteau":  # gros marteau de forge
        x, z = droite.x, droite.z - 0.08
        n.forme("Buste", "Bois", bm_loft([(0.35, 0.08, 0.08, x, z), (1.75, 0.09, 0.09, x, z)], seg=10), subdiv=1)
        n.forme("Buste", "Cuir", bm_loft([(1.45, 0.11, 0.11, x, z), (1.72, 0.11, 0.11, x, z)], seg=10))
        n.forme("Buste", "Metal", bm_cube(T((x, 0.42, z), echelle=(0.42, 0.4, 0.95))), biseau=0.07)
        n.forme("Buste", "Acier", bm_cube(T((x, 0.42, z - 0.5), echelle=(0.46, 0.44, 0.08))), biseau=0.02)
    elif genre == "pioche":
        x, z = droite.x, droite.z - 0.08
        n.forme("Buste", "Bois", bm_loft([(0.05, 0.08, 0.08, x, z), (3.1, 0.09, 0.09, x, z)], seg=10), subdiv=1)
        n.membre("Buste", "Metal", [((x, 2.72, z - 1.1), 0.03), ((x, 2.98, z - 0.6), 0.09), ((x, 3.08, z), 0.15),
                                    ((x, 2.98, z + 0.55), 0.09), ((x, 2.75, z + 1.0), 0.03)], 2)
        n.forme("Buste", "Cuir", bm_loft([(1.15, 0.11, 0.11, x, z), (1.5, 0.11, 0.11, x, z)], seg=10))
    elif genre == "chope":
        x, z = droite.x - 0.05, droite.z - 0.45
        n.forme("Buste", "Bois", bm_loft([(1.2, 0.3, 0.3, x, z), (1.95, 0.32, 0.32, x, z)], seg=20), subdiv=1)
        for y in (1.32, 1.82):
            n.forme("Buste", "Metal", bm_tore(T((x, y, z)), R=0.32, r=0.035, seg=20, segp=6))
        n.sphere("Buste", "Mousse", (x, 1.98, z), (0.33, 0.14, 0.33))
        n.sphere("Buste", "Mousse", (x + 0.12, 2.06, z - 0.05), (0.15, 0.1, 0.15))
        n.membre("Buste", "Bois", [((x + 0.3, 1.8, z), 0.05), ((x + 0.48, 1.64, z), 0.05),
                                   ((x + 0.48, 1.46, z), 0.05), ((x + 0.3, 1.34, z), 0.05)], 1)
    elif genre == "registre":
        x = gauche.x + 0.15
        rot = (0.3, 0, 0)
        n.forme("Buste", "Couverture", bm_cube(T((x, 1.7, -0.55), rot, (0.9, 1.15, 0.26))), biseau=0.03)
        n.forme("Buste", "Pages", bm_cube(T((x + 0.04, 1.7, -0.55), rot, (0.86, 1.09, 0.22))), biseau=0.01)
        n.forme("Buste", "Boucle", bm_cube(T((x - 0.45, 1.7, -0.55), rot, (0.06, 0.3, 0.3))))


def tete(n):
    o = n.o
    t = TETE
    femme = o.get("femme", False)
    bm = bm_sphere(T(t, echelle=(0.64, 0.7, 0.66)), 32, 18)
    for v in bm.verts:
        ry = (v.co.y - t.y) / 0.7
        if ry < -0.1:
            k = 1 - (0.12 if femme else 0.05) * min(1, (-ry - 0.1) / 0.9)
            v.co.x *= k
    n.forme("Tete", "Peau", bm, subdiv=1)
    for s in (-1, 1):
        n.sphere("Tete", "Peau", (s * 0.64, 3.88, 0.04), (0.1, 0.2, 0.15), rot=(0, s * 0.35, 0))
        n.sphere("Tete", "Joues", (s * 0.33, 3.74, -0.47), (0.17, 0.15, 0.12))
        n.sphere("Tete", "Yeux", (s * 0.23, 3.97, -0.54), (0.12, 0.11, 0.08), subdiv=1, u=16, v=10)
        n.sphere("Tete", "Pupilles", (s * 0.23, 3.96, -0.61), (0.065, 0.07, 0.04), subdiv=0, u=12, v=8)
        # paupière supérieure (regard bienveillant)
        n.sphere("Tete", "Peau", (s * 0.23, 4.03, -0.55), (0.13, 0.06, 0.09), subdiv=0, u=14, v=8)
        epais = 0.05 if femme else 0.085
        n.membre("Tete", "Sourcils", [((s * 0.09, 4.12, -0.61), epais), ((s * 0.24, 4.17, -0.58), epais + 0.01),
                                      ((s * 0.4, 4.12, -0.48), epais * 0.7)], 1)
    # gros nez de nain (sert aussi au jeu pour savoir où regarde le PNJ)
    n.membre("Tete", "Nez", [((0, 4.02, -0.6), 0.07), ((0, 3.88, -0.72), 0.12), ((0, 3.78, -0.74), 0.15)])
    for s in (-1, 1):
        n.sphere("Tete", "Nez", (s * 0.1, 3.76, -0.68), (0.08, 0.07, 0.07), subdiv=0, u=10, v=6)
    n.membre("Tete", "Bouche", [((-0.15, 3.6, -0.56), 0.03), ((0, 3.57, -0.6), 0.04), ((0.15, 3.6, -0.56), 0.03)], 1)

    cheveux(n, o.get("coiffure"))
    barbe(n, o.get("barbe"))
    if o.get("chapeau"):
        n.forme("Tete", "Chapeau", bm_loft([(4.36, 1.2, 1.14), (4.42, 1.22, 1.16), (4.47, 0.82, 0.8)], seg=32), subdiv=1)
        n.forme("Tete", "Chapeau", bm_loft([(4.38, 0.76, 0.74), (4.95, 0.7, 0.68), (5.12, 0.6, 0.58), (5.2, 0.28, 0.26)],
                                           seg=28), subdiv=1)
        n.forme("Tete", "Ruban", bm_loft([(4.44, 0.78, 0.76), (4.62, 0.77, 0.75)], seg=28, bas=False, haut=False),
                epaisseur=-0.03)
        n.sphere("Tete", "Boucle", (0.55, 4.53, -0.5), (0.08, 0.1, 0.03), subdiv=0)
    if o.get("lunettes"):  # binocles de marchand
        for s in (-1, 1):
            n.forme("Tete", "Acier", bm_tore(T((s * 0.23, 3.96, -0.68), (math.pi / 2, 0, 0)), R=0.14, r=0.02, seg=18, segp=5))
            n.forme("Tete", "Verre", bm_loft([(-0.005, 0.13, 0.13), (0.005, 0.13, 0.13)], seg=16,
                                             M=T((s * 0.23, 3.96, -0.68), (math.pi / 2, 0, 0))))
        n.membre("Tete", "Acier", [((-0.09, 3.98, -0.7), 0.018), ((0.09, 3.98, -0.7), 0.018)], 0)
    if o.get("lunettesAtelier"):  # lunettes d'atelier relevées sur le front
        for s in (-1, 1):
            m = T((s * 0.24, 4.38, -0.5), (math.pi / 2 - 0.6, 0, 0))
            n.forme("Tete", "Acier", bm_loft([(-0.08, 0.16, 0.16), (0.08, 0.15, 0.15)], seg=18, M=m), biseau=0.02)
            n.forme("Tete", "Verre", bm_loft([(0.08, 0.13, 0.13), (0.1, 0.13, 0.13)], seg=16, M=m))
        n.forme("Tete", "Cuir", bm_tore(T((0, 4.2, 0.04), (-0.35, 0, 0)), R=0.6, rz=0.62, r=0.05, seg=32, segp=6))


def cheveux(n, style):
    o = n.o
    base = style in ("tresses", "chignon")
    if base:  # calotte complète
        bm = bm_sphere(T((0, 3.93, 0.03), echelle=(0.69, 0.75, 0.71)), 32, 18)
        mort = []
        for v in bm.verts:
            uy = (v.co.y - 3.93) / 0.75
            uz = (v.co.z - 0.03) / 0.71
            ux = v.co.x / 0.69
            lim = 0.05 - 0.55 * uz
            if abs(ux) > 0.75 and uz < 0.3:
                lim = max(lim, 0.08)
            if uy < lim:
                mort.append(v)
        bmesh.ops.delete(bm, geom=mort, context='VERTS')
        n.forme("Tete", "Cheveux", bm, subdiv=1, epaisseur=0.07)
        # raie au milieu : deux mèches bombées
        for s in (-1, 1):
            n.sphere("Tete", "Cheveux", (s * 0.3, 4.38, -0.42), (0.34, 0.16, 0.24), rot=(0.5, 0, -s * 0.4))
    if style == "tresses":
        for s in (-1, 1):
            n.tresse("Tete", "Cheveux", (s * 0.6, 3.75, 0.05), (s * 0.82, 2.55, -0.45), 0.17, n=8, anneau="Acier")
    elif style == "chignon":
        n.sphere("Tete", "Cheveux", (0, 4.3, 0.55), (0.34, 0.32, 0.32))
        n.forme("Tete", "Acier", bm_tore(T((0, 4.2, 0.42), (0.9, 0, 0)), R=0.22, r=0.04, seg=16, segp=6))
    elif style == "couronne":  # crâne dégarni, couronne de cheveux
        n.forme("Tete", "Cheveux", bm_tore(T((0, 3.78, 0.08), (0.2, 0, 0)), R=0.62, rz=0.66, r=0.15,
                                           seg=28, segp=8, arc=math.pi * 1.3), subdiv=1)
    if o.get("foulard"):  # fichu noué sur la tête
        bm = bm_sphere(T((0, 4.0, 0.06), echelle=(0.73, 0.76, 0.75)), 28, 16)
        mort = [v for v in bm.verts if (v.co.y - 4.0) / 0.76 < 0.15 - 0.45 * ((v.co.z - 0.06) / 0.75)]
        bmesh.ops.delete(bm, geom=mort, context='VERTS')
        n.forme("Tete", "Foulard", bm, subdiv=1, epaisseur=0.06)
        n.sphere("Tete", "Foulard", (0, 3.86, 0.72), (0.14, 0.12, 0.12))
        for s in (-1, 1):
            n.membre("Tete", "Foulard", [((0, 3.86, 0.74), 0.07), ((s * 0.18, 3.55, 0.82), 0.06), ((s * 0.22, 3.35, 0.8), 0.03)])


def barbe(n, style):
    if not style:
        return
    # barbe pleine qui couvre joues et menton
    bm = bm_sphere(T((0, 3.82, -0.03), echelle=(0.7, 0.74, 0.71)), 32, 18)
    mort = []
    for v in bm.verts:
        ux = v.co.x / 0.7
        uy = (v.co.y - 3.82) / 0.74
        uz = (v.co.z + 0.03) / 0.71
        garde = uz < 0.35 and (uy < -0.3 or (abs(ux) > 0.78 and uy < 0.05))
        if not garde:
            mort.append(v)
    bmesh.ops.delete(bm, geom=mort, context='VERTS')
    n.forme("Tete", "Barbe", bm, subdiv=1, epaisseur=-0.14)
    # moustache fournie
    n.membre("Tete", "Barbe", [((-0.46, 3.5, -0.45), 0.06), ((-0.3, 3.62, -0.6), 0.1), ((-0.1, 3.68, -0.7), 0.11),
                               ((0, 3.68, -0.72), 0.1), ((0.1, 3.68, -0.7), 0.11), ((0.3, 3.62, -0.6), 0.1),
                               ((0.46, 3.5, -0.45), 0.06)])
    if style == "soignee":  # barbe taillée en pointe
        n.forme("Tete", "Barbe", bm_loft([(3.5, 0.55, 0.36, 0, -0.42), (3.15, 0.48, 0.34, 0, -0.55),
                                          (2.85, 0.3, 0.24, 0, -0.62), (2.65, 0.08, 0.08, 0, -0.64)], seg=18), subdiv=2)
    elif style == "tressee":  # énorme barbe de forgeron avec trois tresses
        n.forme("Tete", "Barbe", bm_loft([(3.55, 0.66, 0.42, 0, -0.45), (3.1, 0.7, 0.42, 0, -0.85),
                                          (2.6, 0.6, 0.34, 0, -1.12), (2.3, 0.4, 0.24, 0, -1.22)], seg=20), subdiv=2)
        for x in (-0.32, 0.0, 0.32):
            n.tresse("Tete", "Barbe", (x, 2.4, -1.26 - (0.05 if x == 0 else 0)), (x * 1.2, 1.5, -1.3), 0.15, n=6)


def construire():
    vider()
    tous = []
    for i, (nom, o) in enumerate(NAINS.items()):
        nain = Nain(nom, o, decal=(i * 4.0, 0, 0))
        jambes(nain)
        buste(nain)
        tete(nain)
        tous += nain.finir()
    for o in tous:
        if triangles(o) > 2900:
            print("  gros", o.name, triangles(o))
    print("OBJETS", len(tous), "TRIANGLES", sum(triangles(o) for o in tous))
    exporter_fbx("Nains.fbx", tous)
    rendu("nains_face.png", direction=(-0.3, -1, 0.12))
    rendu("nains_dos.png", direction=(0.5, 1, 0.25), largeur=1400, hauteur=800)
    tetes = [o for o in tous if "_Tete_" in o.name]
    rendu("nains_tetes.png", direction=(-0.25, -1, 0.05), objets=tetes, largeur=1600, hauteur=700)


construire()
