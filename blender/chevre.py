"""Chèvre des montagnes (faune du décor), deux robes.

    "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" -b --factory-startup --python blender/chevre.py

Sortie : assets/Chevre.fbx — « Chevre1 » (robe claire) et « Chevre2 » (robe brune), pièces :
    ChevreN_Corps_<Teinte> et ChevreN_Tete_<Teinte> (la tête est séparée : animée en jeu autour de la nuque).
Repère L : -z = avant, pieds à y = 0, ~2.6 de haut au garrot (mis à l'échelle en jeu).
Nuque (pivot de la tête) : (0, 2.15, -1.05) — repris par Bordures.lua.
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commun import *

vider()
TEINTES = {"Pelage": (236, 228, 214), "PelageBrun": (124, 88, 60), "Sombre": (70, 58, 50),
           "Cornes": (150, 132, 108), "Sabots": (44, 38, 36), "Yeux": (24, 20, 18), "Nez": (180, 140, 130)}


class Atelier:
    def __init__(self, prefixe):
        self.prefixe = prefixe
        self.bms = {}

    def bm(self, g, t):
        return self.bms.setdefault((g, t), bmesh.new())

    def ovo(self, g, t, c, s, rot=(0, 0, 0), sub=2):
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1.0)
        M = Matrix.Translation(Vector(c)) @ Euler(rot, 'XYZ').to_matrix().to_4x4() @ Matrix.Diagonal((s[0], s[1], s[2], 1))
        bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
        self.fondre(g, t, bm)

    def cyl(self, g, t, a, b, r1, r2, seg=8):
        a, b = Vector(a), Vector(b)
        d = b - a
        L = d.length
        q = d.to_track_quat('Z', 'Y')
        M = Matrix.Translation((a + b) / 2) @ q.to_matrix().to_4x4()
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg, radius1=r1, radius2=r2, depth=L, matrix=M)
        self.fondre(g, t, bm)

    def fondre(self, g, t, src):
        dst = self.bm(g, t)
        vmap = {v: dst.verts.new(v.co) for v in src.verts}
        for f in src.faces:
            try:
                dst.faces.new([vmap[v] for v in f.verts])
            except ValueError:
                pass
        src.free()

    def objets(self):
        objs = []
        for (g, t), bm in sorted(self.bms.items()):
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            ob = objet(f"{self.prefixe}_{g}_{t}", bm, materiau(t, TEINTES[t], 0.9))
            centrer_origine(ob)
            objs.append(ob)
        return objs


def chevre(idx, robe, decal):
    A = Atelier(f"Chevre{idx}")
    P = robe
    # corps : tonneau un peu bombé, croupe, poitrail
    A.ovo("Corps", P, (0, 1.75, 0.0), (0.55, 0.55, 1.05))
    A.ovo("Corps", P, (0, 1.8, 0.75), (0.5, 0.5, 0.45))
    A.ovo("Corps", P, (0, 1.85, -0.75), (0.48, 0.55, 0.45))
    A.ovo("Corps", "Sombre" if robe == "Pelage" else "Pelage", (0, 2.25, 0.0), (0.22, 0.08, 0.9))   # raie dorsale
    # pattes (cuisse + canon + sabot), légèrement écartées
    for sx in (-1, 1):
        for sz, inclin in ((-0.75, -0.05), (0.75, 0.08)):
            hanche = Vector((sx * 0.3, 1.55, sz))
            genou = Vector((sx * 0.32, 0.8, sz + inclin))
            pied = Vector((sx * 0.32, 0.12, sz + inclin * 0.5))
            A.cyl("Corps", P, hanche, genou, 0.2, 0.12)
            A.cyl("Corps", P, genou, pied, 0.11, 0.09)
            A.cyl("Corps", "Sabots", pied, pied - Vector((0, 0.14, 0)), 0.1, 0.11)
    # queue relevée
    A.cyl("Corps", P, (0, 2.0, 1.15), (0, 2.35, 1.3), 0.09, 0.04)
    # cou (fait partie du corps), jusqu'à la nuque
    A.cyl("Corps", P, (0, 1.95, -0.9), (0, 2.25, -1.1), 0.26, 0.2)
    # ---- tête (groupe séparé) ----
    A.ovo("Tete", P, (0, 2.45, -1.45), (0.24, 0.26, 0.42), rot=(0.5, 0, 0))
    A.ovo("Tete", P, (0, 2.22, -1.78), (0.17, 0.16, 0.22), rot=(0.4, 0, 0))     # museau
    A.ovo("Tete", "Nez", (0, 2.18, -1.95), (0.1, 0.07, 0.06), sub=1)
    for sx in (-1, 1):
        A.ovo("Tete", "Yeux", (sx * 0.19, 2.55, -1.55), (0.05, 0.05, 0.05), sub=1)
        A.ovo("Tete", P, (sx * 0.3, 2.6, -1.3), (0.2, 0.06, 0.1), rot=(0, 0, sx * -0.4), sub=1)   # oreilles
        # cornes recourbées vers l'arrière
        pts = [Vector((sx * 0.11, 2.68, -1.42)), Vector((sx * 0.16, 2.95, -1.3)), Vector((sx * 0.2, 3.1, -1.05)),
               Vector((sx * 0.22, 3.05, -0.82))]
        for k in range(3):
            A.cyl("Tete", "Cornes", pts[k], pts[k + 1], 0.07 - k * 0.018, 0.055 - k * 0.018)
    A.cyl("Tete", "Sombre" if robe == "Pelage" else "Pelage", (0, 2.1, -1.75), (0, 1.85, -1.7), 0.06, 0.02)   # barbiche
    objs = A.objets()
    for o in objs:
        o.location.x += decal
    return objs


objs = chevre(1, "Pelage", -2.5) + chevre(2, "PelageBrun", 2.5)
exporter_fbx("Chevre.fbx", objs)
try:
    rendu("chevre.png", direction=(-0.9, -0.7, 0.25), objets=objs)
except Exception as e:
    print("rendu impossible :", e)
print("FIN", len(objs), "pièces", sum(triangles(o) for o in objs), "triangles")
