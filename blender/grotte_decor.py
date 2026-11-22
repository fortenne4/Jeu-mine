"""Décor modélisé des grottes profondes : stalactites, stalagmites, colonnes, cristaux, champignons lumineux.

    "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" -b --factory-startup --python blender/grotte_decor.py

Sortie : assets/GrotteDecor.fbx — pièces « <Prefixe>_<Teinte> » (couleurs appliquées par le jeu selon le niveau) :
    Stalactite1..3_Roche / _Goutte      pointe vers le bas, base (plafond) à y = 0, ~10 de long
    Stalagmite1..3_Roche                pointe vers le haut, base (sol) à y = 0, ~8 de haut
    Colonne1..2_Roche                   colonne sol → plafond (sablier), base à y = 0, 20 de haut
    Cristal1..3_Cristal / _Socle        grappe de prismes sur un socle de roche, base à y = 0
    Champignon1..3_Pied / _Chapeau / _Lueur   touffe de champignons bioluminescents, base à y = 0
Repère L (commun.py). Formes organiques : anneaux bruités puis bosselés au bruit 3D.
"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commun import *

vider()
TEINTES = {"Roche": (110, 108, 112), "Goutte": (170, 210, 230), "Cristal": (120, 210, 255), "Socle": (70, 68, 74),
           "Pied": (214, 206, 186), "Chapeau": (60, 120, 150), "Lueur": (120, 255, 230)}
rng = random.Random(777)


def bosseler(bm, force, freq, graine, axe_y=True):
    o = Vector((graine * 3.1, graine * 1.7, graine * 2.3))
    for v in bm.verts:
        n = noise.noise(v.co * freq + o)
        radial = Vector((v.co.x, 0, v.co.z))
        if radial.length > 1e-4:
            v.co += radial.normalized() * n * force
        v.co.y += noise.noise(v.co * freq * 0.7 + o * 2) * force * 0.3


class Piece:
    def __init__(self, prefixe):
        self.prefixe = prefixe
        self.bms = {}

    def ajouter(self, t, bm):
        dst = self.bms.setdefault(t, bmesh.new())
        vmap = {v: dst.verts.new(v.co) for v in bm.verts}
        for f in bm.faces:
            try:
                dst.faces.new([vmap[v] for v in f.verts])
            except ValueError:
                pass
        bm.free()

    def objets(self, decal):
        objs = []
        for t, bm in self.bms.items():
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            ob = objet(f"{self.prefixe}_{t}", bm, materiau(t, TEINTES[t], 0.6 if t in ("Cristal", "Goutte", "Lueur") else 0.9),
                       decal=decal)
            lisse(ob, 50)
            centrer_origine(ob)
            objs.append(ob)
        return objs


def pointe_organique(hauteur, rayon, sens, graine, anneaux=9, seg=12, renflement=0.0):
    """Cône irrégulier (sens -1 : pend du plafond ; +1 : pousse du sol). Base à y = 0."""
    r = random.Random(graine)
    pts = []
    for i in range(anneaux):
        u = i / (anneaux - 1)
        rr = rayon * ((1 - u) ** 1.35) * (1 + 0.18 * math.sin(u * 9 + graine)) + 0.04
        if renflement and u < 0.25:
            rr *= 1 + renflement * (0.25 - u) * 4
        cx = 0.15 * rayon * math.sin(u * 3 + graine) * u
        cz = 0.15 * rayon * math.cos(u * 2.4 + graine) * u
        pts.append((sens * hauteur * u, rr * r.uniform(0.92, 1.08), rr * r.uniform(0.85, 1.05), cx, cz))
    if sens < 0:
        pts = list(reversed(pts))  # bm_loft attend des y croissants
    bm = bm_loft(pts, seg=seg)
    bosseler(bm, rayon * 0.16, 1.6 / max(rayon, 0.5), graine)
    return bm


def goutte(pos, r):
    return bm_ico(T(pos, echelle=(r, r * 1.4, r)), subdiv=2)


objs = []
x = 0.0

# ---- stalactites (pointe vers le bas) avec une goutte d'eau au bout
for i, (h, r) in enumerate(((10, 1.6), (13, 2.0), (7, 1.2)), start=1):
    p = Piece(f"Stalactite{i}")
    p.ajouter("Roche", pointe_organique(h, r, -1, i * 11, renflement=0.5))
    # petites stalactites secondaires accrochées à la base
    for k in range(2):
        a = rng.uniform(0, 6.28)
        sec = pointe_organique(h * rng.uniform(0.3, 0.5), r * 0.45, -1, i * 37 + k)
        bmesh.ops.translate(sec, verts=sec.verts, vec=Vector((math.cos(a) * r * 0.9, 0, math.sin(a) * r * 0.9)))
        p.ajouter("Roche", sec)
    p.ajouter("Goutte", goutte((0, -h - 0.15, 0), 0.22))
    objs += p.objets((x, 0, 0))
    x += 8

# ---- stalagmites
for i, (h, r) in enumerate(((8, 1.8), (5, 1.4), (11, 2.2)), start=1):
    p = Piece(f"Stalagmite{i}")
    p.ajouter("Roche", pointe_organique(h, r, 1, i * 23, renflement=0.8))
    for k in range(rng.randint(1, 2)):
        a = rng.uniform(0, 6.28)
        sec = pointe_organique(h * rng.uniform(0.3, 0.55), r * 0.5, 1, i * 41 + k)
        bmesh.ops.translate(sec, verts=sec.verts, vec=Vector((math.cos(a) * r * 1.1, 0, math.sin(a) * r * 1.1)))
        p.ajouter("Roche", sec)
    objs += p.objets((x, 0, 0))
    x += 8

# ---- colonnes (une stalactite et une stalagmite qui se sont rejointes)
for i in (1, 2):
    p = Piece(f"Colonne{i}")
    H = 20.0
    anneaux = []
    for k in range(15):
        u = k / 14
        taille = 0.55 + 2.4 * (abs(u - 0.52) ** 1.4) * 2.2
        anneaux.append((H * u, taille * rng.uniform(0.9, 1.1), taille * rng.uniform(0.85, 1.05),
                        0.3 * math.sin(u * 5 + i), 0.3 * math.cos(u * 4 + i)))
    bm = bm_loft(anneaux, seg=14)
    bosseler(bm, 0.45, 0.45, i * 5)
    p.ajouter("Roche", bm)
    # coulées à la base
    for k in range(5):
        a = k * 1.256 + rng.uniform(-0.3, 0.3)
        c = pointe_organique(rng.uniform(1.5, 3), rng.uniform(1.2, 1.8), 1, i * 70 + k)
        bmesh.ops.translate(c, verts=c.verts, vec=Vector((math.cos(a) * 2.6, 0, math.sin(a) * 2.6)))
        p.ajouter("Roche", c)
    objs += p.objets((x, 0, 0))
    x += 10

# ---- cristaux : grappe de prismes hexagonaux à pointe, sur un socle de roche
for i in (1, 2, 3):
    p = Piece(f"Cristal{i}")
    socle = bm_ico(T((0, 0.2, 0), echelle=(2.4, 1.0, 2.0)), subdiv=2)
    bosseler(socle, 0.4, 0.9, i * 9)
    p.ajouter("Socle", socle)
    for k in range(rng.randint(5, 8)):
        L = rng.uniform(2.0, 6.0) * (1.3 if k == 0 else 1)
        w = rng.uniform(0.35, 0.75) * (1.3 if k == 0 else 1)
        inclin = (rng.uniform(-0.6, 0.6), rng.uniform(0, 6.28), rng.uniform(-0.6, 0.6)) if k else (0, 0, 0)
        anneaux = [(0, w, w), (L * 0.78, w, w), (L, 0.02, 0.02)]
        bm = bm_loft(anneaux, seg=6)
        M = Matrix.Translation(Vector((rng.uniform(-1, 1), 0.3, rng.uniform(-0.8, 0.8)))) @ Euler(inclin, 'XYZ').to_matrix().to_4x4()
        bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
        p.ajouter("Cristal", bm)
    objs += p.objets((x, 0, 0))
    x += 8

# ---- champignons bioluminescents : touffe de pieds fins et chapeaux bombés, lamelles lumineuses
for i in (1, 2, 3):
    p = Piece(f"Champignon{i}")
    for k in range(rng.randint(4, 7)):
        h = rng.uniform(0.8, 2.6) * (1.4 if k == 0 else 1)
        rc = h * rng.uniform(0.38, 0.55)
        cx, cz = rng.uniform(-1.2, 1.2), rng.uniform(-1.2, 1.2)
        pench = Vector((rng.uniform(-0.25, 0.25), 1, rng.uniform(-0.25, 0.25))).normalized()
        sommet = Vector((cx, 0, cz)) + pench * h
        pied = bm_loft([(0, h * 0.09, h * 0.09), (h * 0.5, h * 0.06, h * 0.06), (h, h * 0.07, h * 0.07)], seg=6)
        # incliner le pied
        for v in pied.verts:
            u = v.co.y / h
            v.co = Vector((cx + v.co.x + pench.x * h * u, v.co.y * pench.y, cz + v.co.z + pench.z * h * u))
        p.ajouter("Pied", pied)
        chapeau = bm_loft([(0, rc, rc), (rc * 0.25, rc * 0.95, rc * 0.95), (rc * 0.55, rc * 0.6, rc * 0.6), (rc * 0.7, 0.05, 0.05)],
                          seg=10, bas=False)
        bmesh.ops.translate(chapeau, verts=chapeau.verts, vec=sommet - Vector((0, rc * 0.1, 0)))
        p.ajouter("Chapeau", chapeau)
        lamelles = bm_loft([(0, rc * 0.92, rc * 0.92), (0.02, rc * 0.2, rc * 0.2)], seg=10, haut=False)
        bmesh.ops.translate(lamelles, verts=lamelles.verts, vec=sommet - Vector((0, rc * 0.12, 0)))
        p.ajouter("Lueur", lamelles)
        # petits points lumineux sur le chapeau
        for _ in range(3):
            a = rng.uniform(0, 6.28)
            q = sommet + Vector((math.cos(a) * rc * 0.5, rc * 0.4, math.sin(a) * rc * 0.5))
            p.ajouter("Lueur", bm_ico(T(q, echelle=rc * 0.09), subdiv=1))
    objs += p.objets((x, 0, 0))
    x += 6

for o in objs:
    n = triangles(o)
    if n > 19000:
        print("  ATTENTION", o.name, n)
exporter_fbx("GrotteDecor.fbx", objs)
try:
    rendu("grotte_decor.png", direction=(0.1, -1.0, 0.2), objets=objs, largeur=2200, hauteur=700)
except Exception as e:
    print("rendu impossible :", e)
print("FIN", len(objs), "pièces", sum(triangles(o) for o in objs), "triangles")
