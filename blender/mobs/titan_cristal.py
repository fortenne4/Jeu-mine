# Titan de cristal (BOSS d'événement) : golem colossal de roche sombre bleutée (~23 studs, ~4,5x un perso R15),
# torse en tonneau, bras-piliers qui touchent presque le sol, poings énormes cerclés de cristaux, coeur de cristal
# violet dans la poitrine, forêt de cristaux violets / bleus dans le dos et en couronne. Attaque : frappe le sol.
# Box rig LihFolk, unités = studs (même chaîne que brute_profondeurs.py).
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mobkit import kf, pose, crystal
S, TAU = math.sin, math.tau

NAME = 'TitanCristal'
STUDS = 1.0
PALETTE = dict(T2='8c92a3', T1='6c7284', T3='555a6a', T4='3a3d49',          # roche bleutée : dessus / principal / côté / dessous
               CR='9b7be0', C2='6a52b8', C3='443a86',                          # cristaux violets (CR = lueur douce)
               CB='5f9ad6', B2='3d6aa8',                                       # cristaux bleus
               VE='7a64c4',                                                    # veines de cristal (solides)
               GO='b39cff', EY='14121c', MO='1c1826', TE='c9c4d6')
GLOW = {'CR', 'CB', 'GO'}
NOSTUD = ('EY', 'GO', 'MO', 'TE', 'CR', 'C2', 'C3', 'CB', 'B2')
BONES = [('root', (0, 0, 0), (0, 0, 2), None),
         ('hips', (0, 0, 8.6), (0, 0, 9.6), 'root'),
         ('torso', (0, 0, 9.4), (0, 0, 18.0), 'hips'),
         ('head', (0, -2.0, 17.6), (0, -2.0, 20.4), 'torso'),
         ('jaw', (0, -1.2, 17.6), (0, -4.8, 17.6), 'head')]
for sx, s in ((1, 'L'), (-1, 'R')):
    BONES += [(f'arm.{s}', (7.6 * sx, 0, 16.6), (7.8 * sx, 0, 10.6), 'torso'),
              (f'fore.{s}', (7.8 * sx, 0, 10.6), (7.9 * sx, 0, 4.0), f'arm.{s}'),
              (f'leg.{s}', (3.0 * sx, 0, 8.4), (3.0 * sx, 0, 0), 'root')]
HEAD = dict(scale=1.3, pivot=(0, -2.0, 17.6), bones=('head', 'jaw'), offset=(0, -0.5, 0.5))


def build(K):
    span, sym = K.span, K.sym
    for sx, s in K.sides():
        P = lambda y0, y1, x0, x1, z0, z1, k, bb: span(y0, y1, x0 * sx, x1 * sx, z0, z1, k, bb)
        # ---- jambes courtes en colonnes, pieds à 3 orteils ----
        b = f'leg.{s}'
        P(-2.9, 2.3, 0.7, 5.3, 0.0, 1.7, 'T4', b)
        for x0 in (0.8, 2.3, 3.8):
            P(-3.8, -2.9, x0, x0 + 1.35, 0.0, 1.25, 'T3', b)
        P(-2.2, 2.0, 1.1, 4.9, 1.7, 4.6, 'T3', b)                   # tibia
        P(-2.7, -2.2, 1.6, 4.4, 3.6, 5.7, 'T2', b)                  # rotule
        P(-2.4, 2.4, 0.8, 5.1, 4.6, 8.9, 'T1', b)                   # cuisse
        P(-2.2, 2.2, 5.1, 5.3, 5.0, 8.4, 'T3', b)
        P(-2.45, -2.4, 2.0, 2.4, 5.2, 7.8, 'VE', b)                 # veine
        P(-2.45, -2.4, 2.4, 3.6, 6.9, 7.3, 'VE', b)
        crystal(K, (4.6 * sx, 1.4, 7.6), (0.7 * sx, 0.5, 0.6), 2.4, 0.9, b, socket='T4')
        # ---- bras : épaulière de roche hérissée de cristaux, biceps ----
        b = f'arm.{s}'
        P(-3.1, 3.1, 5.5, 10.0, 14.6, 19.0, 'T2', b)                # épaule
        P(-2.6, 2.6, 6.0, 9.4, 19.0, 19.6, 'T2', b)
        P(-3.15, -3.1, 6.6, 7.2, 15.2, 18.2, 'VE', b)
        P(-2.3, 2.3, 6.0, 9.5, 10.4, 14.6, 'T1', b)                 # biceps
        P(-2.0, 2.0, 9.5, 9.7, 11.0, 14.0, 'T3', b)
        for base, d, L, w in (((8.3, 0.2, 19.4), (0.6, 0.2, 1), 5.2, 1.7), ((9.6, -1.4, 18.0), (1, -0.3, 0.6), 3.4, 1.2),
                              ((7.0, 1.8, 19.3), (0.2, 0.7, 1), 3.6, 1.2), ((9.7, 1.6, 17.2), (1, 0.5, 0.3), 2.4, 0.9)):
            crystal(K, (base[0] * sx, base[1], base[2]), (d[0] * sx, d[1], d[2]), L, w, b,
                    keys=('C2', 'CR', 'CR') if base[1] < 1 else ('B2', 'CB', 'CB'), socket='T4')
        # ---- avant-bras pilier + poing colossal ----
        b = f'fore.{s}'
        P(-2.8, 2.7, 5.4, 10.2, 6.4, 10.6, 'T1', b)
        P(-2.6, 2.5, 10.2, 10.45, 7.0, 10.2, 'T3', b)
        P(-2.85, -2.8, 6.4, 7.0, 7.2, 9.8, 'VE', b)
        P(-2.85, -2.8, 7.0, 8.6, 9.2, 9.6, 'VE', b)
        P(-3.0, 2.9, 5.0, 10.6, 9.6, 10.4, 'T4', b)                 # bracelet de roche
        P(-3.6, 3.1, 4.8, 10.8, 1.8, 6.4, 'T2', b)                  # poing
        for i in range(4):
            x0 = 5.0 + i * 1.45
            P(-4.3, -3.6, x0, x0 + 1.3, 4.1, 6.1, 'T1', b)          # jointures
            crystal(K, ((x0 + 0.65) * sx, -3.9, 6.1), (0, -0.35, 1), 1.6, 0.75, b, keys=('C2', 'CR', 'CR'))
        P(-4.2, -3.6, 5.0, 10.6, 2.0, 4.1, 'T3', b)                 # doigts repliés
        P(-3.4, -1.0, 4.2, 4.8, 2.8, 5.4, 'T3', b)                  # pouce
        P(-3.4, 3.0, 4.9, 10.7, 1.6, 1.8, 'T4', b)
        crystal(K, (10.6 * sx, 0.2, 4.6), (1, 0.2, 0.35), 2.2, 1.0, b, keys=('B2', 'CB', 'CB'), socket='T4')
    # ---- ceinture de roche ----
    span(-2.9, 2.7, -5.2, 5.2, 7.9, 9.7, 'T4', 'hips')
    span(-3.1, -2.9, -1.6, 1.6, 8.2, 9.5, 'T3', 'hips')
    span(-3.15, -3.1, -0.7, 0.7, 8.5, 9.2, 'VE', 'hips')
    # ---- torse en tonneau : taille, abdos, pectoraux, coeur de cristal, dos ----
    span(-2.8, 2.6, -4.8, 4.8, 9.4, 12.2, 'T1', 'torso')
    for xs in ((-2.2, -0.2), (0.2, 2.2)):
        for zs in ((9.7, 10.8), (11.0, 12.0)):
            span(-3.05, -2.8, *xs, *zs, 'T2', 'torso')
    span(-3.2, 3.0, -5.6, 5.6, 12.0, 12.5, 'T3', 'torso')
    span(-3.5, 3.2, -6.4, 6.4, 12.5, 17.6, 'T1', 'torso')
    sym(-4.1, -3.5, 0.3, 5.8, 14.6, 17.4, 'T2', 'torso')            # pectoraux
    sym(-4.0, -3.5, 0.3, 5.8, 14.2, 14.6, 'T4', 'torso')
    span(-4.25, -3.5, -2.0, 2.0, 12.4, 12.8, 'T4', 'torso')         # cadre du coeur
    span(-4.25, -3.5, -2.0, 2.0, 14.0, 14.6, 'T3', 'torso')
    sym(-4.25, -3.5, 1.4, 2.0, 12.4, 14.6, 'T4', 'torso')
    span(-4.05, -3.5, -1.4, 1.4, 12.8, 14.0, 'CR', 'torso')         # coeur de cristal
    span(-4.15, -4.05, -0.5, 0.5, 13.0, 13.8, 'C3', 'torso')
    span(-4.15, -4.1, 2.4, 2.8, 12.9, 14.2, 'VE', 'torso')          # veines qui partent du coeur
    span(-4.15, -4.1, 2.8, 4.6, 13.8, 14.2, 'VE', 'torso')
    span(-4.15, -4.1, -3.4, -2.4, 13.0, 13.4, 'VE', 'torso')
    span(-2.0, 3.0, -5.2, 5.2, 17.6, 18.8, 'T2', 'torso')            # trapèzes
    span(3.2, 3.7, -5.4, 5.4, 12.8, 17.2, 'T3', 'torso')
    span(3.7, 3.85, -4.0, 4.0, 13.6, 16.6, 'T4', 'torso')
    # ---- forêt de cristaux dans le dos ----
    for base, d, L, w, keys in (((0, 3.5, 16.2), (0, 0.5, 1), 8.0, 2.4, 'v'), ((3.0, 3.4, 15.6), (0.45, 0.6, 1), 6.0, 1.9, 'b'),
                                ((-3.0, 3.4, 15.6), (-0.45, 0.6, 1), 6.0, 1.9, 'b'), ((1.6, 3.8, 13.6), (0.3, 1, 0.8), 4.2, 1.4, 'v'),
                                ((-1.8, 3.8, 13.3), (-0.3, 1, 0.7), 3.8, 1.3, 'v'), ((4.4, 2.4, 18.4), (0.5, 0.3, 1), 3.4, 1.2, 'v'),
                                ((-4.4, 2.6, 18.5), (-0.4, 0.35, 1), 3.0, 1.1, 'v'), ((0, 3.8, 11.6), (0, 1, 0.4), 2.6, 1.0, 'b')):
        crystal(K, base, d, L, w, 'torso', keys=('C2', 'CR', 'CR') if keys == 'v' else ('B2', 'CB', 'CB'), socket='T4')
    # ---- tête enfoncée, arcade lourde, yeux de cristal, couronne ----
    span(-4.7, -0.6, -2.4, 2.4, 17.8, 20.4, 'T1', 'head')
    span(-4.3, -1.0, -2.0, 2.0, 20.4, 20.9, 'T2', 'head')
    sym(-4.5, -1.0, 2.4, 2.55, 18.0, 19.8, 'T3', 'head')
    span(-5.2, -4.7, -2.55, 2.55, 19.3, 20.0, 'T3', 'head')          # arcade
    span(-5.25, -4.7, -0.55, 0.55, 20.0, 20.35, 'T3', 'head')
    sym(-4.75, -4.7, 0.45, 1.9, 18.6, 19.3, 'EY', 'head')            # orbites
    sym(-4.78, -4.72, 0.65, 1.6, 18.75, 19.1, 'GO', 'head')          # yeux
    sym(-4.78, -4.72, 1.2, 1.75, 19.1, 19.25, 'GO', 'head')          # coin extérieur relevé
    span(-5.0, -4.7, -0.45, 0.45, 18.1, 18.8, 'T2', 'head')          # nez
    span(-4.72, -2.0, -1.8, 1.8, 17.6, 17.85, 'MO', 'head')
    for base, d, L, w in (((0, -2.6, 20.8), (0, 0.15, 1), 3.4, 1.15), ((1.6, -2.2, 20.6), (0.4, 0.2, 1), 2.4, 0.9),
                          ((-1.6, -2.2, 20.6), (-0.4, 0.2, 1), 2.4, 0.9), ((0.9, -1.0, 20.7), (0.2, 0.6, 1), 1.8, 0.7),
                          ((-0.9, -1.0, 20.7), (-0.2, 0.6, 1), 1.8, 0.7)):
        crystal(K, base, d, L, w, 'head', socket='T4')
    span(-5.0, -0.8, -2.6, 2.6, 16.2, 17.6, 'T3', 'jaw')
    span(-5.2, -5.0, -1.7, 1.7, 16.3, 17.5, 'T4', 'jaw')
    sym(-5.3, -4.8, 1.1, 1.7, 17.6, 18.4, 'TE', 'jaw')               # crocs
    sym(-5.2, -4.9, 1.25, 1.55, 18.4, 18.7, 'TE', 'jaw')
    span(-5.25, -5.2, -0.6, 0.6, 16.7, 17.2, 'VE', 'jaw')


# ---- clips (mêmes os que la brute, amplitudes de colosse) ----
def idle(f):
    ph = TAU * f / 96
    return {'torso': (3 + 2 * S(ph), 0, 0), 'head': (-2 * S(ph), 0, 4 * S(ph / 2)), 'jaw': (3 + 3 * S(ph), 0, 0),
            'arm.L': (-3 * S(ph), -3, 0), 'arm.R': (-3 * S(ph), 3, 0), 'fore.L': (-10, 0, 0), 'fore.R': (-10, 0, 0),
            'hips': (0, 0, 2 * S(ph / 2)), 'root_loc': (0, 0, 0.08 * S(ph))}


def walk(f):    # pas de colosse : roulis, tangage, bras en balancier
    ph = TAU * f / 56; c = math.cos(ph)
    return {'root': (0, 4 * S(ph), 3 * c), 'hips': (0, 0, -4 * S(ph)), 'torso': (8, -3 * S(ph), 6 * S(ph)),
            'head': (-4, 3 * S(ph), -5 * S(ph)), 'jaw': (4, 0, 0),
            'leg.L': (-20 * S(ph), 0, 0), 'leg.R': (20 * S(ph), 0, 0),
            'arm.L': (14 * S(ph), -4, 0), 'arm.R': (-14 * S(ph), 4, 0), 'fore.L': (-12 - 8 * S(ph), 0, 0),
            'fore.R': (-12 + 8 * S(ph), 0, 0), 'root_loc': (0, 0, 0.45 * abs(S(ph)))}


def attack(f):  # lève les deux poings au-dessus de la tête puis frappe le sol (impact frame 26)
    T = {'torso': [(0, (3, 0, 0)), (20, (-14, 0, 0)), (26, (32, 0, 0)), (40, (32, 0, 0)), (60, (3, 0, 0))],
         'head': [(0, (0, 0, 0)), (20, (-14, 0, 0)), (26, (10, 0, 0)), (60, (0, 0, 0))],
         'jaw': [(0, (3, 0, 0)), (20, (28, 0, 0)), (26, (5, 0, 0)), (60, (3, 0, 0))],
         'arm.L': [(0, (0, -3, 0)), (20, (-165, -10, 0)), (26, (-60, 0, 0)), (40, (-60, 0, 0)), (60, (0, -3, 0))],
         'arm.R': [(0, (0, 3, 0)), (20, (-165, 10, 0)), (26, (-60, 0, 0)), (40, (-60, 0, 0)), (60, (0, 3, 0))],
         'fore.L': [(0, (-10, 0, 0)), (20, (-40, 0, 0)), (26, (-8, 0, 0)), (60, (-10, 0, 0))],
         'fore.R': [(0, (-10, 0, 0)), (20, (-40, 0, 0)), (26, (-8, 0, 0)), (60, (-10, 0, 0))],
         'leg.L': [(0, (0, 0, 0)), (26, (-12, 0, 0)), (60, (0, 0, 0))],
         'leg.R': [(0, (0, 0, 0)), (26, (8, 0, 0)), (60, (0, 0, 0))],
         'root_loc': [(0, (0, 0, 0)), (20, (0, 0.6, 0.3)), (26, (0, -0.8, -0.6)), (40, (0, -0.8, -0.6)), (60, (0, 0, 0))]}
    return pose(f, T)


def roar(f):    # rugissement : tête en arrière, bras écartés, tremble
    a = kf(f, [(0, 0), (14, 1), (48, 1), (64, 0)])
    sh = S(TAU * f / 6) * (1 if 14 < f < 48 else 0)
    return {'torso': (3 - 14 * a, 0, 0), 'head': (-26 * a + 2 * sh, 0, 0), 'jaw': (3 + 34 * a, 0, 0),
            'arm.L': (-30 * a, -45 * a + 3 * sh, 0), 'arm.R': (-30 * a, 45 * a - 3 * sh, 0),
            'fore.L': (-10 - 55 * a, 0, 0), 'fore.R': (-10 - 55 * a, 0, 0)}


def hurt(f):
    a = kf(f, [(0, 0), (6, 1), (26, 0)])
    return {'torso': (3 - 12 * a, 0, -5 * a), 'head': (-14 * a, 0, 7 * a), 'jaw': (3 + 16 * a, 0, 0),
            'arm.L': (10 * a, -8 * a, 0), 'arm.R': (10 * a, 8 * a, 0), 'fore.L': (-10, 0, 0), 'fore.R': (-10, 0, 0)}


def death(f):   # tombe à genoux puis s'écrase face contre terre
    a = kf(f, [(0, 0), (44, 1), (64, 1)])
    w = kf(f, [(0, 0), (18, 1), (64, 1)])
    return {'root': (82 * a, 0, 0), 'torso': (3 + 10 * w, 0, 0), 'head': (-20 * w, 0, -15 * a), 'jaw': (3 + 25 * w, 0, 0),
            'arm.L': (-60 * w, -30 * w, 0), 'arm.R': (-50 * w, 25 * w, 0), 'fore.L': (-30 * w, 0, 0), 'fore.R': (-20 * w, 0, 0),
            'root_loc': (0, -1.8 * a, 2.6 * a)}


CLIPS = {'Walk': (56, walk), 'Attack': (60, attack), 'Roar': (64, roar), 'Hurt': (26, hurt), 'Death': (64, death),
         'Idle': (96, idle)}   # Idle en dernier = pose des vues
PREVIEW = dict(target=(0, 0, 12.5), ortho=31.0, pitch=10, shots=[('Attack', 20), ('Attack', 27), ('Roar', 30)], loop='Walk')
