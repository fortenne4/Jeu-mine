"""Inscription « LA GRANDE MINE » en pierres taillées lumineuses, incrustée dans la falaise au-dessus du portail.

    "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" -b --factory-startup --python blender/inscription.py

Sortie : assets/Inscription.fbx, pièces (couleurs appliquées par le jeu) :
    Inscription_Lettres_Pierre  : lettres en pierre taillée, biseautées, en relief
    Inscription_Lettres_Lueur   : cœur lumineux incrusté dans chaque lettre (néon en jeu)
    Inscription_Lettres_Gorge   : gorge sombre creusée autour des lettres (ombre portée dans la roche)
Repère L : texte centré en x, base des lettres à y = 0, face visible vers -z. Taille : capitales de 18 studs, ~140 de large.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commun import *

vider()
TEXTE = "LA GRANDE MINE"
POLICE = r"C:\Windows\Fonts\georgiab.ttf"
HAUTEUR_CAPITALES = 18.0
TEINTES = {"Pierre": (150, 140, 128), "Lueur": (255, 196, 96), "Gorge": (34, 28, 30)}


def texte_maillage(nom, extrusion, decalage, biseau, profondeur_z):
    """Texte converti en maillage. extrusion = demi-épaisseur ; decalage < 0 amincit les lettres."""
    cu = bpy.data.curves.new(nom, 'FONT')
    cu.body = TEXTE
    try:
        cu.font = bpy.data.fonts.load(POLICE)
    except Exception as e:
        print("police par défaut :", e)
    cu.align_x = 'CENTER'
    cu.size = 1.0
    cu.space_character = 1.06
    cu.extrude = extrusion
    cu.offset = decalage
    cu.bevel_depth = biseau
    cu.bevel_resolution = 1
    cu.resolution_u = 4
    ob = bpy.data.objects.new(nom, cu)
    bpy.context.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.convert(target='MESH')
    ob = bpy.context.view_layer.objects.active
    # mise à l'échelle : hauteur des capitales = HAUTEUR_CAPITALES ; texte debout, face vers -y Blender (= -z jeu)
    me = ob.data
    zs = [v.co.y for v in me.vertices]
    h = max(zs) - min(zs)
    k = HAUTEUR_CAPITALES / h
    ymin = min(zs)
    for v in me.vertices:
        x, y, z = v.co.x, v.co.y, v.co.z
        # Blender (texte à plat dans XY) -> debout : x reste, y (hauteur) -> z, z (épaisseur) -> -y
        v.co = Vector((x * k, -(z * k) + profondeur_z, (y - ymin) * k))
    me.update()
    ob.select_set(False)
    return ob


# l'épaisseur est exprimée avant mise à l'échelle (k ≈ 25) : 0.04 → ~1 stud
pierre = texte_maillage("Inscription_Lettres_Pierre", 0.045, 0.0, 0.012, 0.0)
lueur = texte_maillage("Inscription_Lettres_Lueur", 0.02, -0.018, 0.0, -1.35)     # plus fine, ressort devant
gorge = texte_maillage("Inscription_Lettres_Gorge", 0.012, 0.03, 0.0, 1.0)        # plus épaisse, derrière

for ob, t in ((pierre, "Pierre"), (lueur, "Lueur"), (gorge, "Gorge")):
    ob.data.materials.clear()
    ob.data.materials.append(materiau(t, TEINTES[t], 0.9))
    centrer_origine(ob)
    print(ob.name, triangles(ob), "triangles")

objs = [pierre, lueur, gorge]
exporter_fbx("Inscription.fbx", objs)
try:
    rendu("inscription.png", direction=(0.0, -1.0, 0.15), objets=objs, largeur=1800, hauteur=500)
except Exception as e:
    print("rendu impossible :", e)
print("FIN")
