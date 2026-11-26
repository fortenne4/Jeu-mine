"""12 casques des minerais (maquette previews/minerais/maquette-casques-epees.png).

Source unique : chaque casque est une liste de primitives Roblox (Part bloc / WedgePart) qui sert
  1. au module Luau src/partage/ArmuresVoxels/Casque<Minerai>.lua (Format = "Code", Parts construites en jeu,
     aucun asset importé => visible par tous les joueurs) ;
  2. à l'aperçu previews/armes/casques_minerais/Casque<Minerai>.png (vue 3/4 comme la maquette).

Blender (génère les modules + les rendus) :
  blender -b --factory-startup --python casques_minerais.py [-- Quartz Soufre ...]
Python normal (planche de comparaison maquette | rendu, nécessite Pillow) :
  python casques_minerais.py

Repère = repère Roblox : origine = centre de la tête R15 (1.2 stud), devant = -Z, haut = +Y, droite du perso = +X.
Dans Blender : (x, y, z)_Roblox -> (x, -z, y).
"""
import math, os, sys, random

ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.abspath(os.path.join(ICI, '..', '..'))
D_LUA = os.path.join(JEU, 'src', 'partage', 'ArmuresVoxels')
D_PNG = os.path.join(JEU, 'previews', 'armes', 'casques_minerais')
F_MAQ = os.path.join(JEU, 'previews', 'minerais', 'maquette-casques-epees.png')

LISTE = ['Quartz', 'Soufre', 'Argent', 'Obsidienne', 'Givrite', 'Emeraude', 'Rubis', 'Lunarite',
         'Magmaite', 'Diamant', 'Orichalque', 'Neantite']

try:
    import bpy, bmesh
    BLENDER = True
except ImportError:
    BLENDER = False


# ================================================================== planche (python + Pillow)
def planche():
    from PIL import Image, ImageDraw
    maq = Image.open(F_MAQ).convert('RGB')
    cols = [(20, 250), (405, 635), (790, 1020), (1170, 1400)]
    rows = [(125, 360), (408, 640), (690, 940)]
    T = 300
    out = Image.new('RGB', (4 * 2 * T, 3 * T), (24, 24, 26))
    for i, m in enumerate(LISTE):
        r, c = divmod(i, 4)
        ref = maq.crop((cols[c][0], rows[r][0], cols[c][1], rows[r][1])).resize((T, T))
        out.paste(ref, (c * 2 * T, r * T))
        f = os.path.join(D_PNG, 'Casque%s.png' % m)
        if os.path.exists(f):
            out.paste(Image.open(f).convert('RGB').resize((T, T)), (c * 2 * T + T, r * T))
        ImageDraw.Draw(out).text((c * 2 * T + 6, r * T + 4), m, fill=(255, 255, 255))
    f = os.path.join(D_PNG, '_comparaison.png')
    out.save(f)
    print('PLANCHE', f)


if not BLENDER:
    planche()
    sys.exit(0)

from mathutils import Vector, Matrix

# ================================================================== géométrie (repère Roblox)
I3 = Matrix.Identity(3)
UP = Vector((0, 1, 0))


def V(x, y, z):
    return Vector((x, y, z))


def rot(axe, deg):
    return Matrix.Rotation(math.radians(deg), 3, axe)


def repere(n, bhint):
    """Base directe (a, b, n) : colonnes = axes locaux X, Y, Z ; Z = n, Y au plus près de bhint."""
    n = Vector(n).normalized()
    b = Vector(bhint)
    b = (b - n * b.dot(n)).normalized()
    a = b.cross(n)
    return Matrix((a, b, n)).transposed()


def repere_y(y, zhint):
    y = Vector(y).normalized()
    z = Vector(zhint)
    z = (z - y * z.dot(y))
    if z.length < 1e-6:
        z = Vector((1, 0, 0)) - y * y.x
    z.normalize()
    x = y.cross(z)
    return Matrix((x, y, z)).transposed()


DIAG = Vector((1, 1, 1)).normalized().rotation_difference(Vector((0, 1, 0))).to_matrix()

P = []          # pièces du casque en cours
RND = random.Random(1)


def piece(nom, cle, taille, pos, R=I3, forme='Bloc', tag=None):
    p = dict(nom=nom, cle=cle, forme=forme, taille=Vector(taille), pos=Vector(pos), R=R.copy(), tag=tag)
    P.append(p)
    return p


def jit(R, a):
    if a <= 0:
        return R
    return R @ rot('X', RND.uniform(-a, a)) @ rot('Y', RND.uniform(-a, a)) @ rot('Z', RND.uniform(-a, a))


def barre(nom, cle, p0, p1, w, ep, n, ext=None, tag=None):
    """Barre plate de p0 à p1 (largeur w dans le plan, épaisseur ep selon n)."""
    p0, p1 = Vector(p0), Vector(p1)
    d = p1 - p0
    R = repere_y(d, n)
    return piece(nom, cle, (w, d.length + (w if ext is None else ext), ep), (p0 + p1) / 2, R, tag=tag)


def losange(nom, cle, c, n, cote, ep, up=UP, tag=None):
    return piece(nom, cle, (cote, cote, ep), c, repere(n, up) @ rot('Z', 45), tag=tag)


def triangle(nom, cle, a, b, c, ep, dehors, tag=None):
    """Triangle plein (2 WedgePart, technique classique Roblox) ; face extérieure (côté 'dehors') sur le plan abc."""
    a, b, c = Vector(a), Vector(b), Vector(c)
    # base = arête la plus longue
    for _ in range(3):
        if (b - a).length >= (c - b).length and (b - a).length >= (a - c).length:
            break
        a, b, c = b, c, a
    ab = b - a
    t = (c - a).dot(ab) / ab.length_squared
    h = a + ab * t
    n = ab.cross(c - a).normalized()
    if n.dot(Vector(dehors)) < 0:
        n = -n
    hc = c - h
    if hc.length < 1e-4:
        return
    for A in (a, b):
        ha = A - h
        if ha.length < 1e-4:
            continue
        Y = hc.normalized()
        Z = (-ha).normalized()
        X = Y.cross(Z)
        R = Matrix((X, Y, Z)).transposed()
        ctr = h + hc / 2 + ha / 2 - n * (ep / 2)
        piece(nom, cle, (ep, hc.length, ha.length), ctr, R, forme='Coin', tag=tag)
        tag = None


def pyramide(nom, cles, coins, sommet, ep=0.05, centre=None, tag=None):
    """Facettes triangulaires d'un sommet vers un polygone fermé de coins (couleurs alternées)."""
    centre = Vector(centre) if centre is not None else sum((Vector(c) for c in coins), Vector()) / len(coins)
    for i in range(len(coins)):
        p, q = Vector(coins[i]), Vector(coins[(i + 1) % len(coins)])
        m = (p + q + Vector(sommet)) / 3
        triangle(nom, cles[i % len(cles)], p, q, sommet, ep, m - centre, tag=tag if i == 0 else None)


def cristal(nom, cle, base, d, L, w, tour=45, zhint=V(0, 0, 1), cle2=None, tag=None, pointe=None):
    """Prisme carré tourné + pointe pyramidale à 4 facettes (WedgeParts)."""
    d = Vector(d).normalized()
    pt = pointe if pointe is not None else min(w * 1.1, L * 0.45)
    Lb = max(L - pt, 0.02)
    Rb = repere_y(d, zhint) @ rot('Y', tour)
    base = Vector(base)
    piece(nom, cle, (w, Lb, w), base + d * (Lb / 2), Rb, tag=tag)
    top = base + d * Lb
    coins = [top + Rb.col[0] * (sx * w / 2) + Rb.col[2] * (sz * w / 2) for sx, sz in ((1, 1), (1, -1), (-1, -1), (-1, 1))]
    pyramide(nom, [cle, cle2 or cle], coins, base + d * L, ep=min(0.025, w * 0.12), centre=top)


def pointe_cube(nom, cle, c, d, a, tour=0, zhint=V(0, 0, 1)):
    piece(nom, cle, (a, a, a), c, repere_y(d, zhint) @ rot('Y', tour) @ DIAG)


def tente(nom, cle, base, d, L, wx, wz, zhint, R_extra=I3):
    """Pointe en toit : 2 WedgePart dos à dos (arête selon X local au bout de d)."""
    R = repere_y(d, zhint) @ R_extra
    c = Vector(base) + R.col[1] * (L / 2)
    for sgn, Rw in ((-1, R), (1, R @ rot('Y', 180))):
        piece(nom, cle, (wx, L, wz / 2), c + R.col[2] * (sgn * wz / 4), Rw, forme='Coin')


def panneau(nom, cle, p00, p10, p01, p11, ep, j=0, ext=0.012, tag=None):
    """Plaque tendue sur un quadrilatère (bas p00-p10, haut p01-p11), face extérieure sur la corde."""
    c = (p00 + p10 + p01 + p11) / 4
    u = (p10 + p11) / 2 - (p00 + p01) / 2
    v = (p01 + p11) / 2 - (p00 + p10) / 2
    n = u.cross(v)
    out = c - V(CX, min(c.y, CY), CZ)
    if n.dot(out) < 0:
        n = -n
    R = repere(n, v)
    w = max((p10 - p00).length, (p11 - p01).length) + ext
    h = abs(v.dot(R.col[1])) + ext
    return piece(nom, cle, (w, h, ep), c - R.col[2] * (ep / 2), jit(R, j), tag=tag)


# ------------------------------------------------------------------ coque commune
CX, CY, CZ = 0.0, 0.16, 0.02
RX, RY, RZ = 0.76, 0.8, 0.8


def pd(th, ph, dr=0.0):
    t, p = math.radians(th), math.radians(ph)
    return V(CX + (RX + dr) * math.sin(t) * math.cos(p), CY + (RY + dr) * math.sin(p),
             CZ - (RZ + dr) * math.cos(t) * math.cos(p))


def pm(th, y, dr=0.0):
    t = math.radians(th)
    return V(CX + (RX + dr) * math.sin(t), y, CZ - (RZ + dr) * math.cos(t))


def normale(th, tilt=0.0):
    t = math.radians(th)
    n = V(math.sin(t), 0, -math.cos(t))
    a = math.radians(tilt)
    return (n * math.cos(a) + UP * math.sin(a)).normalized()


def dome(cle_fn, ep=0.08, j=0, lats=(0, 30, 56, 78), dr=0.0, nom='Coque'):
    for b in range(len(lats) - 1):
        for i in range(12):
            c = i * 30 if i <= 6 else i * 30 - 360
            k = cle_fn(c, b)
            if not k:
                continue
            panneau(nom, k, pd(c - 15, lats[b], dr), pd(c + 15, lats[b], dr), pd(c - 15, lats[b + 1], dr),
                    pd(c + 15, lats[b + 1], dr), ep, j)
    k = cle_fn(None, 'cap')
    if k:
        ph = math.radians(lats[-1])
        y = CY + (RY + dr) * math.sin(ph)
        for a in (0, 45):
            piece(nom, k, (2 * (RX + dr) * math.cos(ph) * 0.96, ep * 1.4, 2 * (RZ + dr) * math.cos(ph) * 0.92),
                  V(CX, y - ep * 0.4, CZ), jit(rot('Y', a), j))


def murs(cle_fn, ys, ep=0.08, j=0, dr=0.0, nom='Coque'):
    for r in range(len(ys) - 1):
        for i in range(12):
            c = i * 30 if i <= 6 else i * 30 - 360
            k = cle_fn(c, r)
            if not k:
                continue
            panneau(nom, k, pm(c - 15, ys[r + 1], dr), pm(c + 15, ys[r + 1], dr), pm(c - 15, ys[r], dr),
                    pm(c + 15, ys[r], dr), ep, j)


def bandeau(cle, y0, y1, th_max=100, dr=0.06, ep=0.1, v=0.0, pas=20, nom='Bandeau', cle_v=None, j=0):
    """Bandeau autour du front/des côtés ; v > 0 : pointe en V vers le bas au milieu du front."""
    th = -th_max
    h = y1 - y0
    while th < th_max - 1e-6:
        a, b = th, th + pas
        th = b
        if v > 0 and (abs(a) < 1e-6 or abs(b) < 1e-6):
            continue
        panneau(nom, cle, pm(a, y0, dr), pm(b, y0, dr), pm(a, y1, dr), pm(b, y1, dr), ep, j)
    if v > 0:
        ym = (y0 + y1) / 2
        pc = pm(0, ym - v, dr + 0.03)
        for s in (1, -1):
            q = pm(s * pas, ym, dr)
            barre(nom, cle, pc, q, h, ep, normale(s * pas / 2), ext=h * 0.5)
        losange(nom, cle_v or cle, pm(0, ym - v - h * 0.18, dr + 0.02) - V(0, 0, ep / 2), V(0, 0, -1), h * 0.95, ep)


def lames(cle_fn, rangs, ep=0.07, j=0, nom='Lames', pointe=None):
    """rangs : (y_haut, hauteur, dr, inclinaison°, centres, largeur°)."""
    for ri, (yh, h, dr, tilt, centres, larg) in enumerate(rangs):
        for c in centres:
            k = cle_fn(c, ri)
            if not k:
                continue
            n0 = normale(c)
            t = math.radians(tilt)
            bas = (-UP * math.cos(t) + n0 * math.sin(t))
            nn = (n0 * math.cos(t) + UP * math.sin(t))
            haut = pm(c, yh, dr)
            w = 2 * (RX + dr + 0.05) * math.sin(math.radians(larg / 2))
            R = repere(nn, -bas)
            ctr = haut + bas * (h / 2) - nn * (ep / 2)
            piece(nom, k, (w, h, ep), ctr, jit(R, j))
            if pointe:
                losange(nom, pointe(c, ri) or k, haut + bas * h - nn * (ep / 2), nn, w * 0.5, ep * 0.9, up=-bas)


def joue(s, cle_cadre, cles_insert, alpha=40.0, r=0.8, u0=-0.18, u1=0.36, vtop=0.14, vbot=-0.8, vext=-0.55,
         w=0.075, ep=0.08, insert=True, pointe=True, j=4, nom='Joues', diag=0.13, tag=None):
    a = math.radians(alpha)
    O = V(s * r * math.sin(a), 0, CZ - r * math.cos(a))
    n = V(s * math.sin(a), 0, -math.cos(a))
    t = V(s * math.cos(a), 0, math.sin(a))

    def Q(u, v, d=0.0):
        return O + t * u + UP * v + n * d
    d0 = ep / 2
    barre(nom, cle_cadre, Q(u0, vbot, d0), Q(u0, vtop - diag, d0), w, ep, n)
    barre(nom, cle_cadre, Q(u0, vtop - diag, d0), Q(u0 + diag, vtop, d0), w, ep, n)
    barre(nom, cle_cadre, Q(u0, vbot, d0), Q(u1, vext, d0), w, ep, n)
    barre(nom, cle_cadre, Q(u1, vext, d0), Q(u1, vtop + 0.04, d0), w, ep, n)
    if pointe:
        losange(nom, cle_cadre, Q(u0, vbot - 0.02, d0), n, w * 1.25, ep)
    if insert:
        R = repere(n, UP)
        um = (u0 + u1) / 2 + 0.01
        cols = [(u0 + w / 2, um), (um, u1 - w / 2)]
        for i, (ua, ub) in enumerate(cols):
            k = cles_insert[i % len(cles_insert)]
            piece(nom, k, (ub - ua + 0.01, vtop - vext, 0.05), Q((ua + ub) / 2, (vtop + vext) / 2, 0.0),
                  jit(R, j), tag=tag if i == 0 else None)
        # bas en biseau, parallèle à la barre du bas
        dd = Q(u1, vext) - Q(u0, vbot)
        Rb = repere_y(dd, n)
        hb = 0.16
        cb = (Q(u0, vbot, 0.0) + Q(u1, vext, 0.0)) / 2 + Rb.col[0] * (hb / 2 * (1 if Rb.col[0].y > 0 else -1))
        piece(nom, cles_insert[-1], (hb, dd.length - 0.04, 0.05), cb, jit(Rb, j))
    return Q


def gemme(cle_cadre, cle_gemme, c, n, cote, ep=0.07, up=UP, nom='Gemme', cle_gemme2=None):
    d = cote * math.sqrt(2)
    gemme_longue(cle_cadre, cle_gemme, c, n, d * 0.66, d * 0.66, ep, up, nom, cadre=d * 0.17, cle_gemme2=cle_gemme2)


def gemme_longue(cle_cadre, cle_gemme, c, n, L, w, ep=0.07, up=UP, nom='Gemme', cadre=0.05, cle_gemme2=None):
    """Gemme en losange (L haut x w large) à 4 facettes, dans une monture en losange plat."""
    n = Vector(n).normalized()
    R = repere(n, up)
    c = Vector(c)
    X, Y = R.col[0], R.col[1]

    def los(cc, ww, LL):
        return [cc + Y * (LL / 2), cc + X * (ww / 2), cc - Y * (LL / 2), cc - X * (ww / 2)]
    cd = los(c, w + 2 * cadre, L + 2.6 * cadre)
    triangle(nom, cle_cadre, cd[0], cd[1], cd[3], ep, n)
    triangle(nom, cle_cadre, cd[2], cd[1], cd[3], ep, n)
    cg = c + n * 0.01
    pyramide(nom, [cle_gemme, cle_gemme2 or cle_gemme], los(cg, w, L), cg + n * (min(w, L) * 0.3), ep=0.03,
             centre=c - n * 0.2, tag='lumiere')


def rivet(cle, c, n, t=0.06, nom='Rivets'):
    losange(nom, cle, Vector(c) - Vector(n).normalized() * (t * 0.15), n, t, t * 0.5)


# ================================================================== les 12 casques
CASQUES = {}


def casque(nom_aff, lumiere, particules=None):
    def deco(fn):
        CASQUES[fn.__name__] = dict(fn=fn, nom=nom_aff, lumiere=lumiere, particules=particules)
        return fn
    return deco


def alterne(*cles):
    def f(c, b):
        return cles[RND.randrange(len(cles))]
    return f


LAMES_STD = [(0.02, 0.5, 0.04, 5, [90, 120, 150, 180, -150, -120, -90], 34),
             (-0.32, 0.48, 0.08, 9, [75, 105, 135, 165, -165, -135, -105, -75], 34)]


# ------------------------------------------------------------------ Quartz
@casque("Casque de Quartz", ((255, 190, 230), 6, 0.8))
def Quartz():
    M = {'pierre': ('Slate', (128, 112, 120), 0, 0, 0.8, 0), 'pierre2': ('Slate', (104, 92, 100), 0, 0, 0.85, 0),
         'cadre': ('Slate', (150, 134, 140), 0, 0, 0.75, 0),
         'quartz': ('SmoothPlastic', (232, 186, 218), 0.1, 0, 0.25, 0),
         'quartz2': ('SmoothPlastic', (210, 156, 196), 0.1, 0, 0.25, 0),
         'quartz3': ('SmoothPlastic', (246, 214, 236), 0.15, 0, 0.2, 0),
         'lueur': ('Neon', (255, 205, 236), 0, 0, 0.3, 1.5)}

    def cd(c, b):
        if b == 'cap':
            return 'quartz3'
        if c is not None and abs(c) <= 30 + (30 if b == 1 else 0):
            return RND.choice(['quartz', 'quartz2', 'quartz3'])
        return RND.choice(['pierre', 'pierre2'])
    dome(cd, j=2)
    # gros cristal pyramidal sur le haut du front
    coins = [pd(-58, 4, 0.02), pd(-52, 50, 0.02), pd(0, 80, 0.02), pd(52, 50, 0.02), pd(58, 4, 0.02)]
    pyramide('Cristal', ['quartz', 'quartz3', 'quartz2', 'quartz3', 'quartz'], coins, pd(4, 52, 0.3), ep=0.06,
             centre=V(CX, CY, CZ))
    triangle('Cristal', 'quartz2', coins[0], coins[4], pd(4, 52, 0.3), 0.06, V(0, -0.3, -1))
    # nervures de pierre entre les segments
    for th in (55, -55, 125, -125, 180):
        pts = [pd(th, ph, 0.02) for ph in (0, 30, 60, 85)]
        for a, b in zip(pts, pts[1:]):
            barre('Coque', 'cadre', a, b, 0.1, 0.07, (a + b) / 2 - V(CX, CY, CZ))
    murs(lambda c, r: None if abs(c) <= 30 else RND.choice(['pierre', 'pierre2']), (0.12, -0.15, -0.42))
    # bandeau épais (front) + barre de visière basse, fente entre les deux
    bandeau('cadre', 0.13, 0.36, th_max=110, dr=0.07, ep=0.13, pas=22)
    bandeau('cadre', -0.12, 0.03, th_max=66, dr=0.1, ep=0.1, pas=22, nom='Visiere')
    for s in (1, -1):
        barre('Visiere', 'cadre', pm(s * 64, -0.14, 0.1), pm(s * 64, 0.2, 0.08), 0.12, 0.1, normale(s * 64))
    # pans latéraux : bandes de quartz séparées par des nervures + languette en bas
    for s in (1, -1):
        for c, k in ((60, 'quartz'), (81, 'quartz2'), (102, 'quartz3'), (123, 'quartz')):
            barre('Pans', k, pm(s * c, 0.12, 0.08), pm(s * c, -0.72, 0.22), 0.28, 0.06, normale(s * c, 10), ext=0.0)
        for c in (50, 70, 91, 112, 133):
            barre('Pans', 'pierre', pm(s * c, 0.12, 0.11), pm(s * c, -0.74, 0.25), 0.07, 0.08, normale(s * c, 10))
        barre('Pans', 'cadre', pm(s * 55, -0.7, 0.28), pm(s * 80, -0.84, 0.3), 0.16, 0.1, normale(s * 68))
        barre('Pans', 'pierre2', pm(s * 95, -0.8, 0.28), pm(s * 118, -0.74, 0.28), 0.12, 0.09, normale(s * 106))
    lames(lambda c, r: RND.choice(['pierre', 'pierre2']),
          [(0.05, 0.6, 0.08, 8, [150, 180, -150], 34), (-0.3, 0.5, 0.12, 12, [135, 165, -165, -135], 34)], j=3)


# ------------------------------------------------------------------ Soufre
@casque("Casque de Soufre", ((255, 214, 90), 5, 0.5))
def Soufre():
    M = {'soufre': ('Slate', (214, 168, 52), 0, 0, 0.7, 0), 'soufre2': ('Slate', (190, 146, 40), 0, 0, 0.75, 0),
         'soufre3': ('Slate', (230, 190, 80), 0, 0, 0.7, 0),
         'fer': ('Metal', (98, 84, 92), 0.05, 0.6, 0.5, 0), 'fer2': ('Metal', (78, 66, 74), 0.05, 0.6, 0.55, 0),
         'rivet': ('Metal', (150, 132, 140), 0.1, 0.8, 0.35, 0)}
    global RX, RZ
    rx0, rz0 = RX, RZ
    yb, yt = -0.8, 0.62
    # seau légèrement évasé vers le bas
    for r, (y0, y1, dr0, dr1) in enumerate(((yt, 0.16, -0.02, 0.0), (0.16, -0.18, 0.0, 0.015), (-0.18, yb, 0.015, 0.06))):
        for i in range(12):
            c = i * 30 if i <= 6 else i * 30 - 360
            if r == 1 and abs(c) <= 30:
                continue
            if r == 1:
                panneau('Cerclage', 'fer', pm(c - 15, y1, dr1 + 0.03), pm(c + 15, y1, dr1 + 0.03), pm(c - 15, y0, dr0 + 0.03),
                        pm(c + 15, y0, dr0 + 0.03), 0.08, 1)
                continue
            if r == 2 and abs(c) <= 30:
                if c != 0:   # joue : du bord de l'ouverture (28°) à 45°
                    a0, a1 = sorted((c / 30 * 28, c / 30 * 45))
                    panneau('Coque', RND.choice(['soufre', 'soufre2', 'soufre3']), pm(a0, y1, dr1), pm(a1, y1, dr1),
                            pm(a0, y0, dr0), pm(a1, y0, dr0), 0.08, 1)
                continue
            k = RND.choice(['soufre', 'soufre2', 'soufre3'])
            panneau('Coque', k, pm(c - 15, y1, dr1), pm(c + 15, y1, dr1), pm(c - 15, y0, dr0), pm(c + 15, y0, dr0),
                    0.08, 1)
    # fond plat
    for a in (0, 30, 60):
        piece('Coque', 'fer2', (2 * RX * 0.8, 0.08, 2 * RZ * 0.78), V(CX, yt - 0.02, CZ), rot('Y', a))
    # cerclages : haut, fente (bandeau au-dessus et au-dessous), bas
    def cercle(y0, y1, dr, ep, th_max=180, skip=None):
        th = -th_max
        while th < th_max - 1e-6:
            a, b = th, th + 30
            th = b
            if skip and skip((a + b) / 2):
                continue
            panneau('Cerclage', 'fer', pm(a, y0, dr), pm(b, y0, dr), pm(a, y1, dr), pm(b, y1, dr), ep, 1)
    cercle(yt - 0.13, yt + 0.01, 0.0, 0.1)
    cercle(0.05, 0.17, 0.01, 0.1)
    cercle(-0.2, -0.06, 0.025, 0.1)
    cercle(yb, yb + 0.14, 0.06, 0.1, skip=lambda c: abs(c) < 20)
    # sangle verticale du milieu (dessus -> nasal) + sangles latérales (bords de l'ouverture des joues)
    zf = CZ - RZ
    barre('Sangles', 'fer2', V(0, yt + 0.02, CZ - 0.3), V(0, yt + 0.02, zf + 0.04), 0.18, 0.07, UP)
    barre('Sangles', 'fer2', pm(0, yt + 0.02, 0.03), pm(0, -0.86, 0.07), 0.18, 0.08, V(0, 0, -1), ext=0.0)
    tente('Sangles', 'fer2', pm(0, -0.86, 0.07), V(0, -1, 0), 0.1, 0.18, 0.08, V(0, 0, -1))
    for s in (1, -1):
        barre('Sangles', 'fer2', pm(s * 31, 0.17, 0.04), pm(s * 31, yb - 0.02, 0.08), 0.2, 0.08, normale(s * 31),
              ext=0.0)
        tente('Sangles', 'fer2', pm(s * 31, yb - 0.02, 0.08), V(0, -1, 0), 0.1, 0.2, 0.08, normale(s * 31))
    # rivets
    for y in (yt - 0.06, 0.11, -0.13, -0.45):
        rivet('rivet', pm(0, y, 0.08), V(0, 0, -1), 0.07)
    for s in (1, -1):
        for y in (0.11, -0.13, -0.45, yb + 0.07):
            rivet('rivet', pm(s * 31, y, 0.09), normale(s * 31), 0.06)
        for th in (22, 80):
            rivet('rivet', pm(s * th, yt - 0.06, 0.06), normale(s * th), 0.05)
            rivet('rivet', pm(s * th, -0.13, 0.08), normale(s * th), 0.05)
    RX, RZ = rx0, rz0


# ------------------------------------------------------------------ Argent
@casque("Casque d'Argent", ((200, 150, 255), 6, 0.9))
def Argent():
    M = {'argent': ('Metal', (176, 172, 182), 0.15, 0.85, 0.35, 0), 'argent2': ('Metal', (146, 142, 152), 0.1, 0.85, 0.4, 0),
         'argent3': ('Metal', (204, 200, 208), 0.2, 0.85, 0.3, 0),
         'amethyste': ('SmoothPlastic', (168, 110, 230), 0.1, 0, 0.25, 0),
         'amethyste2': ('SmoothPlastic', (196, 150, 246), 0.1, 0, 0.25, 0),
         'gemme': ('Neon', (190, 130, 255), 0, 0, 0.3, 3), 'fente': ('SmoothPlastic', (14, 12, 16), 0, 0, 1, 0)}

    def cd(c, b):
        if c is not None and b == 0 and 75 <= abs(c) <= 120:
            return 'amethyste'
        return RND.choice(['argent', 'argent2', 'argent3'])
    dome(cd, j=2)
    murs(lambda c, r: None if abs(c) <= 30 else ('amethyste2' if r == 0 and abs(c) == 90 else
                                                RND.choice(['argent', 'argent2'])), (0.12, -0.15, -0.4))
    # crête sur le dessus (de l'avant vers la nuque)
    pts = [pd(0, ph, 0.03) for ph in (38, 62, 85)] + [pd(180, ph, 0.03) for ph in (70, 40, 10)]
    for a, b in zip(pts, pts[1:]):
        barre('Crete', 'argent3', a, b, 0.09, 0.16, V(1, 0, 0))
    tente('Crete', 'argent3', pd(0, 50, 0.06), V(0, 0.5, -1), 0.22, 0.09, 0.22, V(1, 0, 0))
    # bandeau + gemme losange au front
    bandeau('argent2', 0.26, 0.38, th_max=105, dr=0.06, ep=0.08, pas=21)
    gemme('argent3', 'gemme', pd(0, 40, 0.1), V(0, 0.55, -1), 0.24, 0.08)
    # visière en museau (2 plaques en V) avec 3 fentes de chaque côté
    zf = CZ - RZ - 0.12
    for s in (1, -1):
        a = V(0, 0, zf)
        b = V(s * 0.6, 0, zf + 0.46)
        d = b - a
        nn = V(-d.z, 0, d.x).normalized() if s > 0 else V(d.z, 0, -d.x).normalized()
        if nn.z > 0:
            nn = -nn
        R = repere(nn, UP)
        c = (a + b) / 2
        piece('Visiere', 'argent', (d.length + 0.06, 0.92, 0.07), c + V(0, -0.15, 0) - nn * 0.035, R)
        for k in range(3):
            u = 0.15 + k * 0.13
            q = a + d.normalized() * u + V(0, -0.12, 0) + nn * 0.005
            piece('Fentes', 'fente', (0.06, 0.36, 0.03), q, R)
        # pans à plaques avec améthyste
    for s in (1, -1):
        barre('Visiere', 'argent3', V(0, 0.3, zf - 0.02), V(0, -0.58, zf - 0.02), 0.06, 0.08, V(0, 0, -1))
    tente('Visiere', 'argent', V(0, -0.58, zf + 0.02), V(0, -1, 0.3), 0.14, 0.12, 0.12, V(0, 0, -1))
    rivet('argent3', pm(-58, 0.22, 0.1), normale(-58), 0.06)
    rivet('argent3', pm(58, 0.22, 0.1), normale(58), 0.06)
    lames(lambda c, r: ('amethyste' if (r == 1 and abs(c) in (75, 105)) else RND.choice(['argent', 'argent2'])),
          [(0.02, 0.5, 0.05, 8, [60, 90, 120, 150, 180, -150, -120, -90, -60], 34),
           (-0.3, 0.5, 0.1, 14, [75, 105, 135, 165, -165, -135, -105, -75], 34)], j=3)
    for s in (1, -1):
        for c in (75, 105):
            barre('Lames', 'argent3', pm(s * c - s * 15, -0.82, 0.24), pm(s * c + s * 15, -0.82, 0.24), 0.06, 0.08,
                  normale(s * c))


# ------------------------------------------------------------------ Obsidienne
@casque("Casque d'Obsidienne", ((190, 70, 255), 6, 1.0))
def Obsidienne():
    M = {'obs': ('SmoothPlastic', (34, 28, 40), 0.12, 0, 0.35, 0), 'obs2': ('SmoothPlastic', (52, 42, 60), 0.1, 0, 0.4, 0),
         'obs3': ('SmoothPlastic', (72, 58, 82), 0.08, 0, 0.45, 0),
         'veine': ('Neon', (182, 60, 255), 0, 0, 0.3, 3), 'gemme': ('Neon', (205, 110, 255), 0, 0, 0.3, 4),
         'fente': ('SmoothPlastic', (8, 6, 10), 0, 0, 1, 0)}
    dome(lambda c, b: RND.choice(['obs', 'obs2', 'obs', 'obs3']), j=5)
    murs(lambda c, r: None if abs(c) <= 30 else RND.choice(['obs', 'obs2']), (0.12, -0.15, -0.4), j=4)
    # veines violettes sur le crâne
    for th, ph, L, a in ((30, 40, 0.34, 30), (-40, 55, 0.3, -20), (100, 30, 0.3, 60), (150, 50, 0.3, 10),
                         (-120, 35, 0.32, -40), (60, 70, 0.26, 80)):
        c = pd(th, ph, -0.035)
        n = c - V(CX, CY, CZ)
        R = repere(n, UP) @ rot('Z', a)
        piece('Veines', 'veine', (0.05, L, 0.03), c, R)
        piece('Veines', 'veine', (0.04, L * 0.6, 0.03), c + R.col[1] * (L * 0.45) + R.col[0] * 0.08, R @ rot('Z', 35))
    # visière : front, fente des yeux, grille à 2+2 fentes
    zf = CZ - RZ - 0.1
    bandeau('obs3', 0.18, 0.34, th_max=70, dr=0.1, ep=0.08, pas=23.33)
    for s in (1, -1):
        a = V(0, 0, zf)
        b = V(s * 0.6, 0, zf + 0.42)
        d = b - a
        nn = V(-d.z, 0, d.x).normalized()
        if nn.z > 0:
            nn = -nn
        R = repere(nn, UP)
        c = (a + b) / 2
        piece('Visiere', 'obs2', (d.length + 0.06, 0.64, 0.07), c + V(0, -0.3, 0) - nn * 0.035, R)
        for k in range(2):
            u = 0.17 + k * 0.15
            piece('Fentes', 'fente', (0.07, 0.36, 0.03), a + d.normalized() * u + V(0, -0.3, 0) + nn * 0.005, R)
        # bord de la fente des yeux
        piece('Visiere', 'obs3', (d.length + 0.06, 0.05, 0.09), c + V(0, 0.03, 0) - nn * 0.02, R)
        piece('Fentes', 'fente', (d.length * 0.9, 0.1, 0.02), c + V(0, 0.11, 0.07), R)
        rivet('obs3', pm(s * 62, 0.27, 0.15), normale(s * 62), 0.07)
    barre('Visiere', 'obs3', V(0, 0.02, zf - 0.02), V(0, -0.62, zf - 0.02), 0.06, 0.08, V(0, 0, -1))
    tente('Visiere', 'obs2', V(0, -0.62, zf + 0.02), V(0, -1, 0.3), 0.14, 0.12, 0.12, V(0, 0, -1))
    gemme('obs3', 'gemme', pm(0, 0.42, 0.13), V(0, 0.3, -1), 0.22, 0.08)
    lames(lambda c, r: RND.choice(['obs', 'obs2', 'obs3']),
          [(0.02, 0.5, 0.05, 8, [60, 90, 120, 150, 180, -150, -120, -90, -60], 34),
           (-0.3, 0.5, 0.1, 14, [75, 105, 135, 165, -165, -135, -105, -75], 34)], j=5)
    for s in (1, -1):
        for c, y in ((80, -0.55), (110, -0.3), (140, -0.6)):
            n0 = normale(s * c, 12)
            q = pm(s * c, y, 0.2)
            R = repere(n0, UP) @ rot('Z', s * 30)
            piece('Veines', 'veine', (0.04, 0.26, 0.03), q, R)
            piece('Veines', 'veine', (0.04, 0.16, 0.03), q + R.col[1] * 0.1 + R.col[0] * 0.06, R @ rot('Z', -50))


# ------------------------------------------------------------------ Corinthiens (base commune)
def corinthien(coque, cadre, inserts, joue_args=None, lames_fn=None, rangs=LAMES_STD, band=(0.12, 0.34), v=0.14,
               dome_j=4, cle_v=None, band_dr=0.07, band_ep=0.1, murs_fn=None):
    dome(coque, j=dome_j)
    murs(murs_fn or (lambda c, r: None if abs(c) <= 30 else coque(c, 9)), (0.12, -0.15, -0.42), j=dome_j)
    bandeau(cadre, band[0], band[1], th_max=110, dr=band_dr, ep=band_ep, v=v, pas=22, cle_v=cle_v)
    for s in (1, -1):
        joue(s, cadre, inserts, **(joue_args or {}))
    if lames_fn:
        lames(lames_fn, rangs, j=5)


# ------------------------------------------------------------------ Givrite
@casque("Casque de Givrite", ((150, 210, 255), 6, 0.9))
def Givrite():
    M = {'glace': ('SmoothPlastic', (150, 190, 236), 0.15, 0, 0.2, 0), 'glace2': ('SmoothPlastic', (120, 166, 222), 0.15, 0, 0.2, 0),
         'glace3': ('SmoothPlastic', (190, 218, 248), 0.2, 0, 0.15, 0),
         'argent': ('Metal', (206, 208, 220), 0.15, 0.8, 0.3, 0), 'gemme': ('Neon', (150, 210, 255), 0, 0, 0.3, 2.5),
         'gemme2': ('Neon', (220, 240, 255), 0, 0, 0.3, 3)}
    g = alterne('glace', 'glace2', 'glace3')
    corinthien(g, 'argent', ['glace', 'glace2', 'glace3'], lames_fn=g, v=0.12)
    gemme_longue('argent', 'gemme', pm(0, 0.43, 0.15), V(0, 0.25, -1), 0.5, 0.17, cle_gemme2='gemme2')
    # éclats de glace sur le dessus, couchés vers l'arrière
    for th, ph, d, L, w in ((0, 50, V(0, 1, 0.25), 0.55, 0.22), (40, 40, V(0.5, 1, 0.3), 0.5, 0.22),
                            (-40, 40, V(-0.5, 1, 0.3), 0.5, 0.22), (80, 22, V(1, 0.6, 0.2), 0.42, 0.2),
                            (-80, 22, V(-1, 0.6, 0.2), 0.42, 0.2), (120, 45, V(0.6, 0.9, 0.7), 0.45, 0.22),
                            (-120, 45, V(-0.6, 0.9, 0.7), 0.45, 0.22), (180, 55, V(0, 0.8, 1), 0.45, 0.24),
                            (0, 78, V(0, 1, 0.6), 0.4, 0.24)):
        cristal('Cristaux', RND.choice(['glace', 'glace3']), pd(th, ph, -0.12), d, L, w, cle2='glace3')


# ------------------------------------------------------------------ Emeraude
@casque("Casque d'Émeraude", ((60, 230, 110), 6, 1.0))
def Emeraude():
    M = {'roche': ('Slate', (74, 68, 74), 0, 0, 0.8, 0), 'roche2': ('Slate', (58, 54, 60), 0, 0, 0.85, 0),
         'roche3': ('Slate', (92, 86, 90), 0, 0, 0.8, 0), 'cadre': ('Metal', (94, 88, 92), 0.05, 0.5, 0.5, 0),
         'emeraude': ('SmoothPlastic', (40, 190, 70), 0.15, 0, 0.2, 0), 'emeraude2': ('SmoothPlastic', (30, 150, 56), 0.15, 0, 0.2, 0),
         'gemme': ('Neon', (60, 230, 100), 0, 0, 0.3, 2.5)}
    r = alterne('roche', 'roche2', 'roche3')
    corinthien(r, 'cadre', ['emeraude', 'emeraude2'], lames_fn=r, v=0.14)
    gemme_longue('cadre', 'gemme', pm(0, 0.36, 0.15), V(0, 0.2, -1), 0.38, 0.15)
    # couronne de cristaux
    for th, ph, d, L, w in ((0, 40, V(0, 1, -0.2), 0.56, 0.26),
                            (55, 18, V(0.55, 1, -0.2), 0.5, 0.2), (75, 12, V(0.9, 0.7, -0.05), 0.4, 0.17),
                            (-55, 18, V(-0.55, 1, -0.2), 0.5, 0.2), (-75, 12, V(-0.9, 0.7, -0.05), 0.4, 0.17)):
        cristal('Cristaux', 'emeraude', pd(th, ph, -0.1), d, L, w, cle2='emeraude2')


# ------------------------------------------------------------------ Rubis
@casque("Casque de Rubis", ((255, 50, 90), 6, 1.0))
def Rubis():
    M = {'grenat': ('SmoothPlastic', (96, 40, 52), 0.08, 0, 0.45, 0), 'grenat2': ('SmoothPlastic', (78, 32, 44), 0.08, 0, 0.5, 0),
         'bronze': ('Metal', (130, 96, 84), 0.08, 0.7, 0.4, 0),
         'rubis': ('SmoothPlastic', (210, 34, 76), 0.15, 0, 0.2, 0), 'rubis2': ('SmoothPlastic', (172, 24, 60), 0.15, 0, 0.2, 0),
         'gemme': ('Neon', (255, 50, 100), 0, 0, 0.3, 2.5), 'gemme2': ('Neon', (255, 140, 170), 0, 0, 0.3, 3)}
    gr = alterne('grenat', 'grenat2')
    rb = alterne('rubis', 'rubis2')
    corinthien(gr, 'bronze', ['rubis', 'rubis2'], v=0.12,
               joue_args=dict(vbot=-0.42, vext=-0.3, insert=False, u1=0.3, pointe=True),
               lames_fn=lambda c, r: RND.choice(['rubis', 'rubis2']),
               rangs=[(0.0, 0.42, 0.04, 5, [60, 90, 120, 150, 180, -150, -120, -90, -60], 34),
                      (-0.22, 0.42, 0.07, 9, [45, 75, 105, 135, 165, -165, -135, -105, -75, -45], 34),
                      (-0.45, 0.34, 0.1, 13, [55, 85, 115, -115, -85, -55], 34)])
    # plaques en écailles sur le dessus, vers l'arrière
    for th, ph in ((0, 72), (60, 55), (-60, 55), (120, 60), (-120, 60), (180, 60), (30, 85), (-150, 80)):
        c = pd(th, ph, 0.05)
        n = c - V(CX, CY, CZ)
        piece('Coque', RND.choice(['grenat', 'grenat2']), (0.36, 0.3, 0.07), c, jit(repere(n, V(0, 0, 1)) @ rot('X', -18), 4))
    gemme_longue('bronze', 'gemme', pm(0, 0.52, 0.17), V(0, 0.25, -1), 0.62, 0.24, cle_gemme2='gemme2')
    # ailes de rubis au-dessus du bandeau
    for s in (1, -1):
        for th, L in ((50, 0.5), (85, 0.45)):
            cristal('Cristaux', 'rubis', pm(s * (th - 15), 0.4, 0.02), normale(s * (th + 75), 12), L, 0.26, cle2='rubis2')


# ------------------------------------------------------------------ Lunarite
@casque("Casque de Lunarite", ((200, 170, 255), 6, 0.8))
def Lunarite():
    M = {'lune': ('SmoothPlastic', (176, 158, 228), 0.12, 0, 0.25, 0), 'lune2': ('SmoothPlastic', (150, 132, 210), 0.12, 0, 0.25, 0),
         'lune3': ('SmoothPlastic', (204, 188, 240), 0.15, 0, 0.2, 0),
         'argent': ('Metal', (214, 206, 214), 0.15, 0.8, 0.3, 0), 'gemme': ('Neon', (190, 150, 255), 0, 0, 0.3, 2.5)}
    l = alterne('lune', 'lune2', 'lune3')
    corinthien(l, 'argent', ['lune', 'lune3'], lames_fn=l, v=0.14)
    gemme('argent', 'gemme', pm(0, 0.33, 0.15), V(0, 0.15, -1), 0.24, 0.08)
    # croissant de lune sur le dessus : ouvert vers le haut-droite de l'image (= -X), épais en bas-gauche
    cx, cy, cz, R0 = 0.02, CY + RY + 0.22, -0.14, 0.3
    N = 10
    for k in range(N):
        f0, f1 = math.radians(75 + k * 29), math.radians(75 + (k + 1) * 29)
        t = (k + 0.5) / N
        ep = 0.035 + 0.15 * math.sin(math.pi * t)
        p0 = V(cx - R0 * math.cos(f0), cy + R0 * math.sin(f0), cz)
        p1 = V(cx - R0 * math.cos(f1), cy + R0 * math.sin(f1), cz)
        radial = ((p0 + p1) / 2 - V(cx, cy, cz)).normalized()
        barre('Croissant', 'argent', p0 - radial * (ep / 2), p1 - radial * (ep / 2), ep, 0.09, V(0, 0, -1), ext=0.03)
    barre('Croissant', 'argent', V(cx + 0.1, cy - R0 - 0.02, cz + 0.04), V(cx, CY + RY - 0.05, cz + 0.1), 0.1, 0.09,
          V(0, 0, -1))
    # oreilles pointues de lunarite
    for s in (1, -1):
        cristal('Cristaux', 'lune3', pm(s * 82, 0.32, 0.02), V(s * 1, 0.9, 0.1), 0.38, 0.17, cle2='lune')


# ------------------------------------------------------------------ Magmaite
@casque("Casque de Magmaïte", ((255, 110, 30), 7, 1.4), particules='braises')
def Magmaite():
    M = {'basalte': ('Basalt', (66, 58, 60), 0, 0, 0.9, 0), 'basalte2': ('Basalt', (84, 74, 76), 0, 0, 0.9, 0),
         'basalte3': ('Basalt', (50, 44, 48), 0, 0, 0.9, 0),
         'magma': ('Neon', (255, 100, 24), 0, 0, 0.5, 4), 'yeux': ('Neon', (255, 130, 30), 0, 0, 0.5, 4)}
    b = alterne('basalte', 'basalte2', 'basalte3')
    # nappe de magma sous les plaques (visible dans les joints)
    dome(lambda c, k: 'magma', ep=0.04, dr=-0.06, nom='Fissures')
    corinthien(b, 'basalte2', ['basalte', 'basalte3'], lames_fn=b, v=0.0, dome_j=9, band=(0.16, 0.38))
    # pic central du bandeau et éclats de roche sur le dessus
    tente('Pointes', 'basalte2', pm(0, 0.3, 0.12), V(0, 1, -0.1), 0.36, 0.1, 0.3, V(0, 0, -1))
    for th, ph, d, L, w in ((0, 60, V(0, 1, 0.3), 0.5, 0.26), (45, 45, V(0.4, 1, 0.3), 0.42, 0.24),
                            (-45, 45, V(-0.4, 1, 0.3), 0.42, 0.24), (100, 30, V(1, 0.5, 0.2), 0.36, 0.22),
                            (-100, 30, V(-1, 0.5, 0.2), 0.36, 0.22), (160, 50, V(0.3, 0.7, 1), 0.42, 0.24),
                            (-160, 50, V(-0.3, 0.7, 1), 0.42, 0.24), (20, 80, V(0.2, 1, 0.5), 0.34, 0.22)):
        cristal('Pointes', RND.choice(['basalte', 'basalte2']), pd(th, ph, -0.1), d, L, w, tour=RND.uniform(20, 60),
                cle2='basalte3')
    # fissures de lave sur le crâne et le bandeau
    for th, ph, L, a in ((25, 20, 0.32, 70), (-30, 25, 0.3, -60), (70, 35, 0.3, 20), (-75, 40, 0.28, -30),
                         (0, 45, 0.26, 90), (130, 30, 0.3, 40), (-140, 30, 0.3, -40)):
        c = pd(th, ph, -0.035)
        R = repere(c - V(CX, CY, CZ), UP) @ rot('Z', a)
        piece('Fissures', 'magma', (0.045, L, 0.03), c, R)
        piece('Fissures', 'magma', (0.04, L * 0.55, 0.03), c + R.col[1] * (L * 0.4) + R.col[0] * 0.07, R @ rot('Z', 40))
    for s in (1, -1):
        piece('Fissures', 'magma', (0.04, 0.2, 0.03), pm(s * 40, 0.27, 0.13), repere(normale(s * 40), UP) @ rot('Z', 25))
    # regard de lave sous le bandeau
    piece('Visiere', 'yeux', (0.66, 0.12, 0.04), V(0, 0.07, CZ - RZ + 0.08), I3, tag='lumiere')
    piece('Visiere', 'basalte3', (0.7, 0.04, 0.06), V(0, 0.0, CZ - RZ + 0.1), I3)
    # fissures de lave sur les joues et les côtés
    for s in (1, -1):
        for th, y, L, a in ((40, -0.35, 0.36, 12), (58, -0.1, 0.3, -20), (95, 0.0, 0.34, 25), (120, -0.5, 0.3, -10)):
            n0 = normale(s * th)
            q = pm(s * th, y, 0.2 if th < 70 else 0.12)
            R = repere(n0, UP) @ rot('Z', s * a)
            piece('Fissures', 'magma', (0.035, L, 0.03), q, R)
            piece('Fissures', 'magma', (0.03, L * 0.5, 0.03), q + R.col[1] * (L * 0.3) + R.col[0] * 0.05, R @ rot('Z', 40))


# ------------------------------------------------------------------ Diamant
@casque("Casque de Diamant", ((200, 230, 255), 7, 1.0), particules='etincelles')
def Diamant():
    M = {'diamant': ('SmoothPlastic', (196, 204, 240), 0.2, 0, 0.15, 0), 'diamant2': ('SmoothPlastic', (168, 178, 230), 0.2, 0, 0.15, 0),
         'diamant3': ('SmoothPlastic', (222, 228, 250), 0.25, 0, 0.1, 0),
         'argent': ('Metal', (212, 206, 216), 0.15, 0.8, 0.3, 0), 'gemme': ('Neon', (170, 220, 255), 0, 0, 0.3, 2.5)}
    d3 = alterne('diamant', 'diamant2', 'diamant3')
    corinthien(d3, 'argent', ['diamant', 'diamant2'], lames_fn=d3, v=0.14)
    gemme('argent', 'gemme', pm(0, 0.36, 0.16), V(0, 0.15, -1), 0.3, 0.08)
    # couronne d'éclats de diamant (grand au centre)
    for th, ph, d, L, w in ((0, 50, V(0, 1, 0.05), 0.85, 0.3), (28, 38, V(0.3, 1, 0), 0.6, 0.24),
                            (-28, 38, V(-0.3, 1, 0), 0.6, 0.24), (55, 25, V(0.6, 1, 0), 0.62, 0.24),
                            (-55, 25, V(-0.6, 1, 0), 0.62, 0.24), (85, 15, V(1, 0.8, 0.1), 0.46, 0.2),
                            (-85, 15, V(-1, 0.8, 0.1), 0.46, 0.2), (130, 40, V(0.5, 1, 0.5), 0.5, 0.22),
                            (-130, 40, V(-0.5, 1, 0.5), 0.5, 0.22), (180, 50, V(0, 1, 0.5), 0.55, 0.24)):
        cristal('Cristaux', RND.choice(['diamant', 'diamant3']), pd(th, ph, -0.12), d, L, w, cle2='diamant3')


# ------------------------------------------------------------------ Orichalque
@casque("Casque d'Orichalque", ((255, 210, 80), 7, 1.2), particules='etincelles_or')
def Orichalque():
    M = {'or': ('Metal', (232, 172, 52), 0.2, 0.9, 0.3, 0), 'or2': ('Metal', (204, 142, 38), 0.15, 0.9, 0.35, 0),
         'or3': ('Metal', (250, 206, 100), 0.25, 0.9, 0.25, 0), 'bronze': ('Metal', (104, 74, 54), 0.05, 0.6, 0.5, 0),
         'gemme': ('Neon', (255, 214, 60), 0, 0, 0.3, 3.5), 'lueur': ('Neon', (255, 176, 40), 0, 0, 0.3, 2)}
    o = alterne('or', 'or2')
    corinthien(lambda c, b: 'bronze' if (c is not None and b == 1 and abs(c) <= 30) else o(c, b), 'or3',
               ['bronze', 'or2'], lames_fn=o, v=0.0, band=(0.14, 0.32))
    # arche solaire sur le front + rayons
    cc = pd(0, 30, 0.08)
    for k in range(7):
        a0, a1 = math.radians(k * 180 / 7), math.radians((k + 1) * 180 / 7)
        p0 = V(0.4 * math.cos(a0), 0.3 + 0.36 * math.sin(a0), 0)
        p1 = V(0.4 * math.cos(a1), 0.3 + 0.36 * math.sin(a1), 0)

        def place(q):
            th = math.degrees(math.asin(max(-1, min(1, q.x / (RX + 0.1)))))
            return pm(th, q.y, 0.1 + 0.25 * max(0, q.y - 0.3))
        barre('Arche', 'or3', place(p0), place(p1), 0.12, 0.12, V(0, 0.4, -1))
    piece('Arche', 'bronze', (0.5, 0.36, 0.06), pd(0, 35, 0.06), repere(V(0, 0.7, -1), UP))
    gemme_longue('or3', 'gemme', pd(0, 30, 0.15), V(0, 0.5, -1), 0.42, 0.3)
    for k in range(7):
        a = math.radians(15 + k * 25)
        base = V(0.42 * math.cos(a), 0.32 + 0.4 * math.sin(a), 0)
        th = math.degrees(math.asin(base.x / (RX + 0.1)))
        b0 = pm(th, base.y, 0.1 + 0.25 * max(0, base.y - 0.3))
        d = V(math.cos(a), math.sin(a), 0.15)
        cristal('Rayons', 'or3' if k % 2 else 'or', b0, d, 0.46 if k == 3 else (0.4 if k % 2 == 0 else 0.3),
                0.15 if k == 3 else 0.12, cle2='or3')
    # ailes du front
    for s in (1, -1):
        barre('Arche', 'or', pm(s * 10, 0.08, 0.16), pm(s * 70, 0.36, 0.1), 0.13, 0.1, normale(s * 40, 15))
        rivet('bronze', pm(s * 75, 0.25, 0.15), normale(s * 75), 0.08)


# ------------------------------------------------------------------ Neantite
@casque("Casque de Néantite", ((230, 60, 255), 7, 1.2))
def Neantite():
    M = {'neant': ('SmoothPlastic', (52, 38, 60), 0.1, 0, 0.4, 0), 'neant2': ('SmoothPlastic', (40, 30, 48), 0.1, 0, 0.45, 0),
         'neant3': ('SmoothPlastic', (74, 58, 84), 0.1, 0, 0.4, 0),
         'neantite': ('SmoothPlastic', (220, 60, 240), 0.15, 0, 0.2, 0), 'neantite2': ('SmoothPlastic', (180, 40, 210), 0.15, 0, 0.2, 0),
         'gemme': ('Neon', (230, 70, 255), 0, 0, 0.3, 3), 'veine': ('Neon', (210, 50, 240), 0, 0, 0.3, 2.5)}
    n = alterne('neant', 'neant2', 'neant3')
    corinthien(n, 'neant3', ['neant', 'neant2'], lames_fn=n, v=0.14,
               rangs=LAMES_STD + [(-0.55, 0.3, 0.18, 30, [70, 100, -100, -70], 30)])
    gemme_longue('neant3', 'gemme', pm(0, 0.36, 0.15), V(0, 0.2, -1), 0.42, 0.18)
    # couronne : anneau de plaques autour du sommet + pointes sombres + cristaux magenta
    yc = CY + RY * 0.72
    for i in range(12):
        c = i * 30
        a0, a1 = math.radians(c - 15), math.radians(c + 15)
        r = 0.6
        p0 = V(r * math.sin(a0), yc, CZ - r * math.cos(a0))
        p1 = V(r * math.sin(a1), yc, CZ - r * math.cos(a1))
        panneau('Couronne', RND.choice(['neant', 'neant3']), p0, p1, p0 + V(0, 0.24, 0), p1 + V(0, 0.24, 0), 0.08, 3)
    for c, L, k in ((0, 0.7, 'neantite'), (50, 0.5, 'neantite'), (-50, 0.5, 'neantite'), (25, 0.36, 'neant3'),
                    (-25, 0.36, 'neant3'), (90, 0.4, 'neant3'), (-90, 0.4, 'neant3'), (135, 0.4, 'neantite'),
                    (-135, 0.4, 'neantite'), (180, 0.36, 'neant3')):
        a = math.radians(c)
        b0 = V(0.62 * math.sin(a), yc + 0.12, CZ - 0.62 * math.cos(a))
        d = V(0.25 * math.sin(a), 1, -0.25 * math.cos(a))
        if k == 'neant3':
            tente('Couronne', k, b0, d, L, 0.06, 0.2, V(math.sin(a), 0, -math.cos(a)), rot('Y', 90))
        else:
            cristal('Cristaux', k, b0, d, L, 0.22 if c == 0 else 0.18, cle2='neantite2')
    # veines magenta sur les joues et les côtés + pointes latérales
    for s in (1, -1):
        for th, y, L, a in ((40, -0.4, 0.34, 15), (60, -0.15, 0.26, -25), (100, -0.1, 0.3, 30), (125, -0.5, 0.3, -15)):
            q = pm(s * th, y, 0.2 if th < 70 else 0.13)
            R = repere(normale(s * th), UP) @ rot('Z', s * a)
            piece('Veines', 'veine', (0.035, L, 0.03), q, R)
            piece('Veines', 'veine', (0.03, L * 0.5, 0.03), q + R.col[1] * (L * 0.3) + R.col[0] * 0.05, R @ rot('Z', 40))
        for th, y in ((80, -0.4), (105, -0.55)):
            cristal('Pointes', 'neant3', pm(s * th, y, 0.08), V(s * 1, -0.45, 0.25 if th > 90 else -0.1), 0.34, 0.13,
                    cle2='neant2')


# ================================================================== Luau
def f4(x):
    s = '%.4f' % x
    s = s.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


PARTICULES = {
    'braises': dict(couleurs=((255, 176, 64), (210, 40, 10)), taux=6, vie=(1.2, 2.2), vitesse=(0.25, 0.6),
                    taille=0.09, acc=0.5),
    'etincelles': dict(couleurs=((255, 255, 255), (170, 210, 255)), taux=3, vie=(0.6, 1.2), vitesse=(0.05, 0.2),
                       taille=0.12, acc=0.0),
    'etincelles_or': dict(couleurs=((255, 240, 170), (255, 180, 40)), taux=3, vie=(0.8, 1.4), vitesse=(0.1, 0.3),
                          taille=0.08, acc=0.3),
}


def bornes():
    lo, hi = V(1e9, 1e9, 1e9), V(-1e9, -1e9, -1e9)
    for p in P:
        for x in sommets(p)[0]:
            for i in range(3):
                lo[i], hi[i] = min(lo[i], x[i]), max(hi[i], x[i])
    return lo, hi


def ecrire_lua(id_, info, mats):
    lo, hi = bornes()
    taille = hi - lo
    nom = 'Casque' + id_
    L = ['-- Généré par blender/armes/casques_minerais.py (%d Parts en jeu, Racine comprise). Ne pas modifier à la main.'
         % (len(P) + 1),
         '-- %s : casque de forge (maquette previews/minerais/maquette-casques-epees.png).' % info['nom'],
         '-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,',
         '-- donc visible par tous. Aperçu : previews/armes/casques_minerais/%s.png' % nom,
         '-- Repère = Racine = centre de la tête R15 (1.2 stud) : devant = -Z, haut = +Y, droite = +X, unités = studs.',
         '',
         '-- clé -> {matériau, r, g, b, reflectance}',
         'local COULEURS = {']
    for k, (rm, c, refl, *_r) in mats.items():
        L.append('\t["%s"] = {"%s", %d, %d, %d, %s},' % (k, rm, c[0], c[1], c[2], f4(refl)))
    L.append('}')
    L.append('')
    L.append('-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame, marque ("lumiere")}')
    L.append('local PIECES = {')
    for p in P:
        R = p['R']
        cf = ', '.join(f4(x) for x in (p['pos'].x, p['pos'].y, p['pos'].z,
                                        R[0][0], R[0][1], R[0][2], R[1][0], R[1][1], R[1][2], R[2][0], R[2][1], R[2][2]))
        t = p['taille']
        tag = ', "%s"' % p['tag'] if p['tag'] else ''
        L.append('\t{"%s", "%s", "%s", Vector3.new(%s, %s, %s), CFrame.new(%s)%s},'
                 % (p['nom'], p['cle'], p['forme'], f4(t.x), f4(t.y), f4(t.z), cf, tag))
    L.append('}')
    lc, lp, lb = info['lumiere']
    part = PARTICULES.get(info['particules'])
    L.append('''
local function materiau(nom: string): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[nom]
	end)
	return if ok and typeof(m) == "EnumItem" then m else Enum.Material.SmoothPlastic
end
''')
    if part:
        c1, c2 = part['couleurs']
        L.append('''local function particules(parent: BasePart)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Scintillement"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(%d, %d, %d), Color3.fromRGB(%d, %d, %d))
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Rate = %s
	e.Lifetime = NumberRange.new(%s, %s)
	e.Speed = NumberRange.new(%s, %s)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, %s, 0)
	e.Drag = 0.6
	e.RotSpeed = NumberRange.new(-120, 120)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4, %s),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Parent = parent
end
''' % (c1 + c2 + (f4(part['taux']), f4(part['vie'][0]), f4(part['vie'][1]), f4(part['vitesse'][0]),
                  f4(part['vitesse'][1]), f4(part['acc']), f4(part['taille']))))
    L.append('''local function construire(): Model
	local modele = Instance.new("Model")
	modele.Name = "%s"
	modele:SetAttribute("NomAffiche", "%s")

	local racine = Instance.new("Part")
	racine.Name = "Racine"
	racine.Size = Vector3.new(0.2, 0.2, 0.2)
	racine.CFrame = CFrame.identity
	racine.Transparency = 1
	racine.CastShadow = false
	racine.Anchored = false
	racine.CanCollide, racine.CanQuery, racine.CanTouch = false, false, false
	racine.Massless = true
	racine.Parent = modele
	modele.PrimaryPart = racine

	local lumiereFaite = false
	for _, pc in PIECES do
		local nom, cle, forme, taille, cf, marque = pc[1], pc[2], pc[3], pc[4], pc[5], pc[6]
		local c = COULEURS[cle]
		local p: BasePart = if forme == "Coin" then Instance.new("WedgePart") else Instance.new("Part")
		p.Name = nom
		p.Size = taille
		p.CFrame = cf
		p.Anchored = false
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		p.Massless = true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Material = materiau(c[1])
		p.Color = Color3.fromRGB(c[2], c[3], c[4])
		p.Reflectance = c[5]
		p.CastShadow = c[1] ~= "Neon"
		if marque == "lumiere" and not lumiereFaite then
			lumiereFaite = true
			local l = Instance.new("PointLight")
			l.Color = Color3.fromRGB(%d, %d, %d)
			l.Range = %s
			l.Brightness = %s
			l.Shadows = false
			l.Parent = p%s
		end
		p.Parent = modele
		local w = Instance.new("WeldConstraint")
		w.Part0 = racine
		w.Part1 = p
		w.Parent = p
	end
	return modele
end
''' % (nom, info['nom'], lc[0], lc[1], lc[2], f4(lp), f4(lb), '\n\t\t\tparticules(p)' if part else ''))
    L.append('return {')
    L.append('\tNom = "%s",' % info['nom'])
    L.append('\tFormat = "Code",')
    L.append('\tTaille = Vector3.new(%s, %s, %s),' % (f4(taille.x), f4(taille.y), f4(taille.z)))
    L.append('\tCentre = Vector3.new(%s, %s, %s), -- centre de la boîte englobante dans le repère de la tête'
             % (f4((hi.x + lo.x) / 2), f4((hi.y + lo.y) / 2), f4((hi.z + lo.z) / 2)))
    L.append('\tconstruire = construire,')
    L.append('}')
    f = os.path.join(D_LUA, nom + '.lua')
    open(f, 'w', encoding='utf8', newline='\n').write('\n'.join(L) + '\n')
    print('LUA', f, 'parts', len(P) + 1, 'taille', tuple(round(x, 2) for x in taille))


# ================================================================== Blender
def sommets(p):
    hx, hy, hz = p['taille'] / 2
    if p['forme'] == 'Bloc':
        v = [V(x, y, z) for x in (-hx, hx) for y in (-hy, hy) for z in (-hz, hz)]
        f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    else:   # WedgePart : face verticale à l'arrière (+Z), pente vers l'avant (-Z) et le haut
        v = [V(-hx, -hy, -hz), V(hx, -hy, -hz), V(hx, -hy, hz), V(-hx, -hy, hz), V(-hx, hy, hz), V(hx, hy, hz)]
        f = [(0, 1, 2, 3), (3, 2, 5, 4), (0, 4, 5, 1), (0, 3, 4), (1, 5, 2)]
    return [p['pos'] + p['R'] @ x for x in v], f


def r2b(p):
    return (p[0], -p[2], p[1])


def vider():
    for o in list(bpy.data.objects):
        if o.type == 'MESH':
            bpy.data.objects.remove(o, do_unlink=True)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)
    for m in list(bpy.data.materials):
        bpy.data.materials.remove(m)


def construire_blender(mats):
    cache = {}

    def materiau(cle):
        if cle in cache:
            return cache[cle]
        rm, c, refl, metal, rough, em = mats[cle]
        m = bpy.data.materials.new(cle)
        m.use_nodes = True
        b = m.node_tree.nodes['Principled BSDF']
        rgb = tuple((x / 255) ** 2.2 for x in c) + (1,)
        b.inputs['Base Color'].default_value = rgb
        b.inputs['Metallic'].default_value = metal * 0.6
        b.inputs['Roughness'].default_value = rough
        if em or rm == 'Neon':
            b.inputs['Emission Color'].default_value = rgb
            b.inputs['Emission Strength'].default_value = (em or 2) * 0.25
        cache[cle] = m
        return m
    groupes = {}
    for p in P:
        groupes.setdefault(p['cle'], []).append(p)
    for cle, ps in groupes.items():
        verts, faces_ = [], []
        for p in ps:
            vs, fs = sommets(p)
            k = len(verts)
            verts += [r2b(x) for x in vs]
            faces_ += [tuple(i + k for i in f) for f in fs]
        me = bpy.data.meshes.new(cle)
        me.from_pydata(verts, [], faces_)
        me.validate()
        bm = bmesh.new(); bm.from_mesh(me)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(me); bm.free()
        me.materials.append(materiau(cle))
        o = bpy.data.objects.new(cle, me)
        bpy.context.scene.collection.objects.link(o)


def scene_rendu():
    sc = bpy.context.scene
    for eng in ('BLENDER_EEVEE', 'BLENDER_EEVEE_NEXT'):
        try:
            sc.render.engine = eng
            break
        except TypeError:
            pass
    sc.view_settings.view_transform = 'Standard'
    sc.render.resolution_x = sc.render.resolution_y = 600
    w = bpy.data.worlds.new('W'); sc.world = w; w.use_nodes = True
    bg = w.node_tree.nodes['Background']
    bg.inputs[0].default_value = (0.012, 0.012, 0.014, 1); bg.inputs[1].default_value = 2.5

    def soleil(nom, e, depuis, col):
        l = bpy.data.lights.new(nom, 'SUN'); l.energy = e; l.color = col; l.angle = math.radians(8)
        o = bpy.data.objects.new(nom, l); sc.collection.objects.link(o)
        o.rotation_euler = (-Vector(r2b(depuis))).to_track_quat('-Z', 'Y').to_euler()
    soleil("cle", 2.4, (0.9, 1.0, -0.8), (1, 0.97, 0.92))
    soleil('remplissage', 1.2, (-0.6, 0.2, -1.0), (0.85, 0.9, 1))
    soleil('contre', 2.5, (-0.3, 0.6, 1.0), (1, 1, 1))
    cam = bpy.data.cameras.new('C'); cam.lens = 50
    co = bpy.data.objects.new('C', cam); sc.collection.objects.link(co); sc.camera = co
    return sc, co


def vue(sc, co, chemin, oeil, cible=(0, 0.05, 0), dist=3.9):
    c = Vector(r2b(cible))
    d = Vector(r2b(oeil)).normalized()
    co.location = c + d * dist
    co.rotation_euler = (c - co.location).to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = chemin
    bpy.ops.render.render(write_still=True)
    print('PNG', chemin)


def main():
    global P, RND
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc, co = scene_rendu()
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    vues = '--vues' in args
    choix = [a for a in args if not a.startswith('--')] or LISTE
    os.makedirs(D_PNG, exist_ok=True)
    for id_ in choix:
        info = CASQUES[id_]
        P = []
        RND = random.Random(hash(id_) % 1000 if False else sum(map(ord, id_)))
        fn = info['fn']
        # récupère le dictionnaire M de la fonction : on l'exécute avec un traceur
        mats = {}

        def trace(frame, event, arg):
            if event == 'return' and frame.f_code is fn.__code__:
                mats.update(frame.f_locals.get('M', {}))
            return trace if frame.f_code is fn.__code__ else None
        sys.setprofile(trace)
        try:
            fn()
        finally:
            sys.setprofile(None)
        cles = {p['cle'] for p in P}
        manque = cles - set(mats)
        assert not manque, (id_, manque)
        mats = {k: v for k, v in mats.items() if k in cles}
        ecrire_lua(id_, info, mats)
        vider()
        construire_blender(mats)
        vue(sc, co, os.path.join(D_PNG, 'Casque%s.png' % id_), (0.27, 0.22, -1.0))
        if vues:
            for nom, oeil in (('face', (0, 0.1, -1)), ('profil', (1, 0.1, 0)), ('dos', (-0.5, 0.3, 1))):
                vue(sc, co, os.path.join(D_PNG, 'vues', 'Casque%s_%s.png' % (id_, nom)), oeil)


main()
