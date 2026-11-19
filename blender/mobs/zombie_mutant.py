# Zombie mutant : mineur difforme (niveau profond), bras gauche monstrueux traîné au sol à éperons d'os, bras droit atrophié,
# excroissances de chair à pustules, tête décentrée à 5 yeux rouges (+ un œil sur l'épaule). ~6,6 studs. Box rig LihFolk.
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mobkit import kf, pose
S, TAU = math.sin, math.tau

NAME = 'ZombieMutant'
STUDS = 1.0
PALETTE = dict(K2='94a67a', K1='768a5f', K3='5a6b48', K4='414d35', VN='8a2f45',
               FL='a85c62', F2='7f3f4a', F3='c47b78', PS='e8a07a',                  # chair mutée + pustules
               OV='4b5f7a', O2='3b4c63', P1='5e4a35', P2='47382a', BT='2a221f', BE='3a291d', BK='9c7a34',
               BN='dcd3be', B2='b3aa94', GR='ff3b30', EY='150d10', MO='2a1216', TE='d8cfb2')
GLOW = {'GR'}
NOSTUD = ('EY', 'GR', 'MO', 'TE')
BONES = [('root', (0, 0, 0), (0, 0, 1), None),
         ('hips', (0, 0, 2.4), (0, 0, 2.8), 'root'),
         ('torso', (0, 0, 2.7), (0, 0, 4.9), 'hips'),
         ('head', (-0.35, -0.5, 4.75), (-0.35, -0.5, 5.7), 'torso'),
         ('jaw', (-0.35, -0.3, 4.95), (-0.35, -1.3, 4.95), 'head'),
         ('arm.L', (2.05, 0, 4.95), (2.3, 0, 3.4), 'torso'),
         ('fore.L', (2.3, 0, 3.4), (2.4, 0, 0.3), 'arm.L'),
         ('arm.R', (-1.6, -0.05, 4.4), (-1.65, -0.05, 2.5), 'torso'),
         ('leg.L', (0.68, 0, 2.4), (0.68, 0, 0), 'root'),
         ('leg.R', (-0.68, 0, 2.4), (-0.68, 0, 0), 'root')]
HEAD = None


def build(K):
    span, sym = K.span, K.sym
    # ---- jambes épaisses ----
    for sx, s in K.sides():
        b = f'leg.{s}'
        P = lambda y0, y1, x0, x1, z0, z1, k: span(y0, y1, x0 * sx, x1 * sx, z0, z1, k, b)
        P(-0.95, 0.55, 0.08, 1.32, 0.0, 0.16, 'BE')
        P(-0.85, 0.5, 0.12, 1.28, 0.16, 0.85, 'BT')
        P(-0.5, 0.5, 0.15, 1.25, 0.85, 1.7, 'OV')
        P(-0.55, 0.55, 0.12, 1.28, 1.7, 2.45, 'OV')
        P(-0.5, 0.5, 1.25, 1.3, 0.9, 2.35, 'O2')
    span(-0.62, -0.2, -0.3, -1.1, 1.25, 1.95, 'FL', 'leg.R')       # excroissance sur la cuisse
    span(-0.68, -0.6, -0.5, -0.8, 1.45, 1.7, 'PS', 'leg.R')
    span(-0.54, -0.5, 0.35, 0.9, 0.9, 1.3, 'K3', 'leg.L')
    # ---- bassin ----
    span(-0.65, 0.6, -1.35, 1.35, 2.35, 2.7, 'BE', 'hips')
    span(-0.69, -0.65, -0.22, 0.22, 2.38, 2.66, 'BK', 'hips')
    # ---- torse en tonneau, salopette tendue, épaule gauche gonflée ----
    span(-0.75, 0.7, -1.45, 1.45, 2.7, 4.8, 'K1', 'torso')
    span(-0.8, -0.75, -0.9, 0.9, 2.7, 3.9, 'OV', 'torso')          # bavette
    span(-0.8, -0.75, -1.45, -0.9, 2.7, 3.2, 'OV', 'torso')
    span(0.7, 0.75, -1.45, 1.45, 2.7, 3.5, 'OV', 'torso')
    sym(-0.84, -0.8, 0.55, 0.75, 3.9, 4.8, 'O2', 'torso')          # bretelles (gauche craquée)
    span(-0.84, -0.8, 0.55, 0.75, 4.55, 4.8, 'K1', 'torso')
    span(-0.82, -0.8, -0.3, -0.05, 3.3, 3.55, 'BK', 'torso')
    span(-0.79, -0.75, 1.0, 1.08, 3.9, 4.7, 'VN', 'torso')
    span(-0.79, -0.75, -1.2, -1.1, 3.3, 4.6, 'VN', 'torso')
    span(-0.65, 0.6, -1.3, 1.3, 4.8, 5.0, 'K2', 'torso')
    span(-0.7, 0.85, 0.4, 1.95, 4.6, 5.65, 'FL', 'torso')          # bosse de chair sur l'épaule gauche
    span(-0.6, 0.7, 0.55, 1.7, 5.65, 5.95, 'F3', 'torso')
    span(-0.75, -0.7, 0.95, 1.45, 5.0, 5.4, 'EY', 'torso')         # œil d'épaule
    span(-0.77, -0.75, 1.02, 1.36, 5.08, 5.3, 'GR', 'torso')
    for c, sz, k in (((0.55, 0.95, 3.9), (0.55, 1.0, 0.9), 'FL'), ((-0.5, 0.9, 3.3), (0.45, 0.8, 0.7), 'F2'),
                     ((0.1, 1.0, 4.6), (0.4, 0.6, 0.6), 'FL'), ((-0.9, 0.85, 4.1), (0.3, 0.5, 0.5), 'F3')):
        K.box(c, sz, k, 'torso')                                   # excroissances du dos (centre x, y, z)
    for p in ((0.4, 1.25, 4.15), (-0.6, 1.2, 3.55), (0.25, 1.38, 4.7), (1.3, 0.9, 5.3)):
        K.box(p, (0.22, 0.12, 0.22), 'PS', 'torso')
    # ---- tête décentrée, 5 yeux, mâchoire lourde ----
    b = 'head'
    span(-1.35, 0.1, -1.05, 0.35, 5.05, 5.85, 'K1', b)
    span(-1.2, 0.0, -0.9, 0.2, 5.85, 6.0, 'K2', b)
    span(-1.0, -0.2, 0.35, 0.55, 5.2, 5.8, 'FL', b)                 # tumeur latérale
    span(-0.8, -0.4, 0.55, 0.62, 5.35, 5.6, 'PS', b)
    span(-1.38, -1.35, -0.95, -0.1, 5.25, 5.55, 'EY', b)
    span(-1.4, -1.37, -0.85, -0.62, 5.3, 5.48, 'GR', b)             # œil droit
    span(-1.4, -1.37, -0.4, -0.2, 5.32, 5.46, 'GR', b)              # œil gauche
    span(-1.38, -1.35, -0.62, -0.18, 5.6, 5.85, 'EY', b)
    span(-1.4, -1.37, -0.55, -0.25, 5.64, 5.8, 'GR', b)             # œil frontal
    span(-1.38, -1.35, 0.0, 0.25, 5.1, 5.3, 'EY', b)
    span(-1.4, -1.37, 0.04, 0.2, 5.14, 5.25, 'GR', b)               # petit œil de joue
    span(-1.38, -1.35, -1.05, -0.92, 5.6, 5.75, 'GR', b)
    span(-1.3, -0.2, -0.9, 0.2, 4.95, 5.05, 'MO', b)
    for x0 in (-0.8, -0.5, -0.15):
        span(-1.36, -1.3, x0, x0 + 0.14, 4.95, 5.05, 'TE', b)
    span(-1.45, 0.0, -1.15, 0.45, 4.55, 4.95, 'K3', 'jaw')
    for x0, h in ((-1.0, 0.3), (-0.6, 0.2), (-0.1, 0.25), (0.22, 0.32)):
        span(-1.5, -1.38, x0, x0 + 0.16, 4.95, 4.95 + h, 'TE', 'jaw')
    # ---- bras gauche monstrueux ----
    b = 'arm.L'
    span(-0.95, 0.9, 1.45, 3.1, 3.35, 5.35, 'K1', b)
    span(-0.85, 0.8, 3.1, 3.2, 3.5, 5.1, 'K3', b)
    span(-0.98, -0.95, 1.9, 2.0, 3.5, 5.2, 'VN', b)
    span(-0.98, -0.95, 2.0, 2.7, 4.3, 4.4, 'VN', b)
    span(0.6, 1.2, 1.9, 2.9, 4.0, 5.2, 'FL', b)
    span(1.2, 1.26, 2.2, 2.5, 4.5, 4.75, 'PS', b)
    b = 'fore.L'
    span(-1.1, 1.05, 1.35, 3.35, 1.4, 3.45, 'K1', b)
    span(-1.0, 0.95, 3.35, 3.45, 1.6, 3.3, 'K3', b)
    span(-1.13, -1.1, 1.6, 1.72, 1.6, 3.3, 'VN', b)
    span(-1.25, 1.15, 1.25, 3.45, 0.25, 1.45, 'K3', b)              # poing énorme
    span(-1.25, 1.15, 1.3, 3.4, 0.2, 0.25, 'K4', b)
    for i in range(4):
        span(-1.42, -1.25, 1.35 + i * 0.52, 1.35 + i * 0.52 + 0.42, 0.55, 1.35, 'K1', b)
        span(-1.62, -1.42, 1.45 + i * 0.52, 1.45 + i * 0.52 + 0.22, 0.85, 1.1, 'BN', b)   # griffes de jointure
    for base, d, L, w in (((3.3, 0.3, 2.9), (1, 0.4, 0.5), 1.0, 0.42), ((3.3, -0.2, 2.2), (1, 0.2, 0.2), 0.8, 0.36),
                          ((2.4, 1.0, 3.0), (0.3, 1, 0.4), 0.9, 0.38), ((2.0, 1.0, 2.0), (0.2, 1, 0.1), 0.7, 0.32)):
        K.spike(base, d, L, w, 'B2', 'BN', b)
    # ---- bras droit atrophié ----
    b = 'arm.R'
    span(-0.38, 0.36, -1.42, -1.95, 3.7, 4.5, 'OV', b)
    span(-0.28, 0.26, -1.5, -1.88, 2.55, 3.7, 'K3', b)
    span(-0.32, 0.26, -1.48, -1.9, 2.2, 2.55, 'K4', b)
    for x0 in (-1.55, -1.75):
        span(-0.38, -0.14, x0, x0 - 0.12, 1.9, 2.2, 'BN', b)


# ---- clips ----
def idle(f):
    ph = TAU * f / 70
    tw = 6 * S(TAU * f / 9) * (1 if 30 < f < 40 else 0)          # tic nerveux
    return {'hips': (0, 0, 2 * S(ph)), 'torso': (10 + 3 * S(ph), 3, 4 * S(ph / 2)),
            'head': (4 + 3 * S(ph + 1) + tw, -8, 8 * S(ph / 2) + tw), 'jaw': (8 + 6 * S(2 * ph), 0, 0),
            'arm.L': (-8 + 3 * S(ph), -4, 0), 'fore.L': (-6 + 3 * S(ph + 0.5), 0, 0), 'arm.R': (-25 + 6 * S(ph * 2), 10, 0)}


def walk(f):    # embardée : roulis fort vers le gros bras, poing traîné
    ph = TAU * f / 44; c = math.cos(ph)
    return {'root': (0, 4 + 6 * S(ph), 5 * c), 'hips': (0, 0, -6 * S(ph)), 'torso': (14, 2 - 3 * S(ph), 7 * S(ph)),
            'head': (2, -8 + 5 * S(ph), -6 * c), 'jaw': (10 + 6 * abs(S(ph)), 0, 0),
            'leg.L': (-22 * S(ph), 0, 0), 'leg.R': (22 * S(ph), 0, 0),
            'arm.L': (-6 + 10 * S(ph), -4, 0), 'fore.L': (-4 + 6 * S(ph - 0.6), 0, 0), 'arm.R': (-30 - 12 * S(ph), 10, 0),
            'root_loc': (0, 0, 0.15 * abs(S(ph)))}


def attack(f):  # le gros bras se lève et s'abat
    T = {'torso': [(0, (10, 3, 0)), (16, (-10, -6, 12)), (22, (30, 4, -10)), (30, (30, 4, -10)), (46, (10, 3, 0))],
         'head': [(0, (4, -8, 0)), (16, (-14, -8, 0)), (22, (10, -8, 0)), (46, (4, -8, 0))],
         'jaw': [(0, (8, 0, 0)), (16, (34, 0, 0)), (22, (6, 0, 0)), (46, (8, 0, 0))],
         'arm.L': [(0, (-8, -4, 0)), (16, (-165, -8, 0)), (22, (-60, 0, 0)), (30, (-60, 0, 0)), (46, (-8, -4, 0))],
         'fore.L': [(0, (-6, 0, 0)), (16, (-35, 0, 0)), (22, (-8, 0, 0)), (46, (-6, 0, 0))],
         'arm.R': [(0, (-25, 10, 0)), (16, (5, 25, 0)), (22, (-40, 10, 0)), (46, (-25, 10, 0))],
         'leg.L': [(0, (0, 0, 0)), (22, (-14, 0, 0)), (46, (0, 0, 0))],
         'leg.R': [(0, (0, 0, 0)), (22, (10, 0, 0)), (46, (0, 0, 0))]}
    return pose(f, T)


def hurt(f):
    a = kf(f, [(0, 0), (5, 1), (22, 0)])
    return {'torso': (10 - 20 * a, 3, 10 * a), 'head': (4 - 22 * a, -8, -12 * a), 'jaw': (8 + 25 * a, 0, 0),
            'arm.L': (-8 + 18 * a, -15 * a, 0), 'fore.L': (-6, 0, 0), 'arm.R': (-25 + 30 * a, 30 * a, 0)}


def death(f):   # s'effondre sur le côté du gros bras
    a = kf(f, [(0, 0), (34, 1), (46, 1)])
    w = kf(f, [(0, 0), (12, 1), (46, 1)])
    return {'root': (10 * a, 78 * a, 0), 'torso': (10 + 6 * w, 3, 0), 'head': (4 - 15 * w, -8, 20 * a), 'jaw': (8 + 30 * w, 0, 0),
            'arm.L': (-8 - 30 * w, -50 * w, 0), 'fore.L': (-6 - 20 * w, 0, 0), 'arm.R': (-25 - 40 * w, 30 * w, 0),
            'root_loc': (0.5 * a, 0, 0.6 * a)}


CLIPS = {'Walk': (44, walk), 'Attack': (46, attack), 'Hurt': (22, hurt), 'Death': (46, death), 'Idle': (70, idle)}
PREVIEW = dict(target=(0.4, -0.3, 3.2), ortho=9.0, pitch=10, shots=[('Attack', 16), ('Attack', 23)], loop='Walk')
