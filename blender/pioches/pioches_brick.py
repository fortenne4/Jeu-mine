"""Pioches fantasy en voxels à studs (pipeline « brick » du skill LihFolk Stud Voxel), une par lancement :
    blender -b --factory-startup --python blender/pioches/pioches_brick.py -- <Nom> [render]
Noms : Demon Volcan Givre Celeste Neant Legende  (haut de gamme)
       Bois Pierre Cuivre Fer Quartz              (entrée de gamme)

Repère des briques : x = envergure de la tête, y = haut (manche vertical), z = épaisseur ; devant = -z.
Chaque pioche = 2 parties indépendantes, chacune fermée sur elle-même (la tête a un vrai trou pour le manche) :
    <ID>_Manche_<Materiau>, <ID>_Tete_<Materiau>     (convention Prefixe_Groupe_Teinte de src/monde/Modeles3D.lua)
Une pièce par matériau (FerNoir, Acier, Or, Cristal, Lueur...), maillage glouton (faces coplanaires de même couleur
fusionnées), <= 19 500 triangles par pièce. Couleurs = couleurs de sommets x texture de studs Roblox (règle du skill).
Sorties : out_<ID>/<ID>.glb + <ID>.fbx + <ID>.blend + render/<ID>_<vue>.png (+ _glow.png) ; presente.py fait les planches.
"""
import os, sys, math
import numpy as np
import bpy, bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL = next(p for p in (os.path.expanduser('~/.claude/skills/lihfolk-stud-voxel'),
                         os.path.join(HERE, '..', '..', 'lihfolk-stud-voxel'))
             if os.path.exists(os.path.join(p, 'scripts', 'brick_rig.py')))
sys.path.insert(0, os.path.join(SKILL, 'scripts'))
import brick_rig                                                          # _quads : maillage glouton des faces exposées
STUD_PNG = os.path.join(SKILL, 'assets', 'roblox_square_studs.png')

S = 0.04                       # studs par brique : une pioche fait ~9 studs de haut
brick_rig.S = S
brick_rig.UVD = 32.0           # tuile de 8x8 studs sur 32 briques : 1 stud du motif = 4x4 briques
N = (184, 226, 44)
LO = np.array((-92.0, 0.0, -22.0))
LDIR = np.array((-.45, .75, -.5)); LDIR /= np.linalg.norm(LDIR)          # lumière « peinte » des facettes de gemmes


def hx(h): return np.array([int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)], np.float32)
def rgb(c): return hx(c) if isinstance(c, str) else np.asarray(c, np.float32)
def pal(cs): return np.array([rgb(c) for c in cs], np.float32)
def lin(c):
    c = np.asarray(c, np.float64)
    return np.where(c > .04045, ((c + .055) / 1.055) ** 2.4, c / 12.92)


# id -> (nom, métal, rugosité, émission, force du motif de studs)
MATS = {
    1: ('FerNoir', .9, .45, 0, .45), 2: ('Acier', 1., .2, 0, .35), 3: ('Or', 1., .22, 0, .3),
    4: ('MetalRouge', .85, .28, 0, .4), 5: ('Cuir', 0., .62, 0, .7), 6: ('Roche', 0., .9, 0, .8),
    7: ('Obsidienne', .15, .1, 0, .4), 8: ('Cristal', 0., .06, .12, .25), 9: ('Gemme', 0., .03, .9, 0.),
    10: ('Ivoire', 0., .42, 0, .6), 11: ('Corne', 0., .55, 0, .5), 12: ('Mithril', 1., .15, 0, .35),
    13: ('Email', .3, .22, 0, .45), 14: ('Vide', 0., 1., 0, 0.), 20: ('Lueur', 0., .5, 2.2, 0.),
    15: ('Bois', 0., .72, 0, .7), 16: ('Corde', 0., .88, 0, .75), 17: ('Cuivre', 1., .3, 0, .35),
    18: ('Silex', .05, .32, 0, .5), 19: ('Feuille', 0., .55, 0, .6),
}
METALS = (1, 2, 3, 4, 12, 17)
FLAT = (9, 14, 20)             # ni usure ni bruit : gemmes, vide, lueurs (une couleur de lueur plate, règle du skill)


# ------------------------------------------------------------------ outils géométriques
def inpoly(X, Y, P):
    ins = np.zeros(X.shape, bool); j = len(P) - 1
    for i in range(len(P)):
        xi, yi = P[i]; xj, yj = P[j]
        ins ^= ((yi > Y) != (yj > Y)) & (X < (xj - xi) * (Y - yi) / (yj - yi + 1e-9) + xi)
        j = i
    return ins


def dist2(M, it):
    """distance intérieure approx. (octogonale) : 1 sur le bord, croît vers l'intérieur."""
    d = M.astype(np.float32); cur = M.copy()
    for k in range(it):
        p = np.pad(cur, 1)
        nc = cur & p[2:, 1:-1] & p[:-2, 1:-1] & p[1:-1, 2:] & p[1:-1, :-2]
        if k % 2: nc &= p[2:, 2:] & p[:-2, :-2] & p[2:, :-2] & p[:-2, 2:]
        cur = nc; d += cur
        if not cur.any(): break
    return d


def erode(a):
    p = np.pad(a, 1, constant_values=True)
    return (a & p[2:, 1:-1, 1:-1] & p[:-2, 1:-1, 1:-1] & p[1:-1, 2:, 1:-1] & p[1:-1, :-2, 1:-1]
            & p[1:-1, 1:-1, 2:] & p[1:-1, 1:-1, :-2])


def box3(a, r):
    a = a.astype(np.float32)
    for ax in range(3):
        pad = [(0, 0)] * 3; pad[ax] = (r + 1, r); c = np.cumsum(np.pad(a, pad), axis=ax, dtype=np.float32)
        k = 2 * r + 1; n = a.shape[ax]
        a = np.take(c, np.arange(k, k + n), axis=ax) - np.take(c, np.arange(0, n), axis=ax)
    return a / (2 * r + 1) ** 3


def nz3(X, Y, Z, s=0.):
    return (np.sin(X * .23 + s) * np.sin(Y * .19 + 2 * s) * np.sin(Z * .31 + 3 * s)
            + .5 * np.sin(X * .61 - Y * .53 + Z * .37 + s) + .25 * np.sin(X * 1.3 + Y * 1.1 - Z * .9 + 2 * s))


def rotm(deg):
    a, b, c = np.radians(deg)
    Rx = np.array([[1, 0, 0], [0, math.cos(a), -math.sin(a)], [0, math.sin(a), math.cos(a)]])
    Ry = np.array([[math.cos(b), 0, math.sin(b)], [0, 1, 0], [-math.sin(b), 0, math.cos(b)]])
    Rz = np.array([[math.cos(c), -math.sin(c), 0], [math.sin(c), math.cos(c), 0], [0, 0, 1]])
    return Rz @ Ry @ Rx


def octd(X, Z):
    ax, az = np.abs(X), np.abs(Z)
    return np.maximum(np.maximum(ax, az), (ax + az) * .7071)


def mir(pts): return [(-p[0],) + tuple(p[1:]) for p in pts]


def serrate(a, b, n, depth, sign=1):
    """dents de scie entre a et b (n dents, pointe de profondeur depth du côté sign de la normale)."""
    a = np.array(a, float); b = np.array(b, float); d = b - a; nrm = np.array((-d[1], d[0])) / np.linalg.norm(d) * sign
    out = []
    for i in range(n):
        out.append(tuple(a + d * i / n)); out.append(tuple(a + d * (i + .55) / n + nrm * depth))
    return out


# ------------------------------------------------------------------ couleurs
def vgrad(cs, y0, y1):
    P = pal(cs)
    return lambda X, Y, Z: P[np.clip(((Y - y0) / (y1 - y0) * len(P)).astype(int), 0, len(P) - 1)]


def octcol(c1, c2):
    a, b = rgb(c1), rgb(c2)
    return lambda X, Y, Z: np.where(((np.floor((np.arctan2(Z, X) + np.pi / 8) / (np.pi / 4)).astype(int)) % 2 == 0)[:, None], a, b)


def edgecol(edge, mid, main, inner=None, xin=0):
    E, Mi, Ma = rgb(edge), rgb(mid), rgb(main)
    def f(X, Y, Z, D):
        c = np.where((D <= 2)[:, None], E, np.where((D <= 4)[:, None], Mi, Ma))
        if inner is not None:
            c = np.where(((np.abs(X) < xin) & (D > 4))[:, None], rgb(inner), c)
        return c
    return f


def facet(P, n_world):
    sh = n_world @ LDIR
    return P[np.clip(((sh + 1) / 2 * (len(P) - 1) + .5).astype(int), 0, len(P) - 1)]


# ------------------------------------------------------------------ la grille
class W:
    def __init__(s):
        s.mat = np.zeros(N, np.uint8); s.col = np.zeros(N + (3,), np.float32); s.part = np.zeros(N, np.uint8)
        s.cur = 1; s.lights = []

    def sub(s, bb):
        sl = []
        for k in range(3):
            a = int(np.floor(bb[2 * k] - LO[k])); b = int(np.ceil(bb[2 * k + 1] - LO[k]))
            a = min(max(a, 0), N[k]); b = min(max(b, a), N[k]); sl.append(slice(a, b))
        ax = [LO[k] + .5 + np.arange(sl[k].start, sl[k].stop) for k in range(3)]
        X, Y, Z = np.meshgrid(*ax, indexing='ij')
        return tuple(sl), X, Y, Z

    def _set(s, sl, m, X, Y, Z, mat, col):
        if not m.any(): return
        M = s.mat[sl]
        if mat == 0:
            M[m] = 0; return
        C = s.col[sl]; P = s.part[sl]
        M[m] = mat; P[m] = s.cur
        C[m] = col(X[m], Y[m], Z[m]) if callable(col) else rgb(col)

    def put(s, bb, fn, mat, col):
        sl, X, Y, Z = s.sub(bb); s._set(sl, fn(X, Y, Z), X, Y, Z, mat, col)

    def carve(s, bb, fn): s.put(bb, fn, 0, None)

    def inlay(s, bb, fn, mat, col, depth=1, only=None):
        """remplace la couche de surface (profondeur depth) là où fn est vrai : gravure (mat 0), incrustation, fissure."""
        sl, X, Y, Z = s.sub(bb)
        solid = s.mat[sl] > 0; inner = solid.copy()
        for _ in range(depth): inner = erode(inner)
        m = fn(X, Y, Z) & solid & ~inner
        if only is not None: m &= np.isin(s.mat[sl], only)
        s._set(sl, m, X, Y, Z, mat, col)

    # ---- formes
    def sup(s, c, r, mat, col, p=4):
        c = np.asarray(c, float); r = np.asarray(r, float)
        s.put((c[0] - r[0] - 1, c[0] + r[0] + 1, c[1] - r[1] - 1, c[1] + r[1] + 1, c[2] - r[2] - 1, c[2] + r[2] + 1),
              lambda X, Y, Z: (np.abs(X - c[0]) / r[0]) ** p + (np.abs(Y - c[1]) / r[1]) ** p + (np.abs(Z - c[2]) / r[2]) ** p < 1, mat, col)

    def blob(s, c, r, mat, col, lumpy=.2, seed=0.):
        c = np.asarray(c, float); r = np.asarray(r, float); m_ = r.max() * (1 + lumpy) + 1
        s.put((c[0] - m_, c[0] + m_, c[1] - m_, c[1] + m_, c[2] - m_, c[2] + m_),
              lambda X, Y, Z: ((X - c[0]) / r[0]) ** 2 + ((Y - c[1]) / r[1]) ** 2 + ((Z - c[2]) / r[2]) ** 2 < 1 + lumpy * nz3(X, Y, Z, seed), mat, col)

    def blade(s, pts, mat, col, th0=1., slope=.6, thmax=6., zc=0., rough=0., jag=0., seed=0.):
        """lame / plaque : polygone (x, y) extrudé en z, section en losange (arêtes fines, dos épais)."""
        P = np.asarray(pts, float); (x0, y0), (x1, y1) = P.min(0) - 1, P.max(0) + 1
        sl, X, Y, Z = s.sub((x0, x1, y0, y1, zc - thmax - 3, zc + thmax + 3))
        X2, Y2 = X[:, :, 0], Y[:, :, 0]
        M2 = inpoly(X2, Y2, P)
        d = dist2(M2, int(thmax / slope) + 3)
        if jag:                                                            # bord de roche éclatée
            M2 &= ~((d <= 2) & (nz3(X2, Y2, X2 * 0, seed) > 1 - jag))
            d = dist2(M2, int(thmax / slope) + 3)
        th = np.minimum(thmax, th0 + slope * (d - 1))
        if rough: th = th + rough * nz3(X2 * 1.7, Y2 * 1.7, X2 * 0 + 3, seed)
        m = M2[:, :, None] & (np.abs(Z - zc) < th[:, :, None])
        if callable(col):
            D = np.broadcast_to(d[:, :, None], X.shape)
            s._set(sl, m, X, Y, Z, mat, lambda X_, Y_, Z_: col(X_, Y_, Z_, D[m]))
        else:
            s._set(sl, m, X, Y, Z, mat, col)

    def stroke(s, pts, r, th, mat, col, zc=0., inl=False, depth=1, only=None):
        """trait épais dans le plan x-y, extrudé |z - zc| < th (liserés, veines, filigranes)."""
        P = np.asarray(pts, float)
        bb = (P[:, 0].min() - r - 1, P[:, 0].max() + r + 1, P[:, 1].min() - r - 1, P[:, 1].max() + r + 1, zc - th - 1, zc + th + 1)
        def fn(X, Y, Z):
            dm = np.full(X.shape, np.inf)
            for a, b in zip(P[:-1], P[1:]):
                ab = b - a; L2 = ab @ ab + 1e-9
                u = np.clip(((X - a[0]) * ab[0] + (Y - a[1]) * ab[1]) / L2, 0, 1)
                dm = np.minimum(dm, np.hypot(X - a[0] - ab[0] * u, Y - a[1] - ab[1] * u))
            return (dm < r) & (np.abs(Z - zc) < th)
        if inl: s.inlay(bb, fn, mat, col, depth, only)
        else: s.put(bb, fn, mat, col)

    def tube(s, pts, rads, mat, col=None, tcol=None):
        """tube 3D (cornes, pointes, vrilles) ; tcol(t) colore selon la position 0..1 le long du tube."""
        P = np.asarray(pts, float); R = np.asarray(rads, float); rm = R.max() + 1
        sl, X, Y, Z = s.sub((P[:, 0].min() - rm, P[:, 0].max() + rm, P[:, 1].min() - rm, P[:, 1].max() + rm,
                             P[:, 2].min() - rm, P[:, 2].max() + rm))
        seg = np.linalg.norm(np.diff(P, axis=0), axis=1); cum = np.concatenate([[0], np.cumsum(seg)]); tot = max(cum[-1], 1e-6)
        best = np.full(X.shape, np.inf); T = np.zeros(X.shape)
        for i in range(len(P) - 1):
            a, ab = P[i], P[i + 1] - P[i]; L2 = ab @ ab + 1e-9
            u = np.clip(((X - a[0]) * ab[0] + (Y - a[1]) * ab[1] + (Z - a[2]) * ab[2]) / L2, 0, 1)
            dd = np.sqrt((X - a[0] - ab[0] * u) ** 2 + (Y - a[1] - ab[1] * u) ** 2 + (Z - a[2] - ab[2] * u) ** 2)
            v = dd - (R[i] + (R[i + 1] - R[i]) * u)
            w_ = v < best; best[w_] = v[w_]; T[w_] = ((cum[i] + u * seg[i]) / tot)[w_]
        m = best < 0
        if tcol is not None: col = (lambda tm: lambda *_: tcol(tm))(T[m])
        s._set(sl, m, X, Y, Z, mat, col)

    def gem(s, c, r, mat, col, rot=(0, 0, 0), shape='oct'):
        """gemme / cristal flottant : octaèdre (oct), ellipsoïde (ell) ; col = liste de tons -> facettes ombrées."""
        c = np.asarray(c, float); r = np.asarray(r, float); rm = r.max() + 1
        sl, X, Y, Z = s.sub((c[0] - rm, c[0] + rm, c[1] - rm, c[1] + rm, c[2] - rm, c[2] + rm))
        Rm = rotm(rot)
        loc = np.stack([X - c[0], Y - c[1], Z - c[2]], -1) @ Rm
        lx, ly, lz = loc[..., 0] / r[0], loc[..., 1] / r[1], loc[..., 2] / r[2]
        m = (np.abs(lx) + np.abs(ly) + np.abs(lz) < 1) if shape == 'oct' else (lx * lx + ly * ly + lz * lz < 1)
        if isinstance(col, list):
            P = pal(col)
            nl = np.stack([np.sign(lx) / r[0], np.sign(ly) / r[1], np.sign(lz) / r[2]], -1)
            nl /= np.linalg.norm(nl, axis=-1, keepdims=True) + 1e-9
            cols = facet(P, nl @ Rm.T)
            col = (lambda cm: lambda *_: cm)(cols[m])
        s._set(sl, m, X, Y, Z, mat, col)

    def crystal(s, base, dirv, L, R, mat, cs, tip=.35, twist=0.):
        """prisme hexagonal à pointe (glace, cristaux) ; facettes ombrées, arêtes et pointe plus claires."""
        b = np.asarray(base, float); d = np.asarray(dirv, float); d /= np.linalg.norm(d)
        u = np.cross(d, (0, 0, 1.))
        if np.linalg.norm(u) < .2: u = np.cross(d, (1., 0, 0))
        u /= np.linalg.norm(u); v = np.cross(d, u)
        e = b + d * L; lo_ = np.minimum(b, e) - R - 1; hi_ = np.maximum(b, e) + R + 1
        sl, X, Y, Z = s.sub((lo_[0], hi_[0], lo_[1], hi_[1], lo_[2], hi_[2]))
        rx, ry, rz = X - b[0], Y - b[1], Z - b[2]
        t = rx * d[0] + ry * d[1] + rz * d[2]; pu = rx * u[0] + ry * u[1] + rz * u[2]; pv = rx * v[0] + ry * v[1] + rz * v[2]
        hexd = np.max(np.stack([np.abs(pu * np.cos(a) + pv * np.sin(a)) for a in np.arange(3) * np.pi / 3 + twist]), 0)
        rad = R * np.clip(np.where(t < L * (1 - tip), 1., (L - t) / (L * tip)), 0, 1)
        m = (t > -R * .5) & (t < L) & (hexd < rad)
        k = np.round((np.arctan2(pv, pu) - twist) / (np.pi / 3)); na = k * np.pi / 3 + twist
        nw = np.cos(na)[..., None] * u + np.sin(na)[..., None] * v
        P = pal(cs); idx = np.clip((((nw @ LDIR) + 1) / 2 * (len(P) - 1) + .5).astype(int), 0, len(P) - 1)
        idx = np.where((t > L * (1 - tip)) | (hexd > rad - 1), np.minimum(idx + 1, len(P) - 1), idx)
        cols = P[idx]
        s._set(sl, m, X, Y, Z, mat, (lambda cm: lambda *_: cm)(cols[m]))

    def torus(s, c, R, r, n, mat, col):
        c = np.asarray(c, float); n = np.asarray(n, float); n /= np.linalg.norm(n); e = R + r + 1
        def fn(X, Y, Z):
            rx, ry, rz = X - c[0], Y - c[1], Z - c[2]; h = rx * n[0] + ry * n[1] + rz * n[2]
            q = np.sqrt(np.maximum(rx * rx + ry * ry + rz * rz - h * h, 0)) - R
            return q * q + h * h < r * r
        s.put((c[0] - e, c[0] + e, c[1] - e, c[1] + e, c[2] - e, c[2] + e), fn, mat, col)

    def flame(s, base, h, r, cs, seed=0.):
        """flamme en escalier (large en bas, fine en haut), lueur dégradée."""
        b = np.asarray(base, float); P = pal(cs)
        def fn(X, Y, Z):
            t = (Y - b[1]) / h; cx = b[0] + 1.8 * np.sin(t * 5 + seed) * t
            rad = r * np.clip(1 - t, 0, 1) ** .75 * (1 + .25 * np.sin(t * 14 + seed * 2))
            return (t >= 0) & (t < 1) & ((X - cx) ** 2 + ((Z - b[2]) * 1.2) ** 2 < rad * rad)
        s.put((b[0] - r - 3, b[0] + r + 3, b[1], b[1] + h, b[2] - r - 1, b[2] + r + 1), fn, 20,
              lambda X, Y, Z: P[np.clip(((Y - b[1]) / h * len(P)).astype(int), 0, len(P) - 1)])

    def light(s, pos, col, power):
        s.lights.append((pos, col, power))


# ------------------------------------------------------------------ manche commun
def handle(w, mat, col, r=5., y0=12, y1=172, wrap=None, rings=(), gold_wire=None):
    """manche octogonal (part 0, posé APRÈS la tête : la tête garde un vrai trou d'emmanchement)."""
    w.cur = 0
    w.put((-r - 1, r + 1, y0, y1, -r - 1, r + 1), lambda X, Y, Z: (Y >= y0) & (Y < y1) & (octd(X, Z) < r), mat, col)
    if wrap:                                                               # bandes de cuir en spirale, en relief
        ya, yb, wmat, (c1, c2), pitch = wrap
        def ph(X, Y, Z): return (Y + np.arctan2(Z, X) / (2 * np.pi) * pitch) % pitch
        w.put((-r - 2, r + 2, ya, yb, -r - 2, r + 2),
              lambda X, Y, Z: (Y >= ya) & (Y < yb) & (octd(X, Z) < r + 1.1) & (ph(X, Y, Z) < pitch * .8), wmat,
              lambda X, Y, Z: np.where(((ph(X, Y, Z) < 1.2) | (ph(X, Y, Z) > pitch * .8 - 1.2))[:, None], rgb(c2), rgb(c1)))
        if gold_wire:                                                      # fil d'or croisé par-dessus le cuir
            gm, gc = gold_wire
            for sgn in (1, -1):
                w.put((-r - 3, r + 3, ya, yb, -r - 3, r + 3),
                      lambda X, Y, Z, sgn=sgn: (Y >= ya) & (Y < yb) & (octd(X, Z) < r + 1.8) &
                      (np.abs(((Y + sgn * np.arctan2(Z, X) / (2 * np.pi) * pitch * 3) % (pitch * 1.5)) - pitch * .75) < .7), gm, gc)
    for (ya, h, rr, rmat, rcol) in rings:                                  # bagues biseautées
        w.put((-rr - 1, rr + 1, ya, ya + h, -rr - 1, rr + 1),
              lambda X, Y, Z, ya=ya, h=h, rr=rr: (Y >= ya) & (Y < ya + h) &
              (octd(X, Z) < np.where((Y < ya + 1) | (Y >= ya + h - 1), rr - .9, rr)), rmat, rcol)


# ================================================================== 1. DÉMONIAQUE
def demon(w):
    FN = ['121116', '1c1a21', '2a2731', '3c3746']
    RD = ['4a070c', '7d0d15', 'b5141f', 'e02a2a', 'ff4a3c']
    GL = 'ff2a14'
    w.cur = 1
    w.sup((0, 176, 0), (15, 22, 11), 1, vgrad(FN[:3], 154, 198), p=6)
    for ya, yb in ((154, 158), (194, 198)):                                # bagues de la douille
        w.put((-17, 17, ya, yb, -13, 13), lambda X, Y, Z: (Y >= ya) & (Y < yb) & ((np.abs(X) / 16.5) ** 6 + (np.abs(Z) / 12) ** 6 < 1), 1, FN[3])
    top = [(12, 190), (28, 195), (44, 194), (58, 188), (70, 178), (80, 164), (87, 148), (91, 130), (92, 114)]
    bot = [(86, 126), (80, 140)] + serrate((80, 140), (50, 167), 5, 5, -1)[1:] + [(50, 167), (38, 170), (26, 171), (12, 166)]
    for sx in (1, -1):
        pts = top + bot if sx > 0 else mir(top + bot)
        w.blade(pts, 4, edgecol(RD[4], RD[3], RD[2], RD[1], 26), th0=1., slope=.55, thmax=6.)
        spine = [(x, y - 1) for x, y in top[:8]]
        w.stroke(spine if sx > 0 else mir(spine), 2.6, 6.8, 1, FN[2])          # dos de lame en fer noir
        vein = [(16, 180), (32, 182), (50, 178), (64, 168), (76, 154), (84, 138), (88, 124)]
        for v in (vein, [(50, 178), (55, 172), (57, 166)], [(76, 154), (71, 151)], [(32, 182), (36, 176)]):
            w.stroke(v if sx > 0 else mir(v), 1.2, 9, 20, GL, inl=True, only=(4,))     # veine infernale
        for (a, b) in (((36, 194, 0), (38, 204, 0)), ((56, 188, 0), (62, 198, 0)), ((72, 175, 0), (81, 183, 0))):
            w.tube([(sx * a[0], a[1], 0), (sx * b[0], b[1], 0)], [2.8, .5], 1, tcol=lambda t: np.where((t > .6)[:, None], rgb(RD[3]), rgb(FN[3])))
        for (fx, fy, fh, fr) in ((46, 193, 17, 4.4), (64, 186, 13, 3.6)):
            w.flame((sx * fx, fy, 0), fh, fr, ['ff1a0a', 'ff3a10', 'ff6a1c'], seed=fx)
        # cornes annelées
        hp = [(9, 192, 0), (13, 201, 1), (20, 209, 3), (30, 214, 4), (41, 213, 3), (50, 207, 1), (55, 199, 0)]
        w.tube([(sx * x, y, z) for x, y, z in hp], [6, 5.6, 4.8, 3.8, 2.8, 1.6, .5], 11,
               tcol=lambda t: np.where(((t * 16) % 1 < .25)[:, None], .7, 1.) *
               np.where((t < .5)[:, None], rgb('17121a'), np.where((t < .62)[:, None], rgb('3a0b12'), np.where((t < .8)[:, None], rgb('7a0d16'), rgb('c4161f')))))
        w.tube([(sx * 5, 195, 0), (sx * 8, 207, 0)], [2.2, .4], 1, FN[3])
    w.tube([(0, 196, 0), (0, 213, 0)], [3.2, .4], 1, tcol=lambda t: np.where((t > .7)[:, None], rgb(RD[3]), rgb(FN[3])))
    for zs in (-1, 1):                                                     # l'œil central (devant + derrière)
        almond = lambda X, Y, rx, ry: np.abs(Y - 178) < ry * np.clip(1 - (X / rx) ** 2, 0, 1)
        w.carve((-14, 14, 168, 190, -13, 13), lambda X, Y, Z: almond(X, Y, 12, 7) & (Z * zs > 7.5))
        w.put((-14, 14, 168, 190, -13, 13), lambda X, Y, Z: almond(X, Y, 12, 7) & (Z * zs > 6) & (Z * zs <= 7.5), 1, FN[0])
        w.put((-14, 14, 168, 190, -13, 13), lambda X, Y, Z: almond(X, Y, 10, 5.2) & (Z * zs > 6) & (Z * zs <= 8.5), 20, GL)
        w.stroke([(-14, 185), (-7, 188), (0, 184.5), (7, 188), (14, 185)], 1.9, 1.4, 1, FN[3], zc=zs * 10.6)   # arcade en V
        w.stroke([(-11, 172.5), (0, 170), (11, 172.5)], 1.4, 1.2, 1, FN[3], zc=zs * 10.4)
        for k in range(12):                                                # runes gravées autour de l'œil
            a = np.radians(15 + k * 30); c, s_ = math.cos(a), math.sin(a)
            if abs(s_) < .3: continue
            w.stroke([(12.5 * .8 * c, 178 + 17 * .8 * s_), (12.5 * c, 178 + 17 * s_)], .6, 2, 0, None, zc=zs * 11, inl=True, depth=1)
        for crk in ([(-10, 160), (-6, 164), (-7, 168)], [(8, 158), (5, 163), (8, 166)]):
            w.stroke(crk, .8, 2.5, 20, GL, zc=zs * 10.5, inl=True)
        w.light((0, 178, zs * 20), GL, 120)
    handle(w, 1, octcol(FN[1], FN[2]), wrap=(18, 90, 5, ('5a0f16', '2e070b'), 7),
           rings=[(14, 4, 6.3, 1, FN[2]), (90, 4, 6.3, 1, FN[3]), (128, 3, 5.9, 1, FN[2]), (150, 4, 6.5, 1, FN[3])])
    for k in range(4):                                                     # bague à pointes
        a = np.radians(45 + 90 * k)
        w.tube([(6 * math.cos(a), 92, 6 * math.sin(a)), (10 * math.cos(a), 95, 10 * math.sin(a))], [1.7, .4], 1, FN[3])
    w.gem((0, 8, 0), (7, 8, 7), 1, [FN[1], FN[2], FN[3]])                  # pommeau + pointes + gemme rouge
    for k in range(4):
        a = np.radians(90 * k); c, s_ = math.cos(a), math.sin(a)
        w.tube([(5 * c, 8, 5 * s_), (10 * c, 5, 10 * s_)], [2, .4], 1, FN[3])
    for zs in (-1, 1):
        w.torus((0, 9, zs * 5.6), 3.4, 1, (0, 0, 1), 1, FN[3])
        w.gem((0, 9, zs * 5.6), (2.6, 2.6, 2), 9, ['8a0a10', 'd8141c', 'ff5a50'])


# ================================================================== 2. VOLCANIQUE
def volcan(w):
    BAS = ['100e0f', '1b1817', '2a2524', '3d3532']
    MAG, HOT, CRU = 'ff6412', 'ffb52e', '5a1608'
    w.cur = 1
    rock = lambda X, Y, Z: pal(BAS[1:])[np.clip((1.5 + nz3(X, Y, Z, 4) * 1.2).astype(int), 0, 2)]
    w.put((-19, 19, 150, 202, -15, 15), lambda X, Y, Z: (X / 16) ** 2 + ((Y - 176) / 23) ** 2 + (Z / 12) ** 2 < 1 + .18 * nz3(X, Y, Z, 1), 6, rock)
    L = [(-12, 192), (-30, 195), (-48, 190), (-64, 179), (-77, 163), (-86, 145), (-91, 124), (-90, 106),
         (-84, 120), (-77, 136), (-67, 151), (-54, 162), (-38, 169), (-24, 171), (-12, 168)]
    w.blade(L, 6, edgecol(BAS[3], BAS[2], BAS[1]), th0=2, slope=.7, thmax=8, rough=1.2, jag=.25, seed=2)
    Rr = [(12, 194), (28, 197), (42, 200), (54, 205), (62, 206), (66, 196), (67, 178), (66, 160), (62, 148),
          (54, 150), (42, 156), (28, 162), (12, 163)]
    w.blade(Rr, 6, edgecol(BAS[3], BAS[2], BAS[1]), th0=2.5, slope=.7, thmax=9, rough=1.0, jag=.25, seed=5)
    for c, r, sd in (((-30, 184, 0), (12, 8, 10), 1), ((34, 184, 0), (12, 10, 11), 2), ((0, 198, 0), (10, 6, 9), 3),
                     ((-56, 172, 0), (9, 6, 9), 4), ((50, 178, 0), (7, 9, 10), 5)):
        w.blob(c, r, 6, rock, lumpy=.28, seed=sd)
    # fissures de magma : diagramme de Voronoï, croûte sombre puis lueur
    rng = np.random.default_rng(7); seeds = np.c_[rng.uniform(-92, 70, 70), rng.uniform(100, 215, 70)]
    def gap(X, Y):
        d = np.sqrt((X[..., None] - seeds[:, 0]) ** 2 + (Y[..., None] - seeds[:, 1]) ** 2); d.sort(-1)
        return d[..., 1] - d[..., 0]
    bb = (-92, 72, 100, 216, -16, 16)
    w.inlay(bb, lambda X, Y, Z: gap(X[:, :, :1], Y[:, :, :1]).repeat(X.shape[2], 2) < 2.6, 6, CRU, depth=1, only=(6,))
    w.inlay(bb, lambda X, Y, Z: gap(X[:, :, :1], Y[:, :, :1]).repeat(X.shape[2], 2) < 1.3, 20,
            lambda X, Y, Z: np.where((gap(X, Y) < .55)[:, None], rgb(HOT), rgb(MAG)), depth=2, only=(6,))
    for zs in (-1, 1):                                                     # cratère de lave au centre
        w.carve((-9, 9, 169, 187, -15, 15), lambda X, Y, Z: (X / 7) ** 2 + ((Y - 178) / 7) ** 2 < 1 + .15 * nz3(X, Y, Z) - 0 * Z)
        w.put((-9, 9, 169, 187, -15, 15), lambda X, Y, Z: ((X / 7.5) ** 2 + ((Y - 178) / 7.5) ** 2 < 1) & (np.abs(Z) < 8.5), 20,
              lambda X, Y, Z: np.where(((X / 4) ** 2 + ((Y - 178) / 4) ** 2 < 1)[:, None], rgb(HOT), rgb(MAG)))
        w.torus((0, 178, zs * 11), 8.5, 2.4, (0, 0, 1), 6, BAS[3])
        w.light((0, 178, zs * 18), MAG, 110)
    for pts, bulb in (([(-72, 146, 0), (-72, 138, 0), (-71, 132, 0)], (-71, 130, 0)),
                      ([(58, 151, 0), (58, 143, 0), (59, 138, 0)], (59, 136, 0)),
                      ([(-40, 168, 2), (-40, 161, 2)], (-40, 159, 2))):
        w.tube(pts, [2.8, 2.0, 1.4][:len(pts)], 20, MAG)                   # coulées de lave
        w.gem(bulb, (2.4, 2.8, 2.4), 20, HOT, shape='ell')
    w.light((-71, 132, -10), MAG, 25); w.light((59, 138, -10), MAG, 25)
    OBS = ['0d0b10', '1b1622', '2e2638']
    handle(w, 7, octcol(OBS[1], OBS[2]), wrap=(18, 86, 5, ('2b1a14', '160d0a'), 7),
           rings=[(14, 5, 6.6, 6, BAS[2]), (86, 5, 6.6, 6, BAS[2]), (148, 6, 7, 6, BAS[3])])
    w.cur = 0
    w.inlay((-6, 6, 92, 148, -6, 6), lambda X, Y, Z: np.abs(((Y + np.arctan2(Z, X) / (2 * np.pi) * 26 + .9 * np.sin(Y * .7)) % 26) - 13) < .9,
            20, MAG, depth=1, only=(7,))
    w.blob((0, 8, 0), (7, 8, 7), 6, rock, lumpy=.25, seed=9)
    w.inlay((-9, 9, 0, 17, -9, 9), lambda X, Y, Z: (np.abs(np.sin(X * .5 + Y * .35)) < .12) | (np.abs(np.sin(Z * .5 - Y * .3)) < .12), 20, MAG, only=(6,))


# ================================================================== 3. GLACIALE
def givre(w):
    ST = ['5d6878', '8d99ab', 'bcc7d6', 'e6edf6']
    ICE = ['1c58b0', '3a8ae0', '72bdf4', 'bfe9ff']
    GLC = '8ff3ff'
    w.cur = 1
    w.sup((0, 176, 0), (13, 20, 10), 2, vgrad(ST[:3], 156, 196), p=4)
    for sx in (1, -1):
        tang = [(10, 190), (28, 188), (36, 182), (37, 170), (28, 164), (10, 162)]
        w.blade(tang if sx > 0 else mir(tang), 2, edgecol(ST[3], ST[2], ST[1]), slope=.6, thmax=7)
        for zs in (-1, 1):                                                 # flocon incrusté sur la soie
            for k in range(6):
                a = np.radians(k * 60)
                w.stroke([(sx * 24, 176), (sx * 24 + 5 * math.cos(a), 176 + 5 * math.sin(a))], .7, 2, 20, 'aef6ff', zc=zs * 6.5, inl=True)
    for (b, d, L, R, tp) in (((26, 177, 0), (1, -.15, 0), 34, 9.5, .3), ((52, 172, 0), (1, -.62, 0), 30, 7, .35),
                             ((70, 156, 0), (.55, -1, 0), 30, 5.2, .5), ((44, 182, 0), (.7, 1, .15), 18, 3.6, .45),
                             ((60, 174, 2), (.9, .8, .6), 13, 2.8, .5), ((50, 165, -2), (.4, -1, -.5), 12, 2.6, .5)):
        w.crystal(b, d, L, R, 8, ICE, tip=tp)                               # pic de glace (droite)
    for (b, d, L, R, tp) in (((-26, 177, 0), (-1, -.1, 0), 28, 8.5, .3), ((-48, 175, 0), (-1, .35, 0), 26, 5.5, .5),
                             ((-48, 170, 0), (-.8, -.8, 0), 30, 6, .5), ((-40, 184, 0), (-.5, 1, .2), 14, 3, .5),
                             ((-56, 168, -2), (-.6, -.3, -.8), 10, 2.4, .5)):
        w.crystal(b, d, L, R, 8, ICE, tip=tp)                               # fourche de glace (gauche)
    for (b, d, L, R) in (((0, 192, 0), (0, 1, 0), 24, 5.5), ((-6, 190, 0), (-.45, 1, 0), 16, 3.6), ((6, 190, 0), (.45, 1, 0), 16, 3.6),
                         ((0, 190, 5), (0, 1, .6), 12, 2.6), ((0, 190, -5), (0, 1, -.6), 12, 2.6)):
        w.crystal(b, d, L, R, 8, ICE, tip=.45)                              # couronne de cristaux
    for zs in (-1, 1):
        for (y, hw) in ((193, 13), (184, 12), (175, 11)):                  # chevrons d'armure en relief
            ch = [(-hw, y), (0, y - 9), (hw, y), (hw, y - 3), (0, y - 12), (-hw, y - 3)]
            w.put((-15, 15, y - 14, y + 1, -13, 13), (lambda P: lambda X, Y, Z: inpoly(X, Y, P) & (Z * zs > 8) & (Z * zs < 11.2))(ch), 2,
                  lambda X, Y, Z: np.where((np.abs(X) > 9)[:, None], rgb(ST[3]), rgb(ST[2])))
        w.torus((0, 168, zs * 11), 5.6, 1.6, (0, 0, 1), 2, ST[3])
        w.gem((0, 168, zs * 11), (4.6, 4.6, 2.6), 9, ['5ad0ff', 'a8eeff', 'e8fdff'], rot=(0, 0, 45))
        w.light((0, 170, zs * 18), GLC, 70)
    handle(w, 2, octcol(ST[1], ST[2]), wrap=(18, 88, 5, ('2c5592', '183462'), 7),
           rings=[(13, 4, 6.3, 2, ST[3]), (88, 4, 6.3, 2, ST[3]), (126, 3, 5.9, 2, ST[2]), (148, 5, 6.6, 2, ST[3])])
    w.cur = 0
    for k in range(6):
        a = np.radians(k * 60 + 30)
        w.crystal((5.5 * math.cos(a), 151, 5.5 * math.sin(a)), (math.cos(a), .7, math.sin(a)), 8, 1.7, 8, ICE, tip=.5)
    w.crystal((0, 15, 0), (0, -1, 0), 14.5, 5.2, 8, ICE, tip=.45)            # pommeau de glace
    for (dx, dz) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        w.crystal((dx * 3.5, 12, dz * 3.5), (dx, -1.3, dz), 8, 2, 8, ICE, tip=.5)


# ================================================================== 4. CÉLESTE
def celeste(w):
    GO = ['7a4e10', 'b9821f', 'e6b23e', 'ffd879', 'fff0c2']
    WH = ['9aa8c4', 'c6d1e6', 'e2e9f5', 'f4f7fc']
    GLW = 'fff1c0'
    w.cur = 1
    w.sup((0, 176, 0), (14, 21, 11), 3, vgrad(GO[1:4], 156, 196), p=4)
    for k in range(14):                                                    # couronne de rayons solaires
        a = np.radians(90 + (k - 6.5) * 13)
        if not (0 < math.sin(a) or abs(math.sin(a)) < .2): continue
        Lr = 26 if k % 2 == 0 else 20
        c, s_ = math.cos(a), math.sin(a); n = (-s_, c)
        ray = [(12 * c + 3 * n[0], 178 + 12 * s_ + 3 * n[1]), (Lr * c, 178 + Lr * s_), (12 * c - 3 * n[0], 178 + 12 * s_ - 3 * n[1])]
        w.blade(ray, 3, GO[3] if k % 2 == 0 else GO[2], th0=1, slope=.6, thmax=2.6)
    for sx in (1, -1):
        bl = [(12, 188), (30, 194), (50, 193), (68, 186), (82, 172), (91, 154), (95, 134), (86, 146), (74, 158),
              (58, 166), (40, 170), (24, 170), (12, 166)]
        w.blade(bl if sx > 0 else mir(bl), 8, edgecol(WH[3], WH[2], WH[1]), slope=.55, thmax=5.5)
        trim = [(x, y - 1) for x, y in bl[:7]]
        w.stroke(trim if sx > 0 else mir(trim), 2.4, 6.2, 3, GO[3])
        w.stroke([(sx * 18, 178), (sx * 50, 180), (sx * 76, 166), (sx * 88, 148)], .8, 8, 3, GO[2], inl=True, only=(8,))
        for row, (y0, ang, Lf, Wf) in enumerate(((189, -12, 26, 8), (180, -32, 22, 7), (171, -52, 17, 6))):   # ailes de plumes d'or
            for i, x0 in enumerate((14, 22, 30)):
                a = np.radians(ang); d = np.array((math.cos(a), math.sin(a))); nn = np.array((-d[1], d[0]))
                b = np.array((x0, y0 - i * 1.5))
                f = [tuple(b), tuple(b + d * Lf * .35 + nn * Wf / 2), tuple(b + d * Lf), tuple(b + d * Lf * .35 - nn * Wf / 2)]
                w.blade(f if sx > 0 else mir(f), 3, GO[3] if (i + row) % 2 else GO[2], th0=2, slope=.8, thmax=7 - row)
                rib = [tuple(b), tuple(b + d * Lf * .9)]
                w.stroke(rib if sx > 0 else mir(rib), .6, 8, 3, GO[1], inl=True, only=(3,))
    for zs in (-1, 1):                                                     # médaillon solaire + gemme de lumière
        w.put((-13, 13, 164, 192, -14, 14), lambda X, Y, Z: (X * X + (Y - 178) ** 2 < 11.5 ** 2) & (Z * zs > 0) & (Z * zs < 12.5), 3,
              lambda X, Y, Z: np.where((X * X + (Y - 178) ** 2 > 9.5 ** 2)[:, None], rgb(GO[3]), rgb(GO[2])))
        w.inlay((-13, 13, 164, 192, -14, 14), lambda X, Y, Z: np.abs(np.sqrt(X * X + (Y - 178) ** 2) - 8.3) < .6, 0, None)
        for k in range(8):
            a = np.radians(k * 45 + 22.5)
            w.stroke([(9 * math.cos(a), 178 + 9 * math.sin(a)), (11 * math.cos(a), 178 + 11 * math.sin(a))], .5, 1.5, 0, None, zc=zs * 12, inl=True)
        w.gem((0, 178, zs * 12), (5.6, 5.6, 2.6), 20, GLW, shape='ell')
        for k in range(8):                                                 # étoile à 8 branches autour de la gemme
            a = np.radians(k * 45); L_ = 9.5 if k % 2 == 0 else 7.5
            w.stroke([(5 * math.cos(a), 178 + 5 * math.sin(a)), (L_ * math.cos(a), 178 + L_ * math.sin(a))], .7, .9, 3, GO[4], zc=zs * 12.8)
        w.light((0, 178, zs * 18), GLW, 90)
    w.tube([(0, 196, 0), (0, 209, 0)], [3, 1.2], 3, GO[3])                  # flèche + étoile + auréole
    w.gem((0, 208, 0), (1.8, 6.5, 1.8), 3, [GO[2], GO[3], GO[4]])
    w.gem((0, 207, 0), (5, 1.8, 5), 3, [GO[2], GO[3], GO[4]], rot=(0, 45, 0))
    w.torus((0, 215, 0), 13, 1.1, (0, 1, 0), 20, GLW)
    w.light((0, 216, 0), GLW, 60)
    handle(w, 10, octcol('ece4d2', 'd8cdb6'), wrap=(18, 88, 5, ('f3ede0', 'c9bfa9'), 8), gold_wire=(3, GO[3]),
           rings=[(14, 4, 6.4, 3, GO[3]), (88, 4, 6.4, 3, GO[3]), (122, 3, 5.9, 3, GO[2]), (149, 5, 6.8, 3, GO[3])])
    w.gem((0, 8, 0), (6.5, 7.5, 6.5), 3, [GO[1], GO[2], GO[3]])
    for sx in (1, -1):
        wing = [(5, 10), (12, 15), (17, 13), (13, 9), (16, 6), (8, 5)]
        w.blade(wing if sx > 0 else mir(wing), 3, GO[3], th0=1, slope=.7, thmax=1.8)
    for zs in (-1, 1):
        w.gem((0, 9, zs * 5.5), (2.6, 2.6, 2), 9, ['d6e2ff', 'f4f8ff', 'ffffff'])


# ================================================================== 5. NÉANT
def neant(w):
    MT = ['0c0911', '17111f', '251b33', '3a2b52']
    VI = ['2b1260', '4b22a8', '7a45ef', 'b48cff', 'e3d2ff']
    GLV = 'b45cff'
    w.cur = 1
    w.sup((0, 176, 0), (14, 21, 11), 1, vgrad(MT[1:3], 156, 196), p=3)
    w.gem((0, 176, 0), (18, 26, 12.4), 1, [MT[1], MT[2], MT[3]])
    vio = edgecol(VI[3], VI[2], MT[2])
    sc = [(12, 190), (34, 197), (58, 194), (76, 182), (88, 164), (93, 144), (92, 124), (86, 108),
          (84, 124), (80, 142), (70, 158), (54, 170), (34, 176), (12, 172)]
    w.blade(sc, 1, vio, slope=.6, thmax=6)
    w.stroke([(18, 184), (40, 188), (60, 184), (76, 172), (85, 156), (88, 138)], 1.4, 9, 8, VI[2], inl=True, only=(1,))
    w.stroke([(52, 204), (62, 160)], 1.9, 9, 0, None)                        # fractures : fragments qui flottent
    w.stroke([(70, 146.5), (100, 146.5)], 1.9, 9, 0, None)
    w.tube([(53, 184, 0), (61, 180, 0)], [1, 1], 20, GLV)                    # ponts d'énergie dans les fractures
    w.tube([(86, 151, 0), (86, 142, 0)], [1, 1], 20, GLV)
    for cl in ([(-12, 190), (-38, 193), (-60, 182), (-74, 164), (-56, 172), (-34, 178), (-12, 176)],
               [(-12, 174), (-34, 170), (-52, 155), (-60, 136), (-46, 152), (-28, 162), (-12, 164)],
               [(-12, 186), (-24, 199), (-34, 213), (-28, 197), (-14, 180)]):
        w.blade(cl, 1, vio, slope=.6, thmax=5.5)
    for v in ([(-16, 184), (-38, 186), (-58, 176)], [(-16, 170), (-36, 165), (-52, 148)]):
        w.stroke(v, 1.2, 9, 8, VI[2], inl=True, only=(1,))
    for zs in (-1, 1):                                                     # portail : anneau d'énergie + cœur de vide
        w.carve((-8, 8, 169, 186, -15, 15), lambda X, Y, Z: (X * X + (Y - 177) ** 2 < 6.2 ** 2) & (Z * zs > 8))
        w.put((-8, 8, 169, 186, -15, 15), lambda X, Y, Z: (X * X + (Y - 177) ** 2 < 6.2 ** 2) & (Z * zs > 6.5) & (Z * zs <= 8), 14, '050308')
        w.torus((0, 177, zs * 10.8), 7.6, 1.7, (0, 0, 1), 20, GLV)
        w.light((0, 177, zs * 18), GLV, 110)
    for c, r, rot in (((-22, 210, 3), (3, 7, 3), (0, 0, 20)), ((24, 212, -3), (3, 7.5, 3), (0, 0, -25)),
                      ((-52, 200, 0), (2.6, 6, 2.6), (0, 0, 40)), ((62, 206, 0), (2.6, 6, 2.6), (0, 0, -40)),
                      ((-20, 140, 7), (2.4, 5.5, 2.4), (0, 0, 15)), ((22, 134, -7), (2.4, 5.5, 2.4), (0, 0, -20)),
                      ((0, 222, 0), (2, 3.4, 2), (0, 0, 0))):
        w.gem(c, r, 8, VI[1:], rot=rot)                                     # cristaux en orbite
    w.light((0, 212, -10), VI[3], 30)
    handle(w, 1, octcol(MT[1], MT[2]), rings=[(12, 4, 6.3, 1, MT[3]), (150, 5, 6.8, 1, MT[3])])
    w.cur = 0
    for y in range(18, 146, 16):                                           # plaques segmentées + joints lumineux
        w.put((-7, 7, y, y + 12, -7, 7), lambda X, Y, Z, y=y: (Y >= y) & (Y < y + 12) & (octd(X, Z) < np.where((Y < y + 1) | (Y >= y + 11), 5.3, 6.0)), 1,
              octcol(MT[2], MT[3]))
        w.inlay((-6, 6, y + 12, y + 16, -6, 6), lambda X, Y, Z, y=y: (Y >= y + 13) & (Y < y + 15), 20, GLV, only=(1,))
    for off in (0, np.pi):                                                 # vrilles d'énergie autour du manche
        t = np.linspace(0, 1, 28)
        w.tube([(7.6 * math.cos(off + tt * 3 * np.pi), 112 + 44 * tt, 7.6 * math.sin(off + tt * 3 * np.pi)) for tt in t],
               list(.5 + .6 * np.sin(np.pi * t)), 20, GLV)
    for k in range(3):                                                     # pommeau : griffe tenant un cristal
        a = np.radians(k * 120 + 90); c, s_ = math.cos(a), math.sin(a)
        w.tube([(3 * c, 14, 3 * s_), (7.5 * c, 9, 7.5 * s_), (5 * c, 2, 5 * s_)], [2.2, 1.5, .5], 1, MT[3])
    w.gem((0, 7.5, 0), (4.2, 6.5, 4.2), 8, VI[1:])


# ================================================================== 6. LÉGENDAIRE
def legende(w):
    MI = ['6c7d98', '9fb0c8', 'cfdae8', 'f2f6fb']
    GO = ['7a4e10', 'b9821f', 'e6b23e', 'ffd879', 'fff0c2']
    EN = ['0b1230', '16235a', '24388a']
    RUBY, SAPH, EMER, AME = ['7a0618', 'c3112c', 'ff3b56'], ['0c2a8a', '1f5ff0', '7fb2ff'], ['05603a', '12b062', '6ff0a8'], ['4a1680', '8a3ee0', 'c79bff']
    w.cur = 1
    w.sup((0, 176, 0), (15, 22, 11), 13, vgrad(EN, 156, 196), p=5)
    for ya, yb in ((154, 158), (194, 198)):
        w.put((-17, 17, ya, yb, -13, 13), lambda X, Y, Z: (Y >= ya) & (Y < yb) & ((np.abs(X) / 16.4) ** 5 + (np.abs(Z) / 12) ** 5 < 1), 3, GO[3])
    for sx in (1, -1):
        w.stroke([(sx * 12.5, 158), (sx * 12.5, 194)], 1.2, 12, 3, GO[2])
        bl = [(12, 190), (30, 198), (50, 199), (68, 192), (82, 179), (92, 160), (97, 138), (98, 118), (90, 132), (80, 148),
              (68, 160), (52, 168), (34, 172), (18, 171), (12, 168)]
        w.blade(bl if sx > 0 else mir(bl), 12, edgecol(MI[3], MI[2], MI[1]), slope=.6, thmax=6.2)
        ax_ = np.array((1, -.5)) / np.linalg.norm((1, -.5)); nx_ = np.array((-ax_[1], ax_[0]))
        def lens(X, Y, ra, rb, sx=sx):                                     # fente ouverte bordée d'or
            dx, dy = X - sx * 60, Y - 180
            u = dx * ax_[0] * sx + dy * ax_[1]; v = dx * nx_[0] * sx + dy * nx_[1]
            return (u / ra) ** 2 + (v / rb) ** 2 < 1
        w.put((sx * 60 - 16, sx * 60 + 16, 168, 192, -8, 8), lambda X, Y, Z: lens(X, Y, 14, 5) & (np.abs(Z) < 5.4), 3, GO[3])
        w.carve((sx * 60 - 16, sx * 60 + 16, 168, 192, -9, 9), lambda X, Y, Z: lens(X, Y, 11, 2.6))
        for v in ([(16, 181), (34, 185), (46, 186)], [(73, 171), (84, 158), (91, 142)]):
            w.stroke(v if sx > 0 else mir(v), 1.6, 9, 3, GO[2], inl=True, only=(12,))
        fil = [(16 + i * 4, 193 - (i * 4) * .05 + 1.4 * math.sin(i * 1.3) - (0 if i < 9 else (i - 8) * 2.4)) for i in range(14)]
        w.stroke(fil if sx > 0 else mir(fil), .7, 9, 3, GO[3], inl=True, only=(12,))   # filigrane
        for (x, y) in ((30, 198), (50, 199), (68, 192)):                   # crête en écailles de dragon
            fin = [(x - 6, y - 2), (x + 3, y + 9), (x + 6, y - 3)]
            w.blade(fin if sx > 0 else mir(fin), 3, GO[3], th0=1, slope=.7, thmax=2.2)
        for (x, y), cs in (((26, 184), RUBY), ((78, 166), SAPH), ((88, 149), EMER)):
            w.put((sx * x - 5, sx * x + 5, y - 5, y + 5, -8, 8), lambda X, Y, Z, x=x, y=y: ((X - sx * x) ** 2 + (Y - y) ** 2 < 4.4 ** 2)
                  & ((X - sx * x) ** 2 + (Y - y) ** 2 >= 2.6 ** 2) & (np.abs(Z) < 6.6), 3, GO[3])
            w.gem((sx * x, y, 0), (3, 3, 8), 9, cs, shape='ell')
    for zs in (-1, 1):
        for (px, py) in ((7.5, 7.5), (-7.5, 7.5), (7.5, -7.5), (-7.5, -7.5)):
            w.tube([(px, 177 + py, zs * 10.6), (px * .45, 177 + py * .45, zs * 13.5)], [1.4, .9], 3, GO[3])
        w.light((0, 177, zs * 20), 'cfeaff', 30)
        w.torus((0, 177, zs * 11), 9.4, 1.6, (0, 0, 1), 3, GO[3])          # chaton d'or
    w.gem((0, 177, 0), (10, 10, 19), 8, ['5f86b8', '9cc4ec', 'd8ecff', 'f4fbff'], rot=(0, 0, 45))   # grand diamant (8 = cristal)
    for (b, e, r) in (((0, 197, 0), (0, 215, 0), 3), ((-4, 197, 0), (-9, 211, 0), 2.4), ((4, 197, 0), (9, 211, 0), 2.4),
                      ((-7, 196, 0), (-15, 205, 0), 2), ((7, 196, 0), (15, 205, 0), 2)):
        w.tube([b, e], [r, .5], 3, GO[3])                                   # couronne
    for zs in (-1, 1):
        w.gem((0, 202, zs * 3.4), (2.8, 3.6, 2), 9, AME)
    handle(w, 13, octcol(EN[1], EN[2]), wrap=(18, 90, 5, ('1b2550', '0d1330'), 8), gold_wire=(3, GO[3]),
           rings=[(14, 4, 6.4, 3, GO[3]), (90, 4, 6.4, 3, GO[3]), (122, 3, 6, 3, GO[2]), (148, 6, 6.9, 3, GO[3])])
    for k in range(4):
        a = np.radians(45 + 90 * k)
        w.gem((6.6 * math.cos(a), 92, 6.6 * math.sin(a)), (1.7, 1.7, 1.7), 9, RUBY)
        w.gem((6.9 * math.cos(a), 151, 6.9 * math.sin(a)), (1.8, 1.8, 1.8), 9, SAPH)
        c, s_ = math.cos(a), math.sin(a)                                   # pommeau : cage d'or + rubis
        w.tube([(0, 14, 0), (4.5 * c, 11.5, 4.5 * s_), (6 * c, 7.5, 6 * s_), (4 * c, 3, 4 * s_), (0, 1, 0)], [1.4, 1.3, 1.3, 1.2, 1.4], 3, GO[3])
    w.gem((0, 7.5, 0), (4, 5, 4), 9, RUBY)


# ================================================================== ENTRÉE DE GAMME
# Outils de mineur débutant : matériaux simples (bois, silex, cuivre, fer, quartz), pas de lueur intégrée
# (sauf une petite améthyste sur le Quartz), mais le même soin du détail que les pioches légendaires.
WOOD = ['5a3a1e', '6e4826', '82582f', '976a3a']
ASH = ['9a7448', 'ad8656', 'c09a66', 'cfae7c']
DARKW = ['2a1c13', '35241a', '432f21', '533b29']
BARK = ['2a1d13', '3a2a1b', '4c3724']


def woodcol(axis, cs, yc=176., s=1.):
    """veinage du bois : cernes concentriques le long de l'axe de la pièce (y = manche, x = tête)."""
    P = pal(cs)
    def f(X, Y, Z, *_):
        if axis == 'y': g = np.hypot(X, Z) * .95 + nz3(X * .4, Y * .05, Z * .4, s) * 2.4
        else: g = np.hypot(Y - yc, Z) * .95 + nz3(X * .05, Y * .4, Z * .4, s) * 2.4
        return P[np.clip(((np.sin(g) + 1) / 2 * (len(P) - .01)).astype(int), 0, len(P) - 1)]
    return f


def stripes(c1, c2, k=1.3):
    """torsade de corde / cuir : rayures diagonales."""
    a, b = rgb(c1), rgb(c2)
    return lambda X, Y, Z, *_: np.where((np.sin((X + Y + Z) * k) > .2)[:, None], a, b)


def lash(w, xc, yc, ry, rz, mat, col, slant=0., half=1.5):
    """bande de ligature autour de la tête (corde, lanière) ; slant > 0 = bande en diagonale (ligature croisée)."""
    w.put((xc - half - abs(slant) * ry - 2, xc + half + abs(slant) * ry + 2, yc - ry - 1, yc + ry + 1, -rz - 1, rz + 1),
          lambda X, Y, Z: (np.abs(X - xc - slant * (Y - yc)) < half) & (((Y - yc) / ry) ** 4 + (Z / rz) ** 4 < 1), mat, col)


# ------------------------------------------------------------------ E1. BOIS (bûcheron)
def bois(w):
    w.cur = 1
    wd = woodcol('x', WOOD, 181, 1)
    def charred(X, Y, Z, *_):                                                # pointes durcies au feu
        t = np.clip((np.abs(X) - 56) / 22, 0, 1)[:, None]
        return wd(X, Y, Z) * (1 - .82 * t)
    w.blob((0, 179, 0), (12, 16, 9.5), 15, woodcol('y', WOOD, s=2), lumpy=.1, seed=1)   # nœud de la branche
    top = [(8, 190), (24, 194), (40, 192), (54, 186), (66, 176), (74, 164), (79, 151)]
    bot = [(73, 156), (63, 166), (49, 173), (33, 177), (18, 178), (8, 174)]
    for sx in (1, -1):
        w.blade(top + bot if sx > 0 else mir(top + bot), 15, charred, th0=1.6, slope=.7, thmax=7, rough=.6, seed=sx + 3)
        for zs in (-1, 1):                                                   # nœuds du bois, de face et de dos
            w.inlay((sx * 34 - 6, sx * 34 + 6, 179, 191, -10, 10),
                    lambda X, Y, Z: ((X - sx * 34) / 4.5) ** 2 + ((Y - 185) / 3) ** 2 < 1, 15, BARK[0], only=(15,))
            w.inlay((sx * 34 - 6, sx * 34 + 6, 179, 191, -10, 10),
                    lambda X, Y, Z: ((X - sx * 34) / 2.2) ** 2 + ((Y - 185) / 1.4) ** 2 < 1, 15, WOOD[3], only=(15,))
    w.inlay((-80, 80, 170, 200, -12, 12), lambda X, Y, Z: (nz3(X * .45, Y * .45, Z * .45, 2) > .85) & (np.abs(X) < 50), 15,
            lambda X, Y, Z: pal(BARK)[np.clip((nz3(X, Y, Z, 7) + 1.5).astype(int), 0, 2)], only=(15,))   # restes d'écorce
    w.blob((-24, 189, 2), (4, 3, 5), 15, BARK[1], lumpy=.3, seed=4)          # bosse d'écorce
    rope = stripes('c9a96a', '8f7442')
    for xc in (-14, 14):                                                     # ligature de corde croisée
        lash(w, xc, 181, 11, 9.4, 16, rope)
        lash(w, xc * .7, 181, 11, 9.8, 16, rope, slant=.45, half=1.2)
        lash(w, xc * .7, 181, 11, 9.8, 16, rope, slant=-.45, half=1.2)
    w.tube([(0, 193, 0), (2, 200, 0), (5, 207, 1)], [1.6, 1.2, .8], 19, '4f7a26')     # jeune pousse
    w.blade([(5, 206), (11, 213), (17, 212), (12, 206)], 19, edgecol('9ad655', '74bd3d', '559a2b'), th0=.6, slope=.5, thmax=1.3, zc=1)
    w.blade([(3, 204), (-4, 210), (-9, 207), (-3, 203)], 19, edgecol('9ad655', '74bd3d', '559a2b'), th0=.6, slope=.5, thmax=1.3, zc=0)
    handle(w, 15, woodcol('y', WOOD, s=3), wrap=(20, 82, 16, ('c9a96a', '8f7442'), 6),
           rings=[(16, 4, 6.2, 16, '8f7442'), (82, 4, 6.2, 16, '8f7442')])
    for (y, a, r) in ((112, 30, 2.4), (138, 200, 2), (98, 250, 1.8)):        # nœuds du manche
        c, s_ = math.cos(math.radians(a)), math.sin(math.radians(a))
        w.blob((4.6 * c, y, 4.6 * s_), (r, r * 1.4, r), 15, BARK[1], lumpy=.2, seed=y)
    w.blob((0, 9, 0), (7.5, 8.5, 7.5), 15, woodcol('y', BARK + WOOD[:2], s=5), lumpy=.3, seed=9)   # loupe du bois (pommeau)


# ------------------------------------------------------------------ E2. PIERRE (silex taillé)
FLINT = ['34343a', '46454b', '5b5856', '736d66', '8d857a']


def flintcol(seed):
    """éclats conchoïdaux : ondes concentriques autour de points d'impact."""
    rng = np.random.default_rng(seed); pts = np.c_[rng.uniform(-90, 90, 26), rng.uniform(140, 205, 26)]; P = pal(FLINT)
    def f(X, Y, Z, D=None):
        d = np.sqrt((X[:, None] - pts[:, 0]) ** 2 + (Y[:, None] - pts[:, 1]) ** 2); i = d.argmin(1); dm = d.min(1)
        g = np.sin(dm * .55 + i) * .45 + nz3(X * .2, Y * .2, Z * .2, seed) * .35 + (i % 3 - 1) * .3
        c = P[np.clip(((g + 1.1) / 2.2 * (len(P) - .01)).astype(int), 0, len(P) - 1)]
        if D is not None: c = np.where((D <= 1.5)[:, None], np.minimum(c * 1.35, 1), c)   # tranchant plus clair
        return c
    return f


def pierre(w):
    w.cur = 1
    fc = flintcol(3)
    R = [(4, 186), (22, 190), (40, 188), (56, 181), (70, 170), (80, 157), (86, 144), (78, 150), (66, 160), (50, 168), (32, 172), (14, 172), (4, 170)]
    L = [(-4, 188), (-20, 192), (-36, 192), (-50, 188), (-58, 182), (-62, 172), (-60, 164), (-52, 168), (-38, 172), (-20, 173), (-4, 170)]
    w.blade(R, 18, fc, th0=1.2, slope=.65, thmax=7, rough=.7, jag=.14, seed=4)   # pic de silex
    w.blade(L, 18, fc, th0=1.2, slope=.65, thmax=7.5, rough=.7, jag=.14, seed=6)  # tranchant large
    w.sup((0, 180, 0), (11, 15, 10.5), 15, woodcol('y', WOOD, s=4), p=3)       # mâchoire de bois
    leather = stripes('7a4a26', '4e2d16', 1.1)
    for xc in (-9, 9):                                                       # lanières de cuir croisées
        lash(w, xc, 180, 13, 11.4, 5, leather, half=1.6)
    lash(w, 0, 180, 13, 11.6, 5, leather, slant=.55, half=1.3)
    lash(w, 0, 180, 13, 11.6, 5, leather, slant=-.55, half=1.3)
    w.tube([(0, 192, 0), (0, 203, 0)], [3.4, 1.4], 10, 'e6dcc4')            # coin en os
    w.tube([(-6, 166, 9), (-9, 156, 11), (-10, 146, 11)], [.8, .8, .8], 5, '5e3a1c')   # cordelette + dent porte-bonheur
    w.tube([(-10, 146, 11), (-10, 136, 11)], [2.4, .4], 10, 'efe7d2')
    handle(w, 15, woodcol('y', ASH, s=6), wrap=(20, 84, 5, ('6b4423', '3e2614'), 6),
           rings=[(16, 4, 6.2, 5, '4e2d16'), (84, 4, 6.2, 5, '4e2d16'), (150, 3, 6, 5, '4e2d16')])
    w.blob((0, 9, 0), (7.5, 8, 7), 6, vgrad(['59575a', '6e6b6c', '858183'], 2, 16), lumpy=.08, seed=2)   # galet de rivière
    w.torus((0, 11, 0), 7, 1.3, (0, 1, 0), 5, '5e3a1c')


# ------------------------------------------------------------------ E3. CUIVRE
COP = ['6e3218', '9a4c25', 'bd6532', 'da8550', 'efa877']
VERD = ['2c7666', '4ba189', '79c7ac']


def cuivre(w):
    w.cur = 1
    P, V = pal(COP), pal(VERD)
    def copper(X, Y, Z, D=None):
        k = np.full(X.shape, 2) if D is None else np.where(D <= 1.5, 4, np.where(D <= 3, 3, 2))
        c = P[k] * (1 + .08 * np.sin(X * .7 + nz3(X, Y, Z, 3) * 2))[:, None]
        pat = (nz3(X * .35, Y * .35, Z * .35, 4) > .72) & (k <= 2)            # vert-de-gris dans les zones protégées
        return np.where(pat[:, None], V[np.clip((nz3(X, Y, Z, 8) + 1.3).astype(int), 0, 2)], c)
    w.sup((0, 177, 0), (12, 18, 10), 17, copper, p=6)
    for ya, yb in ((157, 161), (193, 197)):
        w.put((-14, 14, ya, yb, -12, 12), lambda X, Y, Z: (Y >= ya) & (Y < yb) & ((np.abs(X) / 13.4) ** 6 + (np.abs(Z) / 11) ** 6 < 1), 17, COP[3])
    top = [(10, 190), (26, 193), (42, 191), (56, 185), (68, 175), (77, 162), (83, 147)]
    bot = [(78, 152), (68, 163), (54, 171), (38, 175), (22, 176), (10, 173)]
    for sx in (1, -1):
        pts = top + bot if sx > 0 else mir(top[:-1] + [(80, 150), (77, 147)] + bot)   # côté gauche : bout en ciseau
        w.blade(pts if sx > 0 else pts, 17, copper, th0=1.2, slope=.6, thmax=6.5)
        ridge = [(12, 183), (30, 185), (46, 182), (60, 175), (70, 165)]
        w.stroke(ridge if sx > 0 else mir(ridge), 1.5, 7.4, 17, COP[3])      # nervure de coulée
        for zs in (-1, 1):
            for (x, y) in ((18, 184), (42, 183)):                            # rivets
                w.gem((sx * x, y, zs * 6.6), (1.8, 1.8, 1.4), 17, COP[4], shape='ell')
    for zs in (-1, 1):                                                       # poinçon du fondeur : deux pioches croisées
        for seg in ([(-6, 170), (6, 186)], [(6, 170), (-6, 186)], [(-9, 184), (-3, 188)], [(9, 184), (3, 188)]):
            w.stroke(seg, .8, 2, 17, COP[0], zc=zs * 10, inl=True)
        w.torus((0, 178, zs * 9.6), 9.5, .9, (0, 0, 1), 17, COP[4])
    handle(w, 15, woodcol('y', ASH, s=7), wrap=(20, 86, 5, ('7a4a26', '4a2a14'), 7),
           rings=[(15, 4, 6.3, 17, COP[3]), (86, 4, 6.3, 17, COP[3]), (150, 4, 6.4, 17, COP[3])])
    w.sup((0, 9, 0), (6.6, 8, 6.6), 17, copper, p=4)                         # embout de cuivre
    w.torus((0, 13, 0), 6.4, 1.1, (0, 1, 0), 17, COP[4])
    w.gem((0, 1.8, 0), (3, 2, 3), 17, COP[3], shape='ell')


# ------------------------------------------------------------------ E4. FER (forgée)
IRON = ['23252a', '32353c', '444851', '5a5f69']
STEEL = ['8a939f', 'b2bac6', 'dde3ea']


def fer(w):
    w.cur = 1
    P = pal(IRON)
    def iron(X, Y, Z, D=None):
        k = np.full(X.shape, 2) if D is None else np.where(D <= 1.5, 3, np.where(D <= 3, 2, 1))
        dimple = (np.sin(X * .8 + np.sin(Y * .5)) * np.sin(Y * .8 + np.sin(X * .4)) > .55)   # traces de marteau
        return P[k] * np.where(dimple, .82, 1.)[:, None]
    w.sup((0, 177, 0), (13, 19, 10.5), 1, iron, p=5)
    R = [(10, 191), (28, 194), (46, 192), (62, 185), (75, 173), (84, 158), (89, 141), (82, 148), (70, 160), (56, 169), (40, 174), (24, 176), (10, 172)]
    L = [(-10, 191), (-28, 192), (-44, 188), (-56, 180), (-64, 168), (-70, 155), (-75, 146), (-55, 146), (-51, 156), (-42, 166), (-26, 173), (-10, 172)]
    w.blade(R, 1, iron, th0=1, slope=.6, thmax=6.5)                          # pic forgé
    w.blade(L, 1, iron, th0=1.2, slope=.5, thmax=6.5)                        # herminette (tranchant plat)
    w.inlay((60, 92, 135, 175, -9, 9), lambda X, Y, Z: X > 72 + (Y - 140) * .5, 2,
            lambda X, Y, Z: pal(STEEL)[np.clip(((X - 70) / 7).astype(int), 0, 2)], depth=3, only=(1,))     # pointe d'acier trempé
    w.inlay((-80, -48, 142, 160, -9, 9), lambda X, Y, Z: Y < 151, 2, STEEL[1], depth=3, only=(1,))         # tranchant d'acier
    for zs in (-1, 1):
        for ya, yb in ((158, 162), (191, 195)):                              # frettes rivetées
            w.put((-15, 15, ya, yb, -13, 13), lambda X, Y, Z: (Y >= ya) & (Y < yb) & ((np.abs(X) / 14.4) ** 5 + (np.abs(Z) / 11.4) ** 5 < 1), 1, IRON[3])
        for x in (-8, 0, 8):
            w.gem((x, 160, zs * 11.2), (1.3, 1.3, 1), 2, STEEL[1], shape='ell')
            w.gem((x, 193, zs * 11.2), (1.3, 1.3, 1), 2, STEEL[1], shape='ell')
        w.put((-2.4, 2.4, 118, 158, -9, 9), lambda X, Y, Z: (np.abs(X) < 2.2) & (Z * zs > 5) & (Z * zs < 6.8), 1, IRON[2])   # attelles
        for y in (124, 140):
            w.gem((0, y, zs * 6.9), (1.3, 1.3, 1), 2, STEEL[1], shape='ell')
        w.stroke([(-7, 170), (0, 184), (7, 170)], .9, 2, 1, IRON[0], zc=zs * 10.5, inl=True)   # marque du forgeron
        w.stroke([(-4, 176), (4, 176)], .9, 2, 1, IRON[0], zc=zs * 10.5, inl=True)
    handle(w, 15, woodcol('y', DARKW, s=8), wrap=(22, 88, 5, ('5a3a22', '2e1d10'), 5),
           rings=[(17, 5, 6.4, 1, IRON[2]), (88, 4, 6.3, 1, IRON[2])])
    for y in range(26, 86, 6):                                               # coutures du cuir
        w.gem((0, y + 2, -6.6), (.7, 1.4, .7), 5, 'c7a77a', shape='ell')
    w.sup((0, 11, 0), (6.4, 6, 6.4), 1, iron, p=4)                           # virole + anneau de suspension
    w.torus((0, 4.6, 0), 3.2, 1.1, (0, 0, 1), 1, IRON[3])


# ------------------------------------------------------------------ E5. QUARTZ (rose)
ROSE = ['7a2e5a', 'b5508a', 'e07db0', 'ffc0dd']
AMT = ['4a1680', '8a3ee0', 'c79bff']
SILV = ['6d7684', '98a2b1', 'c4ccd8', 'e8edf3']


def quartz(w):
    w.cur = 1
    w.sup((0, 177, 0), (12, 17, 10), 2, vgrad(SILV[:3], 160, 194), p=5)
    R = [(10, 189), (26, 191), (40, 188), (52, 181), (58, 174), (54, 166), (42, 170), (26, 173), (10, 172)]
    w.blade(R, 2, edgecol(SILV[3], SILV[2], SILV[1]), th0=1.4, slope=.6, thmax=6.5)
    w.blade(mir([(10, 189), (26, 191), (40, 188), (48, 182), (50, 174), (40, 170), (26, 173), (10, 172)]), 2,
            edgecol(SILV[3], SILV[2], SILV[1]), th0=1.4, slope=.6, thmax=6.5)
    w.crystal((50, 176, 0), (1, -.5, 0), 40, 6.5, 8, ROSE, tip=.4)            # pic de quartz rose
    w.crystal((54, 180, 1), (.8, .4, .5), 13, 2.8, 8, ROSE, tip=.5)
    for (b, d, L, Rr) in (((-44, 176, 0), (-1, -.25, 0), 26, 5), ((-44, 180, 0), (-.7, .7, .1), 16, 3.4),
                          ((-46, 170, 0), (-.6, -1, -.2), 18, 3.6), ((-48, 176, 3), (-.7, 0, .8), 10, 2.4)):
        w.crystal(b, d, L, Rr, 8, ROSE, tip=.45)                              # bouquet de quartz (gauche)
    for (b, d, L, Rr) in (((0, 192, 0), (0, 1, 0), 18, 4.6), ((-4, 191, 1), (-.5, 1, .2), 12, 3), ((4, 191, -1), (.5, 1, -.3), 11, 2.8)):
        w.crystal(b, d, L, Rr, 8, ROSE, tip=.45)                              # couronne de quartz
    for zs in (-1, 1):
        w.torus((0, 175, zs * 10.4), 4.6, 1.3, (0, 0, 1), 2, SILV[3])
        w.gem((0, 175, zs * 10.4), (3.6, 3.6, 2.2), 9, AMT, rot=(0, 0, 45))   # améthyste sertie
        for k in range(4):
            a = np.radians(45 + 90 * k)
            w.gem((7.5 * math.cos(a), 175 + 7.5 * math.sin(a), zs * 10.3), (1.1, 1.1, .9), 2, SILV[3], shape='ell')
    for ya, yb in ((159, 163), (191, 195)):
        w.put((-14, 14, ya, yb, -12, 12), lambda X, Y, Z: (Y >= ya) & (Y < yb) & ((np.abs(X) / 13.4) ** 5 + (np.abs(Z) / 11) ** 5 < 1), 2, SILV[3])
    handle(w, 15, woodcol('y', DARKW, s=9), wrap=(20, 86, 5, ('5b2a6e', '2f1240'), 7),
           rings=[(15, 4, 6.3, 2, SILV[2]), (86, 4, 6.3, 2, SILV[2]), (150, 4, 6.4, 2, SILV[2])])
    w.sup((0, 15, 0), (6.4, 4, 6.4), 2, SILV[2], p=4)
    w.crystal((0, 13, 0), (0, -1, 0), 12, 4.4, 8, ROSE, tip=.45)              # pommeau de quartz


# ------------------------------------------------------------------ finitions (usure, cavités, rayures)
def finish(w, seed=0):
    M = w.mat; solid = M > 0
    occl = box3(solid, 2)
    p = np.pad(solid, 1)
    nb = (p[2:, 1:-1, 1:-1].astype(np.int8) + p[:-2, 1:-1, 1:-1] + p[1:-1, 2:, 1:-1] + p[1:-1, :-2, 1:-1] + p[1:-1, 1:-1, 2:] + p[1:-1, 1:-1, :-2])
    f = np.ones(N, np.float32)
    f *= 1 - .9 * np.clip(occl - .55, 0, .4)                               # creux et gravures plus sombres
    metal = np.isin(M, METALS)
    edge = solid & (nb <= 3)
    f[edge] *= np.where(metal[edge], 1.28, 1.12)                           # arêtes usées, plus claires
    ax = [LO[k] + .5 + np.arange(N[k]) for k in range(3)]
    X, Y, Z = np.meshgrid(*ax, indexing='ij')
    f *= 1 + .07 * nz3(X, Y, Z, seed)                                      # taches / patine
    rng = np.random.default_rng(seed + 11)
    X2, Y2 = X[:, :, 0], Y[:, :, 0]; scr = np.zeros(X2.shape, bool)
    for _ in range(90):                                                    # rayures fines sur le métal
        a = rng.uniform(0, np.pi); cx, cy = rng.uniform(-90, 90), rng.uniform(100, 222); L = rng.uniform(3, 12)
        dx, dy = math.cos(a), math.sin(a)
        scr |= (np.abs(-(X2 - cx) * dy + (Y2 - cy) * dx) < .5) & (np.abs((X2 - cx) * dx + (Y2 - cy) * dy) < L)
    surf = solid & ~erode(solid)
    f[scr[:, :, None] & surf & metal] *= 1.2
    f = np.round(f / .06) * .06                                            # paliers : faces fusionnables, look « palette »
    keep = solid & ~np.isin(M, FLAT)
    w.col[keep] = np.clip(w.col[keep] * f[keep][:, None], 0, 1)


# ------------------------------------------------------------------ maillage + matériaux + export
def make_mat(mid, stud_img):
    name, metal, rough, emit, stud = MATS[mid]
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; b = nt.nodes['Principled BSDF']
    at = nt.nodes.new('ShaderNodeAttribute'); at.attribute_name = 'Col'
    col = at.outputs['Color']
    if stud > 0:
        tx = nt.nodes.new('ShaderNodeTexImage'); tx.image = stud_img; tx.interpolation = 'Linear'
        mx = nt.nodes.new('ShaderNodeMix'); mx.data_type = 'RGBA'; mx.blend_type = 'OVERLAY'; mx.inputs['Factor'].default_value = stud
        nt.links.new(col, mx.inputs[6]); nt.links.new(tx.outputs['Color'], mx.inputs[7]); col = mx.outputs[2]
    nt.links.new(col, b.inputs['Base Color'])
    b.inputs['Metallic'].default_value = metal
    nz = nt.nodes.new('ShaderNodeTexNoise'); nz.inputs['Scale'].default_value = 7; nz.inputs['Detail'].default_value = 8
    mr = nt.nodes.new('ShaderNodeMapRange'); mr.inputs['To Min'].default_value = max(0, rough - .1); mr.inputs['To Max'].default_value = min(1, rough + .16)
    nt.links.new(nz.outputs['Fac'], mr.inputs['Value']); nt.links.new(mr.outputs['Result'], b.inputs['Roughness'])
    if mid in METALS or mid in (6, 7, 11, 13, 10, 15, 16, 18):             # micro-relief : piqûres, rayures, fibres
        n2 = nt.nodes.new('ShaderNodeTexNoise'); n2.inputs['Scale'].default_value = 25 if mid == 6 else 70; n2.inputs['Detail'].default_value = 10
        bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = .35 if mid == 6 else .12
        nt.links.new(n2.outputs['Fac'], bp.inputs['Height']); nt.links.new(bp.outputs['Normal'], b.inputs['Normal'])
    if emit:
        nt.links.new(at.outputs['Color'], b.inputs['Emission Color']); b.inputs['Emission Strength'].default_value = emit
    if mid in (8, 9, 7, 13):
        b.inputs['Coat Weight'].default_value = .7; b.inputs['Coat Roughness'].default_value = .03
    return m


def build(w, ID):
    solid = w.mat > 0
    rgb8 = np.round(np.clip(w.col, 0, 1) * 255).astype(np.int64)
    code = (w.mat.astype(np.int64) << 24) | (rgb8[..., 0] << 16) | (rgb8[..., 1] << 8) | rgb8[..., 2]
    ucode, cid = np.unique(np.where(solid, code, -1), return_inverse=True); cid = cid.reshape(N)
    UCOL = np.stack([(ucode >> 16) & 255, (ucode >> 8) & 255, ucode & 255], 1) / 255.0
    stud_img = bpy.data.images.load(STUD_PNG); stud_img.colorspace_settings.name = 'Non-Color'
    mats = {}; objs = []

    def piece(name, P, U, K, mat, mid, part):
        if 2 * len(P) > 19500:
            cen = P.mean(1); a = int(np.argmax(np.ptp(cen, 0))); o = np.argsort(cen[:, a]); h = len(o) // 2
            piece(name + 'a', P[o[:h]], U[o[:h]], K[o[:h]], mat, mid, part); piece(name + 'b', P[o[h:]], U[o[h:]], K[o[h:]], mat, mid, part)
            return
        nq = len(P); me = bpy.data.meshes.new(name)
        me.from_pydata(P.reshape(-1, 3).tolist(), [], np.arange(4 * nq).reshape(nq, 4).tolist())
        ca = me.color_attributes.new('Col', 'FLOAT_COLOR', 'CORNER')
        cc = np.repeat(lin(UCOL[K]), 4, axis=0)
        ca.data.foreach_set('color', np.concatenate([cc, np.ones((len(cc), 1))], 1).astype(np.float32).ravel())
        me.color_attributes.active_color = ca
        ul = me.uv_layers.new(name='UVMap'); ul.data.foreach_set('uv', U.reshape(-1, 2).astype(np.float32).ravel())
        bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4); bm.to_mesh(me); bm.free()
        me.materials.append(mat)
        ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
        ob['mat'] = mid; ob['part'] = part
        objs.append(ob)

    for p, pname in ((0, 'Manche'), (1, 'Tete')):
        occ = solid & (w.part == p)
        for mid in np.unique(w.mat[occ]):
            mid = int(mid)
            if mid not in mats: mats[mid] = make_mat(mid, stud_img)
            keys = np.where(occ & (w.mat == mid), cid, -1)
            P, U, K = brick_rig._quads(occ, keys, LO)
            if len(P): piece('%s_%s_%s' % (ID, pname, MATS[mid][0]), P, U, K, mats[mid], mid, pname)
    tris = {o.name: sum(len(f.vertices) - 2 for f in o.data.polygons) for o in objs}
    for k, v in tris.items(): print('  PIECE', k, v, 'tris')
    print('BUILD_OK', ID, 'bricks', int(solid.sum()), 'pieces', len(objs), 'tris', sum(tris.values()))
    return objs


def export(objs, out, ID):
    for o in bpy.context.scene.objects: o.select_set(o in objs)
    glb = os.path.join(out, ID + '.glb')
    try:
        bpy.ops.export_scene.gltf(filepath=glb, export_format='GLB', use_selection=True, export_yup=True, export_vertex_color='ACTIVE', export_apply=True)
    except TypeError:
        bpy.ops.export_scene.gltf(filepath=glb, export_format='GLB', use_selection=True, export_yup=True, export_apply=True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(out, ID + '.fbx'), use_selection=True, object_types={'MESH'}, colors_type='SRGB',
                             axis_forward='-Z', axis_up='Y', apply_scale_options='FBX_SCALE_ALL', path_mode='STRIP', mesh_smooth_type='FACE')
    print('EXPORT_OK', glb)


# ------------------------------------------------------------------ rendu studio
def B(p): return Vector((p[0] * S, p[2] * S, p[1] * S))


def studio(objs, w, ID, out):
    sc = bpy.context.scene
    eng = 'BLENDER_EEVEE' if 'BLENDER_EEVEE' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items.keys() else 'BLENDER_EEVEE_NEXT'
    sc.render.engine = eng
    for attr, v in (('taa_render_samples', 64), ('use_raytracing', True), ('use_shadows', True), ('use_gtao', True)):
        try: setattr(sc.eevee, attr, v)
        except Exception: pass
    try: sc.eevee.ray_tracing_options.trace_max_roughness = .7
    except Exception: pass
    sc.view_settings.view_transform = 'Standard'; sc.view_settings.look = 'None'
    sc.render.film_transparent = True
    sc.render.resolution_x, sc.render.resolution_y = 1000, 1300
    # monde : dégradé de studio (sol sombre, horizon gris, plafond clair) -> reflets sur le métal
    wd = bpy.data.worlds.new('Studio'); sc.world = wd; wd.use_nodes = True; nt = wd.node_tree
    bg = nt.nodes['Background']; tc = nt.nodes.new('ShaderNodeTexCoord'); sp = nt.nodes.new('ShaderNodeSeparateXYZ')
    cr = nt.nodes.new('ShaderNodeValToRGB')
    rm = nt.nodes.new('ShaderNodeMapRange'); rm.inputs['From Min'].default_value = -1; rm.inputs['From Max'].default_value = 1
    nt.links.new(tc.outputs['Normal'], sp.inputs[0])        # direction de vue ('Generated' ne marche pas en EEVEE); nt.links.new(sp.outputs['Z'], rm.inputs['Value'])
    nt.links.new(rm.outputs['Result'], cr.inputs['Fac'])
    # Generated du monde = direction (z de -1 à 1) -> fac = .5 + z/2 : sol noir, bande de softbox claire, plafond sombre
    e = cr.color_ramp.elements; e[0].position = .4; e[0].color = (.01, .01, .012, 1); e[1].position = 1.; e[1].color = (.3, .31, .34, 1)
    for pos, c in ((.48, .05), (.52, .2), (.57, .7), (.6, 1.3), (.7, 1.3), (.74, .18), (.86, .25)):
        e.new(pos).color = (c, c, c * 1.05, 1)
    nt.links.new(cr.outputs['Color'], bg.inputs['Color']); bg.inputs['Strength'].default_value = .8
    pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    mn = Vector([min(p[i] for p in pts) for i in range(3)]); mx = Vector([max(p[i] for p in pts) for i in range(3)])
    cen = (mn + mx) / 2; H = mx.z - mn.z; D = H * 1.7
    FH = max(H * 1.08, (mx.x - mn.x) * 1.3 * 1.14)                      # cadre portrait 1000x1300 : les pointes restent dedans
    def area(nm, d, power, size, col=(1, 1, 1)):
        L = bpy.data.lights.new(nm, 'AREA'); L.energy = power; L.size = size; L.color = col
        o = bpy.data.objects.new(nm, L); sc.collection.objects.link(o)
        o.location = cen + Vector(d).normalized() * D
        o.rotation_euler = (cen - o.location).to_track_quat('-Z', 'Y').to_euler()
    area('Cle', (-.7, -1, .55), 650, H * .22)
    area('Remplissage', (1, -.8, .05), 200, H * .5)
    area('ContreG', (-.9, 1, .5), 700, H * .2, (1, .92, .85))
    area('ContreD', (.9, .9, .3), 600, H * .2, (.85, .92, 1))
    for pos, col, pw in w.lights:                                          # la lueur éclaire ce qui l'entoure
        L = bpy.data.lights.new('Lueur', 'POINT'); L.energy = pw; L.color = tuple(lin(rgb(col))); L.shadow_soft_size = .3
        o = bpy.data.objects.new('Lueur', L); sc.collection.objects.link(o); o.location = B(pos)
    cam = bpy.data.objects.new('Cam', bpy.data.cameras.new('Cam')); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.lens = 85; cam.data.sensor_fit = 'VERTICAL'; cam.data.sensor_height = 24; cam.data.clip_end = 500
    fov = 2 * math.atan(12 / 85)
    black = bpy.data.materials.new('Noir'); black.use_nodes = True; bn = black.node_tree
    bn.nodes.remove(bn.nodes['Principled BSDF']); em = bn.nodes.new('ShaderNodeEmission'); em.inputs['Strength'].default_value = 0
    bn.links.new(em.outputs[0], bn.nodes['Material Output'].inputs['Surface'])
    head = B((0, 178, 0))
    views = (('face', cen, 0, 3, FH), ('34', cen, -40, 16, FH * .95), ('tete', head, -28, 10, 96 * S))
    flat = bpy.data.materials.new('LueurPlate'); flat.use_nodes = True; fn_ = flat.node_tree   # passe de lueur : couleur exacte
    fn_.nodes.remove(fn_.nodes['Principled BSDF']); fe = fn_.nodes.new('ShaderNodeEmission'); fa = fn_.nodes.new('ShaderNodeAttribute')
    fa.attribute_name = 'Col'; fn_.links.new(fa.outputs['Color'], fe.inputs['Color']); fe.inputs['Strength'].default_value = 1
    fn_.links.new(fe.outputs[0], fn_.nodes['Material Output'].inputs['Surface'])
    ren = os.path.join(out, 'render'); os.makedirs(ren, exist_ok=True)
    for nm, tgt, az, el, fh in views:
        dv = Vector((math.cos(math.radians(el)) * math.sin(math.radians(az)), -math.cos(math.radians(el)) * math.cos(math.radians(az)), math.sin(math.radians(el))))
        cam.location = tgt + dv * (fh / 2 / math.tan(fov / 2)); cam.rotation_euler = (-dv).to_track_quat('-Z', 'Y').to_euler()
        sc.render.filepath = os.path.join(ren, '%s_%s.png' % (ID, nm)); bpy.ops.render.render(write_still=True)
        keep = {}
        for o in objs:
            keep[o.name] = o.data.materials[0]; o.data.materials[0] = flat if o['mat'] == 20 else black
        sc.view_settings.view_transform = 'Standard'; keepw = sc.world; sc.world = None
        sc.render.filepath = os.path.join(ren, '%s_%s_glow.png' % (ID, nm)); bpy.ops.render.render(write_still=True)
        sc.world = keepw
        for o in objs: o.data.materials[0] = keep[o.name]
    print('RENDER_OK', ID)


DESIGNS = {'Demon': ('PiocheDemon', demon), 'Volcan': ('PiocheVolcan', volcan), 'Givre': ('PiocheGivre', givre),
           'Celeste': ('PiocheCeleste', celeste), 'Neant': ('PiocheNeant', neant), 'Legende': ('PiocheLegende', legende),
           'Bois': ('PiocheBois', bois), 'Pierre': ('PiochePierre', pierre), 'Cuivre': ('PiocheCuivre', cuivre),
           'Fer': ('PiocheFer', fer), 'Quartz': ('PiocheQuartz', quartz)}

if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    key = next((a for a in argv if a in DESIGNS), 'Demon')
    ID, fn = DESIGNS[key]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    w = W(); fn(w); finish(w, seed=len(ID))
    out = os.path.join(HERE, 'out_' + ID); os.makedirs(out, exist_ok=True)
    objs = build(w, ID)
    export(objs, out, ID)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, ID + '.blend'))
    if 'render' in argv: studio(objs, w, ID, out)
