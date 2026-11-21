"""Parois rocheuses stratifiées et vivantes (habillage des falaises autour de la vallée).

    "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" -b --factory-startup --python blender/parois.py

Sortie : assets/Parois.fbx — 4 pans « Paroi1..4 », pièces par teinte :
    RocheChaude, RocheOcre, RocheRose, RocheViolette, Joint (fissures et lits sombres), Mousse, Herbe, Lierre, Buisson, Fleurs
Repère L : face rocheuse tournée vers -z (la vallée), base à y = 0, ~64 de large, ~56 de haut (mis à l'échelle en jeu).
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commun import *

vider()
TEINTES = {
    "RocheChaude": (128, 110, 96), "RocheOcre": (172, 146, 112), "RocheRose": (160, 108, 84),
    "RocheViolette": (96, 88, 106), "Joint": (52, 46, 52), "Mousse": (74, 104, 50), "Herbe": (104, 128, 58),
    "Lierre": (58, 92, 44), "Buisson": (66, 96, 52), "Fleurs": (226, 150, 190),
}
STRATES = ["RocheChaude", "RocheOcre", "RocheChaude", "RocheRose", "RocheViolette", "RocheOcre", "RocheChaude", "RocheRose"]


class Atelier:
    def __init__(self, prefixe):
        self.prefixe = prefixe
        self.bms = {}

    def bm(self, t):
        return self.bms.setdefault(t, bmesh.new())

    def cube(self, t, c, s, rot=(0, 0, 0)):
        M = Matrix.Translation(Vector(c)) @ Euler(rot, 'XYZ').to_matrix().to_4x4() @ Matrix.Diagonal((s[0], s[1], s[2], 1))
        bmesh.ops.create_cube(self.bm(t), size=1.0, matrix=M)

    def boule(self, t, c, s, graine):
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
        for v in bm.verts:
            f = 1 + 0.25 * noise.noise(v.co * 2.5 + Vector((graine, graine, graine)))
            v.co = Vector((v.co.x * s[0] * f, v.co.y * s[1] * f, v.co.z * s[2] * f)) + Vector(c)
        self.fondre(t, bm)

    def fondre(self, t, src):
        dst = self.bm(t)
        vmap = {v: dst.verts.new(v.co) for v in src.verts}
        for f in src.faces:
            try:
                dst.faces.new([vmap[v] for v in f.verts])
            except ValueError:
                pass
        src.free()

    def objets(self):
        objs = []
        for t, bm in sorted(self.bms.items()):
            if not bm.verts:
                continue
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            ob = objet(f"{self.prefixe}_{t}", bm, materiau(t, TEINTES[t], 0.95))
            centrer_origine(ob)
            objs.append(ob)
        return objs


def paroi(idx, graine, W=64.0, nb=8, decal_x=0.0):
    rng = random.Random(graine * 1000)
    A = Atelier(f"Paroi{idx}")
    N = 30          # colonnes
    D = 24.0        # profondeur (dos dans la montagne : enfoui dans le relief en jeu)
    y = 0.0
    fronts = []     # par strate : (y0, y1, [z avant par colonne])
    xs = [(-W / 2 + W * i / N) for i in range(N + 1)]
    # silhouette : la paroi s'abaisse sur les bords (forme de dent)
    def hmax(x):
        u = x / (W / 2)
        return 1 - 0.45 * u * u + 0.12 * noise.noise(Vector((u * 3, graine, 0.5)))

    hauteur_totale = 0
    for j in range(nb):
        ep = rng.uniform(4.5, 8.5)
        y0, y1 = y, y + ep
        recul = j * 1.9 + rng.uniform(-1.4, 1.4)           # la paroi se couche en montant (suit la pente)
        zf = []
        for i, x in enumerate(xs):
            n = noise.noise(Vector((x * 0.09 + graine, j * 0.7, graine * 2)))
            n2 = noise.noise(Vector((x * 0.31 + graine * 3, j * 1.3, 1.7)))
            z = -D / 2 + recul + 3.2 * n + 1.1 * n2
            # bords biseautés : la face rentre dans la montagne sur les côtés (plus de flanc plat visible)
            u = abs(x) / (W / 2)
            bord = max(0.0, min(1.0, (u - 0.55) / 0.45))
            bord = bord * bord * (3 - 2 * bord)
            zf.append(z * (1 - bord) + (D / 2 - 1.0) * bord)
        fronts.append((y0, y1, zf))
        y = y1 + rng.uniform(0.0, 0.5)
        hauteur_totale = y1

    for j, (y0, y1, zf) in enumerate(fronts):
        t = STRATES[(j + idx) % len(STRATES)]
        bm = bmesh.new()
        lignes = []
        for r, yy in enumerate((y0, (y0 + y1) / 2, y1)):
            ligne = []
            for i, x in enumerate(xs):
                h = hmax(x) * hauteur_totale
                yv = min(yy, h)
                bossage = 0.9 * noise.noise(Vector((x * 0.4, yy * 0.5, graine + j)))   # relief de la face
                ligne.append(bm.verts.new((x, yv, zf[i] + bossage - (0.6 if r == 1 else 0))))
            lignes.append(ligne)
        dos = [[bm.verts.new((x, min(yy, hmax(x) * hauteur_totale), D / 2)) for x in xs] for yy in (y0, y1)]
        for r in range(2):
            for i in range(N):
                bm.faces.new((lignes[r][i], lignes[r][i + 1], lignes[r + 1][i + 1], lignes[r + 1][i]))
        for i in range(N):
            bm.faces.new((lignes[2][i], lignes[2][i + 1], dos[1][i + 1], dos[1][i]))      # dessus
            bm.faces.new((dos[0][i], dos[0][i + 1], lignes[0][i + 1], lignes[0][i]))      # dessous
            bm.faces.new((dos[0][i + 1], dos[0][i], dos[1][i], dos[1][i + 1]))            # dos
        for i in (0, N):
            bm.faces.new((lignes[0][i], lignes[1][i], lignes[2][i], dos[1][i], dos[0][i]))
        A.fondre(t, bm)

        # lit sombre entre deux strates (joint)
        for i in range(N):
            x = (xs[i] + xs[i + 1]) / 2
            if y1 < hmax(x) * hauteur_totale - 1 and abs(x) < W * 0.29:   # pas sur les bords biseautés
                A.cube("Joint", (x, y1 + 0.05, zf[i] + 0.6), (W / N + 0.05, 0.45, 1.4))

        # corniche : mousse et herbe là où la strate dépasse de celle du dessus
        if j + 1 < len(fronts):
            zs = fronts[j + 1][2]
            for i in range(N):
                x = (xs[i] + xs[i + 1]) / 2
                avance = zs[i] - zf[i]
                if avance > 0.8 and y1 < hmax(x) * hauteur_totale - 1 and abs(x) < W * 0.3:
                    A.cube("Mousse", (x, y1 + 0.25, zf[i] + avance / 2), (W / N * 1.05, 0.5, avance + 0.3),
                           rot=(rng.uniform(-0.05, 0.05), 0, rng.uniform(-0.05, 0.05)))
                    if rng.random() < 0.55:                       # touffes d'herbe
                        for _ in range(rng.randint(1, 3)):
                            A.cube("Herbe", (x + rng.uniform(-1, 1), y1 + 0.9, zf[i] + rng.uniform(0.2, avance)),
                                   (0.35, rng.uniform(0.9, 1.8), 0.35), rot=(rng.uniform(-0.4, 0.4), rng.uniform(0, 3), rng.uniform(-0.4, 0.4)))
                    if rng.random() < 0.12:                       # buisson
                        A.boule("Buisson", (x, y1 + 1.6, zf[i] + avance * 0.5), (rng.uniform(1.6, 2.6), rng.uniform(1.2, 1.8), 1.6), rng.random() * 9)
                        if rng.random() < 0.6:
                            for _ in range(rng.randint(3, 6)):
                                A.cube("Fleurs", (x + rng.uniform(-1.8, 1.8), y1 + rng.uniform(1.8, 3), zf[i] + rng.uniform(-0.6, 0.6) + avance * 0.3),
                                       (0.45, 0.45, 0.45))
                    if rng.random() < 0.16:                       # lierre qui pend de la corniche
                        L = rng.uniform(4, 14)
                        xx, zz = x, zf[i] - 0.3
                        k = 0
                        while k < L:
                            s = rng.uniform(0.9, 1.6)
                            xx += rng.uniform(-0.35, 0.35)
                            A.cube("Lierre", (xx, y1 - k - s / 2, zz - 0.2 + rng.uniform(-0.2, 0.2)),
                                   (rng.uniform(0.9, 1.7), s, 0.35), rot=(0, 0, rng.uniform(-0.3, 0.3)))
                            k += s * 0.85

    # fissures verticales (failles sombres qui coupent plusieurs strates)
    for _ in range(rng.randint(3, 5)):
        x = rng.uniform(-W * 0.24, W * 0.24)
        i = min(N - 1, max(0, int((x + W / 2) / W * N)))
        j0 = rng.randrange(0, max(1, len(fronts) - 3))
        for j in range(j0, min(len(fronts), j0 + rng.randint(2, 4))):
            y0, y1, zf = fronts[j]
            A.cube("Joint", (x + rng.uniform(-0.4, 0.4), (y0 + y1) / 2, zf[i] - 0.15), (0.7, y1 - y0 + 0.3, 1.4),
                   rot=(0, 0, rng.uniform(-0.15, 0.15)))
    # éboulis au pied
    for _ in range(rng.randint(6, 10)):
        A.boule(rng.choice(STRATES), (rng.uniform(-W * 0.4, W * 0.4), rng.uniform(0.5, 1.5), -D / 2 - rng.uniform(1, 6)),
                (rng.uniform(1.2, 3.2), rng.uniform(0.8, 2), rng.uniform(1.2, 3)), rng.random() * 20)

    objs = A.objets()
    for o in objs:
        o.location.x += decal_x
    return objs


objs = []
for idx, graine in ((1, 1.1), (2, 2.7), (3, 4.3), (4, 6.9)):
    objs += paroi(idx, graine, nb=7 + idx % 3, decal_x=(idx - 2.5) * 80)
for o in objs:
    n = triangles(o)
    if n > 19000:
        print("  ATTENTION", o.name, n)
exporter_fbx("Parois.fbx", objs)
try:
    rendu("parois.png", direction=(0.15, -1.0, 0.3), objets=objs)
    rendu("parois_34.png", direction=(-0.7, -0.7, 0.35), objets=[o for o in objs if o.name.startswith("Paroi2")])
except Exception as e:
    print("rendu impossible :", e)
print("FIN", len(objs), "pièces", sum(triangles(o) for o in objs), "triangles")
