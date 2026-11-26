"""Construit et exporte le Mineur du Pic Doré dans Blender background."""

import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import casque_gear
import corps_tenue
import textures_uv


RACINE = Path(__file__).resolve().parents[1]
CORPS = "01_Corps_R15"
PIVOTS = {
    "02_Visage": (0, 0, 4.586),
    "02_Casque": (0, 0, 5.176),
    "03_Lampe": (0, -0.68, 5.06),
    "04_Torse_Lin": (0, 0, 3.2),
    "05_Salopette": (0, 0, 3.2),
    "05_Salopette_LowerTorso": (0, 0, 2.2),
    "06_Ceinture": (0, 0, 2.2),
    "07_Pioche": (0.92, 0.54, 2.5),
}


def choisir(objets):
    bpy.ops.object.select_all(action="DESELECT")
    for objet in objets:
        objet.select_set(True)
    bpy.context.view_layer.objects.active = objets[0]


class Atelier:
    def __init__(self, ensemble):
        self.ensemble = ensemble
        self.materiau = textures_uv.materiau

    def collection(self, nom):
        col = self.ensemble.children.get(nom)
        if col is None:
            col = bpy.data.collections.new(nom)
            self.ensemble.children.link(col)
        return col

    def boite(self, collection, nom, centre, taille, mat, biseau=0.02, rotation=(0, 0, 0)):
        maillage = bpy.data.meshes.new(nom)
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1)
        for sommet in bm.verts:
            for axe, dimension in enumerate(taille):
                sommet.co[axe] *= dimension
        bm.to_mesh(maillage)
        bm.free()
        objet = bpy.data.objects.new(nom, maillage)
        collection.objects.link(objet)
        objet.location = centre
        objet.rotation_euler = rotation
        objet.data.materials.append(self.materiau(mat))
        if biseau > 0:
            mod = objet.modifiers.new("Arêtes adoucies", "BEVEL")
            mod.width = biseau
            mod.segments = 2
        return objet


def appliquer_modificateurs(objets):
    for objet in objets:
        choisir([objet])
        for mod in list(objet.modifiers):
            bpy.ops.object.modifier_apply(modifier=mod.name)


def joindre(objets, nom, pivot=None):
    assert objets, f"Collection vide : {nom}"
    choisir(objets)
    if len(objets) > 1:
        bpy.ops.object.join()
    objet = bpy.context.object
    objet.name = nom
    objet.data.name = nom
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    if pivot is not None:
        delta = objet.location - Vector(pivot)
        objet.data.transform(Matrix.Translation(delta))
        objet.location = pivot
    bm = bmesh.new()
    bm.from_mesh(objet.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bords = sum(not e.is_manifold for e in bm.edges)
    triangles = len(bm.faces)
    assert 0 < triangles < 4000, f"{nom} : {triangles} triangles"
    assert bords == 0, f"{nom} : {bords} arêtes ouvertes ou non-manifold"
    assert bm.calc_volume(signed=True) > 0, f"{nom} : volume ou orientation invalide"
    bm.to_mesh(objet.data)
    bm.free()
    objet.data.update()
    return objet, triangles


def pivot_piece(nom, corps):
    if nom in PIVOTS:
        return PIVOTS[nom]
    segment = nom.rsplit("_", 1)[-1]
    if nom.startswith(("08_Gant", "09_Botte")):
        segment = ("Left" if nom.endswith("_G") else "Right") + ("Hand" if "Gant" in nom else "Foot")
    if segment in corps:
        return tuple(corps[segment].location)
    raise ValueError(f"Pivot absent pour {nom}")


def exporter(fichier, objets, origine=None):
    choisir(objets)
    positions = [objet.location.copy() for objet in objets]
    try:
        if origine is not None:
            for objet in objets:
                objet.location -= Vector(origine)
        bpy.ops.export_scene.fbx(
            filepath=str(fichier),
            use_selection=True,
            object_types={"MESH"},
            global_scale=1.0,
            apply_scale_options="FBX_SCALE_UNITS",
            axis_forward="Z",
            axis_up="Y",
            use_mesh_modifiers=True,
            mesh_smooth_type="FACE",
            add_leaf_bones=False,
            bake_anim=False,
            path_mode="COPY",
            embed_textures=True,
            use_custom_props=True,
        )
    finally:
        for objet, position in zip(objets, positions):
            objet.location = position


def viser(objet, cible):
    objet.rotation_euler = (Vector(cible) - objet.location).to_track_quat("-Z", "Y").to_euler()


def eclairage(collection):
    def aire(nom, emplacement, cible, energie, taille, couleur):
        data = bpy.data.lights.new(nom, "AREA")
        data.energy = energie
        data.shape = "DISK"
        data.size = taille
        data.color = couleur
        objet = bpy.data.objects.new(nom, data)
        collection.objects.link(objet)
        objet.location = emplacement
        viser(objet, cible)

    aire("Lanterne principale", (-4.5, -4, 8), (0, 0, 2.7), 810, 4.8, (1, 0.79, 0.60))
    aire("Remplissage neutre", (4, -5, 5.1), (0, 0, 3.1), 530, 5.5, (0.83, 0.92, 1))
    aire("Contre-jour ambre", (3.2, 4.3, 7.2), (0, 0, 3), 880, 3.7, (1, 0.73, 0.46))
    aire("Retour arrière", (-4, 3.5, 4), (0, 0, 2.6), 490, 5, (0.92, 0.95, 1))
    aire("Haut doux", (0, 0, 9), (0, 0, 0), 380, 5, (1, 0.93, 0.82))

    monde = bpy.context.scene.world
    monde.use_nodes = True
    fond = monde.node_tree.nodes.get("Background")
    fond.inputs["Color"].default_value = (0.25, 0.25, 0.25, 1)
    fond.inputs["Strength"].default_value = 0.34

def cameras(collection):
    resultats = []
    for nom, angle in (
        ("01_Face", 0),
        ("02_Dos", 180),
        ("03_Profil_gauche", 90),
        ("04_Profil_droit", -90),
        ("05_Trois_quarts", 34),
    ):
        azimut = math.radians(angle)
        emplacement = (12 * math.sin(azimut), -12 * math.cos(azimut), 2.67)
        resultats.append((nom, emplacement, (0, 0, 2.67), 6.34))
    resultats.append(("06_Casque_et_visage", (2.5, -7.0, 5.55), (0, -0.12, 4.55), 2.47))
    objets = []
    for nom, emplacement, cible, echelle in resultats:
        data = bpy.data.cameras.new(nom)
        data.type = "ORTHO"
        data.ortho_scale = echelle
        objet = bpy.data.objects.new(nom, data)
        objet.location = emplacement
        collection.objects.link(objet)
        viser(objet, cible)
        objets.append(objet)
    return objets


def rendre(scene, appareils):
    for appareil in appareils:
        scene.camera = appareil
        scene.render.filepath = str(RACINE / "Rendus" / f"{appareil.name}.png")
        print(f"RENDU {appareil.name}", flush=True)
        bpy.ops.render.render(write_still=True)


def construire():
    for dossier in ("FBX", "FBX/Corps", "Textures", "Rendus"):
        (RACINE / dossier).mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = "Mineur du Pic Doré"
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.world = bpy.data.worlds.new("Ambiance neutre")

    ensemble = bpy.data.collections.new("MINEUR DU PIC DORÉ")
    scene.collection.children.link(ensemble)
    api = Atelier(ensemble)
    corps_tenue.construire(api)
    casque_gear.construire(api)
    appliquer_modificateurs([objet for objet in ensemble.all_objects if objet.type == "MESH"])

    corps = {objet.name: objet for objet in ensemble.children[CORPS].objects if objet.type == "MESH"}
    assert len(corps) == 15, f"Le corps doit avoir 15 segments R15, trouvé {list(corps)}"

    # Une version fusionnée du casque facilite l’Importateur quand un seul MeshPart est souhaité.
    reserve = bpy.data.collections.new("EXPORT · casque et lampe fusionnés")
    scene.collection.children.link(reserve)
    copies = []
    for nom in ("02_Casque", "03_Lampe"):
        for objet in ensemble.children[nom].objects:
            if objet.type == "MESH":
                copie = objet.copy()
                copie.data = objet.data.copy()
                reserve.objects.link(copie)
                copies.append(copie)
    casque_complet, n = joindre(copies, "Casque_Ensemble", PIVOTS["02_Casque"])
    geometries = [(casque_complet, n)]
    pieces = {}
    for collection in ensemble.children:
        if collection.name == CORPS:
            for nom, objet in corps.items():
                geometries.append(joindre([objet], nom))
        else:
            nom = collection.name
            objets = [objet for objet in collection.objects if objet.type == "MESH"]
            if not objets:
                continue
            mesh, n = joindre(objets, nom, pivot_piece(nom, corps))
            pieces[nom] = mesh
            geometries.append((mesh, n))

    for objet, triangles in geometries:
        taille = 1024 if objet.name in {"02_Casque", "03_Lampe", "Casque_Ensemble", "04_Torse_Lin", "05_Salopette"} else 512
        stats = textures_uv.bake(objet, RACINE / "Textures", resolution=taille)
        assert stats["uv_chevauchement"] == 0, f"UV superposés : {objet.name} {stats}"
        objet["triangles"] = triangles
        objet["reference"] = "R15 bloc · 1 unité Blender = 1 stud à l’import"
        print(f"PIECE {objet.name} {triangles} tris {taille}px UV_OK", flush=True)

    fbx = RACINE / "FBX"
    exporter(fbx / "Casque_Ensemble.fbx", [casque_complet], casque_complet.location.copy())
    for nom, objet in pieces.items():
        exporter(fbx / f"{nom}.fbx", [objet], objet.location.copy())
    for nom, objet in corps.items():
        exporter(fbx / "Corps" / f"{nom}.fbx", [objet], objet.location.copy())
    exporter(fbx / "Corps_R15.fbx", list(corps.values()))
    remplaces = {
        f"{cote}{segment}"
        for cote in ("Left", "Right")
        for segment in ("Hand", "Foot", "UpperLeg", "LowerLeg")
    }
    habille = [objet for nom, objet in corps.items() if nom not in remplaces] + list(pieces.values())
    exporter(fbx / "Mineur_Complet.fbx", habille)
    for nom in remplaces:
        corps[nom].hide_render = True
        corps[nom].hide_set(True)
    reserve.hide_render = True
    reserve.hide_viewport = True

    studio = bpy.data.collections.new("STUDIO · présentation")
    scene.collection.children.link(studio)
    eclairage(studio)
    appareils = cameras(studio)
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 28
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 5
    scene.render.resolution_x = 960
    scene.render.resolution_y = 1120
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.camera = appareils[4]
    scene.render.filepath = "//Rendus/05_Trois_quarts.png"
    bpy.ops.object.select_all(action="DESELECT")
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                area.spaces.active.region_3d.view_perspective = "CAMERA"
                area.spaces.active.shading.type = "MATERIAL"
                area.spaces.active.shading.use_scene_lights = True
                area.spaces.active.shading.use_scene_world = True
    bpy.ops.file.pack_all()
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(RACINE / "Mineur_du_Pic_Dore.blend"))
    print(f"ASSEMBLAGE {len(geometries)} maillages {sum(n for _, n in geometries)} triangles avec casque alternatif", flush=True)
    if "--sans-rendus" not in sys.argv:
        rendre(scene, appareils)


if __name__ == "__main__":
    construire()
