"""Les 4 nains du village (Gaspard, Liesel, Brom, Margot), modélisés en détail.
Silhouette de nain : tête et mains fortes, torse en tonneau, jambes courtes, grosses bottes.
Objets « Nom_Groupe_Teinte » (Groupe = Corps | Buste | Tete) ; le jeu recolore selon la tenue.
Repère L : x = droite du perso, y = haut (pieds à 0), -z = devant.
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import math, random
import bmesh
from mathutils import Vector, Matrix
from commun import *

# Inspirés de la planche « nains ventrus » : Gaspard ← Gromm (le sage à barbe grise),
# Liesel ← Brunhilde (tresses rousses, bandeau), Brom ← Zog (torse nu, bretelles, casque à lampe),
# Margot ← Brolg (chope, casque à cornes, cape de fourrure).
APERCU = {
    "Gaspard": dict(Haut=(92, 70, 50), Bas=(54, 46, 40), Peau=(226, 176, 150), Cheveux=(170, 168, 162),
                    Barbe=(188, 186, 180), Fourrure=(120, 98, 74), Lueur=(90, 180, 255)),
    "Liesel": dict(Haut=(58, 44, 36), Bas=(84, 70, 54), Peau=(240, 196, 170), Cheveux=(178, 70, 30),
                   Lueur=(255, 140, 40)),
    "Brom": dict(Haut=(72, 48, 32), Bas=(74, 60, 46), Peau=(214, 160, 128), Cheveux=(56, 38, 28),
                 Barbe=(62, 42, 30), Lueur=(255, 96, 20)),
    "Margot": dict(Haut=(70, 50, 36), Bas=(76, 58, 42), Peau=(232, 180, 150), Cheveux=(172, 72, 32),
                   Fourrure=(112, 90, 68), Lueur=(255, 196, 70)),
}
# Élément lumineux de chaque nain (matière Neon dans Roblox) : runes bleues de Gaspard, gemme et pioche
# ardentes de Liesel, marteau chauffé au rouge de Brom, gemme d'ambre et chope dorée de Margot.
COMMUN = dict(Bottes=(64, 44, 30), Revers=(46, 32, 24), Semelle=(30, 22, 18), Ceinture=(62, 42, 30),
              Boucle=(214, 170, 70), Yeux=(244, 240, 232), Pupilles=(46, 34, 24), Bouche=(126, 62, 56),
              Bois=(110, 76, 48), Metal=(150, 154, 162), Couverture=(120, 36, 32), Pages=(236, 224, 196),
              Mousse=(246, 236, 210), Ruban=(40, 30, 24), Cuir=(92, 60, 38), Acier=(120, 124, 132),
              Verre=(150, 200, 220), Foulard=(150, 60, 50), Fourrure=(110, 88, 66), Casque=(132, 134, 140),
              Corne=(226, 212, 182), Lampe=(255, 230, 150), Or=(232, 178, 58), Peinture=(52, 104, 168),
              Lueur=(255, 200, 120), Pivot=(255, 0, 255))

NAINS = {
    "Gaspard": dict(coiffure="longs", barbe="longue", torseNu=True, manteauOuvert=True, colFourrure=True,
                    outil="registre", carrure=1.05, bracelets=True, hacheDos=True, peinture=True,
                    runes=True, anneauxOr=True),
    "Liesel": dict(coiffure="tressesLongues", barbe="courte", bandeau=True, torseNu=True, brassiere=True, brasNus=True,
                   outil="pioche", carrure=0.95, femme=True, bracelets=True, epauliere=True, anneauxOr=True),
    "Brom": dict(barbe="tressee", casque="mineur", torseNu=True, brasNus=True, bretelles=True,
                 outil="marteau", carrure=1.15, bracelets=True, epaulieres=True, anneauxOr=True),
    "Margot": dict(coiffure="tressesLongues", casque="cornes", torseNu=True, brassiere=True, cape=True,
                   colFourrure=True, outil="chope", carrure=1.0, femme=True, jupe=True, bracelets=True,
                   epaulieres=True, anneauxOr=True),
}

TETE = Vector((0, 3.85, 0))
ECHELLE_TETE = 0.84
# teinte : (force, taille du grain) du relief appliqué
RELIEF = {"Barbe": (0.07, 0.12), "Cheveux": (0.06, 0.12), "Fourrure": (0.12, 0.18), "Sourcils": (0.03, 0.06)}
_textures = {}


def texture_bruit(taille):
    import bpy
    if taille not in _textures:
        t = bpy.data.textures.new(f"Bruit{taille}", 'CLOUDS')
        t.noise_scale = taille
        t.noise_depth = 2
        _textures[taille] = t
    return _textures[taille]


def sombre(c, k=0.3):
    return tuple(int(v * (1 - k)) for v in c)


class Nain:
    def __init__(self, nom, o, decal):
        self.nom, self.o, self.decal = nom, o, decal
        cols = dict(COMMUN)
        cols.update(APERCU[nom])
        cols["Nez"] = cols["Peau"]
        cols["Joues"] = tuple(int(a * 0.88 + b * 0.12) for a, b in zip(cols["Peau"], (210, 90, 80)))
        cols["Barbe"] = cols.get("Barbe", cols["Cheveux"])
        cols["Sourcils"] = cols["Barbe"]
        cols["HautSombre"] = sombre(cols["Haut"])
        cols["Tablier"] = cols.get("Tablier", (80, 60, 40))
        cols["TablierSombre"] = sombre(cols["Tablier"], 0.18)
        cols["Chapeau"] = cols.get("Chapeau", (70, 50, 36))
        self.cols = cols
        self.pieces = {}

    def mat(self, teinte):
        metal = teinte in ("Metal", "Boucle", "Acier", "Casque")
        m = materiau(f"{self.nom}_{teinte}", self.cols[teinte], 0.35 if metal else 0.8, 1.0 if metal else 0.0)
        if teinte in ("Lueur", "Lampe"):  # brille dans l'aperçu (Neon dans le jeu)
            try:
                bsdf = next(nd for nd in m.node_tree.nodes if nd.type == 'BSDF_PRINCIPLED')
                bsdf.inputs["Emission Color"].default_value = (*lin(self.cols[teinte])[:3], 1)
                bsdf.inputs["Emission Strength"].default_value = 6.0
            except Exception:
                pass
        if teinte in ("Or",):
            try:
                bsdf = next(nd for nd in m.node_tree.nodes if nd.type == 'BSDF_PRINCIPLED')
                bsdf.inputs["Metallic"].default_value = 1.0
                bsdf.inputs["Roughness"].default_value = 0.28
            except Exception:
                pass
        if teinte in ("Peau", "Nez", "Joues"):  # peau : légère diffusion sous la surface (aperçu)
            try:
                bsdf = next(nd for nd in m.node_tree.nodes if nd.type == 'BSDF_PRINCIPLED')
                bsdf.inputs["Subsurface Weight"].default_value = 0.25
                bsdf.inputs["Roughness"].default_value = 0.55
            except Exception:
                pass
        return m

    force = None  # groupe imposé aux pièces « Buste » (segment de bras en cours de construction)

    def ajout(self, groupe, teinte, ob):
        if self.force and groupe == "Buste":
            groupe = self.force
        self.pieces.setdefault((groupe, teinte), []).append(ob)
        return ob

    def pivot(self, groupe, pos):
        """Repère d'articulation invisible (Nom_Groupe_Pivot) : le jeu tourne le groupe autour de ce point."""
        self.forme(groupe, "Pivot", bm_cube(T(pos, echelle=(0.04, 0.04, 0.04))))

    def forme(self, groupe, teinte, bm, subdiv=0, biseau=0.0, epaisseur=0.0, segments=3):
        ob = objet(f"{self.nom}_tmp", bm, self.mat(teinte), decal=self.decal)
        if biseau:
            modif(ob, 'BEVEL', width=biseau, segments=segments, limit_method='NONE')
        if epaisseur:
            modif(ob, 'SOLIDIFY', thickness=epaisseur, offset=-1)
        if subdiv:
            modif(ob, 'SUBSURF', levels=subdiv, render_levels=subdiv)
        if teinte in RELIEF:  # poils, cheveux, fourrure : surface irrégulière, moins « pâte à modeler »
            force, taille = RELIEF[teinte]
            modif(ob, 'DISPLACE', texture=texture_bruit(taille), strength=force, mid_level=0.5)
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
            if anneau == "Acier" and self.o.get("anneauxOr"):
                anneau = "Or"
                m = a.lerp(b, 0.5)
                self.forme(groupe, "Or", bm_tore(T(m), R=rayon * 0.82, r=0.035, seg=14, segp=6))
            self.forme(groupe, anneau, bm_tore(T(b + Vector((0, 0.08, 0))), R=rayon * 0.6, r=0.035, seg=14, segp=6))

    def finir(self):
        res = []
        for (groupe, teinte), objs in self.pieces.items():
            ob = fusionner(objs, f"{self.nom}_{groupe}_{teinte}")
            ob.data.materials.clear()
            ob.data.materials.append(self.mat(teinte))
            if groupe == "Tete":  # tête plus petite par rapport au corps : proportions réalistes
                pivot = Vector((self.decal[0], self.decal[1], 3.3))  # repère Blender (Z en haut) après conversion
                mw, inv = ob.matrix_world, ob.matrix_world.inverted()
                for v in ob.data.vertices:
                    w = mw @ v.co
                    v.co = inv @ (pivot + (w - pivot) * ECHELLE_TETE)
            decimer(ob, 5000 if teinte in RELIEF or teinte == "Peau" else 3000)
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
    nu = o.get("torseNu", False)
    n.forme("Buste", "Peau" if nu else "Haut", bm_loft(pr, seg=24), subdiv=2)
    if nu:
        ventre(n, c)
        if not o.get("jupe"):  # haut du pantalon sous le ventre
            n.forme("Corps", "Bas", bm_loft([(1.05, 1.22 * c, 0.94), (1.5, 1.16 * c, 0.9), (1.75, 1.14 * c, 0.88)],
                                            seg=24, bas=False, haut=False), subdiv=1, epaisseur=-0.06)
    # tunique ou manteau qui descend sur les cuisses
    bas_tunique = 0.75 if o.get("manteau") else 1.1
    if not o.get("jupe") and not nu:
        n.forme("Buste", "Haut", bm_loft([(bas_tunique, 1.26 * c, 0.96), (1.5, 1.16 * c, 0.86), (1.85, 1.15 * c, 0.85)],
                                         seg=24, bas=False, haut=False), subdiv=1, epaisseur=-0.06)
        n.forme("Buste", "HautSombre", bm_tore(T((0, bas_tunique + 0.02, 0)), R=1.26 * c, rz=0.96, r=0.05, seg=32, segp=6))
    if o.get("manteau"):  # boutons dorés
        for y in (1.2, 1.6, 2.0, 2.4, 2.8):
            rx, rz = rayon(pr, max(y, 1.45))
            n.sphere("Buste", "Boucle", (0, y, -rz - (0.12 if y < 1.45 else 0.02)), (0.07, 0.07, 0.04), subdiv=0, u=10, v=6)
    if not nu:
        n.forme("Buste", "HautSombre", bm_tore(T((0, 3.34, -0.02)), R=0.5 * c, rz=0.42, r=0.1, seg=24, segp=8))

    # ceinture large, boucle dorée, rivets, bourses (sous le ventre quand il est nu)
    yc = 1.62 if nu else 1.95
    rx, rz = rayon(pr, yc)
    if nu:
        rx, rz = max(rx, 0.9 * c), max(rz, 1.02 * c)
    n.forme("Buste", "Ceinture", bm_loft([(yc - 0.15, rx + 0.04, rz + 0.04), (yc + 0.15, rx + 0.05, rz + 0.05)], seg=32,
                                         bas=False, haut=False), epaisseur=-0.06)
    n.forme("Buste", "Boucle", bm_cube(T((0, yc, -rz - 0.12), echelle=(0.46, 0.4, 0.08))), biseau=0.04)
    n.forme("Buste", "Cuir", bm_cube(T((0, yc, -rz - 0.16), echelle=(0.26, 0.2, 0.06))), biseau=0.02)
    for k in range(10):
        a = math.pi * (0.25 + 0.5 * k / 9) + math.pi
        n.sphere("Buste", "Acier", ((rx + 0.1) * math.cos(a), yc, (rz + 0.1) * math.sin(a)), (0.045, 0.045, 0.045),
                 subdiv=0, u=8, v=5)
    for s in (-1, 1):
        n.sphere("Buste", "Cuir", (s * (rx + 0.05), yc - 0.35, -0.25), (0.2, 0.28, 0.22))
        n.forme("Buste", "Cuir", bm_cube(T((s * (rx + 0.08), yc - 0.13, -0.28), echelle=(0.32, 0.08, 0.3))), biseau=0.03)

    if o.get("manteauOuvert"):
        manteau_ouvert(n, pr, c)
    if o.get("cape"):
        cape(n, pr, c)
    if o.get("brassiere"):
        brassiere(n, pr, c)
    if o.get("bretelles"):
        bretelles(n, pr, c)
    if o.get("colFourrure"):
        col_fourrure(n, c)
    if o.get("runes"):
        runes(n, pr, c)
    if o.get("hacheDos"):
        hache_dos(n, c)
    if o.get("epaulieres"):
        epaulieres(n, c, 1.18 * c if not femme else 1.04 * c)

    # bras épais, mains fortes
    ep = 1.18 * c if not femme else 1.04 * c
    for s in (-1, 1):
        epaule, coude, poignet = (s * (ep - 0.12), 3.12, 0), (s * (ep + 0.22), 2.3, 0.05), (s * (ep + 0.3), 1.58, -0.05)
        r1, r2, r3 = 0.42 * c, 0.37 * c, 0.33 * c
        cote = "D" if s == 1 else "G"
        matiere = "Peau" if o.get("brasNus") else "Haut"
        # épaule (reste sur le buste : c'est la rotule)
        n.sphere("Buste", matiere, (s * (ep - 0.2), 3.1, 0), (0.46 * c, 0.42, 0.5 * c))
        # bras (épaule -> coude), tourne autour de l'épaule
        n.force = "Bras" + cote
        n.pivot("Buste", epaule)
        n.membre("Buste", matiere, [(epaule, r1 + 0.02), (coude, r2 + 0.03)])
        n.sphere("Buste", matiere, coude, (r2 + 0.03, r2 + 0.03, r2 + 0.03), u=16, v=10)  # rotule du coude
        # avant-bras (coude -> main + objet tenu), tourne autour du coude
        n.force = "AvBras" + cote
        n.pivot("Buste", coude)
        n.membre("Buste", matiere, [(coude, r2 + 0.03), (poignet, r3)])
        if not o.get("brasNus"):
            n.forme("Buste", "HautSombre", bm_tore(T(poignet, (0, 0, -s * 0.12)), R=r3 + 0.03, r=0.08, seg=16, segp=6))
        if o.get("bracelets"):  # brassards de cuir cerclés d'acier
            m = Vector(coude).lerp(Vector(poignet), 0.55)
            n.forme("Buste", "Cuir", bm_loft([(m.y - 0.28, r3 + 0.025, r3 + 0.025, m.x, m.z), (m.y + 0.28, r2 + 0.02, r2 + 0.02, m.x, m.z)],
                                             seg=16, bas=False, haut=False), epaisseur=-0.05, subdiv=1)
            for dy in (-0.22, 0.22):
                n.forme("Buste", "Acier", bm_tore(T((m.x, m.y + dy, m.z)), R=r3 + 0.05, r=0.03, seg=16, segp=5))
        # main (+ objet tenu), tourne autour du poignet
        n.force = "Main" + cote
        n.pivot("Buste", poignet)
        tient = (o.get("outil") in ("marteau", "pioche", "chope") and s == 1) or (o.get("outil") == "registre" and s == -1)
        main_serree(n, s, prise(ep, s), 0.11 if tient else 0.035, c)
        n.force = None

    if o.get("epauliere"):  # épaulière de cuir rivetée, sur l'épaule opposée à l'outil (pas de collision)
        n.forme("Buste", "Cuir", bm_sphere(T((-(ep - 0.15), 3.25, 0), (0, 0, 0.35), (0.6, 0.32, 0.62)), 20, 10), subdiv=1)
        for a in range(5):
            t = -1 + a * 0.5
            n.sphere("Buste", "Acier", (-(ep - 0.15 + 0.45 * math.cos(t) * 0.8), 3.38 - 0.1 * abs(t), 0.5 * math.sin(t) - 0.0),
                     (0.05, 0.05, 0.05), subdiv=0, u=8, v=5)

    if o.get("tablier"):
        tablier(n, pr, c, o.get("jupe"))
    # l'objet tenu suit la main qui le tient
    n.force = "MainG" if o.get("outil") == "registre" else "MainD"
    outil(n, o.get("outil"), ep)
    n.force = None
    n.pivot("Buste", (0, 1.55, 0))  # hanches : le buste s'incline autour de ce point
    if o.get("outil") == "marteau":
        enclume(n, c, ep)


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


VENTRE_Y = 2.2


def ventre_geo(c):
    """Centre et demi-axes du gros ventre rond."""
    return Vector((0, VENTRE_Y, -0.3 * c)), Vector((1.05 * c, 0.95, 0.85 * c))


def ventre(n, c):
    centre, ax = ventre_geo(c)
    n.sphere("Buste", "Peau", centre, tuple(ax), u=28, v=16)
    n.sphere("Buste", "Joues", (0, VENTRE_Y - 0.15, centre.z - ax.z + 0.04), (0.07, 0.05, 0.03), subdiv=0, u=10, v=6)


def devant(pr, c, x, y, marge=0.05):
    """z (vers l'avant, négatif) de la surface du torse ou du ventre au point (x, y)."""
    rx, rz = rayon(pr, max(y, 1.45))
    u = min(abs(x) / max(rx, 0.01), 0.99)
    z = -rz * math.sqrt(1 - u * u)
    centre, ax = ventre_geo(c)
    k = 1 - (x / ax.x) ** 2 - ((y - centre.y) / ax.y) ** 2
    if k > 0:
        z = min(z, centre.z - ax.z * math.sqrt(k))
    return z - marge


def manteau_ouvert(n, pr, c):
    """Manteau long ouvert sur le ventre, bordé de fourrure (Gromm)."""
    anneaux = [(0.62, 1.38 * c, 1.12 * c), (1.2, 1.3 * c, 1.08 * c)]
    for y in (1.6, 2.0, 2.4, 2.8, 3.1, 3.32):
        rx, rz = rayon(pr, y)
        anneaux.append((y, rx + 0.14, rz + 0.16))
    bm = bm_loft(anneaux, seg=32, bas=False, haut=False)
    ouverture = 0.82 * c
    mort = [v for v in bm.verts if v.co.z < 0 and abs(v.co.x) < ouverture]
    bmesh.ops.delete(bm, geom=mort, context='VERTS')
    n.forme("Buste", "Haut", bm, subdiv=1, epaisseur=-0.08)
    for s in (-1, 1):  # bordure de fourrure le long de l'ouverture
        for i in range(11):
            y = 0.7 + i * 0.26
            x = s * (ouverture + 0.08)
            rx, rz = rayon(pr, max(y, 1.45))
            rx, rz = (rx + 0.14, rz + 0.16) if y >= 1.45 else (1.32 * c, 1.08 * c)
            u = min(abs(x) / rx, 0.97)
            z = -rz * math.sqrt(1 - u * u)
            r = 0.17 + 0.04 * ((i * 7) % 3)
            n.sphere("Buste", "Fourrure", (x, y, z), (r, r * 1.2, r * 0.8), rot=(0, 0, 0.4 * s), u=12, v=8)


def cape(n, pr, c):
    """Cape de fourrure qui tombe des épaules dans le dos (Brolg)."""
    bm = bmesh.new()
    lignes = []
    for j in range(14):
        y = 3.35 - j * (2.75 / 13)
        demi = (1.15 + 0.25 * j / 13) * c
        rx, rz = rayon(pr, max(y, 1.45))
        ligne = []
        for i in range(9):
            x = -demi + 2 * demi * i / 8
            u = min(abs(x) / (rx + 0.25), 0.98)
            z = (rz + 0.12) * math.sqrt(1 - u * u) + 0.12 + (3.35 - y) * 0.12
            ligne.append(bm.verts.new((x, y, z)))
        lignes.append(ligne)
    for a, b in zip(lignes, lignes[1:]):
        for i in range(8):
            bm.faces.new((a[i], a[i + 1], b[i + 1], b[i]))
    n.forme("Buste", "Fourrure", bm, subdiv=1, epaisseur=0.1)
    for k in range(9):  # bas de cape en mèches
        x = (-1.25 + k * 0.31) * c
        n.sphere("Buste", "Fourrure", (x, 0.62, 0.78 + 0.1 * (k % 2)), (0.18, 0.26, 0.12), u=10, v=6)


def brassiere(n, pr, c):
    """Haut de cuir sur la poitrine, avec bretelles croisées (Brunhilde)."""
    a = []
    for y in (2.92, 3.08, 3.24):
        rx, rz = rayon(pr, y)
        a.append((y, rx + 0.06, rz + 0.1))
    n.forme("Buste", "Haut", bm_loft(a, seg=28, bas=False, haut=False), subdiv=1, epaisseur=-0.07)
    rx, rz = rayon(pr, 3.0)
    n.forme("Buste", "Acier", bm_tore(T((0, 2.92, 0)), R=rx + 0.08, rz=rz + 0.12, r=0.035, seg=28, segp=5))
    if n.o.get("femme"):  # bonnets de cuir galbés
        for s in (-1, 1):
            n.sphere("Buste", "Haut", (s * 0.3 * c, 3.02, -rz + 0.04), (0.32 * c, 0.22, 0.13), rot=(0.25, s * 0.25, 0))
    for s in (-1, 1):
        n.membre("Buste", "Haut", [((s * 0.42 * c, 3.2, -rz - 0.05), 0.06), ((s * 0.55 * c, 3.42, -0.3), 0.06),
                                   ((s * 0.55 * c, 3.38, 0.3), 0.06), ((-s * 0.2 * c, 2.95, rz * 0.95), 0.06)], 1)


def bretelles(n, pr, c):
    """Bretelles de cuir sur le torse nu (Zog)."""
    for s in (-1, 1):
        pts = []
        for y, x in ((1.75, 0.5), (2.2, 0.56), (2.65, 0.56), (3.05, 0.55)):
            pts.append(((s * x * c, y, devant(pr, c, s * x * c, y, 0.04)), 0.075))
        pts += [((s * 0.56 * c, 3.42, -0.15), 0.075), ((s * 0.52 * c, 3.36, 0.4), 0.075),
                ((s * 0.3 * c, 2.6, 0.92 * c), 0.075), ((s * 0.3 * c, 1.8, 0.95 * c), 0.075)]
        n.membre("Buste", "Haut", pts, 1)
        for y in (1.78,):  # boutons dorés
            n.sphere("Buste", "Boucle", (s * 0.5 * c, y, devant(pr, c, s * 0.5 * c, y, 0.1)), (0.07, 0.07, 0.04), subdiv=0, u=10, v=6)


def col_fourrure(n, c):
    """Gros col de fourrure sur les épaules."""
    for k in range(18):
        a = 2 * math.pi * k / 18
        avant = math.sin(a) < -0.3
        R, rz = 1.0 * c, 0.78 * c
        y = 3.3 + 0.06 * math.sin(3 * a)
        r = 0.24 if avant else 0.34
        n.sphere("Buste", "Fourrure", (R * math.cos(a), y, rz * math.sin(a)), (r * 1.1, r, r),
                 rot=(0, a, 0.3 * math.sin(2 * a)), u=12, v=8)


def prise(ep, s):
    """Axe du manche tenu par la main du côté s : la paume se pose juste au bout de l'avant-bras."""
    return Vector((s * (ep + 0.19), 1.3, -0.1))


def main_serree(n, s, H, r, c):
    """Main fermée autour d'un manche vertical passant par H (rayon r ; r petit = poing).
    Paume côté extérieur, quatre doigts articulés qui font le tour du manche par l'avant, pouce par-dessus."""
    H = Vector(H)
    k = 0.9 + 0.1 * c
    R = r + 0.075 * k

    def autour(theta, dy, marge=0.0):
        return H + Vector((s * (R + marge) * math.cos(theta), dy, -(R + marge) * math.sin(theta)))

    # paume et dos de la main (côté extérieur du manche), jointure du poignet
    n.sphere("Buste", "Peau", H + Vector((s * (R + 0.07), 0.02, 0.02)), (0.13 * k, 0.29 * k, 0.24 * k), u=18, v=12)
    n.sphere("Buste", "Peau", H + Vector((s * (R + 0.03), 0.27, 0.04)), (0.15 * k, 0.12, 0.2 * k))
    # quatre doigts : de la paume, ils passent devant le manche et reviennent côté intérieur
    for i, (dy, ep_doigt) in enumerate(((0.19, 0.078), (0.065, 0.08), (-0.06, 0.076), (-0.175, 0.066))):
        dy *= k
        pts = [(autour(0.15, dy, 0.03), ep_doigt * k), (autour(1.0, dy, 0.01), ep_doigt * k),
               (autour(1.9, dy), ep_doigt * 0.95 * k), (autour(2.65, dy - 0.01), ep_doigt * 0.85 * k)]
        n.membre("Buste", "Peau", pts, 1)
        n.sphere("Buste", "Peau", autour(1.0, dy, 0.045), (0.06 * k, 0.055 * k, 0.05 * k), subdiv=0, u=10, v=6)  # jointure
    # pouce : part de la paume, passe par-dessus les doigts côté avant
    n.membre("Buste", "Peau", [(H + Vector((s * (R + 0.04), 0.16 * k, -0.17 * k)), 0.085 * k),
                               (autour(1.15, 0.3 * k, 0.05), 0.08 * k), (autour(1.85, 0.27 * k, 0.04), 0.07 * k)], 1)


def epaulieres(n, c, ep):
    """Spalières de métal à trois lames, bord doré, rivets."""
    for s in (-1, 1):
        for k, (dy, ech) in enumerate(((0.0, 1.0), (-0.24, 0.88), (-0.46, 0.76))):
            m = T((s * (ep - 0.1 + 0.06 * k), 3.28 + dy, 0), (0, 0, -s * (0.45 + 0.12 * k)), (0.62 * ech * c, 0.3, 0.66 * ech * c))
            bm = bm_sphere(m, 24, 12)
            bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < 3.28 + dy - 0.1 and abs(v.co.x) < ep - 0.3], context='VERTS')
            n.forme("Buste", "Acier" if k else "Metal", bm, subdiv=1, epaisseur=0.05)
        n.forme("Buste", "Or", bm_tore(T((s * (ep - 0.1), 3.22, 0), (0, 0, -s * 0.45)), R=0.6 * c, rz=0.64 * c, r=0.04, seg=28, segp=5))
        for a in range(5):
            t = -1.1 + a * 0.55
            n.sphere("Buste", "Or", (s * (ep - 0.1 + 0.25 * math.cos(t)), 3.5 - 0.06 * abs(t), 0.5 * math.sin(t) * c),
                     (0.05, 0.05, 0.05), subdiv=0, u=8, v=5)


def hache_dos(n, c):
    """Grande hache à double lame portée en travers du dos, runes bleues sur les lames (Gromm)."""
    import mathutils
    a, b = Vector((-1.1 * c, 0.9, 1.25 * c)), Vector((1.0 * c, 3.9, 1.25 * c))
    d = (b - a).normalized()
    n.membre("Buste", "Bois", [(a, 0.09), (a.lerp(b, 0.5), 0.1), (b, 0.09)], 1)
    for t in (0.12, 0.5):
        p = a.lerp(b, t)
        n.forme("Buste", "Cuir", bm_loft([(-0.14, 0.12, 0.12), (0.14, 0.12, 0.12)], seg=12,
                                         M=Matrix.Translation(p) @ d.to_track_quat('Y', 'Z').to_matrix().to_4x4()))
    tete = a.lerp(b, 0.86)
    rot = d.to_track_quat('Y', 'Z').to_matrix().to_4x4()
    perp = (rot @ Vector((1, 0, 0, 0))).xyz.normalized()
    for s in (-1, 1):  # deux lames en croissant
        pts = []
        for i in range(7):
            u = -1 + 2 * i / 6
            pts.append((tete + d * (u * 0.62) + perp * s * (0.18 + 0.62 * (1 - u * u) ** 0.5), 0.04 + 0.05 * (1 - abs(u))))
        n.membre("Buste", "Acier", pts, 2)
        bm = bmesh.new()
        coque = [bm.verts.new(tete + d * 0.3 + perp * s * 0.12), bm.verts.new(tete - d * 0.3 + perp * s * 0.12)]
        bord = [bm.verts.new(tete + d * (u * 0.62) + perp * s * (0.18 + 0.62 * (1 - u * u) ** 0.5)) for u in (-0.9, -0.45, 0, 0.45, 0.9)]
        bm.faces.new([coque[1]] + bord + [coque[0]])
        n.forme("Buste", "Metal", bm, epaisseur=0.06)
        n.forme("Buste", "Lueur", bm_cube(Matrix.Translation(tete + perp * s * 0.42 + Vector((0, 0, 0.05))) @ rot @
                                          Matrix.Diagonal((0.05, 0.3, 0.02, 1))))
    n.forme("Buste", "Or", bm_loft([(-0.16, 0.16, 0.16), (0.16, 0.16, 0.16)], seg=14, M=Matrix.Translation(tete) @ rot), biseau=0.03)
    for s in (-1, 1):  # sangle en travers du ventre
        n.membre("Buste", "Cuir", [((s * 0.95 * c, 3.25, 0.5), 0.06), ((s * 0.4 * c, 3.0, 0.95), 0.06)], 1)


def runes(n, pr, c):
    """Fines runes lumineuses le long des bords du manteau (Gromm)."""
    for s in (-1, 1):
        for i in range(6):
            y = 0.9 + i * 0.42
            x = s * (0.82 * c + 0.2)
            rx, rz = rayon(pr, max(y, 1.45))
            rx, rz = (rx + 0.14, rz + 0.16) if y >= 1.45 else (1.32 * c, 1.08 * c)
            u = min(abs(x) / rx, 0.97)
            z = -rz * math.sqrt(1 - u * u) - 0.04
            n.forme("Buste", "Lueur", bm_cube(T((x, y, z), (0, s * 0.6, 0.35 * (i % 2 * 2 - 1)), (0.03, 0.16, 0.015))))


def outil(n, genre, ep):
    droite, gauche = prise(ep, 1), prise(ep, -1)  # le manche passe dans la main serrée
    if genre == "marteau":  # énorme marteau de forge, cœur chauffé au rouge
        x, z = droite.x, droite.z
        n.forme("Buste", "Bois", bm_loft([(0.55, 0.1, 0.1, x, z), (2.0, 0.11, 0.11, x, z)], seg=12), subdiv=1)
        n.forme("Buste", "Cuir", bm_loft([(1.5, 0.13, 0.13, x, z), (1.95, 0.13, 0.13, x, z)], seg=12))
        n.forme("Buste", "Metal", bm_cube(T((x, 0.55, z), echelle=(0.62, 0.6, 1.3))), biseau=0.09)
        for dz in (-0.68, 0.68):  # faces de frappe cerclées d'or
            n.forme("Buste", "Acier", bm_cube(T((x, 0.55, z + dz), echelle=(0.68, 0.66, 0.1))), biseau=0.03)
            n.forme("Buste", "Or", bm_cube(T((x, 0.55, z + dz * 0.8), echelle=(0.66, 0.64, 0.06))), biseau=0.02)
        for s in (-1, 1):  # fentes incandescentes
            n.forme("Buste", "Lueur", bm_cube(T((x + s * 0.315, 0.55, z), echelle=(0.02, 0.36, 0.9))), biseau=0.01)
    elif genre == "pioche":  # pioche lourde, tête posée au sol à côté de la botte, manche serré dans la main
        H = droite
        d = Vector((0.04, 1, 0)).normalized()
        q = Vector((0, 0, 1))

        def P(t, dz=0.0, monte=0.0):
            return H + d * (t + monte) + q * dz

        n.membre("Buste", "Bois", [(P(-1.02), 0.1), (P(-0.2), 0.105), (P(0.6), 0.11)], 1)
        n.membre("Buste", "Cuir", [(P(-0.25), 0.13), (P(0.32), 0.13)], 0)
        # les bras de la pioche se recourbent vers la main (vers le haut)
        n.membre("Buste", "Metal", [(P(-1.0, -1.25, 0.38), 0.04), (P(-1.0, -0.7, 0.12), 0.13), (P(-1.0), 0.21),
                                    (P(-1.0, 0.65, 0.12), 0.13), (P(-1.0, 1.15, 0.34), 0.04)], 2)
        n.membre("Buste", "Lueur", [(P(-1.02, -1.28, 0.36), 0.025), (P(-1.02, -0.75, 0.1), 0.05), (P(-1.02, -0.3, 0.0), 0.04)], 1)
        n.membre("Buste", "Or", [(P(-0.85), 0.15), (P(-0.62), 0.15)], 0)
    elif genre == "chope":  # tenue par l'anse : l'anse passe dans la main, la chope devant, à l'écart de la jupe
        H = droite
        x, z = H.x + 0.12, H.z - 0.68
        n.forme("Buste", "Bois", bm_loft([(1.0, 0.3, 0.3, x, z), (1.75, 0.32, 0.32, x, z)], seg=20), subdiv=1)
        for y in (1.1, 1.62):
            n.forme("Buste", "Or", bm_tore(T((x, y, z)), R=0.33, r=0.04, seg=20, segp=6))
        n.sphere("Buste", "Lueur", (x, 1.36, z - 0.32), (0.08, 0.1, 0.04), subdiv=0, u=10, v=6)  # gemme d'ambre
        n.sphere("Buste", "Mousse", (x, 1.78, z), (0.33, 0.14, 0.33))
        n.sphere("Buste", "Mousse", (x + 0.12, 1.86, z - 0.05), (0.15, 0.1, 0.15))
        n.membre("Buste", "Bois", [((x - 0.04, 1.62, z + 0.3), 0.055), ((H.x, 1.58, H.z), 0.055),
                                   ((H.x, 1.06, H.z), 0.055), ((x - 0.04, 1.1, z + 0.3), 0.055)], 1)
    elif genre == "registre":  # tenu par le dos (reliure dans la main), le livre pointe vers l'avant, hors du manteau
        H = gauche
        c0 = H + Vector((-0.1, -0.3, -0.6))
        n.forme("Buste", "Couverture", bm_cube(T(c0, (0, 0, 0), (0.26, 0.95, 1.1))), biseau=0.03)
        n.forme("Buste", "Pages", bm_cube(T(c0 + Vector((0, 0, -0.03)), (0, 0, 0), (0.22, 0.89, 1.06))), biseau=0.01)
        n.forme("Buste", "Boucle", bm_cube(T(c0 + Vector((0, 0, -0.56)), (0, 0, 0), (0.3, 0.3, 0.06))))
        n.forme("Buste", "Lueur", bm_cube(T(c0 + Vector((-0.14, 0, -0.1)), (0, 0, math.pi / 4), (0.02, 0.22, 0.22))))  # rune


def tete(n):
    o = n.o
    t = TETE
    femme = o.get("femme", False)
    n.pivot("Tete", (0, 3.32, 0))  # cou : la tête pivote autour de ce point
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
        # yeux enfoncés sous l'arcade : petits, paupières lourdes (réaliste)
        oe = 1.15 if femme else 1.0  # yeux un peu plus grands chez les femmes
        n.sphere("Tete", "Yeux", (s * 0.23, 3.96, -0.565), (0.09 * oe, 0.07 * oe, 0.06), subdiv=1, u=16, v=10)
        n.sphere("Tete", "Pupilles", (s * 0.23, 3.955, -0.615), (0.045 * oe, 0.048 * oe, 0.022), subdiv=0, u=12, v=8)
        n.sphere("Tete", "Peau", (s * 0.23, 4.03, -0.565), (0.105, 0.035, 0.07), subdiv=1, u=14, v=8)
        n.sphere("Tete", "Peau", (s * 0.23, 3.895, -0.56), (0.095, 0.025, 0.06), subdiv=1, u=14, v=8)
        n.sphere("Tete", "Peau", (s * 0.25, 4.1, -0.5), (0.19, 0.06, 0.11), rot=(0.2, 0, -s * 0.15))  # arcade
        epais = 0.06 if femme else 0.1
        n.membre("Tete", "Sourcils", [((s * 0.09, 4.12, -0.61), epais), ((s * 0.24, 4.17, -0.58), epais + 0.01),
                                      ((s * 0.4, 4.12, -0.48), epais * 0.7)], 1)
    # gros nez de nain (sert aussi au jeu pour savoir où regarde le PNJ)
    n.membre("Tete", "Nez", [((0, 4.02, -0.58), 0.08), ((0, 3.88, -0.72), 0.13), ((0, 3.76, -0.76), 0.17)])
    for s in (-1, 1):
        n.sphere("Tete", "Nez", (s * 0.12, 3.74, -0.68), (0.09, 0.08, 0.08), subdiv=1, u=12, v=8)
        n.sphere("Tete", "Peau", (s * 0.2, 3.66, -0.54), (0.06, 0.09, 0.05), rot=(0, 0, s * 0.5))  # pli des joues
    n.membre("Tete", "Bouche", [((-0.15, 3.6, -0.56), 0.03), ((0, 3.57, -0.6), 0.04), ((0.15, 3.6, -0.56), 0.03)], 1)
    n.sphere("Tete", "Peau", (0, 3.53, -0.57), (0.12, 0.04, 0.05))  # lèvre inférieure
    if femme:  # traits féminins : cils, lèvres pleines, boucles d'oreilles
        for s in (-1, 1):
            n.membre("Tete", "Pupilles", [((s * 0.13, 4.0, -0.6), 0.012), ((s * 0.23, 4.025, -0.625), 0.016),
                                          ((s * 0.33, 4.01, -0.59), 0.012), ((s * 0.37, 4.03, -0.56), 0.008)], 1)
            n.forme("Tete", "Or", bm_tore(T((s * 0.7, 3.7, 0.16), (0, 0, math.pi / 2)), R=0.09, r=0.022, seg=16, segp=5))
            n.sphere("Tete", "Lueur", (s * 0.7, 3.6, 0.16), (0.035, 0.05, 0.035), subdiv=0, u=10, v=6)
        n.sphere("Tete", "Bouche", (0, 3.585, -0.59), (0.13, 0.035, 0.04))
        n.sphere("Tete", "Bouche", (0, 3.54, -0.585), (0.11, 0.04, 0.04))

    cheveux(n, o.get("coiffure"))
    barbe(n, o.get("barbe"))
    if o.get("casque") == "mineur":  # casque de mineur à lampe (Zog)
        bm = bm_sphere(T((0, 4.08, 0.02), echelle=(0.76, 0.66, 0.78)), 32, 18)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.y < 4.1], context='VERTS')
        n.forme("Tete", "Casque", bm, subdiv=1, epaisseur=0.06)
        n.forme("Tete", "Casque", bm_tore(T((0, 4.12, 0.02)), R=0.82, rz=0.86, r=0.06, seg=32, segp=6))
        n.forme("Tete", "Casque", bm_loft([(4.42, 0.06, 0.6), (4.76, 0.06, 0.66)], seg=20, bas=False, haut=False), epaisseur=-0.05)
        m = T((0, 4.42, -0.74), (-math.pi / 2, 0, 0))
        n.forme("Tete", "Acier", bm_loft([(-0.12, 0.15, 0.15), (0.1, 0.17, 0.17)], seg=20, M=m), biseau=0.02)
        n.forme("Tete", "Lampe", bm_loft([(0.1, 0.14, 0.14), (0.13, 0.13, 0.13)], seg=20, M=m))
    elif o.get("casque") == "cornes":  # casque à petites cornes (Brolg)
        bm = bm_sphere(T((0, 4.02, 0.03), echelle=(0.82, 0.78, 0.84)), 32, 18)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.y < 4.08], context='VERTS')
        n.forme("Tete", "Casque", bm, subdiv=1, epaisseur=0.06)
        n.forme("Tete", "Acier", bm_tore(T((0, 4.1, 0.03)), R=0.86, rz=0.88, r=0.07, seg=32, segp=6))
        n.forme("Tete", "Acier", bm_loft([(4.4, 0.07, 0.88), (4.76, 0.07, 0.7)], seg=20, bas=False, haut=False), epaisseur=-0.05)
        for s in (-1, 1):
            n.membre("Tete", "Corne", [((s * 0.74, 4.3, 0.0), 0.15), ((s * 0.98, 4.42, -0.02), 0.12),
                                       ((s * 1.08, 4.68, -0.06), 0.08), ((s * 1.1, 4.95, -0.1), 0.03)], 2)
            for k, t in enumerate((4.38, 4.56)):  # anneaux d'or sur les cornes
                n.forme("Tete", "Or", bm_tore(T((s * (0.86 + 0.1 * k), t, -0.03), (0, 0, -s * (0.6 - 0.3 * k))),
                                              R=0.13 - 0.025 * k, r=0.03, seg=14, segp=5))
        n.forme("Tete", "Or", bm_cube(T((0, 4.55, -0.82), (0.35, 0, math.pi / 4), (0.2, 0.2, 0.06))), biseau=0.02)
        n.forme("Tete", "Lueur", bm_cube(T((0, 4.55, -0.86), (0.35, 0, math.pi / 4), (0.12, 0.12, 0.04))), biseau=0.02)
    if o.get("bandeau"):  # bandeau de métal orné (Brunhilde)
        n.forme("Tete", "Acier", bm_loft([(4.2, 0.74, 0.77), (4.34, 0.73, 0.76)], seg=32, bas=False, haut=False,
                                         M=T((0, 0, 0.02))), epaisseur=-0.04, biseau=0.01)
        n.forme("Tete", "Or", bm_cube(T((0, 4.27, -0.8), (0, 0, math.pi / 4), (0.2, 0.2, 0.06))), biseau=0.02)
        n.forme("Tete", "Lueur", bm_cube(T((0, 4.27, -0.84), (0, 0, math.pi / 4), (0.12, 0.12, 0.05))), biseau=0.02)
    if o.get("peinture"):  # peinture de guerre bleue sur l'œil (Gromm)
        for s in (-1, 1):
            n.forme("Tete", "Peinture", bm_cube(T((s * 0.25, 3.94, -0.6), (0.1, s * 0.5, s * 0.25), (0.06, 0.32, 0.02))))
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
    base = style in ("tresses", "chignon", "tressesLongues", "longs")
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
        for s in ((-1, 1) if not o.get("casque") else ()):
            n.sphere("Tete", "Cheveux", (s * 0.3, 4.38, -0.42), (0.34, 0.16, 0.24), rot=(0.5, 0, -s * 0.4))
    if style == "tresses":
        for s in (-1, 1):
            n.tresse("Tete", "Cheveux", (s * 0.6, 3.75, 0.05), (s * 0.82, 2.55, -0.45), 0.17, n=8, anneau="Acier")
    elif style == "tressesLongues":  # longues tresses rousses jusqu'au ventre (Brunhilde, Brolg)
        for s in (-1, 1):
            n.tresse("Tete", "Cheveux", (s * 0.6, 3.75, 0.0), (s * 0.78, 1.95, -0.85), 0.18, n=11, anneau="Acier")
            n.tresse("Tete", "Cheveux", (s * 0.42, 3.6, 0.45), (s * 0.5, 2.3, 0.85), 0.16, n=8, anneau="Acier")
    elif style == "longs":  # cheveux gris tirés en arrière, tombant dans le dos, deux tresses devant (Gromm)
        n.sphere("Tete", "Cheveux", (0, 3.55, 0.5), (0.62, 0.8, 0.3))
        n.sphere("Tete", "Cheveux", (0, 3.05, 0.62), (0.5, 0.45, 0.22))
        for s in (-1, 1):
            n.tresse("Tete", "Cheveux", (s * 0.62, 3.7, -0.05), (s * 0.85, 2.4, -0.7), 0.15, n=9, anneau="Acier")
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
        if style == "courte":  # barbe de femme naine : seulement le menton, ni favoris ni moustache
            garde = uz < 0.1 and uy < -0.5 and abs(ux) < 0.55
        else:
            garde = uz < 0.35 and (uy < -0.3 or (abs(ux) > 0.78 and uy < 0.05))
        if not garde:
            mort.append(v)
    bmesh.ops.delete(bm, geom=mort, context='VERTS')
    n.forme("Tete", "Barbe", bm, subdiv=1, epaisseur=-0.07 if style == "courte" else -0.14)
    if style != "courte":  # moustache fournie
        n.membre("Tete", "Barbe", [((-0.46, 3.5, -0.45), 0.06), ((-0.3, 3.62, -0.6), 0.1), ((-0.1, 3.68, -0.7), 0.11),
                                   ((0, 3.68, -0.72), 0.1), ((0.1, 3.68, -0.7), 0.11), ((0.3, 3.62, -0.6), 0.1),
                                   ((0.46, 3.5, -0.45), 0.06)])
    if style == "soignee":  # barbe taillée en pointe
        n.forme("Tete", "Barbe", bm_loft([(3.5, 0.55, 0.36, 0, -0.42), (3.15, 0.48, 0.34, 0, -0.55),
                                          (2.85, 0.3, 0.24, 0, -0.62), (2.65, 0.08, 0.08, 0, -0.64)], seg=18), subdiv=2)
    elif style == "courte":  # petite barbe rousse terminée par une tresse (Brunhilde)
        n.forme("Tete", "Barbe", bm_loft([(3.46, 0.3, 0.22, 0, -0.5), (3.3, 0.22, 0.18, 0, -0.58),
                                          (3.16, 0.1, 0.09, 0, -0.62)], seg=18), subdiv=2)
        n.tresse("Tete", "Barbe", (0, 3.16, -0.63), (0, 2.78, -0.66), 0.075, n=5, anneau="Acier")
    elif style == "longue":  # très longue barbe grise tressée, anneaux de métal (Gromm)
        n.forme("Tete", "Barbe", bm_loft([(3.55, 0.68, 0.44, 0, -0.45), (3.05, 0.74, 0.44, 0, -0.95),
                                          (2.55, 0.62, 0.36, 0, -1.25), (2.15, 0.42, 0.26, 0, -1.38)], seg=20), subdiv=2)
        for x in (-0.36, -0.12, 0.12, 0.36):
            n.tresse("Tete", "Barbe", (x, 2.3, -1.38), (x * 1.25, 1.2, -1.42), 0.13, n=7, anneau="Acier")
    elif style == "tressee":  # énorme barbe de forgeron avec trois tresses
        n.forme("Tete", "Barbe", bm_loft([(3.55, 0.66, 0.42, 0, -0.45), (3.1, 0.7, 0.42, 0, -0.85),
                                          (2.6, 0.6, 0.34, 0, -1.12), (2.3, 0.4, 0.24, 0, -1.22)], seg=20), subdiv=2)
        for x in (-0.32, 0.0, 0.32):
            n.tresse("Tete", "Barbe", (x, 2.4, -1.26 - (0.05 if x == 0 else 0)), (x * 1.2, 1.5, -1.3), 0.15, n=6)


# ================= Poses (animations du jeu) =================
# Une pose = angles des articulations, dans le repère du nain (x droite, y haut, -z devant) :
#   "D"/"G" : bras droit/gauche = (flexion épaule, rotation épaule, écartement épaule, flexion coude, torsion avant-bras)
#             épaule = Rz(écart) · Ry(rotation) · Rx(flexion) ; coude = Rx(flexion) · Ry(torsion)
#   "tete"  : (tangage, lacet) ; tangage > 0 = tête en arrière
#   "buste" : inclinaison autour des hanches ; > 0 = vers l'arrière
# Le jeu (src/client/AnimationsNains.client.lua) applique exactement les mêmes formules : les poses
# sont exportées dans src/partage/PosesNains.lua (fichier généré). Les poses qui doivent toucher un point
# précis (chope aux lèvres, livre sous les yeux, pioche devant le visage) sont calculées par recherche.
POSES = {
    "Brom": {
        "repos": {},
        "garde": {"D": (0.22, 0.0, 0.03, 0.55, 0.0), "tete": (-0.22, 0.0), "buste": -0.03},
        "leve": {"D": (1.05, 0.0, 0.16, 1.62, 0.0), "tete": (-0.1, 0.0), "buste": 0.05},
        "frappe": {"D": (0.42, 0.0, 0.03, 0.98, 0.0), "tete": (-0.2, 0.0), "buste": -0.1},
    },
    "Margot": {"repos": {}},
    "Gaspard": {"repos": {}},
    "Liesel": {"repos": {}},
}


def R(axe, a):
    return Matrix.Rotation(a, 4, axe)


def autour(P, Rm):
    P = Vector(P)
    return Matrix.Translation(P) @ Rm @ Matrix.Translation(-P)


def geo(nom):
    o = NAINS[nom]
    c = o.get("carrure", 1)
    ep = 1.18 * c if not o.get("femme") else 1.04 * c
    g = {"c": c, "ep": ep, "hanche": Vector((0, 1.55, 0)), "cou": Vector((0, 3.3 + 0.02 * ECHELLE_TETE, 0))}
    for s, cote in ((1, "D"), (-1, "G")):
        g["epaule" + cote] = Vector((s * (ep - 0.12), 3.12, 0))
        g["coude" + cote] = Vector((s * (ep + 0.22), 2.3, 0.05))
        g["poignet" + cote] = Vector((s * (ep + 0.3), 1.58, -0.05))
    return g


def bras7(v):
    """Angles d'un bras complétés à 7 : (flexion épaule, rotation, écart, flexion coude, torsion, flexion poignet, inclinaison poignet)."""
    v = tuple(v or ())
    return v + (0.0,) * (7 - len(v))


def tete_pt(p):
    """Point du visage modélisé (avant la mise à l'échelle de la tête) -> position réelle."""
    p = Vector(p)
    pivot = Vector((0, 3.3, 0))
    return pivot + (p - pivot) * ECHELLE_TETE


def transformes(nom, pose):
    g = geo(nom)
    lean = pose.get("buste", 0.0)
    tang, lacet = pose.get("tete", (0.0, 0.0))
    Tb = autour(g["hanche"], R('X', lean))
    T = {"Corps": Matrix.Identity(4), "Buste": Tb, "Tete": Tb @ autour(g["cou"], R('Y', lacet) @ R('X', tang))}
    for cote in "DG":
        f1, rot, ecart, f2, tors, pf, pi = bras7(pose.get(cote))
        Tbr = Tb @ autour(g["epaule" + cote], R('Z', ecart) @ R('Y', rot) @ R('X', f1))
        T["Bras" + cote] = Tbr
        Tav = Tbr @ autour(g["coude" + cote], R('X', f2) @ R('Y', tors))
        T["AvBras" + cote] = Tav
        T["Main" + cote] = Tav @ autour(g["poignet" + cote], R('X', pf) @ R('Z', pi))
    return T


def melange(a, b, t):
    """Pose intermédiaire (interpolation linéaire des angles), comme dans le jeu."""
    res = {}
    for cle in ("D", "G"):
        va, vb = bras7(a.get(cle)), bras7(b.get(cle))
        res[cle] = tuple(x + (y - x) * t for x, y in zip(va, vb))
    ta, tb = a.get("tete", (0, 0)), b.get("tete", (0, 0))
    res["tete"] = tuple(x + (y - x) * t for x, y in zip(ta, tb))
    res["buste"] = a.get("buste", 0) + (b.get("buste", 0) - a.get("buste", 0)) * t
    return res


def chercher(cout, bornes, essais=5000, tours=7, graine=7):
    """Recherche aléatoire qui se resserre autour du meilleur point (sans dépendance externe)."""
    rng = random.Random(graine)
    meilleur, val = None, float("inf")
    for _ in range(essais):
        x = [rng.uniform(a, b) for a, b in bornes]
        v = cout(x)
        if v < val:
            meilleur, val = x, v
    pas = [(b - a) * 0.15 for a, b in bornes]
    for _ in range(tours):
        for _ in range(essais // 4):
            x = [min(max(m + rng.gauss(0, p), a), b) for m, p, (a, b) in zip(meilleur, pas, bornes)]
            v = cout(x)
            if v < val:
                meilleur, val = x, v
        pas = [p * 0.5 for p in pas]
    return meilleur, val


def tete_marteau_coins(ep):
    H = prise(ep, 1)
    c0 = Vector((H.x, 0.55, H.z))
    return [c0 + Vector((sx * 0.35, sy * 0.34, sz * 0.75)) for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]


def impact_frappe(nom, ep):
    """Point où le marteau touche l'épée (frappe) et hauteur du dessus de l'enclume."""
    Ta = transformes(nom, POSES[nom]["frappe"])["MainD"]
    coins = sorted((Ta @ p for p in tete_marteau_coins(ep)), key=lambda p: p.y)[:4]
    impact = sum(coins, Vector()) / 4
    return impact, impact.y - 0.075


class Penetration:
    """Mesure combien un bras (et l'objet qu'il tient) s'intersecte avec le reste du corps, pour une pose.
    Même test que le contrôle final : intersection face contre face (BVH), sur une copie allégée du bras.
    Les contacts aux articulations (épaule, coude) sont normaux et ignorés ; le résultat est relatif à la pose
    de repos (ce qui se touche déjà au repos ne compte pas)."""

    def __init__(self, nom, cote, fixe, objets, ratio=0.18):
        import bpy
        from mathutils.bvhtree import BVHTree
        self.BVHTree = BVHTree
        self.nom, self.cote = nom, cote
        i = list(NAINS).index(nom)
        self.passage = Matrix.Translation(Vector((i * 4.0, 0, 0))) @ (CONV.to_4x4() if len(CONV) == 3 else CONV)
        self.retour = self.passage.inverted()
        T = transformes(nom, fixe)
        mobiles = ("Bras" + cote, "AvBras" + cote, "Main" + cote)
        self.corps = []  # (nom, arbre) par pièce du corps
        self.bras = []  # (groupe, sommets monde au repos, polygones) des copies allégées
        dg = bpy.context.evaluated_depsgraph_get()
        for ob in objets:
            grp, teinte = ob.name.split("_")[1], ob.name.split("_")[-1]
            if teinte == "Pivot":
                continue
            mw = ob.matrix_world
            if grp in mobiles:
                tmp = bpy.data.objects.new("tmp_pen", ob.data)
                bpy.context.scene.collection.objects.link(tmp)
                tmp.matrix_world = mw
                if len(ob.data.polygons) > 60:
                    m = tmp.modifiers.new("dec", 'DECIMATE')
                    m.ratio = ratio
                dg = bpy.context.evaluated_depsgraph_get()
                me = bpy.data.meshes.new_from_object(tmp.evaluated_get(dg))
                self.bras.append((grp, [mw @ v.co for v in me.vertices], [list(p.vertices) for p in me.polygons]))
                bpy.data.objects.remove(tmp)
                bpy.data.meshes.remove(me)
                continue
            W = self.W(T.get(grp, Matrix.Identity(4)))
            self.corps.append((ob.name, BVHTree.FromPolygons([W @ (mw @ v.co) for v in ob.data.vertices],
                                                             [list(pl.vertices) for pl in ob.data.polygons])))
        self.base = {}
        self.base = self.compter({})

    def W(self, M):
        return self.passage @ M @ self.retour

    def compter(self, pose):
        T = transformes(self.nom, pose)
        g = geo(self.nom)
        Wb, Wa, Wm = self.W(T["Bras" + self.cote]), self.W(T["AvBras" + self.cote]), self.W(T["Main" + self.cote])
        epaule = self.passage @ (T["Bras" + self.cote] @ g["epaule" + self.cote])
        coude = self.passage @ (T["AvBras" + self.cote] @ g["coude" + self.cote])
        poignet = self.passage @ (T["Main" + self.cote] @ g["poignet" + self.cote])
        res = {}
        for i, (grp, vs, ps) in enumerate(self.bras):
            M = Wb if grp[0] == "B" else (Wa if grp[0] == "A" else Wm)
            vt = [M @ v for v in vs]
            arbre = self.BVHTree.FromPolygons(vt, ps)
            for nom_c, corps in self.corps:
                n = 0
                for fa, fb in arbre.overlap(corps):
                    c = sum((vt[k] for k in ps[fa]), Vector()) / len(ps[fa])
                    if (c - epaule).length > 0.62 and (c - coude).length > 0.45 and (c - poignet).length > 0.3:
                        n += 1
                if n:
                    res[(i, nom_c)] = n
        return res

    def __call__(self, pose):
        return sum(max(0, n - self.base.get(k, 0) * 1.2) for k, n in self.compter(pose).items()) / 40.0


def pose_bras(fixe, cote, x):
    return dict(fixe, **{cote: tuple(x)})


BORNES = [(-0.4, 2.2), (-1.3, 1.3), (-1.0, 1.1), (0.0, 2.5), (-1.8, 1.8), (-1.6, 1.0), (-0.6, 0.6)]


def passage(nom, cote, A, B, pen, fixe, graine):
    """Pose intermédiaire entre A et B pour que le bras contourne le corps (ventre, barbe, fourrure)."""
    va, vb = bras7(A.get(cote)), bras7(B.get(cote))
    milieu = [(a + b) / 2 for a, b in zip(va, vb)]

    def cout(x):
        P = pose_bras(fixe, cote, x)
        chemin = [pen(P)] + [pen(melange(A, P, t)) + pen(melange(P, B, t)) for t in (0.25, 0.5, 0.75)]
        return (30 * sum(chemin)
                + 0.15 * sum((a - m) ** 2 for a, m in zip(x, milieu)))

    x, v = chercher(cout, BORNES, essais=450, tours=4, graine=graine)
    print(f"PASSAGE {nom}: {[round(a, 3) for a in x]} cout {v:.4f}")
    return pose_bras(fixe, cote, x)


def resoudre_poses(objets):
    """Calcule les poses qui doivent atteindre un point précis, sans traverser le corps."""
    par_nain = {nom: [o for o in objets if o.name.startswith(nom + "_")] for nom in NAINS}

    # --- Margot : boire. Le bord de la chope vient aux lèvres, la chope basculée vers le visage.
    g = geo("Margot")
    H = prise(g["ep"], 1)
    centre_chope = Vector((H.x + 0.12, 1.375, H.z - 0.68))
    bord = [Vector((centre_chope.x + 0.32 * math.cos(a), 1.75, centre_chope.z + 0.32 * math.sin(a)))
            for a in [i * math.pi / 12 for i in range(24)]]
    fixe = {"tete": (0.3, 0.0), "buste": 0.07}
    pen = Penetration("Margot", "D", fixe, par_nain["Margot"])

    def cout_boire(x):
        P = pose_bras(fixe, "D", x)
        T = transformes("Margot", P)
        Ta = T["MainD"]
        levres = T["Tete"] @ tete_pt((0, 3.54, -0.6))
        d = min(((Ta @ p) - levres).length for p in bord)
        axe = (Ta.to_3x3() @ Vector((0, 1, 0))).normalized()
        # geste naturel : la main reste sur le côté du visage (pas devant), la chope devant la bouche
        main = Ta @ H
        cote = max(0.0, 0.5 - main.x)
        devant = max(0.0, (Ta @ centre_chope).z - (levres.z - 0.2))
        return (12 * d * d + 1.5 * (axe.z - 0.8) ** 2 + 40 * pen(P) + 4 * cote ** 2 + 4 * devant ** 2
                + 0.02 * (x[1] ** 2 + x[4] ** 2))

    # coude écarté vers l'extérieur (ecart >= 0) : le bras contourne le ventre et le col de fourrure
    x, v = chercher(cout_boire, [(0.3, 1.9), (-0.9, 0.9), (0.0, 1.1), (0.6, 2.5), (-1.6, 1.6), (-1.8, 0.6), (-0.6, 0.6)], essais=1000, tours=6, graine=3)
    boire = pose_bras(fixe, "D", x)
    POSES["Margot"]["boire"] = boire
    print("POSE Margot boire", [round(a, 3) for a in x], "cout", round(v, 4), "penetration", round(pen(boire), 4))
    approche = passage("Margot", "D", {}, boire, pen, {"tete": (0.05, 0.0), "buste": 0.02}, 11)
    POSES["Margot"]["approche"] = approche
    gorgee = dict(boire)
    gorgee["tete"] = (0.42, 0.0)
    f1, rot, ecart, f2, tors, pf, pi = bras7(boire["D"])
    gorgee["D"] = (f1, rot, ecart, f2, tors, pf, pi)  # le bras reste : c'est la tête qui bascule pour la gorgée
    POSES["Margot"]["gorgee"] = gorgee

    # --- Gaspard : lire son registre. Livre levé devant lui (devant la barbe), face tournée vers ses yeux.
    g = geo("Gaspard")
    H = prise(g["ep"], -1)
    centre_livre = H + Vector((-0.1, -0.3, -0.6))
    fixe = {"tete": (-0.36, 0.14), "buste": -0.03}
    pen = Penetration("Gaspard", "G", fixe, par_nain["Gaspard"])

    def cout_lire(x):
        P = pose_bras(fixe, "G", x)
        T = transformes("Gaspard", P)
        Ta = T["MainG"]
        centre = Ta @ centre_livre
        yeux = T["Tete"] @ tete_pt((0, 3.96, -0.56))
        n = (Ta.to_3x3() @ Vector((1, 0, 0))).normalized()
        vers_yeux = (yeux - centre).normalized()
        cible = Vector((-0.5, 2.45, -1.7))
        return (2 * (centre - cible).length_squared + 2 * (1 - abs(n.dot(vers_yeux)))
                + 40 * pen(P) + 0.02 * (x[1] ** 2 + x[4] ** 2))

    x, v = chercher(cout_lire, BORNES, essais=700, tours=5, graine=5)
    lire = pose_bras(fixe, "G", x)
    POSES["Gaspard"]["lire"] = lire
    print("POSE Gaspard lire", [round(a, 3) for a in x], "cout", round(v, 4), "penetration", round(pen(lire), 4))
    POSES["Gaspard"]["leve_livre"] = passage("Gaspard", "G", {}, lire, pen, {"tete": (-0.1, 0.05), "buste": 0.0}, 13)
    tourne = dict(lire)
    tourne["tete"] = (-0.4, 0.0)
    POSES["Gaspard"]["lire2"] = tourne

    # --- Liesel : lever sa pioche à sa droite et examiner le tranchant (elle tourne la tête vers elle).
    g = geo("Liesel")
    H = prise(g["ep"], 1)
    d = Vector((0.04, 1, 0)).normalized()
    tete_pioche = H + d * (-1.0)
    fixe = {"tete": (-0.12, -0.42), "buste": 0.0}
    pen = Penetration("Liesel", "D", fixe, par_nain["Liesel"])

    def cout_pioche(x):
        P = pose_bras(fixe, "D", x)
        Ta = transformes("Liesel", P)["MainD"]
        p = Ta @ tete_pioche
        cible = Vector((1.6, 2.9, -1.3))
        manche = (Ta.to_3x3() @ (-d)).normalized()
        return 2 * (p - cible).length_squared + 0.6 * (manche.y - 0.5) ** 2 + 40 * pen(P) + 0.03 * (x[1] ** 2 + x[4] ** 2)

    x, v = chercher(cout_pioche, BORNES, essais=700, tours=5, graine=9)
    examiner = pose_bras(fixe, "D", x)
    POSES["Liesel"]["examiner"] = examiner
    print("POSE Liesel examiner", [round(a, 3) for a in x], "cout", round(v, 4), "penetration", round(pen(examiner), 4))
    POSES["Liesel"]["leve_pioche"] = passage("Liesel", "D", {}, examiner, pen, {"tete": (-0.05, -0.15), "buste": 0.0}, 17)
    for nom_p, dt, lacet in (("examiner_g", 0.38, -0.55), ("examiner_d", -0.38, -0.3)):
        p = dict(examiner)
        f1, rot, ecart, f2, tors, pf, pi = bras7(p["D"])
        p["D"] = (f1, rot, ecart, f2, tors + dt, pf, pi)
        p["tete"] = (-0.16, lacet)
        if pen(p) > 0.01:  # la torsion ferait entrer la pioche dans le corps : on la réduit
            p["D"] = (f1, rot, ecart, f2, tors + dt * 0.5, pf, pi)
        POSES["Liesel"][nom_p] = p

    # --- Brom : marteau au-dessus de l'épée (garde), marteau levé (leve) ; la frappe est réglée à la main
    #     et l'enclume a été posée exactement sous le marteau à ce moment-là.
    g = geo("Brom")
    impact, dessus = impact_frappe("Brom", g["ep"])
    H = prise(g["ep"], 1)
    centre_marteau = Vector((H.x, 0.55, H.z))
    frappe = POSES["Brom"]["frappe"]

    def cout_cible(fixe, cible, poids_pen, pen, autres=()):
        def cout(x):
            P = pose_bras(fixe, "D", x)
            Ta = transformes("Brom", P)["MainD"]
            c = 4 * ((Ta @ centre_marteau) - cible).length_squared + poids_pen * pen(P)
            for Q in autres:
                c += poids_pen * pen(melange(P, Q, 0.5))
            return c + 0.03 * (x[1] ** 2 + x[4] ** 2)
        return cout

    # Frappe de forgeron : le geste vient surtout du coude (l'épaule bouge peu, les grosses épaulières
    # empêchent de lever le bras haut) ; le marteau monte au-dessus de l'épaule, devant.
    fixe = {"tete": (-0.2, 0.0), "buste": -0.04}
    pen = Penetration("Brom", "D", fixe, par_nain["Brom"])
    bornes_garde = [(0.1, 0.7), (-0.5, 0.5), (-0.2, 0.5), (0.3, 1.8), (-0.6, 0.6), (-0.9, 0.6), (-0.3, 0.3)]
    x, v = chercher(cout_cible(fixe, impact + Vector((0, 0.9, 0)), 40, pen, (frappe,)), bornes_garde, essais=600, tours=5, graine=21)
    POSES["Brom"]["garde"] = pose_bras(fixe, "D", x)
    print("POSE Brom garde", [round(a, 3) for a in x], "cout", round(v, 4))
    fixe = {"tete": (-0.1, 0.0), "buste": 0.05}
    pen = Penetration("Brom", "D", fixe, par_nain["Brom"])
    cible_leve = Vector((impact.x - 0.05, 3.95, -0.55))
    bornes_leve = [(0.3, 0.85), (-0.5, 0.5), (0.0, 0.5), (1.6, 2.5), (-0.6, 0.6), (-0.6, 0.9), (-0.3, 0.3)]
    x, v = chercher(cout_cible(fixe, cible_leve, 40, pen, (frappe, POSES["Brom"]["garde"])), bornes_leve, essais=600, tours=5, graine=23)
    POSES["Brom"]["leve"] = pose_bras(fixe, "D", x)
    print("POSE Brom leve", [round(a, 3) for a in x], "cout", round(v, 4))
    POSES["Brom"]["souleve"] = passage("Brom", "D", {}, POSES["Brom"]["garde"], pen, {"tete": (-0.15, 0.0), "buste": 0.0}, 29)


def enclume(n, c, ep):
    """Enclume et épée chauffée au rouge, placées exactement sous le marteau de Brom au moment de la frappe."""
    impact, haut = impact_frappe(n.nom, ep)  # dessus de l'enclume : sous le marteau et l'épaisseur de la lame
    x, z = impact.x, impact.z
    print(f"ENCLUME sous le marteau : x={x:.2f} z={z:.2f} dessus={haut:.2f}")
    n.forme("Corps", "Acier", bm_cube(T((x, haut - 0.11, z), echelle=(0.95, 0.22, 0.42))), biseau=0.03)  # table
    n.forme("Corps", "Acier", bm_loft([(0.0, 0.2, 0.15), (0.45, 0.04, 0.03)], seg=12,
                                      M=T((x + 0.47, haut - 0.1, z), (0, 0, -math.pi / 2))), subdiv=1)  # bigorne vers l'extérieur
    n.forme("Corps", "Acier", bm_cube(T((x, haut - 0.38, z), echelle=(0.42, 0.34, 0.28))), biseau=0.03)  # taille
    n.forme("Corps", "Acier", bm_cube(T((x, haut - 0.62, z), echelle=(0.8, 0.16, 0.46))), biseau=0.03)  # pied
    n.forme("Corps", "Bois", bm_loft([(0.0, 0.36, 0.36, x, z), (haut - 0.7, 0.34, 0.34, x, z)], seg=18), biseau=0.02)  # billot
    # épée sur l'enclume : lame vers l'intérieur, poignée vers l'extérieur
    y = haut + 0.025
    n.forme("Corps", "Lueur", bm_cube(T((x - 0.05, y, z), echelle=(0.85, 0.05, 0.13))), biseau=0.01)
    n.forme("Corps", "Lueur", bm_loft([(0.0, 0.065, 0.025), (0.14, 0.005, 0.005)], seg=4,
                                      M=T((x - 0.475, y, z), (0, 0, math.pi / 2))))  # pointe
    n.forme("Corps", "Or", bm_cube(T((x + 0.4, y, z), echelle=(0.05, 0.06, 0.34))), biseau=0.01)  # garde
    n.forme("Corps", "Cuir", bm_loft([(0.0, 0.035, 0.035), (0.26, 0.035, 0.035)], seg=8,
                                     M=T((x + 0.42, y, z), (0, 0, -math.pi / 2))))  # poignée
    n.sphere("Corps", "Or", (x + 0.71, y, z), (0.05, 0.05, 0.05), subdiv=0, u=10, v=6)  # pommeau


def exporter_poses():
    """Écrit src/partage/PosesNains.lua (généré : ne pas modifier à la main)."""
    lignes = ["-- Généré par blender/nains.py (POSES) : ne pas modifier à la main.",
              "-- Angles en radians. Bras = {flexion épaule, rotation épaule, écart épaule, flexion coude, torsion avant-bras}.",
              "return {"]
    for nom, poses in POSES.items():
        lignes.append(f"\t{nom} = {{")
        for nom_p, p in poses.items():
            morceaux = []
            for cote in ("D", "G"):
                if cote in p:
                    morceaux.append(f"{cote} = {{" + ", ".join(f"{a:.4f}" for a in p[cote]) + "}")
            if "tete" in p:
                morceaux.append("tete = {" + ", ".join(f"{a:.4f}" for a in p["tete"]) + "}")
            if "buste" in p:
                morceaux.append(f"buste = {p['buste']:.4f}")
            lignes.append(f"\t\t{nom_p} = {{" + ", ".join(morceaux) + "},")
        lignes.append("\t},")
    lignes.append("}")
    chemin = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "src", "partage", "PosesNains.lua")
    with open(chemin, "w", encoding="utf-8") as f:
        f.write("\n".join(lignes) + "\n")
    print("POSES exportées :", chemin)


def rendu_realiste(nom_fichier, direction, largeur=1600, hauteur=1000):
    """Même cadrage que rendu(), mais éclairé (EEVEE) : lumière chaude de taverne, contre-jour froid."""
    import bpy
    rendu(nom_fichier, direction=direction, largeur=largeur, hauteur=hauteur)  # pose la caméra
    sc = bpy.context.scene
    if not bpy.data.objects.get("SoleilApercu"):
        for nom, energie, rot, coul in (("SoleilApercu", 2.2, (0.9, 0.15, -0.5), (1.0, 0.84, 0.64)),
                                         ("ContreApercu", 4.5, (-1.15, 0.0, 2.7), (0.55, 0.7, 1.0)),
                                         ("BraiseApercu", 1.2, (2.6, 0.0, -0.4), (1.0, 0.45, 0.15))):
            li = bpy.data.lights.new(nom, 'SUN')
            li.energy, li.color, li.angle = energie, coul, 0.35
            ob = bpy.data.objects.new(nom, li)
            ob.rotation_euler = rot
            sc.collection.objects.link(ob)
    w = sc.world
    w.use_nodes = True
    fond = w.node_tree.nodes.get("Background")
    if fond:
        fond.inputs[0].default_value = (0.025, 0.02, 0.018, 1)
        fond.inputs[1].default_value = 0.5
    try:  # halo autour des éléments lumineux
        sc.use_nodes = True
        nt = sc.node_tree
        if not nt.nodes.get("Halo"):
            rl, comp = nt.nodes.get("Render Layers"), nt.nodes.get("Composite")
            g = nt.nodes.new("CompositorNodeGlare")
            g.name = "Halo"
            g.glare_type = 'FOG_GLOW'
            g.threshold = 0.9
            g.size = 7
            nt.links.new(rl.outputs["Image"], g.inputs["Image"])
            nt.links.new(g.outputs["Image"], comp.inputs["Image"])
    except Exception as e:
        print("halo indisponible :", e)
    for moteur in ('BLENDER_EEVEE_NEXT', 'BLENDER_EEVEE'):
        try:
            sc.render.engine = moteur
            break
        except Exception:
            pass
    try:
        sc.view_settings.view_transform = 'Standard'
    except Exception:
        pass
    sc.render.filepath = os.path.join(APERCUS, nom_fichier)
    bpy.ops.render.render(write_still=True)
    print("RENDU REALISTE", sc.render.filepath)


def construire():
    vider()
    tous = []
    for i, (nom, o) in enumerate(NAINS.items()):
        nain = Nain(nom, o, decal=(i * 4.0, 0, 0))
        jambes(nain)
        buste(nain)
        tete(nain)
        tous += nain.finir()
    resoudre_poses(tous)  # a besoin des maillages pour éviter que les bras traversent le corps
    exporter_poses()
    for o in tous:
        if triangles(o) > 2900:
            print("  gros", o.name, triangles(o))
    print("OBJETS", len(tous), "TRIANGLES", sum(triangles(o) for o in tous))
    exporter_fbx("Nains.fbx", tous)
    # aperçu 3D pour l'Atelier (three.js) : blender/apercus/nains.glb
    import bpy
    for ob in bpy.context.scene.objects:
        ob.select_set(ob in tous)
    bpy.ops.export_scene.gltf(filepath=os.path.join(os.path.dirname(os.path.abspath(__file__)), "apercus", "nains.glb"),
                              use_selection=True, export_format='GLB')
    if "--rapide" in sys.argv:  # contrôles des poses : pas besoin des rendus
        return
    rendu("nains_face.png", direction=(-0.3, -1, 0.12))
    rendu("nains_dos.png", direction=(0.5, 1, 0.25), largeur=1400, hauteur=800)
    tetes = [o for o in tous if "_Tete_" in o.name]
    rendu("nains_tetes.png", direction=(-0.25, -1, 0.05), objets=tetes, largeur=1600, hauteur=700)
    rendu_realiste("nains_realiste_face.png", direction=(-0.3, -1, 0.12))
    rendu_realiste("nains_realiste_trois_quarts.png", direction=(0.7, -1, 0.2))


construire()
