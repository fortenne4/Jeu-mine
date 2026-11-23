# Reine araignée (BOSS d'événement) : araignée géante des galeries, carapace noir-violacé, abdomen énorme marqué d'un
# sablier rouge sombre, 8 yeux rouges, crochets d'ivoire, 8 pattes coudées dont les genoux montent à ~16 studs.
# ~20 studs de haut, ~30 studs d'envergure. Box rig LihFolk, unités = studs (même chaîne que rampant_galeries.py).
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mobkit import kf, pose
from mathutils import Vector
S, TAU = math.sin, math.tau

NAME = 'ReineAraignee'
STUDS = 1.0
PALETTE = dict(K2='584e64', K1='3e3748', K3='2d2935', K4='1e1b23',          # carapace : dessus / principal / côté / dessous
               PO='6e607e',                                                    # reflets / poils
               MK='a3302b', M2='6e2020',                                       # marques rouge sombre (solides)
               RE='c8352c', EY='120c10', MO='1a0e12', FA='2a2024', TE='d8cfbd', WB='b9b3c2')
GLOW = {'RE'}
NOSTUD = ('EY', 'RE', 'MO', 'TE', 'FA', 'WB')
HIPY = (-6.4, -4.6, -2.8, -1.0)
KNEE = ((8.2, -11.5), (9.6, -6.6), (9.6, -0.6), (8.4, 4.6))     # (x, y) des genoux, z = 16
FOOT = ((12.6, -17.0), (15.2, -8.2), (15.2, 2.0), (12.8, 10.6))  # (x, y) des pieds, z = 0
BONES = [('root', (0, 0, 0), (0, 0, 2), None),
         ('body', (0, 0.5, 9), (0, -6.5, 9), 'root'),
         ('head', (0, -7.0, 9), (0, -11.5, 9), 'body'),
         ('fang.L', (1.3, -11.2, 7.6), (1.3, -12.2, 4.8), 'head'),
         ('fang.R', (-1.3, -11.2, 7.6), (-1.3, -12.2, 4.8), 'head'),
         ('abdo', (0, 0.8, 10.5), (0, 14, 14), 'body')]
for i in range(4):
    for sx, s in ((1, 'L'), (-1, 'R')):
        BONES.append((f'leg{i}.{s}', (3.4 * sx, HIPY[i], 9.0), (KNEE[i][0] * sx, KNEE[i][1], 16.0), 'body'))
        BONES.append((f'tib{i}.{s}', (KNEE[i][0] * sx, KNEE[i][1], 16.0), (FOOT[i][0] * sx, FOOT[i][1], 0.0), f'leg{i}.{s}'))
HEAD = None


def build(K):
    span, sym = K.span, K.sym
    # ---- céphalothorax ----
    b = 'body'
    span(-7.5, 0.4, -4.0, 4.0, 6.6, 10.6, 'K1', b)
    span(-7.2, 0.0, -3.4, 3.4, 6.0, 6.6, 'K4', b)
    span(-7.0, -0.3, -3.3, 3.3, 10.6, 11.5, 'K2', b)
    span(-6.2, -1.0, -0.6, 0.6, 11.5, 12.0, 'PO', b)
    sym(-7.3, 0.2, 4.0, 4.25, 7.0, 10.2, 'K3', b)
    for y0 in (-5.6, -3.6, -1.6):                                    # sillons de la carapace
        sym(y0, y0 + 0.35, 1.2, 3.3, 11.5, 11.6, 'K3', b)
    span(-7.55, -7.5, -1.2, 1.2, 9.4, 10.2, 'MK', b)
    # ---- tête : 8 yeux rouges, palpes, crochets ----
    b = 'head'
    span(-11.0, -7.5, -3.0, 3.0, 6.8, 11.0, 'K1', b)
    span(-10.6, -7.6, -2.5, 2.5, 11.0, 11.8, 'K2', b)
    sym(-10.8, -7.6, 3.0, 3.2, 7.2, 10.6, 'K3', b)
    span(-11.05, -11.0, -2.6, 2.6, 8.3, 10.9, 'EY', b)
    sym(-11.1, -11.04, 0.35, 1.35, 9.35, 10.4, 'RE', b)              # 2 grands yeux
    sym(-11.1, -11.04, 1.65, 2.3, 9.7, 10.25, 'RE', b)               # 2 moyens
    sym(-11.1, -11.04, 0.55, 1.05, 8.6, 9.0, 'RE', b)                # 2 petits
    sym(-10.4, -9.7, 0.6, 1.3, 11.8, 11.95, 'RE', b)                 # 2 sur le dessus
    span(-11.2, -11.0, -3.0, 3.0, 10.9, 11.4, 'K3', b)               # arcade
    span(-11.05, -11.0, -1.4, 1.4, 7.1, 8.1, 'MO', b)
    for sx, s in K.sides():                                           # palpes
        P = lambda y0, y1, x0, x1, z0, z1, k: span(y0, y1, x0 * sx, x1 * sx, z0, z1, k, 'head')
        P(-12.4, -10.6, 2.3, 3.2, 7.4, 8.3, 'K2')
        P(-13.4, -12.4, 2.4, 3.1, 6.4, 7.6, 'K1')
        P(-13.7, -13.2, 2.5, 3.0, 5.8, 6.4, 'K4')
        b = f'fang.{s}'
        P = lambda y0, y1, x0, x1, z0, z1, k: span(y0, y1, x0 * sx, x1 * sx, z0, z1, k, b)
        P(-12.2, -10.9, 0.3, 2.2, 6.6, 8.4, 'K2')                    # chélicère
        P(-12.15, -11.0, 0.4, 2.1, 6.0, 6.6, 'K3')
        P(-12.6, -11.6, 0.8, 1.8, 4.9, 6.0, 'FA')                    # crochet
        P(-12.9, -12.1, 0.95, 1.6, 4.1, 4.9, 'TE')
        P(-13.1, -12.6, 1.05, 1.45, 3.7, 4.1, 'TE')
    # ---- abdomen énorme ----
    b = 'abdo'
    span(2.0, 12.0, -4.6, 4.6, 7.3, 8.2, 'K4', b)                 # abdomen en oeuf, par paliers
    span(1.0, 13.0, -6.0, 6.0, 8.2, 9.4, 'K3', b)
    span(0.4, 13.6, -7.0, 7.0, 9.4, 15.6, 'K1', b)
    span(2.0, 12.0, -7.6, 7.6, 10.4, 14.6, 'K1', b)
    sym(3.0, 11.0, 7.6, 7.7, 11.0, 14.0, 'K3', b)
    span(1.0, 13.0, -6.0, 6.0, 15.6, 17.2, 'K1', b)
    span(2.4, 11.6, -4.6, 4.6, 17.2, 18.4, 'K2', b)
    span(4.0, 10.0, -2.8, 2.8, 18.4, 19.2, 'K2', b)
    span(13.6, 14.4, -5.0, 5.0, 10.0, 15.0, 'K3', b)
    span(14.4, 15.0, -3.0, 3.0, 11.0, 14.0, 'K4', b)
    span(-0.2, 0.4, -4.2, 4.2, 9.6, 15.0, 'K3', b)
    for y0 in (1.6, 4.2, 6.8, 9.4):                                   # reflets violets en bandes
        sym(y0, y0 + 1.2, 4.6, 6.0, 17.2, 17.3, 'PO', b)
    span(15.0, 15.6, -1.1, 1.1, 10.6, 12.0, 'K4', b)                 # filières
    span(15.6, 15.8, -0.5, 0.5, 10.9, 11.6, 'WB', b)
    # sablier rouge sur le dos
    span(4.2, 5.4, -2.4, 2.4, 19.2, 19.3, 'MK', b)
    span(5.4, 6.4, -1.4, 1.4, 19.2, 19.3, 'MK', b)
    span(6.4, 7.6, -0.5, 0.5, 19.2, 19.3, 'MK', b)
    span(7.6, 8.6, -1.4, 1.4, 19.2, 19.3, 'MK', b)
    span(8.6, 9.8, -2.4, 2.4, 19.2, 19.3, 'MK', b)
    span(10.0, 10.1, -2.4, 2.4, 18.0, 19.0, 'M2', b)                  # bord arrière du sablier
    span(3.9, 4.0, -2.4, 2.4, 18.0, 19.0, 'M2', b)
    for y0 in (3.4, 6.2, 9.0):                                       # chevrons latéraux
        sym(y0 + 0.6, y0 + 2.2, 7.0, 7.61, 12.2, 12.6, 'MK', b)
    for y in (2.4, 5.0, 8.4, 11.0):                                  # épines
        for sx in (1, -1):
            K.spike((4.6 * sx, y + 0.4, 17.0), (0.5 * sx, 0.2, 1), 2.2, 0.8, 'K3', 'PO', b)
    K.spike((0, 12.4, 16.8), (0, 0.6, 1), 2.6, 0.9, 'K3', 'PO', b)
    # ---- 8 pattes : fémur vers le haut (genou haut), tibia en 2 segments vers le sol ----
    for i in range(4):
        for sx, s in K.sides():
            hip = Vector((3.4 * sx, HIPY[i], 8.6)); knee = Vector((KNEE[i][0] * sx, KNEE[i][1], 16.0))
            foot = Vector((FOOT[i][0] * sx, FOOT[i][1], 0.2)); mid = knee + (foot - knee) * 0.48
            b = f'leg{i}.{s}'
            K.box(tuple(hip), (1.8, 1.8, 1.6), 'K3', b)
            K.limb(hip, knee, 1.45, 1.45, 'K1', b)
            K.box(tuple(hip + (knee - hip) * 0.55 + Vector((0, 0, 0.8))), (0.5, 0.5, 0.8), 'PO', b)
            b = f'tib{i}.{s}'
            K.box(tuple(knee), (1.75, 1.75, 1.5), 'K2', b)
            K.box(tuple(knee + Vector((0, 0, -0.95))), (1.55, 1.55, 0.4), 'MK', b)
            K.limb(knee, mid, 1.15, 1.15, 'K1', b)
            K.box(tuple(mid), (1.25, 1.25, 0.9), 'K3', b)
            K.box(tuple(mid + Vector((0, 0, -0.6))), (1.0, 1.0, 0.3), 'MK', b)
            K.limb(mid, foot, 0.85, 0.85, 'K1', b, extend=0.1)
            K.box(tuple(foot + Vector((0, 0, 0.25))), (0.9, 0.9, 0.6), 'K4', b)


# ---- clips ----
LG = [f'leg{i}.{s}' for i in range(4) for s in 'LR']


def _legs(lift, swing, curl=None):
    """lift/swing/curl par patte (clé 'leg<i>.<s>') -> rotations fémur (ry = lever, rz = avant/arrière) + tibia replié"""
    out = {}
    curl = curl or {}
    for i in range(4):
        for sx, s in ((1, 'L'), (-1, 'R')):
            n = f'leg{i}.{s}'
            out[n] = (0, -sx * lift.get(n, 0), sx * swing.get(n, 0))
            out[f'tib{i}.{s}'] = (0, sx * curl.get(n, 0), 0)
    return out


def idle(f):
    ph = TAU * f / 72
    p = {'body': (2 * S(ph), 0, 0), 'head': (-3 * S(ph + 1), 0, 5 * S(ph / 2)), 'abdo': (-3 * S(ph + 0.6), 0, 3 * S(ph / 2)),
         'fang.L': (6 + 6 * S(2 * ph), -6 - 6 * S(2 * ph), 0), 'fang.R': (6 + 6 * S(2 * ph), 6 + 6 * S(2 * ph), 0),
         'root_loc': (0, 0, 0.18 * S(ph))}
    p.update(_legs({}, {n: 2.5 * S(ph + k) for k, n in enumerate(LG)}))
    return p


def walk(f):    # tétrapode alterné
    ph = TAU * f / 32
    A = ('leg0.L', 'leg1.R', 'leg2.L', 'leg3.R')
    lift, swing, curl = {}, {}, {}
    for n in LG:
        q = ph if n in A else ph + math.pi
        swing[n] = 15 * S(q); lift[n] = 12 * max(0.0, math.cos(q)); curl[n] = 8 * max(0.0, math.cos(q))
    p = {'body': (0, 2 * S(ph), 3 * S(ph)), 'head': (0, 0, -4 * S(ph)), 'abdo': (2 * S(2 * ph), 0, -6 * S(ph)),
         'fang.L': (8, -6, 0), 'fang.R': (8, 6, 0), 'root_loc': (0, 0, 0.3 * abs(S(2 * ph)))}
    p.update(_legs(lift, swing, curl))
    return p


def attack(f):  # se cabre, pattes avant levées, puis s'abat et plante les crochets (impact frame 22)
    T = {'body': [(0, (0, 0, 0)), (16, (-14, 0, 0)), (22, (4, 0, 0)), (32, (4, 0, 0)), (46, (0, 0, 0))],
         'head': [(0, (0, 0, 0)), (16, (-12, 0, 0)), (22, (20, 0, 0)), (46, (0, 0, 0))],
         'abdo': [(0, (0, 0, 0)), (16, (22, 0, 0)), (22, (-10, 0, 0)), (46, (0, 0, 0))],
         'fang.L': [(0, (6, -6, 0)), (16, (-20, -30, 0)), (22, (30, 4, 0)), (32, (30, 4, 0)), (46, (6, -6, 0))],
         'fang.R': [(0, (6, 6, 0)), (16, (-20, 30, 0)), (22, (30, -4, 0)), (32, (30, -4, 0)), (46, (6, 6, 0))],
         'root_loc': [(0, (0, 0, 0)), (16, (0, 1.2, 2.8)), (22, (0, -2.4, 0.9)), (32, (0, -2.4, 0.9)), (46, (0, 0, 0))]}
    p = pose(f, T)
    a = kf(f, [(0, 0), (16, 1), (22, -0.4), (32, -0.4), (46, 0)])
    up = max(a, 0)
    p.update(_legs({'leg0.L': 55 * up, 'leg0.R': 55 * up, 'leg1.L': 25 * up, 'leg1.R': 25 * up},
                   {'leg0.L': 25 * a, 'leg0.R': 25 * a, 'leg1.L': 10 * a, 'leg1.R': 10 * a},
                   {'leg0.L': 30 * up, 'leg0.R': 30 * up}))
    return p


def roar(f):    # se dresse, pattes avant battantes, crochets écartés, tremble
    a = kf(f, [(0, 0), (14, 1), (46, 1), (60, 0)])
    sh = S(TAU * f / 7) * (1 if 14 < f < 46 else 0)
    p = {'body': (-20 * a, 0, 0), 'head': (-12 * a + 2 * sh, 0, 0), 'abdo': (18 * a, 0, 3 * sh),
         'fang.L': (-10 * a, -6 - 30 * a, 0), 'fang.R': (-10 * a, 6 + 30 * a, 0), 'root_loc': (0, 1.0 * a, 3.4 * a)}
    p.update(_legs({'leg0.L': (50 + 10 * sh) * a, 'leg0.R': (50 - 10 * sh) * a, 'leg1.L': 30 * a, 'leg1.R': 30 * a},
                   {'leg0.L': 20 * a, 'leg0.R': 20 * a}, {'leg0.L': 25 * a, 'leg0.R': 25 * a}))
    return p


def hurt(f):
    a = kf(f, [(0, 0), (5, 1), (24, 0)])
    p = {'body': (-8 * a, 0, 5 * a), 'head': (-12 * a, 0, -7 * a), 'abdo': (10 * a, 0, -6 * a),
         'fang.L': (0, -6 - 25 * a, 0), 'fang.R': (0, 6 + 25 * a, 0), 'root_loc': (0, 0.8 * a, 1.4 * a)}
    p.update(_legs({n: 14 * a for n in LG}, {}, {n: 10 * a for n in LG}))
    return p


def death(f):   # s'effondre sur le ventre, pattes qui se replient
    a = kf(f, [(0, 0), (26, 1), (56, 1)])
    p = {'body': (0, 0, 6 * a), 'head': (14 * a, 0, 8 * a), 'abdo': (-6 * a, 8 * a, -10 * a),
         'fang.L': (20 * a, 10 * a, 0), 'fang.R': (20 * a, -10 * a, 0), 'root_loc': (0, 0, -3.6 * a)}
    p.update(_legs({n: 40 * a for n in LG}, {f'leg{i}.{s}': (i - 1.5) * 10 * a for i in range(4) for s in 'LR'},
                   {n: 75 * a for n in LG}))
    return p


CLIPS = {'Walk': (32, walk), 'Attack': (46, attack), 'Roar': (60, roar), 'Hurt': (24, hurt), 'Death': (56, death),
         'Idle': (72, idle)}   # Idle en dernier = pose des vues
PREVIEW = dict(target=(0, 0, 9.5), ortho=36.0, pitch=18, shots=[('Attack', 16), ('Attack', 23), ('Death', 56)], loop='Walk')
