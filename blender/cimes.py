"""Sommets lointains de l'horizon (fond de décor au-delà des montagnes jouables).

    "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" -b --factory-startup --python blender/cimes.py

Sortie : assets/Cimes.fbx — 3 massifs « Cime1..3 », chacun en pièces Roche / Neige / Ombre (pied boisé sombre).
Repère L : base à y = 0, emprise ~1000 × 700 studs, sommet ~420 studs (mis à l'échelle en jeu).
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commun import *

vider()
TEINTES = {"Roche": (96, 88, 104), "Neige": (240, 232, 236), "Ombre": (54, 58, 52)}


def cretes(x, z, graine):
    total, amp, freq, somme = 0.0, 1.0, 1.0, 0.0
    for o in range(6):
        n = noise.noise(Vector((x * freq + graine * 3.7 + o * 1.3, z * freq - graine * 2.1, graine + o * 0.4)))
        c = max(0.0, 1 - abs(n * 2))
        total += c * c * amp
        somme += amp
        amp *= 0.5
        freq *= 2.05
    return total / somme


def massif(idx, graine, L=1000, P=700, H=420, N=72):
    """Grille N×N déplacée ; profil en dôme allongé + crêtes ; faces triées par teinte."""
    hauteurs = {}
    for i in range(N + 1):
        for k in range(N + 1):
            u, v = i / N * 2 - 1, k / N * 2 - 1
            d = math.sqrt((u * 1.0) ** 2 + (v * 1.25) ** 2)
            dome = max(0.0, 1 - d) ** 1.35
            c = cretes(u * 1.8, v * 1.8, graine)
            pics = 0.0
            for (px, pz, ph) in PICS[idx]:
                pics += ph * max(0.0, 1 - math.hypot(u - px, v - pz) / 0.42) ** 2
            h = H * (dome * (0.35 + 0.65 * c) + pics * 0.55)
            hauteurs[(i, k)] = h if d < 1 else 0.0
    bms = {t: bmesh.new() for t in TEINTES}
    verts = {t: {} for t in TEINTES}

    def vtx(t, i, k):
        key = (i, k)
        if key not in verts[t]:
            x = (i / N - 0.5) * L
            z = (k / N - 0.5) * P
            verts[t][key] = bms[t].verts.new((x, hauteurs[key] - 2, z))
        return verts[t][key]

    hmax = max(hauteurs.values())
    for i in range(N):
        for k in range(N):
            hs = [hauteurs[(i, k)], hauteurs[(i + 1, k)], hauteurs[(i + 1, k + 1)], hauteurs[(i, k + 1)]]
            if max(hs) <= 0.01:
                continue
            hm = sum(hs) / 4
            pente = (max(hs) - min(hs)) / (L / N)
            limite = hmax * (0.42 + 0.07 * noise.noise(Vector((i * 0.21, k * 0.21, graine))))
            if hm > limite and pente < 2.6:
                t = "Neige"
            elif hm < hmax * 0.16 and pente < 0.9:
                t = "Ombre"
            else:
                t = "Roche"
            q = [vtx(t, i, k), vtx(t, i, k + 1), vtx(t, i + 1, k + 1), vtx(t, i + 1, k)]
            try:
                bms[t].faces.new(q)
            except ValueError:
                pass
    objs = []
    for t, bm in bms.items():
        if not bm.faces:
            bm.free()
            continue
        bmesh.ops.triangulate(bm, faces=bm.faces)
        ob = objet(f"Cime{idx}_{t}", bm, materiau(t, TEINTES[t], 0.9))
        centrer_origine(ob)
        print("  ", ob.name, triangles(ob), "triangles")
        objs.append(ob)
    return objs


# pics dominants (u, v dans [-1, 1], hauteur relative)
PICS = {
    1: [(-0.15, 0.05, 1.0), (0.35, -0.1, 0.7), (-0.55, 0.15, 0.5)],
    2: [(0.1, 0.0, 1.15), (-0.4, -0.05, 0.6)],
    3: [(-0.3, 0.0, 0.8), (0.25, 0.1, 0.95), (0.6, -0.05, 0.45)],
}
objs = []
for idx, graine in ((1, 1.3), (2, 4.9), (3, 8.2)):
    for o in massif(idx, graine):
        o.location.x += (idx - 2) * 1100   # côte à côte pour l'aperçu (recentrés en jeu)
        objs.append(o)
exporter_fbx("Cimes.fbx", objs)
try:
    rendu("cimes.png", direction=(0.0, -1.0, 0.25), objets=objs)
except Exception as e:
    print("rendu impossible :", e)
print("FIN", len(objs), "pièces")
