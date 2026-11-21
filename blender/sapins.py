"""Sapins (épicéas) modélisés dans le style des autres arbres (blender/arbres.py, dont on reprend les outils).

    "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" -b --factory-startup --python blender/sapins.py

Sortie : assets/Sapins.fbx — variantes Sapin1..3. Pièces (couleurs appliquées par le jeu) :
    SapinN_Ecorce (fût gris-brun, racines), SapinN_Branches, SapinN_AiguillesSapin (frondes vert sombre bleuté),
    SapinN_AiguillesSapinClaires (pousses claires au bout des branches), SapinN_AiguillesSombres (cœur du cône), SapinN_Pommes
Silhouette : cône étroit et dense, branches en étages qui retombent puis relèvent la pointe, couronne qui part bas.
Repère L : y = haut, pied du tronc en (0, 0, 0). Hauteur ~32 (mis à l'échelle en jeu, comme les pins).
"""
import os
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ICI)
# On reprend les outils de arbres.py (Maillage, fut, racines, courbe...) sans lancer sa construction
_source = open(os.path.join(ICI, "arbres.py"), encoding="utf-8").read()
_source = _source.rsplit("\nconstruire()", 1)[0]
exec(compile(_source, "arbres.py", "exec"))

TEINTES.update({
    "AiguillesSapin": (34, 66, 46), "AiguillesSapinClaires": (70, 112, 64), "EcorceSapin": (88, 72, 64),
})


def _ico1():
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
    v = [x.co.copy() for x in bm.verts]
    bm.verts.index_update()
    f = [tuple(x.index for x in face.verts) for face in bm.faces]
    bm.free()
    return v, f


ICO1_V, ICO1_F = _ico1()


def plume(m, centre, rayons, rng, rot=0.0, incl=0.0, bosses=0.3):
    """Fronde d'aiguilles : ellipsoïde aplati et bosselé (icosphère légère), orienté le long de la branche."""
    o = Vector((rng.uniform(-90, 90), rng.uniform(-90, 90), rng.uniform(-90, 90)))
    base = len(m.v)
    R = Matrix.Rotation(rot, 3, 'Y') @ Matrix.Rotation(incl, 3, 'Z')
    for p in ICO1_V:
        k = 1 + bosses * noise.noise(p * 1.9 + o)
        q = Vector((p.x * rayons[0], p.y * rayons[1], p.z * rayons[2])) * k
        m.v.append(centre + R @ q)
    for f in ICO1_F:
        m.f.append(tuple(base + i for i in f))


def sapin(nom, graine, decal, H=32.0):
    """Épicéa réaliste, sans aucun volume en boule : uniquement des branches, des rameaux et des aiguilles.
    Chaque branche d'étage porte des rameaux secondaires qui retombent (« en peigne »), eux-mêmes garnis
    d'aiguilles fines disposées en arête de poisson ; le bout des rameaux porte des pousses plus claires."""
    rng = random.Random(graine)
    ecorce, branches = Maillage(), Maillage()
    aiguilles, sombres, claires, pommes = Maillage(), Maillage(), Maillage(), Maillage()
    pointes = Maillage()  # seconde moitié des aiguilles des rameaux (teinte « Aiguilles », légèrement différente)

    # fût droit, peu penché, qui s'affine jusqu'à la flèche
    centre = fut(ecorce, None, rng, H * 0.97, lambda u: 0.6 * (1 - u) ** 0.9 + 0.04, H,
                 flare=0.38, sillons=0.05, penche=0.08, seg=16, anneaux=44, plaques=0.07)
    racines(ecorce, rng, centre, rng.randint(5, 7), 0.9, 1.8)

    def aiguilles_sur(pts, taille, cible, densite=3):
        """Aiguilles en arête de poisson de part et d'autre d'un rameau (feuilles très fines, visibles des deux côtés)."""
        for k in range(len(pts) - 1):
            a, b = pts[k], pts[k + 1]
            t = (b - a)
            L = t.length
            if L < 1e-4:
                continue
            t = t / L
            cote = t.cross(HAUT)
            cote = cote.normalized() if cote.length > 1e-4 else Vector((1, 0, 0))
            for j in range(densite):
                p = a.lerp(b, (j + 0.5) / densite)
                for s in (-1, 1):
                    d = (t * 0.55 + cote * s * 0.75 + HAUT * rng.uniform(-0.15, 0.2)).normalized()
                    cible.feuille(p, d, HAUT, taille * rng.uniform(0.95, 1.25), taille * 0.1, epaisseur=0.5)
                # quelques aiguilles dessous, qui pendent (donnent de la masse sans boule)
                if rng.random() < 0.5:
                    d = (t * 0.3 - HAUT * 0.9 + cote * rng.uniform(-0.4, 0.4)).normalized()
                    cible.feuille(p, d, cote, taille * 0.95, taille * 0.09, epaisseur=0.5)

    bas = H * rng.uniform(0.06, 0.1)          # la couronne part presque du sol
    etages = rng.randint(13, 15)
    for e in range(etages):
        u = e / (etages - 1)                   # 0 = bas, 1 = sommet
        y = bas + (H * 0.93 - bas) * (u ** 0.9)
        L = H * (0.25 * (1 - u) ** 0.92 + 0.03)  # cône : longues branches en bas, courtes en haut
        nbr = 6 if u < 0.6 else 5
        decale = rng.uniform(0, 6.3)
        for b in range(nbr):
            a = decale + b * 2 * math.pi / nbr + rng.uniform(-0.3, 0.3)
            h = Vector((math.cos(a), 0, math.sin(a)))
            Lb = L * rng.uniform(0.85, 1.1)
            # la branche part presque à plat, s'affaisse au milieu et relève sa pointe (port de l'épicéa)
            courb = lambda t: Vector((0, -0.1 if t < 0.6 else 0.12, 0))
            pts = courbe(centre(y), h + HAUT * rng.uniform(-0.12, 0.08), Lb, 5, courb, rng, 0.04)
            r0 = 0.06 + 0.12 * (1 - u)
            branches.tube(pts, [r0 * (1 - 0.82 * k / 5) for k in range(6)], cotes=4)
            taille = 0.55 + 0.35 * (1 - u)
            aiguilles_sur(pts[1:], taille * 1.3, sombres, densite=1)          # aiguilles sombres sur la branche maîtresse
            # rameaux secondaires en peigne qui retombent de chaque côté
            for k in (1, 3):  # deux paires de rameaux par branche (budget de triangles)
                p0 = pts[k]
                t = (pts[k + 1] - pts[k]).normalized()
                cote = t.cross(HAUT)
                cote = cote.normalized() if cote.length > 1e-4 else Vector((1, 0, 0))
                for s in (-1, 1):
                    if rng.random() < 0.15:
                        continue
                    lr = Lb * (0.5 - k * 0.08) * rng.uniform(0.85, 1.15)
                    if lr < 0.6:
                        continue
                    d0 = (t * 0.55 + cote * s * 0.7 - HAUT * rng.uniform(0.15, 0.45)).normalized()
                    pr = courbe(p0, d0, lr, 3, lambda t_: Vector((0, -0.12, 0)), rng, 0.06)
                    branches.tube(pr, [0.035, 0.026, 0.018, 0.01], cotes=3, fermer=False)
                    aiguilles_sur(pr, taille * 1.25, aiguilles if s < 0 else pointes, densite=2)  # deux pièces : < 20 000 triangles chacune
                    # pousse claire au bout du rameau
                    dt = (pr[-1] - pr[-2]).normalized()
                    claires.feuille(pr[-1], (dt + HAUT * 0.2).normalized(), HAUT, taille * 0.9, taille * 0.2, epaisseur=0.4)
            # pousses claires en bout de branche
            dt = (pts[-1] - pts[-2]).normalized()
            for s in (-1, 0, 1):
                d = (dt + Matrix.Rotation(0.5 * s, 3, 'Y') @ dt * 0.3 + HAUT * 0.15).normalized()
                claires.feuille(pts[-1], d, HAUT, taille * 1.1, taille * 0.22, epaisseur=0.4)
            # cônes pendants dans le haut de l'arbre
            if u > 0.55 and rng.random() < 0.3:
                q = pts[-2] + Vector((0, -0.35, 0))
                pommes.boule(q, (0.17, 0.42, 0.17), rng, bosses=0.12, freq=4.0)
    # flèche : une tige droite garnie d'aiguilles
    sommet = centre(H * 0.97)
    fl = [sommet + HAUT * (H * 0.07 * i / 3) for i in range(4)]
    branches.tube(fl, [0.07, 0.05, 0.035, 0.015], cotes=4)
    aiguilles_sur(fl, 0.7, claires, densite=3)

    return [
        ecorce.objet(nom + "_Ecorce", materiau("EcorceSapin", TEINTES["EcorceSapin"], 0.9), decal, angle=70),
        branches.objet(nom + "_Branches", materiau("Branches", TEINTES["Branches"], 0.9), decal),
        aiguilles.objet(nom + "_AiguillesSapin", materiau("AiguillesSapin", TEINTES["AiguillesSapin"], 0.75), decal, lisser=False),
        pointes.objet(nom + "_Aiguilles", materiau("Aiguilles", TEINTES["Aiguilles"], 0.75), decal, lisser=False),
        sombres.objet(nom + "_AiguillesSombres", materiau("AiguillesSombres", TEINTES["AiguillesSombres"], 0.8), decal, lisser=False),
        claires.objet(nom + "_AiguillesSapinClaires", materiau("AiguillesSapinClaires", TEINTES["AiguillesSapinClaires"], 0.7), decal, lisser=False),
        pommes.objet(nom + "_Pommes", materiau("Pommes", TEINTES["Pommes"], 0.9), decal),
    ]


def construire_sapins():
    vider()
    tous = []
    for nom, graine, x in (("Sapin1", 41, 0), ("Sapin2", 57, 16), ("Sapin3", 73, 32)):
        objs = sapin(nom, graine, (-x, 0, 0), H=32.0 + (graine % 5))
        for o in objs:
            n = triangles(o)
            print("  ", o.name, n)
            if n > 20000:
                print("   !! plus de 20 000 triangles")
            centrer_origine(o)
        tous += objs
    exporter_fbx("Sapins.fbx", tous)
    sol = objet("SolApercu", bm_cube(T((-16, -0.25, 0), echelle=(60, 0.5, 20))), materiau("Herbe", (92, 120, 60)))
    rendu("sapins.png", direction=(-0.15, -1, 0.12), objets=tous + [sol], largeur=1600, hauteur=1000)
    rendu("sapin_detail.png", direction=(-0.3, -1, 0.25), objets=[o for o in tous if o.name.startswith("Sapin1")],
          largeur=1000, hauteur=1200)
    print("FIN", len(tous), "pièces", sum(triangles(o) for o in tous), "triangles")


construire_sapins()
