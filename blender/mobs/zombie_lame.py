# Zombie à bras-lame : mineur muté (niveau profond), le bras droit fendu en une longue lame d'obsidienne à veine violette,
# éperons d'os le long du dos et sur le crâne, bandana en lambeaux, yeux violets. ~6 studs. Box rig LihFolk, unités = studs.
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mobkit import kf, pose
S, TAU = math.sin, math.tau

NAME = 'ZombieLame'
STUDS = 1.0
PALETTE = dict(K2='97a77c', K1='788a64', K3='5c6b4c', K4='434f39', VN='7a3d8f',          # peau corrompue + veines
               S1='4f5d6c', S2='3e4a57', S3='627386', P1='5e4a35', P2='47382a', BT='2a221f', BE='3a291d', BK='9c7a34',
               BD='7a2c30', BN='d9d1bc', B2='b3aa94',
               OB1='231c2c', OB2='372c48', OB3='6a5590', GV='c066ff', EY='140f16', TE='d6cdb0')
GLOW = {'GV'}
NOSTUD = ('EY', 'GV', 'TE', 'OB1', 'OB2', 'OB3')
BONES = [('root', (0, 0, 0), (0, 0, 1), None),
         ('hips', (0, 0, 2.4), (0, 0, 2.7), 'root'),
         ('torso', (0, 0, 2.65), (0, 0, 4.4), 'hips'),
         ('head', (0, -0.35, 4.45), (0, -0.35, 5.4), 'torso'),
         ('jaw', (0, -0.2, 4.72), (0, -1.1, 4.72), 'head'),
         ('arm.L', (1.5, -0.05, 4.1), (1.5, -0.05, 1.8), 'torso'),
         ('arm.R', (-1.55, -0.05, 4.1), (-1.55, -0.05, 2.0), 'torso'),
         ('blade', (-1.55, -0.1, 2.0), (-1.55, -4.7, 2.0), 'arm.R'),
         ('leg.L', (0.56, 0, 2.4), (0.56, 0, 0), 'root'),
         ('leg.R', (-0.56, 0, 2.4), (-0.56, 0, 0), 'root')]
HEAD = None


def build(K):
    span, sym = K.span, K.sym
    # ---- jambes ----
    for sx, s in K.sides():
        b = f'leg.{s}'
        P = lambda y0, y1, x0, x1, z0, z1, k: span(y0, y1, x0 * sx, x1 * sx, z0, z1, k, b)
        P(-0.85, 0.5, 0.05, 1.07, 0.0, 0.15, 'BE')
        P(-0.76, 0.46, 0.08, 1.04, 0.15, 0.8, 'BT')
        P(-0.86, -0.46, 0.15, 0.96, 0.15, 0.48, 'BT')
        P(-0.45, 0.45, 0.12, 1.0, 0.8, 1.65, 'P1')
        P(-0.48, 0.48, 0.1, 1.02, 1.65, 2.42, 'P1')
        P(-0.42, 0.42, 1.0, 1.05, 0.85, 2.3, 'P2')
    span(-0.5, -0.46, 0.3, 0.85, 1.7, 2.25, 'K1', 'leg.L')        # cuisse à nu + veine
    span(-0.52, -0.5, 0.5, 0.58, 1.75, 2.15, 'VN', 'leg.L')
    span(-0.48, -0.44, -0.25, -0.7, 0.82, 1.2, 'BN', 'leg.R')     # tibia d'os
    span(-0.49, -0.45, -0.7, -0.92, 1.2, 1.32, 'P2', 'leg.R')
    # ---- bassin ----
    span(-0.55, 0.5, -1.02, 1.02, 2.15, 2.38, 'P1', 'hips')
    span(-0.62, 0.55, -1.06, 1.06, 2.38, 2.68, 'BE', 'hips')
    span(-0.66, -0.62, -0.2, 0.2, 2.41, 2.65, 'BK', 'hips')
    # ---- torse voûté, chemise arrachée côté lame ----
    span(-0.6, 0.55, -1.05, 1.05, 2.68, 3.5, 'S1', 'torso')
    span(-0.78, 0.45, -1.12, 1.12, 3.5, 4.35, 'S1', 'torso')
    span(-0.7, 0.38, -1.05, 1.05, 4.35, 4.45, 'S3', 'torso')
    sym(-0.55, 0.42, 1.05, 1.12, 2.75, 4.3, 'S2', 'torso')
    span(-0.83, -0.78, -1.1, -0.15, 3.15, 4.3, 'K1', 'torso')      # déchirure : peau
    span(-0.85, -0.83, -0.9, -0.82, 3.3, 4.2, 'VN', 'torso')
    span(-0.85, -0.83, -0.82, -0.4, 3.75, 3.83, 'VN', 'torso')
    span(-0.85, -0.83, -0.6, -0.52, 3.3, 3.75, 'VN', 'torso')
    for x0 in (-0.95, -0.4, 0.35):
        span(-0.65, -0.61, x0, x0 + 0.32, 2.45, 2.7, 'S2', 'torso')
    sym(-0.83, -0.78, 0.45, 0.62, 2.7, 4.35, 'BE', 'torso')        # bretelle (gauche seulement visible à droite = arrachée)
    for i, z in enumerate((2.95, 3.45, 3.95)):                      # éperons d'os sur la colonne
        span(0.45, 0.62 + 0.08 * i, -0.16, 0.16, z, z + 0.35, 'B2', 'torso')
        span(0.62 + 0.08 * i, 0.82 + 0.1 * i, -0.08, 0.08, z + 0.08, z + 0.32, 'BN', 'torso')
    span(-0.6, -0.05, -0.4, 0.4, 4.3, 4.55, 'K3', 'torso')          # cou
    # ---- tête : crâne fendu à crête d'os, yeux violets, bandana ----
    span(-1.1, 0.25, -0.72, 0.72, 4.75, 5.4, 'K1', 'head')
    sym(-1.0, 0.15, 0.72, 0.77, 4.8, 5.3, 'K3', 'head')
    span(-1.15, -1.1, -0.66, 0.66, 5.12, 5.22, 'K4', 'head')
    sym(-1.13, -1.1, 0.14, 0.56, 4.88, 5.12, 'EY', 'head')
    sym(-1.145, -1.13, 0.2, 0.46, 4.92, 5.03, 'GV', 'head')
    sym(-1.145, -1.13, 0.36, 0.52, 5.03, 5.09, 'GV', 'head')
    span(-1.0, 0.15, -0.6, 0.6, 5.4, 5.48, 'K2', 'head')
    span(-0.95, 0.2, -0.1, 0.1, 5.48, 5.66, 'BN', 'head')           # crête
    span(-0.7, -0.5, -0.07, 0.07, 5.66, 5.88, 'BN', 'head')
    span(-0.25, -0.05, -0.07, 0.07, 5.66, 5.82, 'B2', 'head')
    span(-0.6, 0.0, 0.73, 0.79, 5.15, 5.2, 'VN', 'head')            # fêlure
    span(-0.25, -0.2, 0.73, 0.79, 4.95, 5.2, 'VN', 'head')
    span(0.2, 0.34, -0.14, 0.04, 4.25, 4.8, 'BD', 'head')           # pans du bandana
    span(0.2, 0.32, 0.08, 0.24, 4.4, 4.8, 'BD', 'head')
    span(-1.05, 0.15, -0.65, 0.65, 4.45, 4.75, 'K3', 'jaw')
    span(-1.12, 0.2, -0.7, 0.7, 4.5, 4.78, 'BD', 'jaw')             # bandana sur la mâchoire
    span(-1.14, -1.12, -0.3, 0.3, 4.6, 4.66, 'P2', 'jaw')
    # ---- bras gauche griffu ----
    b = 'arm.L'
    span(-0.42, 0.4, 1.12, 1.9, 3.5, 4.35, 'S1', b)
    span(-0.44, -0.4, 1.15, 1.5, 3.35, 3.5, 'S2', b)
    span(-0.36, 0.34, 1.18, 1.84, 2.05, 3.5, 'K1', b)
    span(-0.34, 0.32, 1.84, 1.88, 2.1, 3.4, 'K3', b)
    span(-0.38, -0.36, 1.35, 1.45, 2.2, 3.3, 'VN', b)
    span(-0.38, 0.32, 1.2, 1.82, 1.6, 2.05, 'K3', b)
    for x0 in (1.24, 1.46, 1.66):
        span(-0.42, -0.14, x0, x0 + 0.13, 1.25, 1.6, 'BN', b)
    # ---- bras droit muté : épaule à éperons, veines, gaine d'os ----
    b = 'arm.R'
    span(-0.52, 0.48, -1.12, -2.08, 3.65, 4.5, 'K3', b)
    K.spike((-1.75, 0.1, 4.45), (-0.4, 0.35, 1), 0.85, 0.36, 'B2', 'BN', b)
    K.spike((-1.35, 0.3, 4.45), (-0.1, 0.5, 1), 0.6, 0.28, 'B2', 'BN', b)
    span(-0.42, 0.4, -1.15, -1.98, 2.8, 3.65, 'K1', b)
    span(-0.44, -0.42, -1.4, -1.48, 2.85, 3.6, 'VN', b)
    span(-0.44, -0.42, -1.65, -1.85, 3.2, 3.27, 'VN', b)
    span(-0.45, 0.42, -1.12, -2.0, 2.2, 2.8, 'K4', b)
    span(-0.56, 0.32, -1.07, -2.05, 1.7, 2.22, 'BN', b)             # gaine d'os du poignet
    span(-0.58, -0.56, -1.2, -1.9, 1.78, 1.88, 'B2', b)
    # ---- lame d'obsidienne ----
    b = 'blade'
    span(-0.78, -0.56, -1.3, -1.8, 1.55, 2.4, 'B2', b)              # racine osseuse
    for y0, y1, z0, z1 in ((-0.78, -1.7, 1.45, 2.45), (-1.7, -2.7, 1.55, 2.4), (-2.7, -3.6, 1.68, 2.34), (-3.6, -4.3, 1.82, 2.28),
                           (-4.3, -4.72, 1.96, 2.2)):
        span(y0, y1, -1.45, -1.65, z0, z1, 'OB2', b)
        span(y0, y1, -1.48, -1.62, z0 - 0.1, z0, 'OB3', b)          # fil (dessous)
    span(-0.85, -4.05, -1.435, -1.665, 1.9, 1.97, 'GV', b)          # veine lumineuse, deux faces
    for i in range(6):                                              # dos dentelé
        y = -1.0 - i * 0.55
        top = 2.45 if y > -1.7 else 2.4 if y > -2.7 else 2.34 if y > -3.6 else 2.28
        span(y - 0.28, y, -1.49, -1.61, top, top + 0.16, 'OB1', b)


# ---- clips ----
def idle(f):
    ph = TAU * f / 80
    return {'hips': (0, 0, 2 * S(ph)), 'torso': (12 + 2 * S(ph), 0, 4 * S(ph / 2)), 'head': (4 + 3 * S(ph + 1), 0, 10 * S(ph / 2 + 0.4)),
            'jaw': (4 + 3 * S(2 * ph), 0, 0), 'arm.L': (-10 + 4 * S(ph), 0, 4 * S(ph + 1)), 'arm.R': (-2 + 3 * S(ph + 0.4), 3, 0),
            'blade': (2 * S(ph), 0, 0)}


def walk(f):    # traque : pas réguliers, lame basse en avant
    ph = TAU * f / 36; c = math.cos(ph)
    return {'root': (0, 4 * S(ph), 3 * c), 'hips': (0, 0, -5 * S(ph)), 'torso': (16, -2 * S(ph), 6 * S(ph)),
            'head': (2, 4 * S(ph), -5 * c), 'jaw': (5, 0, 0), 'leg.L': (-24 * S(ph), 0, 0), 'leg.R': (24 * S(ph), 0, 0),
            'arm.L': (-10 + 18 * S(ph), 0, -4), 'arm.R': (-4 - 6 * S(ph), 4, 0), 'blade': (3 * S(ph), 0, 0),
            'root_loc': (0, 0, 0.12 * abs(S(ph)))}


def attack(f):  # armé sur le côté puis fauche horizontale
    T = {'torso': [(0, (12, 0, 0)), (11, (8, 0, -28)), (16, (20, 0, 24)), (22, (20, 0, 24)), (32, (12, 0, 0))],
         'head': [(0, (4, 0, 0)), (11, (-6, 0, 18)), (16, (6, 0, -12)), (32, (4, 0, 0))],
         'jaw': [(0, (4, 0, 0)), (11, (26, 0, 0)), (16, (6, 0, 0)), (32, (4, 0, 0))],
         'arm.R': [(0, (-2, 3, 0)), (11, (-18, 22, -70)), (16, (-16, -8, 42)), (22, (-16, -8, 42)), (32, (-2, 3, 0))],
         'blade': [(0, (0, 0, 0)), (11, (0, 0, -12)), (16, (0, 0, 6)), (32, (0, 0, 0))],
         'arm.L': [(0, (-10, 0, 0)), (11, (-25, -25, 0)), (16, (15, -10, 0)), (32, (-10, 0, 0))],
         'leg.L': [(0, (0, 0, 0)), (16, (-14, 0, 0)), (32, (0, 0, 0))],
         'leg.R': [(0, (0, 0, 0)), (16, (10, 0, 0)), (32, (0, 0, 0))]}
    return pose(f, T)


def hurt(f):
    a = kf(f, [(0, 0), (4, 1), (20, 0)])
    return {'torso': (12 - 24 * a, 0, -8 * a), 'head': (4 - 22 * a, 0, 10 * a), 'jaw': (4 + 20 * a, 0, 0),
            'arm.L': (-10 + 20 * a, -25 * a, 0), 'arm.R': (-2 + 15 * a, 25 * a, 0)}


def death(f):   # tombe à genoux puis en avant, la lame plantée
    a = kf(f, [(0, 0), (32, 1), (42, 1)])
    w = kf(f, [(0, 0), (12, 1), (42, 1)])
    return {'root': (80 * a, 0, 0), 'torso': (12 + 8 * w, 0, 0), 'head': (4 - 25 * w, 0, 15 * a), 'jaw': (4 + 25 * w, 0, 0),
            'arm.L': (-10 - 50 * w, -20 * w, 0), 'arm.R': (-2 - 70 * w, 15 * w, 0), 'blade': (40 * w, 0, 0),
            'root_loc': (0, -0.6 * a, 0.45 * a)}


CLIPS = {'Walk': (36, walk), 'Attack': (32, attack), 'Hurt': (20, hurt), 'Death': (42, death), 'Idle': (80, idle)}
PREVIEW = dict(target=(0, -1.0, 3.0), ortho=8.5, pitch=10, shots=[('Attack', 11), ('Attack', 17)], loop='Walk')
