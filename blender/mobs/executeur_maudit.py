# Exécuteur maudit : mineur damné (niveau le plus profond), long manteau en lambeaux sous capuche, yeux bandés par des
# talismans (un œil rouge perce la déchirure), bouche cousue, chaînes croisées sur le torse, aura sombre violette aux épaules,
# fendoir maudit dentelé à fissure rouge, couvert de talismans, relié au bras par une chaîne. ~6,3 studs. Box rig LihFolk.
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mobkit import kf, pose, chain, flame
S, TAU = math.sin, math.tau

NAME = 'ExecuteurMaudit'
STUDS = 1.0
PALETTE = dict(K1='6f7d63', K3='56614c', K4='3f4738',
               CO='524862', C3='6c5f80', C4='3a3346', P2='3a3340', BT='221d22', BE='34261c',
               CH='8d8c98', C2='5d5c68', PA='e6dbb4', RM='b3262a',
               AU1='3a1f52', AU2='6b3aa0', AU3='a66be6',
               BL1='2b2730', BL2='4a4553', BL3='77718a', GC='ff3a2e', BN='d8cfb8', WD='3b2a22',
               GR='ff3b30', EY='120c10', MO='1e1015')
GLOW = {'GR', 'GC', 'AU3'}
NOSTUD = ('EY', 'GR', 'GC', 'MO', 'CH', 'C2', 'PA', 'RM', 'AU1', 'AU2', 'AU3', 'BL1', 'BL2', 'BL3')
BONES = [('root', (0, 0, 0), (0, 0, 1), None),
         ('hips', (0, 0, 2.5), (0, 0, 2.8), 'root'),
         ('torso', (0, 0, 2.7), (0, 0, 4.5), 'hips'),
         ('head', (0, -0.25, 4.55), (0, -0.25, 5.6), 'torso'),
         ('arm.L', (1.5, -0.03, 4.3), (1.5, -0.03, 2.0), 'torso'),
         ('arm.R', (-1.5, -0.03, 4.3), (-1.5, -0.03, 1.9), 'torso'),
         ('tool', (-1.5, 0, 1.85), (-1.5, -4.8, 1.85), 'arm.R'),
         ('leg.L', (0.52, 0, 2.5), (0.52, 0, 0), 'root'),
         ('leg.R', (-0.52, 0, 2.5), (-0.52, 0, 0), 'root')]
HEAD = None


def talisman(K, c, h, bone, rot=(0, 0, 0), face='y', sgn=None):
    """Bande de papier + 2 glyphes rouges. face 'y' = posée sur une face avant/arrière, 'x' = sur une face latérale."""
    x, y, z = c
    if sgn is None: sgn = (1 if x > 0 else -1) if face == 'x' else (1 if y > 0 else -1)
    if face == 'y':
        K.box(c, (0.3, 0.03, h), 'PA', bone, rot=rot)
        K.box((x, y + 0.02 * sgn, z + h * 0.18), (0.18, 0.02, 0.05), 'RM', bone, rot=rot)
        K.box((x, y + 0.02 * sgn, z - h * 0.12), (0.05, 0.02, h * 0.35), 'RM', bone, rot=rot)
    else:
        K.box(c, (0.03, 0.3, h), 'PA', bone, rot=rot)
        K.box((x + 0.02 * sgn, y, z + h * 0.18), (0.02, 0.18, 0.05), 'RM', bone, rot=rot)
        K.box((x + 0.02 * sgn, y, z - h * 0.12), (0.02, 0.05, h * 0.35), 'RM', bone, rot=rot)


def build(K):
    span, sym = K.span, K.sym
    # ---- jambes fines ----
    for sx, s in K.sides():
        b = f'leg.{s}'
        P = lambda y0, y1, x0, x1, z0, z1, k: span(y0, y1, x0 * sx, x1 * sx, z0, z1, k, b)
        P(-0.8, 0.45, 0.1, 0.96, 0.0, 0.14, 'BE')
        P(-0.7, 0.42, 0.13, 0.93, 0.14, 0.85, 'BT')
        P(-0.42, 0.42, 0.17, 0.88, 0.85, 2.5, 'P2')
        P(-0.72, -0.7, 0.3, 0.75, 0.55, 0.62, 'C2')               # sangle de botte
    # ---- bassin + pans du manteau (fendu devant) ----
    b = 'hips'
    span(-0.58, 0.52, -1.02, 1.02, 2.3, 2.62, 'BE', b)
    span(0.45, 0.6, -1.08, 1.08, 1.05, 2.62, 'CO', b)
    sym(-0.5, 0.6, 1.0, 1.12, 1.15, 2.62, 'CO', b)
    sym(-0.64, -0.5, 0.62, 1.12, 1.25, 2.62, 'CO', b)
    for x0, z0 in ((-1.05, 0.75), (-0.55, 0.85), (-0.05, 0.7), (0.45, 0.9)):     # bas déchiqueté
        span(0.47, 0.58, x0, x0 + 0.42, z0, 1.05, 'C4', b)
    sym(-0.62, -0.52, 0.7, 1.0, 0.95, 1.25, 'C4', b)
    sym(-0.45, 0.2, 1.02, 1.1, 0.85, 1.15, 'C4', b)
    # ---- torse : manteau, poitrail à nu recousu, chaînes croisées, talismans ----
    b = 'torso'
    span(-0.6, 0.5, -1.05, 1.05, 2.62, 3.6, 'CO', b)
    span(-0.68, 0.48, -1.12, 1.12, 3.6, 4.45, 'CO', b)
    span(-0.62, 0.42, -1.05, 1.05, 4.45, 4.55, 'C3', b)
    sym(-0.72, -0.68, 0.32, 0.62, 2.7, 4.45, 'C3', b)              # revers
    span(-0.7, -0.66, -0.32, 0.32, 3.3, 4.45, 'K1', b)
    span(-0.72, -0.7, -0.03, 0.03, 3.45, 4.3, 'K4', b)              # cicatrice cousue
    for z in (3.55, 3.8, 4.05):
        span(-0.73, -0.7, -0.1, 0.1, z, z + 0.04, 'C2', b)
    chain(K, (0.95, -0.76, 4.35), (-0.95, -0.76, 2.75), 9, b)
    chain(K, (-0.95, -0.76, 4.35), (0.6, -0.76, 3.1), 7, b)
    chain(K, (0.95, 0.55, 4.35), (-0.95, 0.55, 2.75), 9, b)
    talisman(K, (0.75, -0.72, 3.0), 0.6, b, rot=(0, 8, 0))
    talisman(K, (-0.35, 0.53, 3.7), 0.7, b, rot=(0, -6, 0))
    talisman(K, (0.4, 0.53, 3.2), 0.55, b, rot=(0, 10, 0))
    span(-0.55, -0.05, -0.36, 0.36, 4.4, 4.62, 'K3', b)             # cou
    # aura : flammes sombres aux épaules et dans le dos
    for c, h, w, ln in (((1.3, 0.05, 4.35), 1.8, 0.75, (0.14, 0.18, 0)), ((-1.3, 0.05, 4.35), 1.6, 0.7, (-0.14, 0.18, 0)),
                        ((0.45, 0.6, 3.9), 1.4, 0.7, (0.08, 0.25, 0)), ((-0.45, 0.6, 3.6), 1.3, 0.65, (-0.08, 0.25, 0)),
                        ((0.0, 0.75, 4.6), 2.0, 0.8, (0, 0.3, 0))):
        flame(K, c, h, w, b, lean=ln)
    # ---- tête sous capuche : bandeau de talismans, œil rouge, bouche cousue ----
    b = 'head'
    span(-0.95, 0.2, -0.62, 0.62, 4.6, 5.45, 'K1', b)
    span(-1.05, 0.38, -0.76, 0.76, 5.45, 5.68, 'CO', b)
    sym(-1.0, 0.38, 0.62, 0.76, 4.62, 5.45, 'CO', b)
    span(0.2, 0.42, -0.76, 0.76, 4.4, 5.5, 'CO', b)
    span(-1.1, -1.0, -0.78, 0.78, 5.38, 5.62, 'C3', b)
    span(0.35, 0.55, -0.4, 0.4, 5.1, 5.6, 'CO', b)                  # pointe de capuche
    span(0.5, 0.68, -0.22, 0.22, 4.85, 5.35, 'C4', b)
    span(-0.99, -0.95, -0.62, 0.62, 4.98, 5.2, 'PA', b)             # bandeau de talismans
    for x0 in (-0.48, -0.08, 0.5):
        span(-1.0, -0.99, x0, x0 + 0.05, 5.02, 5.16, 'RM', b)
    span(-1.0, -0.99, -0.45, -0.25, 5.08, 5.11, 'RM', b)
    span(-1.0, -0.97, 0.12, 0.42, 4.97, 5.14, 'EY', b)              # déchirure
    span(-1.01, -1.0, 0.18, 0.36, 5.0, 5.11, 'GR', b)               # œil rouge
    talisman(K, (-0.36, -0.98, 4.78), 0.4, b, rot=(0, -6, 0))       # bandes qui pendent
    talisman(K, (0.55, -0.98, 4.8), 0.36, b, rot=(0, 9, 0))
    span(-0.97, -0.95, -0.28, 0.28, 4.74, 4.78, 'MO', b)            # bouche cousue
    for x0 in (-0.22, -0.06, 0.1):
        span(-0.98, -0.95, x0, x0 + 0.04, 4.68, 4.84, 'C2', b)
    # ---- bras gauche : longue main griffue ----
    b = 'arm.L'
    span(-0.4, 0.38, 1.12, 1.86, 2.7, 4.42, 'CO', b)
    span(-0.42, 0.4, 1.1, 1.88, 2.6, 2.75, 'C4', b)
    span(-0.34, 0.3, 1.2, 1.78, 2.15, 2.6, 'K3', b)
    for x0 in (1.22, 1.43, 1.63):
        span(-0.36, -0.1, x0, x0 + 0.12, 1.7, 2.15, 'K4', b)
    talisman(K, (1.88, -0.05, 3.7), 0.6, b, face='x', rot=(-8, 0, 0))
    # ---- bras droit : manche arrachée, chaîne enroulée, poing autour du manche ----
    b = 'arm.R'
    span(-0.4, 0.38, -1.12, -1.88, 3.2, 4.42, 'CO', b)
    span(-0.42, 0.4, -1.15, -1.6, 3.05, 3.2, 'C4', b)
    span(-0.33, 0.31, -1.18, -1.82, 2.1, 3.2, 'K1', b)
    for z in (2.3, 2.55, 2.8):
        span(-0.36, 0.34, -1.15, -1.85, z, z + 0.08, 'CH', b)
    span(-0.35, 0.35, -1.17, -1.83, 1.62, 2.1, 'K3', b)
    span(-0.39, -0.35, -1.22, -1.78, 1.68, 2.04, 'K4', b)
    chain(K, (-1.5, 0.36, 2.3), (-1.5, 0.75, 1.05), 5, b)
    # ---- fendoir maudit ----
    b = 'tool'
    span(-0.95, 0.55, -1.6, -1.4, 1.75, 1.95, 'WD', b)              # manche
    span(-0.7, -0.45, -1.63, -1.37, 1.72, 1.98, 'PA', b)
    span(0.38, 0.52, -1.63, -1.37, 1.72, 1.98, 'PA', b)
    span(0.55, 0.75, -1.66, -1.34, 1.68, 2.02, 'BN', b)             # pommeau
    chain(K, (-1.5, 0.75, 1.75), (-1.5, 0.78, 1.05), 3, b)
    span(-1.12, -0.95, -1.74, -1.26, 1.4, 2.3, 'BN', b)             # garde d'os
    span(-1.08, -0.98, -1.68, -1.32, 2.3, 2.5, 'BN', b)
    span(-1.08, -0.98, -1.68, -1.32, 1.2, 1.4, 'BN', b)
    segs = ((-1.12, -2.1, 1.15, 2.2), (-2.1, -3.1, 1.0, 2.3), (-3.1, -4.1, 0.9, 2.42), (-4.1, -4.6, 1.1, 2.42), (-4.6, -4.88, 1.6, 2.42))
    for y0, y1, z0, z1 in segs:
        span(y0, y1, -1.4, -1.6, z0, z1, 'BL1', b)
        span(y0, y1, -1.43, -1.57, z1, z1 + 0.08, 'BL2', b)        # dos
    for i in range(8):                                              # dents du fil (dessous)
        y = -1.25 - i * 0.44
        zb = next(z0 for y0, y1, z0, z1 in segs if y1 <= y - 0.1 <= y0) if y > -4.6 else 1.1
        span(y - 0.24, y, -1.44, -1.56, zb - 0.22, zb, 'BL3', b)
    for y in (-1.6, -2.9, -3.9):                                    # crocs du dos
        span(y - 0.2, y, -1.45, -1.55, 2.3 if y > -3 else 2.5, (2.3 if y > -3 else 2.5) + 0.2, 'BL3', b)
    for y0, y1, z0, z1 in ((-1.2, -1.9, 1.62, 1.7), (-1.85, -1.95, 1.62, 1.95), (-1.9, -2.8, 1.88, 1.96), (-2.75, -2.85, 1.55, 1.96),
                           (-2.8, -3.7, 1.55, 1.63), (-3.65, -3.75, 1.55, 1.9), (-3.7, -4.4, 1.82, 1.9)):
        span(y0, y1, -1.385, -1.615, z0, z1, 'GC', b)              # fissure rouge (deux faces)
    talisman(K, (-1.385, -2.45, 1.6), 0.6, b, face='x', rot=(-12, 0, 0), sgn=1)
    talisman(K, (-1.615, -3.4, 1.55), 0.65, b, face='x', rot=(10, 0, 0), sgn=-1)


# ---- clips ----
def idle(f):
    ph = TAU * f / 90
    return {'hips': (0, 0, 2 * S(ph)), 'torso': (6 + 2 * S(ph), 0, 3 * S(ph / 2)), 'head': (6 + 2 * S(ph + 1), 0, 12 * S(ph / 2 + 0.5)),
            'arm.L': (-14 + 5 * S(ph), -6, 4 * S(ph + 1)), 'arm.R': (4 + 2 * S(ph + 0.4), 3, 0), 'tool': (4 * S(ph), 0, 0)}


def walk(f):    # marche lente, fendoir traîné
    ph = TAU * f / 44; c = math.cos(ph)
    return {'root': (0, 3 * S(ph), 3 * c), 'hips': (0, 0, -4 * S(ph)), 'torso': (8, 0, 5 * S(ph)), 'head': (6, 3 * S(ph), -4 * c),
            'leg.L': (-20 * S(ph), 0, 0), 'leg.R': (20 * S(ph), 0, 0),
            'arm.L': (-14 + 14 * S(ph), -6, 0), 'arm.R': (10 + 3 * S(ph), 3, 0), 'tool': (2 * S(ph), 0, 0),
            'root_loc': (0, 0, 0.1 * abs(S(ph)))}


def attack(f):  # fendoir levé à deux temps puis abattu
    T = {'torso': [(0, (6, 0, 0)), (14, (-8, 0, 10)), (19, (28, 0, -6)), (26, (28, 0, -6)), (40, (6, 0, 0))],
         'head': [(0, (6, 0, 0)), (14, (-8, 0, 0)), (19, (14, 0, 0)), (40, (6, 0, 0))],
         'arm.R': [(0, (4, 3, 0)), (14, (-170, 0, 0)), (19, (-90, 0, 0)), (26, (-90, 0, 0)), (40, (4, 3, 0))],
         'tool': [(0, (0, 0, 0)), (14, (-25, 0, 0)), (19, (70, 0, 0)), (26, (70, 0, 0)), (40, (0, 0, 0))],
         'arm.L': [(0, (-14, -6, 0)), (14, (-60, -30, 0)), (19, (10, -10, 0)), (40, (-14, -6, 0))],
         'leg.L': [(0, (0, 0, 0)), (19, (-14, 0, 0)), (40, (0, 0, 0))],
         'leg.R': [(0, (0, 0, 0)), (19, (10, 0, 0)), (40, (0, 0, 0))]}
    return pose(f, T)


def hurt(f):
    a = kf(f, [(0, 0), (4, 1), (20, 0)])
    return {'torso': (6 - 20 * a, 0, 8 * a), 'head': (6 - 25 * a, 0, -12 * a), 'arm.L': (-14 + 25 * a, -30 * a, 0),
            'arm.R': (4 + 15 * a, 20 * a, 0)}


def death(f):   # tombe à genoux, s'affaisse en avant
    a = kf(f, [(0, 0), (34, 1), (46, 1)])
    w = kf(f, [(0, 0), (14, 1), (46, 1)])
    return {'root': (82 * a, 0, 0), 'torso': (6 + 10 * w, 0, 0), 'head': (6 + 20 * w, 0, -15 * a),
            'arm.L': (-14 - 50 * w, -25 * w, 0), 'arm.R': (4 - 60 * w, 20 * w, 0), 'tool': (30 * w, 0, 0),
            'root_loc': (0, -0.6 * a, 0.4 * a)}


CLIPS = {'Walk': (44, walk), 'Attack': (40, attack), 'Hurt': (20, hurt), 'Death': (46, death), 'Idle': (90, idle)}
PREVIEW = dict(target=(0, -1.2, 3.1), ortho=8.5, pitch=10, shots=[('Attack', 14), ('Attack', 20)], loop='Walk')
