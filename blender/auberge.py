"""Auberge à colombages, copie de l'image de référence previews/auberge/reference.png.

    "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" -b --factory-startup --python blender/auberge.py

Repère L (voir commun.py) : x = droite, y = haut, -z = devant (la façade regarde -z). 1 unité = 1 stud.
Plan (vu de devant) :
  - corps principal x [-15, 5], z [-7, 7] : rez-de-chaussée en pierre (porte en arc, 2 fenêtres à volets),
    pignon gauche à colombages en encorbellement, grand toit avec une lucarne à 2 fenêtres et la cheminée ;
  - aile droite x [5, 17], z [-9, 7] : rez-de-chaussée en pierre (portillon, lanterne, fenêtre éclairée),
    très haut pignon à colombages sur la façade, auvent en planches devant.
Objets : Auberge_<Groupe>_<Teinte> (le jeu recolore chaque teinte : Platre = mur, Tuiles = toit, Volets = volets).
Sorties : assets/Auberge.fbx, aperçus previews/auberge/Auberge_face|cote|dos|planche.png
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import math, random
import bpy
import bmesh
from mathutils import Vector, Matrix
import commun
from commun import *

ID = "Auberge"
DOSSIER = os.path.join(RACINE, "previews", "auberge")

TEINTES = {
    "Pierre": (112, 108, 100), "PierreSombre": (80, 78, 74), "PierreClaire": (146, 138, 124),
    "Mortier": (70, 66, 60), "Cheminee": (172, 166, 158),
    "Platre": (234, 224, 202), "Colombage": (72, 48, 32), "Planches": (98, 68, 44),
    "Tuiles": (172, 104, 56), "TuilesClaires": (198, 128, 70), "TuilesSombres": (132, 78, 44),
    "Vitre": (54, 84, 150), "Plomb": (196, 200, 210), "VitreAllumee": (255, 190, 104),
    "Volets": (110, 68, 38), "Porte": (102, 62, 36), "Fer": (46, 46, 50),
    "Tonneau": (142, 98, 58), "Pot": (178, 94, 58),
    "Feuillage": (58, 94, 42), "Lierre": (64, 104, 44), "LierreClair": (108, 140, 58),
    "Fleurs": (198, 40, 42), "FleursClaires": (236, 206, 214),
}

rng = random.Random(1987)
UP = Vector((0, 1, 0))


def V(p):
    return Vector(p)


# ---------------- atelier : un bmesh par (groupe, teinte) ----------------

class Atelier:
    def __init__(self):
        self.bms = {}
        self.ouverts = set()  # groupes à faces simples (feuilles) : ne pas recalculer les normales

    def bm(self, g, t):
        k = (g, t)
        if k not in self.bms:
            self.bms[k] = bmesh.new()
        return self.bms[k]

    def boite(self, g, t, c, axes, s):
        ux, uy, uz = (V(a) for a in axes)
        c = V(c)
        M = Matrix(((ux.x * s[0], uy.x * s[1], uz.x * s[2], c.x),
                    (ux.y * s[0], uy.y * s[1], uz.y * s[2], c.y),
                    (ux.z * s[0], uy.z * s[1], uz.z * s[2], c.z),
                    (0, 0, 0, 1)))
        bmesh.ops.create_cube(self.bm(g, t), size=1.0, matrix=M)

    def bloc(self, g, t, c, s):
        self.boite(g, t, c, ((1, 0, 0), (0, 1, 0), (0, 0, 1)), s)

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
            if not bm.verts:
                continue
            # le plan est décrit vu de face (x = droite de l'observateur) : miroir vers le repère L
            bmesh.ops.transform(bm, matrix=Matrix.Diagonal((-1, 1, 1, 1)), verts=bm.verts)
            bmesh.ops.reverse_faces(bm, faces=bm.faces)
            if g not in self.ouverts:
                bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            ob = objet(f"{ID}_{g}_{t}", bm, materiau(t, TEINTES[t], 0.85))
            n = triangles(ob)
            if n > 19500:
                print("  ATTENTION", ob.name, n, "triangles")
            centrer_origine(ob)
            objs.append(ob)
        return objs


A = Atelier()


def poutre(g, t, a, b, larg, ep, n):
    a, b, n = V(a), V(b), V(n)
    d = b - a
    L = d.length
    if L < 1e-4:
        return
    uz = d / L
    uy = (n - uz * n.dot(uz)).normalized()
    ux = uy.cross(uz)
    A.boite(g, t, (a + b) / 2, (ux, uy, uz), (larg, ep, L))


def prisme(g, t, pts, n, ep):
    """Polygone plan (points 3D) extrudé le long de n sur ep."""
    bm = A.bm(g, t)
    n = V(n)
    av = [bm.verts.new(V(p) + n * ep) for p in pts]
    ar = [bm.verts.new(V(p)) for p in pts]
    bm.faces.new(av)
    bm.faces.new(list(reversed(ar)))
    k = len(pts)
    for i in range(k):
        j = (i + 1) % k
        bm.faces.new((ar[i], ar[j], av[j], av[i]))


def clip(p0, p1, xmin, xmax, ymin, ymax):
    """Liang-Barsky : segment 2D coupé au rectangle."""
    x0, y0 = p0
    dx, dy = p1[0] - x0, p1[1] - y0
    t0, t1 = 0.0, 1.0
    for p, q in ((-dx, x0 - xmin), (dx, xmax - x0), (-dy, y0 - ymin), (dy, ymax - y0)):
        if p == 0:
            if q < 0:
                return None
            continue
        r = q / p
        if p < 0:
            t0 = max(t0, r)
        else:
            t1 = min(t1, r)
        if t0 > t1:
            return None
    return (x0 + dx * t0, y0 + dy * t0), (x0 + dx * t1, y0 + dy * t1)


def decouper(a, b, trous):
    """Intervalle [a, b] privé des intervalles trous."""
    morceaux = [(a, b)]
    for t0, t1 in trous:
        nv = []
        for m0, m1 in morceaux:
            if t1 <= m0 or t0 >= m1:
                nv.append((m0, m1))
            else:
                if t0 > m0:
                    nv.append((m0, t0))
                if t1 < m1:
                    nv.append((t1, m1))
        morceaux = nv
    return [m for m in morceaux if m[1] - m[0] > 0.15]


# ---------------- murs de pierre ----------------

def mur_pierre(O, u, n, L, H, ouvertures=(), g="Murs"):
    """O : bas-gauche de la face extérieure ; u : sens de la longueur ; n : normale extérieure.
    ouvertures : (u0, u1, y0, y1) laissées libres."""
    O, u, n = V(O), V(u), V(n)
    A.boite(g, "Mortier", O + u * (L / 2) + UP * (H / 2) - n * 0.45, (u, UP, n), (L, H, 0.9))
    y = 0.0
    rang = 0
    while y < H - 0.05:
        ch = min(rng.uniform(0.55, 1.0), H - y)
        x = -rng.uniform(0, 0.9) if rang % 2 else 0.0
        while x < L - 0.05:
            lg = rng.uniform(0.6, 1.5)
            x0, x1 = max(x, 0.0), min(x + lg, L)
            x = x + lg
            if x1 - x0 < 0.3:
                continue
            libre = True
            for u0, u1, y0, y1 in ouvertures:
                if x1 > u0 - 0.05 and x0 < u1 + 0.05 and y + ch > y0 - 0.05 and y < y1 + 0.05:
                    libre = False
                    break
            if not libre:
                continue
            r = rng.random()
            t = "PierreSombre" if r < 0.25 else ("PierreClaire" if r < 0.45 else "Pierre")
            sx, sy = x1 - x0 - 0.14, ch - 0.14
            c = O + u * ((x0 + x1) / 2) + UP * (y + ch / 2 + rng.uniform(-0.05, 0.05)) + n * rng.uniform(-0.14, 0.04)
            # pierres brutes : légèrement de travers
            rot = Matrix.Rotation(rng.uniform(-0.08, 0.08), 3, n)
            A.boite(g, t, c, (rot @ u, rot @ UP, n), (sx, sy * rng.uniform(0.85, 1.0), 0.5))
        y += ch
        rang += 1


# ---------------- fenêtres, volets ----------------

def fenetre(g, c, u, n, w, h, cols=2, rows=3, motif="grille", arche=0.0, volets=(), vitre="Vitre",
            appui="PierreClaire", cadre="Colombage"):
    c, u, n = V(c), V(u), V(n)
    P = lambda x, y, o=0.0: c + u * x + UP * y + n * o
    # vitre (arc segmentaire en haut si arche > 0)
    pts = [(-w / 2, -h / 2), (w / 2, -h / 2)]
    if arche > 0:
        R = (arche ** 2 + (w / 2) ** 2) / (2 * arche)
        yc = h / 2 + arche - R
        a0 = math.asin((w / 2) / R)
        for i in range(9):
            a = a0 - 2 * a0 * i / 8
            pts.append((R * math.sin(a), yc + R * math.cos(a)))
    else:
        pts += [(w / 2, h / 2), (-w / 2, h / 2)]
    prisme(g, vitre, [P(x, y, -0.22) for x, y in pts], n, 0.12)
    # plombs / croisillons
    bord = 0.05
    if motif == "losange":
        pas = 0.62
        k = -w - h
        while k < w + h:
            for pente in (1.3, -1.3):
                s = clip((-w, -w * pente + k), (w, w * pente + k), -w / 2 + bord, w / 2 - bord,
                         -h / 2 + bord, h / 2 + arche * 0.6)
                if s:
                    poutre(g, "Plomb" if vitre == "Vitre" else "Colombage", P(*s[0], -0.06), P(*s[1], -0.06), 0.07, 0.05, n)
            k += pas
    else:
        for i in range(1, cols):
            x = -w / 2 + i * w / cols
            poutre(g, "Plomb" if vitre == "Vitre" else "Colombage", P(x, -h / 2, -0.06), P(x, h / 2 + arche * 0.8, -0.06), 0.1, 0.06, n)
        for j in range(1, rows):
            y = -h / 2 + j * h / rows
            poutre(g, "Plomb" if vitre == "Vitre" else "Colombage", P(-w / 2, y, -0.06), P(w / 2, y, -0.06), 0.1, 0.06, n)
    # cadre
    e = 0.3
    poutre(g, cadre, P(-w / 2 - e / 2, -h / 2 - e, 0), P(-w / 2 - e / 2, h / 2 + 0.02, 0), e, 0.36, n)
    poutre(g, cadre, P(w / 2 + e / 2, -h / 2 - e, 0), P(w / 2 + e / 2, h / 2 + 0.02, 0), e, 0.36, n)
    if arche > 0:
        for i in range(len(pts) - 3):
            a, b = pts[2 + i], pts[3 + i]
            poutre(g, cadre, P(a[0], a[1] + e / 2, 0), P(b[0], b[1] + e / 2, 0), e, 0.36, n)
    else:
        poutre(g, cadre, P(-w / 2 - e, h / 2 + e / 2, 0), P(w / 2 + e, h / 2 + e / 2, 0), e, 0.36, n)
    if appui:
        A.boite(g, appui, P(0, -h / 2 - e - 0.12, 0.2), (u, UP, n), (w + 0.9, 0.26, 0.6))
    # volets ouverts plaqués contre le mur
    for cote in volets:
        s = -1 if cote == "g" else 1
        ws = w / 2 + 0.2
        cv = P(s * (w / 2 + e + 0.08 + ws / 2), 0.0, 0.1)
        hv = h + (arche * 0.7 if arche else 0.0) + 0.2
        A.boite(g, "Volets", cv + UP * (arche * 0.35 if arche else 0), (u, UP, n), (ws, hv, 0.16))
        for k in (-1, 1):
            A.boite(g, "Colombage", cv + UP * (k * hv * 0.3) + n * 0.1, (u, UP, n), (ws - 0.06, 0.22, 0.06))
        for k in (-1, 1):
            A.boite(g, "Colombage", cv + u * (k * ws / 6) + n * 0.09, (u, UP, n), (0.05, hv - 0.1, 0.04))
        A.boite(g, "Fer", P(s * (w / 2 + e + 0.15), h * 0.3, 0.2), (u, UP, n), (0.3, 0.1, 0.08))
        A.boite(g, "Fer", P(s * (w / 2 + e + 0.15), -h * 0.3, 0.2), (u, UP, n), (0.3, 0.1, 0.08))


# ---------------- pignons à colombages ----------------

def pignon(g, O, u, n, hw, H, rails, posts, fenetres=(), croix=(), lanterne=None):
    """O : milieu du bas du pignon (dessus de la sablière), sur la face extérieure du plâtre."""
    O, u, n = V(O), V(u), V(n)
    P = lambda x, y, o=0.0: O + u * x + UP * y + n * o
    top = lambda x: H * (1 - abs(x) / hw)
    prisme(g, "Platre", [P(-hw, 0, -0.5), P(hw, 0, -0.5), P(0, H, -0.5)], n, 0.5)
    trousY = []
    trousX = []
    for f in fenetres:
        x, y, w, h = f[:4]
        trousY.append(((x - w / 2 - 0.3, x + w / 2 + 0.3), (y - h / 2 - 0.3, y + h / 2 + 0.3)))
    # sablière (en encorbellement) et rails
    poutre(g, "Colombage", P(-hw - 0.5, -0.35, 0.05), P(hw + 0.5, -0.35, 0.05), 0.7, 0.6, n)
    for hy in rails:
        ext = hw * (1 - hy / H) - 0.1
        trous = [tx for tx, ty in trousY if ty[0] < hy < ty[1]]
        for a, b in decouper(-ext, ext, trous):
            poutre(g, "Colombage", P(a, hy, 0.12), P(b, hy, 0.12), 0.42, 0.3, n)
    for x, y0, y1 in posts:
        y1 = min(y1, top(x) - 0.15)
        if y1 - y0 < 0.3:
            continue
        trous = [ty for tx, ty in trousY if tx[0] < x < tx[1]]
        for a, b in decouper(y0, y1, trous):
            poutre(g, "Colombage", P(x, a, 0.12), P(x, b, 0.12), 0.4, 0.3, n)
    for (x0, y0), (x1, y1) in croix:
        poutre(g, "Colombage", P(x0, y0, 0.12), P(x1, y1, 0.12), 0.34, 0.28, n)
    # chevrons de rive dans le plan du pignon
    for s in (-1, 1):
        poutre(g, "Colombage", P(s * hw, 0, 0.12), P(0, H, 0.12), 0.5, 0.32, n)
    for f in fenetres:
        x, y, w, h, cols, rows = f
        fenetre("Fenetres", P(x, y, 0.15), u, n, w, h, cols, rows, appui="Colombage")
    # aisseliers et bouts de solives sous l'encorbellement
    for x in [i * 1.1 for i in range(-int(hw / 1.1), int(hw / 1.1) + 1)]:
        A.boite(g, "Colombage", P(x, -0.95, -0.35), (u, UP, n), (0.32, 0.45, 1.3))
    for s in (-1, 1):
        poutre(g, "Colombage", P(s * (hw - 0.6), -2.6, -0.9), P(s * (hw - 0.2), -0.7, -0.1), 0.35, 0.35, n)


# ---------------- toitures en tuiles plates ----------------

def pan(g, W0, a, d, ld, L, debord, lat=(1.0, 1.0), coyau=0.32, rh=0.72):
    """Pan de toit : W0 = point bas (dessus du mur) au début ; a = sens du faîtage ; d = sens de la pente
    (du mur vers le faîtage) ; ld = longueur de pente ; L = longueur ; debord = avancée de l'égout (coyau)."""
    W0, a, d = V(W0), V(a).normalized(), V(d).normalized()
    nr = a.cross(d)
    if nr.y < 0:
        nr = -nr
    c1, c2 = d * math.cos(coyau) + nr * math.sin(coyau), d * math.cos(coyau) - nr * math.sin(coyau)
    dk = c1 if c1.y < c2.y else c2
    nk = a.cross(dk)
    if nk.y < 0:
        nk = -nk
    x0, x1 = -lat[0], L + lat[1]
    # voliges sous les tuiles
    A.boite(g, "TuilesSombres", W0 + a * ((x0 + x1) / 2) + d * (ld / 2) + nr * 0.05, (a, nr, d), (x1 - x0, 0.25, ld))
    A.boite(g, "TuilesSombres", W0 + a * ((x0 + x1) / 2) - dk * (debord / 2) + nk * 0.05, (a, nk, dk), (x1 - x0, 0.25, debord))
    s = -debord
    rang = 0
    while s < ld - 0.25:
        if s < 0:
            base, dr, nn = W0 + dk * s, dk, nk
        else:
            base, dr, nn = W0 + d * s, d, nr
        t = 0.14
        dt = dr * math.cos(t) - nn * math.sin(t)
        nt = nn * math.cos(t) + dr * math.sin(t)
        x = x0 - (rng.uniform(0.3, 0.6) if rang % 2 else 0.0)
        while x < x1 - 0.1:
            w = rng.uniform(0.85, 1.3)
            xa, xb = max(x, x0), min(x + w, x1)
            x += w
            if xb - xa < 0.25:
                continue
            r = rng.random()
            tt = "TuilesClaires" if r < 0.28 else ("TuilesSombres" if r < 0.5 else "Tuiles")
            c = base + a * ((xa + xb) / 2) + dr * (rh * 0.62) + nn * (0.26 + rng.uniform(-0.03, 0.03))
            A.boite(g, tt, c, (a, nt, dt), (xb - xa - 0.07, 0.15, rh * 1.5))
        s += rh
        rang += 1


def faitage(g, a, b):
    a, b = V(a), V(b)
    d = (b - a).normalized()
    h = d.cross(UP).normalized()
    u1 = (UP + h).normalized()
    poutre(g, "TuilesSombres", a + UP * 0.25, b + UP * 0.25, 0.75, 0.75, u1)


def chevrons_egout(g, a, b, n, pas=1.05):
    """Sablière et abouts de chevrons sous un égout (a -> b le long du mur, n = vers l'extérieur)."""
    a, b, n = V(a), V(b), V(n)
    poutre(g, "Colombage", a - n * 0.05, b - n * 0.05, 0.5, 0.45, n)
    L = (b - a).length
    d = (b - a) / L
    k = 0.4
    while k < L:
        p = a + d * k
        poutre(g, "Colombage", p + UP * 0.15, p + n * 1.1 - UP * 0.25, 0.3, 0.32, d.cross(n))
        k += pas


# ---------------- accessoires ----------------

def tonneau(c, r, h, couche=False):
    c = V(c)
    bm = bm_loft([(0, r * 0.86, r * 0.86), (h * 0.2, r * 0.96, r * 0.96), (h * 0.5, r, r),
                  (h * 0.8, r * 0.96, r * 0.96), (h, r * 0.86, r * 0.86)], seg=18)
    bmesh.ops.transform(bm, matrix=Matrix.Translation(c), verts=bm.verts)
    A.fondre("Decor", "Tonneau", bm)
    for y, rr in ((h * 0.12, 0.9), (h * 0.3, 0.98), (h * 0.7, 0.98), (h * 0.88, 0.9)):
        bm = bm_tore(Matrix.Translation(c + UP * y), R=r * rr + 0.02, r=0.07, seg=18, segp=4)
        A.fondre("Decor", "Fer", bm)
    # douelles
    for i in range(12):
        t = 2 * math.pi * i / 12
        A.boite("Decor", "Colombage", c + V((math.cos(t) * r * 0.99, h / 2, math.sin(t) * r * 0.99)),
                ((-math.sin(t), 0, math.cos(t)), (0, 1, 0), (math.cos(t), 0, math.sin(t))), (0.05, h * 0.9, 0.05))
    A.boite("Decor", "Colombage", c + UP * (h - 0.05), ((1, 0, 0), (0, 1, 0), (0, 0, 1)), (r * 1.6, 0.1, r * 1.6))


def touffe(c, rx, ry, rz, n_fleurs, rouge=0.8, g="Fleurs"):
    """Massif de feuillage arrondi semé de fleurs."""
    c = V(c)
    for _ in range(max(2, int(rx * rz * 5))):
        p = c + V((rng.uniform(-rx, rx), rng.uniform(-ry * 0.4, ry * 0.5), rng.uniform(-rz, rz)))
        s = rng.uniform(0.4, 0.7)
        A.fondre(g, "Feuillage", bm_ico(T(p, (rng.random(), rng.random(), 0), (s, s * 0.8, s)), subdiv=1))
    for _ in range(n_fleurs):
        p = c + V((rng.uniform(-rx, rx), rng.uniform(0, ry * 0.9), rng.uniform(-rz, rz)))
        s = rng.uniform(0.14, 0.22)
        t = "Fleurs" if rng.random() < rouge else "FleursClaires"
        A.fondre(g, t, bm_ico(T(p, (0, 0, 0), s), subdiv=1))


def pot(c, r, h):
    c = V(c)
    bm = bm_loft([(0, r * 0.7, r * 0.7), (h * 0.85, r, r), (h, r * 1.08, r * 1.08)], seg=14)
    bmesh.ops.transform(bm, matrix=Matrix.Translation(c), verts=bm.verts)
    A.fondre("Decor", "Pot", bm)
    touffe(c + UP * (h + 0.35), r * 1.1, 0.7, r * 1.1, 10, rouge=1.0)


def lanterne(c, n, suspendue=False):
    c, n = V(c), V(n)
    u = UP.cross(n).normalized()
    A.boite("Decor", "VitreAllumee", c, (u, UP, n), (0.6, 0.8, 0.6))
    for sx in (-1, 1):
        for sz in (-1, 1):
            A.boite("Decor", "Fer", c + u * (sx * 0.32) + n * (sz * 0.32), (u, UP, n), (0.08, 0.9, 0.08))
    A.boite("Decor", "Fer", c + UP * 0.5, (u, UP, n), (0.85, 0.12, 0.85))
    A.boite("Decor", "Fer", c + UP * 0.68, (u, UP, n), (0.45, 0.22, 0.45))
    A.boite("Decor", "Fer", c - UP * 0.46, (u, UP, n), (0.7, 0.1, 0.7))
    if suspendue:
        poutre("Decor", "Fer", c + UP * 0.8, c + UP * 1.4, 0.06, 0.06, n)
        poutre("Decor", "Fer", c + UP * 1.4 - n * 1.1, c + UP * 1.4 + n * 0.05, 0.12, 0.12, UP)
    else:
        poutre("Decor", "Fer", c + UP * 0.8 - n * 0.9, c + UP * 0.8, 0.12, 0.12, UP)
        poutre("Decor", "Fer", c + UP * 0.8, c + UP * 0.6, 0.06, 0.06, n)


def lierre(O, u, n, x0, x1, profil, densite=16, retombe=False):
    densite *= 1.8
    """Feuilles de lierre plaquées sur un plan. profil(x) -> (ymin, ymax) à l'abscisse x."""
    O, u, n = V(O), V(u), V(n)
    A.ouverts.add("Lierre")
    surf = 0.0
    for i in range(40):
        x = x0 + (x1 - x0) * (i + 0.5) / 40
        y0, y1 = profil(x)
        surf += max(0, y1 - y0) * (x1 - x0) / 40
    for _ in range(int(surf * densite)):
        x = rng.uniform(x0, x1)
        y0, y1 = profil(x)
        if y1 <= y0:
            continue
        y = rng.uniform(y0, y1)
        p = O + u * x + UP * y + n * rng.uniform(0.05, 0.6)
        s = rng.uniform(0.3, 0.5)
        nn = (n + V((rng.uniform(-0.5, 0.5), rng.uniform(-0.2, 0.6), rng.uniform(-0.5, 0.5)))).normalized()
        t1 = nn.cross(V((rng.uniform(-1, 1), 1, rng.uniform(-1, 1)))).normalized()
        t2 = nn.cross(t1)
        bm = A.bm("Lierre", "LierreClair" if rng.random() < 0.32 else "Lierre")
        vs = [bm.verts.new(p + t1 * s), bm.verts.new(p + t2 * s * 0.75), bm.verts.new(p - t1 * s * 0.8),
              bm.verts.new(p - t2 * s * 0.75)]
        bm.faces.new(vs)
    # tiges
    for _ in range(max(1, int((x1 - x0) / 1.6))):
        x = rng.uniform(x0, x1)
        y0, y1 = profil(x)
        if y1 - y0 < 1:
            continue
        poutre("Decor", "Colombage", O + u * x + UP * y0 + n * 0.08, O + u * (x + rng.uniform(-0.6, 0.6)) + UP * y1 + n * 0.08,
               0.12, 0.1, n)


# ================= construction =================

def construire():
    vider()
    G = 10.0  # hauteur du rez-de-chaussée en pierre
    FZ = -7.0  # façade du corps principal
    DZ = -9.0  # façade de l'aile droite
    RIDGE = 20.0
    XA = 13.0  # axe de l'aile droite (x 6 .. 20)
    APEX = 32.0

    XL = -11.5  # axe de l'aile gauche (x -16 .. -7)
    APEX_G = 21.0  # sommet du pignon gauche

    # ---- murs de pierre ----
    porte = (-5.4, 3.0)  # x centre, largeur
    fen_c = [-1.6, 2.4]  # fenêtres à volets
    fen_g = [-13.6, -9.4]  # fenêtres sous le pignon gauche
    mur_pierre((-16, 0, FZ), (1, 0, 0), (0, 0, -1), 22, G,
               [(porte[0] + 16 - 1.95, porte[0] + 16 + 1.95, 0, 8.1)] +
               [(x + 16 - 1.45, x + 16 + 1.45, 3.0, 7.3) for x in fen_c] +
               [(x + 16 - 1.35, x + 16 + 1.35, 3.2, 6.9) for x in fen_g])
    mur_pierre((-16, 0, 7), (0, 0, -1), (-1, 0, 0), 14, G)
    mur_pierre((6, 0, 7), (-1, 0, 0), (0, 0, 1), 22, G)
    mur_pierre((6, 0, DZ), (1, 0, 0), (0, 0, -1), 14, G, [(1.9, 5.2, 0, 6.8), (8.9, 12.3, 3.3, 7.1)])
    mur_pierre((6, 0, FZ), (0, 0, -1), (-1, 0, 0), 2, G)
    mur_pierre((20, 0, DZ), (0, 0, 1), (1, 0, 0), 16, G)
    mur_pierre((20, 0, 7), (-1, 0, 0), (0, 0, 1), 14, G)
    # dalles intérieures (cachent l'intérieur sous les toits)
    A.bloc("Murs", "Mortier", (-5, G - 0.2, 0), (22, 0.4, 14))
    A.bloc("Murs", "Mortier", (XA, G - 0.2, -1), (14, 0.4, 16))

    # ---- porte en arc ----
    xd, wd = porte
    ya_p = 6.1
    pts = [(xd - wd / 2, 1.2), (xd + wd / 2, 1.2)]
    for i in range(11):
        a = math.pi * i / 10
        pts.append((xd + wd / 2 * math.cos(a), ya_p + wd / 2 * math.sin(a)))
    prisme("Porte", "Porte", [V((x, y, FZ + 0.35)) for x, y in pts], (0, 0, -1), 0.25)
    for k in range(1, 5):
        x = xd - wd / 2 + k * wd / 5
        ytop = ya_p + math.sqrt(max(0, (wd / 2) ** 2 - (x - xd) ** 2))
        A.bloc("Porte", "Colombage", (x, (1.2 + ytop) / 2, FZ + 0.08), (0.07, ytop - 1.3, 0.06))
    for y in (2.6, 5.4):
        A.bloc("Porte", "Fer", (xd - 0.4, y, FZ + 0.05), (2.0, 0.2, 0.08))
    A.fondre("Porte", "Fer", bm_tore(T((xd + 0.9, 4.2, FZ + 0.02), (math.pi / 2, 0, 0)), R=0.22, r=0.05, seg=10, segp=4))
    # encadrement : piédroits et claveaux
    for y in [1.2 + i * 0.98 for i in range(5)]:
        for s in (-1, 1):
            larg = 0.6 if (int(y) % 2) else 0.45
            A.bloc("Porte", "PierreSombre", (xd + s * (wd / 2 + larg / 2), y + 0.48, FZ - 0.08), (larg, 0.92, 0.6))
    for i in range(11):
        a0, a1 = math.pi * i / 11, math.pi * (i + 1) / 11
        am = (a0 + a1) / 2
        r = wd / 2 + 0.32
        c = V((xd + r * math.cos(am), ya_p + r * math.sin(am), FZ - 0.08))
        uu = V((-math.sin(am), math.cos(am), 0))
        A.boite("Porte", "PierreSombre", c, (uu, (math.cos(am), math.sin(am), 0), (0, 0, 1)), (r * (a1 - a0) - 0.07, 0.62, 0.6))
    # perron de trois marches
    for i, (y, z0, z1, xa, xb) in enumerate(((1.2, FZ, FZ - 1.3, -7.6, -3.2), (0.8, FZ - 1.3, FZ - 2.3, -8.0, -3.0),
                                            (0.4, FZ - 2.3, FZ - 3.3, -8.4, -2.8))):
        x = xa
        while x < xb - 0.2:
            w = min(rng.uniform(1.0, 1.8), xb - x)
            A.bloc("Murs", "PierreClaire" if rng.random() < 0.6 else "Pierre", (x + w / 2, y / 2 + (0.2 if i == 0 else 0), (z0 + z1) / 2),
                   (w - 0.08, y if i else y + 0.4, abs(z1 - z0) - 0.06))
            x += w

    # ---- fenêtres du rez-de-chaussée ----
    for x in fen_c:
        fenetre("Fenetres", (x, 5.0, FZ), (1, 0, 0), (0, 0, -1), 2.1, 3.2, motif="losange", arche=0.45,
                volets=("d",), appui=None)
    for x in fen_g:
        fenetre("Fenetres", (x, 5.0, FZ), (1, 0, 0), (0, 0, -1), 2.0, 2.9, 2, 3, appui="Colombage")
    # aile droite : fenêtre éclairée et portillon
    fenetre("Fenetres", (16.6, 5.2, DZ), (1, 0, 0), (0, 0, -1), 3.0, 3.4, 2, 2, vitre="VitreAllumee", appui="Colombage")
    xg = 9.55
    for s in (-1, 1):
        A.bloc("Porte", "Colombage", (xg + s * 1.55, 3.4, DZ - 0.25), (0.4, 6.8, 0.5))
    A.bloc("Porte", "Colombage", (xg, 6.95, DZ - 0.25), (3.6, 0.4, 0.5))
    for i in range(6):
        x = xg - 1.25 + i * 0.5
        h = 5.6 + (0.25 if i % 2 else 0)
        A.bloc("Porte", "Planches", (x, 0.3 + h / 2, DZ + 0.15), (0.46, h, 0.18))
    for y in (1.3, 4.9):
        A.bloc("Porte", "Colombage", (xg, y, DZ + 0.02), (2.8, 0.34, 0.12))
    poutre("Porte", "Colombage", (xg - 1.2, 1.4, DZ + 0.0), (xg + 1.2, 4.8, DZ + 0.0), 0.3, 0.1, (0, 0, -1))
    lanterne((12.25, 6.2, DZ - 1.0), (0, 0, -1))

    # ---- jardinières, muret, pots, tonneaux ----
    A.bloc("Decor", "Colombage", (XL, 2.95, FZ - 0.5), (8.2, 0.8, 1.0))
    touffe((XL, 3.6, FZ - 0.6), 4.0, 0.9, 0.6, 46)
    touffe((-15.0, 0.8, FZ - 1.2), 1.2, 1.6, 1.0, 10)
    touffe((-8.6, 0.6, FZ - 1.0), 1.0, 1.2, 0.8, 6)
    # muret du massif devant les fenêtres à volets
    for y0 in (0.0, 0.85, 1.7):
        x = -3.0 - (0.4 if y0 == 0.85 else 0)
        while x < 4.6:
            w = min(rng.uniform(0.9, 1.7), 4.6 - x)
            A.bloc("Murs", rng.choice(("Pierre", "PierreClaire", "PierreSombre")), (x + w / 2, y0 + 0.42, FZ - 0.75),
                   (w - 0.1, 0.78, 1.45))
            x += w
    A.bloc("Murs", "Mortier", (0.8, 1.25, FZ - 0.75), (7.6, 2.5, 1.2))
    touffe((0.8, 3.0, FZ - 0.8), 3.8, 0.9, 0.7, 60, rouge=0.65)
    pot((-7.9, 0.0, FZ - 3.3), 0.55, 1.0)
    pot((-3.1, 1.2, FZ - 0.7), 0.5, 0.9)
    pot((-2.6, 0.0, FZ - 3.0), 0.55, 1.0)
    tonneau((-15.0, 0, FZ - 4.0), 1.35, 2.7)
    tonneau((-12.3, 0, FZ - 3.6), 0.75, 1.6)
    tonneau((1.4, 0, FZ - 2.2), 0.95, 2.1)
    tonneau((3.4, 0, FZ - 4.1), 0.95, 2.0)
    tonneau((21.6, 0, DZ - 4.6), 1.5, 3.0)

    # ---- pignon de l'aile gauche (façade, en encorbellement) et son dos ----
    pente_g = (APEX_G - G) / 4.5
    hw_l = 4.5 - 0.6 / pente_g
    H_l = APEX_G - (G + 0.6)
    posts_g = [(x, 0, 2.6) for x in (-3.2, -2.0, -0.8, 0.8, 2.0, 3.2)] + \
              [(x, 2.6, 5.6) for x in (-2.5, -1.25, 1.25, 2.5)] + \
              [(x, 5.6, 8.0) for x in (-1.0, 0, 1.0)] + [(0, 8.0, 10.0)]
    croix_g = [((-2.0, 0.0), (-3.2, 2.4)), ((2.0, 0.0), (3.2, 2.4)), ((-1.0, 5.6), (-1.7, 7.0)), ((1.0, 5.6), (1.7, 7.0))]
    pignon("Colombages", (XL, G + 0.6, FZ - 0.8), (1, 0, 0), (0, 0, -1), hw_l, H_l,
           rails=[2.6, 5.6, 8.0], posts=posts_g, fenetres=[(0, 4.1, 1.9, 2.5, 2, 3)], croix=croix_g)
    pignon("Colombages", (XL, G + 0.6, 7.8), (-1, 0, 0), (0, 0, 1), hw_l, H_l,
           rails=[2.6, 5.6, 8.0], posts=posts_g + [(0, 2.6, 5.6)], croix=croix_g)

    # ---- pignon de l'aile droite (façade) et son dos ----
    hw_d = 7.0 - 0.6 / ((APEX - G) / 7.0)
    H_d = APEX - (G + 0.6)
    posts_d = [(x, 0, 3.6) for x in (-5.0, -3.6, -2.2, -0.75, 0.75, 2.2, 3.6, 5.0)] + \
              [(x, 3.6, 8.4) for x in (-4.4, -3.0, -1.5, 1.5, 3.0, 4.4)] + \
              [(x, 8.4, 12.4) for x in (-2.6, -1.3, 0, 1.3, 2.6)] + \
              [(x, 12.4, 15.6) for x in (-0.8, 0.8)] + [(0, 15.6, 18.0)]
    croix_d = [((-3.0, 3.6), (-4.4, 6.6)), ((3.0, 3.6), (4.4, 6.6)), ((-1.3, 8.4), (-2.4, 10.6)), ((1.3, 8.4), (2.4, 10.6))]
    pignon("Colombages", (XA, G + 0.6, DZ - 0.8), (1, 0, 0), (0, 0, -1), hw_d, H_d,
           rails=[3.6, 8.4, 12.4, 15.6], posts=posts_d, fenetres=[(0, 6.0, 2.5, 4.0, 2, 3)], croix=croix_d)
    pignon("Colombages", (XA, G + 0.6, 7.8), (-1, 0, 0), (0, 0, 1), hw_d, H_d,
           rails=[3.6, 8.4, 12.4, 15.6], posts=posts_d + [(0, 3.6, 8.4)], croix=croix_d)
    lanterne((XA + 2.6, G + 5.2, DZ - 2.1), (0, 0, -1), suspendue=True)

    # ---- toits ----
    # toit central (faîtage parallèle à la façade), engagé sous les toits des deux ailes
    ld = math.hypot(RIDGE - G, -FZ)
    pan("ToitPrincipal", (-12.0, G + 0.15, FZ), (1, 0, 0), V((0, RIDGE - G, -FZ)), ld, 24.0, 1.4, lat=(0.0, 0.0))
    pan("ToitPrincipal", (-12.0, G + 0.15, 7), (1, 0, 0), V((0, RIDGE - G, -7)), ld, 24.0, 1.4, lat=(0.0, 0.0))
    faitage("ToitPrincipal", (-12.0, RIDGE + 0.1, 0), (11.5, RIDGE + 0.1, 0))
    chevrons_egout("Colombages", (-7, G - 0.3, FZ), (6, G - 0.3, FZ), (0, 0, -1))
    chevrons_egout("Colombages", (-7, G - 0.3, 7), (6, G - 0.3, 7), (0, 0, 1))
    # aile gauche
    ldg = math.hypot(APEX_G - G, 4.5)
    pan("ToitGauche", (-16, G + 0.15, FZ - 0.8), (0, 0, 1), V((4.5, APEX_G - G, 0)), ldg, 15.6, 1.4, lat=(1.2, 1.0))
    pan("ToitGauche", (-7, G + 0.15, FZ - 0.8), (0, 0, 1), V((-4.5, APEX_G - G, 0)), ldg, 15.6, 1.4, lat=(1.2, 1.0))
    faitage("ToitGauche", (XL, APEX_G + 0.15, FZ - 2.0), (XL, APEX_G + 0.15, 8.8))
    for z in (FZ - 1.95, 8.85):
        for s in (-1, 1):
            poutre("Colombages", "Colombage", (XL + s * 5.3, G + 0.2, z), (XL, APEX_G + 0.5, z), 0.55, 0.4, (0, 0, -1 if z < 0 else 1))
    chevrons_egout("Colombages", (-16, G - 0.3, FZ), (-16, G - 0.3, 7), (-1, 0, 0))
    # aile droite
    ldd = math.hypot(APEX - G, 7.0)
    pan("ToitDroit", (6, G + 0.15, DZ - 0.8), (0, 0, 1), V((7.0, APEX - G, 0)), ldd, 16.6, 1.5, lat=(1.3, 1.2))
    pan("ToitDroit", (20, G + 0.15, DZ - 0.8), (0, 0, 1), V((-7.0, APEX - G, 0)), ldd, 16.6, 1.5, lat=(1.3, 1.2))
    faitage("ToitDroit", (XA, APEX + 0.15, DZ - 2.2), (XA, APEX + 0.15, 9.0))
    for z in (DZ - 2.05, 9.05):
        for s in (-1, 1):
            poutre("Colombages", "Colombage", (XA + s * 7.4, G + 0.2, z), (XA, APEX + 0.5, z), 0.6, 0.4, (0, 0, -1 if z < 0 else 1))
    chevrons_egout("Colombages", (6, G - 0.3, DZ), (6, G - 0.3, FZ), (-1, 0, 0))
    chevrons_egout("Colombages", (20, G - 0.3, DZ), (20, G - 0.3, 7), (1, 0, 0))

    # ---- lucarne à deux fenêtres ----
    xc, zf = 0.4, -4.6
    yb, ye, ya = 13.0, 16.5, 19.2
    prisme("Lucarne", "Colombage", [V(p) for p in ((xc - 3.2, yb, zf), (xc + 3.2, yb, zf), (xc + 3.2, ye, zf),
                                                  (xc, ya, zf), (xc - 3.2, ye, zf))], (0, 0, 1), 4.4)
    for k in range(13):
        x = xc - 3.0 + k * 0.5
        ytop = ye + (ya - ye) * (1 - abs(x - xc) / 3.2) - 0.1
        A.bloc("Lucarne", "Planches" if k % 2 else "Colombage", (x, (yb + ytop) / 2, zf - 0.08), (0.42, ytop - yb, 0.12))
    for x in (xc - 1.25, xc + 1.25):
        fenetre("Fenetres", (x, 15.4, zf - 0.15), (1, 0, 0), (0, 0, -1), 1.8, 2.4, 2, 3,
                volets=("g",) if x < xc else ("d",), appui="Colombage")
    lddo = math.hypot(ya - ye, 3.2)
    pan("Lucarne", (xc - 3.2, ye + 0.1, zf), (0, 0, 1), V((3.2, ya - ye, 0)), lddo, 4.4, 1.0, lat=(0.9, 0.0), rh=0.6)
    pan("Lucarne", (xc + 3.2, ye + 0.1, zf), (0, 0, 1), V((-3.2, ya - ye, 0)), lddo, 4.4, 1.0, lat=(0.9, 0.0), rh=0.6)
    faitage("Lucarne", (xc, ya + 0.15, zf - 1.0), (xc, ya + 0.15, zf + 4.2))
    for s in (-1, 1):
        poutre("Lucarne", "Colombage", (xc + s * 4.1, ye - 0.5, zf - 0.95), (xc, ya + 0.45, zf - 0.95), 0.45, 0.35, (0, 0, -1))

    # ---- œils-de-bœuf ----
    def oeil(c, n, r=0.75):
        c, n = V(c), V(n).normalized()
        u = UP.cross(n).normalized()
        M = Matrix((tuple(u) + (0,), tuple(UP) + (0,), tuple(n) + (0,), (0, 0, 0, 1))).transposed()
        # bm_tore : tore dans le plan x-z, on le redresse dans le plan (u, UP)
        R = Matrix.Translation(c) @ M @ Matrix.Rotation(math.pi / 2, 4, 'X')
        A.fondre("ToitPrincipal", "Platre", bm_tore(R, R=r, r=0.22, seg=16, segp=6, rz=r * 0.8))
        A.boite("ToitPrincipal", "Vitre", c - n * 0.05, (u, UP, n), (r * 1.5, r * 1.2, 0.2))
        A.boite("ToitPrincipal", "TuilesSombres", c - n * 0.6 + UP * 0.45, (u, UP, n), (r * 2.6, 0.4, 1.4))
    oeil((-9.0, 15.3, -4.5), (1, 0.35, -0.45))
    oeil((10.0, 22.6, -4.5), (-1, 0.25, -0.35))

    # ---- cheminée ----
    xch, zch = 4.2, 1.4
    y = 17.0
    while y < 23.8:
        h = 0.62
        A.bloc("ToitPrincipal", "Cheminee" if rng.random() < 0.7 else "PierreClaire", (xch, y + h / 2, zch), (2.2, h - 0.06, 2.2))
        A.bloc("ToitPrincipal", "PierreClaire" if rng.random() < 0.5 else "Cheminee",
               (xch + rng.uniform(-0.3, 0.3), y + h / 2, zch - 1.06), (rng.uniform(0.8, 1.4), h - 0.14, 0.12))
        y += h
    A.bloc("ToitPrincipal", "PierreSombre", (xch, y + 0.22, zch), (2.7, 0.45, 2.7))
    A.bloc("ToitPrincipal", "Cheminee", (xch, y + 0.72, zch), (1.6, 0.6, 1.6))

    # ---- auvent en planches devant l'aile droite ----
    zf_a = DZ - 6.0
    for x in (17.4, 23.2):
        A.bloc("Auvent", "Colombage", (x, 4.2, zf_a), (0.5, 8.4, 0.5))
        A.bloc("Auvent", "Colombage", (x, 8.0, zf_a), (2.4, 0.35, 0.4))
        for s in (-1, 1):
            poutre("Auvent", "Colombage", (x, 6.6, zf_a), (x + s * 1.1, 8.0, zf_a), 0.25, 0.25, (0, 0, -1))
    A.bloc("Auvent", "Colombage", (19.0, 8.4, zf_a), (10.0, 0.45, 0.45))
    for x in (14.6, 17.4, 20.2, 23.2):
        poutre("Auvent", "Colombage", (x, 9.6, DZ - 0.1), (x, 8.6, zf_a - 0.5), 0.3, 0.35, (0, 1, 0))
    nA = V((0, 6.0, -1.2)).normalized()
    dA = V((0, -1.2, -6.4)).normalized()
    k = 0
    x = 14.2
    while x < 24.2:
        w = rng.uniform(0.7, 1.0)
        a = V((x + w / 2, 9.95, DZ - 0.05))
        poutre("Auvent", "Planches" if k % 2 else "Colombage", a, a + dA * 6.9, w - 0.06, 0.15, nA)
        x += w
        k += 1

    # ---- lierre ----
    def profil_coin(x):  # façade x [2.6, 6] : monte jusqu'au toit, plus dense au coin
        return (0.0 if x > 3.6 else 1.0 + (3.6 - x) * 2.5, G + 0.3)
    lierre((0, 0, FZ - 0.02), (1, 0, 0), (0, 0, -1), 2.6, 6.0, profil_coin, densite=20)
    lierre((6, 0, DZ - 0.02), (1, 0, 0), (0, 0, -1), 0.0, 2.6, lambda x: (0.0 if x < 1.0 else 6.6, G + 0.5 + (2.6 - x) * 0.8), densite=20)
    lierre((6 - 0.02, 0, FZ), (0, 0, -1), (-1, 0, 0), 0.0, 2.0, lambda x: (0.0, G + 0.3), densite=20)
    lierre((XA - 7.05, G + 0.6, DZ - 0.85), (1, 0, 0), (0, 0, -1), -0.4, 2.0, lambda x: (0.0, 3.4 - x * 1.2), densite=18)
    # coulée sur le toit (au-dessus du coin)
    nT = V((0, 1, -1.4)).normalized()
    lierre((0, G + 0.6, FZ - 0.6), (1, 0, 0), nT, 3.0, 8.0, lambda x: (0.0, 1.4 + (x - 3.0) * 0.6), densite=16)
    # lierre qui retombe sous l'égout, entre le pignon gauche et la porte
    lierre((0, 0, FZ - 0.02), (1, 0, 0), (0, 0, -1), -9.0, -3.4,
           lambda x: (G - 1.2 - 2.6 * math.exp(-((x + 7.6) / 1.0) ** 2) - 1.0 * math.exp(-((x + 4.4) / 0.7) ** 2), G), densite=18)
    # pied du pignon gauche (coin avant gauche)
    lierre((-16.02, 0, 0), (0, 0, -1), (-1, 0, 0), 5.2, 7.0, lambda x: (5.0 - (x - 5.2), G), densite=16)
    objs = A.objets()
    print("OBJETS", len(objs), "TRIANGLES", sum(triangles(o) for o in objs))
    exporter_fbx("Auberge.fbx", objs)
    return objs


# ================= aperçus =================

def planche(objs, nom, cam_L, cible_L, focale=28, largeur=844, hauteur=740):
    sc = bpy.context.scene
    sol = objet("SolApercu", bm_cube(T((2, -0.1, -6), echelle=(140, 0.2, 120))), materiau("Sol", (214, 198, 160)))
    cam_data = bpy.data.cameras.new("CamPlanche")
    cam = lier(bpy.data.objects.new("CamPlanche", cam_data))
    loc = CONV @ V(cam_L)
    cib = CONV @ V(cible_L)
    cam.location = loc
    cam.rotation_euler = (cib - loc).to_track_quat('-Z', 'Y').to_euler()
    cam_data.lens = focale
    cam_data.clip_end = 1000
    sc.camera = cam
    sc.render.engine = 'BLENDER_WORKBENCH'
    sc.render.resolution_x, sc.render.resolution_y = largeur, hauteur
    sh = sc.display.shading
    sh.light = 'STUDIO'
    sh.color_type = 'MATERIAL'
    sh.show_cavity = True
    sh.cavity_type = 'BOTH'
    sh.show_shadows = True
    sc.display.shadow_focus = 0.2
    sc.display.light_direction = (0.55, -0.35, 0.75)
    w_ = sc.world or bpy.data.worlds.new("Monde")
    sc.world = w_
    w_.color = lin((112, 164, 220))[:3]
    try:
        sc.view_settings.view_transform = 'Standard'
    except Exception:
        pass
    sc.render.filepath = os.path.join(DOSSIER, nom)
    bpy.ops.render.render(write_still=True)
    print("RENDU", sc.render.filepath)
    bpy.data.objects.remove(sol)
    sc.camera = None


def apercus(objs):
    os.makedirs(DOSSIER, exist_ok=True)
    commun.APERCUS = DOSSIER
    # repère Blender : devant = -y, gauche du bâtiment = +x
    rendu(f"{ID}_face.png", direction=(0, -1, 0.18), objets=objs, largeur=1400, hauteur=1100, fond=(112, 164, 220))
    rendu(f"{ID}_cote.png", direction=(-1, 0, 0.18), objets=objs, largeur=1400, hauteur=1100, fond=(112, 164, 220))
    rendu(f"{ID}_dos.png", direction=(0, 1, 0.18), objets=objs, largeur=1400, hauteur=1100, fond=(112, 164, 220))
    planche(objs, f"{ID}_planche.png", CAMERA, CIBLE, FOCALE)


# caméra en repère L (après miroir : la façade vue de face a son pignon haut à droite de l'écran)
CAMERA, CIBLE, FOCALE = (19.0, 6.5, -38.0), (-0.5, 12.5, -2.0), 30

objs = construire()
apercus(objs)
