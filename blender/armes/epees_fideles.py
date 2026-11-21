"""Épées FIDÈLES à l'image de référence (11 épées de la forge, même ordre que la planche de référence).
Vrais meshes Blender : lame en volume (biseau, fil, arête, encoches / barbes, cadre surélevé), fissures Neon,
garde en losange (cadre + gemme pyramidale) ou anneau, bras à pointes / croissants / ailes, poignée tressée
(hélices croisées), bagues et pommeau en losange.

blender -b --factory-startup --python epees_fideles.py [-- Id1 Id2 ...]
-> assets/epees/<Id>.fbx (un objet par rôle de matériau + petit cube "Poignee" au centre de la prise),
   assets/epees/materiaux.json, src/partage/EpeesMeshMateriaux.lua,
   previews/armes/epees/<Id>.png (face / côté / dos) + EpeesFideles.png (planche, cadrage de la référence)

Repère de modélisation « image » : x = droite de l'image vue de face, y = haut (lame vers +Y), z = vers l'arrière.
Repère Roblox (= repère de la Part Poignee) : (x, y, z)_img -> (-x, y, z) ; plat de la lame face à -Z (devant).
Dans Blender : (x, y, z)_Roblox -> (x, -z, y). Export FBX axis_forward=-Z, axis_up=Y => coordonnées FBX = Roblox.
"""
import bpy, bmesh, math, os, sys, json, random
from mathutils import Matrix, Euler

ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.abspath(os.path.join(ICI, '..', '..'))
D_FBX = os.path.join(JEU, 'assets', 'epees')
D_PNG = os.path.join(JEU, 'previews', 'armes', 'epees')
D_LUA = os.path.join(JEU, 'src', 'partage')

# ------------------------------------------------------------------ teintes (Roblox Material, couleur, metal, rough, emission)
ROCHE = ('Slate', (50, 48, 55), 0.0, 0.85, 0)
ROCHE_CL = ('Slate', (92, 90, 100), 0.0, 0.8, 0)
ROCHE_SO = ('Slate', (26, 25, 29), 0.0, 0.9, 0)
CUIVRE = ('Metal', (186, 92, 48), 0.85, 0.36, 0)
CUIVRE_CL = ('Metal', (232, 136, 76), 0.85, 0.3, 0)
CUIVRE_SO = ('Metal', (112, 52, 32), 0.7, 0.45, 0)
BRONZE_DORE = ('Metal', (222, 162, 92), 0.85, 0.3, 0)
FER = ('Metal', (140, 142, 152), 0.85, 0.36, 0)
FER_CL = ('Metal', (210, 212, 220), 0.85, 0.26, 0)
FER_SO = ('Metal', (60, 60, 68), 0.75, 0.45, 0)
OR = ('Metal', (232, 166, 36), 0.9, 0.3, 0)
OR_CL = ('Metal', (255, 210, 84), 0.9, 0.24, 0)
OR_SO = ('Metal', (150, 98, 38), 0.8, 0.4, 0)
CUIR = ('Fabric', (46, 32, 28), 0.0, 0.9, 0)
CUIR_BRUN = ('Fabric', (86, 56, 36), 0.0, 0.85, 0)
NEON_ORANGE = ('Neon', (255, 112, 30), 0.0, 0.5, 4)
NEON_OR = ('Neon', (255, 204, 72), 0.0, 0.5, 4)
AURA_OR = ('Neon', (255, 214, 96), 0.0, 0.5, 5)
MARQUEUR = ('SmoothPlastic', (255, 255, 255), 0.0, 1.0, 0)

# rôle absent de la palette d'une épée -> rôle de repli
REPLI = {'Bras': 'Garde', 'Embout': 'Garde', 'Bague': 'Garde', 'Gorge': 'Lame', 'Tresse': 'Manche', 'Cadre': 'Garde', 'Lisere': 'Cadre'}
TRANSPARENCE = {'Aura': 0.3, 'Poignee': 1}
LUMIERES = {'Fissures': 6, 'Gemme': 5, 'Aura': 8}

# ------------------------------------------------------------------ petites maths
def add(a, b): return tuple(x + y for x, y in zip(a, b))
def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def mul(a, k): return tuple(x * k for x in a)
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def lerp(a, b, t): return a + (b - a) * t


def nrm(v):
    l = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / l for c in v)


def i2b(p):
    """repère image -> Blender (via Roblox : x_r = -x)."""
    return (-p[0], -p[2], p[1])


def courbe(p0, p1, p2, n=7):
    out = []
    for i in range(n):
        t = i / (n - 1)
        out.append(add(add(mul(p0, (1 - t) ** 2), mul(p1, 2 * t * (1 - t))), mul(p2, t * t)))
    return out


# ------------------------------------------------------------------ objets / matériaux Blender
COLL = None
EPEE = None          # id en cours (matériaux uniques par épée)
PAL = {}             # palette de l'épée en cours : rôle -> teinte
_mats = {}


def role_reel(r):
    while r not in PAL and r in REPLI:
        r = REPLI[r]
    return r


def materiau(role):
    role = role_reel(role)
    cle = EPEE + '|' + role
    if cle in _mats:
        return _mats[cle]
    rm, c, metal, rough, em = PAL[role] if role != 'Poignee' else MARQUEUR
    m = bpy.data.materials.new(EPEE + '_' + role); m.use_nodes = True
    m['role'] = role
    b = m.node_tree.nodes['Principled BSDF']
    rgb = tuple((x / 255) ** 2.2 for x in c) + (1,)
    b.inputs['Base Color'].default_value = rgb
    b.inputs['Metallic'].default_value = metal
    b.inputs['Roughness'].default_value = rough
    if em:
        b.inputs['Emission Color'].default_value = rgb
        b.inputs['Emission Strength'].default_value = em
    if rm == 'Slate':
        nt = m.node_tree
        t = nt.nodes.new('ShaderNodeTexNoise'); t.inputs['Scale'].default_value = 30
        bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 0.35
        nt.links.new(t.outputs['Fac'], bp.inputs['Height']); nt.links.new(bp.outputs['Normal'], b.inputs['Normal'])
    if role == 'Aura':
        b.inputs['Alpha'].default_value = 0.75
    _mats[cle] = m
    return m


def nouvel_objet(nom, verts, faces, role, lisse=20):
    me = bpy.data.meshes.new(nom)
    me.from_pydata([i2b(v) for v in verts], [], faces)
    me.validate()
    o = bpy.data.objects.new(nom, me)
    COLL.objects.link(o)
    if isinstance(role, list):          # un rôle par face
        uniques = list(dict.fromkeys(role_reel(r) for r in role))
        for r in uniques:
            o.data.materials.append(materiau(r))
        for p, r in zip(me.polygons, role):
            p.material_index = uniques.index(role_reel(r))
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    if not isinstance(role, list):
        o.data.materials.append(materiau(role))
    lisser(o, lisse)
    return o


def actif(o):
    for x in bpy.context.selected_objects:
        x.select_set(False)
    bpy.context.view_layer.objects.active = o
    o.select_set(True)


def lisser(o, angle=20):
    actif(o)
    try:
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(angle))
    except Exception:
        bpy.ops.object.shade_flat()


# ------------------------------------------------------------------ primitives
def tube(boucles, role, nom='Piece', fermer=True, lisse=20):
    """Surface fermée passant par une suite de boucles (même nb de points) ; fermer = la dernière rejoint la 1re."""
    n = len(boucles[0]); verts = [p for b in boucles for p in b]; faces = []
    nb = len(boucles)
    for j in range(nb if fermer else nb - 1):
        j2 = (j + 1) % nb
        for i in range(n):
            a, b = j * n + i, j * n + (i + 1) % n
            faces.append((a, b, j2 * n + (i + 1) % n, j2 * n + i))
    if not fermer:
        faces.append(tuple(range(n - 1, -1, -1)))
        faces.append(tuple((nb - 1) * n + i for i in range(n)))
    return nouvel_objet(nom, verts, faces, role, lisse)


def fuseau(sections, role, cotes=4, tour=math.pi / 4, nom='Fuseau', cx=0.0, cz=0.0, aplat=1.0, lisse=20):
    """Solide de révolution facetté autour de l'axe Y : sections = [(y, rayon)], rayon 0 = pointe."""
    verts, faces, idx = [], [], []
    for y, r in sections:
        if r <= 1e-6:
            idx.append([len(verts)]); verts.append((cx, y, cz))
        else:
            ring = []
            for k in range(cotes):
                a = tour + 2 * math.pi * k / cotes
                ring.append(len(verts)); verts.append((cx + r * math.cos(a), y, cz + r * aplat * math.sin(a)))
            idx.append(ring)
    for j in range(len(idx) - 1):
        A, B = idx[j], idx[j + 1]
        for k in range(cotes):
            a0, a1 = A[k % len(A)], A[(k + 1) % len(A)]
            b0, b1 = B[k % len(B)], B[(k + 1) % len(B)]
            if len(A) == 1:
                faces.append((a0, b1, b0))
            elif len(B) == 1:
                faces.append((a0, a1, b0))
            else:
                faces.append((a0, a1, b1, b0))
    if len(idx[0]) > 1:
        faces.append(tuple(reversed(idx[0])))
    if len(idx[-1]) > 1:
        faces.append(tuple(idx[-1]))
    return nouvel_objet(nom, verts, faces, role, lisse)


def balayage(pts, largeurs, epaisseurs, normale, role, nom='Corne', lisse=20):
    """Section losange (largeur ⟂ normale, épaisseur selon normale) le long de pts (corne, bras, barbe)."""
    verts, faces = [], []
    n = len(pts)
    for i, p in enumerate(pts):
        t = nrm(sub(pts[min(i + 1, n - 1)], pts[max(i - 1, 0)]))
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
    return nouvel_objet(nom, verts, faces, role, lisse)


def pyramide(base, axe, h, r, role, cotes=4, tour=math.pi / 4, recul=0.06, aplat=1.0, nom='Pointe'):
    axe = nrm(axe)
    a1 = nrm(cross(axe, (0, 0, 1) if abs(axe[2]) < 0.9 else (1, 0, 0)))
    a2 = cross(axe, a1)
    verts = []
    for k in range(cotes):
        ang = tour + 2 * math.pi * k / cotes
        verts.append(add(base, add(mul(a1, r * math.cos(ang)), mul(a2, r * aplat * math.sin(ang)))))
    verts.append(add(base, mul(axe, h)))
    verts.append(add(base, mul(axe, -recul)))
    faces = [(k, (k + 1) % cotes, cotes) for k in range(cotes)] + [((k + 1) % cotes, k, cotes + 1) for k in range(cotes)]
    return nouvel_objet(nom, verts, faces, role, 15)


def helice(y0, y1, r, tours, phase, sens, larg, ep, role, n=64, nom='Tresse'):
    """Ruban hélicoïdal posé sur un cylindre d'axe Y (tresse de la poignée)."""
    boucles = []
    for i in range(n + 1):
        t = i / n
        a = phase + sens * 2 * math.pi * tours * t
        y = lerp(y0, y1, t)
        c, s = math.cos(a), math.sin(a)
        boucles.append([(r * c, y - larg / 2, r * s), ((r + ep) * c, y, (r + ep) * s),
                        (r * c, y + larg / 2, r * s), ((r - ep) * c, y, (r - ep) * s)])
    return tube(boucles, role, nom, fermer=False, lisse=40)


# ------------------------------------------------------------------ lame
RETOUR = 0.05
EPAIS = 1.25      # épaisseur de lame (multiplie les profils)


class Lame:
    """Lame paramétrée : bords lisses (gauche / droite) + encoches, section à colonnes (u, z, rôle)."""

    def __init__(self, s):
        self.s = dict(s)
        self.s['profil'] = [(u, z * EPAIS, r) for u, z, r in s['profil']]
        s = self.s
        self.y0 = s.get('y0', 0.50)
        self.yT = s.get('yT', 3.22)
        self.w0 = s.get('w0', 0.27)
        self.w1 = s.get('w1', 0.34)
        self.ySL = self.yT - s.get('pointeG', 0.80)   # début de la diagonale gauche
        self.ySR = self.yT - s.get('pointeD', 0.30)   # début de la (courte) diagonale droite
        self.xT = s.get('xT', 0.15)
        self.k = s.get('courbe', 0.0)
        self.enc = {'G': list(s.get('encG', [])), 'D': list(s.get('encD', []))}
        if s.get('dentele'):
            gr, amp = s['dentele']
            rnd = random.Random(gr)
            for cote in 'GD':
                y = self.y0 + 0.26 + rnd.uniform(0, 0.08)
                lim = (self.ySL if cote == 'G' else self.ySR) - 0.06
                while y < lim - 0.1:
                    l = rnd.uniform(0.22, 0.40)
                    kind = rnd.choice(('barbe', 'barbe', 'crochet', 'creux', 'barbe'))
                    h = amp * rnd.uniform(0.55, 1.0) * (1 if kind != 'creux' else 0.7)
                    self.enc[cote].append((y, min(y + l, lim), h, kind))
                    y += l + rnd.uniform(0.0, 0.05)

    def bords(self, y):
        """(xG, xD) lisses à la hauteur y."""
        t = (y - self.y0) / (self.yT - self.y0)
        w = lerp(self.w0, self.w1, min(1.0, t / 0.75))
        c = self.k * t * t
        xg, xd = c - w, c + w
        xT = self.xT + self.k
        if y > self.ySL:
            g0 = self.k * ((self.ySL - self.y0) / (self.yT - self.y0)) ** 2 - lerp(self.w0, self.w1, min(1.0, (self.ySL - self.y0) / (self.yT - self.y0) / 0.75))
            u = (y - self.ySL) / (self.yT - self.ySL)
            xg = lerp(g0, xT, u ** self.s.get('galbeG', 0.9))
        if y > self.ySR:
            d0 = self.k * ((self.ySR - self.y0) / (self.yT - self.y0)) ** 2 + lerp(self.w0, self.w1, min(1.0, (self.ySR - self.y0) / (self.yT - self.y0) / 0.75))
            u = (y - self.ySR) / (self.yT - self.ySR)
            xd = lerp(d0, xT, u)
        return xg, xd

    def decal(self, cote, y):
        d = 0.0
        for ya, yb, h, kind in self.enc[cote]:
            if not (ya <= y <= yb):
                continue
            t = (y - ya) / (yb - ya)
            if kind == 'barbe':          # dent qui monte vers l'extérieur, chute nette en haut
                d += h * t ** 1.6
            elif kind == 'crochet':      # festón concave puis épine fine qui remonte vers l'extérieur
                if t < 0.62:
                    d -= 0.32 * h * math.sin(math.pi * t / 0.62)
                else:
                    d += h * ((t - 0.62) / 0.38) ** 2.0
            elif kind == 'creux':        # festón concave
                d -= h * math.sin(math.pi * t)
            elif kind == 'marche':       # plaque de roche en saillie
                d += h
        for ya, yb, h, kind in self.enc[cote]:
            if kind == 'crochet' and yb < y <= yb + RETOUR:
                d += h * (1 - (y - yb) / RETOUR)
        return d

    def ys(self):
        pas = self.s.get('pas', 0.032)
        ys = set()
        y = self.y0
        while y < self.yT - 1e-6:
            ys.add(round(y, 5)); y += pas
        for cote in 'GD':
            for ya, yb, h, kind in self.enc[cote]:
                for v in (ya, yb, yb + 0.006, yb + RETOUR, ya + (yb - ya) * 0.62, ya + (yb - ya) * 0.85, ya + (yb - ya) * 0.95, ya - 0.006 if kind == 'marche' else ya, (ya + yb) / 2, ya + (yb - ya) * 0.75):
                    if self.y0 < v < self.yT:
                        ys.add(round(v, 5))
        ys.add(self.ySL); ys.add(self.ySR)
        for k in range(1, 6):
            ys.add(self.yT - 0.02 * k)
        ys.add(self.yT)
        return sorted(ys)

    def profil(self):
        return self.s['profil']

    def z_surface(self, y, u, dos=False):
        """z (face avant, valeur positive) de la surface à la fraction u (0 bord -> 1 centre)."""
        pr = self.profil()
        z = pr[-1][1]
        for i in range(1, len(pr)):
            if pr[i][0] >= u - 1e-9:
                u0, z0 = pr[i - 1][0], pr[i - 1][1]
                u1, z1 = pr[i][0], pr[i][1]
                z = z0 if u1 - u0 < 1e-6 else lerp(z0, z1, (u - u0) / (u1 - u0))
                break
        return z * self.amincit(y)

    def amincit(self, y):
        return max(0.0, min(1.0, (self.yT - y) / 0.42)) ** 0.7

    def pt(self, y, cote, u, z_off=0.0):
        xg, xd = self.bords(y)
        m = (xg + xd) / 2
        xb = xg if cote == 'G' else xd
        return (lerp(xb, m, u), y, self.z_surface(y, u) + z_off)

    def construire(self):
        s = self.s
        pr = self.profil()
        rnd = random.Random(s.get('graine', 7))
        roche = s.get('roche', 0.0)
        zone = s.get('fil_zone')
        objs = {}
        ys = self.ys()
        ncol = len(pr)
        # colonnes d'une rangée : G (bord -> centre) puis D (centre -> bord), centre partagé
        bruit = {}
        TB = 0.21

        def bruit_lisse(y, c):
            """bruit continu par morceaux (facettes de roche), décalé par colonne."""
            v = (y + 0.13 * c) / TB
            b = math.floor(v)
            for k in (b, b + 1):
                if (k, c) not in bruit:
                    bruit[(k, c)] = rnd.uniform(-1, 1) * roche * (0.4 if c == 0 else 1.0)
            return lerp(bruit[(b, c)], bruit[(b + 1, c)], v - b)

        rows_f, rows_b = [], []
        for y in ys:
            xg, xd = self.bords(y)
            m = (xg + xd) / 2
            am = self.amincit(y)
            rf, rb = [], []
            for cote, xb, sg in (('G', xg, -1), ('D', xd, 1)):
                d = self.decal(cote, y) if y < self.yT - 0.05 else 0.0
                for c, (u, z, role) in enumerate(pr):
                    x = lerp(xb, m, u) if c > 0 else xb + sg * d
                    zz = (z + (bruit_lisse(y, c) if roche and 0 < c else 0.0)) * am
                    if c == ncol - 1 and cote == 'D':
                        continue
                    rf.append((x, y, zz))
                    rb.append((x, y, -zz))
            # ordre : bord G ... centre ... bord D  (la partie D est parcourue centre -> bord)
            ng = ncol
            gauche_f, droite_f = rf[:ng], rf[ng:]
            gauche_b, droite_b = rb[:ng], rb[ng:]
            rows_f.append(gauche_f + list(reversed(droite_f)))
            rows_b.append(gauche_b + list(reversed(droite_b)))
        # rôles des bandes (entre colonne k et k+1) dans l'ordre G->D
        roles_g = [pr[c + 1][2] for c in range(ncol - 1)]
        roles = roles_g + list(reversed(roles_g))
        verts, faces_par_role = [], {}
        nr = len(ys); nc = len(rows_f[0])
        for r in rows_f:
            verts += r
        for r in rows_b:
            verts += r
        off_b = nr * nc

        def ajoute(role, f):
            faces_par_role.setdefault(role, []).append(f)

        for j in range(nr - 1):
            ymid = (ys[j] + ys[j + 1]) / 2
            for k in range(nc - 1):
                role = roles[k]
                if zone and role == 'Fil' and not (zone[0] <= ymid <= zone[1]):
                    role = 'Lame'
                a, b = j * nc + k, j * nc + k + 1
                ajoute(role, (a, b, b + nc, a + nc))
                ajoute(role, (off_b + a + nc, off_b + b + nc, off_b + b, off_b + a))
            # tranches (bord G et bord D) : rôle de la bande extérieure
            rg = roles[0]; rd = roles[-1]
            if zone and not (zone[0] <= ymid <= zone[1]):
                rg = 'Lame' if rg == 'Fil' else rg; rd = 'Lame' if rd == 'Fil' else rd
            a, an = j * nc, (j + 1) * nc
            ajoute(rg, (off_b + a, a, an, off_b + an))
            a, an = j * nc + nc - 1, (j + 1) * nc + nc - 1
            ajoute(rd, (a, off_b + a, off_b + an, an))
        # fond (caché dans la garde)
        ajoute('Lame', tuple(list(range(nc - 1, -1, -1)) + [off_b + i for i in range(nc)]))
        faces, roles_f = [], []
        for role, fs in faces_par_role.items():
            faces += fs; roles_f += [role] * len(fs)
        return [nouvel_objet('Lame', verts, faces, roles_f, s.get('lisse', 12))]

    def fissure(self, pts, role='Fissures', larg=0.026, ep=0.014, faces=(1, -1)):
        """pts = [(s, y)] : s dans [-1, 1] (bord G -> bord D) ; ruban posé sur la surface (avant et arrière)."""
        out = []
        for sg in faces:
            p3 = []
            for s_, y in pts:
                cote = 'G' if s_ < 0 else 'D'
                u = 1 - abs(s_)
                x, yy, z = self.pt(y, cote, u)
                p3.append((x, yy, sg * (z + ep * 0.35 + self.s.get('roche', 0) * 1.1)))
            largs = [larg * (0.55 if i in (0, len(p3) - 1) else 1.0) for i in range(len(p3))]
            out.append(balayage(p3, largs, [ep] * len(p3), (0, 0, 1), role, 'Fissure', 60))
        return out


# ------------------------------------------------------------------ garde, poignée, pommeau
G = 0.62           # centre de la garde
Y_MANCHE = (-0.47, 0.47)


def losange_cadre(c, hx, hy, k_in, z_out, z_in, z_fond, role):
    def boucle(kx, ky, z):
        return [(c[0], c[1] + hy * ky, z), (c[0] + hx * kx, c[1], z), (c[0], c[1] - hy * ky, z), (c[0] - hx * kx, c[1], z)]
    b = [boucle(1, 1, z_out), boucle(k_in, k_in, z_in), boucle(k_in * 0.92, k_in * 0.92, z_in - 0.012),
         boucle(k_in * 0.9, k_in * 0.9, z_fond), boucle(k_in * 0.9, k_in * 0.9, -z_fond),
         boucle(k_in * 0.92, k_in * 0.92, -z_in + 0.012), boucle(k_in, k_in, -z_in), boucle(1, 1, -z_out)]
    return tube(b, role, 'Cadre', lisse=10)


def gemme_losange(c, hx, hy, z_base, z_pointe, role):
    verts = [(c[0], c[1] + hy, 0), (c[0] + hx, c[1], 0), (c[0], c[1] - hy, 0), (c[0] - hx, c[1], 0),
             (c[0], c[1], z_pointe), (c[0], c[1], -z_pointe)]
    # base légèrement en retrait : facettes nettes
    verts = [(x, y, z) for x, y, z in verts]
    faces = [(0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4), (1, 0, 5), (2, 1, 5), (3, 2, 5), (0, 3, 5)]
    return nouvel_objet('Gemme', verts, faces, role, 5)


def anneau(c, r_out, r_in, z_out, z_in, role, n=20):
    def boucle(r, z):
        return [(c[0] + r * math.cos(2 * math.pi * k / n), c[1] + r * math.sin(2 * math.pi * k / n), z) for k in range(n)]
    b = [boucle(r_out, z_out), boucle(r_in + 0.02, z_in), boucle(r_in, z_in - 0.03), boucle(r_in, -z_in + 0.03),
         boucle(r_in + 0.02, -z_in), boucle(r_out, -z_out)]
    return tube(b, role, 'Anneau', lisse=35)


def garde(s):
    g = s.get('garde', {})
    objs = []
    forme = g.get('centre', 'losange')
    hx, hy = g.get('hx', 0.37), g.get('hy', 0.38)
    if forme == 'losange':
        objs.append(losange_cadre((0, G), hx, hy, 0.68, 0.08, 0.14, 0.06, 'Cadre'))
        if g.get('lisere'):
            objs.append(losange_cadre((0, G), hx * 0.7, hy * 0.7, 0.84, 0.138, 0.145, 0.06, 'Lisere'))
        objs.append(gemme_losange((0, G), hx * 0.6, hy * 0.6, 0, g.get('zgemme', 0.24), 'Gemme'))
    else:  # anneau rond (épée de bronze)
        objs.append(anneau((0, G), 0.27, 0.15, 0.08, 0.13, 'Cadre'))
        objs.append(gemme_rond((0, G), 0.155, 0.15))
        objs.append(pyramide((0, G + 0.25, 0), (0, 1, 0), 0.14, 0.1, 'Cadre', tour=math.pi / 4, aplat=0.8))
        objs.append(pyramide((0, G - 0.25, 0), (0, -1, 0), 0.11, 0.09, 'Cadre', tour=math.pi / 4, aplat=0.8))
    # bras
    xb = g.get('bras', 0.68)
    for sg in (-1, 1):
        pts = [(sg * hx * 0.55, G, 0), (sg * (xb * 0.6), G + g.get('releve', 0.0) * 0.4, 0), (sg * xb, G + g.get('releve', 0.0), 0)]
        objs.append(balayage(pts, [0.21, 0.18, 0.15], [0.16, 0.14, 0.13], (0, 0, 1), 'Bras', 'Bras', 15))
        bout = (sg * xb, G + g.get('releve', 0.0), 0)
        fin = g.get('bout', 'pyramide')
        if fin == 'pyramide':
            objs.append(pyramide(add(bout, (sg * 0.03, 0, 0)), (sg, 0.28, 0), g.get('hp', 0.30), g.get('rp', 0.13), 'Embout', recul=0.1))
        elif fin == 'croissant':
            hh, hb = g.get('corne_haut', 0.30) * 1.15, g.get('corne_bas', 0.20) * 1.15
            base = add(bout, (sg * 0.02, 0, 0))
            objs.append(balayage(courbe(add(base, (0, 0.02, 0)), add(base, (sg * 0.13, 0.05, 0)), add(base, (sg * 0.15, hh, 0)), 6),
                                 [0.19, 0.16, 0.13, 0.09, 0.05, 0.0], [0.13, 0.12, 0.10, 0.08, 0.05, 0.02], (0, 0, 1), 'Embout', 'Corne', 15))
            objs.append(balayage(courbe(add(base, (0, -0.02, 0)), add(base, (sg * 0.12, -0.04, 0)), add(base, (sg * 0.13, -hb, 0)), 6),
                                 [0.17, 0.14, 0.11, 0.08, 0.04, 0.0], [0.12, 0.11, 0.09, 0.07, 0.04, 0.02], (0, 0, 1), 'Embout', 'Corne', 15))
            objs.append(pyramide(base, (sg, 0.0, 0), 0.10, 0.09, 'Embout', recul=0.08))
        elif fin == 'ailes':
            for (dx, dy, cx_, cy_, l, z) in ((0.02, 0.42, -0.02, 0.16, 0.24, 0.0), (0.20, 0.26, 0.10, 0.06, 0.22, 0.02), (0.30, 0.06, 0.20, -0.02, 0.18, -0.02)):
                p0 = (sg * hx * 0.75, G + 0.02, z)
                objs.append(balayage(courbe(p0, (sg * (xb * 0.6 + cx_ + 0.1), G + cy_, z), (sg * (xb + dx), G + dy, z), 8),
                                     [l, l * 1.05, l * 0.95, l * 0.8, l * 0.6, l * 0.4, l * 0.2, 0.0],
                                     [0.12, 0.12, 0.11, 0.09, 0.07, 0.05, 0.03, 0.02], (0, 0, 1), 'Embout', 'Aile', 15))
            p0 = (sg * hx * 0.6, G - 0.12, 0)
            objs.append(balayage(courbe(p0, (sg * (xb * 0.6), G - 0.16, 0), (sg * (xb * 0.62 + 0.06), G - 0.02, 0), 6),
                                 [0.16, 0.14, 0.11, 0.08, 0.04, 0.0], [0.11, 0.10, 0.08, 0.06, 0.04, 0.02], (0, 0, 1), 'Embout', 'Crochet', 15))
    # pointes sous la garde (vers la poignée)
    if g.get('pointe_bas', True) and forme == 'losange':
        objs.append(pyramide((0, G - hy * 0.8, 0), (0, -1, 0), 0.12, 0.1, 'Cadre', recul=0.05))
    return objs


def gemme_rond(c, r, zp, n=10):
    verts = [(c[0] + r * math.cos(2 * math.pi * k / n), c[1] + r * math.sin(2 * math.pi * k / n), 0.0) for k in range(n)]
    verts += [(c[0], c[1], zp), (c[0], c[1], -zp)]
    faces = [(k, (k + 1) % n, n) for k in range(n)] + [((k + 1) % n, k, n + 1) for k in range(n)]
    return nouvel_objet('Gemme', verts, faces, 'Gemme', 30)


def poignee(s):
    p = s.get('poignee', {})
    y0, y1 = Y_MANCHE
    r = 0.115
    objs = [fuseau([(y0, r), (y1, r)], 'Manche', cotes=10, tour=0, nom='Manche', lisse=40)]
    nh = p.get('helices', 2)
    tours = p.get('tours', 2.6)
    for k in range(nh):
        sens = 1 if k == 0 else -1
        objs.append(helice(y0 + 0.02, y1 - 0.02, r, tours, 0.0 if k == 0 else math.pi, sens, p.get('larg', 0.11), 0.024, 'Tresse'))
    # bagues haut / bas (bord biseauté)
    for ya, yb in ((y1 - 0.06, y1 + 0.08), (y0 - 0.08, y0 + 0.06)):
        objs.append(fuseau([(ya, 0.12), (ya + 0.02, 0.155), (yb - 0.02, 0.155), (yb, 0.12)], 'Bague', cotes=8, tour=math.pi / 8, nom='Bague'))
    return objs


def pommeau(s):
    p = s.get('pommeau', {})
    yb = Y_MANCHE[0] - 0.08
    r = p.get('r', 0.27)
    objs = [fuseau([(yb + 0.01, 0.0), (yb - 0.01, 0.13), (yb - 0.14, r), (yb - 0.2, r * 0.92), (yb - p.get('long', 0.46), 0.0)],
                   'Pommeau', cotes=4, tour=math.pi / 4, nom='Pommeau', lisse=10)]
    if p.get('ergots'):
        for sg in (-1, 1):
            b = (sg * 0.12, yb - 0.17, 0)
            objs.append(balayage(courbe(b, (sg * 0.28, yb - 0.22, 0), (sg * 0.34, yb - 0.04, 0), 6),
                                 [0.13, 0.11, 0.09, 0.06, 0.03, 0.0], [0.10, 0.09, 0.07, 0.05, 0.03, 0.02], (0, 0, 1), 'Pommeau', 'Ergot', 15))
    return objs


def aura():
    """Deux volutes dorées (rubans fins) enroulées autour de la lame de l'épée d'or."""
    objs = []
    for k, (ph, ra, rb, y0, y1, tours) in enumerate(((0.3, 0.55, 0.40, 0.25, 2.9, 1.6), (2.6, 0.48, 0.62, 0.45, 2.5, 1.25))):
        boucles = []
        n = 90
        for i in range(n + 1):
            t = i / n
            a = ph + 2 * math.pi * tours * t
            r = lerp(ra, rb, t) * (0.85 + 0.15 * math.sin(3 * t))
            y = lerp(y0, y1, t) + 0.12 * math.sin(a * 0.5)
            c = (r * math.cos(a), y, r * math.sin(a) * 0.75)
            ep = 0.012; lg = 0.05 * math.sin(math.pi * t) ** 0.6 + 0.004
            boucles.append([add(c, (0, -lg / 2, 0)), add(c, (ep * math.cos(a), 0, ep * math.sin(a))),
                            add(c, (0, lg / 2, 0)), add(c, (-ep * math.cos(a), 0, -ep * math.sin(a)))])
        objs.append(tube(boucles, 'Aura', 'Aura', fermer=False, lisse=60))
    return objs


# ------------------------------------------------------------------ catalogue (fidèle à la planche de référence)
P_ROCHE = [(0, 0.030, None), (0.26, 0.066, 'Fil'), (0.5, 0.080, 'Lame'), (0.75, 0.090, 'Lame'), (1, 0.094, 'Lame')]
P_ROCHE_FIL = [(0, 0.018, None), (0.30, 0.070, 'Fil'), (0.30, 0.052, 'Fil'), (0.55, 0.075, 'Lame'), (0.8, 0.088, 'Lame'), (1, 0.09, 'Lame')]
P_LISSE = [(0, 0.016, None), (0.26, 0.060, 'Fil'), (1, 0.090, 'Lame')]
P_CADRE = [(0, 0.016, None), (0.38, 0.078, 'Fil'), (0.38, 0.050, 'Fil'), (0.86, 0.064, 'Lame'), (1, 0.082, 'Gorge')]
P_FER = [(0, 0.014, None), (0.56, 0.074, 'Fil'), (0.56, 0.048, 'Fil'), (1, 0.062, 'Lame')]
P_OR = [(0, 0.016, None), (0.30, 0.074, 'Fil'), (0.30, 0.056, 'Fil'), (0.74, 0.066, 'Lame'), (0.74, 0.080, 'Gorge'), (1, 0.096, 'Gorge')]


def B(ya, yb, h, k='barbe'):
    return (ya, yb, h, k)


EPEES = [
    ('EpeeCharbon', 'Charbon', dict(
        pal={'Lame': ROCHE, 'Fil': ROCHE_CL, 'Garde': ROCHE, 'Cadre': ROCHE_CL, 'Gemme': ROCHE_CL, 'Embout': ROCHE_CL,
             'Manche': ROCHE_SO, 'Tresse': ROCHE_CL, 'Pommeau': ROCHE_CL},
        lame=dict(profil=P_ROCHE, dentele=(11, 0.075), roche=0.034, graine=3, lisse=8),
        garde=dict(bout='pyramide', hp=0.30, rp=0.13, releve=0.03), poignee=dict(helices=2, tours=2.2))),
    ('EpeeCharbonBronze', 'Charbon & Cuivre', dict(
        pal={'Lame': ROCHE, 'Fil': CUIVRE_CL, 'Garde': CUIVRE, 'Cadre': CUIVRE_CL, 'Gemme': ROCHE, 'Embout': CUIVRE_CL,
             'Manche': ROCHE_SO, 'Tresse': CUIVRE, 'Pommeau': CUIVRE_CL, 'Fissures': NEON_ORANGE},
        lame=dict(profil=P_ROCHE, dentele=(23, 0.07), roche=0.022, graine=5, lisse=8, fil_zone=(2.32, 9)),
        fissures=[[(0.05, 0.95), (0.2, 1.35), (0.05, 1.7), (0.3, 2.05), (0.15, 2.4), (0.45, 2.75)],
                  [(0.05, 1.7), (-0.35, 1.95), (-0.25, 2.2)], [(0.2, 1.35), (0.55, 1.5)]],
        garde=dict(bout='croissant', corne_haut=0.32, corne_bas=0.22), poignee=dict(helices=2, tours=2.2))),
    ('EpeeCharbonFer', 'Charbon & Fer', dict(
        pal={'Lame': ROCHE, 'Fil': FER_CL, 'Garde': FER_CL, 'Cadre': FER_CL, 'Gemme': FER_CL, 'Embout': FER_CL, 'Bras': FER,
             'Manche': ROCHE_SO, 'Tresse': FER_SO, 'Pommeau': FER_CL},
        lame=dict(profil=P_ROCHE_FIL, dentele=(37, 0.07), roche=0.02, graine=9, lisse=8, pas=0.042),
        garde=dict(bout='pyramide', hp=0.30, rp=0.13, releve=0.04, lisere=True), poignee=dict(helices=2, tours=2.4))),
    ('EpeeCharbonOr', 'Charbon & Or', dict(
        pal={'Lame': ROCHE, 'Fil': OR, 'Garde': OR, 'Cadre': OR_CL, 'Gemme': NEON_OR, 'Embout': OR,
             'Manche': CUIR, 'Tresse': CUIR_BRUN, 'Bague': OR, 'Pommeau': OR, 'Fissures': NEON_OR},
        lame=dict(profil=P_ROCHE_FIL, dentele=(41, 0.07), roche=0.02, graine=13, lisse=8, pas=0.042),
        fissures=[[(0.62, 1.0), (0.55, 1.35), (0.68, 1.7), (0.5, 2.0)], [(-0.6, 1.25), (-0.66, 1.6), (-0.55, 1.9)],
                  [(0.1, 2.2), (0.25, 2.45)]],
        garde=dict(bout='pyramide', hp=0.30, rp=0.13, releve=0.04), poignee=dict(helices=2, tours=2.2))),
    ('EpeeBronze', 'Cuivre', dict(
        pal={'Lame': CUIVRE, 'Fil': CUIVRE_CL, 'Garde': CUIVRE, 'Cadre': CUIVRE_CL, 'Gemme': CUIVRE_SO, 'Embout': CUIVRE_CL,
             'Manche': CUIVRE_SO, 'Tresse': CUIVRE, 'Pommeau': CUIVRE_CL},
        lame=dict(profil=P_LISSE, encG=[B(1.0, 1.28, 0.10, 'crochet'), B(1.36, 1.62, 0.09, 'crochet')],
                  encD=[B(1.28, 1.52, 0.08, 'crochet'), B(1.60, 1.82, 0.07, 'crochet')]),
        garde=dict(centre='anneau', bout='croissant', corne_haut=0.26, corne_bas=0.2), poignee=dict(helices=1, tours=3.2, larg=0.09))),
    ('EpeeBronzeCharbon', 'Cuivre & Charbon', dict(
        pal={'Lame': ROCHE, 'Fil': CUIVRE, 'Garde': CUIVRE, 'Cadre': CUIVRE_CL, 'Gemme': NEON_ORANGE, 'Embout': CUIVRE_CL,
             'Manche': ROCHE_SO, 'Tresse': CUIVRE, 'Pommeau': CUIVRE_CL, 'Fissures': NEON_ORANGE},
        lame=dict(profil=P_ROCHE, roche=0.02, graine=17, lisse=8, fil_zone=(0, 1.55),
                  encG=[B(0.92, 1.20, 0.09, 'crochet'), B(1.30, 1.60, 0.09, 'crochet'), B(1.72, 2.02, 0.08, 'crochet'), B(2.1, 2.3, 0.05, 'creux')],
                  encD=[B(1.05, 1.30, 0.07, 'crochet'), B(1.42, 1.70, 0.08, 'crochet'), B(1.85, 2.15, 0.06, 'crochet')]),
        fissures=[[(0.15, 0.9), (0.4, 1.3), (0.3, 1.6), (0.55, 1.95), (0.45, 2.3), (0.7, 2.6), (0.6, 2.85)],
                  [(0.3, 1.6), (-0.1, 1.8)], [(0.45, 2.3), (0.15, 2.45)], [(-0.3, 1.05), (-0.45, 1.3)]],
        garde=dict(bout='croissant', corne_haut=0.34, corne_bas=0.18), poignee=dict(helices=2, tours=2.2))),
    ('EpeeBronzeFer', 'Cuivre & Fer', dict(
        pal={'Lame': FER_CL, 'Gorge': FER, 'Fil': CUIVRE, 'Garde': BRONZE_DORE, 'Cadre': BRONZE_DORE, 'Gemme': FER_CL,
             'Embout': CUIVRE, 'Bras': CUIVRE, 'Manche': CUIVRE_SO, 'Tresse': CUIVRE, 'Pommeau': CUIVRE},
        lame=dict(profil=P_CADRE,
                  encG=[B(0.95, 1.25, 0.11, 'crochet'), B(1.40, 1.70, 0.11, 'crochet'), B(1.85, 2.15, 0.09, 'crochet')],
                  encD=[B(1.10, 1.40, 0.11, 'crochet'), B(1.58, 1.88, 0.09, 'crochet'), B(2.0, 2.3, 0.08, 'crochet')]),
        garde=dict(bout='croissant', corne_haut=0.32, corne_bas=0.2, lisere=True), poignee=dict(helices=2, tours=2.6))),
    ('EpeeBronzeOr', 'Cuivre & Or', dict(
        pal={'Lame': OR_SO, 'Gorge': OR, 'Fil': OR_CL, 'Garde': OR, 'Cadre': OR_CL, 'Gemme': NEON_OR, 'Embout': OR,
             'Manche': CUIR, 'Tresse': OR, 'Pommeau': OR, 'Fissures': NEON_OR},
        lame=dict(profil=P_CADRE, courbe=0.45, pointeG=0.85,
                  encG=[B(1.00, 1.30, 0.12, 'crochet'), B(1.50, 1.80, 0.11, 'crochet')],
                  encD=[B(1.25, 1.55, 0.06, 'creux')]),
        fissures='cadre',
        garde=dict(bout='croissant', corne_haut=0.32, corne_bas=0.2), poignee=dict(helices=2, tours=2.6))),
    ('EpeeFerPur', 'Fer', dict(
        pal={'Lame': FER_SO, 'Fil': FER_CL, 'Garde': FER_CL, 'Cadre': FER_CL, 'Lisere': FER_SO, 'Gemme': FER_CL,
             'Embout': FER_CL, 'Bras': FER_SO, 'Manche': FER_SO, 'Tresse': FER, 'Pommeau': FER_CL},
        lame=dict(profil=P_FER,
                  encG=[B(1.05, 1.38, 0.15, 'crochet'), B(1.55, 1.88, 0.14, 'crochet'), B(2.05, 2.30, 0.09, 'crochet')],
                  encD=[B(1.20, 1.52, 0.14, 'crochet'), B(1.72, 2.02, 0.12, 'crochet')]),
        garde=dict(bout='croissant', corne_haut=0.34, corne_bas=0.24, lisere=True),
        poignee=dict(helices=2, tours=2.6), pommeau=dict(ergots=True))),
    ('EpeeFerOr', 'Fer & Or', dict(
        pal={'Lame': FER_CL, 'Gorge': FER, 'Fil': OR, 'Garde': OR, 'Cadre': OR_CL, 'Gemme': OR_CL, 'Embout': OR,
             'Manche': OR_SO, 'Tresse': OR, 'Pommeau': OR},
        lame=dict(profil=P_CADRE,
                  encG=[B(0.92, 1.20, 0.14, 'crochet'), B(1.32, 1.62, 0.14, 'crochet'), B(1.75, 2.05, 0.12, 'crochet'), B(2.15, 2.40, 0.09, 'crochet')],
                  encD=[B(1.05, 1.35, 0.12, 'crochet'), B(1.50, 1.80, 0.12, 'crochet'), B(1.95, 2.25, 0.09, 'crochet')]),
        garde=dict(bout='croissant', corne_haut=0.36, corne_bas=0.24, lisere=True), poignee=dict(helices=2, tours=2.6))),
    ('EpeeOr', 'Or', dict(
        pal={'Lame': OR, 'Gorge': OR_CL, 'Fil': OR_CL, 'Garde': OR, 'Cadre': OR_CL, 'Gemme': NEON_OR, 'Embout': OR_CL,
             'Manche': OR_SO, 'Tresse': OR_CL, 'Pommeau': OR_CL, 'Fissures': NEON_OR, 'Aura': AURA_OR},
        lame=dict(profil=P_OR, courbe=0.10, encG=[B(0.92, 1.12, 0.05, 'crochet')], encD=[B(0.98, 1.18, 0.05, 'crochet')]),
        fissures='cadre', aura=True,
        garde=dict(bout='ailes', bras=0.5), poignee=dict(helices=2, tours=2.8), pommeau=dict(long=0.5))),
]
TITRES = [t for _, t, _ in EPEES]
NOMS = {'EpeeCharbon': 'Épée de charbon', 'EpeeCharbonBronze': 'Épée de charbon et bronze', 'EpeeCharbonFer': 'Épée de charbon et fer',
        'EpeeCharbonOr': 'Épée de charbon et or', 'EpeeBronze': 'Épée de bronze', 'EpeeBronzeCharbon': 'Épée de bronze et charbon',
        'EpeeBronzeFer': 'Épée de bronze et fer', 'EpeeBronzeOr': 'Épée de bronze et or', 'EpeeFerPur': 'Épée de fer pur',
        'EpeeFerOr': 'Épée de fer et or', 'EpeeOr': "Épée d'or"}


def construire(cid, spec):
    global EPEE, PAL
    EPEE = cid
    PAL = dict(spec['pal'])
    l = Lame(spec['lame'])
    objs = l.construire()
    fi = spec.get('fissures')
    if fi == 'cadre':   # liseres lumineux le long du cadre (intérieur du fil)
        u = spec['lame']['profil'][1][0]
        for sg in (-1, 1):
            pts = []
            y = l.y0 + 0.30
            while y < l.yT - 0.22:
                pts.append((sg * (1 - u - 0.015), y)); y += 0.12
            objs += l.fissure(pts, larg=0.022, ep=0.012)
    elif fi:
        for pl in fi:
            objs += l.fissure(pl)
    objs += garde(spec)
    objs += poignee(spec)
    objs += pommeau(spec)
    if spec.get('aura'):
        objs += aura()
    tA = (0, l.y0 + 0.45, 0)
    tB = (l.xT + l.k, l.yT - 0.08, 0)
    return objs, tA, tB


# ------------------------------------------------------------------ assemblage par rôle, export
def assembler(cid, objs):
    actif(objs[0])
    for o in objs:
        o.select_set(True)
    bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.separate(type='MATERIAL')
    bpy.ops.object.mode_set(mode='OBJECT')
    parts = {}
    for ob in bpy.context.selected_objects:
        utilises = set(p.material_index for p in ob.data.polygons)
        if not utilises:
            continue
        mat = ob.data.materials[min(utilises)]
        for p in ob.data.polygons:
            p.material_index = 0
        ob.data.materials.clear(); ob.data.materials.append(mat)
        role = mat['role']
        ob.name = role; ob.data.name = cid + '_' + role
        parts[role] = ob
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=0.1)
    me = bpy.data.meshes.new(cid + '_Poignee'); bm.to_mesh(me); bm.free()
    r = bpy.data.objects.new('Poignee', me); COLL.objects.link(r)
    r.data.materials.append(materiau('Poignee'))
    parts['Poignee'] = r
    return parts


def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def exporter(cid, parts):
    os.makedirs(D_FBX, exist_ok=True)
    for x in bpy.context.selected_objects:
        x.select_set(False)
    for o in parts.values():
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts['Poignee']
    dest = os.path.join(D_FBX, cid + '.fbx')
    bpy.ops.export_scene.fbx(filepath=dest, use_selection=True, object_types={'MESH'}, global_scale=1.0,
                             apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE', axis_forward='-Z', axis_up='Y',
                             mesh_smooth_type='FACE', use_mesh_modifiers=True, bake_space_transform=True,
                             add_leaf_bones=False, path_mode='AUTO')
    return dest


def bornes(parts):
    lo = [1e9] * 3; hi = [-1e9] * 3
    for n, o in parts.items():
        if n in ('Poignee', 'Aura'):
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
    nt = w.node_tree
    bg = nt.nodes['Background']; bg.inputs[0].default_value = (0.03, 0.03, 0.036, 1); bg.inputs[1].default_value = 1.0
    # éclairage d'ambiance clair (reflets des métaux) mais fond sombre pour la caméra
    env = nt.nodes.new('ShaderNodeBackground'); env.inputs[0].default_value = (0.32, 0.32, 0.35, 1); env.inputs[1].default_value = 1.0
    lp = nt.nodes.new('ShaderNodeLightPath'); mx = nt.nodes.new('ShaderNodeMixShader')
    nt.links.new(lp.outputs['Is Camera Ray'], mx.inputs[0])
    nt.links.new(env.outputs[0], mx.inputs[1]); nt.links.new(bg.outputs[0], mx.inputs[2])
    nt.links.new(mx.outputs[0], nt.nodes['World Output'].inputs['Surface'])

    def soleil(nom, e, rot, col):
        l = bpy.data.lights.new(nom, 'SUN'); l.energy = e; l.color = col
        o = bpy.data.objects.new(nom, l); sc.collection.objects.link(o)
        o.rotation_euler = Euler(tuple(math.radians(a) for a in rot))
    soleil('cle', 4.0, (-40, 0, 150), (1, 0.92, 0.82))
    soleil('remplissage', 1.6, (-60, 0, 230), (0.78, 0.84, 1))
    soleil('contre', 2.5, (60, 0, 30), (1, 0.85, 0.7))
    soleil('haut', 1.0, (0, 0, 0), (1, 1, 1))
    cam = bpy.data.cameras.new('C'); cam.type = 'ORTHO'
    co = bpy.data.objects.new('C', cam); sc.collection.objects.link(co); sc.camera = co
    try:
        sc.eevee.use_bloom = True
    except Exception:
        pass
    return sc, co


def instance(parts, loc, spin_deg, tilt_deg=0.0, echelle=1.0):
    piv = bpy.data.objects.new('Piv', None); bpy.context.scene.collection.objects.link(piv)
    piv.location = loc; piv.rotation_mode = 'ZYX'
    piv.rotation_euler = Euler((0, math.radians(tilt_deg), math.radians(spin_deg)), 'ZYX')
    piv.scale = (echelle,) * 3
    crees = [piv]
    for n, o in parts.items():
        if n == 'Poignee':
            continue
        c = o.copy(); c.data = o.data; c.hide_render = False
        bpy.context.scene.collection.objects.link(c)
        c.parent = piv; c.matrix_parent_inverse = Matrix.Identity(4)
        crees.append(c)
    return crees


def texte(corps, loc, taille=0.24):
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
    co.location = (0, 30, cz)
    co.rotation_euler = Euler((math.radians(90), 0, math.radians(180)))
    os.makedirs(D_PNG, exist_ok=True)
    sc.render.filepath = os.path.join(D_PNG, nom)
    bpy.ops.render.render(write_still=True)
    print('EPEE_PNG', sc.render.filepath)
    for o in crees:
        bpy.data.objects.remove(o, do_unlink=True)


# ------------------------------------------------------------------ Luau
def v3(v):
    return 'Vector3.new(%.3f, %.3f, %.3f)' % tuple(v)


def ecrire_lua(table):
    L = ['-- Généré par blender/armes/epees_fideles.py. Ne pas modifier à la main.',
         '-- Épées mesh (ReplicatedStorage.EpeesMesh.<Id>, importées depuis assets/epees/<Id>.fbx) :',
         '-- sous-mesh (nom de MeshPart) -> apparence Roblox. Repère = Poignee (centre de la prise, lame vers +Y, plat face à -Z).',
         '-- Taille / Centre = boîte attendue (studs, sans Poignee ni Aura) ; TrailA / TrailB = base / pointe de la lame ;',
         '-- Teinte = couleur du minerai pour la version de secours (EpeeFer teintée) tant que le mesh n\'est pas importé.',
         'return {']
    for cid, e in table.items():
        L.append('\t%s = {' % cid)
        L.append('\t\tNom = "%s",' % NOMS.get(cid, cid))
        L.append('\t\tTaille = %s,' % v3(e['Taille']))
        L.append('\t\tCentre = %s,' % v3(e['Centre']))
        L.append('\t\tTrailA = %s,' % v3(e['TrailA']))
        L.append('\t\tTrailB = %s,' % v3(e['TrailB']))
        L.append('\t\tTeinte = Color3.fromRGB(%d, %d, %d),' % tuple(e['Teinte']))
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
    p = os.path.join(D_LUA, 'EpeesMeshMateriaux.lua')
    open(p, 'w', encoding='utf8', newline='\n').write('\n'.join(L) + '\n')
    print('EPEE_LUA', p)


# positions (px) du centre de la prise dans l'image de référence 1536 x 1024
PLANCHE = [(196, 334), (452, 334), (716, 334), (980, 334), (1250, 334),
           (140, 790), (374, 790), (602, 790), (845, 790), (1090, 790), (1362, 790)]
LABELS = [(183, 441), (445, 441), (712, 441), (975, 441), (1245, 441),
          (131, 942), (366, 942), (593, 942), (836, 942), (1082, 942), (1354, 942)]


def main():
    global COLL
    bpy.ops.wm.read_factory_settings(use_empty=True)
    COLL = bpy.context.scene.collection
    choix = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    sc, co = scene_rendu()
    chemin_json = os.path.join(D_FBX, 'materiaux.json')
    table = json.load(open(chemin_json, encoding='utf8')) if os.path.exists(chemin_json) else {}
    tous = {}
    for cid, titre, spec in EPEES:
        if choix and cid not in choix and 'planche' not in choix:
            continue
        objs, tA, tB = construire(cid, spec)
        parts = assembler(cid, objs)
        exporter(cid, parts)
        for n, o in parts.items():
            o.name = cid + '_' + n
        lo, hi = bornes(parts)
        nb = sum(tris(o) for n, o in parts.items() if n != 'Poignee')
        print('EPEE', cid, 'tris', nb, 'parties', sorted(k for k in parts if k != 'Poignee'))
        teinte = spec['pal']['Fil'][1] if spec['pal']['Fil'][0] != 'Slate' else spec['pal']['Lame'][1]
        if cid == 'EpeeCharbon':
            teinte = (60, 58, 66)
        table[cid] = {'Taille': [round(h - l, 3) for l, h in zip(lo, hi)],
                      'Centre': [round((h + l) / 2, 3) for l, h in zip(lo, hi)],
                      'TrailA': [-tA[0], tA[1], tA[2]], 'TrailB': [round(-tB[0], 3), round(tB[1], 3), tB[2]],
                      'Teinte': list(teinte), 'Triangles': nb, 'Parties': {}}
        for n in parts:
            r = role_reel(n) if n != 'Poignee' else 'Poignee'
            rm, c, *_ = PAL[r] if n != 'Poignee' else MARQUEUR
            e = {'Material': rm, 'Color': list(c), 'Transparency': TRANSPARENCE.get(n, 0)}
            if n in LUMIERES and rm == 'Neon':
                e['PointLight'] = {'Couleur': list(c), 'Portee': LUMIERES[n], 'Luminosite': 1.2}
            table[cid]['Parties'][n] = e
        for o in parts.values():
            o.hide_render = True
            o.location = (0, 0, 0)
        tous[cid] = parts
        crees = []
        for x, rot in ((2.3, 0), (0, 90), (-2.3, 180)):
            crees += instance(parts, (x, 0, 0), rot)
        rendre(sc, co, cid + '.png', (1100, 820), 7.0, 1.15, crees)
    json.dump(table, open(chemin_json, 'w', encoding='utf8'), indent=1, ensure_ascii=False)
    ordre = [c for c, _, _ in EPEES]
    ecrire_lua(dict(sorted(((k, v) for k, v in table.items() if k in ordre), key=lambda kv: ordre.index(kv[0]))))
    if len(tous) == len(EPEES):
        crees = []
        px = 100.0
        for k, (cid, _, _) in enumerate(EPEES):
            u, v = PLANCHE[k]
            crees += instance(tous[cid], (-(u - 768) / px, 0, (512 - v) / px), -28, -15, 0.97)
            lu, lv = LABELS[k]
            crees.append(texte(TITRES[k], (-(lu - 768) / px, 0.5, (512 - lv) / px - 0.08)))
        rendre(sc, co, 'EpeesFideles.png', (1536, 1024), 15.36, 0.0, crees)


main()
