"""PNJ du village modélisés en 3D (formes organiques lissées).
Chaque PNJ est découpé en objets « Nom_Groupe_Teinte » :
    Groupe = Corps | Buste | Tete (le client anime Buste = respiration, Tete = regard)
    Teinte = Peau, Haut, Bas, ... : la couleur est appliquée par le jeu (tenue dans Village.lua)
Repère L : x = droite du perso, y = haut (pieds à 0, centre de la tête à ~6.15), -z = devant.
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import math
import bmesh
from mathutils import Vector
from commun import *

# Couleurs d'aperçu seulement (le jeu recolore selon la tenue de Village.lua)
APERCU = {
    "Gaspard": dict(Haut=(120, 40, 36), Bas=(60, 50, 44), Peau=(232, 190, 160), Cheveux=(150, 146, 140),
                    Barbe=(170, 166, 160), Chapeau=(70, 50, 36)),
    "Liesel": dict(Haut=(70, 96, 120), Bas=(64, 56, 48), Peau=(240, 202, 176), Cheveux=(176, 82, 40),
                   Tablier=(96, 66, 44)),
    "Brom": dict(Haut=(90, 70, 58), Bas=(48, 42, 38), Peau=(196, 150, 118), Cheveux=(150, 70, 36),
                 Barbe=(150, 70, 36), Tablier=(70, 46, 30)),
    "Margot": dict(Haut=(150, 110, 60), Bas=(80, 50, 60), Peau=(222, 176, 140), Cheveux=(92, 56, 34),
                   Tablier=(230, 220, 200)),
}
COMMUN = dict(Bottes=(56, 38, 28), Revers=(42, 28, 22), Semelle=(30, 22, 18), Ceinture=(62, 42, 30),
              Boucle=(214, 170, 70), Yeux=(244, 240, 232), Pupilles=(46, 34, 24), Bouche=(126, 62, 56),
              Bois=(110, 76, 48), Metal=(150, 154, 162), Couverture=(120, 36, 32), Pages=(236, 224, 196),
              Mousse=(246, 236, 210), Ruban=(40, 30, 24), Nez=None, Sourcils=None, HautSombre=None,
              TablierSombre=None)

PNJS = {
    "Gaspard": dict(coiffure="court", chapeau=True, barbe=True, outil="registre", carrure=1.0),
    "Liesel": dict(coiffure="chignon", tablier=True, outil="pioche", carrure=0.92, femme=True),
    "Brom": dict(coiffure="chauve", barbe=True, barbeLongue=True, tablier=True, manchesCourtes=True,
                 outil="marteau", carrure=1.16),
    "Margot": dict(coiffure="long", tablier=True, outil="chope", carrure=0.92, femme=True, jupe=True),
}

TETE = Vector((0, 6.15, 0))


def sombre(c, k=0.3):
    return tuple(int(v * (1 - k)) for v in c)


class Perso:
    def __init__(self, nom, o, decal):
        self.nom, self.o, self.decal = nom, o, decal
        cols = dict(COMMUN)
        cols.update(APERCU[nom])
        cols["Nez"] = cols["Peau"]
        cols["Sourcils"] = cols.get("Barbe", cols["Cheveux"])
        cols["HautSombre"] = sombre(cols["Haut"])
        cols["TablierSombre"] = sombre(cols.get("Tablier", (80, 60, 40)), 0.18)
        cols["Barbe"] = cols.get("Barbe", cols["Cheveux"])
        cols["Chapeau"] = cols.get("Chapeau", (70, 50, 36))
        cols["Tablier"] = cols.get("Tablier", (80, 60, 40))
        self.cols = cols
        self.pieces = {}

    def mat(self, teinte):
        rug = {"Metal": 0.35, "Boucle": 0.3, "Yeux": 0.3, "Pupilles": 0.2}.get(teinte, 0.8)
        met = 1.0 if teinte in ("Metal", "Boucle") else 0.0
        return materiau(f"{self.nom}_{teinte}", self.cols[teinte], rug, met)

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

    def finir(self):
        res = []
        for (groupe, teinte), objs in self.pieces.items():
            ob = fusionner(objs, f"{self.nom}_{groupe}_{teinte}")
            ob.data.materials.clear()
            ob.data.materials.append(self.mat(teinte))
            decimer(ob, 2500)
            lisse(ob, angle=None if teinte not in ("Metal", "Boucle", "Couverture", "Pages", "Semelle") else 50)
            centrer_origine(ob)
            res.append(ob)
        return res


# ---------------- morceaux ----------------

def torse_profil(c, femme):
    """Anneaux (y, rx, rz) du torse."""
    if femme:
        a = [(2.95, 0.92, 0.56), (3.45, 0.84, 0.52), (3.95, 0.86, 0.54), (4.45, 0.96, 0.6),
             (4.95, 1.0, 0.55), (5.22, 0.76, 0.44), (5.34, 0.36, 0.3)]
    else:
        a = [(2.95, 0.94, 0.56), (3.5, 0.93, 0.56), (4.0, 0.98, 0.58), (4.5, 1.08, 0.6),
             (4.98, 1.07, 0.56), (5.24, 0.8, 0.46), (5.36, 0.38, 0.32)]
    return [(y, rx * c, rz * (1 + (c - 1) * 0.6)) for (y, rx, rz) in a]


def rayon_torse(profil, y):
    if y <= profil[0][0]:
        return profil[0][1], profil[0][2]
    for (y0, rx0, rz0), (y1, rx1, rz1) in zip(profil, profil[1:]):
        if y0 <= y <= y1:
            t = (y - y0) / (y1 - y0)
            return rx0 + (rx1 - rx0) * t, rz0 + (rz1 - rz0) * t
    return profil[-1][1], profil[-1][2]


def jambes(p):
    o = p.o
    for s in (-1, 1):
        x = s * 0.47
        # bottes à bout arrondi, semelle et revers
        p.forme("Corps", "Bottes", bm_loft([(0.12, 0.42, 0.5, x, -0.12), (0.5, 0.43, 0.48, x, -0.08),
                                             (0.8, 0.4, 0.42, x, -0.02), (1.02, 0.4, 0.4, x, 0)], seg=16), subdiv=2)
        p.forme("Corps", "Bottes", bm_sphere(T((x, 0.36, -0.5), echelle=(0.4, 0.3, 0.36))), subdiv=1)
        p.forme("Corps", "Semelle", bm_loft([(0.0, 0.44, 0.56, x, -0.14), (0.13, 0.45, 0.57, x, -0.14)], seg=20), biseau=0.03, segments=2)
        p.forme("Corps", "Revers", bm_tore(T((x, 1.02, 0)), R=0.41, r=0.075, seg=20, segp=8))
        if not o.get("jupe"):
            p.membre("Corps", "Bas", [((x, 1.0, 0.0), 0.36), ((x * 1.02, 1.9, -0.05), 0.39),
                                       ((x, 2.6, 0.0), 0.46), ((x * 0.8, 3.0, 0.0), 0.48)])
    if o.get("jupe"):
        p.forme("Corps", "Bas", bm_loft([(1.25, 1.3, 0.95), (1.32, 1.32, 0.97), (1.9, 1.2, 0.86), (2.5, 1.06, 0.72),
                                          (3.05, 0.95, 0.6), (3.2, 0.9, 0.56)], seg=24), subdiv=1)
        for s in (-1, 1):
            p.membre("Corps", "Bas", [((s * 0.47, 1.0, 0.0), 0.33), ((s * 0.47, 1.5, 0.0), 0.36)])
    else:
        p.forme("Corps", "Bas", bm_cube(T((0, 2.95, 0), echelle=(1.84, 0.6, 1.0))), biseau=0.24, subdiv=1)
    # ceinture, boucle, bourse
    c = o.get("carrure", 1)
    rz = 0.58 * (1 + (c - 1) * 0.6)
    p.forme("Corps", "Ceinture", bm_tore(T((0, 3.1, 0)), R=0.95 * c + 0.02, rz=rz + 0.02, r=0.12, seg=32, segp=8))
    p.forme("Corps", "Boucle", bm_cube(T((0, 3.1, -rz - 0.12), echelle=(0.36, 0.3, 0.08))), biseau=0.03)
    p.forme("Corps", "Ceinture", bm_sphere(T((0.92 * c, 2.75, -0.3), echelle=(0.22, 0.27, 0.18))), subdiv=1)
    p.forme("Corps", "Ceinture", bm_sphere(T((0.92 * c, 3.0, -0.3), echelle=(0.12, 0.08, 0.1)), 12, 8))


def buste(p):
    o = p.o
    c = o.get("carrure", 1)
    femme = o.get("femme", False)
    profil = torse_profil(c, femme)
    p.forme("Buste", "Haut", bm_loft(profil, seg=24), subdiv=2)

    p.forme("Buste", "HautSombre", bm_tore(T((0, 5.28, -0.02)), R=0.46 * c, rz=0.38, r=0.09, seg=24, segp=8))
    p.forme("Buste", "Peau", bm_loft([(5.2, 0.27, 0.26), (5.7, 0.25, 0.25)], seg=16), subdiv=1)

    ep = 1.08 * c if not femme else 0.98
    for s in (-1, 1):
        epaule = (s * (ep - 0.1), 4.96, 0.0)
        coude = (s * (ep + 0.1), 3.9, 0.04)
        poignet = (s * (ep + 0.18), 2.98, -0.04)
        # épaule arrondie qui raccorde le bras au torse
        p.forme("Buste", "Haut", bm_sphere(T((s * (ep - 0.16), 4.94, 0.0), echelle=(0.4 * c, 0.37, 0.45 * c))), subdiv=1)
        r_ep, r_co, r_po = 0.4 * c, 0.33 * c, 0.27 * c
        if o.get("manchesCourtes"):
            mi = (s * (ep - 0.02), 4.4, 0.02)
            p.membre("Buste", "Haut", [(epaule, r_ep + 0.02), (mi, r_ep - 0.01)])
            p.membre("Buste", "Peau", [((s * (ep - 0.03), 4.45, 0.02), r_co + 0.03), (coude, r_co + 0.02),
                                       ((s * (ep + 0.15), 3.4, -0.0), r_co + 0.05), (poignet, r_po + 0.01)])
        else:
            p.membre("Buste", "Haut", [(epaule, r_ep), (coude, r_co), (poignet, r_po)])
            p.forme("Buste", "HautSombre", bm_tore(T(poignet, (0, 0, -s * 0.1)), R=r_po + 0.02, r=0.07, seg=16, segp=6))
        main = Vector((s * (ep + 0.22), 2.64, -0.08))
        p.forme("Buste", "Peau", bm_sphere(T(main, echelle=(0.27 * c, 0.33, 0.3))), subdiv=1)
        p.membre("Buste", "Peau", [((main.x - s * 0.1, 2.75, -0.3), 0.08), ((main.x - s * 0.14, 2.6, -0.38), 0.07)], 1)

    if o.get("tablier"):
        tablier(p, profil, c)
    outil(p, o.get("outil"), ep)


def tablier(p, profil, c):
    """Tablier qui épouse le torse puis tombe droit sous la ceinture."""
    bm = bmesh.new()
    lignes = []
    ys = [2.0 + i * 0.2 for i in range(14)]  # 2.0 -> 4.6
    cols = 9
    for y in ys:
        demi = 0.82 * c if y < 3.75 else 0.5 * c
        rx, rz = rayon_torse(profil, max(y, 3.0))
        ligne = []
        for i in range(cols):
            x = -demi + 2 * demi * i / (cols - 1)
            u = min(abs(x) / (rx * 0.98), 0.98)
            z = -rz * math.sqrt(1 - u * u) - 0.07
            if 2.95 < y < 3.3:
                z = min(z, -rz * math.sqrt(1 - u * u) - 0.2)  # passe par-dessus la ceinture
            if y < 3.0:
                z = min(z, -rz * math.sqrt(1 - u * u) - 0.2) - (3.0 - y) * 0.06
            ligne.append(bm.verts.new((x, y, z)))
        lignes.append(ligne)
    for a, b in zip(lignes, lignes[1:]):
        for i in range(cols - 1):
            bm.faces.new((a[i], b[i], b[i + 1], a[i + 1]))
    p.forme("Buste", "Tablier", bm, subdiv=1, epaisseur=-0.06)
    # poche
    rx, rz = rayon_torse(profil, 3.0)
    p.forme("Buste", "TablierSombre", bm_cube(T((0, 2.62, -rz - 0.36), echelle=(0.9 * c, 0.5, 0.06))), biseau=0.03)
    # bretelles par-dessus les épaules
    for s in (-1, 1):
        p.membre("Buste", "Tablier", [((s * 0.46 * c, 4.6, -0.62), 0.05), ((s * 0.52 * c, 5.18, -0.3), 0.05),
                                        ((s * 0.54 * c, 5.2, 0.25), 0.05), ((s * 0.45 * c, 4.6, 0.6), 0.05)], 1)


def outil(p, genre, ep):
    droite = Vector((ep + 0.22, 2.64, -0.08))
    gauche = Vector((-(ep + 0.22), 2.64, -0.08))
    if genre == "marteau":
        x, z = droite.x, droite.z - 0.05
        p.forme("Buste", "Bois", bm_loft([(1.55, 0.07, 0.07, x, z), (3.0, 0.08, 0.08, x, z)], seg=10), subdiv=1)
        p.forme("Buste", "Metal", bm_cube(T((x, 1.62, z), echelle=(0.34, 0.32, 0.78))), biseau=0.06)
        p.forme("Buste", "Metal", bm_loft([(1.5, 0.2, 0.2, x, z - 0.42), (1.74, 0.2, 0.2, x, z - 0.42)], seg=12,
                                          M=None), biseau=0.02)
    elif genre == "pioche":
        x, z = droite.x, droite.z - 0.06
        p.forme("Buste", "Bois", bm_loft([(0.1, 0.08, 0.08, x, z), (4.4, 0.09, 0.09, x, z)], seg=10), subdiv=1)
        p.membre("Buste", "Metal", [((x, 4.02, z - 1.25), 0.03), ((x, 4.3, z - 0.7), 0.09), ((x, 4.42, z), 0.15),
                                    ((x, 4.3, z + 0.65), 0.09), ((x, 4.05, z + 1.15), 0.03)], 2)
    elif genre == "chope":
        x, z = droite.x - 0.05, droite.z - 0.42
        p.forme("Buste", "Bois", bm_loft([(2.55, 0.28, 0.28, x, z), (3.25, 0.3, 0.3, x, z)], seg=20), subdiv=1)
        for y in (2.68, 3.13):
            p.forme("Buste", "Metal", bm_tore(T((x, y, z)), R=0.3, r=0.035, seg=20, segp=6))
        p.forme("Buste", "Mousse", bm_sphere(T((x, 3.28, z), echelle=(0.31, 0.13, 0.31))), subdiv=1)
        p.forme("Buste", "Mousse", bm_sphere(T((x + 0.12, 3.36, z - 0.05), echelle=(0.14, 0.09, 0.14))), subdiv=1)
        p.membre("Buste", "Bois", [((x + 0.28, 3.1, z), 0.05), ((x + 0.45, 2.95, z), 0.05),
                                   ((x + 0.45, 2.78, z), 0.05), ((x + 0.28, 2.68, z), 0.05)], 1)
    elif genre == "registre":
        x = gauche.x + 0.12
        rot = (0.35, 0, 0)
        p.forme("Buste", "Couverture", bm_cube(T((x, 3.0, -0.48), rot, (0.86, 1.12, 0.24))), biseau=0.03)
        p.forme("Buste", "Pages", bm_cube(T((x + 0.04, 3.0, -0.48), rot, (0.82, 1.06, 0.2))), biseau=0.01)


def tete(p):
    o = p.o
    t = TETE
    # crâne + mâchoire affinée
    bm = bm_sphere(T(t, echelle=(0.64, 0.72, 0.66)), 32, 18)
    for v in bm.verts:
        ry = (v.co.y - t.y) / 0.72
        if ry < -0.15:
            k = 1 - 0.22 * min(1, (-ry - 0.15) / 0.85)
            v.co.x *= k
            if v.co.z < 0:
                v.co.z -= 0.04 * min(1, (-ry - 0.15) / 0.85)  # menton
    p.forme("Tete", "Peau", bm, subdiv=1)
    for s in (-1, 1):
        p.forme("Tete", "Peau", bm_sphere(T((s * 0.63, 6.12, 0.04), (0, s * 0.3, 0), (0.09, 0.19, 0.14))), subdiv=1)
        # yeux
        p.forme("Tete", "Yeux", bm_sphere(T((s * 0.24, 6.22, -0.56), echelle=(0.13, 0.12, 0.08)), 16, 10), subdiv=1)
        p.forme("Tete", "Pupilles", bm_sphere(T((s * 0.24, 6.21, -0.63), echelle=(0.07, 0.075, 0.04)), 12, 8))
        # sourcils
        p.membre("Tete", "Sourcils", [((s * 0.1, 6.38, -0.63), 0.045), ((s * 0.24, 6.42, -0.6), 0.05),
                                      ((s * 0.37, 6.39, -0.52), 0.035)], 1)
    # nez (sert aussi au jeu pour savoir où regarde le PNJ)
    p.membre("Tete", "Nez", [((0, 6.24, -0.62), 0.06), ((0, 6.08, -0.72), 0.1), ((0, 6.02, -0.7), 0.09)])
    # bouche en léger sourire
    p.membre("Tete", "Bouche", [((-0.16, 5.89, -0.57), 0.03), ((0, 5.85, -0.62), 0.04), ((0.16, 5.89, -0.57), 0.03)], 1)

    style = o.get("coiffure", "court")
    if style != "chauve":
        bm = bm_sphere(T((0, 6.2, 0.03), echelle=(0.69, 0.77, 0.71)), 32, 18)
        doomed = []
        for v in bm.verts:
            ux = v.co.x / 0.69
            uy = (v.co.y - 6.2) / 0.77
            uz = (v.co.z - 0.03) / 0.71
            limite = -0.05 - 0.55 * uz  # front haut, nuque basse
            if style == "long":
                limite = min(limite, -0.45) if uz > -0.6 else limite
            elif abs(ux) > 0.75 and uz < 0.3:
                limite = max(limite, 0.05)  # dégage les oreilles
            if uy < limite:
                doomed.append(v)
        bmesh.ops.delete(bm, geom=doomed, context='VERTS')
        p.forme("Tete", "Cheveux", bm, subdiv=1, epaisseur=0.07)
        # mèche sur le front
        p.forme("Tete", "Cheveux", bm_sphere(T((0.18, 6.66, -0.48), (0.5, 0, 0.3), (0.32, 0.14, 0.22))), subdiv=1)
    if style == "chignon":
        p.forme("Tete", "Cheveux", bm_sphere(T((0, 6.78, 0.46), echelle=(0.3, 0.28, 0.3))), subdiv=1)
        p.forme("Tete", "HautSombre", bm_tore(T((0, 6.66, 0.36), (0.9, 0, 0)), R=0.2, r=0.05, seg=16, segp=6))
    elif style == "long":
        p.forme("Tete", "Cheveux", bm_cube(T((0, 5.62, 0.42), (-0.08, 0, 0), (1.24, 1.7, 0.36))), biseau=0.16, subdiv=1)
        for s in (-1, 1):
            p.membre("Tete", "Cheveux", [((s * 0.6, 6.1, 0.08), 0.16), ((s * 0.62, 5.6, 0.12), 0.15),
                                         ((s * 0.56, 5.1, 0.16), 0.08)])
    elif style == "chauve":
        p.forme("Tete", "Cheveux", bm_tore(T((0, 6.02, 0.06), (0.25, 0, 0)), R=0.62, rz=0.66, r=0.12,
                                           seg=24, segp=8, arc=math.pi * 1.25), subdiv=1)

    if o.get("barbe"):
        bm = bm_sphere(T((0, 6.12, -0.02), echelle=(0.68, 0.76, 0.7)), 32, 18)
        doomed = []
        for v in bm.verts:
            ux = v.co.x / 0.68
            uy = (v.co.y - 6.12) / 0.76
            uz = (v.co.z + 0.02) / 0.7
            garde = uz < 0.35 and (uy < -0.38 or (abs(ux) > 0.8 and uy < 0.02))
            if not garde:
                doomed.append(v)
        bmesh.ops.delete(bm, geom=doomed, context='VERTS')
        p.forme("Tete", "Barbe", bm, subdiv=1, epaisseur=-0.12)
        p.membre("Tete", "Barbe", [((-0.34, 5.84, -0.54), 0.05), ((-0.14, 5.96, -0.66), 0.08), ((0, 5.97, -0.69), 0.07),
                                   ((0.14, 5.96, -0.66), 0.08), ((0.34, 5.84, -0.54), 0.05)])
        if o.get("barbeLongue"):
            p.forme("Tete", "Barbe", bm_loft([(5.75, 0.5, 0.3, 0, -0.38), (5.3, 0.46, 0.28, 0, -0.46),
                                              (4.9, 0.32, 0.22, 0, -0.5), (4.55, 0.1, 0.08, 0, -0.5)], seg=16), subdiv=2)

    if o.get("chapeau"):
        p.forme("Tete", "Chapeau", bm_loft([(6.6, 1.2, 1.15), (6.66, 1.22, 1.17), (6.7, 0.8, 0.78)], seg=32), subdiv=1)
        p.forme("Tete", "Chapeau", bm_loft([(6.62, 0.74, 0.72), (7.2, 0.7, 0.68), (7.42, 0.62, 0.6),
                                            (7.5, 0.3, 0.28)], seg=28), subdiv=1)
        p.forme("Tete", "Ruban", bm_loft([(6.68, 0.76, 0.74), (6.88, 0.75, 0.73)], seg=28, bas=False, haut=False),
                epaisseur=-0.03)


def construire():
    vider()
    tous = []
    for i, (nom, o) in enumerate(PNJS.items()):
        p = Perso(nom, o, decal=(i * 4.2, 0, 0))
        jambes(p)
        buste(p)
        tete(p)
        tous += p.finir()
    print("OBJETS", len(tous), "TRIANGLES", sum(triangles(o) for o in tous))
    exporter_fbx("PNJ.fbx", tous)
    rendu("pnj_face.png", direction=(-0.35, -1, 0.15))
    rendu("pnj_dos.png", direction=(0.5, 1, 0.25), largeur=1400, hauteur=800)
    # gros plan sur les têtes
    tetes = [o for o in tous if "_Tete_" in o.name]
    rendu("pnj_tetes.png", direction=(-0.3, -1, 0.1), objets=tetes, largeur=1600, hauteur=600)


construire()
