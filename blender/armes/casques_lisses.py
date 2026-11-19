"""Casques lisses (CasqueCharbon, CasqueBronze, CasqueFer) : formes arrondies + CSG, plus de voxel.
Une seule description (primitives Roblox + opérations CSG) sert :
  - à générer les modules Luau src/partage/ArmuresVoxels/Casque*.lua (Format = "Lisse"),
    construits en jeu par ArmuresVoxels/init.lua (GeometryService:UnionAsync / SubtractAsync, cache + Clone) ;
  - au rendu Blender fidèle previews/armes/Casques2.png (mêmes primitives, booléens exacts) sur une tête R15 grise.

blender -b --factory-startup --python casques_lisses.py   (ou run_arme.ps1 casques_lisses.py)

Repère Roblox : origine = centre de la tête R15 (1.2 stud), devant = -Z, haut = +Y, droite = +X.
Primitives : Bloc (Part), Boule (Part Ball, uniforme), Cylindre (Part Cylinder, axe = X local),
             Ellipsoide (Part + SpecialMesh Sphere, hors CSG uniquement).
Pièce CSG : Base + Plus (unions) - Moins (soustractions) ; Secours = pièces simples si le CSG échoue.
La coque (capsule creuse : boule + cylindre) enveloppe dessus / côtés / arrière ; seul le visage reste ouvert.
"""
import math, os, sys

ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.abspath(os.path.join(ICI, '..', '..'))
DOSSIER_LUA = os.path.join(JEU, 'src', 'partage', 'ArmuresVoxels')
DOSSIER_PNG = os.path.join(JEU, 'previews', 'armes')

# ------------------------------------------------------------------ maths (repère Roblox)
I3 = ((1, 0, 0), (0, 1, 0), (0, 0, 1))


def mul(a, b):
    return tuple(tuple(sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)) for i in range(3))


def rx(d):
    a = math.radians(d); c, s = math.cos(a), math.sin(a)
    return ((1, 0, 0), (0, c, -s), (0, s, c))


def ry(d):
    a = math.radians(d); c, s = math.cos(a), math.sin(a)
    return ((c, 0, s), (0, 1, 0), (-s, 0, c))


def rz(d):
    a = math.radians(d); c, s = math.cos(a), math.sin(a)
    return ((c, -s, 0), (s, c, 0), (0, 0, 1))


def add(a, b): return tuple(x + y for x, y in zip(a, b))
def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def sc(a, k): return tuple(x * k for x in a)
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def norm(a):
    l = math.sqrt(dot(a, a)); return tuple(x / l for x in a)


def repere(x=None, y=None, z=None):
    """Matrice dont les colonnes sont les axes locaux X, Y, Z (deux axes donnés suffisent)."""
    if x is not None and y is not None:
        x = norm(x); y = norm(sub(y, sc(x, dot(y, x)))); z = cross(x, y)
    elif y is not None and z is not None:
        y = norm(y); z = norm(sub(z, sc(y, dot(z, y)))); x = cross(y, z)
    elif x is not None and z is not None:
        x = norm(x); z = norm(sub(z, sc(x, dot(z, x)))); y = cross(z, x)
    elif x is not None:
        x = norm(x); aide = (0, 1, 0) if abs(x[1]) < 0.9 else (0, 0, 1)
        y = norm(sub(aide, sc(x, dot(aide, x)))); z = cross(x, y)
    elif y is not None:
        y = norm(y); aide = (0, 0, -1) if abs(y[2]) < 0.9 else (1, 0, 0)
        z = norm(sub(aide, sc(y, dot(aide, y)))); x = cross(y, z)
    return tuple(tuple((x, y, z)[j][i] for j in range(3)) for i in range(3))


AXE_Y = rz(90)   # cylindre debout (axe X local -> Y)
AXE_Z = ry(90)   # cylindre couché vers l'avant (axe X local -> -Z)


def prim(forme, taille, pos, rot=I3):
    return dict(forme=forme, taille=tuple(taille), pos=tuple(pos), rot=rot)


def boule(d, pos): return prim('Boule', (d, d, d), pos)
def bloc(t, pos, rot=I3): return prim('Bloc', t, pos, rot)
def cyl(long, d, pos, rot=I3): return prim('Cylindre', (long, d, d), pos, rot)
def ellip(t, pos, rot=I3): return prim('Ellipsoide', t, pos, rot)


def piece(nom, cle, p):
    p = dict(p); p['nom'] = nom; p['cle'] = cle; return p


def csg(nom, cle, base, plus=(), moins=(), secours=()):
    return dict(nom=nom, cle=cle, forme='CSG', base=base, plus=list(plus), moins=list(moins), secours=list(secours))


# ------------------------------------------------------------------ briques communes
def capsule(R, c_y, y_bas):
    """Boule (centre (0, c_y, 0)) + cylindre debout jusqu'à y_bas : volume plein arrondi de la coque."""
    h = c_y - y_bas
    return boule(2 * R, (0, c_y, 0)), cyl(h, 2 * R * 0.999, (0, c_y - h / 2, 0), AXE_Y)


def creux(r, c_y):
    """Volume intérieur à retirer (ouvert en bas)."""
    return [boule(2 * r, (0, c_y, 0)), cyl(c_y + 2.5, 2 * r, (0, (c_y - 2.5) / 2, 0), AXE_Y)]


def demi_espace(point, n, cote=6):
    """Bloc géant qui retire tout ce qui est au-delà du plan (point, normale n)."""
    n = norm(n)
    return bloc((cote, cote, cote), add(point, sc(n, cote / 2)), repere(y=n))


def dir_surf(lon, lat):
    """Direction (lon 0 = devant -Z, 90 = droite +X ; lat 90 = haut)."""
    lo, la = math.radians(lon), math.radians(lat)
    return (math.sin(lo) * math.cos(la), math.sin(la), -math.cos(lo) * math.cos(la))


def surf(lon, lat, R, c_y):
    """Point de la capsule : sphère au-dessus du centre, cylindre en dessous (lat < 0 -> y = c + R sin lat)."""
    lo = math.radians(lon)
    if lat >= 0:
        return add((0, c_y, 0), sc(dir_surf(lon, lat), R))
    return (R * math.sin(lo), c_y + R * math.sin(math.radians(lat)), -R * math.cos(lo))


def normale_surf(p, c_y):
    if p[1] >= c_y:
        return norm(sub(p, (0, c_y, 0)))
    return norm((p[0], 0, p[2]))


def rainures(lignes, R, c_y, larg=0.045, prof=0.10):
    """Lignes brisées (lon, lat) -> blocs fins tangents à la surface (à soustraire)."""
    out = []
    for ligne in lignes:
        pts = [surf(lo, la, R, c_y) for lo, la in ligne]
        for a, b in zip(pts, pts[1:]):
            m = sc(add(a, b), 0.5)
            n = normale_surf(m, c_y)
            centre = add((0, c_y, 0), sc(n, R)) if m[1] >= c_y else (n[0] * R, m[1], n[2] * R)
            t = sub(b, a)
            out.append(bloc((larg, 2 * prof, math.sqrt(dot(t, t)) + larg), centre, repere(y=n, z=t)))
    return out


def sur_surface(lon, lat, R, c_y, enfonce=0.0):
    p = surf(lon, lat, R, c_y)
    n = normale_surf(p, c_y)
    return sub(p, sc(n, enfonce)), n


def secours_coque(cle, c_y, R, y_bas):
    """Sans CSG : dôme + nuque + couvre-joues en ellipsoïdes (couvre le crâne, laisse le visage)."""
    return [
        piece('Coque', cle, ellip((2 * R + 0.04, 1.3, 2 * R + 0.1), (0, c_y + 0.44, 0.15))),
        piece('Coque', cle, ellip((2 * R, 1.5, 1.2), (0, y_bas + 0.75, 0.38))),
        piece('Coque', cle, ellip((0.32, 1.1, 1.25), (0.66, y_bas + 0.62, -0.12))),
        piece('Coque', cle, ellip((0.32, 1.1, 1.25), (-0.66, y_bas + 0.62, -0.12))),
    ]


# ------------------------------------------------------------------ briques de design (casques 3, 5..10)
def arche(m=0.0, r=0.40, yc=-0.05):
    """Ouverture en arche (visage), m = marge (couche intérieure un peu plus large)."""
    return [cyl(1.1, 2 * (r + m), (0, yc, -0.75), AXE_Z), bloc((2 * (r + m), 1.45, 1.1), (0, yc - 0.725, -0.75))]


def ouv_T(m=0.0):
    return [bloc((0.72 + 2 * m, 0.29 + 2 * m, 1.05), (0, 0.125, -0.775)),
            cyl(1.05, 0.29 + 2 * m, (0.36, 0.125, -0.775), AXE_Z), cyl(1.05, 0.29 + 2 * m, (-0.36, 0.125, -0.775), AXE_Z),
            bloc((0.46 + 2 * m, 1.5, 1.05), (0, -0.75, -0.775))]


def ouv_rect(m=0.0):
    return [bloc((0.60 + 2 * m, 1.77, 1.05), (0, -0.615 + m / 2, -0.775)),
            bloc((0.80 + 2 * m, 1.67, 1.05), (0, -0.665 + m / 2, -0.775)),
            cyl(1.05, 0.20 + 2 * m, (0.30, 0.17, -0.775), AXE_Z), cyl(1.05, 0.20 + 2 * m, (-0.30, 0.17, -0.775), AXE_Z)]


def coque(nom, cle, R, C, BAS, RI, ouv, plus=(), moins=()):
    b, c = capsule(R, C, BAS)
    return csg(nom, cle, b, [c] + list(plus), creux(RI, C) + list(ouv) + list(moins), secours_coque(cle, C, R, BAS))


def couche(nom, cle, R, C, BAS, RI, ouv, moins=()):
    """Sous-couche (braise / or) révélée par les rainures de la coque extérieure."""
    b, c = capsule(R, C, BAS)
    return csg(nom, cle, b, [c], creux(RI, C) + list(ouv) + list(moins))


def anneau(nom, cle, r_out, r_in, y, h, moins=(), plus=()):
    return csg(nom, cle, cyl(h, 2 * r_out, (0, y, 0), AXE_Y), list(plus), [cyl(h + 0.4, 2 * r_in, (0, y, 0), AXE_Y)] + list(moins))


def alveoles(r, y, d=0.06, pas=22.5, sauf=(0,)):
    out = []
    k = 0.0
    while k < 360 - 1e-6:
        if all(abs(k - s) > 1e-6 for s in sauf):
            a = math.radians(k)
            out.append(boule(d, (r * math.sin(a), y, -r * math.cos(a))))
        k += pas
    return out


def cimier(nom, cle, O, r_out, r_in, larg, f=40, d=-130, secours=()):
    """Arc vertical (plan YZ) gardé entre l'angle f (vers l'avant) et d (vers l'arrière, négatif)."""
    nf = (0, -math.sin(math.radians(f)), -math.cos(math.radians(f)))
    nd = (0, math.sin(math.radians(d)), math.cos(math.radians(d)))
    return csg(nom, cle, cyl(larg, 2 * r_out, O), moins=[cyl(larg + 0.3, 2 * r_in, O), demi_espace(O, nf), demi_espace(O, nd)],
               secours=secours)


def point_anneau(lon, r, y):
    a = math.radians(lon)
    return (r * math.sin(a), y, -r * math.cos(a)), (math.sin(a), 0, -math.cos(a))


def gemme(nom, cle, p, n, d=0.13, cle_s='orF'):
    """Gemme Neon (boule) sertie dans une bague (cylindre orienté selon la normale n)."""
    return [piece('Serti', cle_s, cyl(0.07, d * 1.5, add(p, sc(n, 0.005)), repere(x=n))),
            piece(nom, cle, boule(d, add(p, sc(n, d * 0.28))))]


def corne(base, a0, a1, segs, nom='Corne'):
    """Ellipsoïdes empilés de base vers a1 (courbure progressive). segs = [(taille, distance, clé)]."""
    out = []
    pos = base; prec = 0
    n = len(segs)
    for i, (t, d, cle) in enumerate(segs):
        k = i / max(1, n - 1)
        ax = norm(add(sc(a0, 1 - k), sc(a1, k)))
        pos = add(pos, sc(ax, d - prec)); prec = d
        out.append(piece(nom, cle, ellip(t, pos, repere(y=ax, z=(0, 0, 1) if abs(ax[2]) < 0.9 else (1, 0, 0)))))
    return out


def sym_lignes(lignes):
    return lignes + [[(-lo, la) for lo, la in l] for l in lignes]


# ================================================================== CasqueCharbon
def casque_charbon():
    C = 0.08; R = 0.85; RN = 0.828; RI = 0.68; BAS = -0.66
    # ouverture en arche (cylindre vers l'avant + bloc dessous)
    def arche(m):
        return [cyl(1.1, 2 * (0.40 + m), (0, -0.05, -0.75), AXE_Z),
                bloc((0.80 + 2 * m, 1.45, 1.1), (0, -0.775, -0.75))]
    facettes = [(0, 90), (40, 56), (-40, 56), (110, 50), (-110, 50), (180, 55), (150, 26), (-150, 26),
                (75, 24), (-75, 24), (0, 40)]
    D = 0.815
    coupes = [demi_espace(add((0, C, 0), sc(dir_surf(lo, la), D)), dir_surf(lo, la)) for lo, la in facettes]
    # la couche de braise suit les facettes un peu en retrait (veines visibles même de biais)
    coupes_n = [demi_espace(add((0, C, 0), sc(dir_surf(lo, la), D - 0.022)), dir_surf(lo, la)) for lo, la in facettes]
    veines = rainures([
        [(8, 47), (22, 58), (16, 72), (36, 83)],
        [(-8, 45), (-21, 55), (-34, 63)],
        [(95, 62), (87, 41), (100, 22), (91, 5), (104, -15), (95, -40)],
        [(-92, 60), (-101, 38), (-88, 18), (-99, -5), (-90, -32)],
        [(150, 76), (166, 52), (154, 30), (170, 8), (159, -20), (171, -42)],
        [(-145, 64), (-161, 40), (-149, 15), (-166, -16)],
        [(118, 80), (168, 86), (-128, 78)],
        [(50, 14), (59, -6), (49, -30)],
        [(-52, 10), (-44, -12), (-56, -33)],
        [(128, 18), (136, -8), (126, -36)],
        [(-122, 22), (-131, -2), (-120, -34)],
    ], R, C, larg=0.055)
    b, c = capsule(R, C, BAS)
    roche = csg('Roche', 'roche', b, [c], creux(RI, C) + arche(0) + coupes + veines,
                secours_coque('roche', C, R, BAS))
    bn, cn = capsule(RN, C, BAS + 0.02)
    braise = csg('Braise', 'braise', bn, [cn], creux(RI + 0.01, C) + arche(0.025) + coupes_n)
    pieces = [roche, braise]
    # coeur de braise serti sur la facette du front
    n = dir_surf(0, 40); p = add((0, C, 0), sc(n, D))
    pieces.append(piece('Serti', 'socle', cyl(0.10, 0.27, add(p, sc(n, 0.02)), repere(x=n))))
    pieces.append(piece('Coeur', 'braise', boule(0.15, add(p, sc(n, 0.07)))))
    # deux petites cornes rocheuses (ellipsoïdes empilés, pointe de braise)
    for s in (1, -1):
        n = dir_surf(68 * s, 48)
        base = add((0, C, 0), sc(n, R - 0.06))
        a0 = norm(add(sc(n, 0.6), (0.0, 0.9, 0.15)))
        a1 = norm(add(a0, (0.35 * s, 0.1, 0.25)))
        segs = [((0.27, 0.30, 0.27), 0.02, 'rocheC'), ((0.20, 0.25, 0.20), 0.17, 'rocheC'),
                ((0.13, 0.19, 0.13), 0.31, 'rocheC'), ((0.065, 0.11, 0.065), 0.42, 'braise')]
        pos = base
        prec = 0
        for i, (t, d, cle) in enumerate(segs):
            ax = norm(add(sc(a0, 1 - i / 3), sc(a1, i / 3)))
            pos = add(pos, sc(ax, d - prec)); prec = d
            pieces.append(piece('Corne', cle, ellip(t, pos, repere(y=ax, z=(0, 0, 1)))))
    return dict(id='CasqueCharbon', nom='Casque de charbon', pieces=pieces,
                lumieres=[dict(piece='Coeur', type='Point', couleur=(255, 120, 40), portee=7, luminosite=1.3)])


# ================================================================== CasqueBronze
def casque_bronze():
    C = 0.08; R = 0.82; RI = 0.70; BAS = -0.70
    t_visage = [bloc((0.72, 0.29, 1.05), (0, 0.125, -0.775)),
                cyl(1.05, 0.29, (0.36, 0.125, -0.775), AXE_Z), cyl(1.05, 0.29, (-0.36, 0.125, -0.775), AXE_Z),
                bloc((0.46, 1.5, 1.05), (0, -0.75, -0.775))]
    rivets = []
    for s in (1, -1):
        for x, y in ((0.50, -0.22), (0.43, -0.50)):
            z = -math.sqrt(R * R - x * x)
            rivets.append(boule(0.09, (s * x, y, z)))
    b, c = capsule(R, C, BAS)
    coque = csg('Coque', 'bronze', b, [c] + rivets, creux(RI, C) + t_visage, secours_coque('bronze', C, R, BAS))
    # bandeau gravé (anneau + alvéoles)
    YB = 0.345
    alveoles = []
    for k in range(16):
        lon = k * 22.5
        if lon in (0.0,):
            continue
        a = math.radians(lon)
        alveoles.append(boule(0.06, (0.85 * math.sin(a), YB, -0.85 * math.cos(a))))
    bandeau = csg('Bandeau', 'bronzeF', cyl(0.13, 1.69, (0, YB, 0), AXE_Y),
                  moins=[cyl(0.5, 1.48, (0, YB, 0), AXE_Y)] + alveoles)
    bord = csg('Bord', 'bronzeF', cyl(0.08, 1.72, (0, BAS + 0.04, 0), AXE_Y),
               moins=[cyl(0.5, 1.48, (0, BAS, 0), AXE_Y), t_visage[3]])
    # cimier : arc de crin rouge sur support bronze
    O = (0, 0.10, 0.08)
    def coupes_cimier():
        f, d = 40, -130
        nf = (0, -math.sin(math.radians(f)), -math.cos(math.radians(f)))
        nd = (0, math.sin(math.radians(d)), math.cos(math.radians(d)))
        return [demi_espace(O, nf), demi_espace(O, nd)]
    crin = csg('Crin', 'crin', cyl(0.20, 2.24, O), moins=[cyl(0.4, 1.60, O)] + coupes_cimier(),
               secours=[piece('Crin', 'crin', ellip((0.2, 0.6, 1.5), (0, 0.85, 0.25)))])
    support = csg('Support', 'bronzeF', cyl(0.27, 1.82, O), moins=[cyl(0.5, 1.58, O)] + coupes_cimier())
    pieces = [coque, bandeau, bord, crin, support,
              piece('Nasal', 'bronze', bloc((0.10, 0.31, 0.09), (0, 0.13, -0.77)))]
    # patine verte (lentilles plates à fleur de surface)
    for lon, lat, t in ((118, 22, (0.26, 0.05, 0.18)), (-100, -25, (0.22, 0.05, 0.30)), (158, 48, (0.20, 0.05, 0.16)),
                        (-38, 62, (0.17, 0.05, 0.13)), (62, -42, (0.18, 0.05, 0.24)), (-150, 10, (0.15, 0.05, 0.12))):
        p, n = sur_surface(lon, lat, R, C, 0.008)
        pieces.append(piece('Patine', 'patine', ellip(t, p, repere(y=n, z=(0.3, 1, 0.2)))))
    return dict(id='CasqueBronze', nom='Casque de bronze', pieces=pieces, lumieres=[])


# ================================================================== CasqueFer
def casque_fer():
    C = 0.08; R = 0.81; RI = 0.69; BAS = -0.68
    ouverture = [bloc((0.60, 1.77, 1.05), (0, -0.615, -0.775)), bloc((0.80, 1.67, 1.05), (0, -0.665, -0.775)),
                 cyl(1.05, 0.20, (0.30, 0.17, -0.775), AXE_Z), cyl(1.05, 0.20, (-0.30, 0.17, -0.775), AXE_Z)]
    b, c = capsule(R, C, BAS)
    coque = csg('Coque', 'acier', b, [c], creux(RI, C) + ouverture, secours_coque('acier', C, R, BAS))
    arete = csg('Arete', 'acierF', cyl(0.075, 1.72, (0, C, 0)),
                moins=[cyl(0.3, 1.40, (0, C, 0)), bloc((1, 2, 1.5), (0, -0.70, -1.05)), bloc((1, 1, 3), (0, -1.12, 0))])
    YV = 0.285
    visiere = csg('Visiere', 'acier', cyl(0.06, 1.96, (0, YV, 0), AXE_Y),
                  moins=[cyl(0.3, 1.40, (0, YV, 0), AXE_Y), bloc((3, 1, 3), (0, YV, 1.05))])
    camail1 = csg('Camail', 'maille', cyl(0.22, 1.80, (0, -0.56, 0), AXE_Y),
                  moins=[cyl(0.6, 1.48, (0, -0.56, 0), AXE_Y), bloc((3, 1, 3), (0, -0.56, -1.22))])
    camail2 = csg('Camail', 'maille', cyl(0.18, 1.92, (0, -0.74, 0.02), AXE_Y),
                  moins=[cyl(0.6, 1.58, (0, -0.74, 0.02), AXE_Y), bloc((3, 1, 3), (0, -0.74, -1.16))])
    pieces = [coque, arete, visiere, camail1, camail2,
              piece('Nasal', 'acierF', bloc((0.12, 0.44, 0.07), (0, 0.07, -0.79))),
              piece('Nasal', 'acierF', boule(0.15, (0, -0.15, -0.79)))]
    for s in (1, -1):
        for x, y in ((0.56, -0.28), (0.50, -0.52), (0.62, 0.02)):
            z = -math.sqrt(R * R - x * x)
            pieces.append(piece('Rivet', 'acierC', boule(0.085, (s * x, y, z))))
    # lampe de mineur (front gauche du perso = -X)
    p, n = sur_surface(-24, 34, R, C)
    av = norm((0, -0.12, -1))
    rot = repere(x=av, y=(0, 1, 0))
    corps = add(p, add(sc(n, 0.03), sc(av, 0.06)))
    pieces += [
        piece('Support', 'laiton', bloc((0.10, 0.16, 0.16), add(p, sc(n, 0.02)), repere(y=n, z=(0, 0, 1)))),
        piece('Lampe', 'laiton', cyl(0.20, 0.25, corps, rot)),
        piece('Lampe', 'acierF', cyl(0.05, 0.30, add(corps, sc(av, 0.11)), rot)),
        piece('Lentille', 'lampe', cyl(0.03, 0.20, add(corps, sc(av, 0.135)), rot)),
    ]
    return dict(id='CasqueFer', nom='Casque de fer', pieces=pieces, lumieres=[
        dict(piece='Lentille', type='Point', couleur=(255, 220, 150), portee=8, luminosite=1.2),
        dict(piece='Lentille', type='Spot', couleur=(255, 226, 170), portee=18, luminosite=2, angle=55, face='Right'),
    ])


# ================================================================== 3 CasqueCharbonBronze
def casque_charbon_bronze():
    C = 0.08; R = 0.80; RI = 0.68; BAS = -0.68; RK = 0.86; YC = 0.36
    rivets = []
    for s in (1, -1):
        for x, y in ((0.50, -0.22), (0.43, -0.50)):
            rivets.append(boule(0.09, (s * x, y, -math.sqrt(R * R - x * x))))
    veines = rainures(sym_lignes([
        [(14, 49), (30, 61), (22, 76)], [(88, 46), (101, 60), (86, 76)], [(158, 46), (170, 62), (156, 79)],
        [(128, 42), (118, 56)],
    ]), RK, C, larg=0.05)
    bas_cap = demi_espace((0, YC, 0), (0, -1, 0))
    pieces = [
        coque('Coque', 'bronze', R, C, BAS, RI, arche(), plus=rivets),
        csg('Roche', 'roche', boule(2 * RK, (0, C, 0)), moins=[boule(1.40, (0, C, 0)), bas_cap] + veines),
        csg('Braise', 'braise', boule(2 * (RK - 0.022), (0, C, 0)),
            moins=[boule(1.40, (0, C, 0)), demi_espace((0, YC + 0.02, 0), (0, -1, 0))]),
        anneau('Bandeau', 'bronzeF', 0.845, 0.72, YC + 0.01, 0.11, moins=alveoles(0.85, YC + 0.01)),
    ]
    n = dir_surf(0, 40); p = add((0, C, 0), sc(n, RK))
    pieces.append(piece('Serti', 'socle', cyl(0.10, 0.27, add(p, sc(n, 0.0)), repere(x=n))))
    pieces.append(piece('Coeur', 'braise', boule(0.15, add(p, sc(n, 0.05)))))
    for lon, lat in ((0, 68), (0, 90), (180, 64)):
        n = dir_surf(lon, lat)
        pieces += corne(add((0, C, 0), sc(n, RK - 0.05)), n, n,
                        [((0.20, 0.26, 0.20), 0, 'rocheC'), ((0.12, 0.18, 0.12), 0.14, 'rocheC'),
                         ((0.06, 0.10, 0.06), 0.25, 'braise')], 'Pointe')
    return dict(id='CasqueCharbonBronze', nom='Casque de charbon et bronze', rang=3, pieces=pieces,
                lumieres=[dict(piece='Coeur', type='Point', couleur=(255, 120, 40), portee=7, luminosite=1.3)])


# ================================================================== 5 CasqueCharbonFer
def casque_charbon_fer():
    C = 0.08; R = 0.83; RN = 0.81; RI = 0.69; BAS = -0.70
    veines = rainures(sym_lignes([
        [(70, 42), (82, 20), (73, 0), (86, -26)], [(140, 52), (155, 26), (144, 0), (158, -32)],
        [(112, 60), (118, 38)],
    ]) + [[(180, 72), (170, 48), (180, 26)]], R, C, larg=0.045)
    pieces = [
        coque('Coque', 'acierN', R, C, BAS, RI, ouv_rect(), moins=veines),
        couche('Braise', 'braise', RN, C, BAS + 0.02, RI + 0.01, ouv_rect(0.025)),
        csg('Arete', 'braise', cyl(0.05, 1.72, (0, C, 0)),
            moins=[cyl(0.3, 1.40, (0, C, 0)), bloc((1, 2, 1.5), (0, -0.70, -1.05)), bloc((1, 1, 3), (0, -1.12, 0))]),
        csg('Visiere', 'acierN', cyl(0.07, 2.0, (0, 0.285, 0), AXE_Y),
            moins=[cyl(0.3, 1.40, (0, 0.285, 0), AXE_Y), bloc((3, 1, 3), (0, 0.285, 1.15))]),
        piece('Nasal', 'acierF', bloc((0.13, 0.46, 0.08), (0, 0.06, -0.80))),
        piece('Nasal', 'acierF', boule(0.16, (0, -0.17, -0.80))),
    ]
    p, n = sur_surface(0, 31, R, C)
    pieces += gemme('Gemme', 'braise', p, n, 0.14, 'acierF')
    for s in (1, -1):
        p, n = sur_surface(80 * s, 30, R, C)
        a0 = norm((s * 1.0, 0.35, 0.05)); a1 = norm((s * 0.35, 1.0, -0.45))
        pieces += corne(sub(p, sc(n, 0.05)), a0, a1, [
            ((0.30, 0.50, 0.30), 0, 'acierN'), ((0.25, 0.46, 0.25), 0.20, 'acierN'), ((0.20, 0.40, 0.20), 0.38, 'acierF'),
            ((0.15, 0.34, 0.15), 0.54, 'acierF'), ((0.10, 0.26, 0.10), 0.68, 'acierC'), ((0.05, 0.16, 0.05), 0.80, 'braise')])
        for x, y in ((0.56, -0.30), (0.50, -0.54)):
            pieces.append(piece('Rivet', 'acierC', boule(0.085, (s * x, y, -math.sqrt(R * R - x * x)))))
    return dict(id='CasqueCharbonFer', nom='Casque de guerre de charbon et fer', rang=5, pieces=pieces,
                lumieres=[dict(piece='Gemme', type='Point', couleur=(255, 110, 40), portee=7, luminosite=1.4)])


# ================================================================== 6 CasqueBronzeFer
def casque_bronze_fer():
    C = 0.08; R = 0.82; RI = 0.70; BAS = -0.70
    O = (0, 0.10, 0.06)
    pieces = [
        coque('Coque', 'acier', R, C, BAS, RI, ouv_T()),
        anneau('Bandeau', 'bronze', 0.85, 0.74, 0.345, 0.13, moins=alveoles(0.855, 0.345)),
        anneau('Bord', 'bronze', 0.86, 0.74, BAS + 0.04, 0.08, moins=[ouv_T()[3]]),
        cimier('Crin', 'crinBleu', O, 1.18, 0.80, 0.22, 35, -140,
               secours=[piece('Crin', 'crinBleu', ellip((0.22, 0.6, 1.5), (0, 0.85, 0.25)))]),
        cimier('Support', 'bronzeF', O, 0.93, 0.78, 0.30, 35, -140),
        piece('Nasal', 'bronze', bloc((0.10, 0.31, 0.09), (0, 0.13, -0.77))),
    ]
    for s in (1, -1):
        p, n = sur_surface(58 * s, -22, R, C, 0.012)
        pieces.append(piece('Joue', 'bronze', ellip((0.34, 0.05, 0.50), p, repere(y=n, z=(0, 1, 0)))))
        pieces.append(piece('Rivet', 'bronzeC', boule(0.08, add(p, sc(n, 0.03)))))
        pieces.append(piece('Oreille', 'bronze', cyl(0.07, 0.36, (s * 0.82, -0.02, 0.08))))
        pieces.append(piece('Gemme', 'saphir', boule(0.12, (s * 0.86, -0.02, 0.08))))
    return dict(id='CasqueBronzeFer', nom='Casque de bronze et fer', rang=6, pieces=pieces,
                lumieres=[dict(piece='Gemme', type='Point', couleur=(110, 150, 255), portee=5, luminosite=0.8)])


# ================================================================== 7 CasqueOr
def casque_or():
    C = 0.08; R = 0.82; RI = 0.70; BAS = -0.68; YB = 0.33
    pieces = [
        coque('Coque', 'or', R, C, BAS, RI, arche(r=0.41)),
        anneau('Bandeau', 'orF', 0.85, 0.74, YB, 0.12, moins=alveoles(0.855, YB, sauf=(0, 35, 325))),
        anneau('Bord', 'orF', 0.85, 0.72, BAS + 0.04, 0.08, moins=[arche(r=0.41)[1]]),
    ]
    # couronne solaire : rayons dressés sur le bandeau, en éventail au-dessus du front
    for lon, L, w in ((-60, 0.42, 0.11), (-40, 0.52, 0.12), (-20, 0.62, 0.13), (0, 0.76, 0.15),
                      (20, 0.62, 0.13), (40, 0.52, 0.12), (60, 0.42, 0.11)):
        p, n = point_anneau(lon, 0.84, YB + 0.04)
        dr = norm(add(sc(n, 0.30), (0, 1, 0)))
        pieces.append(piece('Rayon', 'orC', ellip((w, L, w * 0.45), add(p, sc(dr, L / 2 - 0.05)), repere(y=dr, z=n))))
    p, n = point_anneau(0, 0.85, YB)
    pieces += gemme('Gemme', 'rubis', p, n, 0.16, 'orC')
    for lon in (35, -35):
        p, n = point_anneau(lon, 0.85, YB)
        pieces += gemme('Gemme', 'saphir', p, n, 0.11, 'orC')
    return dict(id='CasqueOr', nom="Casque d'or solaire", rang=7, pieces=pieces,
                lumieres=[dict(piece='Gemme', type='Point', couleur=(255, 205, 100), portee=8, luminosite=1.3)])


# ================================================================== 8 CasqueCharbonOr
def casque_charbon_or():
    C = 0.08; R = 0.84; RN = 0.82; RI = 0.70; BAS = -0.68
    incrust = rainures(sym_lignes([
        [(58, 18), (74, 40), (96, 55), (122, 60), (150, 56)],
        [(70, -32), (80, -4), (102, 14), (132, 20), (162, 14)],
        [(150, -36), (166, -12), (180, -2)],
    ]), R, C, larg=0.07)
    pieces = [
        coque('Coque', 'obsidienne', R, C, BAS, RI, arche(), moins=incrust),
        couche('Or', 'or', RN, C, BAS + 0.02, RI + 0.01, arche(0.025)),
        anneau('Bord', 'or', 0.87, 0.74, BAS + 0.04, 0.08, moins=[arche()[1]]),
    ]
    p, n = sur_surface(0, 38, R, C)
    pieces += gemme('Gemme', 'braise', p, n, 0.18, 'or')
    for lon, lat, t in ((-22, 52, (0.10, 0.32, 0.08)), (-11, 58, (0.12, 0.42, 0.09)), (0, 62, (0.15, 0.54, 0.10)),
                        (11, 58, (0.12, 0.42, 0.09)), (22, 52, (0.10, 0.32, 0.08))):
        p, n = sur_surface(lon, lat, R, C)
        dr = norm(add(sc(n, 0.5), (0, 1, 0)))
        pieces.append(piece('Flamme' if lon == 0 else 'Langue', 'flamme', ellip(t, add(p, sc(dr, t[1] * 0.32)), repere(y=dr, z=n))))
    for s in (1, -1):
        p, n = sur_surface(62 * s, 44, R, C)
        a0 = norm(add(n, (0, 0.8, 0))); a1 = norm((s * 0.45, 1.0, 0.35))
        pieces += corne(sub(p, sc(n, 0.05)), a0, a1, [
            ((0.28, 0.46, 0.28), 0, 'or'), ((0.23, 0.42, 0.23), 0.18, 'or'), ((0.18, 0.36, 0.18), 0.34, 'or'),
            ((0.13, 0.30, 0.13), 0.48, 'orC'), ((0.09, 0.24, 0.09), 0.60, 'orC'), ((0.05, 0.16, 0.05), 0.71, 'flamme')])
    return dict(id='CasqueCharbonOr', nom="Casque d'obsidienne et d'or", rang=8, pieces=pieces,
                lumieres=[dict(piece='Gemme', type='Point', couleur=(255, 150, 50), portee=8, luminosite=1.5)],
                particules=[dict(piece='Flamme', couleur=(255, 170, 60), taux=6, vie=0.9, taille=0.07, vitesse=0.9)])


# ================================================================== 9 CasqueBronzeOr
def casque_bronze_or():
    C = 0.08; R = 0.82; RI = 0.70; BAS = -0.70; YB = 0.33
    O = (0, 0.10, 0.06)
    pieces = [
        coque('Coque', 'orRose', R, C, BAS, RI, arche(r=0.42)),
        anneau('Bandeau', 'or', 0.85, 0.74, YB, 0.12, moins=alveoles(0.855, YB, sauf=(0, 30, 330))),
        anneau('Bord', 'or', 0.86, 0.72, BAS + 0.04, 0.08, moins=[arche(r=0.42)[1]]),
        cimier('Support', 'or', O, 0.98, 0.78, 0.12, 28, -150),
        cimier('Plumet', 'plume', O, 1.14, 0.90, 0.17, 22, -125,
               secours=[piece('Plumet', 'plume', ellip((0.17, 0.5, 1.3), (0, 0.9, 0.25)))]),
    ]
    p, n = point_anneau(0, 0.85, YB)
    pieces += gemme('Gemme', 'emeraude', p, n, 0.16, 'orC')
    for lon in (30, -30):
        p, n = point_anneau(lon, 0.85, YB)
        pieces += gemme('Gemme', 'rubis', p, n, 0.10, 'orC')
    for s in (1, -1):
        p, n = sur_surface(90 * s, 22, R, C)
        o = (s * 1.0, 0, 0)
        racine = add(p, sc(o, 0.03))
        pieces.append(piece('Aile', 'or', ellip((0.14, 0.30, 0.38), racine)))
        for a, L, w in ((5, 0.75, 0.17), (28, 0.86, 0.17), (50, 0.80, 0.16), (72, 0.68, 0.15), (94, 0.52, 0.14)):
            dr = norm(add(add(sc((0, 1, 0), math.cos(math.radians(a))), sc((0, 0, 1), math.sin(math.radians(a)))), sc(o, 0.30)))
            pieces.append(piece('Plume', 'orC', ellip((0.05, L, w), add(add(racine, sc(o, 0.04)), sc(dr, L / 2)), repere(y=dr, z=cross(o, dr)))))
    return dict(id='CasqueBronzeOr', nom="Casque ailé de bronze et d'or", rang=9, pieces=pieces,
                lumieres=[dict(piece='Gemme', type='Point', couleur=(255, 190, 150), portee=8, luminosite=1.2)])


# ================================================================== 10 CasqueFerOr
def casque_fer_or():
    C = 0.08; R = 0.82; RI = 0.70; BAS = -0.70; YV = 0.285; YC = 0.56
    O = (0, 0.12, 0.08)
    festons = [boule(0.14, (1.0 * math.sin(math.radians(k)), YV, -1.0 * math.cos(math.radians(k)))) for k in range(-60, 61, 20)]
    pieces = [
        coque('Coque', 'acierR', R, C, BAS, RI, ouv_rect()),
        csg('Visiere', 'or', cyl(0.06, 1.98, (0, YV, 0), AXE_Y),
            moins=[cyl(0.3, 1.42, (0, YV, 0), AXE_Y), bloc((3, 1, 3), (0, YV, 1.15))] + festons),
        anneau('Couronne', 'or', 0.78, 0.62, YC, 0.16, moins=alveoles(0.785, YC, d=0.05, pas=20, sauf=(0,))),
        anneau('Bord', 'or', 0.86, 0.72, BAS + 0.04, 0.08, moins=[ouv_rect()[1]]),
        cimier('Crin', 'crinRoyal', O, 1.20, 0.86, 0.20, 30, -140,
               secours=[piece('Crin', 'crinRoyal', ellip((0.2, 0.6, 1.5), (0, 0.9, 0.25)))]),
        cimier('Support', 'or', O, 0.97, 0.80, 0.28, 30, -140),
        piece('Nasal', 'or', bloc((0.12, 0.44, 0.07), (0, 0.07, -0.80))),
        piece('Nasal', 'or', boule(0.15, (0, -0.15, -0.80))),
    ]
    for i, lon in enumerate((40, -40, 115, -115)):
        p, n = point_anneau(lon, 0.74, YC + 0.08)
        dr = norm(add((0, 1, 0), sc(n, 0.25)))
        pieces.append(piece('Fleuron', 'or', ellip((0.16, 0.42, 0.10), add(p, sc(dr, 0.17)), repere(y=dr, z=n))))
        pieces.append(piece('Gemme', 'rubis' if i % 2 == 0 else 'saphir', boule(0.09, add(p, sc(dr, 0.34)))))
    p, n = point_anneau(0, 0.79, YC)
    pieces += gemme('Joyau', 'saphir', p, n, 0.18, 'orC')
    for s in (1, -1):
        for x, y in ((0.56, -0.30), (0.50, -0.54)):
            pieces.append(piece('Rivet', 'or', boule(0.085, (s * x, y, -math.sqrt(R * R - x * x)))))
    return dict(id='CasqueFerOr', nom="Casque royal de fer et d'or", rang=10, pieces=pieces,
                lumieres=[dict(piece='Joyau', type='Point', couleur=(150, 185, 255), portee=8, luminosite=1.4),
                          dict(piece='Couronne', type='Point', couleur=(255, 210, 120), portee=6, luminosite=0.8)],
                particules=[dict(piece='Couronne', couleur=(255, 236, 170), taux=5, vie=1.0, taille=0.06, vitesse=0.25)])


COULEURS = {
    'roche':   ('Basalt', (46, 42, 44), 0),
    'rocheC':  ('Slate', (74, 67, 64), 0),
    'socle':   ('Basalt', (24, 22, 24), 0),
    'braise':  ('Neon', (255, 108, 28), 0),
    'bronze':  ('Metal', (214, 148, 74), 0.12),
    'bronzeF': ('Metal', (156, 96, 46), 0.06),
    'crin':    ('Fabric', (172, 30, 34), 0),
    'patine':  ('SmoothPlastic', (86, 158, 132), 0),
    'acier':   ('Metal', (170, 178, 188), 0.12),
    'acierF':  ('Metal', (104, 110, 120), 0.06),
    'acierC':  ('Metal', (204, 210, 218), 0.15),
    'maille':  ('Metal', (76, 80, 90), 0.02),
    'laiton':  ('Metal', (208, 166, 82), 0.1),
    'lampe':   ('Neon', (255, 228, 156), 0),
    'bronzeC': ('Metal', (232, 178, 104), 0.12),
    'acierN':  ('Metal', (62, 64, 72), 0.06),
    'acierR':  ('Metal', (200, 208, 220), 0.2),
    'or':      ('Metal', (240, 188, 72), 0.2),
    'orF':     ('Metal', (186, 130, 44), 0.1),
    'orC':     ('Metal', (252, 218, 124), 0.2),
    'orRose':  ('Metal', (232, 156, 128), 0.18),
    'obsidienne': ('SmoothPlastic', (24, 20, 30), 0.18),
    'rubis':   ('Neon', (255, 40, 80), 0),
    'saphir':  ('Neon', (60, 130, 255), 0),
    'emeraude': ('Neon', (40, 230, 130), 0),
    'flamme':  ('Neon', (255, 168, 40), 0),
    'crinBleu': ('Fabric', (40, 70, 170), 0),
    'crinRoyal': ('Fabric', (150, 20, 48), 0),
    'plume':   ('Fabric', (246, 240, 232), 0),
}

CASQUES = [casque_charbon(), casque_bronze(), casque_charbon_bronze(), casque_fer(), casque_charbon_fer(),
           casque_bronze_fer(), casque_or(), casque_charbon_or(), casque_bronze_or(), casque_fer_or()]
for _rang, _cq in enumerate(CASQUES, 1):
    _cq['rang'] = _rang


# ------------------------------------------------------------------ export Luau
def f(v):
    s = ('%.4f' % v).rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def lua_prim(p):
    pos, r = p['pos'], p['rot']
    cf = 'CFrame.new(%s)' % ', '.join(f(v) for v in (*pos, *r[0], *r[1], *r[2])) if r != I3 else \
        'CFrame.new(%s)' % ', '.join(f(v) for v in pos)
    return '{Forme = "%s", Taille = Vector3.new(%s), CF = %s}' % (p['forme'], ', '.join(f(v) for v in p['taille']), cf)


def lua_piece(p, ind='\t\t'):
    if p['forme'] != 'CSG':
        return '%s{Nom = "%s", Cle = "%s", %s},' % (ind, p['nom'], p['cle'], lua_prim(p)[1:-1])
    L = ['%s{Nom = "%s", Cle = "%s", Forme = "CSG",' % (ind, p['nom'], p['cle']),
         '%s\tBase = %s,' % (ind, lua_prim(p['base']))]
    for champ, cle in (('Plus', 'plus'), ('Moins', 'moins')):
        if p[cle]:
            L.append('%s\t%s = {' % (ind, champ))
            L += ['%s\t\t%s,' % (ind, lua_prim(q)) for q in p[cle]]
            L.append('%s\t},' % ind)
    if p['secours']:
        L.append('%s\tSecours = {' % ind)
        L += [lua_piece(q, ind + '\t\t') for q in p['secours']]
        L.append('%s\t},' % ind)
    L.append('%s},' % ind)
    return '\n'.join(L)


def export_lua(cq):
    cles = []
    for p in cq['pieces']:
        for q in [p] + p.get('secours', []):
            if q['cle'] not in cles:
                cles.append(q['cle'])
    nb = 1 + len(cq['pieces'])
    L = ['-- Généré par blender/armes/casques_lisses.py (%s : %d parts en jeu, Racine comprise). Ne pas modifier à la main.' % (cq['id'], nb),
         '-- Casque lisse construit par ArmuresVoxels (CSG GeometryService, cache + Clone ; Secours si le CSG échoue).',
         '-- Repère = Racine = centre de la tête R15 (1.2 stud) : devant = -Z, haut = +Y, droite = +X, unités = studs.',
         'return {',
         '\tNom = "%s",' % cq['nom'],
         '\tFormat = "Lisse",',
         '\tRang = %d, -- échelle de puissance des casques (1 = plus faible, 10 = plus prestigieux)' % cq['rang'],
         '\t-- clé -> {matériau, r, g, b, reflectance}',
         '\tCouleurs = {']
    for k in cles:
        m, c, r = COULEURS[k]
        L.append('\t\t["%s"] = {"%s", %d, %d, %d, %g},' % (k, m, *c, r))
    L.append('\t},')
    L.append('\tPieces = {')
    L += [lua_piece(p) for p in cq['pieces']]
    L.append('\t},')
    L.append('\tLumieres = {')
    for l in cq['lumieres']:
        extra = ''
        if l['type'] == 'Spot':
            extra = ', Angle = %g, Face = "%s"' % (l['angle'], l['face'])
        L.append('\t\t{Piece = "%s", Type = "%s", Couleur = Color3.fromRGB(%d, %d, %d), Portee = %g, Luminosite = %g%s},'
                 % (l['piece'], l['type'], *l['couleur'], l['portee'], l['luminosite'], extra))
    L.append('\t},')
    if cq.get('particules'):
        L.append('\tParticules = {')
        for q in cq['particules']:
            L.append('\t\t{Piece = "%s", Couleur = Color3.fromRGB(%d, %d, %d), Taux = %g, Vie = %g, Taille = %g, Vitesse = %g},'
                     % (q['piece'], *q['couleur'], q['taux'], q['vie'], q['taille'], q['vitesse']))
        L.append('\t},')
    L.append('}')
    dest = os.path.join(DOSSIER_LUA, cq['id'] + '.lua')
    open(dest, 'w', encoding='utf8', newline='\n').write('\n'.join(L) + '\n')
    nb_csg = sum(1 for p in cq['pieces'] if p['forme'] == 'CSG')
    print('ARME_LUA', dest, nb, 'parts', nb_csg, 'CSG')


# ------------------------------------------------------------------ rendu Blender
def rendu():
    import bpy, bmesh
    from mathutils import Matrix, Euler
    sys.path.insert(0, ICI)
    import armure_commun as A

    A.scene((1500, 1560))
    sc_ = bpy.context.scene
    try:
        sc_.render.film_transparent = False
    except Exception:
        pass
    mats = {}

    def mat(cle):
        if cle in mats:
            return mats[cle]
        if cle == '_tete':
            m_, c, r = 'Plastic', (128, 128, 136), 0
        elif cle == '_yeux':
            m_, c, r = 'Plastic', (28, 28, 32), 0
        else:
            m_, c, r = COULEURS[cle]
        mt = bpy.data.materials.new(cle); mt.use_nodes = True
        nt = mt.node_tree
        b = nt.nodes['Principled BSDF']
        rgb = tuple((v / 255) ** 2.2 for v in c) + (1,)
        b.inputs['Base Color'].default_value = rgb
        b.inputs['Roughness'].default_value = {'Metal': 0.3, 'Basalt': 0.92, 'Slate': 0.85, 'Fabric': 1.0}.get(m_, 0.6)
        b.inputs['Metallic'].default_value = 0.6 if m_ == 'Metal' else 0
        if m_ == 'Neon':
            b.inputs['Emission Color'].default_value = rgb
            b.inputs['Emission Strength'].default_value = 5
        if m_ in ('Basalt', 'Slate', 'Fabric'):
            tex = nt.nodes.new('ShaderNodeTexNoise'); tex.inputs['Scale'].default_value = 28 if m_ != 'Fabric' else 90
            bump = nt.nodes.new('ShaderNodeBump'); bump.inputs['Strength'].default_value = 0.35
            nt.links.new(tex.outputs['Fac'], bump.inputs['Height'])
            nt.links.new(bump.outputs['Normal'], b.inputs['Normal'])
        mats[cle] = mt
        return mt

    def objet_prim(p, parent, nom='p'):
        f_ = p['forme']
        bm = bmesh.new()
        if f_ == 'Bloc':
            bmesh.ops.create_cube(bm, size=1)
        elif f_ in ('Boule', 'Ellipsoide'):
            bmesh.ops.create_uvsphere(bm, u_segments=64, v_segments=32, radius=0.5)
        elif f_ == 'Cylindre':
            bmesh.ops.create_cone(bm, cap_ends=True, segments=64, radius1=0.5, radius2=0.5, depth=1)
            bmesh.ops.rotate(bm, verts=bm.verts, matrix=Matrix.Rotation(math.radians(90), 3, 'Y'))
        bmesh.ops.scale(bm, vec=p['taille'], verts=bm.verts)
        me = bpy.data.meshes.new(nom); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(nom, me); bpy.context.scene.collection.objects.link(o)
        r = p['rot']
        M = Matrix(((r[0][0], r[0][1], r[0][2], p['pos'][0]), (r[1][0], r[1][1], r[1][2], p['pos'][1]),
                    (r[2][0], r[2][1], r[2][2], p['pos'][2]), (0, 0, 0, 1)))
        o.parent = parent
        o.matrix_parent_inverse = Matrix.Identity(4)
        o.matrix_basis = M
        return o

    def activer(o):
        for x in bpy.context.selected_objects:
            x.select_set(False)
        bpy.context.view_layer.objects.active = o
        o.select_set(True)

    def lisser(o, angle=38):
        activer(o)
        try:
            bpy.ops.object.shade_smooth_by_angle(angle=math.radians(angle))
        except Exception:
            bpy.ops.object.shade_smooth()

    def objet_piece(p, parent):
        if p['forme'] != 'CSG':
            o = objet_prim(p, parent, p['nom'])
            o.data.materials.append(mat(p['cle']))
            lisser(o)
            return o
        o = objet_prim(p['base'], parent, p['nom'])
        outils = []
        for op, liste in (('UNION', p['plus']), ('DIFFERENCE', p['moins'])):
            for q in liste:
                t = objet_prim(q, parent, 'outil')
                outils.append(t)
                md = o.modifiers.new('b', 'BOOLEAN'); md.operation = op; md.object = t; md.solver = 'EXACT'
        activer(o)
        for md in list(o.modifiers):
            bpy.ops.object.modifier_apply(modifier=md.name)
        for t in outils:
            bpy.data.objects.remove(t, do_unlink=True)
        o.data.materials.clear()
        o.data.materials.append(mat(p['cle']))
        for poly in o.data.polygons:
            poly.material_index = 0
        lisser(o)
        return o

    def tete(parent):
        bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1.2)
        me = bpy.data.meshes.new('tete'); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new('Tete', me); bpy.context.scene.collection.objects.link(o)
        o.parent = parent; o.matrix_parent_inverse = Matrix.Identity(4)
        bv = o.modifiers.new('bv', 'BEVEL'); bv.width = 0.28; bv.segments = 8
        o.data.materials.append(mat('_tete'))
        lisser(o, 50)
        for p, cle in ((bloc((0.6, 0.3, 0.6), (0, -0.75, 0)), '_tete'), (bloc((2.0, 0.7, 1.0), (0, -1.25, 0)), '_tete'),
                       (ellip((0.13, 0.2, 0.04), (0.22, 0.08, -0.6)), '_yeux'), (ellip((0.13, 0.2, 0.04), (-0.22, 0.08, -0.6)), '_yeux'),
                       (bloc((0.34, 0.05, 0.04), (0, -0.25, -0.6)), '_yeux')):
            q = objet_prim(p, parent, 'deco'); q.data.materials.append(mat(cle))

    # gabarits : un exemplaire de chaque casque, dupliqué ensuite (booléens calculés une fois)
    choix = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    casques = [cq for cq in CASQUES if not choix or cq['id'] in choix or 'echelle' in choix]
    gabarits = {}
    for cq in casques:
        piv = bpy.data.objects.new('G' + cq['id'], None); bpy.context.scene.collection.objects.link(piv)
        objs = [objet_piece(p, piv) for p in cq['pieces']]
        for o in objs:
            o.hide_render = True
        gabarits[cq['id']] = objs
        print('ARME_GABARIT', cq['id'], len(objs) + 1, 'parts')

    A.lumieres_et_camera(9.6, 0.15)
    w = sc_.world.node_tree.nodes['Background']; w.inputs[1].default_value = 3.0
    cam = sc_.camera

    def texte(corps, loc, taille=0.32):
        cu = bpy.data.curves.new('t', 'FONT'); cu.body = corps; cu.align_x = 'CENTER'; cu.size = taille
        o = bpy.data.objects.new('t', cu); bpy.context.scene.collection.objects.link(o)
        o.location = loc; o.rotation_euler = Euler((math.radians(90), 0, math.radians(180)), 'XYZ')
        mt = mats.get('_texte')
        if not mt:
            mt = bpy.data.materials.new('_texte'); mt.use_nodes = True
            b = mt.node_tree.nodes['Principled BSDF']
            b.inputs['Emission Color'].default_value = (1, 0.85, 0.55, 1); b.inputs['Emission Strength'].default_value = 1.5
            b.inputs['Base Color'].default_value = (1, 0.85, 0.55, 1)
            mats['_texte'] = mt
        o.data.materials.append(mt)
        return o

    def image(nom, placements, res, ortho, cz, etiquettes=()):
        crees = []
        for cid, x, z, rot in placements:
            piv = bpy.data.objects.new('Piv', None); bpy.context.scene.collection.objects.link(piv)
            piv.location = (x, 0, z)
            piv.rotation_euler = Euler((math.radians(90), 0, math.radians(rot)), 'XYZ')
            avant = set(bpy.data.objects)
            tete(piv)
            for o in gabarits[cid]:
                c = o.copy(); c.data = o.data; c.hide_render = False
                bpy.context.scene.collection.objects.link(c)
                c.parent = piv; c.matrix_parent_inverse = Matrix.Identity(4); c.matrix_basis = o.matrix_basis.copy()
            crees += [piv] + [o for o in bpy.data.objects if o not in avant]
        for corps, loc in etiquettes:
            crees.append(texte(corps, loc))
        sc_.render.resolution_x, sc_.render.resolution_y = res
        cam.data.ortho_scale = ortho
        cam.location = (0, 14, cz + 14 * math.tan(math.radians(8)))
        A.rendre(nom)
        for o in crees:
            bpy.data.objects.remove(o, do_unlink=True)

    for cq in casques:
        if choix and cq['id'] not in choix:
            continue
        image(cq['id'] + '.png', [(cq['id'], 2.75, 0, 30), (cq['id'], 0, 0, 0), (cq['id'], -2.75, 0, 150)],
              (1500, 760), 8.4, 0.25)
    if len(casques) == len(CASQUES):
        place = []
        etiq = []
        for k, cq in enumerate(CASQUES):
            r, j = divmod(k, 5)
            x, z = (2 - j) * 2.65, 1.95 - r * 3.9
            place.append((cq['id'], x, z, 30))
            import re
            etiq.append(('%d  %s' % (cq['rang'], ' + '.join(re.findall('[A-Z][a-z]+', cq['id'][6:]))), (x, 0.6, z - 1.95)))
        image('CasquesEchelle.png', place, (2200, 1420), 13.4, -0.35, etiq)
        image('Casques2.png', [(cid, (1 - i) * 2.75, z, rot) for z, rot in ((3.25, 30), (0.0, 0), (-3.25, 150))
                               for i, cid in enumerate(('CasqueCharbon', 'CasqueBronze', 'CasqueFer'))],
              (1500, 1560), 9.6, 0.15)


if __name__ == '__main__':
    for cq in CASQUES:
        export_lua(cq)
    if 'bpy' in sys.modules or any('blender' in a.lower() for a in sys.argv[:1]):
        rendu()
