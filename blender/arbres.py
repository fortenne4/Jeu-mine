"""Arbres modélisés : saule pleureur et pin sylvestre (d'après les photos de référence).
    blender --background --factory-startup --python blender/arbres.py

Repère L : y = haut, pied du tronc en (0, 0, 0).
Variantes : Saule1..2 et Pin1..3. Pièces (couleurs appliquées par le jeu) :
    SauleN_Tronc (fût, racines, charpentières), SauleN_Feuillage (masse sombre du dôme),
    SauleN_Rameaux, SauleN_RameauxClairs, SauleN_RameauxSombres (rideaux qui pendent),
    SauleN_Feuilles, SauleN_FeuillesClaires (petites feuilles effilées le long des rameaux)
    PinN_Ecorce (bas du fût, gris-brun, racines), PinN_Tronc (haut du fût, orangé), PinN_Branches,
    PinN_Aiguilles, PinN_AiguillesClaires (aiguilles en goupillon), PinN_AiguillesSombres (cœur des touffes), PinN_Pommes (pommes de pin)
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import math, random
import bmesh
from mathutils import Vector, Matrix, noise
from commun import *

TEINTES = {
    "Tronc": (92, 70, 52), "Feuillage": (58, 84, 40), "Rameaux": (96, 128, 58), "RameauxClairs": (138, 160, 78),
    "Ecorce": (96, 80, 66), "TroncPin": (176, 98, 54), "Branches": (84, 64, 48),
    "Aiguilles": (46, 80, 42), "AiguillesClaires": (84, 122, 54),
    "RameauxSombres": (70, 98, 46), "Feuilles": (110, 140, 62), "FeuillesClaires": (160, 176, 92),
    "Pommes": (118, 84, 52), "AiguillesSombres": (34, 58, 34),
}
HAUT = Vector((0, 1, 0))
OR = math.pi * (3 - math.sqrt(5))  # angle d'or


class Maillage:
    """Accumule sommets et faces (repère L) avant de créer l'objet."""

    def __init__(self):
        self.v, self.f = [], []

    def tube(self, pts, rayons, cotes=6, axe=None, aplati=1.0, fermer=True, ondule=None):
        """Tube le long d'une polyligne. axe : direction de la largeur (sinon transport parallèle).
        aplati : épaisseur / largeur. ondule(i) : facteur de largeur par anneau."""
        n = len(pts)
        if n < 2:
            return
        tang = []
        for i in range(n):
            a, b = pts[max(0, i - 1)], pts[min(n - 1, i + 1)]
            tang.append((b - a).normalized())
        ref = Vector((1, 0, 0)) if abs(tang[0].x) < 0.9 else Vector((0, 0, 1))
        N = (ref - tang[0] * ref.dot(tang[0])).normalized()
        base = len(self.v)
        for i in range(n):
            t = tang[i]
            if axe is not None:
                N = (axe - t * axe.dot(t))
                N = N.normalized() if N.length > 1e-5 else N
            elif i > 0:
                N = tang[i - 1].rotation_difference(t) @ N
                N = (N - t * N.dot(t)).normalized()
            B = t.cross(N)
            r = rayons[i] * (ondule(i) if ondule else 1.0)
            for k in range(cotes):
                a = 2 * math.pi * k / cotes
                self.v.append(pts[i] + N * (math.cos(a) * r) + B * (math.sin(a) * r * aplati))
        for i in range(n - 1):
            for k in range(cotes):
                j = (k + 1) % cotes
                self.f.append((base + i * cotes + k, base + i * cotes + j,
                               base + (i + 1) * cotes + j, base + (i + 1) * cotes + k))
        if fermer:
            self.f.append(tuple(base + k for k in reversed(range(cotes))))
            self.f.append(tuple(base + (n - 1) * cotes + k for k in range(cotes)))

    def boule(self, centre, rayons, rng, bosses=0.28, freq=1.6, rot=0.0):
        """Ellipsoïde bosselé (icosphère subdivisée + bruit)."""
        o = Vector((rng.uniform(-90, 90), rng.uniform(-90, 90), rng.uniform(-90, 90)))
        base = len(self.v)
        R = Matrix.Rotation(rot, 3, 'Y')
        for p in ICO_V:
            k = 1 + bosses * noise.noise(p * freq + o)
            q = Vector((p.x * rayons[0], p.y * rayons[1], p.z * rayons[2])) * k
            self.v.append(centre + R @ q)
        for f in ICO_F:
            self.f.append(tuple(base + i for i in f))

    def cone(self, base, direction, longueur, rayon, cotes=4):
        """Cône fin (pinceau d'aiguilles, brindille)."""
        d = direction.normalized()
        ref = Vector((1, 0, 0)) if abs(d.x) < 0.9 else Vector((0, 0, 1))
        N = (ref - d * ref.dot(d)).normalized()
        B = d.cross(N)
        b0 = len(self.v)
        for k in range(cotes):
            a = 2 * math.pi * k / cotes
            self.v.append(base + (N * math.cos(a) + B * math.sin(a)) * rayon)
        self.v.append(base + d * longueur)
        for k in range(cotes):
            self.f.append((b0 + k, b0 + (k + 1) % cotes, b0 + cotes))
        self.f.append(tuple(b0 + k for k in reversed(range(cotes))))

    def feuille(self, p, direction, cote, longueur, largeur, epaisseur=0.25):
        """Feuille effilée (losange avec un peu d'épaisseur, visible des deux côtés)."""
        d = direction.normalized()
        s = (cote - d * cote.dot(d)).normalized()
        n = d.cross(s)
        m = p + d * longueur * 0.42
        b0 = len(self.v)
        self.v += [p, p + d * longueur, m + s * largeur, m + n * largeur * epaisseur,
                   m - s * largeur, m - n * largeur * epaisseur]
        tour = (2, 3, 4, 5)
        for i in range(4):
            a, b = tour[i], tour[(i + 1) % 4]
            self.f.append((b0, b0 + a, b0 + b))
            self.f.append((b0 + 1, b0 + b, b0 + a))

    def objet(self, nom, mat, decal, lisser=True, angle=None):
        me = bpy.data.meshes.new(nom)
        M = Matrix.Translation(Vector(decal)) @ CONV
        me.from_pydata([M @ v for v in self.v], [], self.f)
        bm = bmesh.new()
        bm.from_mesh(me)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(me)
        bm.free()
        ob = lier(bpy.data.objects.new(nom, me))
        me.materials.append(mat)
        if lisser:
            lisse(ob, angle)
        return ob


def _ico():
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
    v = [x.co.copy() for x in bm.verts]
    bm.verts.index_update()
    f = [tuple(x.index for x in face.verts) for face in bm.faces]
    bm.free()
    return v, f


ICO_V, ICO_F = _ico()


def racines(m, rng, centre, nb, rayon, longueur):
    """Racines apparentes qui partent du pied et plongent dans le sol."""
    for i in range(nb):
        a = i * 2 * math.pi / nb + rng.uniform(-0.3, 0.3)
        h = Vector((math.cos(a), 0, math.sin(a)))
        p0 = centre(rayon * 0.6) + h * rayon * 0.5
        L = longueur * rng.uniform(0.6, 1.1)
        pts = courbe(p0, h + HAUT * -0.25, L, 5, lambda u: Vector((0, -0.06 * u, 0)), rng, 0.12)
        pts[-1].y = min(pts[-1].y, -0.3)
        r = rayon * rng.uniform(0.35, 0.5)
        m.tube(pts, [r * (1 - 0.75 * k / 5) for k in range(6)], cotes=7)


def fut(m_bas, m_haut, rng, hauteur, rayon, coupe, flare=0.3, sillons=0.0, penche=0.25, seg=16, anneaux=40,
        plaques=0.0):
    """Tronc à écorce bruitée ; les anneaux sous `coupe` vont dans m_bas, les autres dans m_haut."""
    o = rng.uniform(0, 100)
    ph1, ph2 = rng.uniform(0, 6.3), rng.uniform(0, 6.3)

    def centre(y):
        return Vector((penche * math.sin(y * 0.13 + ph1) + 0.04 * y * math.cos(ph1),
                       y, penche * 0.8 * math.sin(y * 0.1 + ph2) + 0.04 * y * math.sin(ph1)))

    def anneau(y):
        u = y / hauteur
        r = rayon(u) + flare * math.exp(-y / (0.08 * hauteur + 0.3))
        c = centre(y)
        pts = []
        for k in range(seg):
            a = 2 * math.pi * k / seg
            d = Vector((math.cos(a), 0, math.sin(a)))
            b = 1 + 0.09 * noise.noise(Vector((math.cos(a) * 2, y * 0.9, math.sin(a) * 2 + o)))
            b += sillons * noise.noise(Vector((a * 2.2, y * 0.12, o)))
            if plaques:
                # plaques d'écorce : cellules marquées (bruit cellulaire) + fines fissures verticales
                b += plaques * (noise.cell(Vector((math.cos(a) * 1.6, y * 0.55, math.sin(a) * 1.6 + o))) - 0.5)
                b += plaques * 0.5 * abs(math.sin(a * seg / 2.5 + 2 * noise.noise(Vector((a, y * 0.3, o)))))
            # contreforts au pied
            b += flare * 0.9 * math.exp(-y / 0.6) * max(0.0, math.sin(3 * a + ph2)) / max(r, 0.1)
            pts.append(c + d * r * b)
        return pts

    ys = [hauteur * (i / (anneaux - 1)) ** 1.15 for i in range(anneaux)]
    for cible, morceau in ((m_bas, [y for y in ys if y <= coupe]), (m_haut, [y for y in ys if y >= coupe])):
        if cible is None or len(morceau) < 2:
            continue
        if morceau[0] > 0 and morceau[0] != coupe:
            morceau = [coupe] + morceau
        if morceau[-1] < coupe <= hauteur:
            morceau.append(coupe)
        base = len(cible.v)
        for y in morceau:
            cible.v.extend(anneau(y))
        n = len(morceau)
        for i in range(n - 1):
            for k in range(seg):
                j = (k + 1) % seg
                cible.f.append((base + i * seg + k, base + i * seg + j, base + (i + 1) * seg + j, base + (i + 1) * seg + k))
        cible.f.append(tuple(base + k for k in reversed(range(seg))))
        cible.f.append(tuple(base + (n - 1) * seg + k for k in range(seg)))
    return centre


def courbe(depart, direction, longueur, n, courbure, rng, tremble=0.08):
    """Branche : avance dans `direction`, tirée par `courbure(u)` (vecteur ajouté à chaque pas)."""
    pts = [depart.copy()]
    d = direction.normalized()
    pas = longueur / n
    for i in range(n):
        u = (i + 1) / n
        d = (d + courbure(u) + Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-1, 1))) * tremble).normalized()
        pts.append(pts[-1] + d * pas)
    return pts


# ======================= PIN SYLVESTRE =======================

def pin(nom, graine, decal, H=30.0):
    rng = random.Random(graine)
    ecorce, tronc, branches = Maillage(), Maillage(), Maillage()
    aiguilles, claires, pommes, coeur = Maillage(), Maillage(), Maillage(), Maillage()
    bas_couronne = H * rng.uniform(0.58, 0.66)

    centre = fut(ecorce, tronc, rng, H, lambda u: 0.62 * (1 - u) ** 0.85 + 0.05, H * 0.2,
                 flare=0.32, sillons=0.06, penche=0.22, seg=22, anneaux=70, plaques=0.09)
    racines(ecorce, rng, centre, rng.randint(4, 6), 0.95, 1.7)

    # chicots morts le long du fût
    for i in range(rng.randint(14, 20)):
        y = rng.uniform(H * 0.22, bas_couronne)
        a = i * OR + rng.uniform(-0.4, 0.4)
        h = Vector((math.cos(a), 0, math.sin(a)))
        p0 = centre(y)
        L = rng.uniform(0.5, 1.4) * (1.6 if y > H * 0.45 and rng.random() < 0.4 else 1)
        pts = courbe(p0, h + HAUT * rng.uniform(-0.5, 0.1), L, 3, lambda u: Vector((0, -0.12, 0)), rng, 0.1)
        branches.tube(pts, [0.075, 0.055, 0.04, 0.02], cotes=5)

    def touffe(p, taille, u_hauteur, dehors):
        """Touffe d'aiguilles : un cœur sombre bosselé, hérissé de rameaux couverts d'aiguilles en goupillon."""
        # cœur (volume sombre qui bouche les trous)
        for _ in range(rng.randint(2, 3)):
            q = p + Vector((rng.uniform(-1, 1), rng.uniform(-0.2, 0.3), rng.uniform(-1, 1))) * taille * 0.45
            r = taille * rng.uniform(0.6, 0.85)
            coeur.boule(q, (r, r * rng.uniform(0.4, 0.55), r * rng.uniform(0.8, 1.0)), rng, bosses=0.35, freq=1.8,
                        rot=rng.uniform(0, 6.3))
        # rameaux en éventail, orientés vers l'extérieur et le ciel
        ext = Vector((p.x, 0, p.z))
        ext = ext.normalized() if ext.length > 0.3 else Vector((1, 0, 0))
        for j in range(rng.randint(4, 6)):
            ang = (j / 5 - 0.5) * 2.6 + rng.uniform(-0.25, 0.25)
            d = Matrix.Rotation(ang, 3, 'Y') @ ext + HAUT * rng.uniform(0.05, 0.5)
            if not dehors and rng.random() < 0.4:
                d = -d + HAUT * 0.6  # vers l'intérieur pour les touffes du milieu de branche
            d.normalize()
            L = taille * rng.uniform(0.9, 1.4)
            q0 = p + d * taille * 0.15
            pts = courbe(q0, d, L, 3, lambda u_: Vector((0, 0.08, 0)), rng, 0.06)
            branches.tube(pts, [0.035 * taille, 0.028 * taille, 0.02 * taille, 0.012 * taille], cotes=4, fermer=False)
            clair_r = rng.random() < 0.3 + 0.25 * (d.y > 0.3) + 0.2 * u_hauteur
            cible = claires if clair_r else aiguilles
            # aiguilles groupées par pinceaux le long du rameau (goupillon), plus serrées au bout
            for k, s in ((1, 0.0), (2, 0.5), (3, 0.9)):
                c = pts[k - 1].lerp(pts[k], 0.6)
                t = (pts[k] - pts[k - 1]).normalized()
                ref = Vector((0, 1, 0)) if abs(t.y) < 0.9 else Vector((1, 0, 0))
                N = (ref - t * ref.dot(t)).normalized()
                Bv = t.cross(N)
                nb_aig = 6 if k < 3 else 7
                for a_i in range(nb_aig):
                    a = 2 * math.pi * a_i / nb_aig + rng.uniform(-0.2, 0.2)
                    rad = N * math.cos(a) + Bv * math.sin(a)
                    da = (rad * 0.85 + t * (0.75 + 0.4 * s) + HAUT * 0.15).normalized()
                    cible.cone(c, da, taille * rng.uniform(0.45, 0.65) * (0.85 if k == 3 else 1),
                               taille * 0.055, cotes=3)
            # bourgeon terminal
            cible.cone(pts[-1], d, taille * 0.22, taille * 0.05, cotes=4)
        # pomme de pin pendante
        if rng.random() < 0.3:
            q = p + Vector((rng.uniform(-0.5, 0.5), -taille * 0.35, rng.uniform(-0.5, 0.5)))
            r = 0.16 * (taille / 1.2) + 0.06
            pommes.boule(q, (r, r * 1.6, r), rng, bosses=0.15, freq=4.0)

    # branches vivantes de la couronne
    nb = rng.randint(15, 19)
    for i in range(nb):
        u = i / (nb - 1)  # 0 = bas de la couronne, 1 = cime
        y = bas_couronne + (H * 0.97 - bas_couronne) * (u ** 0.9) + rng.uniform(-0.3, 0.3)
        a = i * OR * 1.7 + rng.uniform(-0.5, 0.5)
        h = Vector((math.cos(a), 0, math.sin(a)))
        L = H * (0.25 * (1 - 0.62 * u) + rng.uniform(-0.03, 0.05))
        tombe = u < 0.45 and rng.random() < 0.45
        elev = rng.uniform(0.15, 0.55) if not tombe else rng.uniform(-0.1, 0.2)
        p0 = centre(y)
        courb = (lambda u_: Vector((0, -0.16 if u_ < 0.6 else 0.12, 0))) if tombe else \
                (lambda u_: Vector((0, -0.07 if u_ < 0.5 else 0.1, 0)))
        pts = courbe(p0, h + HAUT * elev, L, 6, courb, rng)
        r0 = 0.07 + 0.16 * (1 - u)
        branches.tube(pts, [r0 * (1 - 0.8 * k / 6) for k in range(7)], cotes=6)
        touffe(pts[-1], 1.15 + 0.6 * (1 - u), u, True)
        touffe(pts[-3], 0.95 + 0.4 * (1 - u), u, False)
        # rameaux secondaires
        for _ in range(rng.randint(1, 3)):
            k = rng.randint(2, 4)
            dev = Matrix.Rotation(rng.uniform(-0.9, 0.9), 3, 'Y') @ (pts[k + 1] - pts[k]).normalized()
            p2 = courbe(pts[k], dev + HAUT * rng.uniform(0.0, 0.4), L * rng.uniform(0.3, 0.5), 3,
                        lambda u_: Vector((0, 0.05, 0)), rng)
            branches.tube(p2, [r0 * 0.45, r0 * 0.35, r0 * 0.25, r0 * 0.15], cotes=5)
            touffe(p2[-1], 0.9 + 0.4 * (1 - u), u, True)
    # flèche sommitale
    sommet = centre(H)
    touffe(sommet + Vector((0, 0.3, 0)), 1.0, 1.0, True)
    touffe(centre(H * 0.93), 1.2, 0.95, True)

    objs = [
        ecorce.objet(nom + "_Ecorce", materiau("Ecorce", TEINTES["Ecorce"], 0.9), decal, angle=70),
        tronc.objet(nom + "_Tronc", materiau("TroncPin", TEINTES["TroncPin"], 0.85), decal, angle=70),
        branches.objet(nom + "_Branches", materiau("Branches", TEINTES["Branches"], 0.9), decal),
        aiguilles.objet(nom + "_Aiguilles", materiau("Aiguilles", TEINTES["Aiguilles"], 0.7), decal),
        claires.objet(nom + "_AiguillesClaires", materiau("AiguillesClaires", TEINTES["AiguillesClaires"], 0.7), decal),
        coeur.objet(nom + "_AiguillesSombres", materiau("AiguillesSombres", TEINTES["AiguillesSombres"], 0.75), decal),
        pommes.objet(nom + "_Pommes", materiau("Pommes", TEINTES["Pommes"], 0.9), decal),
    ]
    return objs


# ======================= SAULE PLEUREUR =======================

def saule(nom, graine, decal):
    rng = random.Random(graine)
    tronc, feuillage, rameaux, clairs, sombres = Maillage(), Maillage(), Maillage(), Maillage(), Maillage()
    feuilles, feuilles_claires = Maillage(), Maillage()
    Ht = rng.uniform(4.6, 5.4)           # hauteur du fût avant la fourche
    C = Vector((0, 10.4, 0))             # centre du dôme
    Rh, Rv = 10.6, 7.8                   # rayons horizontal / vertical du dôme
    lob = [rng.uniform(0, 6.3) for _ in range(3)]

    def lobes(phi):
        return 1 + 0.1 * math.sin(3 * phi + lob[0]) + 0.07 * math.sin(5 * phi + lob[1]) + 0.04 * math.sin(7 * phi + lob[2])

    def dome(theta, phi, o):
        """Point du dôme (theta = 0 au sommet)."""
        r = Rh * lobes(phi) * o
        return C + Vector((math.sin(theta) * r * math.cos(phi), math.cos(theta) * Rv * o, math.sin(theta) * r * math.sin(phi)))

    centre = fut(tronc, None, rng, Ht + 0.6, lambda u: 1.15 - 0.3 * u, 99, flare=0.55, sillons=0.2, penche=0.18,
                 seg=26, anneaux=18, plaques=0.07)
    racines(tronc, rng, centre, rng.randint(5, 7), 1.0, 3.2)
    centre_tronc = centre  # le fût n'a qu'un morceau (coupe au-dessus du sommet)

    # grosses charpentières qui montent puis s'arquent vers l'extérieur
    nb = rng.randint(5, 6)
    for i in range(nb):
        a = i * 2 * math.pi / nb + rng.uniform(-0.35, 0.35)
        h = Vector((math.cos(a), 0, math.sin(a)))
        p0 = centre_tronc(Ht - rng.uniform(0, 0.6))
        L = rng.uniform(9.0, 11.5)
        pts = courbe(p0, h * 0.7 + HAUT, L, 10, lambda u: h * (0.03 + 0.1 * u) + Vector((0, -0.05 * u, 0)), rng, 0.06)
        tronc.tube(pts, [0.75 * (1 - 0.8 * k / 10) for k in range(11)], cotes=9)
        for _ in range(3):
            k = rng.randint(3, 8)
            dev = Matrix.Rotation(rng.uniform(-0.8, 0.8), 3, 'Y') @ h
            p2 = courbe(pts[k], dev + HAUT * 0.8, L * rng.uniform(0.35, 0.55), 4,
                        lambda u: dev * 0.15 + Vector((0, -0.08, 0)), rng)
            tronc.tube(p2, [0.22, 0.17, 0.12, 0.08, 0.05], cotes=6)

    # masse intérieure sombre (empêche de voir à travers le haut du dôme)
    for i in range(60):
        theta = math.acos(1 - rng.uniform(0, 1.25))
        phi = i * OR + rng.uniform(-0.3, 0.3)
        p = dome(theta, phi, rng.uniform(0.7, 0.8))
        r = rng.uniform(2.5, 3.4)
        feuillage.boule(p, (r, r * 0.8, r), rng, bosses=0.3, freq=1.4)

    # rideaux : grappes de rameaux qui épousent le dôme puis pendent jusqu'au sol
    for g in range(100):
        phi_g = g * OR + rng.uniform(-0.1, 0.1)
        theta_g = math.acos(1 - 0.95 * rng.uniform(0, 1) ** 1.6)
        o_g = rng.uniform(0.96, 1.08)
        bas_g = rng.uniform(0.3, 2.2) if rng.random() < 0.8 else rng.uniform(2.2, 5.0)
        clair_g = rng.random() < (0.15 + 0.25 * (1 - theta_g / 1.6))
        sombre_g = not clair_g and (o_g < 1.03 or rng.random() < 0.3)
        for _ in range(rng.randint(6, 8)):
            phi = phi_g + rng.uniform(-0.09, 0.09)
            theta0 = max(0.02, theta_g + rng.uniform(-0.12, 0.12))
            o = o_g + rng.uniform(-0.04, 0.04)
            theta_fin = math.pi / 2 + rng.uniform(-0.05, 0.2)
            pts = []
            m = max(2, int((theta_fin - theta0) / 0.2) + 1)
            for k in range(m):
                th = theta0 + (theta_fin - theta0) * k / (m - 1)
                pts.append(dome(th, phi, o + 0.04 * k / m))
            dehors = Vector((math.cos(phi), 0, math.sin(phi)))
            depart = pts[-1]
            y_fin = bas_g + rng.uniform(-0.3, 1.2)
            chute = depart.y - y_fin
            nchute = max(2, int(chute / 1.25))
            ph = rng.uniform(0, 6.3)
            cote = Vector((-math.sin(phi), 0, math.cos(phi)))
            for k in range(1, nchute + 1):
                s = k / nchute
                p = depart + dehors * (0.7 * s - 0.55 * s * s) + Vector((0, -chute * s, 0))
                p += cote * 0.2 * math.sin(ph + s * 3)
                pts.append(p)
            larg = rng.uniform(0.42, 0.62)
            n = len(pts)
            rayons = [larg * (1 - 0.6 * (k / (n - 1)) ** 1.5) for k in range(n)]
            ondule = (lambda k, ph=ph: 0.75 + 0.35 * math.sin(k * 2.3 + ph))
            clair = clair_g if rng.random() < 0.8 else not clair_g
            cible = clairs if clair else (sombres if sombre_g else rameaux)
            cible.tube(pts, rayons, cotes=3, axe=cote, aplati=0.3, ondule=ondule)
            # petites feuilles effilées qui s'écartent du rameau (surtout sur la partie qui pend)
            for _ in range(rng.randint(3, 5)):
                k = rng.randint(max(1, n // 3), n - 1)
                q = pts[k] + cote * rayons[k] * rng.choice((-0.9, 0.9)) + dehors * rng.uniform(0, 0.15)
                d = Vector((0, -1, 0)) + dehors * rng.uniform(0.2, 0.7) + cote * rng.uniform(-0.6, 0.6)
                (feuilles_claires if (clair or rng.random() < 0.25) else feuilles).feuille(
                    q, d, cote, rng.uniform(0.55, 0.85), rng.uniform(0.09, 0.13))

    objs = [
        tronc.objet(nom + "_Tronc", materiau("Tronc", TEINTES["Tronc"], 0.9), decal, angle=70),
        feuillage.objet(nom + "_Feuillage", materiau("Feuillage", TEINTES["Feuillage"], 0.7), decal),
        rameaux.objet(nom + "_Rameaux", materiau("Rameaux", TEINTES["Rameaux"], 0.7), decal),
        clairs.objet(nom + "_RameauxClairs", materiau("RameauxClairs", TEINTES["RameauxClairs"], 0.7), decal),
        sombres.objet(nom + "_RameauxSombres", materiau("RameauxSombres", TEINTES["RameauxSombres"], 0.7), decal),
        feuilles.objet(nom + "_Feuilles", materiau("Feuilles", TEINTES["Feuilles"], 0.6), decal, lisser=False),
        feuilles_claires.objet(nom + "_FeuillesClaires", materiau("FeuillesClaires", TEINTES["FeuillesClaires"], 0.6),
                               decal, lisser=False),
    ]
    return objs


VARIANTES = [
    ("Saule1", saule, 7, 0), ("Saule2", saule, 19, 26),
    ("Pin1", pin, 3, 52), ("Pin2", pin, 13, 66), ("Pin3", pin, 29, 80),
]


def construire():
    vider()
    tous = []
    for nom, f, graine, x in VARIANTES:
        objs = f(nom, graine, (-x, 0, 0))
        for o in objs:
            print("  ", o.name, triangles(o))
            if triangles(o) > 20000:
                print("   !! plus de 20 000 triangles")
            centrer_origine(o)
        tous += objs
    print("OBJETS", len(tous), "TRIANGLES", sum(triangles(o) for o in tous))
    exporter_fbx("Arbres.fbx", tous)
    sol = objet("SolApercu", bm_cube(T((-44, -0.25, 0), echelle=(124, 0.5, 34))), materiau("Herbe", (92, 120, 60)))
    rendu("arbres.png", direction=(-0.15, -1, 0.12), objets=tous + [sol], largeur=2000, hauteur=900)
    sauls = [o for o in tous if o.name.startswith("Saule1")]
    rendu("arbres_saule.png", direction=(-0.3, -1, 0.15), objets=sauls, largeur=1000, hauteur=900)
    pins = [o for o in tous if o.name.startswith("Pin1")]
    rendu("arbres_pin.png", direction=(-0.3, -1, 0.1), objets=pins, largeur=1200, hauteur=1200)
    rendu("arbres_pin_couronne.png", direction=(-0.3, -1, 0.25), objets=[o for o in pins if "Aiguilles" in o.name or o.name.endswith("Pommes")], largeur=1400, hauteur=1000)
    rendu("arbres_saule_haut.png", direction=(-0.3, -1, 0.9), objets=sauls, largeur=1000, hauteur=900)


construire()
