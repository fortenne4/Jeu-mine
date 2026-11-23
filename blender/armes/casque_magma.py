"""Casque du Cœur Magmatique (casque unique de quête, grotte de lave −200 m).

Source unique du modèle : la liste de primitives Roblox (Part bloc / WedgePart) définie ici sert à la fois
  1. au module Luau src/partage/ArmuresVoxels/CasqueMagma.lua (Format = "Code", Parts construites en jeu,
     visibles par tous les collaborateurs, aucun asset importé) ;
  2. au vrai mesh Blender low poly : assets/casques/CasqueMagma.fbx + CasqueMagma.obj (objets séparés
     Coque, Cornes, Plaques, Fissures, Cristal, Visiere, Pointes, Eclats ; un objet par matériau) ;
  3. à l'aperçu previews/armes/CasqueMagma.png (vue 3/4 avant, fond sombre).

blender -b --factory-startup --python casque_magma.py [-- <dossier_vues_de_controle>]

Repère = repère Roblox : origine = centre de la tête R15 (1.2 stud), devant = -Z, haut = +Y, droite du perso = +X.
Dans Blender : (x, y, z)_Roblox -> (x, -z, y). Export FBX axis_forward=-Z, axis_up=Y => coordonnées FBX = Roblox.
"""
import bpy, bmesh, math, os, sys, random
from mathutils import Vector, Matrix

ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.abspath(os.path.join(ICI, '..', '..'))
F_LUA = os.path.join(JEU, 'src', 'partage', 'ArmuresVoxels', 'CasqueMagma.lua')
D_FBX = os.path.join(JEU, 'assets', 'casques')
F_PNG = os.path.join(JEU, 'previews', 'armes', 'CasqueMagma.png')

# ------------------------------------------------------------------ matériaux
#  clé            Roblox Material   couleur RGB        reflect  metal rough émission
MATS = {
    'basalte':    ('Basalt',        (38, 35, 38),      0.0,    0.0, 0.92, 0),
    'obsidienne': ('SmoothPlastic', (21, 19, 25),      0.12,   0.0, 0.5, 0),
    'roche':      ('Slate',         (70, 64, 64),      0.0,    0.0, 0.88, 0),
    'visiere':    ('SmoothPlastic', (46, 42, 50),      0.1,    0.0, 0.28, 0),
    'fente':      ('SmoothPlastic', (0, 0, 0),         0.0,    0.0, 1.00, 0),
    'yeux':       ('Neon',          (150, 16, 8),      0.0,    0.0, 0.50, 3),
    'magma':      ('Neon',          (255, 88, 18),     0.0,    0.0, 0.50, 4),
    'cristal':    ('Neon',          (255, 124, 26),    0.0,    0.0, 0.30, 6),
    'coeur':      ('Neon',          (255, 222, 96),    0.0,    0.0, 0.20, 9),
}
# groupe Roblox (nom des Parts) -> objet Blender ; matériau principal de l'objet (les autres : <Objet>_<mat>)
OBJETS = {'Coque': 'Coque', 'CorneG': 'Cornes', 'CorneD': 'Cornes', 'Plaques': 'Plaques', 'Fissures': 'Fissures',
          'Cristal': 'Cristal', 'Visiere': 'Visiere', 'Pointes': 'Pointes', 'Eclats': 'Eclats'}
PRINCIPAL = {'Coque': 'basalte', 'Cornes': 'roche', 'Plaques': 'obsidienne', 'Fissures': 'magma',
             'Cristal': 'cristal', 'Visiere': 'visiere', 'Pointes': 'obsidienne', 'Eclats': 'roche'}

# ------------------------------------------------------------------ géométrie (repère Roblox)
I3 = Matrix.Identity(3)


def V(x, y, z):
    return Vector((x, y, z))


def rot(axe, deg):
    return Matrix.Rotation(math.radians(deg), 3, axe)


def repere(n, bhint):
    """Base (a, b, n) directe : a x b = n. Colonnes de la matrice = axes locaux X, Y, Z."""
    n = Vector(n).normalized()
    b = Vector(bhint)
    b = (b - n * b.dot(n)).normalized()
    a = b.cross(n)
    return Matrix((a, b, n)).transposed()


def repere_y(y, zhint):
    """Axe local Y = y ; Z au plus près de zhint ; X = Y x Z."""
    y = Vector(y).normalized()
    z = Vector(zhint)
    z = (z - y * z.dot(y)).normalized()
    x = y.cross(z)
    return Matrix((x, y, z)).transposed()


PIECES = []   # dict(nom, cle, forme, taille, pos, R, tag)


def piece(nom, cle, taille, pos, R=I3, forme='Bloc', tag=None):
    p = dict(nom=nom, cle=cle, forme=forme, taille=Vector(taille), pos=Vector(pos), R=R.copy(), tag=tag)
    PIECES.append(p)
    return p


S = Matrix(((-1, 0, 0), (0, 1, 0), (0, 0, 1)))


def miroir(p, nom=None):
    """Copie symétrique (x -> -x) ; S R S garde det = +1, bloc et coin sont symétriques en X."""
    return piece(nom or p['nom'], p['cle'], p['taille'], V(-p['pos'].x, p['pos'].y, p['pos'].z), S @ p['R'] @ S,
                 p['forme'], p['tag'])


def tente(nom, cle, base, d, L, wx, wz, zhint, R_extra=I3):
    """Pointe en toit : 2 WedgePart dos à dos, arête (largeur wx selon X local) au bout de d."""
    R = repere_y(d, zhint) @ R_extra
    c = Vector(base) + R.col[1] * (L / 2)
    for sgn, Rw in ((-1, R), (1, R @ rot('Y', 180))):
        piece(nom, cle, (wx, L, wz / 2), c + R.col[2] * (sgn * wz / 4), Rw, forme='Coin')


class Face:
    def __init__(self, origine, n, bhint, w, h):
        self.o = Vector(origine)
        self.R = repere(n, bhint)
        self.w, self.h = w, h

    def point(self, u, v, d):
        return self.o + self.R.col[0] * u + self.R.col[1] * v + self.R.col[2] * d


E, YT, C, YB, T = 0.72, 0.76, 0.22, -0.68, 0.08   # demi-largeur, haut, chanfrein, bas, épaisseur coque
YC, HH = (YB + YT - C) / 2, YT - C - YB
W0, WC = 2 * (E - C), C * math.sqrt(2)


def faces():
    F = {}
    F['haut'] = Face((0, YT, 0), (0, 1, 0), (0, 0, -1), W0, W0)
    F['droite'] = Face((E, YC, 0), (1, 0, 0), (0, 1, 0), W0, HH)
    F['gauche'] = Face((-E, YC, 0), (-1, 0, 0), (0, 1, 0), W0, HH)
    F['dos'] = Face((0, YC, E), (0, 0, 1), (0, 1, 0), W0, HH)
    F['avant'] = Face((0, YC, -E), (0, 0, -1), (0, 1, 0), W0, HH)
    for s, k in ((1, 'cD'), (-1, 'cG')):
        F[k] = Face((s * (E - C / 2), YT - C / 2, 0), (s, 1, 0), (0, 1, 0), W0, WC)
    for s, k in ((1, 'cDos'), (-1, 'cAv')):
        F[k] = Face((0, YT - C / 2, s * (E - C / 2)), (0, 1, s), (0, 1, 0), W0, WC)
    for sx in (1, -1):
        for sz in (1, -1):
            F['v%d%d' % (sx, sz)] = Face((sx * (E - C / 2), YC, sz * (E - C / 2)), (sx, 0, sz), (0, 1, 0), WC, HH)
            F['k%d%d' % (sx, sz)] = Face((sx * (E - 2 * C / 3), YT - 2 * C / 3, sz * (E - 2 * C / 3)),
                                         (sx, 1, sz), (0, 1, 0), 0.27, 0.27)
    return F


def coque(F):
    for k, f in F.items():
        if k == 'avant':
            piece('Visiere', 'visiere', (f.w, f.h, T), f.point(0, 0, -T / 2), f.R)
        else:
            marge = 0.03 if k[0] in 'cv' else 0.0
            piece('Coque', 'basalte', (f.w + marge, f.h + marge, T), f.point(0, 0, -T / 2), f.R,
                  tag='braises' if k == 'haut' else None)


def nappe_magma(F):
    """Fond de fissures : couche Neon sous les plaques, visible dans les joints."""
    for k in ('haut', 'droite', 'gauche', 'dos', 'cD', 'cG', 'cDos', 'cAv', 'v11', 'v-11', 'v1-1', 'v-1-1'):
        f = F[k]
        piece('Fissures', 'magma', (f.w - 0.01, f.h - 0.01, 0.045), f.point(0, 0, 0.022), f.R)
    f = F['avant']   # bandeau du front (sous les arcades)
    piece('Fissures', 'magma', (f.w - 0.01, 0.32, 0.045), f.point(0, 0.45, 0.022), f.R)


def plaques(f, graine, nb, v0=None, v1=None, gap=0.04, ep=(0.06, 0.11), obs=0.7):
    rnd = random.Random(graine)
    rects = [(-f.w / 2, f.w / 2, v0 if v0 is not None else -f.h / 2, v1 if v1 is not None else f.h / 2)]
    while len(rects) < nb:
        rects.sort(key=lambda r: (r[1] - r[0]) * (r[3] - r[2]))
        u0, u1, a0, a1 = rects.pop()
        t = rnd.uniform(0.36, 0.64)
        if (u1 - u0) >= (a1 - a0):
            m = u0 + (u1 - u0) * t
            rects += [(u0, m, a0, a1), (m, u1, a0, a1)]
        else:
            m = a0 + (a1 - a0) * t
            rects += [(u0, u1, a0, m), (u0, u1, m, a1)]
    for (u0, u1, a0, a1) in rects:
        du, dv = u1 - u0 - gap, a1 - a0 - gap
        e = rnd.uniform(*ep)
        R = f.R @ rot('Z', rnd.uniform(-6, 6)) @ rot('X', rnd.uniform(-7, 7)) @ rot('Y', rnd.uniform(-7, 7))
        cle = 'obsidienne' if rnd.random() < obs else 'roche'
        piece('Plaques', cle, (du, dv, e), f.point((u0 + u1) / 2, (a0 + a1) / 2, e / 2 + 0.012), R)


def toutes_plaques(F):
    plaques(F['haut'], 11, 4)
    plaques(F['droite'], 12, 6)
    plaques(F['gauche'], 13, 6)
    plaques(F['dos'], 14, 6)
    for i, k in enumerate(('cD', 'cG', 'cDos', 'cAv')):
        plaques(F[k], 20 + i, 2)
    for i, k in enumerate(('v11', 'v-11', 'v1-1', 'v-1-1')):
        plaques(F[k], 30 + i, 2)
    for i, k in enumerate(('k11', 'k-11', 'k1-1', 'k-1-1')):
        plaques(F[k], 40 + i, 1, gap=0.0, obs=0.5)
    # arcades du front en V (bord inférieur avancé, extrémité intérieure plus basse : regard furieux)
    g = piece('Plaques', 'obsidienne', (0.58, 0.28, 0.2), (-0.28, 0.37, -(E + 0.1)), rot('Z', -14) @ rot('X', 12))
    miroir(g)


def visiere():
    """Mufle en V : 2 plaques très sombres qui se rejoignent en arête devant le nez, fentes + yeux."""
    th, zr, L, h, yc = 22.0, -(E + 0.22), 0.66, 0.90, -0.23
    R = rot('Y', th)
    c = V(0, yc, zr) - R.col[0] * (L / 2) + R.col[2] * 0.035
    pl = piece('Visiere', 'visiere', (L, h, 0.07), c, R)
    Rf = R @ rot('Z', -12)
    fente = piece('Visiere', 'fente', (0.44, 0.1, 0.03), c + R.col[0] * 0.04 + R.col[1] * 0.31 - R.col[2] * 0.04, Rf)
    oeil = piece('Visiere', 'yeux', (0.12, 0.05, 0.02), c + R.col[0] * 0.10 + R.col[1] * 0.297 - R.col[2] * 0.05, Rf)
    # larme de magma sous l'œil
    lar = piece('Fissures', 'magma', (0.035, 0.24, 0.02), c + R.col[0] * 0.13 + R.col[1] * 0.12 - R.col[2] * 0.045,
                R @ rot('Z', 4))
    gou = piece('Fissures', 'magma', (0.065, 0.065, 0.025), c + R.col[0] * 0.14 + R.col[1] * -0.01 - R.col[2] * 0.045,
                R @ rot('Z', 45))
    # crocs sous la visière
    crocs = [piece('Pointes', 'obsidienne', (0.12, 0.12, 0.06),
                   c + R.col[0] * u + R.col[1] * (-h / 2) - R.col[2] * 0.004, R @ rot('Z', 45))
             for u in (-0.22, 0.0, 0.22)]
    for p in [pl, fente, oeil, lar, gou] + crocs:
        miroir(p)
    # pointe du menton
    tente('Pointes', 'obsidienne', V(0, -0.6, -(E + 0.21)), V(0, -1, -0.3), 0.3, 0.08, 0.2, V(1, 0, 0))


def cristal():
    z = -(E + 0.2)
    piece('Plaques', 'obsidienne', (0.31, 0.31, 0.07), (0, 0.41, z), rot('Z', 45))
    piece('Cristal', 'cristal', (0.22, 0.22, 0.1), (0, 0.41, z - 0.05), rot('Z', 45), tag='lumiere')
    piece('Cristal', 'coeur', (0.115, 0.115, 0.06), (0, 0.41, z - 0.09), rot('Z', 45))
    # éclats de cristal au-dessus / au-dessous : losange étiré
    piece('Cristal', 'cristal', (0.07, 0.07, 0.06), (0, 0.59, z - 0.03), rot('Z', 45))
    piece('Cristal', 'cristal', (0.06, 0.06, 0.06), (0, 0.24, z - 0.03), rot('Z', 45))


def bezier(p, t):
    a, b, c, d = p
    u = 1 - t
    return a * u ** 3 + b * 3 * u * u * t + c * 3 * u * t * t + d * t ** 3


def corne(nom, s, ctrl, w0, w1, n=7, anneaux=(1, 3)):
    ctrl = [V(s * x, y, z) for x, y, z in ctrl]
    P = [bezier(ctrl, i / n) for i in range(n + 1)]
    larg = [w0 + (w1 - w0) * (i / n) ** 0.9 for i in range(n + 1)]
    for i in range(n):
        a, b = P[i], P[i + 1]
        d = b - a
        w = (larg[i] + larg[i + 1]) / 2
        R = repere_y(d, V(0, 0, 1)) @ rot('Y', 45)
        cle = 'roche' if i < n - 2 else 'obsidienne'
        piece(nom, cle, (w, d.length + w * 0.8, w), (a + b) / 2, R)
        if i in anneaux:   # anneau de magma à la jointure
            d2 = (P[i + 1] - P[i - 1])
            Ra = repere_y(d2, V(0, 0, 1)) @ rot('Y', 45)
            piece('Fissures', 'magma', (larg[i] * 1.22, 0.06, larg[i] * 1.22), a, Ra)
    d = P[n] - P[n - 1]
    tente(nom, 'obsidienne', P[n] - d.normalized() * 0.04, d, 0.34, larg[n] * 0.95, larg[n] * 0.95, V(0, 0, 1),
          rot('Y', 45))


def cornes():
    # gauche du perso (x < 0) : plus haute, plus recourbée vers l'intérieur et l'arrière
    corne('CorneG', -1, [(0.66, 0.32, 0.05), (1.18, 0.42, 0.12), (1.38, 1.15, 0.25), (0.98, 1.85, 0.50)], 0.44, 0.10)
    # droite : plus courte, plus droite
    corne('CorneD', 1, [(0.66, 0.32, 0.05), (1.08, 0.38, 0.05), (1.20, 0.92, 0.10), (1.08, 1.42, 0.26)], 0.40, 0.11)


def pointes():
    # crête rocheuse sur le dessus, penchée vers l'arrière
    for z, L, wz in ((-0.32, 0.32, 0.3), (-0.06, 0.46, 0.36), (0.20, 0.56, 0.4), (0.44, 0.46, 0.34)):
        y = YT + 0.03 if z <= E - C else YT + 0.03 - (z - (E - C))
        tente('Pointes', 'obsidienne', V(0, y, z), V(0, 1, 0.5), L, 0.12, wz, V(0, 0, 1))
    # pointes de la nuque
    tente('Pointes', 'obsidienne', V(0, 0.2, E + 0.06), V(0, -0.25, 1), 0.46, 0.11, 0.34, V(0, 1, 0))
    # bord inférieur dentelé (nuque et joues) : losanges dont la pointe dépasse vers le bas
    for x, z, n in ((-0.3, E + 0.06, (0, 0, 1)), (0.0, E + 0.07, (0, 0, 1)), (0.3, E + 0.06, (0, 0, 1)),
                    (-(E + 0.06), 0.25, (-1, 0, 0)), (-(E + 0.06), -0.15, (-1, 0, 0)),
                    (E + 0.06, 0.25, (1, 0, 0)), (E + 0.06, -0.15, (1, 0, 0))):
        piece('Pointes', 'obsidienne', (0.17, 0.17, 0.07), (x, YB - 0.01, z), repere(n, (0, 1, 0)) @ rot('Z', 45))


def coulees(F):
    """Coulées de lave qui débordent des joints sur la surface des plaques."""
    for k, u, v, L, a in (('gauche', 0.14, -0.22, 0.40, 7), ('droite', -0.2, -0.3, 0.34, -6), ('dos', 0.26, -0.3, 0.36, 5)):
        f = F[k]
        piece('Fissures', 'magma', (0.04, L, 0.02), f.point(u, v, 0.115), f.R @ rot('Z', a))
        piece('Fissures', 'magma', (0.07, 0.07, 0.025), f.point(u + math.sin(math.radians(a)) * L / 2, v - L / 2, 0.115),
              f.R @ rot('Z', 45))


def eclats():
    rnd = random.Random(7)
    for pos, t, cle in (((-1.12, 0.12, 0.28), 0.15, 'roche'), ((-1.0, -0.42, -0.18), 0.1, 'obsidienne'),
                        ((1.08, 0.0, 0.36), 0.13, 'obsidienne'), ((1.3, 0.62, -0.1), 0.09, 'magma'),
                        ((0.42, 1.08, 0.66), 0.1, 'roche'), ((-0.5, 1.0, -0.62), 0.08, 'magma'),
                        ):
        R = rot('X', rnd.uniform(0, 90)) @ rot('Y', rnd.uniform(0, 90)) @ rot('Z', rnd.uniform(0, 90))
        piece('Eclats', cle, (t, t * rnd.uniform(1.1, 1.6), t * rnd.uniform(0.7, 1.0)), pos, R)


def construire_spec():
    F = faces()
    coque(F)
    nappe_magma(F)
    toutes_plaques(F)
    visiere()
    cristal()
    cornes()
    pointes()
    coulees(F)
    eclats()


# ------------------------------------------------------------------ sommets des primitives (repère local Roblox)
def sommets(p):
    hx, hy, hz = p['taille'] / 2
    if p['forme'] == 'Bloc':
        v = [V(x, y, z) for x in (-hx, hx) for y in (-hy, hy) for z in (-hz, hz)]
        f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    else:   # WedgePart : face verticale à l'arrière (+Z), pente vers l'avant (-Z) et le haut
        v = [V(-hx, -hy, -hz), V(hx, -hy, -hz), V(hx, -hy, hz), V(-hx, -hy, hz), V(-hx, hy, hz), V(hx, hy, hz)]
        f = [(0, 1, 2, 3), (3, 2, 5, 4), (0, 4, 5, 1), (0, 3, 4), (1, 5, 2)]
    return [p['pos'] + p['R'] @ x for x in v], f


def bornes():
    lo, hi = V(1e9, 1e9, 1e9), V(-1e9, -1e9, -1e9)
    for p in PIECES:
        for x in sommets(p)[0]:
            for i in range(3):
                lo[i], hi[i] = min(lo[i], x[i]), max(hi[i], x[i])
    return lo, hi


# ------------------------------------------------------------------ Luau
def f4(x):
    s = '%.4f' % x
    s = s.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def ecrire_lua():
    lo, hi = bornes()
    taille = hi - lo
    L = ['-- Généré par blender/armes/casque_magma.py (%d Parts en jeu, Racine comprise). Ne pas modifier à la main.' % (len(PIECES) + 1),
         '-- Casque du Cœur Magmatique : casque unique de quête (grotte de lave −200 m, voir Partage.CasqueMagma).',
         '-- Format = "Code" : Parts Roblox construites par construire() (Part bloc + WedgePart), aucun asset importé,',
         '-- donc visible par tous. Version mesh exportable : assets/casques/CasqueMagma.fbx / .obj.',
         '-- Repère = Racine = centre de la tête R15 (1.2 stud) : devant = -Z, haut = +Y, droite = +X, unités = studs.',
         '',
         '-- clé -> {matériau, r, g, b, reflectance}',
         'local COULEURS = {']
    for k, (rm, c, refl, *_r) in MATS.items():
        L.append('\t%s = {"%s", %d, %d, %d, %s},' % (k, rm, c[0], c[1], c[2], f4(refl)))
    L.append('}')
    L.append('')
    L.append('-- {nom, clé, forme ("Bloc" | "Coin" = WedgePart), taille, CFrame, marque ("lumiere" | "braises")}')
    L.append('local PIECES = {')
    for p in PIECES:
        R = p['R']
        cf = ', '.join(f4(x) for x in (p['pos'].x, p['pos'].y, p['pos'].z,
                                        R[0][0], R[0][1], R[0][2], R[1][0], R[1][1], R[1][2], R[2][0], R[2][1], R[2][2]))
        t = p['taille']
        tag = ', "%s"' % p['tag'] if p['tag'] else ''
        L.append('\t{"%s", "%s", "%s", Vector3.new(%s, %s, %s), CFrame.new(%s)%s},'
                 % (p['nom'], p['cle'], p['forme'], f4(t.x), f4(t.y), f4(t.z), cf, tag))
    L.append('}')
    L.append('''
local function materiau(nom: string): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[nom]
	end)
	return if ok and typeof(m) == "EnumItem" then m else Enum.Material.SmoothPlastic
end

local function braises(parent: BasePart)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Braises"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 176, 64), Color3.fromRGB(210, 40, 10))
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Rate = 6
	e.Lifetime = NumberRange.new(1.2, 2.2)
	e.Speed = NumberRange.new(0.25, 0.6)
	e.EmissionDirection = Enum.NormalId.Top
	e.SpreadAngle = Vector2.new(30, 30)
	e.Acceleration = Vector3.new(0, 0.5, 0)
	e.Drag = 0.6
	e.RotSpeed = NumberRange.new(-120, 120)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.4, 0.09),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Parent = parent
end

local function construire(): Model
	local modele = Instance.new("Model")
	modele.Name = "CasqueMagma"
	modele:SetAttribute("NomAffiche", "Casque du Cœur Magmatique")
	modele:SetAttribute("Rarete", "Unique")

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

	local lumiereFaite, braisesFaites = false, false
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
			l.Color = Color3.fromRGB(255, 130, 40)
			l.Range = 8
			l.Brightness = 1.5
			l.Shadows = false
			l.Parent = p
		elseif marque == "braises" and not braisesFaites then
			braisesFaites = true
			braises(p)
		end
		p.Parent = modele
		local w = Instance.new("WeldConstraint")
		w.Part0 = racine
		w.Part1 = p
		w.Parent = p
	end
	return modele
end
''')
    L.append('return {')
    L.append('\tNom = "Casque du Cœur Magmatique",')
    L.append('\tFormat = "Code",')
    L.append('\tTaille = Vector3.new(%s, %s, %s),' % (f4(taille.x), f4(taille.y), f4(taille.z)))
    L.append('\tCentre = Vector3.new(%s, %s, %s), -- centre de la boîte englobante dans le repère de la tête'
             % (f4((hi.x + lo.x) / 2), f4((hi.y + lo.y) / 2), f4((hi.z + lo.z) / 2)))
    L.append('\tconstruire = construire,')
    L.append('}')
    os.makedirs(os.path.dirname(F_LUA), exist_ok=True)
    open(F_LUA, 'w', encoding='utf8', newline='\n').write('\n'.join(L) + '\n')
    print('MAGMA_LUA', F_LUA, 'parts', len(PIECES) + 1, 'taille', tuple(round(x, 3) for x in taille))


# ------------------------------------------------------------------ Blender
def r2b(p):
    return (p[0], -p[2], p[1])


_mats = {}


def materiau(nom):
    if nom in _mats:
        return _mats[nom]
    rm, c, refl, metal, rough, em = MATS[nom]
    m = bpy.data.materials.new(nom)
    m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    rgb = tuple((x / 255) ** 2.2 for x in c) + (1,)
    b.inputs['Base Color'].default_value = rgb
    b.inputs['Metallic'].default_value = metal
    b.inputs['Roughness'].default_value = rough
    if em:
        b.inputs['Emission Color'].default_value = rgb
        b.inputs['Emission Strength'].default_value = em
    m.diffuse_color = rgb
    _mats[nom] = m
    return m


def construire_blender():
    groupes = {}
    for p in PIECES:
        obj = OBJETS[p['nom']]
        nom = obj if p['cle'] == PRINCIPAL[obj] else obj + '_' + p['cle']
        groupes.setdefault(nom, (p['cle'], []))[1].append(p)
    objets = {}
    for nom, (cle, ps) in groupes.items():
        verts, faces_ = [], []
        for p in ps:
            vs, fs = sommets(p)
            k = len(verts)
            verts += [r2b(x) for x in vs]
            faces_ += [tuple(i + k for i in f) for f in fs]
        me = bpy.data.meshes.new(nom)
        me.from_pydata(verts, [], faces_)
        me.validate()
        bm = bmesh.new(); bm.from_mesh(me)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(me); bm.free()
        for poly in me.polygons:
            poly.use_smooth = False
        me.materials.append(materiau(cle))
        o = bpy.data.objects.new(nom, me)
        bpy.context.scene.collection.objects.link(o)
        objets[nom] = o
    # marqueur Racine (centre de la tête), comme les autres casques
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=0.1)
    me = bpy.data.meshes.new('Racine'); bm.to_mesh(me); bm.free()
    r = bpy.data.objects.new('Racine', me); bpy.context.scene.collection.objects.link(r)
    objets['Racine'] = r
    return objets


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def exporter(objets):
    os.makedirs(D_FBX, exist_ok=True)
    for x in bpy.context.selected_objects:
        x.select_set(False)
    for o in objets.values():
        o.select_set(True)
    bpy.context.view_layer.objects.active = objets['Racine']
    fbx = os.path.join(D_FBX, 'CasqueMagma.fbx')
    bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, object_types={'MESH'}, global_scale=1.0,
                             apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE', axis_forward='-Z', axis_up='Y',
                             mesh_smooth_type='FACE', use_mesh_modifiers=True, bake_space_transform=True,
                             add_leaf_bones=False, path_mode='AUTO')
    obj = os.path.join(D_FBX, 'CasqueMagma.obj')
    bpy.ops.wm.obj_export(filepath=obj, export_selected_objects=True, forward_axis='NEGATIVE_Z', up_axis='Y',
                          export_materials=True, export_normals=True, export_uv=False, apply_modifiers=True)
    print('MAGMA_FBX', fbx)
    print('MAGMA_OBJ', obj)


# ------------------------------------------------------------------ rendu
def scene_rendu():
    sc = bpy.context.scene
    for eng in ('BLENDER_EEVEE', 'BLENDER_EEVEE_NEXT'):
        try:
            sc.render.engine = eng
            break
        except TypeError:
            pass
    sc.view_settings.view_transform = 'Standard'
    sc.render.resolution_x = sc.render.resolution_y = 1024
    w = bpy.data.worlds.new('W'); sc.world = w; w.use_nodes = True
    bg = w.node_tree.nodes['Background']
    bg.inputs[0].default_value = (0.018, 0.014, 0.016, 1); bg.inputs[1].default_value = 1.0

    def soleil(nom, e, rot_deg, col):
        l = bpy.data.lights.new(nom, 'SUN'); l.energy = e; l.color = col
        o = bpy.data.objects.new(nom, l); sc.collection.objects.link(o)
        o.rotation_euler = tuple(math.radians(a) for a in rot_deg)
    soleil('cle', 3.2, (-50, 0, 145), (1, 0.92, 0.84))
    soleil('remplissage', 0.9, (-70, 0, -150), (0.7, 0.78, 1))
    soleil('contre', 3.0, (60, 0, 20), (1, 0.55, 0.3))
    # lueur du cristal / des fissures
    for pos, e in (((0, 1.1, 0.42), 25), ((0, -1.4, 0.3), 15)):
        l = bpy.data.lights.new('lueur', 'POINT'); l.energy = e; l.color = (1, 0.45, 0.12)
        o = bpy.data.objects.new('lueur', l); sc.collection.objects.link(o); o.location = pos
    # braises (rendu seulement)
    rnd = random.Random(5)
    for i in range(16):
        bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=1, radius=rnd.uniform(0.012, 0.028))
        me = bpy.data.meshes.new('braise'); bm.to_mesh(me); bm.free()
        me.materials.append(materiau('cristal' if i % 3 else 'coeur'))
        o = bpy.data.objects.new('braise', me); sc.collection.objects.link(o)
        o.location = r2b((rnd.uniform(-0.9, 0.9), rnd.uniform(0.85, 2.0), rnd.uniform(-0.6, 0.6)))
    cam = bpy.data.cameras.new('C'); cam.lens = 50
    co = bpy.data.objects.new('C', cam); sc.collection.objects.link(co); sc.camera = co
    # halo (glare) si le compositeur de cette version de Blender le permet
    try:
        ng = bpy.data.node_groups.new('Compo', 'CompositorNodeTree')
        sc.compositing_node_group = ng
        rl = ng.nodes.new('CompositorNodeRLayers')
        gl = ng.nodes.new('CompositorNodeGlare')
        ng.interface.new_socket('Image', in_out='OUTPUT', socket_type='NodeSocketColor')
        out = ng.nodes.new('NodeGroupOutput')
        for k, v in (('Type', 'Fog Glow'), ('Quality', 'High'), ('Threshold', 0.9), ('Size', 0.5), ('Strength', 0.6)):
            if k in gl.inputs:
                try:
                    gl.inputs[k].default_value = v
                except Exception:
                    pass
        ng.links.new(rl.outputs['Image'], gl.inputs['Image'])
        ng.links.new(gl.outputs['Image'], out.inputs[0])
    except Exception as e:
        print('MAGMA_GLARE_ABSENT', e)
    return sc, co


def vue(sc, co, chemin, oeil, cible=(0, 0.42, 0), dist=5.4):
    c = Vector(r2b(cible))
    d = Vector(r2b(oeil)).normalized()
    co.location = c + d * dist
    co.rotation_euler = (c - co.location).to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = chemin
    bpy.ops.render.render(write_still=True)
    print('MAGMA_PNG', chemin)


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    construire_spec()
    ecrire_lua()
    objets = construire_blender()
    nb = sum(tris(o) for n, o in objets.items() if n != 'Racine')
    print('MAGMA_TRIS', nb, 'objets', sorted(objets))
    exporter(objets)
    objets['Racine'].hide_render = True
    sc, co = scene_rendu()
    os.makedirs(os.path.dirname(F_PNG), exist_ok=True)
    vue(sc, co, F_PNG, (-0.5, 0.3, -0.95), dist=5.6)
    extra = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    if extra:
        os.makedirs(extra[0], exist_ok=True)
        for nom, oeil in (('face', (0, 0.1, -1)), ('profil', (1, 0.1, 0)), ('dos', (0.5, 0.3, 1)), ('dessus', (0.2, 1, -0.4))):
            vue(sc, co, os.path.join(extra[0], nom + '.png'), oeil)


main()
