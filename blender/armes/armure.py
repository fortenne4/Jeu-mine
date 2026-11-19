"""Aperçu de l'armure complète portée sur un R15 en blocs gris (previews/armes/Armure.png).
Exporte aussi les 3 modules Luau. blender -b --factory-startup --python armure.py
Vues : face (acier), 3/4 (acier), 3/4 avec une teinte d'alliage (montre la règle Teinte).
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import armure_commun as A
import casque, plastron, jambieres

# positions des Racines dans le repère du centre de l'UpperTorso (R15 standard)
PORT = [(casque.PIECES, (0, 1.45, 0)), (plastron.PIECES, (0, 0, 0)), (jambieres.PIECES, (0, -2.2, 0))]

if __name__ == '__main__':
    A.export_lua(casque.ID, 'Casque de mineur blindé', 'casque.py', casque.PIECES, casque.LUEUR)
    A.export_lua(plastron.ID, 'Cuirasse du mineur-guerrier', 'plastron.py', plastron.PIECES, plastron.LUEUR)
    A.export_lua(jambieres.ID, 'Jambières du mineur-guerrier', 'jambieres.py', jambieres.PIECES, None, jambieres.CENTRES)
    if A.en_blender():
        A.scene((1600, 1100))
        for dx, rot, teinte in ((4.6, 0, None), (0, 35, None), (-4.6, 35, (214, 168, 72))):
            A.mannequin((dx, 0, 0), rot)
            for pieces, decal in PORT:
                A.poser(pieces, (dx, 0, 0), rot, teinte, decal)
        A.lumieres_et_camera(10.5 * 1.3, -0.5)
        A.rendre('Armure.png')
