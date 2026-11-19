"""Outils communs aux scripts Blender du jeu (lancés sans interface) :
    blender --background --factory-startup --python blender/pnj.py

Toute la géométrie est décrite dans le repère du jeu (« repère L ») :
    x = droite du personnage, y = haut, z = arrière (-z = devant, comme LookVector dans Roblox)
puis convertie dans le repère de Blender (z en haut) avec CONV.
"""
import bpy
import bmesh
import math
import os
import random
from mathutils import Vector, Matrix, Euler, noise

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(RACINE, "assets")
APERCUS = os.path.join(RACINE, "blender", "apercus")

# L(x, y, z) -> Blender(-x, z, y)  (rotation propre, pas de miroir)
CONV = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def vider():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    os.makedirs(ASSETS, exist_ok=True)
    os.makedirs(APERCUS, exist_ok=True)


def lin(rgb):
    def f(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    return (f(rgb[0]), f(rgb[1]), f(rgb[2]), 1.0)


def materiau(nom, rgb, rugosite=0.8, metal=0.0):
    m = bpy.data.materials.get(nom)
    if m:
        return m
    m = bpy.data.materials.new(nom)
    c = lin(rgb)
    m.diffuse_color = c
    m.roughness = rugosite
    m.metallic = metal
    try:
        nt = m.node_tree
        b = nt.nodes.get("Principled BSDF") if nt else None
        if b:
            b.inputs["Base Color"].default_value = c
            b.inputs["Roughness"].default_value = rugosite
            b.inputs["Metallic"].default_value = metal
    except Exception:
        pass
    return m


# ---------- transformations (repère L) ----------

def T(pos=(0, 0, 0), rot=(0, 0, 0), echelle=(1, 1, 1)):
    if not isinstance(echelle, (tuple, list, Vector)):
        echelle = (echelle, echelle, echelle)
    S = Matrix.Diagonal((echelle[0], echelle[1], echelle[2], 1))
    return Matrix.Translation(Vector(pos)) @ Euler(rot, 'XYZ').to_matrix().to_4x4() @ S


# ---------- primitives bmesh (repère L, avant conversion) ----------

def bm_sphere(M, u=24, v=14):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
    return bm


def bm_cube(M):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
    return bm


def bm_ico(M, subdiv=4):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
    bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
    return bm


def bm_loft(anneaux, seg=20, bas=True, haut=True, M=None):
    """anneaux : liste de (y, rx, rz) ou (y, rx, rz, cx, cz) le long de l'axe vertical."""
    bm = bmesh.new()
    cercles = []
    for a in anneaux:
        y, rx, rz = a[0], a[1], a[2]
        cx = a[3] if len(a) > 3 else 0.0
        cz = a[4] if len(a) > 4 else 0.0
        cercle = []
        for i in range(seg):
            t = 2 * math.pi * i / seg
            cercle.append(bm.verts.new((cx + rx * math.cos(t), y, cz + rz * math.sin(t))))
        cercles.append((cercle, (cx, y, cz)))
    for k in range(len(cercles) - 1):
        a, b = cercles[k][0], cercles[k + 1][0]
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((a[i], a[j], b[j], b[i]))
    if bas:
        c = bm.verts.new(cercles[0][1])
        r = cercles[0][0]
        for i in range(seg):
            bm.faces.new((r[(i + 1) % seg], r[i], c))
    if haut:
        c = bm.verts.new(cercles[-1][1])
        r = cercles[-1][0]
        for i in range(seg):
            bm.faces.new((r[i], r[(i + 1) % seg], c))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if M is not None:
        bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
    return bm


def bm_tore(M, R=1.0, r=0.2, seg=28, segp=10, arc=2 * math.pi, rz=None):
    """Tore horizontal (plan x-z du repère L). arc < 2pi : portion ouverte. rz : grand rayon en z (ellipse)."""
    rz = R if rz is None else rz
    bm = bmesh.new()
    ferme = arc >= 2 * math.pi - 1e-6
    n = seg if ferme else seg + 1
    anneaux = []
    for i in range(n):
        t = arc * i / seg - (0 if ferme else arc / 2) + (0 if ferme else math.pi / 2)
        cx, cz = R * math.cos(t), rz * math.sin(t)
        nx, nz = math.cos(t), math.sin(t)
        anneau = []
        for j in range(segp):
            p = 2 * math.pi * j / segp
            anneau.append(bm.verts.new((cx + nx * r * math.cos(p), r * math.sin(p), cz + nz * r * math.cos(p))))
        anneaux.append(anneau)
    for i in range(n if ferme else n - 1):
        a, b = anneaux[i], anneaux[(i + 1) % n]
        for j in range(segp):
            k = (j + 1) % segp
            bm.faces.new((a[j], a[k], b[k], b[j]))
    if not ferme:
        for anneau in (anneaux[0], anneaux[-1]):
            bm.faces.new(anneau)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
    return bm


# ---------- objets ----------

def lier(ob):
    bpy.context.scene.collection.objects.link(ob)
    return ob


def objet(nom, bm, mat=None, convertir=True, decal=(0, 0, 0)):
    if convertir:
        bmesh.ops.transform(bm, matrix=Matrix.Translation(Vector(decal)) @ CONV, verts=bm.verts)
    me = bpy.data.meshes.new(nom)
    bm.to_mesh(me)
    bm.free()
    ob = lier(bpy.data.objects.new(nom, me))
    if mat:
        me.materials.append(mat)
    return ob


def modif(ob, genre, **props):
    m = ob.modifiers.new(genre.lower(), genre)
    for k, v in props.items():
        setattr(m, k, v)
    return m


def appliquer(ob):
    """Applique tous les modificateurs de l'objet."""
    if not ob.modifiers:
        return ob
    mats = list(ob.data.materials)
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    ancien = ob.data
    ob.modifiers.clear()
    ob.data = me
    if ancien.users == 0:
        bpy.data.meshes.remove(ancien)
    if not me.materials:
        for m in mats:
            me.materials.append(m)
    return ob


def lisse(ob, angle=None):
    """Ombrage lisse ; angle (degrés) : arêtes plus vives que l'angle marquées dures."""
    me = ob.data
    bm = bmesh.new()
    bm.from_mesh(me)
    for f in bm.faces:
        f.smooth = True
    if angle is not None:
        lim = math.radians(angle)
        for e in bm.edges:
            if e.is_manifold and e.calc_face_angle(0) > lim:
                e.smooth = False
    bm.to_mesh(me)
    bm.free()


def chaine(nom, points, mat=None, subdiv=2, decal=(0, 0, 0)):
    """Membre organique (modificateur Skin) : points = [(pos_L, rayon), ...]."""
    me = bpy.data.meshes.new(nom)
    vs = [Matrix.Translation(Vector(decal)) @ CONV @ Vector(p[0]) for p in points]
    me.from_pydata(vs, [(i, i + 1) for i in range(len(points) - 1)], [])
    ob = lier(bpy.data.objects.new(nom, me))
    sk = modif(ob, 'SKIN')
    sk.use_smooth_shade = True
    couche = me.skin_vertices[0].data
    for i, p in enumerate(points):
        r = p[1]
        couche[i].radius = (r, r) if not isinstance(r, (tuple, list)) else r
        couche[i].use_root = (i == 0)
    if subdiv:
        modif(ob, 'SUBSURF', levels=subdiv, render_levels=subdiv)
    appliquer(ob)
    if mat:
        ob.data.materials.clear()
        ob.data.materials.append(mat)
    return ob


def fusionner(objets, nom):
    """Fusionne plusieurs objets maillage en un seul."""
    objets = [o for o in objets if o is not None]
    bm = bmesh.new()
    mats = []
    for o in objets:
        me = o.data
        base = len(bm.verts)
        tmp = bmesh.new()
        tmp.from_mesh(me)
        tmp.transform(o.matrix_world)
        for m in me.materials:
            if m not in mats:
                mats.append(m)
        vmap = [bm.verts.new(v.co) for v in tmp.verts]
        bm.verts.ensure_lookup_table()
        for f in tmp.faces:
            try:
                nf = bm.faces.new([vmap[v.index] for v in f.verts])
                nf.smooth = f.smooth
            except ValueError:
                pass
        tmp.free()
    for o in objets:
        me = o.data
        bpy.data.objects.remove(o)
        if me.users == 0:
            bpy.data.meshes.remove(me)
    me = bpy.data.meshes.new(nom)
    bm.to_mesh(me)
    bm.free()
    for m in mats[:1]:
        me.materials.append(m)
    return lier(bpy.data.objects.new(nom, me))


def centrer_origine(ob):
    """Place l'origine au centre de la boîte englobante (pivot propre dans Roblox)."""
    me = ob.data
    if not me.vertices:
        return
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    c = Vector(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2))
    me.transform(Matrix.Translation(-c))
    ob.matrix_world = Matrix.Translation(c) @ ob.matrix_world


def triangles(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


def decimer(ob, cible):
    t = triangles(ob)
    if t > cible:
        modif(ob, 'DECIMATE', ratio=cible / t)
        appliquer(ob)


# ---------- export / rendu ----------

def exporter_fbx(nom_fichier, objets=None):
    objets = objets or [o for o in bpy.context.scene.objects if o.type == 'MESH']
    for o in bpy.context.scene.objects:
        o.select_set(o in objets)
    chemin = os.path.join(ASSETS, nom_fichier)
    bpy.ops.export_scene.fbx(
        filepath=chemin, use_selection=True, object_types={'MESH'},
        use_mesh_modifiers=True, mesh_smooth_type='FACE',
        axis_forward='-Z', axis_up='Y', apply_scale_options='FBX_SCALE_ALL',
        add_leaf_bones=False, bake_anim=False, path_mode='STRIP',
    )
    print("EXPORT", chemin, len(objets), "objets", sum(triangles(o) for o in objets), "triangles")
    return chemin


def rendu(nom_fichier, direction=(-0.55, -1.0, 0.32), objets=None, largeur=1600, hauteur=1000,
          fond=(46, 40, 52), marge=1.12, focale=None):
    """Rendu Workbench orthographique cadré sur les objets (aperçu de contrôle)."""
    sc = bpy.context.scene
    objets = objets or [o for o in sc.objects if o.type == 'MESH']
    pts = [o.matrix_world @ Vector(c) for o in objets for c in o.bound_box]
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    centre = (mn + mx) / 2
    taille = (mx - mn).length

    cam_data = bpy.data.cameras.get("CamApercu") or bpy.data.cameras.new("CamApercu")
    cam = bpy.data.objects.get("CamApercu") or lier(bpy.data.objects.new("CamApercu", cam_data))
    d = Vector(direction).normalized()
    cam.location = centre + d * taille * 2
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    cam_data.type = 'ORTHO'
    cam_data.clip_end = taille * 10
    # échelle ortho : projeter la boîte sur le plan de la caméra
    rot = cam.rotation_euler.to_matrix()
    droite, haut = rot @ Vector((1, 0, 0)), rot @ Vector((0, 1, 0))
    w = max(abs((p - centre).dot(droite)) for p in pts) * 2
    h = max(abs((p - centre).dot(haut)) for p in pts) * 2
    ratio = largeur / hauteur
    cam_data.ortho_scale = max(w, h * ratio) * marge
    sc.camera = cam

    sc.render.engine = 'BLENDER_WORKBENCH'
    sc.render.resolution_x = largeur
    sc.render.resolution_y = hauteur
    sc.render.resolution_percentage = 100
    sh = sc.display.shading
    sh.light = 'STUDIO'
    sh.color_type = 'MATERIAL'
    sh.show_cavity = True
    sh.cavity_type = 'BOTH'
    sh.show_shadows = True
    sh.show_specular_highlight = True
    w_ = sc.world or bpy.data.worlds.new("Monde")
    sc.world = w_
    w_.color = lin(fond)[:3]
    sc.render.film_transparent = False
    try:
        sc.view_settings.view_transform = 'Standard'
    except Exception:
        pass
    sc.render.image_settings.file_format = 'PNG'
    sc.render.filepath = os.path.join(APERCUS, nom_fichier)
    bpy.ops.render.render(write_still=True)
    print("RENDU", sc.render.filepath)
