"""Grotte −50 m « Le Lac des Lueurs » : assets bioluminescents, ruines naines englouties, camp des mineurs.

    "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" -b --factory-startup --python blender/grotte_lueurs.py

Sortie : assets/GrotteLueurs.fbx — pièces « <Prefixe>_<Teinte> », base à y = 0 (sauf « pend » : sommet à y = 0) :
    ChampiGeant1..3   Pied / Chapeau / Lamelles / Points       champignons géants (h ≈ 9–14)
    Fils1..2          Fil / Perle                    (pend)    fils de soie de vers luisants (≈ 3–9 de long)
    Mousse1..2        Mousse / Bout                  (pend)    rideau de mousse qui pend (≈ 4–7)
    Geode1..2         Cristal / Cristal2 / Socle               géode bicolore (cyan + améthyste)
    Arche             Pierre / Rune                            arche runique naine (ouverture 14 × 17)
    ColonneBrisee1..2 Pierre / Rune                            colonne cannelée cassée
    Gravats           Pierre                                   blocs taillés effondrés
    Nenuphar1..2      Feuille / Fleur                          nénuphars lumineux (posés sur l'eau)
    Meduse            Cloche / Coeur / Tentacule               méduse de spores (flotte dans l'air)
    Poisson           Corps / Nageoire                         poisson lumineux (≈ 1,6 de long, tête vers -z)
    Algue1..2         Tige / Lueur                             algues lumineuses (sous l'eau)
    LanterneVers      Bois / Fer / Verre / Lueur               lanterne à vers luisants sur piquet (h ≈ 5)
    Tente             Toile / Bois                             tente de mineur (camp d'arrivée)
    TableCarte        Bois / Papier / Fer                      table avec carte et chandelle
Repère L (commun.py).
"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commun import *

vider()
TEINTES = {
    "Pied": (210, 200, 220), "Chapeau": (92, 52, 140), "Lamelles": (255, 120, 220), "Points": (120, 255, 240),
    "Fil": (200, 240, 255), "Perle": (120, 255, 240), "Mousse": (40, 80, 70), "Bout": (120, 255, 200),
    "Cristal": (90, 230, 255), "Cristal2": (190, 110, 255), "Socle": (54, 52, 64),
    "Pierre": (110, 112, 124), "Rune": (90, 230, 255),
    "Feuille": (30, 110, 90), "Fleur": (200, 140, 255),
    "Cloche": (150, 220, 255), "Coeur": (255, 150, 240), "Tentacule": (140, 230, 255),
    "Corps": (90, 220, 255), "Nageoire": (220, 150, 255),
    "Tige": (20, 90, 80), "Lueur": (120, 255, 220),
    "Bois": (96, 66, 44), "Fer": (70, 70, 78), "Verre": (170, 210, 220),
    "Toile": (176, 150, 112), "Papier": (226, 206, 160),
}
BRILLANT = {"Lamelles", "Points", "Perle", "Bout", "Cristal", "Cristal2", "Rune", "Fleur", "Coeur", "Tentacule",
            "Corps", "Nageoire", "Lueur", "Verre", "Cloche"}
rng = random.Random(2026)


def bosseler(bm, force, freq, graine):
    o = Vector((graine * 3.1, graine * 1.7, graine * 2.3))
    for v in bm.verts:
        v.co += Vector((noise.noise(v.co * freq + o), noise.noise(v.co * freq + o * 2) * 0.4,
                        noise.noise(v.co * freq + o * 3))) * force


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

    def objets(self, decal, angle=45):
        objs = []
        for t, bm in self.bms.items():
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            ob = objet(f"{self.prefixe}_{t}", bm, materiau(t, TEINTES[t], 0.5 if t in BRILLANT else 0.9), decal=decal)
            lisse(ob, angle)
            centrer_origine(ob)
            objs.append(ob)
        return objs


def tube(points, rayons, seg=6):
    """Tube le long d'une polyligne (points en repère L), rayon variable."""
    bm = bmesh.new()
    cercles = []
    for i, p in enumerate(points):
        p = Vector(p)
        d = (Vector(points[min(i + 1, len(points) - 1)]) - Vector(points[max(i - 1, 0)])).normalized()
        a = Vector((1, 0, 0)) if abs(d.x) < 0.9 else Vector((0, 0, 1))
        u = d.cross(a).normalized()
        w = d.cross(u).normalized()
        r = rayons[i] if isinstance(rayons, (list, tuple)) else rayons
        cercles.append([bm.verts.new(p + (u * math.cos(2 * math.pi * k / seg) + w * math.sin(2 * math.pi * k / seg)) * r)
                        for k in range(seg)])
    for a, b in zip(cercles, cercles[1:]):
        for k in range(seg):
            j = (k + 1) % seg
            bm.faces.new((a[k], a[j], b[j], b[k]))
    for c, sens in ((cercles[0], -1), (cercles[-1], 1)):
        centre = bm.verts.new(sum((v.co for v in c), Vector()) / seg)
        for k in range(seg):
            j = (k + 1) % seg
            bm.faces.new((c[j], c[k], centre) if sens < 0 else (c[k], c[j], centre))
    return bm


def prisme(base, direction, longueur, largeur, seg=6):
    d = Vector(direction).normalized()
    bm = bm_loft([(0, largeur, largeur), (longueur * 0.78, largeur, largeur), (longueur, 0.02, 0.02)], seg=seg)
    rot = Vector((0, 1, 0)).rotation_difference(d).to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation(Vector(base)) @ rot, verts=bm.verts)
    return bm


def bloc(pos, taille, rot=(0, 0, 0)):
    return bm_cube(T(pos, rot, taille))


objs = []
x = 0.0

# ===== Champignons géants : pied courbe, chapeau en dôme ondulé, lamelles lumineuses dessous, points lumineux
for i, (h, rc) in enumerate(((14, 6.5), (10, 4.8), (8, 3.6)), start=1):
    p = Piece(f"ChampiGeant{i}")
    pench = Vector((rng.uniform(-0.25, 0.25), 1, rng.uniform(-0.25, 0.25)))
    pts, rs = [], []
    for k in range(9):
        u = k / 8
        courbe = Vector((pench.x * h * u * u, h * u, pench.z * h * u * u))
        pts.append(courbe)
        rs.append(h * (0.09 - 0.035 * u) + (0.6 if k == 0 else 0) + 0.25 * math.exp(-u * 8))
    pied = tube(pts, rs, seg=12)
    bosseler(pied, 0.12, 0.8, i)
    p.ajouter("Pied", pied)
    # anneau (volve) sous le chapeau
    p.ajouter("Pied", bm_tore(T(pts[6]), R=rs[6] + 0.25, r=0.22, seg=16, segp=6))
    sommet = pts[-1]
    chap = bm_loft([(0, rc, rc), (rc * 0.12, rc * 1.02, rc * 1.02), (rc * 0.32, rc * 0.86, rc * 0.86),
                    (rc * 0.52, rc * 0.55, rc * 0.55), (rc * 0.62, 0.05, 0.05)], seg=28, bas=False)
    for v in chap.verts:  # bord ondulé
        a = math.atan2(v.co.z, v.co.x)
        if v.co.y < rc * 0.15:
            v.co.y += 0.35 * math.sin(a * 7 + i) * (rc / 5)
    bosseler(chap, 0.15, 0.5, i * 7)
    bmesh.ops.translate(chap, verts=chap.verts, vec=sommet - Vector((0, rc * 0.08, 0)))
    p.ajouter("Chapeau", chap)
    # lamelles : disque conique sous le chapeau, plissé
    lam = bm_loft([(0, rc * 0.97, rc * 0.97), (rc * 0.18, rs[-1] + 0.2, rs[-1] + 0.2)], seg=40, bas=False, haut=False)
    for v in lam.verts:
        a = math.atan2(v.co.z, v.co.x)
        v.co.y += 0.12 * math.sin(a * 40) * (rc / 5)
    bmesh.ops.translate(lam, verts=lam.verts, vec=sommet - Vector((0, rc * 0.12, 0)))
    p.ajouter("Lamelles", lam)
    for _ in range(int(rc * 3)):
        a = rng.uniform(0, 6.28)
        r = rng.uniform(0.15, 0.8) * rc
        y = rc * (0.6 * (1 - (r / rc) ** 2)) + rc * 0.02
        q = sommet + Vector((math.cos(a) * r, y - rc * 0.05, math.sin(a) * r))
        p.ajouter("Points", bm_ico(T(q, echelle=(rc * 0.07, rc * 0.035, rc * 0.07)), subdiv=1))
    # petits champignons au pied
    for k in range(rng.randint(3, 5)):
        a = rng.uniform(0, 6.28)
        d = rng.uniform(1.2, 2.6) + h * 0.05
        hh = rng.uniform(0.8, 2.2)
        c = Vector((math.cos(a) * d, 0, math.sin(a) * d))
        p.ajouter("Pied", bm_loft([(0, 0.18, 0.18), (hh, 0.12, 0.12)], seg=6, M=T(c)))
        rr = hh * 0.5
        p.ajouter("Chapeau", bm_loft([(0, rr, rr), (rr * 0.4, rr * 0.8, rr * 0.8), (rr * 0.7, 0.04, 0.04)], seg=10, bas=False,
                                     M=T(c + Vector((0, hh, 0)))))
        p.ajouter("Lamelles", bm_loft([(0, rr * 0.95, rr * 0.95), (0.05, 0.1, 0.1)], seg=10, haut=False,
                                      M=T(c + Vector((0, hh - 0.05, 0)))))
    objs += p.objets((x, 0, 0))
    x += 16

# ===== Fils de vers luisants : sommet à y = 0, fils qui pendent avec perles lumineuses
for i, n in ((1, 26), (2, 16)):
    p = Piece(f"Fils{i}")
    for _ in range(n):
        c = Vector((rng.uniform(-2.5, 2.5), 0, rng.uniform(-2.5, 2.5)))
        L = rng.uniform(3, 9) * (1 if i == 1 else 0.7)
        pts = [c + Vector((0.08 * math.sin(k * 1.3), -L * k / 5, 0.08 * math.cos(k))) for k in range(6)]
        p.ajouter("Fil", tube(pts, 0.025, seg=3))
        for k in range(rng.randint(5, 9)):
            u = rng.uniform(0.1, 1.0)
            q = c + Vector((0, -L * u, 0))
            r = 0.05 + 0.07 * u
            p.ajouter("Perle", bm_ico(T(q, echelle=(r, r * 1.4, r)), subdiv=1))
    objs += p.objets((x, 0, 0))
    x += 8

# ===== Rideau de mousse qui pend (rubans bruités, bouts lumineux)
for i, n, Lmax in ((1, 22, 7), (2, 14, 4.5)):
    p = Piece(f"Mousse{i}")
    for k in range(n):
        c = Vector((rng.uniform(-3, 3), 0, rng.uniform(-0.6, 0.6)))
        L = rng.uniform(0.4, 1) * Lmax
        pts = [c + Vector((0.25 * math.sin(j * 0.9 + k), -L * j / 6, 0.2 * math.cos(j * 1.1 + k))) for j in range(7)]
        p.ajouter("Mousse", tube(pts, [0.22 - 0.025 * j for j in range(7)], seg=4))
        p.ajouter("Bout", bm_ico(T(pts[-1] - Vector((0, 0.1, 0)), echelle=0.16), subdiv=1))
    # coussin de mousse au plafond
    nappe = bm_ico(T((0, 0, 0), echelle=(3.6, 0.5, 1.2)), subdiv=2)
    bosseler(nappe, 0.3, 1.2, i)
    p.ajouter("Mousse", nappe)
    objs += p.objets((x, 0, 0))
    x += 9

# ===== Géodes bicolores
for i in (1, 2):
    p = Piece(f"Geode{i}")
    socle = bm_ico(T((0, 0.3, 0), echelle=(3.2, 1.3, 2.6)), subdiv=2)
    bosseler(socle, 0.5, 0.7, i * 13)
    p.ajouter("Socle", socle)
    for k in range(rng.randint(9, 13)):
        t = "Cristal" if k % 3 else "Cristal2"
        L = rng.uniform(2, 7) * (1.4 if k == 0 else 1)
        w = rng.uniform(0.4, 0.9) * (1.4 if k == 0 else 1)
        d = (rng.uniform(-0.7, 0.7), 1, rng.uniform(-0.7, 0.7)) if k else (0, 1, 0)
        p.ajouter(t, prisme((rng.uniform(-1.6, 1.6), 0.6, rng.uniform(-1.2, 1.2)), d, L, w))
    objs += p.objets((x, 0, 0), angle=30)
    x += 10

# ===== Arche runique naine : deux piliers + voussoirs, clé de voûte runique, base y = 0
p = Piece("Arche")
L, H = 14.0, 11.0  # demi-ouverture 7, naissance de l'arc à 11, sommet à 18
for sx in (-1, 1):
    px = sx * (L / 2 + 1.4)
    p.ajouter("Pierre", bloc((px, 0.6, 0), (3.8, 1.2, 3.8)))
    for k in range(5):  # tambours du pilier, légèrement décalés (usure)
        p.ajouter("Pierre", bloc((px + rng.uniform(-0.1, 0.1), 1.2 + k * 2 + 1, rng.uniform(-0.1, 0.1)), (2.8, 1.9, 2.8),
                                 (0, rng.uniform(-0.05, 0.05), 0)))
    p.ajouter("Pierre", bloc((px, H + 0.5, 0), (3.6, 1.0, 3.6)))
    # runes verticales sur la face avant du pilier
    for k in range(4):
        y = 2.6 + k * 2.1
        p.ajouter("Rune", bloc((px, y, -1.43), (0.18, 1.2, 0.08)))
        p.ajouter("Rune", bloc((px + 0.3, y + 0.25, -1.43), (0.5, 0.14, 0.08), (0, 0, 0.6)))
nv = 13
for k in range(nv):
    a0, a1 = math.pi * k / nv, math.pi * (k + 1) / nv
    am = (a0 + a1) / 2
    R = L / 2 + 1.4
    c = Vector((math.cos(am) * R, H + 1 + math.sin(am) * R, 0))
    t = "Rune" if k == nv // 2 else "Pierre"
    taille = (2.9, R * (a1 - a0) * 1.02, 2.9) if t == "Pierre" else (3.2, R * (a1 - a0) * 1.15, 3.1)
    p.ajouter("Pierre" if t == "Pierre" else "Pierre", bloc(c, taille, (0, 0, am - math.pi / 2)))
    if t == "Rune":
        p.ajouter("Rune", bloc(c + Vector((0, 0, -1.6)), (1.2, 1.2, 0.1), (0, 0, math.pi / 4)))
        p.ajouter("Rune", bloc(c + Vector((0, 0, -1.62)), (0.5, 0.5, 0.1), (0, 0, math.pi / 4)))
# ligne de runes le long de l'arc
for k in range(26):
    a = math.pi * (k + 0.5) / 26
    if abs(a - math.pi / 2) < 0.15:
        continue
    R = L / 2 + 0.55
    c = Vector((math.cos(a) * R, H + 1 + math.sin(a) * R, -1.47))
    p.ajouter("Rune", bloc(c, (0.12, 0.45 if k % 2 else 0.25, 0.06), (0, 0, a)))
objs += p.objets((x, 0, 0), angle=30)
x += 24

# ===== Colonnes cannelées brisées
for i, h in ((1, 9.0), (2, 5.0)):
    p = Piece(f"ColonneBrisee{i}")
    p.ajouter("Pierre", bloc((0, 0.5, 0), (3.4, 1.0, 3.4)))
    seg = 16
    col = bm_loft([(1.0, 1.25, 1.25), (h, 1.1, 1.1)], seg=seg, bas=True, haut=True)
    for v in col.verts:  # cannelures
        a = math.atan2(v.co.z, v.co.x)
        f = 1 - 0.07 * (0.5 + 0.5 * math.cos(a * 8))
        v.co.x *= f
        v.co.z *= f
    for v in col.verts:  # cassure en biseau irrégulier
        if v.co.y > h - 0.1:
            v.co.y -= (v.co.x + 1.2) * 0.9 + noise.noise(v.co * 2) * 0.6
    p.ajouter("Pierre", col)
    p.ajouter("Rune", bm_tore(T((0, 2.4, 0)), R=1.2, r=0.07, seg=24, segp=4))
    # morceau tombé à côté
    morceau = bm_loft([(0, 1.1, 1.1), (2.4, 1.05, 1.05)], seg=seg, M=T((2.8, 1.0, 1.0), (0, 0.4, math.pi / 2 - 0.1)))
    p.ajouter("Pierre", morceau)
    objs += p.objets((x, 0, 0), angle=35)
    x += 9

p = Piece("Gravats")
for k in range(9):
    s = rng.uniform(0.8, 2.0)
    p.ajouter("Pierre", bloc((rng.uniform(-3, 3), s * 0.35, rng.uniform(-3, 3)), (s * 1.4, s * 0.8, s),
                             (rng.uniform(-0.3, 0.3), rng.uniform(0, 3), rng.uniform(-0.3, 0.3))))
objs += p.objets((x, 0, 0), angle=30)
x += 9

# ===== Nénuphars lumineux
for i, n in ((1, 5), (2, 3)):
    p = Piece(f"Nenuphar{i}")
    for k in range(n):
        c = Vector((rng.uniform(-2.5, 2.5), 0, rng.uniform(-2.5, 2.5)))
        r = rng.uniform(0.7, 1.5)
        bm = bmesh.new()
        centre = bm.verts.new(c + Vector((0, 0.08, 0)))
        bord = [bm.verts.new(c + Vector((math.cos(a) * r, 0.04 * math.sin(a * 3), math.sin(a) * r)))
                for a in [0.35 + (2 * math.pi - 0.7) * j / 15 for j in range(16)]]
        for a, b in zip(bord, bord[1:]):
            bm.faces.new((centre, b, a))
        bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.06)
        p.ajouter("Feuille", bm)
        if k % 2 == 0:
            for j in range(6):
                a = j * math.pi / 3
                pet = prisme(c + Vector((0, 0.08, 0)), (math.cos(a) * 0.8, 1, math.sin(a) * 0.8), r * 0.55, r * 0.14, seg=4)
                p.ajouter("Fleur", pet)
    objs += p.objets((x, 0, 0))
    x += 8

# ===== Méduse de spores
p = Piece("Meduse")
p.ajouter("Cloche", bm_loft([(0, 1.6, 1.6), (0.5, 1.5, 1.5), (1.2, 1.05, 1.05), (1.6, 0.4, 0.4), (1.7, 0.02, 0.02)], seg=20,
                            bas=False))
p.ajouter("Coeur", bm_ico(T((0, 0.7, 0), echelle=(0.7, 0.55, 0.7)), subdiv=2))
for k in range(9):
    a = k * 2 * math.pi / 9
    c = Vector((math.cos(a) * 1.2, 0, math.sin(a) * 1.2))
    L = rng.uniform(3, 5.5)
    pts = [c + Vector((0.25 * math.sin(j + k), -L * j / 7, 0.25 * math.cos(j * 0.8 + k))) for j in range(8)]
    p.ajouter("Tentacule", tube(pts, [0.09 - 0.01 * j for j in range(8)], seg=4))
objs += p.objets((x, 0, 0))
x += 7

# ===== Poisson lumineux (tête vers -z)
p = Piece("Poisson")
corps = bm_loft([(0, 0.02, 0.02), (0.25, 0.22, 0.12), (0.7, 0.28, 0.14), (1.2, 0.14, 0.08), (1.45, 0.03, 0.02)], seg=10)
bmesh.ops.transform(corps, matrix=T((0, 0.3, -0.7), (math.pi / 2, 0, 0)), verts=corps.verts)
p.ajouter("Corps", corps)
queue = bmesh.new()
v = [queue.verts.new(q) for q in ((0, 0.3, 0.7), (0, 0.65, 1.1), (0, -0.05, 1.1))]
queue.faces.new(v)
bmesh.ops.solidify(queue, geom=queue.faces[:], thickness=0.03)
p.ajouter("Nageoire", queue)
dors = bmesh.new()
v = [dors.verts.new(q) for q in ((0, 0.5, -0.4), (0, 0.75, 0.1), (0, 0.45, 0.2))]
dors.faces.new(v)
bmesh.ops.solidify(dors, geom=dors.faces[:], thickness=0.03)
p.ajouter("Nageoire", dors)
objs += p.objets((x, 0, 0))
x += 4

# ===== Algues lumineuses
for i, n in ((1, 7), (2, 4)):
    p = Piece(f"Algue{i}")
    for k in range(n):
        c = Vector((rng.uniform(-1, 1), 0, rng.uniform(-1, 1)))
        L = rng.uniform(1.5, 4)
        pts = [c + Vector((0.3 * math.sin(j * 1.4 + k), L * j / 6, 0.3 * math.cos(j * 1.1 + k))) for j in range(7)]
        p.ajouter("Tige", tube(pts, [0.09 - 0.01 * j for j in range(7)], seg=4))
        for j in range(2, 7, 2):
            p.ajouter("Lueur", bm_ico(T(pts[j], echelle=(0.14, 0.22, 0.14)), subdiv=1))
    objs += p.objets((x, 0, 0))
    x += 5

# ===== Lanterne à vers luisants sur piquet
p = Piece("LanterneVers")
p.ajouter("Bois", tube([(0, 0, 0), (0.05, 2.2, 0), (0, 4.4, 0)], [0.14, 0.12, 0.1], seg=6))
p.ajouter("Bois", tube([(0, 4.2, 0), (0.6, 4.6, 0), (1.1, 4.6, 0)], 0.08, seg=5))  # potence
p.ajouter("Fer", tube([(1.1, 4.6, 0), (1.1, 4.1, 0)], 0.03, seg=4))
cage = bm_loft([(3.0, 0.32, 0.32), (3.15, 0.4, 0.4), (3.75, 0.4, 0.4), (3.9, 0.3, 0.3)], seg=8)
bmesh.ops.translate(cage, verts=cage.verts, vec=Vector((1.1, 0, 0)))
p.ajouter("Verre", cage)
for k in range(4):
    a = k * math.pi / 2 + math.pi / 4
    p.ajouter("Fer", tube([(1.1 + math.cos(a) * 0.42, 3.0, math.sin(a) * 0.42), (1.1 + math.cos(a) * 0.42, 3.95, math.sin(a) * 0.42)],
                         0.035, seg=4))
p.ajouter("Fer", bm_loft([(3.9, 0.45, 0.45), (4.1, 0.1, 0.1)], seg=8, M=T((1.1, 0, 0))))
p.ajouter("Fer", bm_loft([(2.9, 0.42, 0.42), (3.0, 0.42, 0.42)], seg=8, M=T((1.1, 0, 0))))
for k in range(5):
    q = Vector((1.1 + rng.uniform(-0.2, 0.2), rng.uniform(3.2, 3.7), rng.uniform(-0.2, 0.2)))
    p.ajouter("Lueur", bm_ico(T(q, echelle=(0.06, 0.06, 0.18), rot=(rng.uniform(0, 3), rng.uniform(0, 3), 0)), subdiv=1))
objs += p.objets((x, 0, 0), angle=40)
x += 5

# ===== Tente de mineur (A), ouverte vers -z
p = Piece("Tente")
for sz in (-1, 1):
    z = sz * 2.6
    p.ajouter("Bois", tube([(-2.4, 0, z), (0, 3.6, z)], 0.1, seg=6))
    p.ajouter("Bois", tube([(2.4, 0, z), (0, 3.6, z)], 0.1, seg=6))
p.ajouter("Bois", tube([(0, 3.65, -3.0), (0, 3.65, 3.0)], 0.09, seg=6))
toile = bmesh.new()
for sx in (-1, 1):
    v = [toile.verts.new(q) for q in ((sx * 2.6, -0.05, -2.8), (0, 3.7, -2.8), (0, 3.7, 2.8), (sx * 2.6, -0.05, 2.8))]
    toile.faces.new(v)
fond = [toile.verts.new(q) for q in ((-2.5, 0, 2.75), (0, 3.6, 2.75), (2.5, 0, 2.75))]
toile.faces.new(fond)
bmesh.ops.subdivide_edges(toile, edges=toile.edges[:], cuts=4, use_grid_fill=True)
for v in toile.verts:  # toile qui s'affaisse un peu
    v.co.y -= 0.12 * math.sin(max(0.0, min(1.0, v.co.y / 3.7)) * math.pi) + noise.noise(v.co * 1.3) * 0.05
bmesh.ops.solidify(toile, geom=toile.faces[:], thickness=0.05)
p.ajouter("Toile", toile)
# rabat ouvert
rabat = bmesh.new()
v = [rabat.verts.new(q) for q in ((0, 3.6, -2.85), (-1.6, 0.4, -3.6), (-0.4, 0.2, -3.2))]
rabat.faces.new(v)
bmesh.ops.solidify(rabat, geom=rabat.faces[:], thickness=0.05)
p.ajouter("Toile", rabat)
objs += p.objets((x, 0, 0), angle=40)
x += 8

# ===== Table avec carte et chandelle
p = Piece("TableCarte")
p.ajouter("Bois", bloc((0, 2.3, 0), (4.0, 0.25, 2.4)))
for sx in (-1, 1):
    for sz in (-1, 1):
        p.ajouter("Bois", bloc((sx * 1.7, 1.1, sz * 0.95), (0.25, 2.2, 0.25)))
carte = bmesh.new()
v = [carte.verts.new(q) for q in ((-1.4, 2.44, -0.8), (1.3, 2.44, -0.9), (1.4, 2.44, 0.85), (-1.3, 2.44, 0.9))]
carte.faces.new(v)
bmesh.ops.subdivide_edges(carte, edges=carte.edges[:], cuts=3, use_grid_fill=True)
for vv in carte.verts:
    if abs(vv.co.x) > 1.2:
        vv.co.y += 0.12  # bords enroulés
bmesh.ops.solidify(carte, geom=carte.faces[:], thickness=0.02)
p.ajouter("Papier", carte)
p.ajouter("Fer", bm_loft([(2.43, 0.25, 0.25), (2.55, 0.25, 0.25), (2.6, 0.08, 0.08), (2.9, 0.08, 0.08)], seg=8, M=T((1.5, 0, 0.7))))
p.ajouter("Papier", bm_loft([(2.6, 0.07, 0.07), (3.1, 0.07, 0.07)], seg=6, M=T((1.5, 0, 0.7))))
objs += p.objets((x, 0, 0), angle=40)

for o in objs:
    n = triangles(o)
    if n > 19000:
        print("  ATTENTION", o.name, n)
exporter_fbx("GrotteLueurs.fbx", objs)
try:
    rendu("grotte_lueurs.png", direction=(0.15, -0.6, 1.0), objets=objs, largeur=2600, hauteur=800)
except Exception as e:
    print("rendu impossible :", e)
print("FIN", len(objs), "pièces", sum(triangles(o) for o in objs), "triangles")
