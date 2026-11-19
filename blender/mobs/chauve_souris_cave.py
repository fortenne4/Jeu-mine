# Chauve-souris de cave : chauve-souris des mines, fourrure prune, membranes rougeâtres, yeux rouges, éclats d'améthyste
# incrustés dans le dos. Vole en vol stationnaire (~3 studs au-dessus du sol), envergure ~7,5 studs. Box rig LihFolk, unités = studs.
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mobkit import kf, pose, crystal
S, TAU = math.sin, math.tau

NAME = 'ChauveSourisCave'
STUDS = 1.0
PALETTE = dict(F2='7c6579', F1='5e4a5b', F3='443542', W1='934d5e', W2='70394a', WB='2a2026', EP='b06a74',
               AM='d48cff', A2='7a3fb0', GR='ff4b3a', EY='140f12', MO='1e1015', TE='ece6d6')
GLOW = {'GR', 'AM'}
NOSTUD = ('EY', 'GR', 'AM', 'A2', 'MO', 'TE', 'W1', 'W2')
BONES = [('root', (0, 0, 0), (0, 0, 1), None),
         ('body', (0, 0, 3.4), (0, 0, 4.6), 'root'),
         ('head', (0, -0.1, 4.6), (0, -0.1, 5.6), 'body')]
for sx, s in ((1, 'L'), (-1, 'R')):
    BONES += [(f'wing.{s}', (0.55 * sx, 0, 4.5), (2.2 * sx, 0, 4.75), 'body'),
              (f'tip.{s}', (2.2 * sx, 0, 4.75), (3.95 * sx, 0, 4.35), f'wing.{s}')]
HEAD = None


def build(K):
    span, sym = K.span, K.sym
    # ---- corps ----
    span(-0.55, 0.55, -0.6, 0.6, 3.2, 4.6, 'F1', 'body')
    span(-0.62, -0.55, -0.4, 0.4, 3.3, 4.3, 'F2', 'body')
    span(-0.65, 0.6, -0.72, 0.72, 4.35, 4.66, 'F2', 'body')             # collerette de fourrure
    sym(0.55, 0.62, 0.2, 0.5, 3.4, 4.3, 'F3', 'body')
    sym(-0.2, 0.2, 0.18, 0.45, 2.75, 3.2, 'F3', 'body')                 # pattes arrière
    sym(-0.3, -0.12, 0.18, 0.45, 2.62, 2.78, 'WB', 'body')
    span(0.2, 0.5, -0.12, 0.12, 2.8, 3.25, 'F3', 'body')                # queue
    crystal(K, (0, 0.55, 4.1), (0, 1, 0.7), 0.85, 0.36, 'body', keys=('A2', 'AM', 'AM'))
    crystal(K, (0.32, 0.55, 3.7), (0.35, 1, 0.4), 0.55, 0.26, 'body', keys=('A2', 'AM', 'AM'))
    crystal(K, (-0.3, 0.55, 3.85), (-0.35, 1, 0.5), 0.5, 0.24, 'body', keys=('A2', 'AM', 'AM'))
    # ---- tête : grandes oreilles, feuille nasale, crocs ----
    b = 'head'
    span(-0.65, 0.4, -0.6, 0.6, 4.6, 5.4, 'F1', b)
    span(-0.55, 0.3, -0.5, 0.5, 5.4, 5.5, 'F2', b)
    span(-0.9, -0.65, -0.32, 0.32, 4.62, 5.0, 'F2', b)
    span(-0.96, -0.9, -0.12, 0.12, 4.85, 5.18, 'EP', b)                 # feuille nasale
    sym(-0.25, 0.15, 0.28, 0.62, 5.4, 6.2, 'F1', b)                     # oreilles
    sym(-0.28, -0.25, 0.36, 0.54, 5.45, 6.05, 'EP', b)
    sym(-0.12, 0.1, 0.38, 0.56, 6.2, 6.48, 'F3', b)
    sym(-0.67, -0.65, 0.16, 0.5, 4.98, 5.24, 'EY', b)
    sym(-0.69, -0.66, 0.22, 0.45, 5.02, 5.16, 'GR', b)
    sym(-0.69, -0.66, 0.34, 0.47, 5.16, 5.22, 'GR', b)
    span(-0.93, -0.9, -0.26, 0.26, 4.62, 4.68, 'MO', b)
    sym(-0.94, -0.86, 0.1, 0.2, 4.42, 4.64, 'TE', b)
    # ---- ailes : bras + membrane festonnée en bandes, doigts ----
    for sx, s in K.sides():
        b = f'wing.{s}'
        P = lambda y0, y1, x0, x1, z0, z1, k, bb=b: span(y0, y1, x0 * sx, x1 * sx, z0, z1, k, bb)
        K.limb((0.55 * sx, 0, 4.55), (2.2 * sx, 0, 4.8), 0.2, 0.2, 'WB', b)
        for x0, x1, zb, k in ((0.55, 1.0, 3.3, 'W1'), (1.0, 1.5, 3.5, 'W2'), (1.5, 1.9, 3.78, 'W1'), (1.9, 2.2, 4.05, 'W2')):
            P(-0.04, 0.04, x0, x1, zb, 4.7, k)
        b = f'tip.{s}'
        P(-0.12, 0.12, 2.1, 2.3, 4.85, 5.12, 'WB', b)                    # griffe du pouce
        K.limb((2.2 * sx, 0, 4.8), (3.95 * sx, 0, 4.4), 0.15, 0.15, 'WB', b)
        K.limb((2.2 * sx, 0, 4.75), (3.6 * sx, 0, 3.6), 0.12, 0.12, 'WB', b)
        K.limb((2.2 * sx, 0, 4.7), (2.95 * sx, 0, 3.3), 0.12, 0.12, 'WB', b)
        for x0, x1, zb, zt, k in ((2.2, 2.6, 3.75, 4.75, 'W1'), (2.6, 2.95, 3.4, 4.65, 'W1'), (2.95, 3.3, 3.75, 4.56, 'W2'),
                                  (3.3, 3.62, 3.62, 4.48, 'W2'), (3.62, 3.92, 4.0, 4.42, 'W1')):
            P(-0.04, 0.04, x0, x1, zb, zt, k, b)


# ---- clips : battements (ry = monter/descendre l'aile) ----
def _wings(a, t):
    return {'wing.L': (0, a, 0), 'wing.R': (0, -a, 0), 'tip.L': (0, t, 0), 'tip.R': (0, -t, 0)}


def idle(f):    # vol stationnaire
    ph = TAU * f / 16
    p = {'body': (6, 0, 0), 'head': (-4 + 3 * S(ph), 0, 6 * S(TAU * f / 48)), 'root_loc': (0, 0, 0.25 * S(ph - 1.2))}
    p.update(_wings(38 * S(ph), 26 * S(ph - 0.9)))
    return p


def walk(f):    # vol vers l'avant (penché, battements amples)
    ph = TAU * f / 12
    p = {'body': (24, 0, 0), 'head': (-16, 0, 0), 'root_loc': (0, 0, 0.3 * S(ph - 1.2))}
    p.update(_wings(46 * S(ph), 30 * S(ph - 0.9)))
    return p


def attack(f):  # recul puis piqué morsure
    T = {'body': [(0, (6, 0, 0)), (10, (-20, 0, 0)), (16, (40, 0, 0)), (22, (40, 0, 0)), (32, (6, 0, 0))],
         'head': [(0, (-4, 0, 0)), (10, (-20, 0, 0)), (16, (8, 0, 0)), (32, (-4, 0, 0))],
         'root_loc': [(0, (0, 0, 0)), (10, (0, 0.6, 0.6)), (16, (0, -1.6, -0.9)), (22, (0, -1.6, -0.9)), (32, (0, 0, 0))]}
    p = pose(f, T)
    a = kf(f, [(0, 0), (10, -50), (16, 40), (22, 30), (32, 0)])
    p.update(_wings(a, a * 0.5))
    return p


def hurt(f):
    a = kf(f, [(0, 0), (4, 1), (16, 0)])
    p = {'body': (6 - 30 * a, 0, 12 * a), 'head': (-20 * a, 0, 0), 'root_loc': (0, 0.5 * a, 0.3 * a)}
    p.update(_wings(-50 * a, -30 * a))
    return p


def death(f):   # ailes repliées, chute
    a = kf(f, [(0, 0), (8, 1), (40, 1)])
    fall = kf(f, [(0, 0), (8, 0), (30, 1), (40, 1)])
    p = {'body': (6 + 80 * fall, 0, 20 * fall), 'head': (-10 * a, 0, 0), 'root_loc': (0, -1.0 * fall, -3.0 * fall)}
    p.update(_wings(-70 * a, -90 * a))
    return p


CLIPS = {'Walk': (12, walk), 'Attack': (32, attack), 'Hurt': (16, hurt), 'Death': (40, death), 'Idle': (16, idle)}
PREVIEW = dict(target=(0, 0, 3.4), ortho=8.5, pitch=10, shots=[('Idle', 4), ('Attack', 16)], loop='Idle')
