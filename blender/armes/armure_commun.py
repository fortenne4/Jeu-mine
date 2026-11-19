"""Outils communs des armures voxel (Casque, Plastron, Jambieres) : export Luau + rendu Blender.
Même style que epee_fer.py : quelques Parts (boîtes), métal + cuir + rivets cuivre, petit cristal.

Repère Roblox de chaque pièce : origine = centre de la pièce (Part "Racine", créée par init.lua),
devant = -Z, haut = +Y, droite du personnage = +X. Unités = studs.
Une pièce = (nom, couleur, taille (x, y, z), position (x, y, z), rotation Y en degrés, groupe ou None).
Couleurs = nom -> (matériau Roblox, (r, g, b), reflectance, facteur de teinte ou None).
  facteur 1    -> métal principal : prend la teinte de l'alliage
  facteur 0.72 -> métal sombre (bords, arêtes) : teinte x 0.72
  None         -> cuir, rivets, cristal : couleur fixe
"""
import math, os, sys

ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.abspath(os.path.join(ICI, '..', '..'))
DOSSIER_LUA = os.path.join(JEU, 'src', 'partage', 'ArmuresVoxels')
DOSSIER_PNG = os.path.join(JEU, 'previews', 'armes')

COUL = {
    'acier':   ('Metal', (176, 184, 194), 0.15, 1),
    'acierF':  ('Metal', (127, 132, 140), 0.05, 0.72),
    'cuivre':  ('Metal', (196, 114, 62), 0.1, None),
    'cuivreF': ('Metal', (138, 74, 40), 0, None),
    'patine':  ('Metal', (82, 158, 136), 0, None),
    'cuir':    ('Fabric', (96, 60, 34), 0, None),
    'lanière': ('Fabric', (58, 36, 21), 0, None),
    'cristal': ('Neon', (110, 225, 255), 0, None),
}
CRISTAL = (110, 225, 255)


def P(nom, k, s, p, ry=0, g=None):
    return (nom, k, tuple(s), tuple(p), ry, g)


def sym(pieces):
    """Ajoute le miroir en X de chaque pièce décentrée (gauche <-> droite)."""
    out = []
    for nom, k, s, p, ry, g in pieces:
        out.append((nom, k, s, p, ry, g))
        if abs(p[0]) > 1e-6:
            out.append((nom, k, s, (-p[0], p[1], p[2]), -ry, g))
    return out


def bornes(pieces):
    lo = [min(p[i] - s[i] / 2 for _, _, s, p, _, _ in pieces) for i in range(3)]
    hi = [max(p[i] + s[i] / 2 for _, _, s, p, _, _ in pieces) for i in range(3)]
    return lo, hi


# ---------------------------------------------------------------- export Luau
def f3(v):
    return 'Vector3.new(%s)' % ', '.join(('%.3f' % c).rstrip('0').rstrip('.') if abs(c) > 1e-9 else '0' for c in v)


def export_lua(ID, nom_affiche, script, pieces, lueur=None, groupes=None):
    lo, hi = bornes(pieces)
    taille = tuple(h - l for l, h in zip(lo, hi))
    utilisees = [k for k in COUL if any(pc[1] == k for pc in pieces)]
    L = ['-- Généré par blender/armes/%s (%s, %d pièces). Ne pas modifier à la main.' % (script, ID, len(pieces)),
         '-- Repère = Racine : origine au centre de la pièce, devant = -Z, haut = +Y, droite = +X, unités = studs.',
         'return {',
         '\tNom = "%s",' % nom_affiche,
         '\tTaille = %s,' % f3(taille),
         '\t-- nom -> {matériau, r, g, b, reflectance, facteur de teinte (nil = couleur fixe)}',
         '\tCouleurs = {']
    for k in utilisees:
        m, c, r, t = COUL[k]
        L.append('\t\t["%s"] = {"%s", %d, %d, %d, %g%s},' % (k, m, *c, r, '' if t is None else ', %g' % t))
    L.append('\t},')
    if groupes:
        L.append('\t-- sous-groupes : nom -> centre (repère de Racine)')
        L.append('\tGroupes = {')
        for g, c in groupes.items():
            L.append('\t\t%s = %s,' % (g, f3(c)))
        L.append('\t},')
    L.append('\t-- nom, couleur, taille, position (repère de Racine), rotation Y (degrés), groupe')
    L.append('\tPieces = {')
    for nom, k, s, p, ry, g in pieces:
        L.append('\t\t{"%s", "%s", %s, %s, %g%s},' % (nom, k, f3(s), f3(p), ry, '' if g is None else ', "%s"' % g))
    L.append('\t},')
    if lueur:
        L.append('\tLueur = {Couleur = Color3.fromRGB(%d, %d, %d), Portee = %g, Luminosite = %g},'
                 % (*lueur['couleur'], lueur['portee'], lueur['luminosite']))
    L.append('}')
    os.makedirs(DOSSIER_LUA, exist_ok=True)
    dest = os.path.join(DOSSIER_LUA, ID + '.lua')
    open(dest, 'w', encoding='utf8', newline='\n').write('\n'.join(L) + '\n')
    print('ARME_LUA', dest, len(pieces), 'pieces', 'taille=%.2f x %.2f x %.2f' % taille)


# ---------------------------------------------------------------- rendu Blender
def scene(res=(1300, 1100)):
    import bpy
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    for eng in ('BLENDER_EEVEE', 'BLENDER_EEVEE_NEXT'):
        try:
            sc.render.engine = eng
            break
        except TypeError:
            pass
    sc.view_settings.view_transform = 'Standard'
    sc.render.resolution_x, sc.render.resolution_y = res
    w = bpy.data.worlds.new('W'); sc.world = w
    w.use_nodes = True
    w.node_tree.nodes['Background'].inputs[0].default_value = (0.035, 0.032, 0.04, 1)
    return sc


_mats = {}


def materiau(k, c, m):
    import bpy
    cle = (k, c)
    if cle in _mats:
        return _mats[cle]
    mat = bpy.data.materials.new(k); mat.use_nodes = True
    b = mat.node_tree.nodes['Principled BSDF']
    rgb = tuple((v / 255) ** 2.2 for v in c) + (1,)
    b.inputs['Base Color'].default_value = rgb
    b.inputs['Roughness'].default_value = 0.42 if m == 'Metal' else 0.85
    b.inputs['Metallic'].default_value = 0.55 if m == 'Metal' else 0
    if m == 'Neon':
        b.inputs['Emission Color'].default_value = rgb
        b.inputs['Emission Strength'].default_value = 2.5
    _mats[cle] = mat
    return mat


def r2b(v):  # Roblox (x, y, z) -> Blender (x, -z, y)
    from mathutils import Vector
    return Vector((v[0], -v[2], v[1]))


def poser(pieces, loc=(0, 0, 0), rot=0, teinte=None, decal=(0, 0, 0)):
    """Place une pièce d'armure ; loc en Blender, rot autour de Z (deg), decal en repère Roblox."""
    import bpy
    from mathutils import Euler
    sc = bpy.context.scene
    piv = bpy.data.objects.new('Piv', None); sc.collection.objects.link(piv)
    piv.location = loc; piv.rotation_euler = Euler((0, 0, math.radians(rot)))
    for nom, k, s, p, ry, g in pieces:
        m, c, r, t = COUL[k]
        if teinte is not None and t is not None:
            c = tuple(min(255, round(v * t)) for v in teinte)
        bpy.ops.mesh.primitive_cube_add(size=1)
        o = bpy.context.object
        o.scale = (s[0], s[2], s[1])
        o.location = r2b(tuple(a + b for a, b in zip(p, decal)))
        o.rotation_euler = Euler((0, 0, math.radians(ry)))
        o.data.materials.append(materiau(k, c, m))
        o.parent = piv
    return piv


def mannequin(loc=(0, 0, 0), rot=0):
    """R15 en blocs gris (repère : centre UpperTorso = 0) pour juger l'ajustement."""
    gris = [('m', (2, 1.6, 1), (0, 0, 0)), ('m', (1.2, 1.2, 1.2), (0, 1.45, 0)), ('m', (2, 0.4, 1), (0, -1.0, 0)),
            ('m', (1, 2, 1), (-1.5, -0.2, 0)), ('m', (1, 2, 1), (1.5, -0.2, 0)),
            ('m', (1, 2.0, 1), (-0.5, -2.2, 0)), ('m', (1, 2.0, 1), (0.5, -2.2, 0))]
    COUL['_mannequin'] = ('Plastic', (70, 70, 78), 0, None)
    return poser([(n, '_mannequin', s, p, 0, None) for n, s, p in gris], loc, rot)


def lumieres_et_camera(ortho, cz, cx=0, dist=14):
    import bpy
    from mathutils import Euler
    sc = bpy.context.scene

    def lumiere(nom, e, rot, col=(1, 1, 1)):
        l = bpy.data.lights.new(nom, 'SUN'); l.energy = e; l.color = col
        o = bpy.data.objects.new(nom, l); sc.collection.objects.link(o)
        o.rotation_euler = Euler(tuple(math.radians(a) for a in rot))
    # la caméra regarde le devant (Roblox -Z = Blender +Y) : lumières placées côté +Y
    lumiere('cle', 2.5, (-55, 0, 25), (1, 0.96, 0.9))
    lumiere('remplissage', 1.1, (-70, 0, -120), (0.75, 0.85, 1))
    lumiere('contre', 2.0, (60, 0, 0))
    cam = bpy.data.cameras.new('C'); cam.type = 'ORTHO'; cam.ortho_scale = ortho
    co = bpy.data.objects.new('C', cam); sc.collection.objects.link(co); sc.camera = co
    co.location = (cx, dist, cz + dist * math.tan(math.radians(8)))
    co.rotation_euler = Euler((math.radians(82), 0, math.radians(180)))


def rendre(nom_png):
    import bpy
    os.makedirs(DOSSIER_PNG, exist_ok=True)
    out = os.path.join(DOSSIER_PNG, nom_png)
    bpy.context.scene.render.filepath = out
    bpy.ops.render.render(write_still=True)
    print('ARME_PNG', out)


def apercu_trois_vues(pieces, nom_png, ecart, ortho, cz=0):
    """Face, 3/4, profil (comme EpeeFer.png)."""
    scene()
    for dx, rot in ((ecart, 0), (0, 35), (-ecart, 90)):   # x Blender inversé vu de face
        poser(pieces, (dx, 0, 0), rot)
    lumieres_et_camera(ortho, cz)
    rendre(nom_png)


def en_blender():
    return 'bpy' in sys.modules or any('blender' in a.lower() for a in sys.argv[:1])
