# Seigneur de braise (BOSS d'événement) : démon colossal de roche noire fendue de lave (~25 studs avec les cornes),
# grandes cornes recourbées couleur os brûlé, coeur de magma dans la poitrine, épaules hérissées de pics d'où montent des
# flammes, griffes, queue à pointe de lave. Fissures = briques orange SOLIDES ; seuls yeux / coeur / gueule / pointes de
# flammes brillent (couleurs adoucies). Box rig LihFolk, unités = studs (même chaîne que brute_profondeurs.py).
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mobkit import kf, pose, flame
from mathutils import Vector
S, TAU = math.sin, math.tau

NAME = 'SeigneurBraise'
STUDS = 1.0
PALETTE = dict(R2='564c49', R1='413937', R3='2f2928', R4='1f1a1a',          # roche noire : dessus / principal / côté / dessous
               LV='d9652a', L2='a8431c',                                       # fissures de lave (solides)
               F1='8c3216', F2='c4561f', GL='f08a3c',                          # flammes (GL = lueur)
               HO='6b584a', H2='a8977c', H3='d6c9ad',                          # cornes / griffes
               EY='120c0c', MO='1a0c08', TE='d6c9ad')
GLOW = {'GL'}
NOSTUD = ('EY', 'GL', 'MO', 'TE', 'F1', 'F2', 'H3')
BONES = [('root', (0, 0, 0), (0, 0, 2), None),
         ('hips', (0, 0, 9.4), (0, 0, 10.4), 'root'),
         ('torso', (0, 0, 10.2), (0, 0, 18.2), 'hips'),
         ('head', (0, -1.6, 18.2), (0, -1.6, 21.2), 'torso'),
         ('jaw', (0, -1.2, 18.1), (0, -5.0, 18.1), 'head'),
         ('tail', (0, 2.4, 9.6), (0, 11.5, 3.0), 'hips')]
for sx, s in ((1, 'L'), (-1, 'R')):
    BONES += [(f'arm.{s}', (6.8 * sx, 0, 16.6), (7.1 * sx, 0, 11.2), 'torso'),
              (f'fore.{s}', (7.1 * sx, 0, 11.2), (7.2 * sx, -0.6, 4.6), f'arm.{s}'),
              (f'leg.{s}', (2.8 * sx, 0, 9.4), (2.8 * sx, 0, 0), 'root')]
HEAD = dict(scale=1.2, pivot=(0, -1.6, 18.2), bones=('head', 'jaw'), offset=(0, -0.3, 0.2))


def build(K):
    span, sym = K.span, K.sym
    for sx, s in K.sides():
        P = lambda y0, y1, x0, x1, z0, z1, k, bb: span(y0, y1, x0 * sx, x1 * sx, z0, z1, k, bb)
        # ---- jambes : sabots griffus, tibia, genou de roche, cuisse fendue ----
        b = f'leg.{s}'
        P(-3.0, 2.0, 0.7, 4.9, 0.0, 1.6, 'R4', b)
        for x0 in (0.9, 2.3, 3.7):
            P(-3.9, -3.0, x0, x0 + 1.0, 0.0, 0.9, 'H2', b)
            P(-4.3, -3.9, x0 + 0.2, x0 + 0.8, 0.0, 0.5, 'H3', b)
        P(-2.0, 1.8, 1.1, 4.5, 1.6, 5.2, 'R1', b)
        P(-2.5, -2.0, 1.5, 4.1, 4.1, 6.2, 'R2', b)                  # genou
        P(-2.3, 2.3, 0.7, 4.9, 5.2, 9.8, 'R1', b)                   # cuisse
        P(-2.1, 2.1, 4.9, 5.1, 5.6, 9.4, 'R3', b)
        P(-2.35, -2.3, 2.3, 2.7, 5.6, 7.6, 'LV', b)                 # fissure en zigzag
        P(-2.35, -2.3, 2.7, 3.7, 7.4, 7.8, 'LV', b)
        P(-2.35, -2.3, 3.5, 3.9, 7.8, 9.4, 'L2', b)
        P(-2.05, -2.0, 2.0, 2.4, 2.2, 4.0, 'LV', b)
        # ---- bras : épaulière à pics + flammes, biceps fendu ----
        b = f'arm.{s}'
        P(-3.0, 3.0, 4.8, 9.4, 14.4, 18.8, 'R2', b)
        P(-2.5, 2.5, 5.3, 8.9, 18.8, 19.4, 'R3', b)
        P(-3.05, -3.0, 6.0, 6.4, 14.8, 17.6, 'LV', b)
        P(-3.05, -3.0, 6.4, 8.0, 17.2, 17.6, 'LV', b)
        for base, d, L, w in (((7.0, 0.0, 19.3), (0.35, 0.1, 1), 4.2, 1.6), ((8.8, -1.6, 18.2), (1, -0.4, 0.7), 3.0, 1.2),
                              ((8.8, 1.6, 18.2), (1, 0.4, 0.7), 2.8, 1.1)):
            K.spike((base[0] * sx, base[1], base[2]), (d[0] * sx, d[1], d[2]), L, w, 'R3', 'H2', b)
        flame(K, (5.8 * sx, 1.4, 19.3), 5.0, 2.2, b, keys=('F1', 'F2', 'GL'), lean=(0.1 * sx, 0.3, 0))
        flame(K, (8.2 * sx, 1.9, 18.8), 3.6, 1.6, b, keys=('F1', 'F2', 'GL'), lean=(0.15 * sx, 0.25, 0))
        P(-2.0, 2.0, 5.3, 8.7, 11.0, 14.4, 'R1', b)
        P(-2.05, -2.0, 6.4, 6.8, 11.4, 13.8, 'LV', b)
        # ---- avant-bras, brassard, main griffue ----
        b = f'fore.{s}'
        P(-2.2, 2.2, 5.1, 9.1, 7.0, 11.2, 'R1', b)
        P(-2.5, 2.5, 4.9, 9.3, 9.2, 10.2, 'R3', b)
        P(-2.55, -2.5, 6.6, 7.6, 9.4, 10.0, 'LV', b)
        P(-2.25, -2.2, 7.6, 8.0, 7.4, 9.2, 'LV', b)
        P(-3.0, 2.2, 5.0, 9.2, 4.6, 7.0, 'R2', b)                   # main
        for i in range(4):
            x0 = 5.1 + i * 1.03
            P(-3.6, -2.4, x0, x0 + 0.85, 3.2, 5.0, 'R1', b)         # doigts
            P(-3.9, -2.9, x0 + 0.12, x0 + 0.73, 2.1, 3.2, 'H2', b)  # griffes
            P(-4.2, -3.5, x0 + 0.22, x0 + 0.63, 1.5, 2.1, 'H3', b)
        P(-3.2, -1.2, 4.3, 5.0, 4.0, 6.2, 'R3', b)                  # pouce
        P(-3.6, -3.0, 4.35, 4.95, 3.3, 4.0, 'H2', b)
    # ---- pagne de plaques de roche ----
    span(-2.8, 2.6, -4.8, 4.8, 8.8, 10.4, 'R3', 'hips')
    span(-3.1, -2.8, -1.6, 1.6, 6.2, 10.2, 'R2', 'hips')
    sym(-3.15, -3.1, 0.2, 0.6, 7.0, 7.8, 'LV', 'hips')               # rune en V
    sym(-3.15, -3.1, 0.6, 1.0, 7.8, 9.4, 'LV', 'hips')
    span(-3.15, -3.1, -0.2, 0.2, 6.6, 7.2, 'L2', 'hips')
    sym(-2.9, -2.6, 2.0, 3.8, 7.0, 8.8, 'R2', 'hips')
    # ---- queue en 3 segments, pointe de lave ----
    pts = [Vector((0, 2.4, 9.6)), Vector((0, 6.0, 7.6)), Vector((0, 9.2, 4.8)), Vector((0, 11.6, 3.2))]
    for (a, c), w in zip(zip(pts, pts[1:]), (2.0, 1.5, 1.1)):
        K.limb(a, c, w, w, 'R1', 'tail', extend=0.4)
        K.box(tuple(c), (w * 0.95, w * 0.95, w * 0.6), 'R3', 'tail')
    K.box(tuple(pts[1] + Vector((0, 0, 1.0))), (0.5, 1.4, 0.2), 'LV', 'tail')
    K.spike(tuple(pts[3]), (0, 0.8, -0.2), 2.4, 1.2, 'R3', 'LV', 'tail')
    for p, h in ((pts[0] + Vector((0, 1.6, 1.0)), 1.6), (pts[1] + Vector((0, 0, 0.8)), 1.3)):
        K.spike(tuple(p), (0, 0.3, 1), h, 0.8, 'R3', 'H2', 'tail')
    # ---- torse : taille, abdos fendus, pectoraux, coeur de magma, dos à pics ----
    span(-2.4, 2.2, -4.0, 4.0, 10.2, 12.6, 'R1', 'torso')
    for xs in ((-1.8, -0.15), (0.15, 1.8)):
        for zs in ((10.4, 11.4), (11.6, 12.5)):
            span(-2.65, -2.4, *xs, *zs, 'R2', 'torso')
    span(-2.66, -2.4, -0.15, 0.15, 10.4, 12.6, 'L2', 'torso')
    span(-2.8, 2.6, -4.8, 4.8, 12.4, 12.8, 'R3', 'torso')
    span(-3.4, 3.0, -5.8, 5.8, 12.8, 17.8, 'R1', 'torso')
    sym(-3.95, -3.4, 0.3, 5.2, 14.6, 17.5, 'R2', 'torso')            # pectoraux
    sym(-3.9, -3.4, 0.3, 5.2, 14.2, 14.6, 'R4', 'torso')
    span(-4.0, -3.4, -1.4, 1.4, 13.2, 15.6, 'R4', 'torso')           # cadre du coeur
    span(-4.15, -3.5, -0.9, 0.9, 13.6, 15.2, 'GL', 'torso')          # coeur de magma
    for (x0, x1, z0, z1) in ((1.4, 2.6, 15.0, 15.35), (2.4, 2.75, 15.35, 16.8), (2.75, 4.2, 16.5, 16.85),
                             (-2.4, -1.4, 13.6, 13.95), (-2.75, -2.4, 12.9, 13.95), (-1.3, -0.95, 15.6, 17.4)):
        span(-4.0, -3.95, x0, x1, z0, z1, 'LV', 'torso')            # fissures qui partent du coeur
    span(-1.8, 2.8, -5.0, 5.0, 17.8, 18.9, 'R2', 'torso')            # trapèzes
    span(3.0, 3.5, -5.0, 5.0, 13.2, 17.4, 'R3', 'torso')
    span(3.5, 3.55, -0.3, 0.3, 13.4, 17.2, 'LV', 'torso')
    for z, h in ((17.2, 3.2), (15.2, 2.6), (13.4, 2.0)):
        K.spike((0, 3.4, z), (0, 1, 0.9), h, 1.3, 'R3', 'H2', 'torso')
    flame(K, (0, 2.0, 18.9), 4.0, 2.0, 'torso', keys=('F1', 'F2', 'GL'), lean=(0, 0.35, 0))
    # ---- tête : museau, arcade en V, yeux de braise, grandes cornes recourbées ----
    span(-4.6, -0.8, -2.2, 2.2, 18.4, 21.2, 'R1', 'head')
    span(-4.2, -1.2, -1.8, 1.8, 21.2, 21.7, 'R2', 'head')
    sym(-4.4, -1.0, 2.2, 2.35, 18.6, 20.8, 'R3', 'head')
    span(-5.0, -4.6, -0.5, 0.5, 20.1, 20.9, 'R3', 'head')            # arcade en V
    sym(-5.0, -4.6, 0.5, 1.4, 20.3, 20.9, 'R3', 'head')
    sym(-5.0, -4.6, 1.4, 2.4, 20.6, 21.2, 'R3', 'head')
    sym(-4.65, -4.6, 0.45, 1.85, 19.5, 20.3, 'EY', 'head')           # orbites
    sym(-4.68, -4.62, 0.6, 1.3, 19.6, 19.95, 'GL', 'head')           # yeux en biais
    sym(-4.68, -4.62, 1.3, 1.7, 19.85, 20.15, 'GL', 'head')
    span(-5.4, -4.6, -1.2, 1.2, 18.4, 19.4, 'R2', 'head')            # museau
    sym(-5.45, -5.4, 0.35, 0.75, 18.8, 19.1, 'MO', 'head')           # naseaux
    span(-5.42, -4.6, -1.5, 1.5, 18.1, 18.4, 'MO', 'head')
    span(-5.43, -5.0, -1.0, 1.0, 18.15, 18.35, 'GL', 'head')         # braise dans la gueule
    for sx in (1, -1):
        hp = [Vector((2.0 * sx, -2.6, 20.6)), Vector((4.4 * sx, -2.2, 21.4)), Vector((5.8 * sx, -2.6, 23.2)),
              Vector((5.6 * sx, -4.0, 24.8))]
        for (a, c), w, k in zip(zip(hp, hp[1:]), (1.8, 1.35, 0.95), ('HO', 'H2', 'H3')):
            K.limb(a, c, w, w, k, 'head', extend=0.5)
        K.box(tuple(hp[1] + Vector((0, 0, 0.1))), (1.6, 1.6, 1.6), 'HO', 'head')
        K.spike((1.0 * sx, -3.4, 21.5), (0.3 * sx, 0.2, 1), 1.3, 0.6, 'HO', 'H2', 'head')
    span(-5.4, -0.9, -2.3, 2.3, 16.9, 18.1, 'R3', 'jaw')
    span(-5.5, -5.4, -1.5, 1.5, 17.0, 18.0, 'R4', 'jaw')
    sym(-5.5, -5.1, 0.9, 1.4, 18.1, 18.9, 'TE', 'jaw')               # crocs
    sym(-5.45, -5.2, 1.0, 1.3, 18.9, 19.2, 'TE', 'jaw')
    span(-5.45, -5.0, -0.5, 0.5, 18.1, 18.45, 'TE', 'jaw')
    span(-5.45, -5.4, -0.3, 0.3, 17.2, 17.7, 'LV', 'jaw')


# ---- clips ----
def idle(f):
    ph = TAU * f / 88
    return {'torso': (5 + 2 * S(ph), 0, 0), 'head': (-3 * S(ph), 0, 5 * S(ph / 2)), 'jaw': (4 + 4 * S(ph), 0, 0),
            'arm.L': (-4 * S(ph), -5, 0), 'arm.R': (-4 * S(ph), 5, 0), 'fore.L': (-16, 0, 0), 'fore.R': (-16, 0, 0),
            'hips': (0, 0, 2 * S(ph / 2)), 'tail': (3 * S(ph), 0, 8 * S(ph / 2)), 'root_loc': (0, 0, 0.1 * S(ph))}


def walk(f):    # pas lourd et menaçant, queue qui balance
    ph = TAU * f / 52; c = math.cos(ph)
    return {'root': (0, 4 * S(ph), 3 * c), 'hips': (0, 0, -5 * S(ph)), 'torso': (10, -3 * S(ph), 7 * S(ph)),
            'head': (-6, 3 * S(ph), -6 * S(ph)), 'jaw': (6, 0, 0), 'tail': (4 * c, 0, 12 * S(ph)),
            'leg.L': (-22 * S(ph), 0, 0), 'leg.R': (22 * S(ph), 0, 0),
            'arm.L': (16 * S(ph), -6, 0), 'arm.R': (-16 * S(ph), 6, 0), 'fore.L': (-18 - 8 * S(ph), 0, 0),
            'fore.R': (-18 + 8 * S(ph), 0, 0), 'root_loc': (0, 0, 0.45 * abs(S(ph)))}


def attack(f):  # coup de griffes en revers du bras droit puis écrase le sol du gauche (impacts frames 18 et 34)
    T = {'torso': [(0, (5, 0, 0)), (12, (-6, 0, -24)), (18, (14, 0, 26)), (26, (-10, 0, 10)), (34, (30, 0, 0)),
                   (44, (30, 0, 0)), (62, (5, 0, 0))],
         'head': [(0, (0, 0, 0)), (12, (-10, 0, 10)), (18, (6, 0, -10)), (26, (-14, 0, 0)), (34, (10, 0, 0)), (62, (0, 0, 0))],
         'jaw': [(0, (4, 0, 0)), (12, (26, 0, 0)), (18, (6, 0, 0)), (26, (30, 0, 0)), (34, (6, 0, 0)), (62, (4, 0, 0))],
         'arm.R': [(0, (0, 5, 0)), (12, (-110, 40, 0)), (18, (-70, -30, 0)), (26, (-20, 10, 0)), (62, (0, 5, 0))],
         'fore.R': [(0, (-16, 0, 0)), (12, (-50, 0, 0)), (18, (-10, 0, 0)), (62, (-16, 0, 0))],
         'arm.L': [(0, (0, -5, 0)), (18, (10, -10, 0)), (26, (-170, -10, 0)), (34, (-60, 0, 0)), (44, (-60, 0, 0)),
                   (62, (0, -5, 0))],
         'fore.L': [(0, (-16, 0, 0)), (26, (-40, 0, 0)), (34, (-6, 0, 0)), (62, (-16, 0, 0))],
         'tail': [(0, (0, 0, 0)), (12, (0, 0, 20)), (18, (0, 0, -25)), (34, (-15, 0, 0)), (62, (0, 0, 0))],
         'leg.L': [(0, (0, 0, 0)), (34, (-12, 0, 0)), (62, (0, 0, 0))],
         'leg.R': [(0, (0, 0, 0)), (34, (8, 0, 0)), (62, (0, 0, 0))],
         'root_loc': [(0, (0, 0, 0)), (18, (0, -0.6, 0)), (26, (0, 0.4, 0.3)), (34, (0, -1.0, -0.6)), (44, (0, -1.0, -0.6)),
                      (62, (0, 0, 0))]}
    return pose(f, T)


def roar(f):    # rugissement de feu : tête en arrière, bras ouverts, flammes qui tremblent
    a = kf(f, [(0, 0), (14, 1), (46, 1), (62, 0)])
    sh = S(TAU * f / 6) * (1 if 14 < f < 46 else 0)
    return {'torso': (5 - 18 * a, 0, 0), 'head': (-30 * a + 2 * sh, 0, 0), 'jaw': (4 + 38 * a, 0, 0),
            'arm.L': (-25 * a, -55 * a + 3 * sh, 0), 'arm.R': (-25 * a, 55 * a - 3 * sh, 0),
            'fore.L': (-16 - 50 * a, 0, 0), 'fore.R': (-16 - 50 * a, 0, 0), 'tail': (-20 * a, 0, 6 * sh)}


def hurt(f):
    a = kf(f, [(0, 0), (6, 1), (24, 0)])
    return {'torso': (5 - 14 * a, 0, -6 * a), 'head': (-16 * a, 0, 8 * a), 'jaw': (4 + 18 * a, 0, 0),
            'arm.L': (10 * a, -12 * a, 0), 'arm.R': (10 * a, 12 * a, 0), 'fore.L': (-16, 0, 0), 'fore.R': (-16, 0, 0),
            'tail': (10 * a, 0, -10 * a)}


def death(f):   # tombe à genoux, bras ballants, puis s'effondre en avant
    a = kf(f, [(0, 0), (42, 1), (62, 1)])
    w = kf(f, [(0, 0), (18, 1), (62, 1)])
    return {'root': (80 * a, 0, 0), 'torso': (5 + 12 * w, 0, 0), 'head': (-22 * w, 0, -15 * a), 'jaw': (4 + 28 * w, 0, 0),
            'arm.L': (-55 * w, -30 * w, 0), 'arm.R': (-50 * w, 28 * w, 0), 'fore.L': (-30 * w, 0, 0), 'fore.R': (-25 * w, 0, 0),
            'tail': (-40 * a, 0, 15 * w), 'root_loc': (0, -1.8 * a, 2.6 * a)}


CLIPS = {'Walk': (52, walk), 'Attack': (62, attack), 'Roar': (62, roar), 'Hurt': (24, hurt), 'Death': (62, death),
         'Idle': (88, idle)}   # Idle en dernier = pose des vues
PREVIEW = dict(target=(0, 0, 13.2), ortho=32.0, pitch=10, shots=[('Attack', 12), ('Attack', 34), ('Roar', 30)], loop='Walk')
