"""12 plastrons + 12 jambières des minerais, assortis aux casques (casques_minerais.py) et aux épées
(epees_minerais.py) : Quartz, Soufre, Argent, Obsidienne, Givrite, Emeraude, Rubis, Lunarite, Magmaite,
Diamant, Orichalque, Neantite. Raffinement croissant avec la rareté (Soufre/Quartz sobres ... Néantite très ornée).

Source unique : chaque pièce est une liste de primitives Roblox (Part bloc / WedgePart) qui sert
  1. aux modules Luau src/partage/ArmuresVoxels/Plastron<Minerai>.lua et Jambieres<Minerai>.lua
     (Format = "Code", Parts construites en jeu, aucun asset importé => visibles par tous) ;
  2. aux aperçus previews/armes/plastrons_minerais/, previews/armes/jambieres_minerais/ (vue 3/4 sur un
     mannequin R15 gris + planche _comparaison.png) et previews/armes/sets_minerais/ (casque + plastron +
     jambières + épée par minerai, planche _sets.png).

Blender (génère les modules + les rendus) :
  blender -b --factory-startup --python armures_minerais.py [-- Quartz Soufre ...] [--sans-planches]

Repères (= contrat de ArmuresVoxels/init.lua) :
  Plastron  : Racine = centre de l'UpperTorso R15 (2 x 1.6 x 1).
  Jambieres : Racine entre les deux jambes, à hauteur du genou (hanches y = +1, chevilles y = -1) ;
              sous-Models JambeG (x = -0.5) / JambeD (x = +0.5), PrimaryPart "Centre" soudé à Racine.
  Devant = -Z, haut = +Y, droite du perso = +X. Dans Blender : (x, y, z)_Roblox -> (x, -z, y).
"""
import math, os, sys, random, re

ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.abspath(os.path.join(ICI, '..', '..'))
D_LUA = os.path.join(JEU, 'src', 'partage', 'ArmuresVoxels')
D_EPEES = os.path.join(JEU, 'src', 'partage', 'ArmesVoxels')
D_PNG = {'Plastron': os.path.join(JEU, 'previews', 'armes', 'plastrons_minerais'),
         'Jambieres': os.path.join(JEU, 'previews', 'armes', 'jambieres_minerais'),
         'Set': os.path.join(JEU, 'previews', 'armes', 'sets_minerais')}

# ordre de rareté (Forge.lua)
LISTE = ['Soufre', 'Quartz', 'Argent', 'Obsidienne', 'Givrite', 'Emeraude', 'Rubis', 'Lunarite',
         'Magmaite', 'Diamant', 'Orichalque', 'Neantite']

import bpy, bmesh
from mathutils import Vector, Matrix

# ================================================================== géométrie (repère Roblox)
I3 = Matrix.Identity(3)
UP = Vector((0, 1, 0))
MX = Matrix.Diagonal((-1, 1, 1))


def V(x, y, z):
    return Vector((x, y, z))


def rot(axe, deg):
    return Matrix.Rotation(math.radians(deg), 3, axe)


def E(rx=0, ry=0, rz=0):
    """Rotation : roulis (Z local) puis tangage (X) puis lacet (Y)."""
    return rot('Y', ry) @ rot('X', rx) @ rot('Z', rz)


def repere(n, bhint):
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


P = []          # pièces en cours
GRP = [None]    # groupe courant (JambeD pendant la construction d'une jambe)
RND = random.Random(1)


def piece(nom, cle, taille, pos, R=I3, forme='Bloc', tag=None):
    p = dict(nom=nom, cle=cle, forme=forme, taille=Vector(taille), pos=Vector(pos), R=R.copy(), tag=tag, grp=GRP[0])
    P.append(p)
    return p


def jit(R, a):
    if a <= 0:
        return R
    return R @ rot('X', RND.uniform(-a, a)) @ rot('Y', RND.uniform(-a, a)) @ rot('Z', RND.uniform(-a, a))


def K(k):
    return k() if callable(k) else k


def alterne(*cles):
    return lambda: cles[RND.randrange(len(cles))]


def plaque(nom, cle, c, R, taille, j=0, frag=None, jeu=0.9):
    """Plaque (bloc) ; frag = (nx, ny) : découpée en tuiles disjointes (joints visibles) le long de X/Y locaux."""
    c = Vector(c)
    if not frag:
        return piece(nom, K(cle), taille, c, jit(R, j))
    nx, ny = frag
    tx, ty = taille[0] / nx, taille[1] / ny
    for ix in range(nx):
        for iy in range(ny):
            q = c + R.col[0] * ((ix + 0.5) * tx - taille[0] / 2) + R.col[1] * ((iy + 0.5) * ty - taille[1] / 2)
            piece(nom, K(cle), (tx * jeu, ty * jeu, taille[2]), q + R.col[2] * RND.uniform(-0.015, 0.015), jit(R, j))


def barre(nom, cle, p0, p1, w, ep, n, ext=None, tag=None):
    p0, p1 = Vector(p0), Vector(p1)
    d = p1 - p0
    R = repere_y(d, n)
    return piece(nom, K(cle), (w, d.length + (w if ext is None else ext), ep), (p0 + p1) / 2, R, tag=tag)


def losange(nom, cle, c, n, cote, ep, up=UP, tag=None):
    return piece(nom, K(cle), (cote, cote, ep), c, repere(n, up) @ rot('Z', 45), tag=tag)


def triangle(nom, cle, a, b, c, ep, dehors, tag=None):
    a, b, c = Vector(a), Vector(b), Vector(c)
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


def tente(nom, cle, base, d, L, wx, wz, zhint, R_extra=I3):
    """Pointe en toit : 2 WedgePart dos à dos."""
    R = repere_y(d, zhint) @ R_extra
    c = Vector(base) + R.col[1] * (L / 2)
    for sgn, Rw in ((-1, R), (1, R @ rot('Y', 180))):
        piece(nom, cle, (wx, L, wz / 2), c + R.col[2] * (sgn * wz / 4), Rw, forme='Coin')


def gemme_longue(cle_cadre, cle_gemme, c, n, L, w, ep=0.07, up=UP, nom='Gemme', cadre=0.05, cle_gemme2=None,
                 tag='lumiere'):
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
             centre=c - n * 0.2, tag=tag)


def rivet(cle, c, n, t=0.07, nom='Rivets'):
    losange(nom, cle, Vector(c) - Vector(n).normalized() * (t * 0.15), n, t, t * 0.5)


def veine(cle, c, n, L, a, up=UP, nom='Veines'):
    """Fissure lumineuse en Y (2 baguettes Neon) posée sur une surface de normale n."""
    R = repere(n, up) @ rot('Z', a)
    piece(nom, cle, (0.045, L, 0.03), c, R)
    piece(nom, cle, (0.04, L * 0.55, 0.03), Vector(c) + R.col[1] * (L * 0.4) + R.col[0] * 0.07, R @ rot('Z', 40))


def arc(nom, cle, centre, n, up, r, a0, a1, N, ep_fn, prof=0.08):
    """Arc de cercle (barres) dans le plan de normale n ; ep_fn(t) = largeur radiale."""
    R = repere(n, up)
    X, Y = R.col[0], R.col[1]
    for k in range(N):
        f0, f1 = math.radians(a0 + (a1 - a0) * k / N), math.radians(a0 + (a1 - a0) * (k + 1) / N)
        p0 = centre + (X * math.cos(f0) + Y * math.sin(f0)) * r
        p1 = centre + (X * math.cos(f1) + Y * math.sin(f1)) * r
        e = ep_fn((k + 0.5) / N)
        rad = ((p0 + p1) / 2 - centre).normalized()
        barre(nom, cle, p0 - rad * (e / 2), p1 - rad * (e / 2), e, prof, n, ext=0.03)


def miroir(depuis, grp=None):
    """Duplique en miroir (x -> -x) les pièces ajoutées depuis l'indice donné (option : nouveau groupe)."""
    for p in list(P[depuis:]):
        q = dict(p)
        q['pos'] = V(-p['pos'].x, p['pos'].y, p['pos'].z)
        q['R'] = MX @ p['R'] @ MX
        if grp:
            q['grp'] = grp
        P.append(q)


# ================================================================== plastron : squelette commun
# Torse R15 : x ±1, y ±0.8, z ±0.5. Plaques à ~0.6 du centre (devant) ; épaulières au-dessus des bras.
def R_poit(s):
    return E(ry=-s * 12)


def poitrine(x, y, out=0.0):
    """Point (et normale) sur la face avant d'une plaque de poitrine (en V, arête au centre)."""
    s = 1 if x >= 0 else -1
    R = R_poit(s)
    c = V(s * 0.5, 0.36, -0.64)
    u = (x - c.x) / R.col[0].x
    n = -R.col[2]
    return c + R.col[0] * u + V(0, y - 0.36, 0) + n * (0.06 + out), n


def Y_LAME(i):
    return -0.21 - 0.24 * i


def R_lame(s):
    return E(rx=8, ry=-s * 8)


def ventre(x, i, dy=0.0, out=0.0):
    s = 1 if x >= 0 else -1
    R = R_lame(s)
    c = V(s * 0.48, Y_LAME(i), -0.62 - 0.02 * i)
    u = (x - c.x) / R.col[0].x
    n = -R.col[2]
    return c + R.col[0] * u + R.col[1] * dy + n * (0.06 + out), n


def R_ep(s):
    return E(rz=-s * 8)


def epaule(s, t, z=0.0, out=0.0):
    """Point sur le dessus de l'épaulière (t = distance vers l'extérieur depuis son centre)."""
    R = R_ep(s)
    c = V(s * 1.05, 0.96, 0)
    return c + R.col[0] * (s * t) + V(0, 0, z) + R.col[1] * (0.1 + out), R.col[1]


def plastron_base(k, j=0, frag=None, frag_dos=None, faulds=False, epaul=2, col=True, cap_frag=None):
    piece('Dessous', K(k['dessous']), (2.02, 1.66, 1.02), V(0, -0.06, 0))
    for s in (1, -1):
        plaque('Poitrine', k['plaque'], V(s * 0.5, 0.36, -0.64), R_poit(s), (1.0, 0.86, 0.12), j, frag)
        piece('Liseré', K(k['cadre']), (1.04, 0.1, 0.16), V(s * 0.5, 0.8, -0.66), R_poit(s))
    piece('Arete', K(k['cadre']), (0.16, 0.9, 0.16), V(0, 0.35, -0.72), E(ry=45))
    for i in range(3):
        for s in (1, -1):
            plaque('Lames', k['plaque2'], V(s * 0.48, Y_LAME(i), -0.62 - 0.02 * i), R_lame(s),
                   (0.98 + 0.02 * i, 0.28, 0.12), j, (2, 1) if frag else None)
    # flancs
    for s in (1, -1):
        plaque('Flanc', k['plaque2'], V(s * 1.06, -0.14, 0.0), E(ry=s * 90), (1.02, 1.28, 0.12), j)
    # dossière + lames du dos + échine
    plaque('Dossiere', k['plaque'], V(0, 0.32, 0.62), E(ry=180), (1.96, 0.94, 0.12), j, frag_dos)
    piece('Dossiere', K(k['cadre']), (0.14, 0.92, 0.1), V(0, 0.32, 0.7))
    for i in range(3):
        plaque('Dossiere', k['plaque2'], V(0, Y_LAME(i), 0.62 + 0.02 * i), E(rx=-8), (1.98 + 0.02 * i, 0.28, 0.12), j,
               (3, 1) if frag_dos else None)
    # gorgerin (anneau autour de la base du casque)
    if col:
        piece('Col', K(k['cadre']), (1.4, 0.16, 0.14), V(0, 0.88, -0.7), E(rx=15))
        piece('Col', K(k['cadre']), (1.4, 0.16, 0.14), V(0, 0.88, 0.68), E(rx=-15))
        for s in (1, -1):
            piece('Col', K(k['cadre']), (0.14, 0.16, 1.4), V(s * 0.72, 0.88, -0.01), E(rz=-s * 15))
    # épaulières (au-dessus du bras : bras R15 = x 1..2, y < 0.8)
    for s in (1, -1):
        plaque('Epauliere', k['plaque'], V(s * 1.05, 0.96, 0), R_ep(s), (1.0, 0.2, 1.26), j, cap_frag)
        piece('Epauliere', K(k['plaque2']), (0.6, 0.18, 1.2), V(s * 1.72, 0.92, 0), jit(E(rz=-s * 28), j))
        piece('Epauliere', K(k['cadre']), (0.12, 0.26, 1.3), V(s * 1.5, 0.98, 0), E(rz=-s * 8))
        if epaul >= 2:
            piece('Epauliere', K(k['plaque']), (0.16, 0.44, 1.14), V(s * 2.04, 0.66, 0), jit(E(rz=-s * 8), j))
    # ceinture
    piece('Ceinture', K(k['ceinture']), (2.14, 0.16, 1.18), V(0, -0.84, 0))
    piece('Boucle', K(k['boucle']), (0.32, 0.26, 0.08), V(0, -0.84, -0.62))
    piece('Boucle', K(k['dessous']), (0.14, 0.1, 0.04), V(0, -0.84, -0.665))
    if faulds:
        for s in (1, -1):
            piece('Tassette', K(k['plaque2']), (0.64, 0.3, 0.1), V(s * 0.46, -1.06, -0.6), jit(E(rx=6), j))
            piece('Tassette', K(k['cadre']), (0.66, 0.06, 0.12), V(s * 0.46, -1.2, -0.62), E(rx=6))


# ================================================================== jambières : squelette (jambe droite)
CJ = 0.5   # centre de la jambe droite ; extérieur = +x


def cuisse(dx, y, out=0.0):
    return V(CJ + dx, y, -0.64 - out), V(0, 0, -1)


def greve(dx, y, out=0.0):
    return V(CJ + dx, y, -0.64 - out), V(0, 0, -1)


def cote(y, z, out=0.0):
    return V(CJ + 0.61 + out, y, z), V(1, 0, 0)


def jambe_base(k, j=0, frag=None, mollet=True):
    piece('Dessous', K(k['dessous']), (0.96, 1.86, 1.0), V(CJ, 0, 0))
    # cuissard
    plaque('Cuissard', k['plaque'], V(CJ, 0.54, -0.58), E(rx=4), (0.94, 0.78, 0.12), j, frag)
    piece('Cuissard', K(k['cadre']), (1.0, 0.12, 0.18), V(CJ, 0.94, -0.6))
    plaque('Cuissard', k['plaque2'], V(CJ + 0.55, 0.54, 0.0), E(ry=90), (0.92, 0.78, 0.12), j)
    # genouillère
    piece('Genouillere', K(k['cadre']), (0.66, 0.42, 0.16), V(CJ, 0.02, -0.64))
    piece('Genouillere', K(k['plaque']), (0.14, 0.4, 0.56), V(CJ + 0.56, 0.02, -0.28), jit(I3, j))
    # grève
    plaque('Greve', k['plaque'], V(CJ, -0.5, -0.58), E(rx=-3), (0.92, 0.8, 0.12), j, frag)
    piece('Greve', K(k['cadre']), (0.14, 0.72, 0.14), V(CJ, -0.5, -0.645), E(ry=45))
    plaque('Greve', k['plaque2'], V(CJ + 0.55, -0.5, 0.0), E(ry=90), (0.94, 0.8, 0.12), j)
    if mollet:
        plaque('Mollet', k['plaque2'], V(CJ, -0.48, 0.58), E(rx=3), (0.92, 0.74, 0.12), j)
    piece('Cheville', K(k['cadre']), (1.0, 0.14, 1.14), V(CJ + 0.02, -0.92, 0))


# ================================================================== les 12 armures
ARMURES = {}


def armure(nomP, nomJ, lumP=None, lumJ=None, particules=None):
    def deco(fn):
        ARMURES[fn.__name__] = dict(fn=fn, Plastron=nomP, Jambieres=nomJ, lumP=lumP, lumJ=lumJ, particules=particules)
        return fn
    return deco


# matériaux : clé -> (matériau Roblox, rgb, reflectance, metal, rugosité, émission)
# ------------------------------------------------------------------ Soufre (rang 1)
@armure("Plastron de soufre", "Jambières de soufre")
def Soufre(t):
    M = {'soufre': ('Slate', (214, 168, 52), 0, 0, 0.7, 0), 'soufre2': ('Slate', (190, 146, 40), 0, 0, 0.75, 0),
         'soufre3': ('Slate', (230, 190, 80), 0, 0, 0.7, 0),
         'fer': ('Metal', (98, 84, 92), 0.05, 0.6, 0.5, 0), 'fer2': ('Metal', (78, 66, 74), 0.05, 0.6, 0.55, 0),
         'rivet': ('Metal', (150, 132, 140), 0.1, 0.8, 0.35, 0), 'cuir': ('Fabric', (70, 46, 30), 0, 0, 0.9, 0)}
    s3 = alterne('soufre', 'soufre2', 'soufre3')
    k = dict(plaque=s3, plaque2=s3, cadre='fer', dessous='cuir', ceinture='fer2', boucle='rivet')
    if t == 'Plastron':
        plastron_base(k, j=1, epaul=1)
        # sangles de fer verticales (poitrine + ventre) et rivets
        for s in (1, -1):
            x = s * 0.44
            a, n = poitrine(x, 0.76, 0.0)
            b, _ = poitrine(x, -0.04, 0.0)
            barre('Sangles', 'fer2', a, b, 0.17, 0.07, n, ext=0.0)
            a, n = ventre(x, 0, 0.13, 0.0)
            b, _ = ventre(x, 2, -0.13, 0.0)
            barre('Sangles', 'fer2', a, b, 0.17, 0.07, n, ext=0.0)
            for y in (0.62, 0.16):
                c, n = poitrine(x, y, 0.035)
                rivet('rivet', c, n)
            for i in (0, 2):
                c, n = ventre(x, i, 0, 0.035)
                rivet('rivet', c, n)
            c, n = epaule(s, 0.0, -0.45, 0.0)
            rivet('rivet', c, n, 0.08)
            c, n = epaule(s, 0.0, 0.45, 0.0)
            rivet('rivet', c, n, 0.08)
    else:
        jambe_base(k, j=1)
        for y in (0.66, -0.66):
            piece('Sangles', 'fer2', (0.98, 0.12, 0.08), V(CJ, y, -0.66))
            for dx in (-0.36, 0.36):
                c, n = cuisse(dx, y, 0.04)
                rivet('rivet', c, n, 0.07)
        piece('Genouillere', 'fer2', (0.24, 0.24, 0.1), V(CJ, 0.02, -0.75), E(rz=45))
        c, n = cote(0.02, -0.3, 0.02)
        rivet('rivet', c, n, 0.08)
    return M


# ------------------------------------------------------------------ Quartz (rang 2)
@armure("Plastron de quartz", "Jambières de quartz")
def Quartz(t):
    M = {'pierre': ('Slate', (128, 112, 120), 0, 0, 0.8, 0), 'pierre2': ('Slate', (104, 92, 100), 0, 0, 0.85, 0),
         'cadre': ('Slate', (150, 134, 140), 0, 0, 0.75, 0),
         'quartz': ('SmoothPlastic', (232, 186, 218), 0.1, 0, 0.25, 0),
         'quartz2': ('SmoothPlastic', (210, 156, 196), 0.1, 0, 0.25, 0),
         'quartz3': ('SmoothPlastic', (246, 214, 236), 0.15, 0, 0.2, 0),
         'cuir': ('Fabric', (82, 52, 40), 0, 0, 0.9, 0)}
    pi = alterne('pierre', 'pierre2')
    k = dict(plaque=pi, plaque2=pi, cadre='cadre', dessous='cuir', ceinture='pierre2', boucle='quartz3')
    if t == 'Plastron':
        plastron_base(k, j=2, epaul=1)
        # gros cristal de quartz pyramidal sur la poitrine
        coins = [poitrine(x, y, 0.0)[0] for x, y in ((-0.62, 0.02), (-0.5, 0.6), (0.0, 0.8), (0.5, 0.6), (0.62, 0.02))]
        sommet = V(0, 0.36, -1.04)
        pyramide('Cristal', ['quartz', 'quartz3', 'quartz2', 'quartz3', 'quartz'], coins, sommet, ep=0.06,
                 centre=V(0, 0.36, -0.3))
        triangle('Cristal', 'quartz2', coins[0], coins[4], sommet, 0.06, V(0, -0.5, -1))
        # bandes de quartz sur le dessus des épaulières
        for s in (1, -1):
            for z, kq in ((-0.36, 'quartz'), (0.0, 'quartz3'), (0.36, 'quartz2')):
                piece('Epauliere', kq, (0.86, 0.06, 0.26), epaule(s, -0.02, z, 0.0)[0], R_ep(s))
    else:
        jambe_base(k, j=2)
        # bandes de quartz sur la grève et le cuissard (séparées par la pierre)
        for dx, kq in ((-0.27, 'quartz'), (0.0, 'quartz3'), (0.27, 'quartz2')):
            piece('Bandes', kq, (0.22, 0.62, 0.06), greve(dx, -0.52, 0.0)[0], E(rx=-3))
        for dx, kq in ((-0.2, 'quartz2'), (0.2, 'quartz')):
            piece('Bandes', kq, (0.3, 0.5, 0.06), cuisse(dx, 0.52, -0.02)[0], E(rx=4))
        # petit cristal pyramidal sur le genou
        c = V(CJ, 0.02, -0.72)
        coins = [c + V(0, 0.2, 0), c + V(0.2, 0, 0), c + V(0, -0.2, 0), c + V(-0.2, 0, 0)]
        pyramide('Cristal', ['quartz', 'quartz3'], coins, c + V(0, 0, -0.16), ep=0.04, centre=c + V(0, 0, 0.2))
    return M


# ------------------------------------------------------------------ Argent (rang 3)
@armure("Plastron d'argent", "Jambières d'argent", lumP=((200, 150, 255), 5, 0.7))
def Argent(t):
    M = {'argent': ('Metal', (176, 172, 182), 0.15, 0.85, 0.35, 0), 'argent2': ('Metal', (146, 142, 152), 0.1, 0.85, 0.4, 0),
         'argent3': ('Metal', (204, 200, 208), 0.2, 0.85, 0.3, 0),
         'amethyste': ('SmoothPlastic', (168, 110, 230), 0.1, 0, 0.25, 0),
         'amethyste2': ('SmoothPlastic', (196, 150, 246), 0.1, 0, 0.25, 0),
         'gemme': ('Neon', (190, 130, 255), 0, 0, 0.3, 3), 'cuir': ('Fabric', (80, 88, 110), 0, 0, 0.9, 0),
         'fente': ('SmoothPlastic', (14, 12, 16), 0, 0, 1, 0)}
    ag = alterne('argent', 'argent2')
    k = dict(plaque='argent', plaque2=ag, cadre='argent3', dessous='cuir', ceinture='argent2', boucle='argent3')
    if t == 'Plastron':
        plastron_base(k, j=0, faulds=True)
        gemme_longue('argent3', 'gemme', V(0, 0.44, -0.86), V(0, 0, -1), 0.36, 0.22)
        for s in (1, -1):
            # améthystes : sur la lame d'épaulière et sur le flanc
            piece('Epauliere', 'amethyste', (0.44, 0.06, 0.9), V(s * 1.72, 0.92, 0) + E(rz=-s * 28).col[1] * 0.1,
                  E(rz=-s * 28))
            piece('Flanc', 'amethyste2', (0.06, 0.7, 0.5), V(s * 1.13, -0.1, 0))
            # liseré gravé le long des plaques de poitrine
            a, n = poitrine(s * 0.86, 0.72, 0.0)
            b, _ = poitrine(s * 0.86, 0.0, 0.0)
            barre('Gravure', 'argent3', a, b, 0.06, 0.05, n)
            c, n = poitrine(s * 0.62, 0.62, 0.03)
            rivet('argent3', c, n, 0.08)
            losange('Tassette', 'amethyste', V(s * 0.46, -1.06, -0.66), V(0, 0.1, -1), 0.14, 0.05)
            # crête sur l'épaulière + fentes de visière sur la lame du milieu (comme le casque)
            piece('Crete', 'argent3', (0.1, 0.14, 1.1), epaule(s, -0.05, 0.0, 0.05)[0], R_ep(s))
            for x in (0.3, 0.5, 0.7):
                c, n = ventre(s * x, 1, 0.0, 0.0)
                piece('Fentes', 'fente', (0.05, 0.17, 0.03), c, R_lame(s))
    else:
        jambe_base(k)
        piece('Cuissard', 'amethyste', (0.05, 0.5, 0.56), V(CJ + 0.62, 0.54, 0))
        piece('Greve', 'amethyste2', (0.05, 0.5, 0.56), V(CJ + 0.62, -0.5, 0))
        losange('Genouillere', 'amethyste', V(CJ, 0.02, -0.74), V(0, 0, -1), 0.2, 0.06)
        for dx in (-0.34, 0.34):
            c, n = cuisse(dx, 0.76, 0.0)
            rivet('argent3', c, n, 0.07)
    return M


# ------------------------------------------------------------------ Obsidienne (rang 4)
@armure("Plastron d'obsidienne", "Jambières d'obsidienne", lumP=((190, 70, 255), 5, 0.8))
def Obsidienne(t):
    M = {'obs': ('SmoothPlastic', (34, 28, 40), 0.12, 0, 0.35, 0), 'obs2': ('SmoothPlastic', (52, 42, 60), 0.1, 0, 0.4, 0),
         'obs3': ('SmoothPlastic', (72, 58, 82), 0.08, 0, 0.45, 0),
         'veine': ('Neon', (182, 60, 255), 0, 0, 0.3, 3), 'gemme': ('Neon', (205, 110, 255), 0, 0, 0.3, 4),
         'cuir': ('Fabric', (40, 28, 48), 0, 0, 0.9, 0)}
    ob = alterne('obs', 'obs2', 'obs', 'obs3')
    k = dict(plaque=ob, plaque2=ob, cadre='obs3', dessous='cuir', ceinture='obs2', boucle='obs3')
    if t == 'Plastron':
        plastron_base(k, j=4, faulds=True)
        gemme_longue('obs3', 'gemme', V(0, 0.44, -0.86), V(0, 0, -1), 0.34, 0.2)
        for s in (1, -1):
            for x, y, L, a in ((0.6, 0.5, 0.36, 30), (0.3, 0.12, 0.3, -40)):
                c, n = poitrine(s * x, y, 0.005)
                veine('veine', c, n, L, s * a)
            c, n = ventre(s * 0.55, 1, 0.0, 0.005)
            veine('veine', c, n, 0.26, s * 70)
            c, n = epaule(s, 0.1, 0.2, 0.005)
            veine('veine', c, n, 0.3, s * 20, up=V(0, 0, -1))
            veine('veine', V(s * 0.5, 0.4, 0.685), V(0, 0, 1), 0.32, s * 35)
    else:
        jambe_base(k, j=4)
        veine('veine', cuisse(0.15, 0.55, 0.005)[0], V(0, 0, -1), 0.34, 25)
        veine('veine', greve(-0.2, -0.45, 0.005)[0], V(0, 0, -1), 0.3, -30)
        veine('veine', cote(-0.5, 0.1, 0.005)[0], V(1, 0, 0), 0.3, 40)
        losange('Genouillere', 'obs3', V(CJ, 0.02, -0.73), V(0, 0, -1), 0.26, 0.06)
        losange('Genouillere', 'gemme', V(CJ, 0.02, -0.765), V(0, 0, -1), 0.15, 0.05)
    return M


# ------------------------------------------------------------------ Givrite (rang 5)
@armure("Plastron de givrite", "Jambières de givrite", lumP=((150, 210, 255), 5, 0.8))
def Givrite(t):
    M = {'glace': ('SmoothPlastic', (150, 190, 236), 0.15, 0, 0.2, 0), 'glace2': ('SmoothPlastic', (120, 166, 222), 0.15, 0, 0.2, 0),
         'glace3': ('SmoothPlastic', (190, 218, 248), 0.2, 0, 0.15, 0),
         'argent': ('Metal', (206, 208, 220), 0.15, 0.8, 0.3, 0), 'gemme': ('Neon', (150, 210, 255), 0, 0, 0.3, 2.5),
         'gemme2': ('Neon', (220, 240, 255), 0, 0, 0.3, 3), 'cuir': ('Fabric', (88, 102, 134), 0, 0, 0.9, 0)}
    g = alterne('glace', 'glace2', 'glace3')
    k = dict(plaque=g, plaque2=g, cadre='argent', dessous='cuir', ceinture='argent', boucle='glace3')
    if t == 'Plastron':
        plastron_base(k, j=2, faulds=True)
        gemme_longue('argent', 'gemme', V(0, 0.42, -0.86), V(0, 0, -1), 0.5, 0.2, cle_gemme2='gemme2')
        for s in (1, -1):
            # éclats de glace sur l'épaulière, couchés vers l'extérieur et l'arrière
            for tt, z, d, L, w in ((-0.15, -0.3, V(s * 0.3, 1, 0.15), 0.5, 0.2), (0.15, 0.1, V(s * 0.6, 1, 0.3), 0.6, 0.22),
                                   (0.3, 0.42, V(s * 0.7, 0.8, 0.6), 0.42, 0.18)):
                cristal('Cristaux', RND.choice(['glace', 'glace3']), epaule(s, tt, z, -0.08)[0], d, L, w, cle2='glace3')
            # liserés d'argent sur les lames
            a, n = ventre(s * 0.02, 2, -0.13, 0.0)
            b, _ = ventre(s * 0.95, 2, -0.13, 0.0)
            barre('Liseré', 'argent', a, b, 0.06, 0.05, n)
    else:
        jambe_base(k, j=2)
        cristal('Cristaux', 'glace3', V(CJ, 0.08, -0.7), V(0, 0.9, -0.6), 0.42, 0.18, cle2='glace')
        cristal('Cristaux', 'glace', cote(0.6, 0.05, -0.04)[0], V(1, 0.9, 0.2), 0.4, 0.17, cle2='glace3')
        losange('Genouillere', 'gemme', V(CJ, -0.1, -0.74), V(0, 0, -1), 0.12, 0.05)
    return M


# ------------------------------------------------------------------ Emeraude (rang 6)
@armure("Plastron d'émeraude", "Jambières d'émeraude", lumP=((60, 230, 110), 5, 0.8))
def Emeraude(t):
    M = {'roche': ('Slate', (74, 68, 74), 0, 0, 0.8, 0), 'roche2': ('Slate', (58, 54, 60), 0, 0, 0.85, 0),
         'roche3': ('Slate', (92, 86, 90), 0, 0, 0.8, 0), 'cadre': ('Metal', (94, 88, 92), 0.05, 0.5, 0.5, 0),
         'emeraude': ('SmoothPlastic', (40, 190, 70), 0.15, 0, 0.2, 0), 'emeraude2': ('SmoothPlastic', (30, 150, 56), 0.15, 0, 0.2, 0),
         'gemme': ('Neon', (60, 230, 100), 0, 0, 0.3, 2.5), 'cuir': ('Fabric', (66, 66, 44), 0, 0, 0.9, 0)}
    r = alterne('roche', 'roche2', 'roche3')
    k = dict(plaque=r, plaque2=r, cadre='cadre', dessous='cuir', ceinture='cadre', boucle='emeraude')
    if t == 'Plastron':
        plastron_base(k, j=3, faulds=True)
        gemme_longue('cadre', 'gemme', V(0, 0.42, -0.86), V(0, 0, -1), 0.44, 0.18)
        for s in (1, -1):
            # incrustations d'émeraude dans la poitrine et les lames
            c, n = poitrine(s * 0.56, 0.36, -0.02)
            piece('Incrustation', 'emeraude', (0.48, 0.56, 0.06), c, R_poit(s))
            piece('Incrustation', 'cadre', (0.06, 0.62, 0.08), c + R_poit(s).col[0] * (s * 0.27), R_poit(s))
            c, n = ventre(s * 0.55, 1, 0, -0.02)
            piece('Incrustation', 'emeraude2', (0.5, 0.14, 0.06), c, R_lame(s))
            # couronne de cristaux sur l'épaulière
            for tt, z, d, L, w in ((0.0, -0.05, V(s * 0.25, 1, -0.1), 0.62, 0.24), (0.15, -0.4, V(s * 0.6, 1, -0.4), 0.44, 0.18),
                                   (0.15, 0.35, V(s * 0.6, 1, 0.4), 0.44, 0.18)):
                cristal('Cristaux', 'emeraude', epaule(s, tt, z, -0.08)[0], d, L, w, cle2='emeraude2')
    else:
        jambe_base(k, j=3)
        piece('Incrustation', 'emeraude', (0.44, 0.5, 0.06), greve(0, -0.5, -0.02)[0], E(rx=-3))
        piece('Incrustation', 'emeraude2', (0.44, 0.4, 0.06), cuisse(0, 0.52, -0.02)[0], E(rx=4))
        cristal('Cristaux', 'emeraude', V(CJ + 0.12, 0.05, -0.68), V(0.3, 0.8, -0.6), 0.4, 0.18, cle2='emeraude2')
        cristal('Cristaux', 'emeraude2', V(CJ - 0.12, 0.0, -0.68), V(-0.2, 0.6, -0.8), 0.3, 0.14, cle2='emeraude')
    return M


# ------------------------------------------------------------------ Rubis (rang 7)
@armure("Plastron de rubis", "Jambières de rubis", lumP=((255, 50, 90), 5, 0.9))
def Rubis(t):
    M = {'grenat': ('SmoothPlastic', (96, 40, 52), 0.08, 0, 0.45, 0), 'grenat2': ('SmoothPlastic', (78, 32, 44), 0.08, 0, 0.5, 0),
         'bronze': ('Metal', (130, 96, 84), 0.08, 0.7, 0.4, 0),
         'rubis': ('SmoothPlastic', (210, 34, 76), 0.15, 0, 0.2, 0), 'rubis2': ('SmoothPlastic', (172, 24, 60), 0.15, 0, 0.2, 0),
         'gemme': ('Neon', (255, 50, 100), 0, 0, 0.3, 2.5), 'gemme2': ('Neon', (255, 140, 170), 0, 0, 0.3, 3),
         'cuir': ('Fabric', (92, 56, 38), 0, 0, 0.9, 0)}
    gr = alterne('grenat', 'grenat2')
    rb = alterne('rubis', 'rubis2')
    k = dict(plaque=gr, plaque2=gr, cadre='bronze', dessous='cuir', ceinture='bronze', boucle='rubis')
    if t == 'Plastron':
        plastron_base(k, j=2, faulds=True)
        gemme_longue('bronze', 'gemme', V(0, 0.4, -0.86), V(0, 0, -1), 0.62, 0.26, cle_gemme2='gemme2')
        for s in (1, -1):
            # écailles de rubis sur les lames (2 par demi-lame, décalées)
            for i in range(3):
                for x in ((0.3, 0.72) if i % 2 == 0 else (0.5, 0.9)):
                    c, n = ventre(s * x, i, 0.02, 0.0)
                    piece('Ecailles', rb(), (0.36, 0.26, 0.06), c, jit(R_lame(s) @ E(rx=10), 3))
            # ailes de rubis sur l'épaulière
            for tt, z, L in ((0.0, -0.25, 0.56), (0.2, 0.2, 0.46)):
                cristal('Cristaux', 'rubis', epaule(s, tt, z, -0.08)[0], V(s * 0.9, 1, 0.25), L, 0.24, cle2='rubis2')
    else:
        jambe_base(k, j=2)
        for y, xs in ((0.66, (-0.22, 0.22)), (0.42, (0.0,))):
            for dx in xs:
                piece('Ecailles', rb(), (0.38, 0.28, 0.06), cuisse(dx, y, 0.0)[0], jit(E(rx=12), 3))
        gemme_longue('bronze', 'gemme', V(CJ, 0.02, -0.74), V(0, 0, -1), 0.3, 0.16, nom='Genouillere', tag=None)
        cristal('Cristaux', 'rubis', cote(0.1, -0.2, -0.04)[0], V(1, 0.8, 0.4), 0.38, 0.18, cle2='rubis2')
    return M


# ------------------------------------------------------------------ Lunarite (rang 8)
@armure("Plastron de lunarite", "Jambières de lunarite", lumP=((200, 170, 255), 5, 0.8))
def Lunarite(t):
    M = {'lune': ('SmoothPlastic', (176, 158, 228), 0.12, 0, 0.25, 0), 'lune2': ('SmoothPlastic', (150, 132, 210), 0.12, 0, 0.25, 0),
         'lune3': ('SmoothPlastic', (204, 188, 240), 0.15, 0, 0.2, 0),
         'argent': ('Metal', (214, 206, 214), 0.15, 0.8, 0.3, 0), 'gemme': ('Neon', (190, 150, 255), 0, 0, 0.3, 2.5),
         'cuir': ('Fabric', (128, 128, 144), 0, 0, 0.9, 0)}
    l = alterne('lune', 'lune2', 'lune3')
    k = dict(plaque=l, plaque2=l, cadre='argent', dessous='cuir', ceinture='argent', boucle='lune3')
    if t == 'Plastron':
        plastron_base(k, j=2, faulds=True)
        # croissant de lune d'argent sur la poitrine, ouvert vers le haut-droite, gemme au creux
        arc('Croissant', 'argent', V(0.02, 0.42, -0.9), V(0, 0, -1), UP, 0.42, 75, 365, 10,
            lambda u: 0.05 + 0.18 * math.sin(math.pi * u))
        gemme_longue('argent', 'gemme', V(0.12, 0.52, -0.88), V(0, 0, -1), 0.22, 0.16, cadre=0.03)
        for s in (1, -1):
            # oreille / pointe de lunarite sur l'épaulière
            cristal('Cristaux', 'lune3', epaule(s, 0.2, 0.0, -0.08)[0], V(s * 1, 0.9, 0.1), 0.48, 0.2, cle2='lune')
            # étoiles d'argent sur les lames
            c, n = ventre(s * 0.62, 1, 0.0, 0.0)
            losange('Etoiles', 'argent', c, n, 0.12, 0.04)
            losange('Etoiles', 'argent', c + V(0, 0, -0.01), n, 0.07, 0.05, up=V(1, 1, 0))
    else:
        jambe_base(k, j=2)
        arc('Croissant', 'argent', V(CJ, 0.02, -0.76), V(0, 0, -1), UP, 0.22, 75, 365, 8,
            lambda u: 0.04 + 0.1 * math.sin(math.pi * u), prof=0.06)
        cristal('Cristaux', 'lune3', cote(0.62, 0.0, -0.04)[0], V(1, 0.9, 0.1), 0.38, 0.16, cle2='lune')
    return M


# ------------------------------------------------------------------ Magmaite (rang 9)
@armure("Plastron de magmaïte", "Jambières de magmaïte", lumP=((255, 110, 30), 6, 1.2), lumJ=((255, 110, 30), 3, 0.5),
        particules='braises')
def Magmaite(t):
    M = {'basalte': ('Basalt', (66, 58, 60), 0, 0, 0.9, 0), 'basalte2': ('Basalt', (84, 74, 76), 0, 0, 0.9, 0),
         'basalte3': ('Basalt', (50, 44, 48), 0, 0, 0.9, 0),
         'magma': ('Neon', (255, 100, 24), 0, 0, 0.5, 4), 'coeur': ('Neon', (255, 150, 40), 0, 0, 0.5, 5)}
    b = alterne('basalte', 'basalte2', 'basalte3')
    k = dict(plaque=b, plaque2=b, cadre='basalte2', dessous='magma', ceinture='basalte3', boucle='basalte2')
    if t == 'Plastron':
        plastron_base(k, j=6, frag=(2, 2), frag_dos=(3, 2), faulds=True, cap_frag=(2, 1))
        # coeur de lave au centre de la poitrine (dans une gueule de basalte)
        losange('Coeur', 'basalte3', V(0, 0.42, -0.84), V(0, 0, -1), 0.36, 0.08)
        losange('Coeur', 'coeur', V(0, 0.42, -0.89), V(0, 0, -1), 0.22, 0.06, tag='lumiere')
        for s in (1, -1):
            # pointes de roche sur l'épaulière
            for tt, z, d, L, w in ((0.0, -0.3, V(s * 0.3, 1, -0.2), 0.48, 0.24), (0.1, 0.15, V(s * 0.5, 1, 0.2), 0.56, 0.26),
                                   (0.35, 0.45, V(s * 0.9, 0.6, 0.5), 0.38, 0.2)):
                cristal('Pointes', RND.choice(['basalte', 'basalte2']), epaule(s, tt, z, -0.1)[0], d, L, w,
                        tour=RND.uniform(20, 60), cle2='basalte3')
            for x, y, L, a in ((0.7, 0.55, 0.3, 60), (0.25, 0.65, 0.26, -30)):
                c, n = poitrine(s * x, y, 0.005)
                veine('magma', c, n, L, s * a, nom='Fissures')
    else:
        jambe_base(k, j=6, frag=(2, 2))
        losange('Genouillere', 'basalte3', V(CJ, 0.02, -0.74), V(0, 0, -1), 0.3, 0.08)
        losange('Genouillere', 'coeur', V(CJ, 0.02, -0.79), V(0, 0, -1), 0.16, 0.05, tag='lumiere')
        cristal('Pointes', 'basalte2', cote(0.05, -0.2, -0.06)[0], V(1, 0.5, 0.3), 0.42, 0.22, tour=35, cle2='basalte3')
        cristal('Pointes', 'basalte', V(CJ, 0.18, -0.7), V(0, 0.7, -1), 0.34, 0.2, tour=30, cle2='basalte3')
        veine('magma', cote(-0.5, 0.15, 0.005)[0], V(1, 0, 0), 0.3, 30, nom='Fissures')
    return M


# ------------------------------------------------------------------ Diamant (rang 10)
@armure("Plastron de diamant", "Jambières de diamant", lumP=((200, 230, 255), 6, 0.9), lumJ=((200, 230, 255), 3, 0.5),
        particules='etincelles')
def Diamant(t):
    M = {'diamant': ('SmoothPlastic', (196, 204, 240), 0.2, 0, 0.15, 0), 'diamant2': ('SmoothPlastic', (168, 178, 230), 0.2, 0, 0.15, 0),
         'diamant3': ('SmoothPlastic', (222, 228, 250), 0.25, 0, 0.1, 0),
         'argent': ('Metal', (212, 206, 216), 0.15, 0.8, 0.3, 0), 'gemme': ('Neon', (170, 220, 255), 0, 0, 0.3, 2.5),
         'cuir': ('Fabric', (96, 104, 130), 0, 0, 0.9, 0)}
    d3 = alterne('diamant', 'diamant2', 'diamant3')
    k = dict(plaque=d3, plaque2=d3, cadre='argent', dessous='cuir', ceinture='argent', boucle='diamant3')
    if t == 'Plastron':
        plastron_base(k, j=3, faulds=True)
        gemme_longue('argent', 'gemme', V(0, 0.42, -0.86), V(0, 0, -1), 0.46, 0.3)
        for s in (1, -1):
            # couronne d'éclats de diamant sur l'épaulière (grand au centre)
            for tt, z, d, L, w in ((0.0, 0.0, V(s * 0.2, 1, 0.05), 0.78, 0.28), (-0.15, -0.38, V(s * 0.3, 1, -0.4), 0.52, 0.22),
                                   (-0.15, 0.38, V(s * 0.3, 1, 0.4), 0.52, 0.22), (0.3, -0.2, V(s * 1, 0.8, -0.2), 0.42, 0.2),
                                   (0.3, 0.25, V(s * 1, 0.8, 0.3), 0.42, 0.2)):
                cristal('Cristaux', RND.choice(['diamant', 'diamant3']), epaule(s, tt, z, -0.1)[0], d, L, w, cle2='diamant3')
            # éclats latéraux du gorgerin
            cristal('Cristaux', 'diamant3', V(s * 0.74, 0.9, -0.2), V(s * 0.5, 1, -0.2), 0.3, 0.14, cle2='diamant')
            # liserés d'argent
            a, n = ventre(s * 0.02, 2, -0.13, 0.0)
            b, _ = ventre(s * 0.95, 2, -0.13, 0.0)
            barre('Liseré', 'argent', a, b, 0.06, 0.05, n)
    else:
        jambe_base(k, j=3)
        gemme_longue('argent', 'gemme', V(CJ, 0.02, -0.74), V(0, 0, -1), 0.3, 0.2, nom='Genouillere')
        for y, z, d, L in ((0.12, -0.25, V(1, 1, -0.2), 0.46), (-0.08, 0.15, V(1, 0.6, 0.3), 0.36)):
            cristal('Cristaux', RND.choice(['diamant', 'diamant3']), cote(y, z, -0.05)[0], d, L, 0.18, cle2='diamant3')
    return M


# ------------------------------------------------------------------ Orichalque (rang 11)
@armure("Plastron d'orichalque", "Jambières d'orichalque", lumP=((255, 210, 80), 6, 1.0), lumJ=((255, 210, 80), 3, 0.5),
        particules='etincelles_or')
def Orichalque(t):
    M = {'or': ('Metal', (232, 172, 52), 0.2, 0.9, 0.3, 0), 'or2': ('Metal', (204, 142, 38), 0.15, 0.9, 0.35, 0),
         'or3': ('Metal', (250, 206, 100), 0.25, 0.9, 0.25, 0), 'bronze': ('Metal', (104, 74, 54), 0.05, 0.6, 0.5, 0),
         'gemme': ('Neon', (255, 214, 60), 0, 0, 0.3, 3.5), 'cuir': ('Fabric', (92, 60, 36), 0, 0, 0.9, 0)}
    o = alterne('or', 'or2')
    k = dict(plaque=o, plaque2=o, cadre='or3', dessous='cuir', ceinture='bronze', boucle='or3')
    if t == 'Plastron':
        plastron_base(k, j=0, faulds=True)
        # soleil : disque de bronze, arche d'or, rayons et gemme
        cc = V(0, 0.4, -0.86)
        piece('Soleil', 'bronze', (0.62, 0.62, 0.06), cc + V(0, 0, 0.02), E(rz=45))
        arc('Soleil', 'or3', cc + V(0, 0, -0.02), V(0, 0, -1), UP, 0.4, 0, 360, 10, lambda u: 0.09, prof=0.08)
        gemme_longue('or3', 'gemme', cc + V(0, 0, -0.04), V(0, 0, -1), 0.36, 0.3)
        for kk in range(8):
            a = math.radians(kk * 45 + 22.5)
            dd = V(math.cos(a), math.sin(a), -0.15)
            tente('Rayons', 'or3' if kk % 2 else 'or', cc + V(math.cos(a), math.sin(a), 0) * 0.42 + V(0, 0, -0.03), dd,
                  0.28 if kk % 2 else 0.2, 0.07, 0.16, V(-math.sin(a), math.cos(a), 0))
        for s in (1, -1):
            # incrustations de bronze dans la poitrine
            c, n = poitrine(s * 0.78, 0.36, -0.02)
            piece('Incrustation', 'bronze', (0.22, 0.6, 0.06), c, R_poit(s))
            # rayons sur l'épaulière
            for tt, z, d, L in ((0.0, -0.35, V(s * 0.4, 1, -0.5), 0.4), (0.05, 0.0, V(s * 0.5, 1, 0), 0.52),
                                (0.0, 0.35, V(s * 0.4, 1, 0.5), 0.4)):
                cristal('Rayons', 'or3', epaule(s, tt, z, -0.06)[0], d, L, 0.15, cle2='or')
            c, n = ventre(s * 0.6, 1, 0, 0.0)
            piece('Incrustation', 'bronze', (0.5, 0.1, 0.05), c, R_lame(s))
    else:
        jambe_base(k)
        piece('Incrustation', 'bronze', (0.5, 0.5, 0.06), greve(0, -0.5, -0.02)[0], E(rx=-3))
        cc = V(CJ, 0.02, -0.74)
        piece('Soleil', 'bronze', (0.3, 0.3, 0.06), cc, E(rz=45))
        gemme_longue('or3', 'gemme', cc + V(0, 0, -0.03), V(0, 0, -1), 0.24, 0.2, nom='Genouillere', cadre=0.03)
        for kk in range(5):
            a = math.radians(30 + kk * 30)
            tente('Rayons', 'or3', cc + V(math.cos(a), math.sin(a), 0) * 0.19, V(math.cos(a), math.sin(a), -0.2), 0.16,
                  0.05, 0.1, V(-math.sin(a), math.cos(a), 0))
        cristal('Rayons', 'or3', cote(0.5, 0.0, -0.04)[0], V(1, 0.9, 0), 0.36, 0.14, cle2='or')
    return M


# ------------------------------------------------------------------ Neantite (rang 12)
@armure("Plastron de néantite", "Jambières de néantite", lumP=((230, 60, 255), 6, 1.0), lumJ=((230, 60, 255), 3, 0.5))
def Neantite(t):
    M = {'neant': ('SmoothPlastic', (52, 38, 60), 0.1, 0, 0.4, 0), 'neant2': ('SmoothPlastic', (40, 30, 48), 0.1, 0, 0.45, 0),
         'neant3': ('SmoothPlastic', (74, 58, 84), 0.1, 0, 0.4, 0),
         'neantite': ('SmoothPlastic', (220, 60, 240), 0.15, 0, 0.2, 0), 'neantite2': ('SmoothPlastic', (180, 40, 210), 0.15, 0, 0.2, 0),
         'gemme': ('Neon', (230, 70, 255), 0, 0, 0.3, 3), 'veine': ('Neon', (210, 50, 240), 0, 0, 0.3, 2.5),
         'cuir': ('Fabric', (34, 24, 40), 0, 0, 0.9, 0)}
    n_ = alterne('neant', 'neant2', 'neant3')
    k = dict(plaque=n_, plaque2=n_, cadre='neant3', dessous='cuir', ceinture='neant2', boucle='neant3')
    if t == 'Plastron':
        plastron_base(k, j=3, faulds=True)
        gemme_longue('neant3', 'gemme', V(0, 0.4, -0.86), V(0, 0, -1), 0.56, 0.24)
        for s in (1, -1):
            # cristaux magenta + pointes sombres sur l'épaulière
            for tt, z, d, L, w in ((0.0, -0.05, V(s * 0.25, 1, 0.0), 0.7, 0.24), (0.1, -0.42, V(s * 0.5, 1, -0.4), 0.46, 0.18),
                                   (0.1, 0.38, V(s * 0.5, 1, 0.4), 0.46, 0.18)):
                cristal('Cristaux', 'neantite', epaule(s, tt, z, -0.08)[0], d, L, w, cle2='neantite2')
            for z in (-0.2, 0.2):
                tente('Pointes', 'neant3', epaule(s, 0.38, z, -0.02)[0], V(s * 1, 0.5, 0), 0.32, 0.06, 0.2, V(0, 0, 1))
            # pointes du gorgerin (arrière / côtés)
            tente('Pointes', 'neant3', V(s * 0.74, 0.92, 0.25), V(s * 0.4, 1, 0.3), 0.3, 0.06, 0.2, V(1, 0, 0))
            # veines magenta
            for x, y, L, a in ((0.66, 0.5, 0.34, 30), (0.32, 0.1, 0.28, -45)):
                c, nn = poitrine(s * x, y, 0.005)
                veine('veine', c, nn, L, s * a)
            c, nn = ventre(s * 0.6, 1, 0.0, 0.005)
            veine('veine', c, nn, 0.26, s * 70)
            veine('veine', V(s * 0.55, 0.35, 0.685), V(0, 0, 1), 0.34, s * 30)
            losange('Tassette', 'neantite', V(s * 0.46, -1.06, -0.66), V(0, 0.1, -1), 0.14, 0.05)
            a, nn = ventre(s * 0.02, 2, -0.13, 0.0)
            b, _ = ventre(s * 0.95, 2, -0.13, 0.0)
            barre('Liseré', 'veine', a, b, 0.05, 0.05, nn)
        tente('Pointes', 'neant3', V(0, 0.92, 0.72), V(0, 1, 0.5), 0.36, 0.06, 0.22, V(1, 0, 0))
    else:
        jambe_base(k, j=3)
        cristal('Cristaux', 'neantite', V(CJ, 0.1, -0.7), V(0, 0.8, -0.7), 0.44, 0.2, cle2='neantite2', tag='lumiere')
        for y in (0.3, -0.25):
            tente('Pointes', 'neant3', cote(y, 0.0, -0.02)[0], V(1, 0.4, 0), 0.3, 0.06, 0.2, V(0, 0, 1))
        veine('veine', cuisse(-0.15, 0.55, 0.005)[0], V(0, 0, -1), 0.34, -25)
        veine('veine', greve(0.2, -0.45, 0.005)[0], V(0, 0, -1), 0.3, 30)
        cristal('Cristaux', 'neantite2', cote(0.6, 0.15, -0.04)[0], V(1, 1, 0.2), 0.36, 0.16, cle2='neantite')
        piece('Liseré', 'veine', (0.9, 0.04, 0.04), V(CJ, 0.86, -0.655))
        piece('Liseré', 'veine', (0.98, 0.04, 0.04), V(CJ + 0.02, -0.84, -0.58))
    return M


# ================================================================== construction d'une pièce
def generer(id_, t):
    """Construit les pièces (liste P) ; renvoie les matériaux utilisés."""
    global P, RND
    P = []
    RND = random.Random(sum(map(ord, id_ + t)))
    info = ARMURES[id_]
    if t == 'Jambieres':
        GRP[0] = 'JambeD'
        mats = info['fn'](t)
        GRP[0] = None
        miroir(0, 'JambeG')
    else:
        GRP[0] = None
        mats = info['fn'](t)
    cles = {p['cle'] for p in P}
    manque = cles - set(mats)
    assert not manque, (id_, t, manque)
    return {k: v for k, v in mats.items() if k in cles}


# ================================================================== Luau
def f4(x):
    s = '%.4f' % x
    s = s.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


PARTICULES = {
    'braises': dict(couleurs=((255, 176, 64), (210, 40, 10)), taux=5, vie=(1.2, 2.2), vitesse=(0.25, 0.6),
                    taille=0.09, acc=0.5),
    'etincelles': dict(couleurs=((255, 255, 255), (170, 210, 255)), taux=3, vie=(0.6, 1.2), vitesse=(0.05, 0.2),
                       taille=0.12, acc=0.0),
    'etincelles_or': dict(couleurs=((255, 240, 170), (255, 180, 40)), taux=3, vie=(0.8, 1.4), vitesse=(0.1, 0.3),
                          taille=0.08, acc=0.3),
}


def bornes(ps):
    lo, hi = V(1e9, 1e9, 1e9), V(-1e9, -1e9, -1e9)
    for p in ps:
        for x in sommets(p)[0]:
            for i in range(3):
                lo[i], hi[i] = min(lo[i], x[i]), max(hi[i], x[i])
    return lo, hi


def ecrire_lua(id_, t, mats):
    info = ARMURES[id_]
    nom = t + id_
    nom_aff = info[t]
    lum = info['lumP'] if t == 'Plastron' else info['lumJ']
    part = PARTICULES.get(info['particules']) if t == 'Plastron' else None
    jamb = t == 'Jambieres'
    lo, hi = bornes(P)
    taille = hi - lo
    repere_txt = ("Racine = centre de l'UpperTorso R15" if not jamb else
                  "Racine = entre les jambes, au genou (hanches y = +1, chevilles y = -1) ; JambeG x = -0.5, JambeD x = +0.5")
    L = ['-- Généré par blender/armes/armures_minerais.py (%d Parts en jeu, Racine%s). Ne pas modifier à la main.'
         % (len(P) + 1 + (2 if jamb else 0), ' et Centres comprises' if jamb else ' comprise'),
         '-- %s : assorti(es) au casque et à l\'épée du même minerai.' % nom_aff,
         '-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,',
         '-- donc visible par tous. Aperçu : previews/armes/%s/%s.png'
         % ('jambieres_minerais' if jamb else 'plastrons_minerais', nom),
         '-- Repère : %s. Devant = -Z, haut = +Y, droite = +X, unités = studs.' % repere_txt,
         '',
         '-- clé -> {matériau, r, g, b, reflectance}',
         'local COULEURS = {']
    for k, (rm, c, refl, *_r) in mats.items():
        L.append('\t["%s"] = {"%s", %d, %d, %d, %s},' % (k, rm, c[0], c[1], c[2], f4(refl)))
    L.append('}')
    L.append('')
    if jamb:
        L.append('-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), groupe, marque}')
    else:
        L.append('-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame (repère de Racine), marque ("lumiere")}')
    L.append('local PIECES = {')
    for p in P:
        R = p['R']
        cf = ', '.join(f4(x) for x in (p['pos'].x, p['pos'].y, p['pos'].z,
                                        R[0][0], R[0][1], R[0][2], R[1][0], R[1][1], R[1][2], R[2][0], R[2][1], R[2][2]))
        tz = p['taille']
        if jamb:
            extra = ', "%s"' % p['grp'] + (', "%s"' % p['tag'] if p['tag'] else '')
        else:
            extra = ', "%s"' % p['tag'] if p['tag'] else ''
        L.append('\t{"%s", "%s", "%s", Vector3.new(%s, %s, %s), CFrame.new(%s)%s},'
                 % (p['nom'], p['cle'], p['forme'], f4(tz.x), f4(tz.y), f4(tz.z), cf, extra))
    L.append('}')
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
    L.append('''local function invisible(nom: string, pos: Vector3): Part
	local p = Instance.new("Part")
	p.Name = nom
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = CFrame.new(pos)
	p.Transparency = 1
	p.CastShadow = false
	p.Anchored = false
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.Massless = true
	return p
end

local function souder(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end
''')
    lumiere_lua = ''
    if lum:
        lc, lp, lb = lum
        lumiere_lua = '''		if marque == "lumiere" and not lumieres[cleLumiere] then
			lumieres[cleLumiere] = true
			local l = Instance.new("PointLight")
			l.Color = Color3.fromRGB(%d, %d, %d)
			l.Range = %s
			l.Brightness = %s
			l.Shadows = false
			l.Parent = p%s
		end
''' % (lc[0], lc[1], lc[2], f4(lp), f4(lb), '\n\t\t\tparticules(p)' if part else '')
    elif part:
        raise RuntimeError('particules sans lumière')
    if jamb:
        corps = '''	-- sous-groupes JambeG / JambeD : Model + PrimaryPart "Centre" (centre de la jambe) soudé à Racine
	local groupes: { [string]: Model } = {}
	local centres: { [string]: BasePart } = {}
	for nomG, pos in GROUPES do
		local g = Instance.new("Model")
		g.Name = nomG
		local c = invisible("Centre", pos)
		c.Parent = g
		g.PrimaryPart = c
		g.Parent = modele
		souder(racine, c)
		groupes[nomG] = g
		centres[nomG] = c
	end

	local lumieres: { [string]: boolean } = {}
	for _, pc in PIECES do
		local nom, cle, forme, taille, cf, groupe, marque = pc[1], pc[2], pc[3], pc[4], pc[5], pc[6], pc[7]
		local cleLumiere = groupe
'''
        attache = '''		p.Parent = groupes[groupe]
		souder(centres[groupe], p)
'''
    else:
        corps = '''	local lumieres: { [string]: boolean } = {}
	for _, pc in PIECES do
		local nom, cle, forme, taille, cf, marque = pc[1], pc[2], pc[3], pc[4], pc[5], pc[6]
		local cleLumiere = ""
'''
        attache = '''		p.Parent = modele
		souder(racine, p)
'''
    if jamb:
        L.append('local GROUPES = {\n\tJambeG = Vector3.new(-0.5, 0, 0),\n\tJambeD = Vector3.new(0.5, 0, 0),\n}\n')
    L.append('''local function construire(): Model
	local modele = Instance.new("Model")
	modele.Name = "%s"
	modele:SetAttribute("NomAffiche", "%s")

	local racine = invisible("Racine", Vector3.zero)
	racine.Parent = modele
	modele.PrimaryPart = racine

%s		local c = COULEURS[cle]
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
%s%s	end
	return modele
end
''' % (nom, nom_aff, corps, lumiere_lua, attache))
    L.append('return {')
    L.append('\tNom = "%s",' % nom_aff)
    L.append('\tFormat = "Code",')
    L.append('\tTaille = Vector3.new(%s, %s, %s),' % (f4(taille.x), f4(taille.y), f4(taille.z)))
    L.append('\tCentre = Vector3.new(%s, %s, %s), -- centre de la boîte englobante dans le repère de Racine'
             % (f4((hi.x + lo.x) / 2), f4((hi.y + lo.y) / 2), f4((hi.z + lo.z) / 2)))
    if jamb:
        L.append('\tGroupes = GROUPES,')
    L.append('\tconstruire = construire,')
    L.append('}')
    f = os.path.join(D_LUA, nom + '.lua')
    open(f, 'w', encoding='utf8', newline='\n').write('\n'.join(L) + '\n')
    ntri = sum(12 if p['forme'] == 'Bloc' else 8 for p in P)
    print('LUA', nom, 'parts', len(P) + 1 + (2 if jamb else 0), 'tris', ntri, 'taille', tuple(round(x, 2) for x in taille))
    return len(P) + 1 + (2 if jamb else 0), ntri


# ================================================================== lecture des casques / épées générés (planche set)
def lire_casque(id_):
    txt = open(os.path.join(D_LUA, 'Casque%s.lua' % id_), encoding='utf8').read()
    mats = {}
    for k, rm, r, g, b, refl in re.findall(r'\["(\w+)"\] = \{"(\w+)", (\d+), (\d+), (\d+), ([\d.]+)\}', txt):
        mats[k] = mat_auto(rm, (int(r), int(g), int(b)), float(refl))
    ps = []
    for nom, cle, forme, t, cf in re.findall(
            r'\{"([^"]+)", "([^"]+)", "(Bloc|Coin)", Vector3\.new\(([^)]*)\), CFrame\.new\(([^)]*)\)', txt):
        t = [float(x) for x in t.split(',')]
        c = [float(x) for x in cf.split(',')]
        R = Matrix(((c[3], c[4], c[5]), (c[6], c[7], c[8]), (c[9], c[10], c[11])))
        ps.append(dict(nom=nom, cle='c_' + cle, forme=forme, taille=Vector(t), pos=V(c[0], c[1], c[2]), R=R))
    return ps, {'c_' + k: v for k, v in mats.items()}


def lire_epee(id_):
    txt = open(os.path.join(D_EPEES, 'Epee%s.lua' % id_), encoding='utf8').read()
    mats = {}
    for k, rm, r, g, b, refl in re.findall(r'\["(\w+)"\] = \{"(\w+)", (\d+), (\d+), (\d+), ([\d.]+)\}', txt):
        mats['e_' + k] = mat_auto(rm, (int(r), int(g), int(b)), float(refl))
    ps = []
    for nom, cle, t, pos, reste in re.findall(
            r'\{"([^"]+)", "([^"]+)", Vector3\.new\(([^)]*)\), Vector3\.new\(([^)]*)\), ([^}]*)\}', txt):
        champs = [x.strip() for x in reste.split(',') if x.strip()]
        ry = float(champs[0]) if champs else 0
        rz = float(champs[1]) if len(champs) > 1 else 0
        forme = champs[2].strip('"') if len(champs) > 2 else 'Bloc'
        t = Vector([float(x) for x in t.split(',')])
        if forme == 'Boule':
            t = t * 0.8
            forme = 'Bloc'
        ps.append(dict(nom=nom, cle='e_' + cle, forme='Coin' if forme == 'Coin' else 'Bloc', taille=t,
                       pos=Vector([float(x) for x in pos.split(',')]), R=rot('Z', rz) @ rot('Y', ry)))
    return ps, mats


def mat_auto(rm, c, refl):
    rough = {'Metal': 0.35, 'Neon': 0.5, 'Slate': 0.8, 'Basalt': 0.9, 'Fabric': 0.9, 'Sandstone': 0.8,
             'Glass': 0.12, 'Ice': 0.15}.get(rm, 0.3)
    metal = 0.85 if rm == 'Metal' else 0
    return (rm, c, refl, metal, rough, 3 if rm == 'Neon' else 0)


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
        if o.type in ('MESH', 'FONT'):
            bpy.data.objects.remove(o, do_unlink=True)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)
    for c in list(bpy.data.curves):
        bpy.data.curves.remove(c)


CACHE_MAT = {}


def materiau_b(cle, spec):
    cle_c = (cle, repr(spec))
    if cle_c in CACHE_MAT:
        return CACHE_MAT[cle_c]
    rm, c, refl, metal, rough, em = spec
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
    CACHE_MAT[cle_c] = m
    return m


def construire_blender(ps, mats, decal=V(0, 0, 0), prefixe=''):
    """decal : translation en coordonnées Roblox."""
    groupes = {}
    for p in ps:
        groupes.setdefault(p['cle'], []).append(p)
    for cle, gp in groupes.items():
        verts, faces_ = [], []
        for p in gp:
            vs, fs = sommets(p)
            k = len(verts)
            verts += [r2b(x + decal) for x in vs]
            faces_ += [tuple(i + k for i in f) for f in fs]
        me = bpy.data.meshes.new(prefixe + cle)
        me.from_pydata(verts, [], faces_)
        me.validate()
        bm = bmesh.new(); bm.from_mesh(me)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(me); bm.free()
        me.materials.append(materiau_b(prefixe + cle, mats[cle]))
        o = bpy.data.objects.new(prefixe + cle, me)
        bpy.context.scene.collection.objects.link(o)


# mannequin R15 (coordonnées monde : pieds à y = 0)
Y_PLASTRON, Y_JAMBES, Y_TETE = 3.2, 1.0, 4.6
MANNEQUIN = {
    'Tete': ((1.2, 1.2, 1.2), (0, 4.6, 0)), 'Torse': ((2, 1.6, 1), (0, 3.2, 0)), 'Bassin': ((2, 0.4, 1), (0, 2.2, 0)),
    'BrasD': ((1, 2, 1), (1.5, 3.0, 0)), 'BrasG': ((1, 2, 1), (-1.5, 3.0, 0)),
    'JambeD': ((1, 2, 1), (0.5, 1.0, 0)), 'JambeG': ((1, 2, 1), (-0.5, 1.0, 0)),
}
MAT_MANNEQUIN = {'mannequin': ('SmoothPlastic', (96, 100, 112), 0, 0, 0.7, 0)}


def mannequin(noms, decal=V(0, 0, 0)):
    ps = [dict(nom=n, cle='mannequin', forme='Bloc', taille=V(*MANNEQUIN[n][0]), pos=V(*MANNEQUIN[n][1]), R=I3)
          for n in noms]
    construire_blender(ps, MAT_MANNEQUIN, decal)


def decaler(ps, d):
    return [dict(p, pos=p['pos'] + d) for p in ps]


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
    soleils = []

    def soleil(nom, e, depuis, col):
        l = bpy.data.lights.new(nom, 'SUN'); l.energy = e; l.color = col; l.angle = math.radians(8)
        o = bpy.data.objects.new(nom, l); sc.collection.objects.link(o)
        o.rotation_euler = (-Vector(r2b(depuis))).to_track_quat('-Z', 'Y').to_euler()
        soleils.append(l)
    soleil("cle", 2.4, (0.9, 1.0, -0.8), (1, 0.97, 0.92))
    soleil('remplissage', 1.2, (-0.6, 0.2, -1.0), (0.85, 0.9, 1))
    soleil('contre', 2.5, (-0.3, 0.6, 1.0), (1, 1, 1))
    cam = bpy.data.cameras.new('C'); cam.lens = 50
    co = bpy.data.objects.new('C', cam); sc.collection.objects.link(co); sc.camera = co
    return sc, co, soleils


OEIL = (0.5, 0.28, -1.0)


def vue(sc, co, chemin, cible, dist, oeil=OEIL, res=(600, 600)):
    co.data.type = 'PERSP'
    sc.render.resolution_x, sc.render.resolution_y = res
    c = Vector(r2b(cible))
    d = Vector(r2b(oeil)).normalized()
    co.location = c + d * dist
    co.rotation_euler = (c - co.location).to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = chemin
    bpy.ops.render.render(write_still=True)
    print('PNG', chemin)


def texte(txt, pos_b, rot_e, taille=0.45):
    cu = bpy.data.curves.new('T', 'FONT')
    cu.body = txt
    cu.align_x = 'CENTER'
    cu.size = taille
    o = bpy.data.objects.new('T', cu)
    o.location = pos_b
    o.rotation_euler = rot_e
    m = bpy.data.materials.get('texte') or bpy.data.materials.new('texte')
    m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (1, 1, 1, 1)
    b.inputs['Emission Color'].default_value = (1, 1, 1, 1)
    b.inputs['Emission Strength'].default_value = 1.5
    cu.materials.append(m)
    bpy.context.scene.collection.objects.link(o)


def planche(sc, co, soleils, chemin, elements, cols, cw, ch, res, cible_y, oeil=OEIL):
    """elements : liste de (titre, fn(decal_roblox)) ; grille dans le plan de l'écran, caméra orthographique."""
    vider()
    rows = (len(elements) + cols - 1) // cols
    d = Vector(r2b(oeil)).normalized()
    q = (-d).to_track_quat('-Z', 'Y')
    Rm = q.to_matrix()
    droite_b, haut_b = Rm.col[0], Rm.col[1]
    # vecteurs en coordonnées Roblox : (x, y, z)_R -> (x, -z, y)_B  donc  R = (b.x, b.z, -b.y)
    droite = V(droite_b.x, droite_b.z, -droite_b.y)
    haut = V(haut_b.x, haut_b.z, -haut_b.y)
    for i, (titre, fn) in enumerate(elements):
        r, c = divmod(i, cols)
        off = droite * ((c - (cols - 1) / 2) * cw) - haut * ((r - (rows - 1) / 2) * ch)
        fn(off)
        pos_t = off + V(0, cible_y, 0) - haut * (ch * 0.47)
        texte(titre, Vector(r2b(pos_t)) + d * 3, q.to_euler(), taille=ch * 0.055)
    co.data.type = 'ORTHO'
    co.data.ortho_scale = max(cols * cw, rows * ch * res[0] / res[1])
    sc.render.resolution_x, sc.render.resolution_y = res
    c = Vector(r2b(V(0, cible_y, 0)))
    co.location = c + d * 40
    co.rotation_euler = q.to_euler()
    co.data.clip_end = 200
    sc.render.filepath = chemin
    bpy.ops.render.render(write_still=True)
    print('PLANCHE', chemin)


NOMS = {'Soufre': 'Soufre', 'Quartz': 'Quartz', 'Argent': 'Argent', 'Obsidienne': 'Obsidienne', 'Givrite': 'Givrite',
        'Emeraude': 'Émeraude', 'Rubis': 'Rubis', 'Lunarite': 'Lunarite', 'Magmaite': 'Magmaïte', 'Diamant': 'Diamant',
        'Orichalque': 'Orichalque', 'Neantite': 'Néantite'}


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc, co, soleils = scene_rendu()
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    choix = [a for a in args if not a.startswith('--')] or LISTE
    sans_planches = '--sans-planches' in args
    for dd in D_PNG.values():
        os.makedirs(dd, exist_ok=True)
    data = {}
    stats = []
    for id_ in choix:
        for t in ('Plastron', 'Jambieres'):
            mats = generer(id_, t)
            n, tri = ecrire_lua(id_, t, mats)
            stats.append((t + id_, n, tri))
            data[(id_, t)] = (list(P), mats)
    # aperçus individuels (mannequin gris)
    for id_ in choix:
        ps, mats = data[(id_, 'Plastron')]
        vider()
        mannequin(['Tete', 'Torse', 'Bassin', 'BrasD', 'BrasG'])
        construire_blender(decaler(ps, V(0, Y_PLASTRON, 0)), mats)
        vue(sc, co, os.path.join(D_PNG['Plastron'], 'Plastron%s.png' % id_), V(0, 3.15, 0), 7.2)
        ps, mats = data[(id_, 'Jambieres')]
        vider()
        mannequin(['Bassin', 'JambeD', 'JambeG'])
        construire_blender(decaler(ps, V(0, Y_JAMBES, 0)), mats)
        vue(sc, co, os.path.join(D_PNG['Jambieres'], 'Jambieres%s.png' % id_), V(0, 1.15, 0), 5.6)
        # set complet : casque + plastron + jambières + épée
        vider()
        construire_set(id_, data, V(0, 0, 0))
        vue(sc, co, os.path.join(D_PNG['Set'], 'Set%s.png' % id_), V(0.5, 2.7, 0), 12.5, res=(600, 700))
    for s in stats:
        print('STAT', *s)
    if sans_planches or len(choix) < len(LISTE):
        return
    # planches de comparaison (ordre de rareté)
    def el_plastron(id_):
        def f(off):
            ps, mats = data[(id_, 'Plastron')]
            mannequin(['Tete', 'Torse', 'BrasD', 'BrasG'], off)
            construire_blender(decaler(ps, off + V(0, Y_PLASTRON, 0)), mats, prefixe=id_)
        return f

    def el_jambes(id_):
        def f(off):
            ps, mats = data[(id_, 'Jambieres')]
            mannequin(['Bassin', 'JambeD', 'JambeG'], off)
            construire_blender(decaler(ps, off + V(0, Y_JAMBES, 0)), mats, prefixe=id_)
        return f

    def el_set(id_):
        return lambda off: construire_set(id_, data, off + V(-0.9, 0, 0), prefixe=id_)
    planche(sc, co, soleils, os.path.join(D_PNG['Plastron'], '_comparaison.png'),
            [(NOMS[i], el_plastron(i)) for i in LISTE], 4, 5.0, 4.4, (2000, 1320), 3.3)
    planche(sc, co, soleils, os.path.join(D_PNG['Jambieres'], '_comparaison.png'),
            [(NOMS[i], el_jambes(i)) for i in LISTE], 4, 3.4, 3.4, (1600, 1200), 1.1)
    planche(sc, co, soleils, os.path.join(D_PNG['Set'], '_sets.png'),
            [(NOMS[i], el_set(i)) for i in LISTE], 4, 6.6, 7.6, (2400, 2073), 2.7)


def construire_set(id_, data, off, prefixe=''):
    mannequin(list(MANNEQUIN), off)
    ps, mats = data[(id_, 'Plastron')]
    construire_blender(decaler(ps, off + V(0, Y_PLASTRON, 0)), mats, prefixe=prefixe + 'P')
    ps, mats = data[(id_, 'Jambieres')]
    construire_blender(decaler(ps, off + V(0, Y_JAMBES, 0)), mats, prefixe=prefixe + 'J')
    try:
        ps, mats = lire_casque(id_)
        construire_blender(decaler(ps, off + V(0, Y_TETE, 0)), mats, prefixe=prefixe + 'C')
    except OSError as e:
        print('casque absent', id_, e)
    try:
        ps, mats = lire_epee(id_)
        # épée plantée à droite du personnage, lame vers le haut, plat face à la caméra
        Rr = rot('Y', -25)
        ps = [dict(p, pos=Rr @ p['pos'] + off + V(2.9, 1.0, -0.2), R=Rr @ p['R']) for p in ps]
        construire_blender(ps, mats, prefixe=prefixe + 'E')
    except OSError as e:
        print('épée absente', id_, e)


main()
