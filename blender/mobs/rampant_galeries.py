# Rampant des galeries : prédateur aveugle des tunnels, carapace d'os pâle sur une chair violacée, 6 pattes, mandibules,
# grappe d'yeux luminescents (chasse à la lumière des lampes). ~7,5 studs de long, ~2,7 de haut. Box rig LihFolk, unités = studs.
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mobkit import kf, pose
from mathutils import Vector
S, TAU = math.sin, math.tau

NAME = 'RampantGaleries'
STUDS = 1.0
PALETTE = dict(B2='eee8d8', B1='d6cfbd', B3='b0a893', B4='857c6b',          # carapace d'os
               F3='8a7593', F1='6a5673', F2='4c3d55',                          # chair
               MA='2d2626', MB='4a3f3c', TS='4fc9a8', GT='8affd9', EY='141218', MO='1c1016', TE='e2dccb')
GLOW = {'GT'}
NOSTUD = ('EY', 'GT', 'MO', 'TE')
LEGS = (-1.25, 0.15, 1.45)
BONES = [('root', (0, 0, 0), (0, 0, 1), None),
         ('body', (0, 0.2, 1.4), (0, -1.4, 1.4), 'root'),
         ('head', (0, -1.7, 1.45), (0, -3.3, 1.45), 'body'),
         ('mand.L', (0.55, -3.1, 1.02), (0.55, -4.1, 1.02), 'head'),
         ('mand.R', (-0.55, -3.1, 1.02), (-0.55, -4.1, 1.02), 'head'),
         ('tail', (0, 1.6, 1.4), (0, 4.2, 1.2), 'body')]
for i, y in enumerate(LEGS):
    for sx, s in ((1, 'L'), (-1, 'R')):
        BONES.append((f'leg{i}.{s}', (1.05 * sx, y, 1.35), (3.25 * sx, y + (-0.6, 0, 0.6)[i], 0.05), 'body'))
HEAD = None


def build(K):
    span, sym = K.span, K.sym
    # ---- thorax : chair + 3 plaques de carapace qui se chevauchent ----
    span(-1.7, 1.7, -1.15, 1.15, 0.7, 1.9, 'F1', 'body')
    span(-1.5, 1.5, -0.9, 0.9, 0.55, 0.7, 'F2', 'body')
    for y0, y1 in ((-1.85, -0.6), (-0.75, 0.5), (0.35, 1.65)):
        span(y0, y1, -1.35, 1.35, 1.9, 2.32, 'B1', 'body')
        span(y0 + 0.1, y1 - 0.18, -1.0, 1.0, 2.32, 2.52, 'B2', 'body')
        sym(y0, y1, 1.35, 1.47, 1.35, 2.28, 'B3', 'body')
        span(y1 - 0.14, y1, -1.36, 1.36, 1.86, 2.36, 'B4', 'body')        # bord arrière plus sombre
        span(y0 + 0.35, y1 - 0.5, -0.14, 0.14, 2.52, 2.57, 'TS', 'body')  # marque turquoise
    # ---- tête sous un capuchon d'os ----
    span(-3.1, -1.7, -0.95, 0.95, 0.8, 1.85, 'F3', 'head')
    span(-3.3, -1.8, -1.15, 1.15, 1.85, 2.2, 'B1', 'head')
    span(-3.45, -3.2, -1.05, 1.05, 1.7, 2.08, 'B3', 'head')
    span(-3.0, -2.0, -0.8, 0.8, 2.2, 2.36, 'B2', 'head')
    sym(-2.6, -1.9, 0.7, 1.0, 2.2, 2.55, 'B3', 'head')                    # petites cornes du capuchon
    sym(-2.4, -2.05, 0.75, 0.92, 2.55, 2.78, 'B4', 'head')
    span(-3.12, -3.1, -0.92, 0.92, 1.22, 1.72, 'EY', 'head')
    span(-3.14, -3.11, -0.15, 0.15, 1.42, 1.64, 'GT', 'head')             # grappe d'yeux
    sym(-3.14, -3.11, 0.3, 0.54, 1.48, 1.66, 'GT', 'head')
    sym(-3.14, -3.11, 0.64, 0.8, 1.3, 1.42, 'GT', 'head')
    sym(-3.14, -3.11, 0.24, 0.36, 1.27, 1.36, 'GT', 'head')
    span(-3.13, -3.1, -0.5, 0.5, 0.88, 1.15, 'MO', 'head')
    for x0 in (-0.42, -0.14, 0.14):
        span(-3.15, -3.11, x0, x0 + 0.13, 1.02, 1.15, 'TE', 'head')
    # ---- mandibles ----
    for sx, s in K.sides():
        b = f'mand.{s}'
        P = lambda y0, y1, x0, x1, z0, z1, k: span(y0, y1, x0 * sx, x1 * sx, z0, z1, k, b)
        P(-3.35, -2.9, 0.38, 0.8, 0.85, 1.2, 'MB')
        P(-3.95, -3.35, 0.45, 0.8, 0.87, 1.16, 'MA')
        P(-4.2, -3.9, 0.15, 0.58, 0.9, 1.12, 'MA')
        P(-3.62, -3.46, 0.3, 0.45, 0.92, 1.08, 'TE')
    # ---- abdomen segmenté + pointe ----
    b = 'tail'
    span(1.6, 2.65, -0.95, 0.95, 0.8, 1.85, 'F1', b)
    span(1.5, 2.65, -1.05, 1.05, 1.85, 2.18, 'B1', b)
    span(1.6, 2.5, -0.7, 0.7, 2.18, 2.3, 'B2', b)
    span(2.5, 2.65, -1.06, 1.06, 1.82, 2.2, 'B4', b)
    span(2.65, 3.45, -0.7, 0.7, 0.9, 1.6, 'F1', b)
    span(2.55, 3.45, -0.8, 0.8, 1.6, 1.88, 'B3', b)
    span(2.9, 3.2, -0.12, 0.12, 1.88, 1.92, 'TS', b)
    span(3.45, 4.0, -0.42, 0.42, 1.0, 1.42, 'F2', b)
    span(3.45, 3.95, -0.45, 0.45, 1.42, 1.55, 'B4', b)
    span(4.0, 4.5, -0.16, 0.16, 1.1, 1.32, 'B4', b)
    # ---- 6 pattes : cuisse vers le haut (genou haut), tibia d'os vers le sol ----
    for i, y in enumerate(LEGS):
        dy = (-0.45, 0, 0.45)[i]
        for sx, s in K.sides():
            b = f'leg{i}.{s}'
            hip = Vector((1.0 * sx, y, 1.3)); knee = Vector((2.45 * sx, y + dy * 0.4, 2.05)); foot = Vector((3.25 * sx, y + dy * 1.3, 0.1))
            K.limb(hip, knee, 0.42, 0.42, 'F3', b)
            K.box(tuple(knee), (0.5, 0.5, 0.42), 'B3', b)
            K.limb(knee, foot, 0.34, 0.34, 'B3', b, extend=0.1)
            K.box(tuple(foot + Vector((0.08 * sx, 0, 0.05))), (0.3, 0.3, 0.22), 'B4', b)


# ---- clips ----
def _legs(lift, swing):
    """lift/swing par patte -> rotations (rz = avant/arrière, ry = lever)"""
    out = {}
    for i in range(3):
        for sx, s in ((1, 'L'), (-1, 'R')):
            n = f'leg{i}.{s}'
            out[n] = (0, -sx * lift.get(n, 0), sx * swing.get(n, 0))
    return out


def idle(f):
    ph = TAU * f / 60
    p = {'body': (2 * S(ph), 0, 0), 'head': (-3 * S(ph + 1), 0, 6 * S(ph / 2)), 'tail': (0, 0, 7 * S(ph + 0.5)),
         'mand.L': (0, 0, 8 + 8 * S(2 * ph)), 'mand.R': (0, 0, -8 - 8 * S(2 * ph)), 'root_loc': (0, 0, 0.05 * S(ph))}
    p.update(_legs({}, {f'leg{i}.{s}': 3 * S(ph + i) for i in range(3) for s in 'LR'}))
    return p


def walk(f):    # trottinement en trépied
    ph = TAU * f / 20
    A = ('leg0.L', 'leg1.R', 'leg2.L')
    lift, swing = {}, {}
    for i in range(3):
        for s in 'LR':
            n = f'leg{i}.{s}'; q = ph if n in A else ph + math.pi
            swing[n] = 24 * S(q); lift[n] = 18 * max(0.0, math.cos(q))
    p = {'body': (0, 3 * S(ph), 4 * S(ph)), 'head': (0, 0, -6 * S(ph)), 'tail': (0, 0, -10 * S(ph)),
         'mand.L': (0, 0, 10), 'mand.R': (0, 0, -10), 'root_loc': (0, 0, 0.08 * abs(S(2 * ph)))}
    p.update(_legs(lift, swing))
    return p


def attack(f):  # se cabre puis bondit en refermant les mandibules
    T = {'body': [(0, (0, 0, 0)), (12, (-16, 0, 0)), (17, (10, 0, 0)), (24, (10, 0, 0)), (34, (0, 0, 0))],
         'head': [(0, (0, 0, 0)), (12, (-10, 0, 0)), (17, (14, 0, 0)), (34, (0, 0, 0))],
         'tail': [(0, (0, 0, 0)), (12, (14, 0, 0)), (17, (-8, 0, 0)), (34, (0, 0, 0))],
         'mand.L': [(0, (0, 0, 8)), (12, (0, 0, 42)), (17, (0, 0, -6)), (24, (0, 0, -6)), (34, (0, 0, 8))],
         'mand.R': [(0, (0, 0, -8)), (12, (0, 0, -42)), (17, (0, 0, 6)), (24, (0, 0, 6)), (34, (0, 0, -8))],
         'root_loc': [(0, (0, 0, 0)), (12, (0, 0.5, 0.15)), (17, (0, -1.4, 0.1)), (24, (0, -1.4, 0)), (34, (0, 0, 0))]}
    p = pose(f, T)
    a = kf(f, [(0, 0), (12, 1), (17, -1), (24, -1), (34, 0)])
    p.update(_legs({'leg0.L': 20 * max(a, 0), 'leg0.R': 20 * max(a, 0)}, {f'leg{i}.{s}': 14 * a for i in range(3) for s in 'LR'}))
    return p


def hurt(f):
    a = kf(f, [(0, 0), (4, 1), (18, 0)])
    p = {'body': (-10 * a, 0, 6 * a), 'head': (-14 * a, 0, -8 * a), 'mand.L': (0, 0, 8 + 30 * a), 'mand.R': (0, 0, -8 - 30 * a),
         'tail': (12 * a, 0, 0), 'root_loc': (0, 0.4 * a, 0)}
    p.update(_legs({f'leg{i}.{s}': 25 * a for i in range(3) for s in 'LR'}, {}))
    return p


def death(f):   # s'effondre, pattes repliées
    a = kf(f, [(0, 0), (18, 1), (40, 1)])
    p = {'body': (0, 0, 8 * a), 'head': (12 * a, 0, 10 * a), 'tail': (8 * a, 0, -15 * a), 'mand.L': (0, 0, 30 * a),
         'mand.R': (0, 0, -30 * a), 'root_loc': (0, 0, -0.55 * a)}
    p.update(_legs({f'leg{i}.{s}': 55 * a for i in range(3) for s in 'LR'}, {f'leg{i}.{s}': (i - 1) * 15 * a for i in range(3) for s in 'LR'}))
    return p


CLIPS = {'Walk': (20, walk), 'Attack': (34, attack), 'Hurt': (18, hurt), 'Death': (40, death), 'Idle': (60, idle)}
PREVIEW = dict(target=(0, 0, 1.4), ortho=9.5, pitch=24, shots=[('Attack', 12), ('Attack', 18)], loop='Walk')
