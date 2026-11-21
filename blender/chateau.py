"""Château fort des montagnes (décor de bordure de carte), style médiéval fantastique.

    "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" -b --factory-startup --python blender/chateau.py

Sortie : assets/Chateau.fbx (pièces « Chateau_<Groupe>_<Teinte> », colorées en jeu par la teinte)
         blender/apercus/chateau_*.png (aperçus).
Repère L (commun.py) : x = droite, y = haut, -z = façade (tournée vers le village). 1 unité = 1 stud.
Taille : ~150 × 130 studs au sol, flèche à ~125 studs. Base du château à y = 0 ; le socle rocheux descend sous 0.
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commun import *

vider()
ID = "Chateau"
TEINTES = {
    "Pierre": (128, 120, 132), "PierreSombre": (86, 80, 94), "PierreClaire": (164, 156, 166),
    "Roche": (92, 86, 96), "Ardoise": (58, 54, 82), "ArdoiseClaire": (82, 76, 112),
    "Bois": (86, 58, 40), "Fer": (44, 44, 50), "Or": (236, 180, 80),
    "Lumiere": (255, 190, 100), "Banniere": (122, 34, 52), "Lierre": (60, 96, 46),
}
rng = random.Random(4242)


class Atelier:
    """Un bmesh par (groupe, teinte) → une MeshPart par couple."""

    def __init__(self):
        self.bms = {}

    def bm(self, g, t):
        return self.bms.setdefault((g, t), bmesh.new())

    def cube(self, g, t, c, s, rot=(0, 0, 0)):
        M = Matrix.Translation(Vector(c)) @ Euler(rot, 'XYZ').to_matrix().to_4x4() @ Matrix.Diagonal((s[0], s[1], s[2], 1))
        bmesh.ops.create_cube(self.bm(g, t), size=1.0, matrix=M)

    def cylindre(self, g, t, c, r, h, seg=24, r2=None, rot=(0, 0, 0)):
        """Cylindre (ou tronc de cône si r2) debout, base en c."""
        M = Matrix.Translation(Vector(c) + Vector((0, h / 2, 0))) @ Euler(rot, 'XYZ').to_matrix().to_4x4() \
            @ Euler((-math.pi / 2, 0, 0), "XYZ").to_matrix().to_4x4()
        bmesh.ops.create_cone(self.bm(g, t), cap_ends=True, cap_tris=False, segments=seg,
                              radius1=r, radius2=r if r2 is None else r2, depth=h, matrix=M)

    def cone(self, g, t, c, r, h, seg=24):
        M = Matrix.Translation(Vector(c) + Vector((0, h / 2, 0))) @ Euler((-math.pi / 2, 0, 0), "XYZ").to_matrix().to_4x4()
        bmesh.ops.create_cone(self.bm(g, t), cap_ends=True, cap_tris=True, segments=seg,
                              radius1=r, radius2=0.0, depth=h, matrix=M)

    def pyramide(self, g, t, c, lx, lz, h):
        bm = self.bm(g, t)
        x, y, z = c
        b = [bm.verts.new((x + sx * lx / 2, y, z + sz * lz / 2)) for sx, sz in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        s = bm.verts.new((x, y + h, z))
        for i in range(4):
            bm.faces.new((b[i], b[(i + 1) % 4], s))
        bm.faces.new(list(reversed(b)))

    def toit2pans(self, g, t, c, lx, lz, h, debord=1.5):
        """Toit à deux pans, faîtage selon x."""
        bm = self.bm(g, t)
        x, y, z = c
        hx, hz = lx / 2 + debord, lz / 2 + debord
        p = [bm.verts.new(v) for v in ((x - hx, y, z - hz), (x + hx, y, z - hz), (x + hx, y, z + hz), (x - hx, y, z + hz),
                                        (x - hx, y + h, z), (x + hx, y + h, z))]
        for f in ((0, 1, 5, 4), (2, 3, 4, 5), (0, 4, 3), (1, 2, 5), (0, 3, 2, 1)):
            bm.faces.new([p[i] for i in f])

    def objets(self):
        objs = []
        for (g, t), bm in sorted(self.bms.items()):
            if not bm.verts:
                continue
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            ob = objet(f"{ID}_{g}_{t}", bm, materiau(t, TEINTES[t], 0.85))
            n = triangles(ob)
            if n > 19500:
                print("  ATTENTION", ob.name, n, "triangles")
            centrer_origine(ob)
            objs.append(ob)
        return objs


A = Atelier()


# ---------------- éléments ----------------

def creneaux_droits(g, a, b, y, ep, h=3.2, pas=4.2):
    """Merlons le long du segment a→b (au sommet y d'un mur d'épaisseur ep)."""
    a, b = Vector(a), Vector(b)
    d = b - a
    L = d.length
    u = d.normalized()
    ang = math.atan2(-u.z, u.x)
    n = max(1, int(L / pas))
    for i in range(n):
        if i % 2 == 0:
            c = a + u * ((i + 0.5) * L / n)
            A.cube(g, "Pierre", (c.x, y + h / 2, c.z), (L / n * 0.98, h, ep), rot=(0, ang, 0))
    # parapet bas continu
    m = (a + b) / 2
    A.cube(g, "PierreClaire", (m.x, y + 0.4, m.z), (L + ep, 0.8, ep + 0.8), rot=(0, ang, 0))


def mur(g, a, b, h, ep=5.0, fentes=True):
    a, b = Vector(a), Vector(b)
    d = b - a
    L = d.length
    u = d.normalized()
    ang = math.atan2(-u.z, u.x)
    m = (a + b) / 2
    A.cube(g, "Pierre", (m.x, h / 2 - 6, m.z), (L, h + 12, ep), rot=(0, ang, 0))
    # assise de base plus large (talus) et cordon
    A.cube(g, "PierreSombre", (m.x, 2, m.z), (L, 8, ep + 2.4), rot=(0, ang, 0))
    A.cube(g, "PierreClaire", (m.x, h - 1.2, m.z), (L, 1.0, ep + 1.2), rot=(0, ang, 0))
    # pierres saillantes (usure) sur la face extérieure
    nrm = Vector((u.z, 0, -u.x))
    for _ in range(int(L / 3)):
        t = rng.uniform(0.05, 0.95)
        c = a + d * t + nrm * (ep / 2 + 0.15)
        A.cube(g, rng.choice(("PierreSombre", "PierreClaire")), (c.x, rng.uniform(5, h - 4), c.z),
               (rng.uniform(1.5, 3.2), rng.uniform(0.8, 1.5), 0.5), rot=(0, ang, 0))
    if fentes:
        for i in range(1, int(L / 10)):
            c = a + u * (i * L / int(L / 10)) + nrm * (ep / 2 + 0.05)
            A.cube(g, "Fer", (c.x, h * 0.6, c.z), (0.6, 3.2, 0.3), rot=(0, ang, 0))
    creneaux_droits(g, a + nrm * (ep / 2 - 0.6), b + nrm * (ep / 2 - 0.6), h, 1.2)


def machicoulis(g, c, r, y, n=20):
    """Couronne de corbeaux sous le crénelage d'une tour ronde."""
    x, _, z = c
    A.cylindre(g, "PierreClaire", (x, y, z), r + 1.4, 2.2, seg=28)
    for i in range(n):
        a = i / n * 2 * math.pi
        A.cube(g, "PierreSombre", (x + math.cos(a) * (r + 0.6), y - 1.6, z + math.sin(a) * (r + 0.6)),
               (1.0, 2.2, 1.6), rot=(0, -a, 0))


def creneaux_ronds(g, c, r, y, n=16, h=3.2):
    x, _, z = c
    for i in range(n):
        if i % 2 == 0:
            a = (i + 0.5) / n * 2 * math.pi
            A.cube(g, "Pierre", (x + math.cos(a) * r, y + h / 2, z + math.sin(a) * r),
                   (2 * math.pi * r / n * 0.95, h, 1.3), rot=(0, -a + math.pi / 2, 0))


def fenetres_tour(g, c, r, y0, y1, n=3, larg=1.4, haut=3.4, decal=0.0):
    x, _, z = c
    for k in range(n):
        a = decal + k / n * 2 * math.pi
        y = y0 + (y1 - y0) * ((k * 0.37) % 1)
        px, pz = x + math.cos(a) * (r + 0.05), z + math.sin(a) * (r + 0.05)
        A.cube(g, "Lumiere", (px, y, pz), (larg, haut, 0.4), rot=(0, -a + math.pi / 2, 0))
        A.cube(g, "PierreClaire", (px, y + haut / 2 + 0.4, pz), (larg + 0.8, 0.6, 0.7), rot=(0, -a + math.pi / 2, 0))


def banniere(g, c, h=10, larg=3.2, dir_a=0.0):
    x, y, z = c
    A.cylindre(g, "Fer", (x, y, z), 0.18, h, seg=6)
    A.cube(g, "Banniere", (x + math.cos(dir_a) * larg / 2, y + h - 2.6, z + math.sin(dir_a) * larg / 2),
           (larg, 4.4, 0.15), rot=(0, -dir_a, rng.uniform(-0.05, 0.05)))
    A.cube(g, "Or", (x, y + h + 0.3, z), (0.6, 0.6, 0.6))


def tour_ronde(g, c, r, h, toit=True, couleur_toit="Ardoise"):
    x, y, z = c
    A.cylindre(g, "PierreSombre", (x, y - 14, z), r + 1.6, 16, seg=28, r2=r + 0.6)  # talus
    A.cylindre(g, "Pierre", (x, y, z), r, h, seg=28)
    A.cylindre(g, "PierreClaire", (x, y + h * 0.45, z), r + 0.35, 0.8, seg=28)    # cordon
    fenetres_tour(g, (x, y, z), r, y + h * 0.35, y + h * 0.8, n=4, decal=rng.uniform(0, 6))
    machicoulis(g, (x, y, z), r, y + h)
    if toit:
        A.cylindre(g, "Pierre", (x, y + h + 1.1, z), r + 0.6, 3.0, seg=28)
        hr = r * 2.6
        A.cone(g, couleur_toit, (x, y + h + 4.1, z), r + 2.4, hr, seg=28)
        # coyau : bas du toit retroussé
        A.cylindre(g, couleur_toit, (x, y + h + 3.4, z), r + 2.9, 0.8, seg=28, r2=r + 2.3)
        A.cube(g, "Or", (x, y + h + 4.1 + hr + 0.4, z), (0.8, 0.8, 0.8))
        banniere(g, (x, y + h + 4.1 + hr - 0.2, z), h=6, larg=3, dir_a=rng.uniform(0, 6.28))
        # lucarne
        a = rng.uniform(0, 6.28)
        lx, lz = x + math.cos(a) * (r + 0.4), z + math.sin(a) * (r + 0.4)
        A.cube(g, "Lumiere", (lx, y + h + 7, lz), (1.4, 2.2, 0.5), rot=(0, -a + math.pi / 2, 0))
    else:
        A.cylindre(g, "Pierre", (x, y + h + 1.1, z), r + 1.1, 0.4, seg=28)
        creneaux_ronds(g, (x, y, z), r + 0.9, y + h + 1.1)


def fenetre_gothique(g, c, ang, larg=2.6, haut=7.0):
    x, y, z = c
    A.cube(g, "Lumiere", (x, y, z), (larg, haut, 0.4), rot=(0, ang, 0))
    # ogive : petit losange au-dessus
    A.cube(g, "Lumiere", (x, y + haut / 2, z), (larg * 0.72, larg * 0.72, 0.4), rot=(0, ang, 0) if False else (0, ang, 0))
    A.cube(g, "PierreClaire", (x, y - haut / 2 - 0.4, z), (larg + 1.0, 0.7, 0.9), rot=(0, ang, 0))
    A.cube(g, "Fer", (x, y, z), (0.25, haut, 0.5), rot=(0, ang, 0))


# ---------------- plan ----------------
# Enceinte : hexagone irrégulier ; façade (porte) au sud (-z)
ENCEINTE = [(-58, 0, -40), (-14, 0, -52), (14, 0, -52), (58, 0, -40), (66, 0, 30), (20, 0, 62), (-20, 0, 62), (-66, 0, 30)]
H_MUR = 30

# Socle rocheux sous le château (rattrape le relief)
def rocher_socle(c, s, graine):
    """Bloc de roche irrégulier (icosphère bosselée par du bruit, dessus aplati sous les murs)."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=3, radius=1.0)
    for v in bm.verts:
        n = noise.noise(v.co * 2.2 + Vector((graine, graine * 0.7, graine * 1.3)))
        f = 1 + 0.28 * n + 0.1 * noise.noise(v.co * 6 + Vector((graine,) * 3))
        p = Vector((v.co.x * s[0] * f, v.co.y * s[1] * f, v.co.z * s[2] * f)) + Vector(c)
        p.y = min(p.y, -0.5)                      # rien ne dépasse au-dessus du sol du château
        v.co = p
    A.fondre_bm("Socle", "Roche", bm)


def _fondre_bm(g, t, src):
    dst = A.bm(g, t)
    vmap = {v: dst.verts.new(v.co) for v in src.verts}
    for f in src.faces:
        try:
            dst.faces.new([vmap[v] for v in f.verts])
        except ValueError:
            pass
    src.free()


A.fondre_bm = _fondre_bm
rocher_socle((0, -26, 6), (74, 34, 64), 1.7)
for i in range(9):
    a = i / 9 * 2 * math.pi + rng.uniform(-0.2, 0.2)
    rocher_socle((math.cos(a) * 58, -30 + rng.uniform(-6, 4), math.sin(a) * 52 + 6),
                 (rng.uniform(16, 24), rng.uniform(22, 32), rng.uniform(16, 24)), 3.1 + i)

# Remparts (sauf le segment de la porte)
for i in range(len(ENCEINTE)):
    a, b = ENCEINTE[i], ENCEINTE[(i + 1) % len(ENCEINTE)]
    if i == 1:
        continue  # châtelet
    mur("Remparts", a, b, H_MUR)

# Tours d'angle
for i, p in enumerate(ENCEINTE):
    if i in (1, 2):
        continue
    r = 8.5 if i in (0, 3) else 7.5
    tour_ronde("Tours", p, r, H_MUR + rng.uniform(12, 20), toit=(i % 2 == 0) or i == 3,
               couleur_toit="Ardoise" if i % 3 else "ArdoiseClaire")

# ---- Châtelet (porte d'entrée) ----
G = "Chatelet"
for sx in (-1, 1):
    tour_ronde(G, (sx * 14, 0, -52), 7.5, H_MUR + 14, toit=True)
A.cube(G, "Pierre", (0, (H_MUR + 8) / 2 - 6, -52), (22, H_MUR + 8 + 12, 12))
A.cube(G, "PierreSombre", (0, 2, -52), (22, 8, 14))
creneaux_droits(G, (-11, 0, -58.2), (11, 0, -58.2), H_MUR + 8, 1.2)
# arche et porte
A.cube(G, "Fer", (0, 8, -58.3), (9, 16, 0.6))              # fond sombre de l'arche
for k in range(-4, 5):                                       # herse
    A.cube(G, "Fer", (k * 1.1, 8.5, -58.7), (0.35, 15, 0.35))
for k in range(1, 7):
    A.cube(G, "Fer", (0, k * 2.4, -58.7), (9, 0.35, 0.35))
A.cube(G, "PierreClaire", (0, 17, -58.6), (12, 2.2, 1.2))    # linteau
A.cube(G, "PierreClaire", (-5.6, 8, -58.6), (2, 18, 1.2))
A.cube(G, "PierreClaire", (5.6, 8, -58.6), (2, 18, 1.2))
# pont-levis abaissé + chaînes
for k in range(7):
    A.cube(G, "Bois", (-3.6 + k * 1.2, 0.3, -66), (1.1, 0.6, 15))
A.cube(G, "Fer", (-4.6, 0.6, -66), (0.4, 0.4, 15))
A.cube(G, "Fer", (4.6, 0.6, -66), (0.4, 0.4, 15))
for sx in (-1, 1):
    A.cube(G, "Fer", (sx * 4.6, 9, -66), (0.3, 18.5, 0.3), rot=(0.9, 0, 0))
# armoiries et fenêtres au-dessus de la porte
A.cube(G, "Banniere", (0, 26, -58.4), (5, 6, 0.3))
A.cube(G, "Or", (0, 26, -58.6), (2, 2, 0.3), rot=(0, 0, math.pi / 4))
for sx in (-1, 1):
    fenetre_gothique(G, (sx * 6, 25, -58.3), 0, larg=1.8, haut=4.5)
# lanternes de part et d'autre de la porte
for sx in (-1, 1):
    A.cube(G, "Fer", (sx * 7.5, 11, -59), (0.3, 0.3, 1.2))
    A.cube(G, "Lumiere", (sx * 7.5, 10, -59.6), (1.0, 1.5, 1.0))

# ---- Grande salle (nord-ouest de la cour) ----
G = "Salle"
A.cube(G, "Pierre", (-22, 13, 24), (44, 26 + 12, 22))
A.cube(G, "PierreSombre", (-22, 1, 24), (46, 6, 24))
A.toit2pans(G, "Ardoise", (-22, 32, 24), 44, 22, 16)
for k in range(5):
    fenetre_gothique(G, (-40 + k * 9, 16, 12.8), 0, larg=2.6, haut=8)
for sx in (-44, 0):                                          # contreforts
    for k in range(4):
        A.cube(G, "PierreSombre", (-40 + k * 12 + 3, 10, 12.2), (2, 20, 2.6))
A.cube(G, "Pierre", (-34, 44, 30), (3.5, 14, 3.5))         # cheminée
A.cube(G, "PierreClaire", (-34, 51.5, 30), (4.5, 1.2, 4.5))

# ---- Donjon (au fond, au centre-est) ----
G = "Donjon"
DX, DZ = 18, 30
A.cube(G, "Pierre", (DX, 34, DZ), (30, 80, 30))
A.cube(G, "PierreSombre", (DX, 2, DZ), (34, 10, 34))
for y in (24, 50):
    A.cube(G, "PierreClaire", (DX, y, DZ), (31, 1, 31))
A.cube(G, "PierreClaire", (DX, 73.6, DZ), (33, 2.4, 33))
for (sx, sz) in ((-1, -1), (1, -1), (1, 1), (-1, 1)):    # corbeaux sous le crénelage
    pass
for k in range(12):
    t = (k + 0.5) / 12 * 30 - 15
    for (cx, cz, rot) in ((DX + t, DZ - 15.6, 0), (DX + t, DZ + 15.6, 0), (DX - 15.6, DZ + t, math.pi / 2), (DX + 15.6, DZ + t, math.pi / 2)):
        A.cube(G, "PierreSombre", (cx, 71.6, cz), (1.0, 2.2, 1.6), rot=(0, rot, 0))
creneaux_droits(G, (DX - 16, 0, DZ - 16), (DX + 16, 0, DZ - 16), 74.8, 1.2)
creneaux_droits(G, (DX + 16, 0, DZ - 16), (DX + 16, 0, DZ + 16), 74.8, 1.2)
creneaux_droits(G, (DX + 16, 0, DZ + 16), (DX - 16, 0, DZ + 16), 74.8, 1.2)
creneaux_droits(G, (DX - 16, 0, DZ + 16), (DX - 16, 0, DZ - 16), 74.8, 1.2)
# toit en pavillon au centre du donjon
A.cube(G, "Pierre", (DX, 80, DZ), (20, 10, 20))
A.pyramide(G, "Ardoise", (DX, 85, DZ), 24, 24, 22)
A.cube(G, "Or", (DX, 107.5, DZ), (1, 1, 1))
banniere(G, (DX, 107, DZ), h=9, larg=4.5, dir_a=0.6)
# fenêtres du donjon (façade sud et côtés)
for y in (32, 44, 58):
    for k in (-1, 0, 1):
        fenetre_gothique(G, (DX + k * 8, y, DZ - 15.25), 0, larg=2.0, haut=5.5)
        fenetre_gothique(G, (DX - 15.25, y, DZ + k * 8), math.pi / 2, larg=2.0, haut=5.5)
# échauguettes aux 4 coins
for (sx, sz) in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
    cx, cz = DX + sx * 15.5, DZ + sz * 15.5
    A.cylindre(G, "Pierre", (cx, 62, cz), 3.2, 14, seg=16, r2=3.2)
    A.cylindre(G, "PierreSombre", (cx, 58, cz), 0.6, 4.2, seg=16, r2=3.2)
    A.cone(G, "ArdoiseClaire", (cx, 76, cz), 4.2, 10, seg=16)
    A.cube(G, "Lumiere", (cx + sx * 3.2, 68, cz), (0.4, 2.2, 1.0))

# ---- Tour du mage : fine et très haute, à l'est ----
G = "TourMage"
MX, MZ = 46, -6
A.cylindre(G, "PierreClaire", (MX, 0, MZ), 6.5, 92, seg=24, r2=5.2)
for y in (20, 40, 60, 80):
    A.cylindre(G, "Pierre", (MX, y, MZ), 6.9 - y * 0.014, 1.0, seg=24)
fenetres_tour(G, (MX, 0, MZ), 5.8, 20, 85, n=7, larg=1.2, haut=3.0)
A.cylindre(G, "Pierre", (MX, 92, MZ), 7.6, 4, seg=24)
machicoulis(G, (MX, 0, MZ), 6.6, 92, n=18)
A.cylindre(G, "Lumiere", (MX, 96, MZ), 4.6, 6, seg=16)       # lanterne vitrée au sommet
for k in range(8):
    a = k / 8 * 2 * math.pi
    A.cube(G, "Pierre", (MX + math.cos(a) * 4.8, 99, MZ + math.sin(a) * 4.8), (1.0, 6, 1.0))
A.cone(G, "ArdoiseClaire", (MX, 102, MZ), 7.4, 24, seg=24)
A.cube(G, "Or", (MX, 126.5, MZ), (0.9, 0.9, 0.9))
banniere(G, (MX, 125.5, MZ), h=7, larg=4, dir_a=2.4)

# ---- Courtine intérieure, escaliers, lierre ----
G = "Details"
for k in range(10):                                           # escalier vers le chemin de ronde
    A.cube(G, "PierreSombre", (-50 + k * 1.6, k * 2.4 + 1, -30 + k * 0.4), (2.6, 2.4 + k * 0.02, 6))
for _ in range(26):                                           # lierre grimpant sur les remparts
    i = rng.randrange(len(ENCEINTE))
    a, b = Vector(ENCEINTE[i]), Vector(ENCEINTE[(i + 1) % len(ENCEINTE)])
    if i == 1:
        continue
    t = rng.uniform(0.1, 0.9)
    p = a + (b - a) * t
    u = (b - a).normalized()
    nrm = Vector((u.z, 0, -u.x))
    ang = math.atan2(-u.z, u.x)
    h = rng.uniform(6, 20)
    for k in range(int(h / 2)):
        q = p + nrm * 2.75 + u * rng.uniform(-1.5, 1.5)
        A.cube(G, "Lierre", (q.x, k * 2 + rng.uniform(0, 1), q.z), (rng.uniform(2, 4.5), rng.uniform(1.6, 3), 0.5),
               rot=(0, ang, rng.uniform(-0.4, 0.4)))
for _ in range(14):                                           # braseros sur le chemin de ronde
    i = rng.randrange(len(ENCEINTE))
    if i == 1:
        continue
    a, b = Vector(ENCEINTE[i]), Vector(ENCEINTE[(i + 1) % len(ENCEINTE)])
    p = a + (b - a) * rng.uniform(0.2, 0.8)
    A.cylindre(G, "Fer", (p.x, H_MUR, p.z), 0.9, 1.4, seg=8, r2=1.3)
    A.cylindre(G, "Lumiere", (p.x, H_MUR + 1.4, p.z), 1.1, 0.8, seg=8, r2=0.4)


objs = A.objets()
exporter_fbx("Chateau.fbx", objs)
try:
    rendu("chateau_face.png", direction=(0.25, -1.0, 0.35), objets=objs)
    rendu("chateau_34.png", direction=(-0.8, -0.8, 0.5), objets=objs)
except Exception as e:
    print("rendu impossible :", e)
print("FIN", len(objs), "pièces", sum(triangles(o) for o in objs), "triangles")
