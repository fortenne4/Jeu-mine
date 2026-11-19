"""Plaques de lierre modélisées : tiges ramifiées (Skin) + feuilles lobées en coupelle.
Repère L : le mur est le plan x-y (z = 0), le lierre pousse devant (-z).
Variantes : Lierre1..3 (grimpe depuis le bas, y >= 0) et LierreHaut1 (retombe depuis le haut, y <= 0).
Objets : <Variante>_Tiges, _Feuilles, _FeuillesClaires, _FeuillesRousses (couleurs appliquées par le jeu).
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import math, random
import bmesh
from mathutils import Vector, Matrix
from commun import *

TEINTES = {"Tiges": (88, 64, 44), "Feuilles": (46, 72, 36), "FeuillesClaires": (78, 104, 48),
           "FeuillesRousses": (132, 84, 40)}

# Contour d'une feuille de lierre (angle depuis l'axe de la feuille, rayon relatif)
CONTOUR = [(0.0, 1.0), (0.62, 0.5), (1.2, 0.8), (2.0, 0.5), (2.85, 0.2)]
BUDGET = 900  # feuilles max par plaque


def contour():
    pts = []
    for a, r in CONTOUR:
        pts.append((a, r))
    for a, r in reversed(CONTOUR[1:]):
        pts.append((2 * math.pi - a, r))
    return pts  # angles croissants (sens horaire vu de devant => normale vers -z)


def feuille(bm, M, taille):
    c = bm.verts.new(M @ Vector((0, 0.35 * taille, -0.05 * taille)))
    bord = []
    for a, r in contour():
        rr = r * taille
        x, y = rr * math.sin(a), rr * math.cos(a) * 0.95 + 0.25 * taille
        z = 0.05 * taille * (abs(x) / taille) ** 2 * 4  # bords relevés vers le mur => coupelle
        bord.append(bm.verts.new(M @ Vector((x, y, z))))
    n = len(bord)
    for i in range(n):
        bm.faces.new((c, bord[i], bord[(i + 1) % n]))


class Lierre:
    def __init__(self, nom, rng, largeur, hauteur, sens=1):
        self.nom, self.rng, self.L, self.H, self.sens = nom, rng, largeur, hauteur, sens
        self.verts, self.rayons, self.aretes, self.liste = [], [], [], []
        self.feuilles = {"Feuilles": bmesh.new(), "FeuillesClaires": bmesh.new(), "FeuillesRousses": bmesh.new()}

    def point(self, p, r):
        self.verts.append(Vector(p))
        self.rayons.append(r)
        return len(self.verts) - 1

    def tige(self, depart_idx, direction, longueur, epaisseur, profondeur=0):
        rng = self.rng
        idx = depart_idx
        pos = self.verts[idx].copy()
        d = Vector(direction).normalized()
        pas = 0.3
        n = int(longueur / pas)
        for k in range(n):
            vise = Vector((rng.uniform(-1.3, 1.3), self.sens * 0.55, 0))
            # rester dans la largeur de la plaque
            if abs(pos.x) > self.L / 2 * 0.8:
                vise.x -= math.copysign(1.2, pos.x)
            d = (d * 1.6 + vise).normalized()
            d.z = 0
            pos = pos + d * pas
            pos.z = -0.07 + rng.uniform(-0.02, 0.02)
            if self.sens > 0 and pos.y > self.H or self.sens < 0 and pos.y < -self.H:
                break
            avance = k / max(1, n)
            r = max(0.022, epaisseur * (1 - 0.7 * avance))
            nouv = self.point(pos, r)
            self.aretes.append((idx, nouv))
            idx = nouv
            self.garnir(pos, avance, profondeur)
            if profondeur < 3 and rng.random() < (0.3 if profondeur == 0 else 0.2):
                cote = rng.choice((-1, 1))
                nd = Vector((cote * rng.uniform(1.0, 1.8), self.sens * rng.uniform(0.1, 0.6), 0))
                self.tige(idx, nd, longueur * rng.uniform(0.35, 0.65), r * 0.75, profondeur + 1)

    def garnir(self, pos, avance, profondeur):
        rng = self.rng
        for _ in range(rng.randint(3, 4)):
            taille = rng.uniform(0.26, 0.4) * (1.15 - 0.35 * avance) * (1 if profondeur < 2 else 0.85)
            ang = rng.uniform(0, 2 * math.pi)
            off = Vector((math.cos(ang), math.sin(ang), 0)) * rng.uniform(0.1, 0.45)
            p = pos + off
            p.z = -0.12 - rng.uniform(0, 0.16)
            # orientation : axe vers le haut/extérieur, feuille inclinée vers l'avant
            phi = rng.uniform(-1.3, 1.3) + (math.pi if self.sens < 0 and rng.random() < 0.5 else 0)
            incl = rng.uniform(0.35, 0.95)
            M = Matrix.Translation(p) @ Matrix.Rotation(phi, 4, 'Z') @ Matrix.Rotation(-incl, 4, 'X') \
                @ Matrix.Rotation(rng.uniform(-0.3, 0.3), 4, 'Y')
            t = rng.random()
            teinte = "FeuillesRousses" if t < 0.05 else ("FeuillesClaires" if t < 0.35 + 0.25 * avance else "Feuilles")
            self.liste.append((teinte, M, p, taille))

    def construire(self, departs, decal):
        for x, longueur, ep in departs:
            idx = self.point((x, 0 if self.sens > 0 else 0.0, -0.06), ep)
            # quelques feuilles au pied
            self.tige(idx, (self.rng.uniform(-0.3, 0.3), self.sens, 0), longueur, ep)
        # budget de feuilles : on en garde une partie, plus grandes, pour couvrir autant
        liste = self.liste
        k = 1.0
        if len(liste) > BUDGET:
            k = max(1.0, min(1.45, math.sqrt(len(liste) / BUDGET) * 0.85))
            liste = self.rng.sample(liste, BUDGET)
        for teinte, M, p, taille in liste:
            feuille(self.feuilles[teinte], M, taille * k)
        print("  ", self.nom, len(self.liste), "feuilles ->", len(liste), "x", round(k, 2))
        objs = []
        # tiges : tubes à 4 pans (les brindilles trop fines sont ignorées, cachées par les feuilles)
        bm = bmesh.new()
        Z = Vector((0, 0, 1))
        for i, j in self.aretes:
            r = self.rayons[j]
            if r < 0.03:
                continue
            a, b = self.verts[i], self.verts[j]
            d = (b - a)
            if d.length < 1e-4:
                continue
            u = d.normalized().cross(Z).normalized()
            anneaux = []
            for centre, rr in ((a, self.rayons[i]), (b, r)):
                anneaux.append([bm.verts.new(centre + (u * math.cos(t) + Z * math.sin(t)) * rr)
                                for t in (0.0, math.pi / 2, math.pi, 3 * math.pi / 2)])
            A, B = anneaux
            for k in range(4):
                bm.faces.new((A[k], A[(k + 1) % 4], B[(k + 1) % 4], B[k]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        ob = objet(self.nom + "_Tiges", bm, materiau("Tiges", TEINTES["Tiges"]), decal=decal)
        print("   tiges", triangles(ob))
        lisse(ob)
        objs.append(ob)
        for teinte, bm in self.feuilles.items():
            if not bm.verts:
                bm.free()
                continue
            o = objet(f"{self.nom}_{teinte}", bm, materiau(teinte, TEINTES[teinte], 0.55), decal=decal)
            print("  ", o.name, triangles(o))
            lisse(o)
            objs.append(o)
        for o in objs:
            centrer_origine(o)
        return objs


VARIANTES = [
    # nom, graine, largeur, hauteur, sens, départs (x, longueur, épaisseur)
    ("Lierre1", 11, 7, 10, 1, [(-0.8, 10, 0.09), (1.2, 8, 0.07)]),
    ("Lierre2", 23, 10, 7, 1, [(-2.8, 7, 0.08), (0.2, 7, 0.09), (3.0, 5.5, 0.06)]),
    ("Lierre3", 37, 4, 12, 1, [(0.0, 12, 0.1)]),
    ("LierreHaut1", 51, 9, 5, -1, [(-3.0, 4.5, 0.07), (-0.5, 5, 0.08), (2.2, 4, 0.07), (3.8, 3.5, 0.06)]),
]


def construire():
    vider()
    tous = []
    x = 0
    for nom, graine, L, H, sens, departs in VARIANTES:
        l = Lierre(nom, random.Random(graine), L, H, sens)
        tous += l.construire(departs, (-(x + L / 2), 0, 0))
        x += L + 2
    print("OBJETS", len(tous), "TRIANGLES", sum(triangles(o) for o in tous))
    exporter_fbx("Lierre.fbx", tous)
    # mur d'aperçu (non exporté)
    mur = objet("MurApercu", bm_cube(T((x / 2 - 1, 0, 0.3), echelle=(x + 2, 26, 0.5))),
                materiau("Platre", (214, 200, 170)), decal=(0, 0, 0))
    rendu("lierre.png", direction=(-0.35, -1, 0.2), objets=tous + [mur], largeur=1800, hauteur=900)


construire()
