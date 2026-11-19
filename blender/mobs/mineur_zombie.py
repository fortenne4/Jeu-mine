# Mineur zombifié : mineur mort-vivant voûté, casque à lampe cassée, peau verdâtre, vêtements déchirés, petite pioche rouillée.
# Box rig LihFolk (studlib.py). Unités = studs (STUDS = 1), Z haut, devant = -Y, gauche = +X. Hauteur ~5,5 studs (R15).
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mobkit import kf, pose, EASE
S, TAU = math.sin, math.tau

NAME = 'MineurZombie'
STUDS = 1.0
PALETTE = dict(G1='7f9a5a', G2='9db574', G3='627c47', G4='46593a',          # peau : clair / principal / côté / dessous
               S1='5b6d7e', S2='475767', S3='71859a',                          # chemise délavée
               P1='6e5539', P2='54412e', BT='2b2420', BE='3b2a1e', BK='b08a3a',
               H1='c49a34', H2='94732a', H3='dcb854', M1='45464c', LN='a9b6b4', CK='1f1c1c',
               RU='8b4b25', R2='6a361c', R3='a9662f', WD='634429',
               GY='d4f25c', EY='1a1616', MO='2b1717', TE='d3caa6', WU='5a2c2c')
GLOW = {'GY'}
NOSTUD = ('EY', 'GY', 'MO', 'TE', 'LN', 'CK')
BONES = [('root', (0, 0, 0), (0, 0, 1), None),
         ('hips', (0, 0, 2.2), (0, 0, 2.6), 'root'),
         ('torso', (0, 0, 2.45), (0, 0, 4.0), 'hips'),
         ('head', (0, -0.3, 4.0), (0, -0.3, 5.0), 'torso'),
         ('jaw', (0, -0.2, 4.28), (0, -1.0, 4.28), 'head'),
         ('arm.L', (1.42, -0.05, 3.75), (1.42, -0.05, 1.5), 'torso'),
         ('arm.R', (-1.42, -0.05, 3.75), (-1.42, -0.05, 1.5), 'torso'),
         ('tool', (-1.42, 0, 1.7), (-1.42, -1.9, 1.7), 'arm.R'),
         ('leg.L', (0.52, 0, 2.15), (0.52, 0, 0), 'root'),
         ('leg.R', (-0.52, 0, 2.15), (-0.52, 0, 0), 'root')]
HEAD = None


def build(K):
    span, sym = K.span, K.sym
    # ---- jambes + bottes (pantalon déchiré au genou gauche, tibia droit à nu) ----
    for sx, s in K.sides():
        b = f'leg.{s}'
        P = lambda y0, y1, x0, x1, z0, z1, k: span(y0, y1, x0 * sx, x1 * sx, z0, z1, k, b)
        P(-0.8, 0.5, 0.05, 1.0, 0.0, 0.14, 'BE')          # semelle
        P(-0.72, 0.45, 0.08, 0.98, 0.14, 0.72, 'BT')      # botte
        P(-0.8, -0.45, 0.15, 0.9, 0.14, 0.45, 'BT')       # bout
        P(-0.42, 0.42, 0.12, 0.93, 0.72, 1.5, 'P1')       # bas du pantalon
        P(-0.45, 0.45, 0.1, 0.95, 1.5, 2.2, 'P1')         # cuisse
        P(-0.4, 0.4, 0.93, 0.98, 0.8, 2.1, 'P2')          # côté extérieur
        P(0.42, 0.46, 0.2, 0.85, 0.75, 1.3, 'P2')         # arrière genou
    span(-0.47, -0.43, 0.3, 0.75, 1.12, 1.52, 'G1', 'leg.L')        # genou à nu
    span(-0.48, -0.44, 0.25, 0.4, 1.0, 1.12, 'P2', 'leg.L')         # lambeau
    span(-0.48, -0.44, 0.6, 0.78, 1.52, 1.62, 'P2', 'leg.L')
    span(-0.45, -0.41, -0.22, -0.62, 0.72, 1.02, 'G3', 'leg.R')     # tibia à nu
    span(-0.46, -0.42, -0.62, -0.8, 0.72, 0.9, 'P2', 'leg.R')
    # ---- bassin + ceinture ----
    span(-0.5, 0.45, -0.98, 0.98, 1.95, 2.15, 'P1', 'hips')
    span(-0.58, 0.5, -1.02, 1.02, 2.15, 2.45, 'BE', 'hips')
    span(-0.62, -0.58, -0.2, 0.2, 2.18, 2.42, 'BK', 'hips')
    span(0.5, 0.75, 0.3, 0.75, 2.0, 2.5, 'M1', 'hips')              # batterie de lampe (dos)
    # ---- torse voûté, chemise déchirée, bretelles ----
    span(-0.55, 0.5, -1.0, 1.0, 2.45, 3.2, 'S1', 'torso')
    span(-0.72, 0.42, -1.05, 1.05, 3.2, 3.95, 'S1', 'torso')
    span(0.42, 0.62, -0.8, 0.8, 3.25, 3.9, 'S2', 'torso')           # bosse du dos
    span(-0.65, 0.35, -1.0, 1.0, 3.95, 4.05, 'S3', 'torso')         # haut des épaules
    sym(-0.5, 0.4, 1.0, 1.06, 2.5, 3.9, 'S2', 'torso')
    span(-0.76, -0.72, -0.3, 0.3, 3.55, 3.95, 'G1', 'torso')        # col ouvert
    span(-0.76, -0.72, 0.32, 0.78, 2.95, 3.35, 'G3', 'torso')       # trou poitrine
    span(-0.78, -0.75, 0.42, 0.68, 3.05, 3.1, 'G4', 'torso')        # côtes
    span(-0.78, -0.75, 0.42, 0.68, 3.18, 3.23, 'G4', 'torso')
    span(-0.59, -0.55, -0.72, -0.28, 2.5, 2.85, 'G1', 'torso')      # trou ventre
    for x0 in (-0.85, -0.35, 0.3):                                   # ourlet en lambeaux
        span(-0.6, -0.56, x0, x0 + 0.32, 2.25, 2.5, 'S2', 'torso')
    span(0.5, 0.54, -0.6, -0.2, 2.25, 2.5, 'S2', 'torso')
    sym(-0.77, -0.73, 0.45, 0.62, 2.45, 3.95, 'BE', 'torso')        # bretelles
    sym(0.62, 0.66, 0.4, 0.58, 3.3, 3.9, 'BE', 'torso')
    sym(0.5, 0.54, 0.4, 0.58, 2.45, 3.3, 'BE', 'torso')
    span(-0.55, -0.05, -0.38, 0.38, 3.9, 4.15, 'G3', 'torso')       # cou
    # ---- tête (penchée en avant), mâchoire pendante ----
    span(-1.0, 0.25, -0.68, 0.68, 4.35, 4.95, 'G1', 'head')
    sym(-0.9, 0.15, 0.68, 0.72, 4.4, 4.85, 'G3', 'head')
    span(-1.05, -1.0, -0.62, 0.62, 4.68, 4.78, 'G4', 'head')        # arcade
    span(-1.03, -1.0, -0.52, -0.14, 4.45, 4.68, 'EY', 'head')       # orbite droite (grande)
    span(-1.045, -1.03, -0.44, -0.22, 4.5, 4.62, 'GY', 'head')
    span(-1.03, -1.0, 0.15, 0.5, 4.42, 4.62, 'EY', 'head')          # orbite gauche (tombante)
    span(-1.045, -1.03, 0.22, 0.38, 4.45, 4.53, 'GY', 'head')
    span(-1.12, -1.0, -0.08, 0.08, 4.38, 4.56, 'G3', 'head')        # nez
    span(-1.02, -0.98, 0.5, 0.64, 4.62, 4.82, 'WU', 'head')         # plaie
    span(-0.98, -0.2, -0.5, 0.5, 4.27, 4.35, 'MO', 'head')          # bouche
    for x0 in (-0.32, -0.06, 0.2):
        span(-1.0, -0.96, x0, x0 + 0.12, 4.27, 4.35, 'TE', 'head')
    span(-0.95, 0.15, -0.6, 0.6, 4.02, 4.27, 'G3', 'jaw')
    span(-0.97, -0.93, -0.3, -0.18, 4.27, 4.33, 'TE', 'jaw')
    span(-0.97, -0.93, 0.12, 0.24, 4.27, 4.33, 'TE', 'jaw')
    span(-0.9, 0.1, -0.5, 0.5, 3.98, 4.02, 'G4', 'jaw')
    # ---- casque de mineur cabossé, lampe tordue au verre fendu ----
    span(-1.25, 0.5, -0.85, 0.55, 4.85, 4.95, 'H2', 'head')         # bord (encoche arrière gauche)
    span(-1.25, 0.0, 0.55, 0.85, 4.85, 4.95, 'H2', 'head')
    span(-1.05, 0.35, -0.72, 0.72, 4.95, 5.3, 'H1', 'head')
    span(-0.85, 0.15, -0.55, 0.55, 5.3, 5.45, 'H3', 'head')
    span(-0.95, 0.3, -0.1, 0.1, 5.45, 5.52, 'H2', 'head')
    span(-0.65, -0.1, 0.72, 0.76, 5.0, 5.2, 'H2', 'head')           # bosse
    span(-1.12, -1.05, -0.2, 0.2, 4.95, 5.25, 'M1', 'head')         # support
    K.box((0.05, -1.3, 5.1), (0.5, 0.35, 0.42), 'M1', 'head', rot=(0, -16, 0))
    K.box((0.05, -1.485, 5.1), (0.38, 0.04, 0.3), 'LN', 'head', rot=(0, -16, 0))
    K.box((0.04, -1.51, 5.1), (0.4, 0.02, 0.035), 'CK', 'head', rot=(0, 34, 0))
    K.box((0.12, -1.51, 5.06), (0.2, 0.02, 0.03), 'CK', 'head', rot=(0, -58, 0))
    span(0.3, 0.42, -0.08, 0.08, 4.25, 4.9, 'BE', 'head')           # câble
    # ---- bras gauche ballant ----
    b = 'arm.L'
    span(-0.42, 0.38, 1.05, 1.85, 3.15, 3.95, 'S1', b)
    span(-0.44, -0.4, 1.1, 1.4, 3.0, 3.15, 'S2', b)
    span(0.2, 0.4, 1.5, 1.83, 3.0, 3.15, 'S2', b)
    span(-0.35, 0.32, 1.1, 1.78, 1.75, 3.15, 'G1', b)
    span(-0.33, 0.3, 1.78, 1.82, 1.8, 3.1, 'G3', b)
    span(-0.39, -0.35, 1.25, 1.6, 2.0, 2.3, 'WU', b)
    span(-0.38, 0.3, 1.12, 1.76, 1.3, 1.75, 'G3', b)
    for x0 in (1.15, 1.38, 1.6):
        span(-0.36, -0.08, x0, x0 + 0.16, 1.05, 1.3, 'G4', b)
    # ---- bras droit + poing autour du manche ----
    b = 'arm.R'
    span(-0.42, 0.38, -1.85, -1.05, 3.1, 3.95, 'S1', b)
    span(-0.44, -0.4, -1.75, -1.45, 2.95, 3.1, 'S2', b)
    span(-0.35, 0.32, -1.78, -1.1, 1.95, 3.1, 'G1', b)
    span(-0.33, 0.3, -1.82, -1.78, 2.0, 3.05, 'G3', b)
    span(-0.35, 0.35, -1.77, -1.07, 1.45, 1.95, 'G3', b)
    span(-0.39, -0.35, -1.72, -1.12, 1.52, 1.9, 'G4', b)
    # ---- petite pioche rouillée ----
    b = 'tool'
    span(-1.95, 0.45, -1.52, -1.32, 1.6, 1.8, 'WD', b)
    span(-1.5, -1.38, -1.54, -1.3, 1.58, 1.82, 'R2', b)
    span(-2.15, -1.85, -1.56, -1.28, 1.5, 1.92, 'R2', b)            # douille
    span(-2.12, -1.88, -1.53, -1.31, 1.05, 1.5, 'RU', b)            # pic (vers le bas, courbé vers l'avant)
    span(-2.25, -1.97, -1.51, -1.33, 0.78, 1.05, 'RU', b)
    span(-2.36, -2.12, -1.49, -1.35, 0.58, 0.78, 'R3', b)
    span(-2.1, -1.9, -1.52, -1.32, 1.92, 2.22, 'RU', b)             # pointe arrière
    span(-2.05, -1.92, -1.49, -1.35, 2.22, 2.4, 'R3', b)
    span(-2.16, -2.12, -1.5, -1.38, 1.18, 1.34, 'R3', b)            # taches de rouille


# ---- clips (30 fps) : {bone: (rx, ry, rz)}, rx+ = vers l'avant/bas ----
BASE = {'torso': (10, 0, 0), 'head': (6, 0, 0), 'jaw': (8, 0, 0), 'arm.L': (-12, 0, 0), 'arm.R': (-10, 0, 0)}


def idle(f):
    ph = TAU * f / 90
    return {'hips': (0, 0, 2 * S(ph)), 'torso': (10 + 2 * S(ph), 0, 3 * S(ph / 2)),
            'head': (6 + 3 * S(ph + 1), 4 * S(ph / 2), 9 * S(ph / 2 + 0.3)), 'jaw': (8 + 5 * S(2 * ph), 0, 0),
            'arm.L': (-12 + 5 * S(ph), 0, 3 * S(ph + 1)), 'arm.R': (-10 + 3 * S(ph + 0.5), 0, 0), 'tool': (4 * S(ph), 0, 0)}


def walk(f):   # démarche traînante : jambe gauche qui traîne, roulis, tête qui ballotte
    ph = TAU * f / 40; c = math.cos(ph)
    return {'root': (0, 5 * S(ph), 4 * c), 'hips': (0, 0, -6 * S(ph)), 'torso': (14, -3 * S(ph), 6 * S(ph)),
            'head': (5 + 3 * abs(S(ph)), 6 * S(ph), -6 * c), 'jaw': (10 + 6 * abs(S(ph)), 0, 0),
            'leg.L': (-14 * S(ph), 0, 0), 'leg.R': (24 * S(ph), 0, 3),
            'arm.L': (-14 - 16 * S(ph), 0, -4), 'arm.R': (-12 + 14 * S(ph), 0, 0), 'tool': (6 * S(ph), 0, 0),
            'root_loc': (0, 0, 0.12 * abs(S(ph)))}


def attack(f):   # pioche levée au-dessus de la tête -> coup -> retour
    T = {'torso': [(0, (10, 0, 0)), (12, (-4, 0, 8)), (17, (26, 0, -6)), (23, (26, 0, -6)), (36, (10, 0, 0))],
         'head': [(0, (6, 0, 0)), (12, (-10, 0, 0)), (17, (12, 0, 0)), (36, (6, 0, 0))],
         'jaw': [(0, (8, 0, 0)), (12, (28, 0, 0)), (17, (4, 0, 0)), (36, (8, 0, 0))],
         'arm.R': [(0, (-10, 0, 0)), (12, (-170, 0, 0)), (17, (-88, 0, 0)), (23, (-88, 0, 0)), (36, (-10, 0, 0))],
         'tool': [(0, (0, 0, 0)), (12, (-20, 0, 0)), (17, (70, 0, 0)), (23, (70, 0, 0)), (36, (0, 0, 0))],
         'arm.L': [(0, (-12, 0, 0)), (12, (10, -15, 0)), (17, (-30, 0, 0)), (36, (-12, 0, 0))],
         'leg.R': [(0, (0, 0, 0)), (12, (-8, 0, 0)), (17, (12, 0, 0)), (36, (0, 0, 0))]}
    return pose(f, T)


def hurt(f):
    a = kf(f, [(0, 0), (4, 1), (20, 0)])
    return {'torso': (10 - 22 * a, 0, 6 * a), 'head': (6 - 25 * a, 0, -10 * a), 'jaw': (8 + 20 * a, 0, 0),
            'arm.L': (-12 + 20 * a, -25 * a, 0), 'arm.R': (-10 + 20 * a, 25 * a, 0)}


def death(f):    # bascule en arrière
    a = kf(f, [(0, 0), (30, 1), (40, 1)])
    w = kf(f, [(0, 0), (10, 1), (40, 1)])
    return {'root': (-86 * a, 0, 0), 'torso': (10 - 10 * w, 0, 0), 'head': (6 - 20 * w, 0, 18 * a), 'jaw': (8 + 30 * w, 0, 0),
            'arm.L': (-12 - 60 * w, -30 * w, 0), 'arm.R': (-10 - 80 * w, 20 * w, 0), 'leg.L': (-20 * w, 0, 0),
            'root_loc': (0, 0.6 * a, 0.45 * a)}


CLIPS = {'Walk': (40, walk), 'Attack': (36, attack), 'Hurt': (20, hurt), 'Death': (40, death), 'Idle': (90, idle)}   # Idle en dernier = pose des vues
PREVIEW = dict(target=(0, -0.4, 2.75), ortho=7.0, pitch=10, shots=[('Attack', 12), ('Attack', 18)], loop='Walk')
