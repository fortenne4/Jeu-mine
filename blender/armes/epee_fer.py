"""Épée de fer du mineur (EpeeFer) : modèle voxel en quelques Parts.
blender -b --factory-startup --python epee_fer.py            -> src/partage/ArmesVoxels/EpeeFer.lua + previews/armes/EpeeFer.png
(lancer de préférence via run_arme.ps1 epee_fer.py)

Repère = repère local de la Part "Poignee" (Roblox) : origine = centre de la prise en main,
lame vers +Y, plat de la lame face à -Z (devant). Unités = studs.
"""
import math, os, sys

ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.abspath(os.path.join(ICI, '..', '..'))
ID = 'EpeeFer'

# --- palette : nom -> (matériau Roblox, (r, g, b), reflectance) ---
COUL = {
    'acier':    ('Metal', (176, 184, 194), 0.15),   # corps de lame
    'fil':      ('Metal', (214, 220, 228), 0.2),    # tranchants clairs
    'gorge':    ('Metal', (104, 110, 120), 0),      # gouttière centrale
    'usure':    ('Metal', (120, 92, 70), 0),        # tache de rouille
    'talon':    ('Metal', (84, 88, 98), 0),         # ricasso sombre
    'cuivre':   ('Metal', (196, 114, 62), 0.1),
    'cuivreF':  ('Metal', (138, 74, 40), 0),
    'patine':   ('Metal', (82, 158, 136), 0),       # vert-de-gris
    'cuir':     ('Fabric', (96, 60, 34), 0),
    'lanière':  ('Fabric', (58, 36, 21), 0),
    'cristal':  ('Neon', (110, 225, 255), 0),
}

# --- pièces : (nom, couleur, taille (x, y, z), position (x, y, z), rotation Y en degrés) ---
# Total : pommeau y = -0.84 -> pointe y = 3.20 (~4 studs).
L0, L1 = 0.62, 2.70            # corps de lame (bas / haut avant la pointe)
PIECES = [
    # poignée (PrimaryPart) + 3 lanières de cuir
    ('Poignee', 'cuir', (0.30, 0.80, 0.30), (0, 0, 0), 0),
    ('Laniere', 'lanière', (0.34, 0.10, 0.34), (0, -0.26, 0), 0),
    ('Laniere', 'lanière', (0.34, 0.10, 0.34), (0, 0.02, 0), 0),
    ('Laniere', 'lanière', (0.34, 0.10, 0.34), (0, 0.28, 0), 0),
    # garde en cuivre : barre, cœur, embouts tombants, points de vert-de-gris
    ('Garde', 'cuivre', (1.36, 0.20, 0.36), (0, 0.50, 0), 0),
    ('Garde', 'cuivreF', (0.46, 0.32, 0.46), (0, 0.50, 0), 0),
    ('Garde', 'cuivreF', (0.20, 0.34, 0.42), (-0.74, 0.46, 0), 0),
    ('Garde', 'cuivreF', (0.20, 0.34, 0.42), (0.74, 0.46, 0), 0),
    ('Patine', 'patine', (0.12, 0.10, 0.04), (-0.42, 0.54, -0.18), 0),
    ('Patine', 'patine', (0.10, 0.08, 0.04), (0.50, 0.46, 0.18), 0),
    ('Rivet', 'cuivre', (0.12, 0.12, 0.50), (0, 0.50, 0), 0),
    # talon de lame (ricasso)
    ('Talon', 'talon', (0.50, 0.18, 0.18), (0, L0 + 0.09, 0), 0),
    # lame : corps (Lame), gouttière, tranchants ébréchés (2 segments par côté), pointe en 3 marches
    ('Lame', 'acier', (0.50, L1 - L0, 0.14), (0, (L0 + L1) / 2, 0), 0),
    ('Gorge', 'gorge', (0.12, 1.70, 0.16), (0, L0 + 0.20 + 0.85, 0), 0),
    ('Tranchant', 'fil', (0.08, 0.66, 0.10), (-0.29, L0 + 0.33, 0), 0),         # encoche à y ~ 1.28..1.40
    ('Tranchant', 'fil', (0.08, L1 - 1.40, 0.10), (-0.29, (1.40 + L1) / 2, 0), 0),
    ('Tranchant', 'fil', (0.08, 1.40, 0.10), (0.29, L0 + 0.70, 0), 0),          # encoche à y ~ 2.02..2.12
    ('Tranchant', 'fil', (0.08, L1 - 2.12, 0.10), (0.29, (2.12 + L1) / 2, 0), 0),
    ('Rouille', 'usure', (0.12, 0.16, 0.15), (0.14, 1.02, 0), 0),
    ('Pointe', 'acier', (0.46, 0.24, 0.12), (0, L1 + 0.12, 0), 0),
    ('Pointe', 'fil', (0.28, 0.18, 0.10), (0, L1 + 0.24 + 0.09, 0), 0),
    ('Pointe', 'fil', (0.12, 0.08, 0.08), (0, L1 + 0.42 + 0.04, 0), 0),
    # pommeau : bague en cuivre, coupelle, griffes, cristal lumineux tourné de 45°
    ('Pommeau', 'cuivreF', (0.40, 0.14, 0.40), (0, -0.47, 0), 0),
    ('Pommeau', 'cuivre', (0.30, 0.10, 0.30), (0, -0.58, 0), 0),
    ('Griffe', 'cuivre', (0.07, 0.18, 0.07), (-0.16, -0.66, 0), 0),
    ('Griffe', 'cuivre', (0.07, 0.18, 0.07), (0.16, -0.66, 0), 0),
    ('Cristal', 'cristal', (0.20, 0.22, 0.20), (0, -0.72, 0), 45),
    ('Cristal', 'cristal', (0.12, 0.08, 0.12), (0, -0.865, 0), 45),
]
TRAIL_A = (0, L0 + 0.10, 0)     # base de la lame, juste au-dessus de la garde
TRAIL_B = (0, L1 + 0.50, 0)     # pointe
LUEUR = dict(couleur=COUL['cristal'][1], portee=5, luminosite=1.2)


# ---------------------------------------------------------------- export Luau
def f3(v):
    return 'Vector3.new(%s)' % ', '.join(('%.3f' % c).rstrip('0').rstrip('.') if c else '0' for c in v)


def export_lua():
    noms = list(COUL)
    lignes = ['-- Généré par blender/armes/epee_fer.py (%s, %d pièces). Ne pas modifier à la main.' % (ID, len(PIECES)),
              '-- Repère = Poignee : origine au centre de la prise, lame vers +Y, unités = studs.',
              'return {',
              '\tNom = "Épée de fer du mineur",',
              '\tCouleurs = {']
    for k in noms:
        m, c, r = COUL[k]
        lignes.append('\t\t["%s"] = {"%s", %d, %d, %d, %g},' % (k, m, *c, r))
    lignes.append('\t},')
    lignes.append('\t-- nom, couleur, taille, position (dans le repère de Poignee), rotation Y (degrés)')
    lignes.append('\tPieces = {')
    for nom, k, s, p, ry in PIECES:
        lignes.append('\t\t{"%s", "%s", %s, %s, %g},' % (nom, k, f3(s), f3(p), ry))
    lignes.append('\t},')
    lignes.append('\tTrailA = %s,' % f3(TRAIL_A))
    lignes.append('\tTrailB = %s,' % f3(TRAIL_B))
    lignes.append('\tLueur = {Couleur = Color3.fromRGB(%d, %d, %d), Portee = %g, Luminosite = %g},'
                  % (*LUEUR['couleur'], LUEUR['portee'], LUEUR['luminosite']))
    lignes.append('}')
    dest = os.path.join(JEU, 'src', 'partage', 'ArmesVoxels', ID + '.lua')
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    open(dest, 'w', encoding='utf8', newline='\n').write('\n'.join(lignes) + '\n')
    ys = [p[1] - s[1] / 2 for _, _, s, p, _ in PIECES] + [p[1] + s[1] / 2 for _, _, s, p, _ in PIECES]
    xs = [abs(p[0]) + s[0] / 2 for _, _, s, p, _ in PIECES]
    print('ARME_LUA', dest, len(PIECES), 'pieces', 'longueur=%.2f' % (max(ys) - min(ys)), 'largeur=%.2f' % (2 * max(xs)))


# ---------------------------------------------------------------- rendu Blender
def rendu():
    import bpy
    from mathutils import Vector, Euler
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    for eng in ('BLENDER_EEVEE', 'BLENDER_EEVEE_NEXT'):
        try:
            sc.render.engine = eng
            break
        except TypeError:
            pass
    sc.view_settings.view_transform = 'Standard'
    sc.render.resolution_x, sc.render.resolution_y = 1300, 1100
    sc.render.film_transparent = False
    w = bpy.data.worlds.new('W'); sc.world = w
    w.use_nodes = True
    w.node_tree.nodes['Background'].inputs[0].default_value = (0.035, 0.032, 0.04, 1)
    w.node_tree.nodes['Background'].inputs[1].default_value = 1.0

    mats = {}
    for k, (m, c, r) in COUL.items():
        mat = bpy.data.materials.new(k); mat.use_nodes = True
        b = mat.node_tree.nodes['Principled BSDF']
        rgb = tuple((v / 255) ** 2.2 for v in c) + (1,)
        b.inputs['Base Color'].default_value = rgb
        b.inputs['Roughness'].default_value = 0.45 if m == 'Metal' else 0.8
        b.inputs['Metallic'].default_value = 0.55 if m == 'Metal' else 0
        if m == 'Neon':
            b.inputs['Emission Color'].default_value = rgb
            b.inputs['Emission Strength'].default_value = 2.5
        mats[k] = mat

    def r2b(v):  # Roblox (x, y, z) -> Blender (x, -z, y)
        return Vector((v[0], -v[2], v[1]))

    # trois exemplaires : de face, 3/4, profil
    for i, (dx, rot) in enumerate(((-2.0, 0), (0, -40), (2.0, -90))):
        piv = bpy.data.objects.new('Epee%d' % i, None); sc.collection.objects.link(piv)
        piv.location = (dx, 0, 0); piv.rotation_euler = Euler((0, 0, math.radians(rot)))
        for nom, k, s, p, ry in PIECES:
            bpy.ops.mesh.primitive_cube_add(size=1)
            o = bpy.context.object
            o.scale = (s[0], s[2], s[1])
            o.location = r2b(p)
            o.rotation_euler = Euler((0, 0, math.radians(ry)))
            o.data.materials.append(mats[k])
            o.parent = piv
        lp = bpy.data.lights.new('L%d' % i, 'POINT'); lp.color = tuple(c / 255 for c in LUEUR['couleur'])
        lp.energy = 25; lp.shadow_soft_size = 0.1
        lo = bpy.data.objects.new('L%d' % i, lp); sc.collection.objects.link(lo); lo.parent = piv
        lo.location = r2b((0, -0.72, -0.25))

    def lumiere(nom, typ, e, rot, col=(1, 1, 1)):
        l = bpy.data.lights.new(nom, typ); l.energy = e; l.color = col
        o = bpy.data.objects.new(nom, l); sc.collection.objects.link(o)
        o.rotation_euler = Euler(tuple(math.radians(a) for a in rot))
    lumiere('cle', 'SUN', 3.2, (55, 0, -25), (1, 0.96, 0.9))
    lumiere('remplissage', 'SUN', 1.1, (70, 0, 120), (0.75, 0.85, 1))
    lumiere('contre', 'SUN', 2.0, (-60, 0, 180))

    cam = bpy.data.cameras.new('C'); cam.type = 'ORTHO'; cam.ortho_scale = 6.4
    co = bpy.data.objects.new('C', cam); sc.collection.objects.link(co); sc.camera = co
    co.location = (0, -12, 1.18 + 1.0); co.rotation_euler = Euler((math.radians(85), 0, 0))
    co.location.z = 1.18 + 12 * math.tan(math.radians(5))

    out = os.path.join(JEU, 'previews', 'armes', ID + '.png')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sc.render.filepath = out
    bpy.ops.render.render(write_still=True)
    print('ARME_PNG', out)


if __name__ == '__main__':
    export_lua()
    if 'bpy' in sys.modules or any('blender' in a.lower() for a in sys.argv[:1]):
        rendu()
