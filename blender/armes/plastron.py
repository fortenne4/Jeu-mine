"""Cuirasse du mineur-guerrier (Plastron) : plaque de poitrine bombée, arête centrale, deux lames de
ventre, dossière, flancs, épaulières à deux étages, col, ceinture et bretelles en cuir, rivets
cuivre et petit cristal serti au centre du torse.
blender -b --factory-startup --python plastron.py   (ou run_arme.ps1 plastron.py)
-> src/partage/ArmuresVoxels/Plastron.lua + previews/armes/Plastron.png

Repère = Racine = centre de l'UpperTorso R15 (2 x 1.6 x 1 : x [-1, 1], y [-0.8, 0.8], z [-0.5, 0.5]).
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from armure_commun import P, sym, export_lua, apercu_trois_vues, en_blender

ID = 'Plastron'
PIECES = sym([
    # devant : plaque, poitrine bombée, arête, lames de ventre
    P('Plaque', 'acier', (1.92, 1.30, 0.14), (0, 0.02, -0.58)),
    P('Poitrine', 'acier', (2.04, 0.46, 0.18), (0, 0.50, -0.62)),
    P('Arete', 'acierF', (0.18, 1.04, 0.08), (0, 0.06, -0.68)),
    P('Lame', 'acierF', (1.98, 0.20, 0.18), (0, -0.56, -0.62)),
    P('Lame', 'acier', (2.06, 0.18, 0.20), (0, -0.74, -0.62)),
    P('Interieur', 'lanière', (1.96, 1.56, 0.98), (0, 0, 0)),
    # dos et flancs
    P('Dossiere', 'acier', (1.92, 1.40, 0.14), (0, 0.02, 0.58)),
    P('Dossiere', 'acierF', (1.30, 0.20, 0.08), (0, 0.40, 0.68)),
    P('Flanc', 'acier', (0.14, 1.22, 1.30), (1.04, -0.04, 0)),
    # épaulières (deux étages) et col
    P('Epauliere', 'acier', (0.74, 0.24, 1.36), (0.92, 0.86, 0)),
    P('Epauliere', 'acierF', (0.30, 0.34, 1.30), (1.20, 0.66, 0)),
    P('Col', 'acierF', (0.86, 0.18, 0.18), (0, 0.84, -0.52)),
    P('Col', 'acierF', (0.86, 0.18, 0.18), (0, 0.84, 0.52)),
    # cuir : bretelles sur les épaules, ceinture, boucle
    P('Bretelle', 'cuir', (0.18, 0.06, 1.24), (0.42, 0.82, 0)),
    P('Ceinture', 'cuir', (2.12, 0.16, 1.40), (0, -0.36, 0)),
    P('Boucle', 'cuivre', (0.28, 0.24, 0.06), (0, -0.36, -0.72)),
    P('Boucle', 'lanière', (0.12, 0.10, 0.04), (0, -0.36, -0.76)),
    # rivets cuivre
    P('Rivet', 'cuivre', (0.09, 0.09, 0.06), (0.86, 0.52, -0.72)),
    P('Rivet', 'cuivre', (0.09, 0.09, 0.06), (0.50, -0.56, -0.72)),
    P('Rivet', 'cuivre', (0.09, 0.06, 0.09), (0.92, 0.99, -0.46)),
    P('Rivet', 'cuivre', (0.09, 0.06, 0.09), (0.92, 0.99, 0.46)),
    P('Patine', 'patine', (0.12, 0.08, 0.04), (-0.60, 0.20, -0.66)),
    # cristal serti (monture cuivre + griffes)
    P('Monture', 'cuivreF', (0.40, 0.40, 0.06), (0, 0.50, -0.73)),
    P('Cristal', 'cristal', (0.20, 0.22, 0.06), (0, 0.50, -0.76)),
    P('Griffe', 'cuivre', (0.06, 0.12, 0.06), (0.13, 0.50, -0.78)),
])
LUEUR = dict(couleur=(110, 225, 255), portee=4, luminosite=0.8)

if __name__ == '__main__':
    export_lua(ID, 'Cuirasse du mineur-guerrier', 'plastron.py', PIECES, LUEUR)
    if en_blender():
        apercu_trois_vues(PIECES, ID + '.png', 3.3, 10.4, 0.1)
