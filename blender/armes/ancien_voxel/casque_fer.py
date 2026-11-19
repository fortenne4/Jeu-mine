"""Casque de fer (CasqueFer) : casque de chevalier-mineur en acier gris. Calotte renforcée de
bandes croisées rivetées, visière plate, large nasal évasé, couvre-joues pleins (ouverture en T),
camail de mailles sur la nuque, petite lampe de mineur en laiton décalée sur le front gauche.
blender -b --factory-startup --python casque_fer.py   (ou run_arme.ps1 casque_fer.py)
-> src/partage/ArmuresVoxels/CasqueFer.lua + previews/armes/CasqueFer.png

Repère = Racine = centre de la tête R15 (tête 1.2 stud). Couleurs fixes (pas de teinte).
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from armure_commun import P, sym, export_lua, apercu_trois_vues, en_blender

ID = 'CasqueFer'
NOM = 'Casque de fer'
PIECES = sym([
    P('Interieur', 'lanière', (1.18, 1.0, 1.18), (0, 0.04, 0)),
    # calotte étagée
    P('Calotte', 'fer', (1.50, 0.36, 1.50), (0, 0.64, 0.02)),
    P('Calotte', 'fer', (1.24, 0.18, 1.26), (0, 0.91, 0.03)),
    P('Calotte', 'fer', (0.86, 0.10, 0.90), (0, 1.04, 0.03)),
    # bandes de renfort croisées (débordent d'un cheveu)
    P('Bande', 'ferF', (0.22, 0.38, 1.56), (0, 0.65, 0.02)),
    P('Bande', 'ferF', (0.22, 0.20, 1.30), (0, 0.91, 0.03)),
    P('Bande', 'ferF', (0.22, 0.12, 0.94), (0, 1.05, 0.03)),
    P('Bande', 'ferF', (1.56, 0.38, 0.22), (0, 0.65, 0.02)),
    # bandeau, visière plate, large nasal évasé
    P('Bandeau', 'ferF', (1.58, 0.22, 0.16), (0, 0.40, -0.72)),
    P('Visiere', 'fer', (1.42, 0.08, 0.30), (0, 0.29, -0.87)),
    P('Nasal', 'ferC', (0.22, 0.58, 0.10), (0, 0.00, -0.80)),
    P('Nasal', 'ferF', (0.32, 0.12, 0.12), (0, -0.30, -0.80)),
    # parois + couvre-joues pleins (ouverture en T)
    P('Flanc', 'fer', (0.14, 0.80, 1.36), (0.70, 0.08, 0.06)),
    P('Nuque', 'fer', (1.42, 0.80, 0.14), (0, 0.08, 0.72)),
    P('CouvreJoue', 'fer', (0.14, 0.62, 0.58), (0.71, -0.38, -0.32)),
    P('CouvreJoue', 'ferC', (0.26, 0.50, 0.12), (0.59, -0.40, -0.66)),
    # camail de mailles sur la nuque
    P('Camail', 'maille', (1.48, 0.36, 0.20), (0, -0.48, 0.70)),
    P('Camail', 'maille', (0.16, 0.30, 0.50), (0.72, -0.84, 0.30)),
    # rivets
    P('Rivet', 'ferC', (0.09, 0.09, 0.06), (0.48, 0.42, -0.81)),
    P('Rivet', 'ferC', (0.06, 0.09, 0.09), (0.785, 0.24, 0.40)),
    P('Rivet', 'ferC', (0.06, 0.09, 0.09), (0.785, -0.26, -0.48)),
    P('Rivet', 'ferC', (0.09, 0.09, 0.06), (0.16, 0.66, -0.75)),
])
# petite lampe de mineur décalée à gauche du front (asymétrique : hors sym)
PIECES += [
    P('Support', 'laiton', (0.24, 0.22, 0.08), (-0.46, 0.66, -0.79)),
    P('Lampe', 'laiton', (0.28, 0.24, 0.18), (-0.46, 0.66, -0.91)),
    P('Lampe', 'ferF', (0.34, 0.06, 0.24), (-0.46, 0.81, -0.91)),
    P('Cristal', 'lampe', (0.18, 0.14, 0.04), (-0.46, 0.66, -1.01)),
    P('Barreau', 'ferF', (0.04, 0.20, 0.04), (-0.46, 0.66, -1.04)),
]
LUEUR = dict(couleur=(255, 214, 140), portee=8, luminosite=1.2)

if __name__ == '__main__':
    export_lua(ID, NOM, 'casque_fer.py', PIECES, LUEUR)
    if en_blender():
        apercu_trois_vues(PIECES, ID + '.png', 2.35, 7.6, 0.25)
