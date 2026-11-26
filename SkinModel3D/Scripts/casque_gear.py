"""Casque, lampe et accessoires rigides conformes à la planche du Mineur."""

import math

import bmesh
import bpy
from mathutils import Vector


def maillage(api, collection, nom, sommets, faces, cle, origine):
    """Construit une pièce fermée et place son origine sur son point de montage."""
    position = Vector(origine)
    maillage_objet = bpy.data.meshes.new(nom)
    maillage_objet.from_pydata([Vector(sommet) - position for sommet in sommets], [], faces)
    bords = bmesh.new()
    bords.from_mesh(maillage_objet)
    bmesh.ops.recalc_face_normals(bords, faces=list(bords.faces))
    bords.to_mesh(maillage_objet)
    bords.free()
    maillage_objet.update()
    objet = bpy.data.objects.new(nom, maillage_objet)
    objet.location = position
    objet.data.materials.append(api.materiau(cle))
    collection.objects.link(objet)
    return objet


def boucle(cx, cy, z, largeur, profondeur, coin):
    x, y = largeur / 2.0, profondeur / 2.0
    return [
        (cx + px, cy + py, z)
        for px, py in [
            (-x + coin, -y), (x - coin, -y), (x, -y + coin), (x, y - coin),
            (x - coin, y), (-x + coin, y), (-x, y - coin), (-x, -y + coin),
        ]
    ]


def entre_anneaux(debut, fin, nombre):
    return [
        (debut + i, debut + (i + 1) % nombre, fin + (i + 1) % nombre, fin + i)
        for i in range(nombre)
    ]


def anneaux(api, collection, nom, centre, profils, cle, ferme=True):
    cx, cy = centre
    sommets = [p for profil in profils for p in boucle(cx, cy, *profil)]
    n = 8
    faces = [
        face for i in range(len(profils) - 1) for face in entre_anneaux(i * n, (i + 1) * n, n)
    ]
    dernier = (len(profils) - 1) * n
    if ferme:
        faces.extend((tuple(reversed(range(n))), tuple(range(dernier, dernier + n))))
    else:
        faces.extend(entre_anneaux(dernier, 0, n))
    return maillage(api, collection, nom, sommets, faces, cle, (cx, cy, profils[0][0]))


def cylindre(api, collection, nom, centre, axe, profils, cle, cotes=12, etire=1):
    origine = Vector(centre)
    rotation = Vector((0, 0, 1)).rotation_difference(Vector(axe).normalized())
    sommets = [
        origine
        + rotation
        @ Vector((rayon * etire * math.cos(a * math.tau / cotes),
                  rayon * math.sin(a * math.tau / cotes), profondeur))
        for profondeur, rayon in profils
        for a in range(cotes)
    ]
    faces = [
        face
        for i in range(len(profils) - 1)
        for face in entre_anneaux(i * cotes, (i + 1) * cotes, cotes)
    ]
    dernier = (len(profils) - 1) * cotes
    faces.extend((tuple(reversed(range(cotes))), tuple(range(dernier, dernier + cotes))))
    return maillage(api, collection, nom, sommets, faces, cle, origine)


def rivet(api, collection, nom, centre, axe, rayon, cle):
    return cylindre(
        api, collection, nom, centre, axe,
        [(-0.007, rayon * 0.94), (0.004, rayon), (0.016, rayon * 0.73)], cle, 10,
    )


def barre(api, collection, nom, origine, fin, epaisseur, profondeur, cle):
    avance = Vector(fin) - Vector(origine)
    milieu = (Vector(fin) + Vector(origine)) * .5
    rotation = Vector((0, 0, 1)).rotation_difference(avance.normalized()).to_euler()
    return api.boite(
        collection, nom, milieu, (epaisseur, profondeur, avance.length), cle,
        biseau=min(epaisseur, profondeur) * .22, rotation=rotation,
    )


def casque_et_lampe(api):
    casque = api.collection("02_Casque")
    lampe = api.collection("03_Lampe")
    # La couronne est creuse, avec une lèvre rentrée sous la coque.
    cx, cy = 0, .015
    profils = [
        (4.86, 1.292, 1.324, .110), (4.905, 1.348, 1.361, .132),
        (5.192, 1.370, 1.358, .153), (5.287, 1.281, 1.256, .173),
        (5.309, 1.195, 1.180, .162),
    ]
    interieur = [
        (4.86, 1.183, 1.195, .092), (4.947, 1.238, 1.262, .121),
        (5.239, 1.156, 1.135, .149),
    ]
    sommets = [p for profil in profils + interieur for p in boucle(cx, cy, *profil)]
    faces = [face for i in range(4) for face in entre_anneaux(i * 8, (i + 1) * 8, 8)]
    faces += entre_anneaux(40, 48, 8) + entre_anneaux(48, 56, 8)
    faces += entre_anneaux(0, 40, 8)
    faces += [tuple(range(32, 40)), tuple(reversed(range(56, 64)))]
    maillage(api, casque, "Coque_ardoise", sommets, faces, "ardoise", (0, 0, 5.18))

    anneaux(api, casque, "Bandeau_serti", (0, -.020), [
        (4.793, 1.424, 1.459, .112), (4.810, 1.492, 1.517, .124),
        (4.864, 1.480, 1.499, .129), (4.889, 1.392, 1.415, .119),
        (4.889, 1.217, 1.216, .093), (4.793, 1.215, 1.211, .092),
    ], "bandeau", ferme=False)
    anneaux(api, casque, "Calotte", (0, .022), [
        (5.273, 1.118, 1.107, .165), (5.320, 1.127, 1.129, .157),
        (5.401, 1.033, 1.037, .173), (5.421, .963, .971, .163),
    ], "bandeau")

    for signe in (-1, 1):
        rivet(api, casque, "Rivet_avant", (signe * .476, -.662, 4.936), (0, -1, 0), .044, "fer")
        rivet(api, casque, "Rivet_arriere", (signe * .453, .692, 4.945), (0, 1, 0), .038, "fer")
        for y in (-.235, .351):
            rivet(api, casque, "Rivet_flanc", (signe * .684, y, 4.928), (signe, 0, 0), .033, "fer")
        barre(
            api, casque, "Nervure_de_coque",
            (signe * .674, -.326, 5.139), (signe * .680, .225, 5.152), .018, .022, "bandeau",
        )

    api.boite(lampe, "Support_fronteau", (0, -.689, 5.068), (.508, .142, .346), "ardoise", biseau=.026)
    api.boite(lampe, "Corps_laiton", (0, -.772, 5.073), (.461, .119, .319), "laiton", biseau=.034)
    api.boite(lampe, "Assise_du_cerclage", (0, -.829, 5.072), (.407, .044, .251), "bandeau", biseau=.020)
    cylindre(
        api, lampe, "Cerclage_perimetrique", (0, -.839, 5.073), (0, -1, 0),
        [(-.012, .132), (.010, .150), (.041, .149), (.062, .133)], "laiton", 16, 1.13,
    )
    cylindre(
        api, lampe, "Joint_lentille", (0, -.902, 5.073), (0, -1, 0),
        [(-.016, .134), (.005, .136), (.012, .122)], "ardoise", 16, 1.13,
    )
    cylindre(
        api, lampe, "Verre_ambre", (0, -.911, 5.073), (0, -1, 0),
        [(-.007, .117), (.011, .114), (.025, .101), (.034, .071)], "verre", 16, 1.13,
    )
    for x in (-.188, .188):
        for z in (4.959, 5.187):
            rivet(api, lampe, "Vis_laiton", (x, -.831, z), (0, -1, 0), .021, "fer")


def ceinture_et_pioche(api):
    ceinture = api.collection("06_Ceinture")
    pioche = api.collection("07_Pioche")
    anneaux(api, ceinture, "Ceinturon_brun", (0, 0), [
        (2.307, 2.052, 1.059, .095), (2.323, 2.101, 1.124, .102),
        (2.464, 2.101, 1.124, .102), (2.479, 2.052, 1.059, .095),
        (2.479, 1.971, .981, .087), (2.307, 1.971, .981, .087),
    ], "ceinture", ferme=False)
    api.boite(ceinture, "Languette", (.052, -.579, 2.389), (.457, .049, .138), "cuir", biseau=.013)
    for x in (-.175, .175):
        api.boite(ceinture, "Montant_de_boucle", (x, -.626, 2.392), (.053, .047, .200), "laiton", biseau=.010)
    for z in (2.305, 2.479):
        api.boite(ceinture, "Traverse_de_boucle", (0, -.626, z), (.342, .046, .045), "laiton", biseau=.010)
    barre(api, ceinture, "Ardillon", (-.024, -.657, 2.392), (.155, -.657, 2.392), .023, .024, "laiton")

    for x, y in [(-.660, -.575), (.656, -.575), (-.265, .576), (.290, .576)]:
        api.boite(ceinture, "Passant_de_cuir", (x, y, 2.391), (.085, .042, .223), "cuir", biseau=.013)
    poche_x = -.733
    api.boite(ceinture, "Pochette_de_dos", (poche_x, .607, 2.273), (.403, .195, .310), "ceinture", biseau=.043)
    api.boite(ceinture, "Rabat_de_poche", (poche_x, .710, 2.361), (.385, .043, .141), "cuir", biseau=.025)
    rivet(api, ceinture, "Bouton_de_poche", (poche_x, .735, 2.337), (0, 1, 0), .033, "laiton")
    for signe in (-1, 1):
        for i in range(4):
            api.boite(
                ceinture, "Couture_pochette", (poche_x + signe * .147, .712, 2.185 + .037 * i),
                (.012, .012, .023), "fil_cuir", biseau=.003,
            )
    api.boite(ceinture, "Fourreau_sur_hanche", (.843, .537, 2.374), (.252, .213, .218), "cuir", biseau=.029)
    rivet(api, ceinture, "Clou_du_fourreau", (.832, .649, 2.385), (0, 1, 0), .025, "laiton")

    base = Vector((1.089, .705, 1.547))
    sommet = Vector((.956, .609, 2.452))
    axe = sommet - base
    cylindre(api, pioche, "Manche_veine", base, axe, [
        (0, .042), (.047, .050), (.157, .046), (.690, .050), (.864, .061), (.951, .047),
    ], "bois", 8)
    cylindre(api, pioche, "Virole", base, axe, [(0.067, .052), (.094, .054), (.120, .053)], "fer", 8)
    cylindre(
        api, pioche, "Bague_de_tete", sommet, axe, [(-.085, .068), (-.074, .079), (.030, .073), (.054, .061)],
        "fer", 8,
    )
    # Fer asymétrique, pointe fine côté extérieur et patin émoussé côté intérieur.
    points = [
        (-.309, -.037), (-.289, .041), (-.165, .083), (-.034, .089),
        (.079, .063), (.176, .023), (.265, -.049), (.347, -.158),
        (.251, -.105), (.140, -.059), (.025, -.027), (-.166, -.026),
    ]
    origine = Vector((.960, .635, 2.518))
    sommets = [tuple(origine + Vector((x, y, z))) for y in (-.063, .063) for x, z in points]
    n = len(points)
    faces = entre_anneaux(0, n, n) + [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    maillage(api, pioche, "Panneton_de_pioche", sommets, faces, "fer", origine)
    barre(
        api, pioche, "Reflet_du_tranchant", (1.126, .700, 2.507), (1.233, .699, 2.442), .018, .008, "embout",
    )


def gant(api, signe, cote):
    collection = api.collection("08_Gant_" + cote)
    x = signe * 1.5
    anneaux(api, collection, "Gant_" + cote, (x, 0), [
        (2.012, .967, .974, .077), (2.041, 1.019, 1.019, .074),
        (2.271, 1.025, 1.031, .072), (2.313, 1.010, 1.012, .069),
    ], "gants")
    anneaux(api, collection, "Poignet_" + cote, (x, 0), [
        (2.287, 1.022, 1.028, .073), (2.310, 1.044, 1.047, .077),
        (2.401, 1.044, 1.047, .077), (2.417, 1.024, 1.031, .072),
        (2.417, .979, .979, .067), (2.287, .979, .979, .067),
    ], "cuir", ferme=False)
    api.boite(collection, "Contrefort_de_gant", (x, -.516, 2.152), (.672, .035, .144), "cuir", biseau=.022)
    for z in (2.321, 2.383):
        for i in range(7):
            api.boite(
                collection, "Couture_gant", (x - .326 + i * .108, -.526, z),
                (.061, .009, .015), "fil_cuir", biseau=.003,
            )
    rivet(api, collection, "Rivet_de_poignet", (x + signe * .519, -.271, 2.344), (signe, 0, 0), .038, "laiton")


def botte(api, signe, cote):
    collection = api.collection("09_Botte_" + cote)
    x = signe * .502
    anneaux(api, collection, "Botte_" + cote, (x, -.021), [
        (.015, .989, 1.012, .102), (.053, .998, 1.059, .108),
        (.261, 1.000, 1.053, .108), (.346, .997, 1.019, .092),
        (.369, .981, 1.002, .089),
    ], "bottes")
    anneaux(api, collection, "Semelle_" + cote, (x, -.030), [
        (0, .980, 1.025, .116), (.018, 1.002, 1.069, .122),
        (.070, 1.000, 1.067, .122), (.088, .987, 1.045, .114),
    ], "ceinture")
    anneaux(api, collection, "Embout_renforce", (x, -.438), [
        (.078, .901, .304, .086), (.106, .918, .322, .088),
        (.190, .914, .296, .081), (.228, .867, .241, .070),
    ], "embout")
    api.boite(collection, "Bride_de_botte", (x + signe * .487, .068, .283), (.043, .615, .105), "cuir", biseau=.015)
    xb = x + signe * .515
    for y in (-.045, .113):
        api.boite(collection, "Cote_de_boucle", (xb, y, .287), (.026, .030, .110), "laiton", biseau=.006)
    for z in (.239, .335):
        api.boite(collection, "Traverse_de_boucle", (xb, .034, z), (.025, .139, .023), "laiton", biseau=.005)
    for i in range(6):
        api.boite(
            collection, "Couture_embout", (x - .324 + i * .128, -.549, .241),
            (.060, .009, .012), "fil_cuir", biseau=.003,
        )
    for y in (-.382, -.244, -.105, .034, .172, .311):
        api.boite(collection, "Strie_semelle", (x + signe * .499, y, .036), (.011, .057, .033), "bottes", biseau=.003)


def construire(api):
    casque_et_lampe(api)
    ceinture_et_pioche(api)
    for signe, cote in [(1, "G"), (-1, "D")]:
        gant(api, signe, cote)
        botte(api, signe, cote)
