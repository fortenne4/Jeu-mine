# Brute des profondeurs : colosse de roche vivante (~9,7 studs, ~1,8x un perso R15), torse massif, poings énormes,
# veines de minerai de cuivre, cristaux luminescents qui lui poussent dans le dos. Box rig LihFolk, unités = studs.
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mobkit import kf, pose, crystal
S, TAU = math.sin, math.tau

NAME = 'BruteProfondeurs'
STUDS = 1.0
PALETTE = dict(T2='a09a90', T1='7f7a72', T3='645f59', T4='48443f',          # roche : dessus / principal / côté / dessous
               OR='e08a2e', O2='b8641c',                                       # veines de cuivre (solides)
               CR='6ff0ff', C2='2f9fcf', C3='1f5f86',                          # cristaux (CR = lueur)
               LE='5c3e26', L2='45301e', GO='ffb43a', EY='141212', MO='2a1c18', TE='cfc6ad')
GLOW = {'CR', 'GO'}
NOSTUD = ('EY', 'GO', 'MO', 'TE', 'CR', 'C2')
BONES = [('root', (0, 0, 0), (0, 0, 1), None),
         ('hips', (0, 0, 3.9), (0, 0, 4.5), 'root'),
         ('torso', (0, 0, 4.4), (0, 0, 8.5), 'hips'),
         ('head', (0, -1.0, 8.2), (0, -1.0, 9.6), 'torso'),
         ('jaw', (0, -0.5, 8.2), (0, -2.4, 8.2), 'head')]
for sx, s in ((1, 'L'), (-1, 'R')):
    BONES += [(f'arm.{s}', (3.4 * sx, 0, 7.8), (3.5 * sx, 0, 5.05), 'torso'),
              (f'fore.{s}', (3.5 * sx, 0, 5.05), (3.6 * sx, 0, 2.0), f'arm.{s}'),
              (f'leg.{s}', (1.35 * sx, 0, 3.7), (1.35 * sx, 0, 0), 'root')]
HEAD = None


def build(K):
    span, sym = K.span, K.sym
    for sx, s in K.sides():
        # ---- jambes courtes et massives, pieds à 3 orteils ----
        b = f'leg.{s}'
        P = lambda y0, y1, x0, x1, z0, z1, k, bb=b: span(y0, y1, x0 * sx, x1 * sx, z0, z1, k, bb)
        P(-1.45, 0.95, 0.35, 2.4, 0.0, 0.8, 'T4')
        for x0 in (0.4, 1.07, 1.74):
            P(-1.8, -1.45, x0, x0 + 0.58, 0.0, 0.6, 'T3')
        P(-0.9, 0.9, 0.55, 2.2, 0.8, 2.05, 'T3')                  # tibia
        P(-1.2, -0.9, 0.75, 2.0, 1.75, 2.65, 'T2')                # rotule
        P(-1.05, 1.05, 0.45, 2.3, 2.05, 3.95, 'T1')               # cuisse
        P(-0.95, 0.95, 2.3, 2.42, 2.25, 3.7, 'T3')
        P(-1.1, -1.05, 1.0, 1.28, 2.3, 3.4, 'OR')                 # veine
        P(-1.1, -1.05, 1.28, 1.85, 2.9, 3.12, 'OR')
        # ---- bras : deltoïde, biceps ----
        b = f'arm.{s}'
        P(-1.35, 1.35, 2.6, 4.25, 6.85, 8.6, 'T2', b)
        P(-1.1, 1.1, 2.85, 3.95, 8.6, 8.88, 'T2', b)
        P(-1.4, -1.35, 3.0, 3.3, 7.1, 8.3, 'OR', b)
        P(-1.4, -1.35, 3.3, 3.8, 7.1, 7.32, 'O2', b)
        P(-1.0, 1.0, 2.85, 4.1, 5.0, 6.85, 'T1', b)
        P(-0.9, 0.9, 4.1, 4.2, 5.2, 6.7, 'T3', b)
        # ---- avant-bras épais + poing géant ----
        b = f'fore.{s}'
        P(-1.3, 1.25, 2.7, 4.5, 2.95, 5.1, 'T1', b)
        P(-1.2, 1.15, 4.5, 4.62, 3.2, 4.9, 'T3', b)
        P(-1.35, -1.3, 3.2, 3.5, 3.3, 4.7, 'OR', b)
        P(1.25, 1.3, 3.4, 3.7, 3.4, 4.6, 'O2', b)
        P(-1.6, 1.4, 2.5, 4.78, 0.95, 2.95, 'T2', b)              # poing
        for i in range(4):
            x0 = 2.58 + i * 0.55
            P(-1.85, -1.6, x0, x0 + 0.47, 1.95, 2.85, 'T1', b)    # jointures
        P(-1.8, -1.6, 2.6, 4.7, 1.05, 1.9, 'T3', b)               # doigts repliés
        P(-1.5, -0.4, 2.2, 2.5, 1.55, 2.65, 'T3', b)              # pouce
        P(-1.5, 1.3, 2.6, 4.68, 0.9, 0.95, 'T4', b)
    # ---- pagne de cuir ----
    span(-1.35, 1.25, -2.35, 2.35, 3.6, 4.35, 'L2', 'hips')
    span(-1.45, -1.35, -0.9, 0.9, 2.4, 3.9, 'LE', 'hips')
    span(-1.46, -1.38, -0.9, -0.35, 2.12, 2.4, 'LE', 'hips')
    span(-1.46, -1.38, 0.2, 0.75, 2.2, 2.4, 'LE', 'hips')
    span(1.25, 1.35, -1.0, 1.0, 2.6, 3.9, 'LE', 'hips')
    span(-1.55, -1.35, -0.38, 0.38, 3.65, 4.3, 'O2', 'hips')       # pépite trophée
    span(-1.58, -1.55, -0.2, 0.15, 3.85, 4.12, 'OR', 'hips')
    # ---- torse : taille, abdos, pectoraux, trapèzes, dos ----
    span(-1.3, 1.25, -2.2, 2.2, 4.3, 5.6, 'T1', 'torso')
    for xs in ((-0.98, -0.08), (0.08, 0.98)):
        for zs in ((4.45, 4.95), (5.05, 5.52)):
            span(-1.42, -1.3, *xs, *zs, 'T2', 'torso')
    span(-1.34, -1.3, -1.95, -1.65, 4.4, 5.35, 'OR', 'torso')
    span(-1.5, 1.4, -2.5, 2.5, 5.4, 5.6, 'T3', 'torso')
    span(-1.6, 1.45, -2.8, 2.8, 5.6, 8.0, 'T1', 'torso')
    sym(-1.85, -1.6, 0.1, 2.6, 6.6, 7.9, 'T2', 'torso')
    sym(-1.8, -1.6, 0.1, 2.6, 6.42, 6.6, 'T4', 'torso')
    span(-1.9, -1.85, 1.0, 1.26, 6.9, 7.7, 'OR', 'torso')
    span(-1.9, -1.85, 1.26, 1.95, 7.45, 7.66, 'OR', 'torso')
    span(-1.9, -1.85, -2.2, -1.6, 6.95, 7.15, 'O2', 'torso')
    span(-0.9, 1.35, -2.3, 2.3, 8.0, 8.7, 'T2', 'torso')
    span(1.45, 1.7, -2.4, 2.4, 5.8, 7.9, 'T3', 'torso')
    span(1.7, 1.78, -1.8, 1.8, 6.2, 7.6, 'T4', 'torso')
    # ---- cristaux dans le dos ----
    for base, d, L, w in (((0, 1.65, 7.4), (0, 0.55, 1), 3.4, 1.05), ((1.45, 1.6, 7.1), (0.45, 0.65, 1), 2.5, 0.85),
                          ((-1.45, 1.6, 7.1), (-0.45, 0.65, 1), 2.5, 0.85), ((0.75, 1.75, 6.1), (0.3, 1, 0.8), 1.7, 0.62),
                          ((-0.85, 1.75, 5.9), (-0.3, 1, 0.7), 1.5, 0.58), ((2.2, 1.0, 8.4), (0.5, 0.25, 1), 1.3, 0.5),
                          ((-2.1, 1.1, 8.5), (-0.4, 0.3, 1), 1.0, 0.42)):
        crystal(K, base, d, L, w, 'torso', socket='T4')
    # ---- tête enfoncée, arcade lourde, yeux de braise, crocs inférieurs ----
    span(-2.15, -0.3, -1.05, 1.05, 8.3, 9.45, 'T1', 'head')
    span(-1.95, -0.5, -0.85, 0.85, 9.45, 9.68, 'T2', 'head')
    sym(-2.1, -0.6, 1.05, 1.12, 8.35, 9.1, 'T3', 'head')
    span(-2.38, -2.1, -1.12, 1.12, 8.95, 9.25, 'T3', 'head')       # arcade
    span(-2.4, -2.1, -0.25, 0.25, 9.25, 9.4, 'T3', 'head')
    sym(-2.18, -2.15, 0.22, 0.85, 8.62, 8.95, 'EY', 'head')        # orbites
    sym(-2.2, -2.17, 0.3, 0.72, 8.68, 8.82, 'GO', 'head')          # yeux
    sym(-2.2, -2.17, 0.55, 0.78, 8.82, 8.9, 'GO', 'head')          # coin extérieur relevé
    span(-2.32, -2.15, -0.22, 0.22, 8.42, 8.74, 'T2', 'head')       # nez
    span(-2.16, -1.0, -0.8, 0.8, 8.2, 8.32, 'MO', 'head')
    span(-2.4, -0.4, -1.15, 1.15, 7.55, 8.2, 'T3', 'jaw')
    span(-2.5, -2.4, -0.75, 0.75, 7.6, 8.12, 'T4', 'jaw')
    sym(-2.52, -2.3, 0.5, 0.78, 8.2, 8.62, 'TE', 'jaw')             # crocs
    sym(-2.47, -2.38, 0.56, 0.72, 8.62, 8.75, 'TE', 'jaw')
    span(-2.43, -2.4, -0.3, 0.3, 7.95, 8.2, 'OR', 'jaw')


# ---- clips ----
def idle(f):
    ph = TAU * f / 80
    return {'torso': (3 + 2 * S(ph), 0, 0), 'head': (-2 * S(ph), 0, 5 * S(ph / 2)), 'jaw': (3 + 3 * S(ph), 0, 0),
            'arm.L': (-3 * S(ph), -4, 0), 'arm.R': (-3 * S(ph), 4, 0), 'fore.L': (-12, 0, 0), 'fore.R': (-12, 0, 0),
            'hips': (0, 0, 2 * S(ph / 2))}


def walk(f):    # pas lourd : roulis, tangage, bras en balancier
    ph = TAU * f / 44; c = math.cos(ph)
    return {'root': (0, 5 * S(ph), 4 * c), 'hips': (0, 0, -5 * S(ph)), 'torso': (7, -3 * S(ph), 7 * S(ph)),
            'head': (-3, 3 * S(ph), -6 * S(ph)), 'jaw': (4, 0, 0),
            'leg.L': (-22 * S(ph), 0, 0), 'leg.R': (22 * S(ph), 0, 0),
            'arm.L': (16 * S(ph), -5, 0), 'arm.R': (-16 * S(ph), 5, 0), 'fore.L': (-14 - 8 * S(ph), 0, 0),
            'fore.R': (-14 + 8 * S(ph), 0, 0), 'root_loc': (0, 0, 0.22 * abs(S(ph)))}


def attack(f):  # double coup de poing au sol
    T = {'torso': [(0, (3, 0, 0)), (16, (-12, 0, 0)), (21, (30, 0, 0)), (30, (30, 0, 0)), (48, (3, 0, 0))],
         'head': [(0, (0, 0, 0)), (16, (-14, 0, 0)), (21, (10, 0, 0)), (48, (0, 0, 0))],
         'jaw': [(0, (3, 0, 0)), (16, (30, 0, 0)), (21, (5, 0, 0)), (48, (3, 0, 0))],
         'arm.L': [(0, (0, -4, 0)), (16, (-165, -10, 0)), (21, (-62, 0, 0)), (30, (-62, 0, 0)), (48, (0, -4, 0))],
         'arm.R': [(0, (0, 4, 0)), (16, (-165, 10, 0)), (21, (-62, 0, 0)), (30, (-62, 0, 0)), (48, (0, 4, 0))],
         'fore.L': [(0, (-12, 0, 0)), (16, (-40, 0, 0)), (21, (-10, 0, 0)), (48, (-12, 0, 0))],
         'fore.R': [(0, (-12, 0, 0)), (16, (-40, 0, 0)), (21, (-10, 0, 0)), (48, (-12, 0, 0))],
         'leg.L': [(0, (0, 0, 0)), (21, (-10, 0, 0)), (48, (0, 0, 0))],
         'leg.R': [(0, (0, 0, 0)), (21, (8, 0, 0)), (48, (0, 0, 0))]}
    return pose(f, T)


def roar(f):    # rugissement : tête en arrière, bras écartés
    a = kf(f, [(0, 0), (12, 1), (40, 1), (54, 0)])
    sh = S(TAU * f / 6) * (1 if 12 < f < 40 else 0)
    return {'torso': (3 - 12 * a, 0, 0), 'head': (-24 * a + 2 * sh, 0, 0), 'jaw': (3 + 36 * a, 0, 0),
            'arm.L': (-20 * a, -40 * a + 3 * sh, 0), 'arm.R': (-20 * a, 40 * a - 3 * sh, 0),
            'fore.L': (-12 - 50 * a, 0, 0), 'fore.R': (-12 - 50 * a, 0, 0)}


def hurt(f):
    a = kf(f, [(0, 0), (5, 1), (22, 0)])
    return {'torso': (3 - 14 * a, 0, -6 * a), 'head': (-14 * a, 0, 8 * a), 'jaw': (3 + 18 * a, 0, 0),
            'arm.L': (10 * a, -10 * a, 0), 'arm.R': (10 * a, 10 * a, 0), 'fore.L': (-12, 0, 0), 'fore.R': (-12, 0, 0)}


def death(f):   # tombe à genoux puis face contre terre
    a = kf(f, [(0, 0), (34, 1), (50, 1)])
    w = kf(f, [(0, 0), (14, 1), (50, 1)])
    return {'root': (84 * a, 0, 0), 'torso': (3 + 10 * w, 0, 0), 'head': (-20 * w, 0, -15 * a), 'jaw': (3 + 25 * w, 0, 0),
            'arm.L': (-60 * w, -30 * w, 0), 'arm.R': (-50 * w, 25 * w, 0), 'fore.L': (-30 * w, 0, 0), 'fore.R': (-20 * w, 0, 0),
            'root_loc': (0, -0.8 * a, 1.3 * a)}


CLIPS = {'Walk': (44, walk), 'Attack': (48, attack), 'Roar': (54, roar), 'Hurt': (22, hurt), 'Death': (50, death),
         'Idle': (80, idle)}   # Idle en dernier = pose des vues
PREVIEW = dict(target=(0, 0, 5.0), ortho=12.5, pitch=10, shots=[('Attack', 16), ('Attack', 22), ('Roar', 24)], loop='Walk')
