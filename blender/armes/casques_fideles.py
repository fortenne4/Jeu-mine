"""Casques FIDÈLES à l'image de référence (10 casques, même ordre / ids que l'échelle).
Vrais meshes Blender : coque creuse (solidify), ouvertures en T booléennes, plaques biseautées projetées
sur la coque, plaques de roche (Voronoi sphérique) sur un fond de fissures Neon, pointes, cornes et ailes balayées.

blender -b --factory-startup --python casques_fideles.py [-- Id1 Id2 ...]
-> assets/casques/<Id>.fbx (un objet par matériau + "Racine" au centre de la tête), assets/casques/materiaux.json,
   src/partage/CasquesMeshMateriaux.lua, previews/armes/fideles/<Id>.png + CasquesFideles.png

Repère de modélisation = repère Roblox (origine = centre de la tête R15 1.2 stud, devant -Z, haut +Y, droite +X).
Dans Blender : (x, y, z)_Roblox -> (x, -z, y). Export FBX axis_forward=-Z, axis_up=Y => coordonnées FBX = Roblox.
"""
import bpy, bmesh, math, os, sys, json, random
from mathutils import Vector, Matrix, Euler

ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.abspath(os.path.join(ICI, '..', '..'))
D_FBX = os.path.join(JEU, 'assets', 'casques')
D_PNG = os.path.join(JEU, 'previews', 'armes', 'fideles')
D_LUA = os.path.join(JEU, 'src', 'partage')

# ------------------------------------------------------------------ matériaux (Blender PBR + Roblox)
MATS = {
    #  nom          Roblox Material   couleur          metal rough emission
    'Roche':       ('Slate',         (44, 41, 45),    0.0, 0.85, 0),
    'Fissures':    ('Neon',          (255, 96, 24),   0.0, 0.5, 3),
    'Doublure':   ('SmoothPlastic', (16, 13, 12),    0.0, 0.9, 0),
    'Bronze':      ('Metal',         (176, 98, 52),   0.8, 0.38, 0),
    'BronzeClair': ('Metal',         (212, 134, 72),  0.8, 0.32, 0),
    'BronzeRouge': ('Metal',         (122, 58, 40),   0.6, 0.5, 0),
    'Fer':         ('Metal',         (108, 112, 120), 0.8, 0.42, 0),
    'FerClair':    ('Metal',         (160, 164, 172), 0.8, 0.34, 0),
    'FerSombre':   ('Metal',         (58, 57, 62),    0.7, 0.5, 0),
    'Or':          ('Metal',         (222, 160, 40),  0.85, 0.3, 0),
    'OrClair':     ('Metal',         (248, 200, 84),  0.85, 0.26, 0),
    'Gemme':       ('Neon',          (255, 214, 80),  0.0, 0.2, 3),
    'Racine':      ('SmoothPlastic', (255, 255, 255), 0.0, 1.0, 0),
}
LUMIERES = {'Fissures': dict(Couleur=(255, 120, 40), Portee=6, Luminosite=1.2),
            'Gemme': dict(Couleur=(255, 210, 110), Portee=7, Luminosite=1.4)}


def r2b(p):
    return (p[0], -p[2], p[1])


def nrm(v):
    l = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / l for c in v)


def add(a, b): return tuple(x + y for x, y in zip(a, b))
def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def mul(a, k): return tuple(x * k for x in a)
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


# ------------------------------------------------------------------ forme de la coque (paramétrée)
class Forme:
    def __init__(self, A=0.80, B=0.84, Y0=0.32, VT=1.24, P1=1.6, P2=0.75, N=2.6, FWD=0.12,
                 VBF=-0.96, VBB=-0.82, FLB=0.15, FLF=0.11):
        self.__dict__.update(locals())

    def vb(self, u):
        return self.VBB + (self.VBF - self.VBB) * max(math.cos(math.radians(u)), 0)

    def k(self, u, v):
        if v >= self.Y0:
            s = min(1.0, (v - self.Y0) / (self.VT - self.Y0))
            return max(0.0, 1 - s ** self.P1) ** self.P2
        if v < -0.15:
            s = (-0.15 - max(v, self.vb(u))) / 0.7
            cu = max(math.cos(math.radians(u)), 0)
            return 1 + s * s * (self.FLB * (1 - cu) + self.FLF * cu)
        return 1.0

    def p(self, u, v):
        a = math.radians(u)
        su, cu = math.sin(a), math.cos(a)
        e = 2.0 / self.N
        k = self.k(u, v)
        x = self.A * k * math.copysign(abs(su) ** e, su)
        z = -self.B * k * math.copysign(abs(cu) ** e, cu)
        if v > self.Y0:
            s = min(1.0, (v - self.Y0) / (self.VT - self.Y0))
            z -= self.FWD * s * s
        return (x, v, z)

    def n(self, u, v):
        if v > self.VT - 0.02:
            return (0, 1, 0)
        du = sub(self.p(u + 0.5, v), self.p(u - 0.5, v))
        dv = sub(self.p(u, v + 0.01), self.p(u, v - 0.01))
        nn = nrm(cross(dv, du))
        c = self.p(u, v)
        if dot(nn, (c[0], 0, c[2])) + 0.3 * nn[1] < 0:
            nn = mul(nn, -1)
        return nn

    def q(self, u, v, off=0.0):
        return add(self.p(u, v), mul(self.n(u, v), off))

    def vers(self, d, c=(0, 0.02, 0)):
        """Point de la coque (prolongée sous le bord) dans la direction d depuis c (bissection)."""
        def dedans(pt):
            u = math.degrees(math.atan2(pt[0], -pt[2]))
            v = pt[1]
            if v >= self.VT or v < -2.5:
                return False
            s = self.p(u, v)
            return math.hypot(pt[0], pt[2]) < math.hypot(s[0], s[2])
        lo, hi = 0.0, 3.0
        for _ in range(40):
            m = (lo + hi) / 2
            if dedans(add(c, mul(d, m))):
                lo = m
            else:
                hi = m
        return add(c, mul(d, lo))


# ------------------------------------------------------------------ objets Blender
COLL = None


def nouvel_objet(nom, verts, faces, mat, lisse=True):
    me = bpy.data.meshes.new(nom)
    me.from_pydata([r2b(v) for v in verts], [], faces)
    me.validate()
    o = bpy.data.objects.new(nom, me)
    COLL.objects.link(o)
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    if mat:
        o.data.materials.append(materiau(mat))
    return o


_mats = {}


def materiau(nom):
    if nom in _mats:
        return _mats[nom]
    rm, c, metal, rough, em = MATS[nom]
    m = bpy.data.materials.new(nom); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    rgb = tuple((x / 255) ** 2.2 for x in c) + (1,)
    b.inputs['Base Color'].default_value = rgb
    b.inputs['Metallic'].default_value = metal
    b.inputs['Roughness'].default_value = rough
    if em:
        b.inputs['Emission Color'].default_value = rgb
        b.inputs['Emission Strength'].default_value = em
    if nom in ('Roche',):
        nt = m.node_tree
        t = nt.nodes.new('ShaderNodeTexNoise'); t.inputs['Scale'].default_value = 22
        bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 0.4
        nt.links.new(t.outputs['Fac'], bp.inputs['Height']); nt.links.new(bp.outputs['Normal'], b.inputs['Normal'])
    _mats[nom] = m
    return m


def actif(o):
    for x in bpy.context.selected_objects:
        x.select_set(False)
    bpy.context.view_layer.objects.active = o
    o.select_set(True)


def appliquer(o):
    actif(o)
    for md in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=md.name)


def solidifier(o, ep, offset=-1.0, mat_int=None):
    md = o.modifiers.new('s', 'SOLIDIFY'); md.thickness = ep; md.offset = offset; md.use_even_offset = True
    if mat_int:
        o.data.materials.append(materiau(mat_int)); md.material_offset = 1
    appliquer(o)


def booleen(o, outil, op='DIFFERENCE', garder=False, auto=False):
    md = o.modifiers.new('b', 'BOOLEAN'); md.operation = op; md.object = outil; md.solver = 'EXACT'
    if auto:
        md.use_self = True; md.use_hole_tolerant = True
    try:
        md.material_mode = 'INDEX'
    except Exception:
        pass
    appliquer(o)
    if not garder:
        bpy.data.objects.remove(outil, do_unlink=True)


def biseauter(o, l=0.012, angle=35):
    md = o.modifiers.new('bv', 'BEVEL'); md.width = l; md.segments = 1; md.limit_method = 'ANGLE'
    md.angle_limit = math.radians(angle)
    appliquer(o)


def lisser(o, angle=40):
    actif(o)
    try:
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(angle))
    except Exception:
        bpy.ops.object.shade_flat()


# ------------------------------------------------------------------ briques géométriques
NU, NV = 48, 26


def surface_coque(F, off=0.0, prolonge=0.0):
    """Grille (u, v) de la coque décalée de off ; prolonge = descente sous le bord (couches de plaques)."""
    verts, faces = [], []
    for j in range(NV):
        t = j / NV
        for i in range(NU):
            u = i * 360.0 / NU
            vb = F.vb(u) - prolonge
            v = vb + (F.VT - vb) * (t ** 0.9)
            verts.append(F.q(u, v, off))
    pole = len(verts)
    verts.append(add(F.p(0, F.VT), (0, off, 0)))
    for j in range(NV - 1):
        for i in range(NU):
            a = j * NU + i; b = j * NU + (i + 1) % NU
            faces.append((a, b, b + NU, a + NU))
    j = NV - 1
    for i in range(NU):
        faces.append((j * NU + i, j * NU + (i + 1) % NU, pole))
    return verts, faces


def prisme(poly, z0=-3.0, z1=3.0, nom='outil'):
    """Polygone (x, y) Roblox extrudé selon z (z0 -> z1)."""
    n = len(poly)
    verts = [(x, y, z0) for x, y in poly] + [(x, y, z1) for x, y in poly]
    faces = [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    return nouvel_objet(nom, verts, faces, None)


def miroir(demi):
    """Demi-polygone côté +x (de haut en bas, x >= 0) -> polygone complet."""
    return demi + [(-x, y) for x, y in reversed(demi) if abs(x) > 1e-9]


def coque(F, mat, mat_int='Doublure', off=0.0, ep=0.07, ouverture=None):
    v, f = surface_coque(F, off)
    o = nouvel_objet('Coque', v, f, mat)
    solidifier(o, ep, -1.0, mat_int)
    if ouverture:
        booleen(o, prisme(ouverture, -3.0, 0.0))
    lisser(o)
    return o


def plaque(F, poly, mat, off=0.0, ep=0.05, z0=-3.0, z1=3.0, trou=None, bord=0.012, prolonge=0.0):
    """Plaque épousant la coque : couche décalée solidifiée, intersectée avec un prisme (projection de face)."""
    v, f = surface_coque(F, off, prolonge)
    o = nouvel_objet('Plaque', v, f, mat)
    solidifier(o, ep, 1.0)
    booleen(o, prisme(poly, z0, z1), 'INTERSECT')
    if trou:
        booleen(o, prisme(trou, z0 - 0.1, z1 + 0.1))
    if bord:
        biseauter(o, bord)
    lisser(o, 30)
    return o


def cadre(F, poly, retrait, mat, off=0.0, ep=0.05, panneau=None, z0=-3.0, z1=0.02):
    """Plaque à rebord : cadre épais + panneau intérieur plus bas (panneau=None : seulement le cadre)."""
    interieur = retrecir(poly, retrait)
    objs = [plaque(F, poly, mat, off, ep, z0, z1, trou=interieur)]
    if panneau:
        objs.append(plaque(F, interieur, panneau, off, ep * 0.45, z0, z1))
    return objs


def retrecir(poly, d):
    """Décalage intérieur d'un polygone convexe/simple (approx : bissectrices)."""
    n = len(poly)
    aire = sum(poly[i][0] * poly[(i + 1) % n][1] - poly[(i + 1) % n][0] * poly[i][1] for i in range(n))
    s = 1 if aire > 0 else -1
    out = []
    for i in range(n):
        p0, p1, p2 = poly[i - 1], poly[i], poly[(i + 1) % n]
        def nor(a, b):
            dx, dy = b[0] - a[0], b[1] - a[1]
            l = math.hypot(dx, dy) or 1
            return (-dy / l * s, dx / l * s)
        n1, n2 = nor(p0, p1), nor(p1, p2)
        b = (n1[0] + n2[0], n1[1] + n2[1])
        bl = math.hypot(*b) or 1
        cosd = max(0.35, (n1[0] * b[0] + n1[1] * b[1]) / bl)
        k = d / cosd
        out.append((p1[0] + b[0] / bl * k, p1[1] + b[1] / bl * k))
    return out


def ico(c, r, mat, nom='Rivet'):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=r)
    me = bpy.data.meshes.new(nom); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(nom, me); COLL.objects.link(o)
    o.location = r2b(c)
    o.data.materials.append(materiau(mat))
    appliquer_transfo(o)
    lisser(o, 80)
    return o


def appliquer_transfo(o):
    actif(o)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def rivets(F, liste, off, mat, r=0.032):
    return [ico(F.q(u, v, off), r, mat) for u, v in liste]


def balayage(pts, largeurs, epaisseurs, normale, mat, nom='Lame', facettes=True):
    """Lame / corne : sections losange (largeur dans le plan ⟂ normale, épaisseur selon normale) le long de pts."""
    verts, faces = [], []
    n = len(pts)
    for i, p in enumerate(pts):
        t = sub(pts[min(i + 1, n - 1)], pts[max(i - 1, 0)])
        t = nrm(t)
        nn = nrm(sub(normale, mul(t, dot(normale, t))))
        w = nrm(cross(t, nn))
        lw, le = largeurs[i] / 2, epaisseurs[i] / 2
        verts += [add(p, mul(w, lw)), add(p, mul(nn, le)), add(p, mul(w, -lw)), add(p, mul(nn, -le))]
    for i in range(n - 1):
        for k in range(4):
            a, b = i * 4 + k, i * 4 + (k + 1) % 4
            faces.append((a, b, b + 4, a + 4))
    faces.append((3, 2, 1, 0))
    faces.append(tuple((n - 1) * 4 + k for k in range(4)))
    o = nouvel_objet(nom, verts, faces, mat)
    if facettes:
        lisser(o, 20)
    return o


def courbe(p0, p1, p2, n=7):
    """Bézier quadratique."""
    out = []
    for i in range(n):
        t = i / (n - 1)
        out.append(add(add(mul(p0, (1 - t) ** 2), mul(p1, 2 * t * (1 - t))), mul(p2, t * t)))
    return out


def pyramide(base, axe, h, r, mat, cotes=4, tour=0.0, nom='Pointe', aplat=1.0):
    """Pointe angulaire (pyramide) : base au point base, vers axe."""
    axe = nrm(axe)
    a1 = nrm(cross(axe, (0, 0, 1) if abs(axe[2]) < 0.9 else (1, 0, 0)))
    a2 = cross(axe, a1)
    verts = []
    for k in range(cotes):
        ang = tour + 2 * math.pi * k / cotes
        verts.append(add(base, add(mul(a1, r * math.cos(ang)), mul(a2, r * aplat * math.sin(ang)))))
    verts.append(add(base, mul(axe, h)))
    verts.append(add(base, mul(axe, -0.08)))
    faces = [(k, (k + 1) % cotes, cotes) for k in range(cotes)] + [((k + 1) % cotes, k, cotes + 1) for k in range(cotes)]
    o = nouvel_objet(nom, verts, faces, mat)
    lisser(o, 20)
    return o


def losange(c, hx, hy_haut, hy_bas, prof, mat, nom='Losange', recul=0.06):
    """Bipyramide à 4 côtés (cadre / gemme facettés), face vers -Z."""
    verts = [(c[0], c[1] + hy_haut, c[2]), (c[0] + hx, c[1], c[2]), (c[0], c[1] - hy_bas, c[2]), (c[0] - hx, c[1], c[2]),
             (c[0], c[1], c[2] - prof), (c[0], c[1], c[2] + recul)]
    faces = [(0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4), (1, 0, 5), (2, 1, 5), (3, 2, 5), (0, 3, 5)]
    o = nouvel_objet(nom, verts, faces, mat)
    lisser(o, 10)
    return o


# ------------------------------------------------------------------ roche : plaques Voronoi sphériques
def plaques_roche(F, graine, nb, ouverture=None, off=(0.0, 0.05), ep=0.09, ecart=0.016, filtre=None,
                  mat='Roche', saillie=None):
    rnd = random.Random(graine)
    seeds = []
    ga = math.pi * (3 - math.sqrt(5))
    for i in range(nb):
        y = 1 - 1.78 * (i + 0.5) / nb      # graines limitées au-dessus du bord bas (élévation > -50°)
        r = math.sqrt(1 - y * y)
        th = ga * i + rnd.uniform(-0.3, 0.3)
        s = nrm((r * math.cos(th) + rnd.uniform(-.12, .12), y + rnd.uniform(-.1, .1), r * math.sin(th) + rnd.uniform(-.12, .12)))
        seeds.append(s)
    C = (0, 0.02, 0)
    verts, faces = [], []
    for i, s in enumerate(seeds):
        e1 = nrm(cross(s, (0, 1, 0) if abs(s[1]) < 0.95 else (1, 0, 0)))
        e2 = cross(s, e1)
        poly = [(-2, -2), (2, -2), (2, 2), (-2, 2)]
        for j, o in enumerate(seeds):
            if j == i:
                continue
            w = sub(s, o)
            a, b, c0 = dot(e1, w), dot(e2, w), dot(s, w)
            # garder a*x + b*y + c0 >= 0
            new = []
            for k in range(len(poly)):
                P, Q = poly[k], poly[(k + 1) % len(poly)]
                fp, fq = a * P[0] + b * P[1] + c0, a * Q[0] + b * Q[1] + c0
                if fp >= 0:
                    new.append(P)
                if (fp >= 0) != (fq >= 0):
                    t = fp / (fp - fq)
                    new.append((P[0] + (Q[0] - P[0]) * t, P[1] + (Q[1] - P[1]) * t))
            poly = new
            if len(poly) < 3:
                break
        if len(poly) < 3:
            continue
        pts = [F.vers(nrm(add(s, add(mul(e1, x), mul(e2, y)))), C) for x, y in poly]
        cen = mul(tuple(map(sum, zip(*pts))), 1 / len(pts))
        if filtre and not filtre(cen):
            continue
        # plan de la plaque : normale moyenne + inclinaison aléatoire, décalage aléatoire
        nn = F.n(math.degrees(math.atan2(cen[0], -cen[2])), min(cen[1], F.VT - 0.03))
        nn = nrm(add(nn, (rnd.uniform(-.08, .08), rnd.uniform(-.08, .08), rnd.uniform(-.08, .08))))
        dh = rnd.uniform(*off)
        if saillie:
            dh += saillie(cen, rnd)
        uc = math.degrees(math.atan2(cen[0], -cen[2]))
        sur = F.p(uc, min(cen[1], F.VT - 0.03))   # le centroïde des sommets est sous la surface : on le ramène dessus
        plan_c = add(sur, mul(nn, dh))
        taille = max(math.dist(cen, p) for p in pts)
        k = max(0.4, 1 - ecart / max(taille, 0.05))
        top = []
        for p in pts:
            d = sub(p, plan_c)
            p2 = sub(p, mul(nn, dot(d, nn)))            # projeté sur le plan
            top.append(add(plan_c, mul(sub(p2, plan_c), k)))
        base = len(verts)
        m = len(top)
        verts += top + [add(p, mul(nn, -ep)) for p in top]
        faces.append(tuple(base + q for q in range(m)))
        faces.append(tuple(base + m + q for q in range(m - 1, -1, -1)))
        for q in range(m):
            r_ = (q + 1) % m
            faces.append((base + q, base + m + q, base + m + r_, base + r_))
    o = nouvel_objet('Roche', verts, faces, mat)
    biseauter(o, 0.014, 30)
    if ouverture:
        booleen(o, prisme(ouverture, -3.0, 0.0), auto=True)
    booleen(o, prisme([(-3, -3), (3, -3), (3, F.VBB - 0.03), (-3, F.VBB - 0.03)], -0.1, 3.0), auto=True)
    booleen(o, prisme([(-3, -3), (3, -3), (3, F.VBF - 0.02), (-3, F.VBF - 0.02)], -3.0, 0.0), auto=True)
    lisser(o, 15)
    return o


def dedans_poly(poly, x, y):
    c = False
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]; x2, y2 = poly[(i + 1) % n]
        if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1):
            c = not c
    return c


def fond_fissures(F, ouverture):
    return coque(F, 'Fissures', 'Doublure', off=-0.055, ep=0.06, ouverture=ouverture)


# ------------------------------------------------------------------ éléments communs du modèle de référence
OUV = miroir([(0.0, 0.11), (0.55, 0.28), (0.72, 0.27), (0.64, 0.02), (0.13, -0.13), (0.10, -1.5)])


def bandeau_poly(yc=0.12, ys=0.27, h=0.15, pointe=None):
    """Bandeau horizontal à V central (bas du V = haut de l'ouverture)."""
    pts_bas = []
    for i in range(41):
        x = -1.3 + 2.6 * i / 40
        pts_bas.append((x, yc + (ys - yc) * min(abs(x) / 0.55, 1)))
    haut = [(x, y + h) for x, y in reversed(pts_bas)]
    bas = pts_bas
    if pointe:  # languette en V qui descend au centre (CharbonFer, FerOr)
        bas = [p for p in pts_bas if abs(p[0]) > 0.16]
        g = [p for p in bas if p[0] < 0]; d = [p for p in bas if p[0] > 0]
        bas = g + [(-0.16, yc + (ys - yc) * 0.16 / 0.55), (0, pointe), (0.16, yc + (ys - yc) * 0.16 / 0.55)] + d
    return bas + haut


def bandeau(F, mat, off=0.0, ep=0.05, h=0.15, pointe=None):
    """Bandeau : V à l'avant (z < 0), droit à l'arrière."""
    ys = 0.27
    return [plaque(F, bandeau_poly(h=h, pointe=pointe), mat, off, ep, -3.0, 0.0),
            plaque(F, [(-1.3, ys), (1.3, ys), (1.3, ys + h), (-1.3, ys + h)], mat, off, ep, 0.0, 3.0)]


def arete_poly(w_bas=0.10, w_haut=0.065, y_bas=0.20, pointe=0.30):
    return [(0, y_bas), (w_bas, pointe), (w_haut, 1.4), (-w_haut, 1.4), (-w_bas, pointe)]


JOUE_D = [(0.11, -1.5), (0.13, -0.15), (0.64, 0.00), (1.3, 0.00), (1.3, -1.5)]
JOUE_G = [(-x, y) for x, y in reversed(JOUE_D)]
RIVETS_BANDEAU = [(u, 0.35) for u in (62, 80, 98, 116, -62, -80, -98, -116)]


def cornes(mat, base_u=58, haut=1.42, ecart=1.0, larg=0.28, ep=0.11, F=None):
    out = []
    for s in (1, -1):
        b = F.q(s * base_u, 0.36, 0.03)
        pts = courbe(b, (s * ecart, 0.62, b[2] + 0.02), (s * (ecart - 0.18), haut, b[2] + 0.12), 8)
        n = len(pts)
        out.append(balayage(pts, [larg * (1 - i / (n - 1)) ** 0.8 + 0.004 for i in range(n)],
                            [ep * (1 - i / (n - 1)) + 0.01 for i in range(n)], (0, 0, -1), mat, 'Corne'))
    return out


def pointe_centrale(F, mat, haut=1.62, larg=0.38, ep=0.20, y0=0.30):
    b = F.q(0, y0, 0.05)
    top = (0, haut, F.p(0, 0.9)[2] + 0.05)
    pts = courbe(b, (0, (y0 + haut) / 2, b[2] + 0.02), top, 6)
    n = len(pts)
    return balayage(pts, [larg * (1 - i / (n - 1)) + 0.005 for i in range(n)],
                    [ep * (1 - i / (n - 1)) + 0.01 for i in range(n)], (0, 0, -1), mat, 'Pointe')


def ailes(F, mat):
    out = []
    for s in (1, -1):
        base = F.q(s * 62, 0.40, 0.04)
        for k, (dx, dy, lg, w) in enumerate(((0.32, 1.0, 0.95, 0.22), (0.58, 0.78, 0.92, 0.20), (0.78, 0.48, 0.80, 0.18), (0.85, 0.18, 0.62, 0.15))):
            p0 = add(base, (0, -0.06 * k, 0.03 * k))
            p2 = add(p0, (s * dx * lg, dy * lg + 0.12, 0.10))
            p1 = add(p0, (s * dx * lg * 0.35, dy * lg * 0.25, 0.0))
            pts = courbe(p0, p1, p2, 7)
            n = len(pts)
            out.append(balayage(pts, [w * (1 - (i / (n - 1)) ** 1.6) + 0.004 for i in range(n)],
                                [0.06 * (1 - i / (n - 1)) + 0.012 for i in range(n)], (0, 0, -1), mat, 'Aile'))
    return out


def gemme_front(F, mat_cadre, y=0.43, hx=0.29, hh=0.36, hb=0.26, gem=True):
    c = F.q(0, y, 0.10)
    out = [losange(c, hx, hh, hb, 0.16, mat_cadre, 'Cadre', 0.08)]
    if gem:
        out.append(losange(add(c, (0, 0.0, -0.09)), hx * 0.6, hh * 0.6, hb * 0.6, 0.13, 'Gemme', 'Gemme', 0.02))
    return out


def pointes_roche(F, liste, mat='Roche', graine=3):
    rnd = random.Random(graine)
    out = []
    for u, v, h, r in liste:
        b = F.q(u, v, -0.02)
        axe = nrm(add(F.n(u, v), (0, 1.3, 0)))
        out.append(pyramide(b, axe, h, r, mat, cotes=rnd.choice((4, 5)), tour=rnd.uniform(0, 3), aplat=rnd.uniform(.6, 1)))
    return out


# ------------------------------------------------------------------ les 10 casques
def c_charbon():
    F = Forme(A=0.82, B=0.86, VT=1.16, P1=1.4, P2=0.5)
    o = [fond_fissures(F, OUV)]
    o.append(plaques_roche(F, 11, 44, OUV, off=(0.0, 0.04),
                           saillie=lambda c, r: (0.04 * r.random() if c[1] > 0.5 else 0.0)))
    o += pointes_roche(F, [(0, 1.0, 0.36, 0.22), (40, 0.82, 0.24, 0.18), (-45, 0.80, 0.26, 0.17), (150, 0.80, 0.22, 0.18)])
    return F, o


def c_bronze():
    F = Forme()
    o = [coque(F, 'Bronze', ouverture=OUV),
         plaque(F, arete_poly(), 'BronzeClair', 0.0, 0.06),
         *bandeau(F, 'BronzeClair', 0.0, 0.05)]
    o += cadre(F, JOUE_D, 0.07, 'BronzeClair', panneau='Bronze')
    o += cadre(F, JOUE_G, 0.07, 'BronzeClair', panneau='Bronze')
    o += rivets(F, RIVETS_BANDEAU, 0.055, 'BronzeClair')
    return F, o


def c_charbon_bronze():
    F = Forme(A=0.82, B=0.86, VT=1.16, P1=1.4, P2=0.5)
    o = [fond_fissures(F, OUV),
         plaques_roche(F, 23, 44, OUV, off=(0.0, 0.05), filtre=None),
         *bandeau(F, 'Bronze', 0.05, 0.05, h=0.14)]
    o += pointes_roche(F, [(0, 0.86, 0.62, 0.19), (38, 0.76, 0.55, 0.17), (-38, 0.76, 0.55, 0.17),
                           (78, 0.62, 0.45, 0.16), (-78, 0.62, 0.45, 0.16), (180, 0.76, 0.35, 0.16)], graine=5)
    o += rivets(F, RIVETS_BANDEAU, 0.105, 'BronzeClair')
    return F, o


def c_fer():
    F = Forme(VT=0.98, P1=2.0, P2=0.5, FWD=0.06)
    o = [coque(F, 'Fer', ouverture=OUV),
         plaque(F, arete_poly(0.10, 0.07), 'FerClair', 0.0, 0.04),
         *bandeau(F, 'FerClair', 0.0, 0.05)]
    o += cadre(F, JOUE_D, 0.06, 'FerClair', panneau='Fer')
    o += cadre(F, JOUE_G, 0.06, 'FerClair', panneau='Fer')
    o += rivets(F, RIVETS_BANDEAU + [(30, -0.6), (-30, -0.6)], 0.055, 'FerClair')
    return F, o


def bandes_joues(F, mat, off):
    """Barres verticales sur les joues (le long de la fente + bord extérieur)."""
    out = []
    for s in (1, -1):
        for poly in ([(0.12, -1.4), (0.14, -0.02), (0.26, 0.02), (0.24, -1.4)],
                     [(0.52, -1.4), (0.56, 0.08), (0.68, 0.11), (0.66, -1.4)]):
            out.append(plaque(F, [(s * x, y) for x, y in (poly if s > 0 else list(reversed(poly)))], mat, off, 0.05, -3, 0.3))
    return out


def c_charbon_fer():
    F = Forme(A=0.82, B=0.86, VT=1.16, P1=1.4, P2=0.5)
    o = [fond_fissures(F, OUV),
         plaques_roche(F, 37, 44, OUV, off=(0.0, 0.05)),
         *bandeau(F, 'FerClair', 0.05, 0.06, h=0.16, pointe=0.0),
         pointe_centrale(F, 'FerClair', haut=1.70)]
    o += cornes('FerClair', base_u=70, haut=1.25, ecart=1.0, larg=0.20, ep=0.09, F=F)
    o += bandes_joues(F, 'FerClair', 0.05)
    o += rivets(F, [(u, 0.36) for u in (70, 95, -70, -95)], 0.115, 'Fer')
    return F, o


def c_bronze_fer():
    F = Forme()
    o = [coque(F, 'FerSombre', ouverture=OUV),
         plaque(F, arete_poly(0.13, 0.10), 'Bronze', 0.0, 0.05),
         *bandeau(F, 'Bronze', 0.0, 0.055, h=0.16),
         plaque(F, [(-1.3, -0.80), (1.3, -0.80), (1.3, -0.68), (-1.3, -0.68)], 'Bronze', 0.0, 0.05, 0.0, 3.0, prolonge=0.0)]
    o += cadre(F, JOUE_D, 0.08, 'Bronze')
    o += cadre(F, JOUE_G, 0.08, 'Bronze')
    o += rivets(F, RIVETS_BANDEAU + [(25, -0.45), (-25, -0.45), (40, -0.7), (-40, -0.7), (55, 0.0), (-55, 0.0),
                                     (130, -0.74), (-130, -0.74), (180, -0.74)], 0.06, 'BronzeClair')
    return F, o


def c_or():
    F = Forme(FWD=0.14, P1=1.5, P2=0.6)
    o = [coque(F, 'Or', ouverture=OUV),
         plaque(F, arete_poly(0.12, 0.05), 'OrClair', 0.0, 0.05),
         *bandeau(F, 'OrClair', 0.0, 0.055, h=0.15)]
    o += gemme_front(F, 'Or', y=0.48, hh=0.40, hb=0.24)
    o += cornes('OrClair', base_u=62, haut=1.46, F=F)
    o += cadre(F, JOUE_D, 0.07, 'OrClair', panneau='Or')
    o += cadre(F, JOUE_G, 0.07, 'OrClair', panneau='Or')
    o += rivets(F, RIVETS_BANDEAU, 0.06, 'OrClair')
    return F, o


def c_charbon_or():
    F = Forme(A=0.82, B=0.86, VT=1.16, P1=1.4, P2=0.5)
    o = [fond_fissures(F, OUV),
         plaques_roche(F, 51, 44, OUV, off=(0.0, 0.05)),
         *bandeau(F, 'Or', 0.05, 0.06, h=0.17),
         pointe_centrale(F, 'FerClair', haut=1.66, larg=0.34)]
    o += cornes('Or', base_u=66, haut=1.44, F=F)
    o += bandes_joues(F, 'Or', 0.05)
    return F, o


def c_bronze_or():
    F = Forme(FWD=0.12, P1=1.5, P2=0.6)
    o = [coque(F, 'BronzeRouge', ouverture=OUV),
         *bandeau(F, 'Or', 0.0, 0.06, h=0.17),
         pointe_centrale(F, 'Or', haut=1.55, larg=0.40, ep=0.16, y0=0.45)]
    o += gemme_front(F, 'OrClair', y=0.46, hh=0.38, hb=0.26)
    o += cornes('Or', base_u=62, haut=1.46, F=F)
    o += cadre(F, JOUE_D, 0.08, 'Or')
    o += cadre(F, JOUE_G, 0.08, 'Or')
    o.append(plaque(F, [(-1.3, -0.80), (1.3, -0.80), (1.3, -0.70), (-1.3, -0.70)], 'Or', 0.0, 0.05, 0.0, 3.0))
    return F, o


def c_fer_or():
    F = Forme(FWD=0.12, P1=1.6, P2=0.6)
    o = [coque(F, 'Fer', ouverture=OUV),
         *bandeau(F, 'Or', 0.0, 0.065, h=0.18, pointe=-0.02),
         pointe_centrale(F, 'FerClair', haut=1.60, larg=0.34, ep=0.16, y0=0.45)]
    o += gemme_front(F, 'OrClair', y=0.42, hh=0.36, hb=0.50)
    o += ailes(F, 'Or')
    o += cadre(F, JOUE_D, 0.06, 'OrClair', panneau='Or')
    o += cadre(F, JOUE_G, 0.06, 'OrClair', panneau='Or')
    return F, o


CASQUES = [('CasqueCharbon', c_charbon), ('CasqueBronze', c_bronze), ('CasqueCharbonBronze', c_charbon_bronze),
           ('CasqueFer', c_fer), ('CasqueCharbonFer', c_charbon_fer), ('CasqueBronzeFer', c_bronze_fer),
           ('CasqueOr', c_or), ('CasqueCharbonOr', c_charbon_or), ('CasqueBronzeOr', c_bronze_or), ('CasqueFerOr', c_fer_or)]
TITRES = ['1. Charbon', '2. Bronze', '3. Charbon + Bronze', '4. Fer', '5. Charbon + Fer',
          '6. Bronze + Fer', '7. Or', '8. Charbon + Or', '9. Bronze + Or', '10. Fer + Or']


# ------------------------------------------------------------------ assemblage, découpe par matériau, export
def assembler(cid, objs):
    """Fusionne puis sépare par matériau -> {nom_mat: objet} dans une collection <cid>."""
    actif(objs[0])
    for o in objs:
        o.select_set(True)
    bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=1e-5)
    bpy.ops.mesh.separate(type='MATERIAL')
    bpy.ops.object.mode_set(mode='OBJECT')
    parts = {}
    for ob in bpy.context.selected_objects:
        ob.data.materials[:]  # noqa
        noms = [m.name for m in ob.data.materials if m]
        utilises = set(p.material_index for p in ob.data.polygons)
        mat = ob.data.materials[min(utilises)] if utilises else None
        # nettoie les emplacements inutilisés (un seul matériau par sous-mesh)
        if mat is not None:
            for p in ob.data.polygons:
                p.material_index = 0
            ob.data.materials.clear(); ob.data.materials.append(mat)
            ob.name = mat.name; ob.data.name = cid + '_' + mat.name
            parts[mat.name] = ob
    # marqueur Racine (centre de la tête)
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=0.1)
    me = bpy.data.meshes.new(cid + '_Racine'); bm.to_mesh(me); bm.free()
    r = bpy.data.objects.new('Racine', me); COLL.objects.link(r)
    r.data.materials.append(materiau('Racine'))
    parts['Racine'] = r
    return parts


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def exporter(cid, parts):
    os.makedirs(D_FBX, exist_ok=True)
    for x in bpy.context.selected_objects:
        x.select_set(False)
    for o in parts.values():
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts['Racine']
    dest = os.path.join(D_FBX, cid + '.fbx')
    bpy.ops.export_scene.fbx(filepath=dest, use_selection=True, object_types={'MESH'}, global_scale=1.0,
                             apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE', axis_forward='-Z', axis_up='Y',
                             mesh_smooth_type='FACE', use_mesh_modifiers=True, bake_space_transform=True,
                             add_leaf_bones=False, path_mode='AUTO')
    return dest


def bornes(parts):
    lo = [1e9] * 3; hi = [-1e9] * 3
    for n, o in parts.items():
        if n == 'Racine':
            continue
        for v in o.data.vertices:
            p = o.matrix_world @ v.co
            r = (p.x, p.z, -p.y)
            for i in range(3):
                lo[i] = min(lo[i], r[i]); hi[i] = max(hi[i], r[i])
    return lo, hi


# ------------------------------------------------------------------ rendu
def scene_rendu():
    sc = bpy.context.scene
    for eng in ('BLENDER_EEVEE', 'BLENDER_EEVEE_NEXT'):
        try:
            sc.render.engine = eng; break
        except TypeError:
            pass
    sc.view_settings.view_transform = 'Standard'
    w = bpy.data.worlds.new('W'); sc.world = w; w.use_nodes = True
    bg = w.node_tree.nodes['Background']; bg.inputs[0].default_value = (0.022, 0.022, 0.026, 1); bg.inputs[1].default_value = 1.0

    def soleil(nom, e, rot, col):
        l = bpy.data.lights.new(nom, 'SUN'); l.energy = e; l.color = col
        o = bpy.data.objects.new(nom, l); sc.collection.objects.link(o)
        o.rotation_euler = Euler(tuple(math.radians(a) for a in rot))
    soleil('cle', 4.0, (-42, 0, 30), (1, 0.9, 0.78))
    soleil('remplissage', 1.5, (-65, 0, -45), (0.75, 0.82, 1))
    soleil('contre', 2.5, (55, 0, 30), (1, 0.85, 0.7))
    soleil('haut', 1.2, (0, 0, 0), (1, 1, 1))
    cam = bpy.data.cameras.new('C'); cam.type = 'ORTHO'
    co = bpy.data.objects.new('C', cam); sc.collection.objects.link(co); sc.camera = co
    return sc, co


def tete_grise(piv):
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1.2)
    me = bpy.data.meshes.new('tete'); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new('Tete', me); bpy.context.scene.collection.objects.link(o)
    bv = o.modifiers.new('bv', 'BEVEL'); bv.width = 0.28; bv.segments = 6
    m = bpy.data.materials.get('_tete') or bpy.data.materials.new('_tete')
    m.diffuse_color = (0.35, 0.35, 0.38, 1)
    o.data.materials.append(m)
    o.parent = piv
    return [o]


def instance(parts, loc, rot_deg, tete=False):
    piv = bpy.data.objects.new('Piv', None); bpy.context.scene.collection.objects.link(piv)
    piv.location = loc; piv.rotation_euler = Euler((0, 0, math.radians(rot_deg)))
    crees = [piv]
    if tete:
        crees += tete_grise(piv)
    for n, o in parts.items():
        if n == 'Racine':
            continue
        c = o.copy(); c.data = o.data; c.hide_render = False
        bpy.context.scene.collection.objects.link(c)
        c.parent = piv; c.matrix_parent_inverse = Matrix.Identity(4)
        crees.append(c)
    return crees


def texte(corps, loc, taille=0.34):
    cu = bpy.data.curves.new('t', 'FONT'); cu.body = corps; cu.align_x = 'CENTER'; cu.size = taille
    o = bpy.data.objects.new('t', cu); bpy.context.scene.collection.objects.link(o)
    o.location = loc; o.rotation_euler = Euler((math.radians(90), 0, math.radians(180)))
    m = bpy.data.materials.get('_texte')
    if not m:
        m = bpy.data.materials.new('_texte'); m.use_nodes = True
        b = m.node_tree.nodes['Principled BSDF']
        b.inputs['Emission Color'].default_value = (1, 1, 1, 1); b.inputs['Emission Strength'].default_value = 1.0
    o.data.materials.append(m)
    return o


def rendre(sc, co, nom, res, ortho, cz, crees):
    sc.render.resolution_x, sc.render.resolution_y = res
    co.data.ortho_scale = ortho
    co.location = (0, 20, cz + 20 * math.tan(math.radians(10)))
    co.rotation_euler = Euler((math.radians(80), 0, math.radians(180)))
    os.makedirs(D_PNG, exist_ok=True)
    sc.render.filepath = os.path.join(D_PNG, nom)
    bpy.ops.render.render(write_still=True)
    print('CASQUE_PNG', sc.render.filepath)
    for o in crees:
        bpy.data.objects.remove(o, do_unlink=True)


# ------------------------------------------------------------------ Luau : table des matériaux mesh
def ecrire_lua(table):
    L = ['-- Généré par blender/armes/casques_fideles.py. Ne pas modifier à la main.',
         '-- Casques mesh (ReplicatedStorage.CasquesMesh.<Id>, importés depuis assets/casques/<Id>.fbx) :',
         '-- sous-mesh (nom de MeshPart) -> apparence Roblox ; Taille = encombrement attendu (studs, sans Racine).',
         'return {']
    for cid, e in table.items():
        L.append('\t%s = {' % cid)
        L.append('\t\tTaille = Vector3.new(%.3f, %.3f, %.3f),' % tuple(e['Taille']))
        L.append('\t\tCentre = Vector3.new(%.3f, %.3f, %.3f), -- centre de la boîte dans le repère de la tête' % tuple(e['Centre']))
        L.append('\t\tParties = {')
        for n, m in e['Parties'].items():
            extra = ''
            if m.get('PointLight'):
                l = m['PointLight']
                extra = ', Lumiere = {Couleur = Color3.fromRGB(%d, %d, %d), Portee = %g, Luminosite = %g}' % (*l['Couleur'], l['Portee'], l['Luminosite'])
            L.append('\t\t\t%s = {Material = Enum.Material.%s, Color = Color3.fromRGB(%d, %d, %d), Transparency = %g%s},'
                     % (n, m['Material'], *m['Color'], m['Transparency'], extra))
        L.append('\t\t},')
        L.append('\t},')
    L.append('}')
    p = os.path.join(D_LUA, 'CasquesMeshMateriaux.lua')
    open(p, 'w', encoding='utf8', newline='\n').write('\n'.join(L) + '\n')
    print('CASQUE_LUA', p)


# ------------------------------------------------------------------ main
def main():
    global COLL
    bpy.ops.wm.read_factory_settings(use_empty=True)
    COLL = bpy.context.scene.collection
    choix = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    sc, co = scene_rendu()
    chemin_json = os.path.join(D_FBX, 'materiaux.json')
    table = json.load(open(chemin_json, encoding='utf8')) if os.path.exists(chemin_json) else {}
    tous = {}
    for cid, f in CASQUES:
        if choix and cid not in choix and 'planche' not in choix:
            continue
        F, objs = f()
        objs = [o for o in objs if o is not None]
        parts = assembler(cid, objs)
        exporter(cid, parts)
        for n, o in parts.items():
            o.name = cid + '_' + n   # libère les noms de sous-mesh pour le casque suivant
        lo, hi = bornes(parts)
        nb = sum(tris(o) for n, o in parts.items() if n != 'Racine')
        print('CASQUE', cid, 'tris', nb, 'parties', sorted(k for k in parts if k != 'Racine'))
        table[cid] = {'Taille': [round(h - l, 3) for l, h in zip(lo, hi)],
                      'Centre': [round((h + l) / 2, 3) for l, h in zip(lo, hi)],
                      'Triangles': nb,
                      'Parties': {}}
        for n in parts:
            rm, c, *_ = MATS[n]
            e = {'Material': rm, 'Color': list(c), 'Transparency': 1 if n == 'Racine' else 0, 'Neon': rm == 'Neon'}
            if n in LUMIERES:
                e['PointLight'] = LUMIERES[n]
            table[cid]['Parties'][n] = e
        for o in parts.values():
            o.hide_render = True
            o.location = (0, 0, 0)
        tous[cid] = parts
        crees = []
        for x, rot in ((3.0, 0), (0, 90), (-3.0, 180)):
            crees += instance(parts, (x, 0, 0), rot, tete=True)
        rendre(sc, co, cid + '.png', (1500, 620), 9.0, 0.15, crees)
    json.dump(table, open(chemin_json, 'w', encoding='utf8'), indent=1, ensure_ascii=False)
    ecrire_lua(dict(sorted(table.items(), key=lambda kv: [c for c, _ in CASQUES].index(kv[0]))))
    if len(tous) == len(CASQUES):
        crees = []
        for k, (cid, _) in enumerate(CASQUES):
            r, j = divmod(k, 5)
            x, z = (2 - j) * 2.7, 1.85 - r * 3.85
            crees += instance(tous[cid], (x, 0, z), -28)
            crees.append(texte(TITRES[k], (x, 0.5, z + 1.85)))
        rendre(sc, co, 'CasquesFideles.png', (1536, 1024), 13.4, 0.05, crees)


main()
