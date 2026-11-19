"""Regroupe les 11 pioches dans un seul FBX texturé pour Roblox : assets/Pioches.fbx.

L'import Roblox ignore les couleurs peintes sur les sommets (les modèles arrivent tout blancs).
Pour chaque pioche (blender/pioches/out_Pioche<X>/Pioche<X>.blend) :
  1. nouvelle carte UV « Bake » commune à toutes les pièces (dépliage + rangement dans un seul carré) ;
  2. la couleur de l'Atelier (couleurs peintes + motif à studs) est cuite dans une texture
     assets/textures/Pioche<X>.png (1024 px) ;
  3. chaque pièce reçoit un matériau simple qui lit cette texture.
Les pièces gardent leurs noms « PiocheDemon_Tete_FerNoir » : le jeu les retrouve par leur préfixe.

    "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" -b --factory-startup --python blender/pioches/exporte_roblox.py
"""
import os, math
import bpy

ICI = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.normpath(os.path.join(ICI, '..', '..', 'assets'))
TEXTURES = os.path.join(ASSETS, 'textures')
SORTIE = os.path.join(ASSETS, 'Pioches.fbx')
IDS = ['Bois', 'Pierre', 'Cuivre', 'Fer', 'Quartz', 'Givre', 'Volcan', 'Celeste', 'Demon', 'Neant', 'Legende']
TAILLE = 1024


def cuire(ID):
    """Ouvre la pioche, cuit sa texture, renvoie ses pièces prêtes à exporter (dans la scène courante)."""
    bpy.ops.wm.open_mainfile(filepath=os.path.join(ICI, 'out_' + ID, ID + '.blend'))
    scene = bpy.context.scene
    objs = [o for o in scene.objects if o.type == 'MESH' and o.name.startswith(ID + '_')]
    for o in scene.objects:
        o.select_set(o in objs)
    bpy.context.view_layer.objects.active = objs[0]

    # 1. carte UV « Bake » (l'ancienne « UVMap » reste celle du motif à studs pendant la cuisson)
    for o in objs:
        uv = o.data.uv_layers.new(name='Bake')
        o.data.uv_layers.active = uv
        for l in o.data.uv_layers:
            l.active_render = (l.name == 'UVMap')
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.004, area_weight=0.0, correct_aspect=True,
                             scale_to_bounds=False)
    bpy.ops.uv.pack_islands(margin=0.004)
    bpy.ops.object.mode_set(mode='OBJECT')

    # 2. cuisson : la couleur de base de chaque matériau passe par une émission (les métaux cuiraient en noir sinon)
    img = bpy.data.images.new(ID, TAILLE, TAILLE, alpha=False)
    mats = {m for o in objs for m in o.data.materials if m}
    for m in mats:
        nt = m.node_tree
        b = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
        out = next(n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL')
        # le motif à studs lit explicitement « UVMap »
        for n in list(nt.nodes):
            if n.type == 'TEX_IMAGE':
                uvn = nt.nodes.new('ShaderNodeUVMap'); uvn.uv_map = 'UVMap'
                nt.links.new(uvn.outputs['UV'], n.inputs['Vector'])
        em = nt.nodes.new('ShaderNodeEmission')
        lien = b.inputs['Base Color'].links
        if lien:
            nt.links.new(lien[0].from_socket, em.inputs['Color'])
        else:
            em.inputs['Color'].default_value = b.inputs['Base Color'].default_value
        nt.links.new(em.outputs['Emission'], out.inputs['Surface'])
        cible = nt.nodes.new('ShaderNodeTexImage'); cible.image = img
        uvb = nt.nodes.new('ShaderNodeUVMap'); uvb.uv_map = 'Bake'
        nt.links.new(uvb.outputs['UV'], cible.inputs['Vector'])
        for n in nt.nodes:
            n.select = False
        cible.select = True
        nt.nodes.active = cible
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 4
    scene.render.bake.margin = 6
    bpy.ops.object.bake(type='EMIT', margin=6, use_clear=True)
    os.makedirs(TEXTURES, exist_ok=True)
    chemin = os.path.join(TEXTURES, ID + '.png')
    img.filepath_raw = chemin
    img.file_format = 'PNG'
    img.save()

    # 3. matériau final : texture cuite sur la carte « Bake », seule carte UV gardée
    mat = bpy.data.materials.new(ID)
    mat.use_nodes = True
    nt = mat.node_tree
    b = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
    tex = nt.nodes.new('ShaderNodeTexImage'); tex.image = bpy.data.images.load(chemin)
    nt.links.new(tex.outputs['Color'], b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.6
    for o in objs:
        o.data.materials.clear()
        o.data.materials.append(mat)
        ancienne = o.data.uv_layers.get('UVMap')
        if ancienne:
            o.data.uv_layers.remove(ancienne)
        o.data.uv_layers['Bake'].active = True
        o.data.uv_layers['Bake'].active_render = True
    # garde seulement ces pièces dans un fichier à part, fusionné ensuite
    tmp = os.path.join(ICI, 'out_' + ID, ID + '_roblox.blend')
    bpy.data.libraries.write(tmp, set(objs), fake_user=True)
    print('CUIT', ID, len(objs), 'pièces', chemin)
    return tmp


fichiers = [cuire(ID) for ID in IDS if os.path.exists(os.path.join(ICI, 'out_Pioche' + ID, 'Pioche' + ID + '.blend'))
            for ID in ['Pioche' + ID]]

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
for f in fichiers:
    with bpy.data.libraries.load(f, link=False) as (src, dst):
        dst.objects = list(src.objects)
    for o in dst.objects:
        if o is not None:
            scene.collection.objects.link(o)
for o in scene.objects:
    o.select_set(o.type == 'MESH')
bpy.ops.export_scene.fbx(filepath=SORTIE, use_selection=True, object_types={'MESH'}, colors_type='NONE',
                         axis_forward='-Z', axis_up='Y', apply_scale_options='FBX_SCALE_ALL', path_mode='COPY',
                         embed_textures=True, mesh_smooth_type='FACE')
print('EXPORT_OK', SORTIE, len(scene.objects), 'pièces')
