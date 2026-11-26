"""Mannequin Roblox R15 et vêtements du mineur, axes Blender Z haut / face -Y."""

from math import atan2, cos, hypot, pi, sin

import bmesh
import bpy


def profil(api, collection, nom, points, avant, arriere, mat, cote=0):
    """Volume fermé d'un panneau; le plan est XZ, ou YZ pour une applique de côté."""
    sommets = []
    for profondeur in (avant, arriere):
        for u, z in points:
            sommets.append((profondeur, u, z) if cote else (u, profondeur, z))
    n = len(points)
    faces = [tuple(range(n - 1, -1, -1)), tuple(range(n, n * 2))]
    faces.extend((i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n))
    pivot = tuple(sum(p[a] for p in sommets) / len(sommets) for a in range(3))
    sommets = [tuple(p[a] - pivot[a] for a in range(3)) for p in sommets]
    mesh = bpy.data.meshes.new(nom)
    mesh.from_pydata(sommets, [], faces)
    poly = bmesh.new()
    poly.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(poly, faces=list(poly.faces))
    poly.to_mesh(mesh)
    poly.free()
    mesh.update()
    objet = bpy.data.objects.new(nom, mesh)
    objet.location = pivot
    objet.data.materials.append(api.materiau(mat))
    collection.objects.link(objet)
    return objet


def rectangle(u, z, largeur, hauteur, angle=0):
    """Coins chanfreinés pour des pièces de toile, des coutures et les appliques du visage."""
    a, b = largeur / 2, hauteur / 2
    c = min(a, b) * 0.26
    points = [
        (-a + c, -b), (a - c, -b), (a, -b + c), (a, b - c),
        (a - c, b), (-a + c, b), (-a, b - c), (-a, -b + c),
    ]
    return [(u + x * cos(angle) - y * sin(angle), z + x * sin(angle) + y * cos(angle)) for x, y in points]


def ovale(u, z, rx, rz, n=14):
    return [(u + rx * cos(i * 2 * pi / n), z + rz * sin(i * 2 * pi / n)) for i in range(n)]


def ligne(api, collection, nom, points, profondeur, epaisseur, mat, cote=0):
    for index, (a, b) in enumerate(zip(points, points[1:])):
        angle = atan2(b[1] - a[1], b[0] - a[0])
        longueur = ((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2) ** 0.5
        u, z = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        profil(
            api, collection, f"{nom}_{index + 1}",
            rectangle(u, z, longueur + epaisseur * 0.32, epaisseur, angle),
            profondeur, profondeur + (0.003 if profondeur < 0 else -0.003), mat, cote,
        )


def trait_visage(api, collection, nom, points, profondeur, epaisseur, mat, cote=0):
    """Une seule bande fermée, avec raccords en onglet aux changements de direction."""
    normales = []
    for a, b in zip(points, points[1:]):
        du, dz = b[0] - a[0], b[1] - a[1]
        longueur = hypot(du, dz)
        normales.append((-dz / longueur, du / longueur))
    demi = epaisseur * 0.5
    bord_gauche, bord_droit = [], []
    for i, (u, z) in enumerate(points):
        a = normales[max(0, i - 1)]
        b = normales[min(i, len(normales) - 1)]
        m = demi / (1 + a[0] * b[0] + a[1] * b[1])
        du, dz = (a[0] + b[0]) * m, (a[1] + b[1]) * m
        bord_gauche.append((u + du, z + dz))
        bord_droit.append((u - du, z - dz))
    profil(
        api, collection, nom, bord_gauche + bord_droit[::-1],
        profondeur, profondeur + (0.003 if profondeur < 0 else -0.003), mat, cote,
    )


def points_couture(api, collection, nom, u0, u1, z, profondeur, mat, compte=7):
    pas = (u1 - u0) / compte
    for i in range(compte):
        u = u0 + (i + 0.5) * pas
        ligne(api, collection, f"{nom}_{i + 1}", [(u - pas * 0.22, z), (u + pas * 0.22, z)], profondeur, 0.008, mat)


def mannequin(api):
    collection = api.collection("01_Corps_R15")
    api.boite(collection, "Head", (0, 0, 4.586), (1.196, 1.198, 1.203), "peau", biseau=0.085)
    api.boite(collection, "UpperTorso", (0, 0, 3.2), (2.0, 1.0, 1.6), "lin", biseau=0.055)
    api.boite(collection, "LowerTorso", (0, 0, 2.2), (2.0, 1.0, 0.4), "bleu", biseau=0.048)
    for signe, cote in ((1, "Left"), (-1, "Right")):
        segments = (
            ("UpperArm", 1.5, 3.3687, 1.1687, "lin"),
            ("LowerArm", 1.5, 2.7759, 1.0519, "lin"),
            ("Hand", 1.5, 2.1500, 0.3001, "cuir"),
            ("UpperLeg", 0.5, 1.5792, 1.2166, "bleu"),
            ("LowerLeg", 0.5, 0.7991, 1.1931, "bleu"),
            ("Foot", 0.5, 0.1500, 0.3000, "cuir"),
        )
        for segment, x, z, hauteur, mat in segments:
            api.boite(collection, f"{cote}{segment}", (signe * x, 0, z), (1, 1, hauteur), mat, biseau=0.044)


def visage(api):
    collection = api.collection("02_Visage")
    face = -0.603
    for signe, cote in ((-1, "Droit"), (1, "Gauche")):
        x = signe * 0.220
        profil(api, collection, f"Oeil_{cote}", ovale(x, 4.542, 0.031, 0.075), face, face + 0.004, "visage_yeux")
        profil(api, collection, f"Reflet_{cote}", ovale(x - 0.007, 4.565, 0.008, 0.015, 10), face - 0.003, face, "col")
        trait_visage(
            api, collection, f"Sourcil_{cote}", [
                (x - 0.075, 4.635 + signe * 0.003), (x, 4.648),
                (x + 0.074, 4.637 - signe * 0.004),
            ], face, 0.018, "visage_sourcils",
        )
        tache = [
            (signe * 0.319, 4.431), (signe * 0.362, 4.456),
            (signe * 0.402, 4.450 - signe * 0.006), (signe * 0.388, 4.420),
            (signe * 0.349, 4.414),
        ]
        profil(api, collection, f"Poussiere_Joue_{cote}", tache, face + 0.001, face + 0.003, "visage_poussiere")
        for i, (du, dz, rayon) in enumerate(((0.095, 0.018, 0.008), (0.082, -0.019, 0.006))):
            profil(
                api, collection, f"Grain_Joue_{cote}_{i+1}",
                ovale(x + signe * du, 4.423 + dz, rayon, rayon * 0.8, 8),
                face + 0.001, face + 0.003, "visage_poussiere",
            )
        bord = signe * 0.602
        for i in range(11):
            a, b = (i + 0.5) * 2 * pi / 13, (i + 1.5) * 2 * pi / 13
            a0, b0 = (0.022 + cos(a) * 0.104, 4.476 + sin(a) * 0.135), (0.022 + cos(b) * 0.104, 4.476 + sin(b) * 0.135)
            ligne(api, collection, f"Oreille_{cote}_{i+1}", [a0, b0], bord, 0.010, "visage_poussiere", cote=1)
        trait_visage(api, collection, f"Oreille_Pli_{cote}", [(0.036, 4.523), (-0.003, 4.486), (0.004, 4.443)], bord, 0.011, "visage_poussiere", cote=1)
    trait_visage(api, collection, "Profil_Nez", [(-0.008, 4.517), (-0.037, 4.436), (0.043, 4.436)], face, 0.014, "visage_poussiere")
    trait_visage(api, collection, "Sourire", [(-0.112, 4.365), (-0.050, 4.351), (0.048, 4.350), (0.113, 4.362)], face, 0.019, "visage_bouche")


def chemise(api):
    collection = api.collection("04_Torse_Lin")
    api.boite(collection, "Chemise_Lin_Torse", (0, 0, 3.197), (2.025, 1.047, 1.604), "lin", biseau=0.044)
    for signe, cote in ((1, "Gauche"), (-1, "Droite")):
        points = [(signe * x, z) for x, z in [(0.04, 3.98), (0.34, 3.975), (0.32, 3.835), (0.20, 3.724), (0.025, 3.850)]]
        profil(api, collection, f"Col_{cote}", points, -0.555, -0.521, "col")
        ligne(api, collection, f"Col_Piqure_{cote}", [(signe * 0.302, 3.950), (signe * 0.281, 3.843), (signe * 0.202, 3.767)], -0.559, 0.010, "fil_lin")
        api.boite(collection, f"Couture_Epaule_{cote}", (signe * 0.671, 0, 3.997), (0.46, 0.011, 0.014), "fil_lin", biseau=0.003)
    api.boite(collection, "Chemise_Patte", (0, -0.531, 3.742), (0.077, 0.017, 0.29), "col", biseau=0.007)
    for z in (3.582, 3.710):
        profil(api, collection, f"Chemise_Bouton_{z}", ovale(0, z, 0.026, 0.025, 10), -0.546, -0.537, "laiton")
    ligne(api, collection, "Dos_Empiecement", [(-0.68, 3.807), (-0.38, 3.692), (0.38, 3.692), (0.68, 3.807)], 0.529, 0.013, "fil_lin")
    for signe, cote in ((1, "Left"), (-1, "Right")):
        x = signe * 1.50
        for nom, bas, haut in (("UpperArm", 3.010, 3.969), ("LowerArm", 2.400, 3.014)):
            collection = api.collection(f"04_Manche_{cote}{nom}")
            api.boite(collection, f"Toile_{cote}{nom}", (x, 0, (haut + bas) / 2), (1.029, 1.041, haut - bas), "lin", biseau=0.036)
            for y in (-0.524, 0.524):
                ligne(api, collection, "Ourlet_Manche", [(x - 0.382, bas + 0.082), (x + 0.382, bas + 0.082)], y, 0.015, "fil_lin")
            if nom == "UpperArm":
                z = 3.524
                ext = signe * 2.017
                profil(api, collection, "Poche_Manche", rectangle(0.03, z, 0.49, 0.318), ext, ext - signe * 0.016, "lin", cote=1)
                ligne(api, collection, "Poche_Manche_Ouverture", [(-0.15, z + 0.087), (0.21, z + 0.087)], ext + signe * 0.007, 0.016, "fil_lin", cote=1)
            else:
                for y in (-0.526, 0.526):
                    ligne(api, collection, "Pli_Coude", [(x - 0.365, 2.862), (x - 0.326, 2.784), (x - 0.304, 2.586)], y, 0.012, "fil_lin")
                profil(api, collection, "Usure_Coude", [
                    (x + 0.079, 2.812), (x + 0.184, 2.845), (x + 0.289, 2.802),
                    (x + 0.262, 2.745), (x + 0.130, 2.762),
                ], 0.524, 0.521, "poussiere")


def poche(api, collection, nom, centre, profondeur, taille):
    x, z = centre
    w, h = taille
    sens = 1 if profondeur > 0 else -1
    contours = [(x - w / 2, z + h / 2), (x + w / 2, z + h / 2), (x + w * 0.47, z - h * 0.32), (x + w * 0.34, z - h / 2),
                (x - w * 0.34, z - h / 2), (x - w * 0.47, z - h * 0.32)]
    profil(api, collection, nom, contours, profondeur + sens * 0.020, profondeur, "bleu_renfort")
    ligne(api, collection, f"{nom}_Bord", [(x - w * 0.40, z + h * 0.31),
        (x - w * 0.31, z - h * 0.37), (x + w * 0.31, z - h * 0.37),
        (x + w * 0.40, z + h * 0.31)], profondeur + sens * 0.024, 0.012, "fil_bleu")
    points_couture(api, collection, f"{nom}_Surpiqures", x - w * 0.41, x + w * 0.41, z + h * 0.36, profondeur + sens * 0.024, "fil_bleu")


def salopette(api):
    collection = api.collection("05_Salopette")
    for signe in (-1, 1):
        panneau = [(-0.802, 2.395), (0.802, 2.395), (0.776, 2.73), (0.630, 3.429),
                   (0.580, 3.469), (-0.580, 3.469), (-0.630, 3.429), (-0.776, 2.73)]
        profil(api, collection, "Plastron" if signe < 0 else "Empiecement_Dos", panneau, signe * 0.558, signe * 0.515, "bleu")
        poche(api, collection, "Poche_Plastron" if signe < 0 else "Poche_Dos", (0, 3.008), signe * 0.557, (0.79, 0.424))
        for x in (-0.700, 0.700):
            ligne(api, collection, "Bord_Salopette", [(x * 1.09, 2.486), (x, 2.752), (x * 0.84, 3.340)], signe * 0.562, 0.010, "fil_bleu")
    for cote, s in (("Gauche", 1), ("Droite", -1)):
        for t in (-1, 1):
            contours = [(s * 0.53, 3.447), (s * 0.76, 3.447), (s * 0.768, 3.988), (s * 0.548, 3.988)]
            if t > 0:
                contours[0] = (s * 0.416, 3.446)
                contours[1] = (s * 0.656, 3.446)
            profil(api, collection, f"Bretelle_{cote}_{t}", contours, t * 0.581, t * 0.499, "cuir")
            for plan in (0, 1):
                a, b = contours[plan], contours[3 - plan]
                delta = s * (0.025 if plan == 0 else -0.025)
                ligne(api, collection, "Piqure_Bretelle", [(a[0] + delta, a[1] + 0.028), (b[0] + delta, b[1] - 0.021)],
                    t * 0.585, 0.008, "fil_lin")
            profil(api, collection, "Bretelle_Rivet", ovale(s * (0.628 if t < 0 else 0.535), 3.452, 0.040, 0.040, 12),
                t * 0.601, t * 0.560, "laiton")
        api.boite(collection, f"Bretelle_Sur_Epaule_{cote}", (s * 0.658, 0, 4.002), (0.225, 1.146, 0.037), "cuir", biseau=0.012)
        x = s * 0.645
        profil(api, collection, "Bretelle_Ajustement", rectangle(x, 3.540, 0.213, 0.096), -0.599, -0.577, "laiton")
        profil(api, collection, "Bretelle_Emplacement", rectangle(x, 3.540, 0.142, 0.042), -0.603, -0.598, "cuir")

    collection = api.collection("05_Salopette_LowerTorso")
    api.boite(collection, "Salopette_Bassin", (0, 0, 2.201), (2.028, 1.033, 0.410), "bleu", biseau=0.030)
    for y in (-0.522, 0.522):
        ligne(api, collection, "Ourlet_Taille", [(-0.85, 2.107), (0.85, 2.107)], y, 0.011, "fil_bleu")
    for signe, cote in ((1, "Left"), (-1, "Right")):
        x = signe * 0.511
        for nom, bas, haut in (("UpperLeg", 1.072, 2.080), ("LowerLeg", 0.322, 1.067)):
            collection = api.collection(f"05_Jambe_{cote}{nom}")
            api.boite(collection, f"Toile_{cote}{nom}", (x, 0, (haut + bas) / 2), (1.014, 1.034, haut - bas), "bleu", biseau=0.032)
            for y in (-0.522, 0.522):
                ligne(api, collection, "Couture_Jambe", [(x + signe * 0.395, bas + 0.070), (x + signe * 0.398, haut - 0.065)], y, 0.011, "fil_bleu")
            if nom == "UpperLeg":
                poche(api, collection, "Renfort_Genou", (x, 1.428), -0.522, (0.696, 0.428))
                poche(api, collection, "Poche_Cuisse_Dos", (x - signe * 0.054, 1.742), 0.522, (0.542, 0.302))
                ligne(api, collection, "Pli_Cuisse", [(x - 0.31, 1.936), (x - 0.13, 1.879), (x + 0.14, 1.906)], -0.522, 0.011, "fil_bleu")
                r = 0.114 * signe
                profil(api, collection, "Poussiere_Genou", [(x + r - 0.056, 1.320), (x + r - 0.014, 1.358), (x + r + 0.047, 1.342),
                    (x + r + 0.080, 1.304), (x + r + 0.023, 1.281)], -0.545, -0.542, "poussiere")
            else:
                for y in (-0.525, 0.525):
                    ligne(api, collection, "Pli_Tibia", [(x - 0.282, 0.454), (x, 0.432), (x + 0.267, 0.462)], y, 0.010, "fil_bleu")
                for index, (u, z) in enumerate(((-0.23, 0.64), (0.12, 0.456), (0.22, 0.618))):
                    points = [(x + signe * u + du, z + dz) for du, dz in ((-0.038, 0), (-0.014, 0.027), (0.025, 0.015), (0.032, -0.015), (-0.007, -0.020))]
                    profil(api, collection, f"Poussiere_Tibia_{index+1}", points, -0.524, -0.521, "poussiere")


def construire(api):
    mannequin(api)
    visage(api)
    chemise(api)
    salopette(api)
