"""Déplie et peint les atlas des meshes du Mineur du Pic Doré."""

from collections import Counter
from pathlib import Path
import struct
import zlib

import bpy
import numpy as np


# Couleur sRGB, famille de surface, rugosité, métal.
PALETTE = {
    "peau": ("C99167", "peau", 0.82, 0.0),
    "visage_yeux": ("332928", "plat", 0.82, 0.0),
    "visage_sourcils": ("593C2E", "plat", 0.82, 0.0),
    "visage_bouche": ("694035", "plat", 0.82, 0.0),
    "visage_poussiere": ("9D7359", "peau", 0.91, 0.0),
    "lin": ("A99573", "toile", 0.87, 0.0),
    "col": ("C2AC87", "toile", 0.87, 0.0),
    "bleu": ("46545B", "toile", 0.90, 0.0),
    "bleu_renfort": ("4E5D65", "toile", 0.92, 0.0),
    "cuir": ("72503B", "cuir", 0.78, 0.0),
    "laiton": ("BA853E", "laiton", 0.56, 0.66),
    "fil_lin": ("C6AD83", "plat", 0.91, 0.0),
    "fil_bleu": ("899495", "plat", 0.92, 0.0),
    "poussiere": ("AA8E6C", "toile", 0.94, 0.0),
    "ardoise": ("2D3336", "peinture", 0.72, 0.08),
    "bandeau": ("41494C", "peinture", 0.73, 0.08),
    "verre": ("F3D48B", "verre", 0.39, 0.0),
    "gants": ("654A37", "cuir", 0.83, 0.0),
    "bottes": ("3B3430", "cuir", 0.81, 0.0),
    "fer": ("717777", "fer", 0.63, 0.63),
    "embout": ("555B5B", "fer", 0.69, 0.56),
    "ceinture": ("51372B", "cuir", 0.78, 0.0),
    "bois": ("835B3C", "bois", 0.86, 0.0),
    "fil_cuir": ("A78865", "plat", 0.91, 0.0),
}


def _rgb(hexa):
    return np.array([int(hexa[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32) / 255


def _linear(couleur):
    return tuple(float(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4) for v in couleur)


def materiau(cle):
    """Matériau de travail. Son nom identifie la matière pendant la cuisson."""
    present = bpy.data.materials.get(cle)
    if present:
        return present
    hexa, _, rugosite, metal = PALETTE[cle]
    mat = bpy.data.materials.new(cle)
    mat.use_nodes = True
    couleur = (*_linear(_rgb(hexa)), 1.0)
    mat.diffuse_color = couleur
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = couleur
    shader.inputs["Roughness"].default_value = rugosite
    shader.inputs["Metallic"].default_value = metal
    if cle == "verre":
        shader.inputs["Emission Color"].default_value = couleur
        shader.inputs["Emission Strength"].default_value = 0.28
    return mat


def _bruit(points, taux, graine=0.0):
    """Bruit de valeur interpolé, stable aux coutures UV."""
    p = points * taux
    origine = np.floor(p)
    proportion = p - origine
    proportion = proportion * proportion * (3 - 2 * proportion)
    poids_x, poids_y, poids_z = proportion.T
    somme = np.zeros(len(points), dtype=np.float32)
    for x in (0, 1):
        for y in (0, 1):
            for z in (0, 1):
                h = np.sin(
                    (origine[:, 0] + x) * 19.19
                    + (origine[:, 1] + y) * 57.47
                    + (origine[:, 2] + z) * 99.11
                    + graine
                ) * 43758.5453
                valeur = h - np.floor(h)
                poids = (
                    (poids_x if x else 1 - poids_x)
                    * (poids_y if y else 1 - poids_y)
                    * (poids_z if z else 1 - poids_z)
                )
                somme += poids * valeur
    return somme


def _motif(cle, points, normale):
    hexa, famille, rugosite, metal = PALETTE.get(cle, PALETTE["ardoise"])
    couleur = _rgb(hexa)
    if famille == "plat":
        return np.broadcast_to(couleur, (len(points), 3)), rugosite, metal, 0.0

    x, y, z = points.T
    surface = np.argsort(np.abs(normale))[:2]
    a, b = points[:, surface[0]], points[:, surface[1]]
    cote = np.abs(x)
    nuage = _bruit(points, 4.2, 3.6)
    grain = _bruit(points, 103.0, 9.8)
    variation = 0.045 * (nuage - 0.5) + 0.045 * (grain - 0.5)
    creux = np.zeros(len(points), dtype=np.float32)

    if famille == "toile":
        # Croisure du fil, plis verticaux et salissures sur les zones frottées.
        trame = np.sin(a * 294) * np.sin(b * 310)
        pli = np.sin((x + y * 0.6) * 26 + z * 4 + nuage * 2.4)
        variation += 0.034 * trame + 0.045 * pli + 0.13 * (nuage - 0.5)
        genou = np.exp(-((z - 0.94) / 0.22) ** 2) * (y < -0.20)
        coude = np.exp(-((z - 2.95) / 0.20) ** 2) * (cote > 1.02)
        bas = np.clip((0.81 - z) / 0.61, 0, 1)
        creux = np.clip(nuage * 1.3 - 0.14, 0, 1) * np.maximum.reduce((genou * 0.32, coude * 0.22, bas * 0.32))
    elif famille == "cuir":
        micro = np.sin(a * 180 + b * 33 + grain * 4) * np.sin(b * 191)
        pli = np.maximum(0, np.cos(z * 26 + x * 6 + nuage * 3)) ** 8
        variation += 0.09 * (grain - 0.5) + 0.023 * micro + 0.11 * (nuage - 0.5) - 0.055 * pli
        bas = np.clip((0.52 - z) / 0.40, 0, 1) if cle == "bottes" else 0.22
        creux = bas * np.maximum(nuage - 0.20, 0) * 0.52
    elif famille in {"peinture", "fer", "laiton"}:
        # Rayures fines intermittentes et piqûres sans changer la teinte principale.
        rayure = np.maximum(0, np.sin(a * 108 + b * 21 + nuage * 4)) ** 34
        rayure *= np.clip((np.sin(b * 52 + nuage * 11) - 0.25) * 1.6, 0, 1)
        piqure = np.maximum(0, grain - 0.76)
        variation += 0.07 * (grain - 0.5) + 0.11 * rayure - 0.30 * piqure + 0.10 * (nuage - 0.5)
        creux = np.maximum(nuage - 0.46, 0) * (0.31 if famille == "peinture" else 0.19)
        rugosite = np.clip(rugosite + 0.10 * (nuage - 0.5) + piqure * 0.37, 0, 1)
    elif famille == "bois":
        veines = np.sin((x + y * 0.73) * 84 + z * 2 + nuage * 3.1)
        cerne = (2 + np.sin((x - y * 0.45) * 51 + z * 3)) / 3
        variation = 0.10 * veines + 0.077 * (cerne - 0.5) + 0.12 * (nuage - 0.5)
    elif famille == "peau":
        variation *= 0.45
    elif famille == "verre":
        variation = 0.075 * np.sin(x * 8 + z * 3) + 0.025 * (grain - 0.5)

    couleur = couleur * (1 + variation[:, None])
    poussiere = _rgb("AA8E6C")
    couleur = couleur * (1 - creux[:, None]) + poussiere * creux[:, None]
    emission = 0.28 if famille == "verre" else 0.0
    return np.clip(couleur, 0, 1), rugosite, metal, emission


def _deplier(obj, resolution):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    if not obj.data.uv_layers:
        obj.data.uv_layers.new(name="UVMap")
    obj.data.uv_layers.active.name = "UVMap"
    bpy.ops.object.mode_set(mode="EDIT")
    try:
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(
            angle_limit=1.16,
            margin_method="FRACTION",
            island_margin=max(5 / resolution, 0.011),
            area_weight=0.10,
            correct_aspect=False,
            scale_to_bounds=True,
        )
    finally:
        bpy.ops.object.mode_set(mode="OBJECT")


def _rasteriser(obj, taille):
    mesh = obj.data
    mesh.calc_loop_triangles()
    uvs = np.empty(len(mesh.loops) * 2, dtype=np.float32)
    mesh.uv_layers.active.data.foreach_get("uv", uvs)
    uvs = uvs.reshape((-1, 2)) * taille
    monde = obj.matrix_world
    points = np.array([tuple(monde @ sommet.co) for sommet in mesh.vertices], dtype=np.float32)
    remplis = np.zeros((taille, taille), dtype=bool)
    interieurs = np.zeros_like(remplis)
    atlas = np.zeros((taille, taille, 6), dtype=np.float32)
    chevauchements = 0
    cles = [slot.material.name if slot.material else "ardoise" for slot in obj.material_slots]
    normales = monde.to_3x3().inverted_safe().transposed()
    for triangle in mesh.loop_triangles:
        t = uvs[list(triangle.loops)]
        bas = np.maximum(np.ceil(t.min(axis=0) - 0.5).astype(int), 0)
        haut = np.minimum(np.floor(t.max(axis=0) - 0.5).astype(int), taille - 1)
        if np.any(haut < bas):
            continue
        e1, e2 = t[1] - t[0], t[2] - t[0]
        determinant = e1[0] * e2[1] - e1[1] * e2[0]
        if abs(determinant) < 1e-10:
            continue
        xx, yy = np.meshgrid(np.arange(bas[0], haut[0] + 1), np.arange(bas[1], haut[1] + 1))
        dx, dy = xx + 0.5 - t[0, 0], yy + 0.5 - t[0, 1]
        w1 = (dx * e2[1] - dy * e2[0]) / determinant
        w2 = (e1[0] * dy - e1[1] * dx) / determinant
        w0 = 1 - w1 - w2
        minimum = np.minimum(np.minimum(w0, w1), w2)
        dans = minimum >= -1e-5
        franc = minimum > 1e-4
        chevauchements += int(np.count_nonzero(interieurs[yy[franc], xx[franc]]))
        interieurs[yy[franc], xx[franc]] = True
        if not dans.any():
            continue
        poids = np.stack((w0[dans], w1[dans], w2[dans]), axis=1)
        xyz = poids @ points[list(triangle.vertices)]
        index = triangle.material_index
        cle = cles[index] if index < len(cles) else "ardoise"
        valeurs = _motif(cle, xyz, tuple(normales @ triangle.normal))
        iy, ix = yy[dans], xx[dans]
        atlas[iy, ix, :3], atlas[iy, ix, 3], atlas[iy, ix, 4], atlas[iy, ix, 5] = valeurs
        remplis[iy, ix] = True
    return atlas, remplis, chevauchements


def _etendre(atlas, masque, marge=6):
    """Prolonge les îlots dans les marges pour les niveaux de mipmap."""
    masque = masque.copy()
    taille = masque.shape[0]
    for _ in range(marge):
        precedents = masque.copy()
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            source = (slice(max(0, -dy), taille - max(0, dy)), slice(max(0, -dx), taille - max(0, dx)))
            cible = (slice(max(0, dy), taille - max(0, -dy)), slice(max(0, dx), taille - max(0, -dx)))
            prendre = precedents[source] & ~masque[cible]
            atlas[cible][prendre] = atlas[source][prendre]
            masque[cible][prendre] = True
    return masque


def _png(chemin, data, srgb=False):
    pixels = np.rint(np.clip(data[::-1], 0, 1) * 255).astype(np.uint8)
    h, l = pixels.shape[:2]
    nature = 2 if pixels.ndim == 3 else 0

    def morceau(nom, message):
        crc = zlib.crc32(nom + message)
        return struct.pack(">I", len(message)) + nom + message + struct.pack(">I", crc)

    with chemin.open("wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(morceau(b"IHDR", struct.pack(">IIBBBBB", l, h, 8, nature, 0, 0, 0)))
        if srgb:
            f.write(morceau(b"sRGB", b"\x00"))
        scanlines = b"".join(b"\x00" + ligne.tobytes() for ligne in pixels)
        f.write(morceau(b"IDAT", zlib.compress(scanlines, 6)))
        f.write(morceau(b"IEND", b""))


def _materiau_atlas(obj, fichiers, hexa):
    mat = bpy.data.materials.new(f"{obj.name}_Atlas")
    mat.use_nodes = True
    mat.diffuse_color = (*_linear(_rgb(hexa)), 1.0)
    nodes = mat.node_tree.nodes
    relier = mat.node_tree.links.new
    shader = nodes.get("Principled BSDF")
    couleurs = None
    for index, (cle, entree) in enumerate((
        ("albedo", "Base Color"), ("rugosite", "Roughness"), ("metal", "Metallic"), ("emission", "Emission Strength")
    )):
        chemin = fichiers.get(cle)
        if chemin is None:
            continue
        node = nodes.new("ShaderNodeTexImage")
        node.label = chemin.stem
        node.image = bpy.data.images.load(str(chemin), check_existing=True)
        node.image.colorspace_settings.name = "sRGB" if cle == "albedo" else "Non-Color"
        node.location = (-310, 280 - index * 240)
        relier(node.outputs["Color"], shader.inputs[entree])
        if cle == "albedo":
            couleurs = node
    if "emission" in fichiers:
        relier(couleurs.outputs["Color"], shader.inputs["Emission Color"])
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for polygone in obj.data.polygons:
        polygone.material_index = 0


def bake(obj, dossier, resolution=512):
    """Écrit les cartes par pièce, assigne l'atlas et donne les compteurs UV."""
    dossier = Path(dossier).resolve()
    dossier.mkdir(parents=True, exist_ok=True)
    _deplier(obj, resolution)
    atlas, couverture, chevauchements = _rasteriser(obj, resolution)
    compte = int(couverture.sum())
    if not compte:
        raise ValueError(f"Atlas vide : {obj.name}")
    if chevauchements:
        print(f"[UV] {obj.name}: {chevauchements} pixels superposés")
    cle = Counter(
        obj.material_slots[p.material_index].material.name
        for p in obj.data.polygons
        if p.material_index < len(obj.material_slots) and obj.material_slots[p.material_index].material
    ).most_common(1)
    hexa, _, rugosite, metal = PALETTE.get(cle[0][0] if cle else "ardoise", PALETTE["ardoise"])
    rempli = _etendre(atlas, couverture)
    atlas[~rempli, :3] = _rgb(hexa)
    atlas[~rempli, 3] = rugosite
    atlas[~rempli, 4] = metal
    nom = bpy.path.clean_name(obj.name)
    fichiers = {
        "albedo": dossier / f"{nom}_Albedo.png",
        "rugosite": dossier / f"{nom}_Rugosite.png",
        "metal": dossier / f"{nom}_Metal.png",
    }
    _png(fichiers["albedo"], atlas[:, :, :3], srgb=True)
    _png(fichiers["rugosite"], atlas[:, :, 3])
    _png(fichiers["metal"], atlas[:, :, 4])
    if np.any(atlas[:, :, 5]):
        fichiers["emission"] = dossier / f"{nom}_Emission.png"
        _png(fichiers["emission"], atlas[:, :, 5])
    _materiau_atlas(obj, fichiers, hexa)
    fichiers["uv_pixels"] = compte
    fichiers["uv_chevauchement"] = chevauchements
    return fichiers
