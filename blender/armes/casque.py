"""Casque de mineur blindé (Casque) : calotte à crête, bandeau riveté, visière courte, nasal,
couvre-joues, couvre-nuque évasé, jugulaire en cuir et support de lampe à cristal sur le front.
blender -b --factory-startup --python casque.py   (ou run_arme.ps1 casque.py)
-> src/partage/ArmuresVoxels/Casque.lua + previews/armes/Casque.png

Repère = Racine = centre de la tête R15 (tête ~1.2 stud de côté : x, y, z dans [-0.6, 0.6]).
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from armure_commun import P, sym, export_lua, apercu_trois_vues, en_blender

ID = 'Casque'
PIECES = sym([
    # calotte + dôme + crête
    P('Calotte', 'acier', (1.52, 0.32, 1.52), (0, 0.62, 0.02)),
    P('Calotte', 'acier', (1.22, 0.16, 1.24), (0, 0.86, 0.04)),
    P('Rebord', 'acierF', (1.62, 0.08, 1.62), (0, 0.46, 0.02)),
    P('Interieur', 'lanière', (1.18, 1.0, 1.18), (0, 0.04, 0)),
    P('Crete', 'acierF', (0.22, 0.12, 1.36), (0, 0.98, 0.04)),
    P('Crete', 'acierF', (0.30, 0.10, 0.20), (0, 0.97, 0.60)),
    # parois latérales et arrière (tête libre à l'intérieur)
    P('Flanc', 'acier', (0.14, 0.78, 1.36), (0.70, 0.10, 0.06)),
    P('Nuque', 'acier', (1.40, 0.78, 0.14), (0, 0.10, 0.72)),
    P('CouvreNuque', 'acierF', (1.60, 0.18, 0.34), (0, -0.33, 0.76)),
    # bandeau frontal, visière courte, nasal
    P('Bandeau', 'acier', (1.54, 0.24, 0.16), (0, 0.40, -0.70)),
    P('Visiere', 'acierF', (1.36, 0.08, 0.30), (0, 0.30, -0.88)),
    P('Nasal', 'acierF', (0.16, 0.58, 0.10), (0, 0.02, -0.80)),
    P('Nasal', 'acierF', (0.24, 0.10, 0.12), (0, -0.28, -0.80)),
    P('Doublure', 'cuir', (1.30, 0.08, 0.06), (0, 0.25, -0.65)),
    # couvre-joues articulés + jugulaire
    P('CouvreJoue', 'acier', (0.12, 0.44, 0.52), (0.71, -0.40, -0.32)),
    P('Charniere', 'cuivreF', (0.16, 0.10, 0.18), (0.72, -0.16, -0.32)),
    P('Jugulaire', 'cuir', (1.44, 0.07, 0.14), (0, -0.66, -0.30)),
    # rivets cuivre (bandeau, flancs, nuque)
    P('Rivet', 'cuivre', (0.09, 0.09, 0.06), (0.36, 0.42, -0.79)),
    P('Rivet', 'cuivre', (0.09, 0.09, 0.06), (0.62, 0.42, -0.79)),
    P('Rivet', 'cuivre', (0.06, 0.09, 0.09), (0.78, 0.30, 0.30)),
    P('Rivet', 'cuivre', (0.09, 0.09, 0.06), (0.40, 0.30, 0.80)),
    P('Patine', 'patine', (0.10, 0.08, 0.04), (-0.48, 0.66, -0.77)),
    # support de lampe : patte, boîtier cuivre, chapeau, cristal derrière deux barreaux
    P('Support', 'cuivreF', (0.30, 0.30, 0.08), (0, 0.64, -0.80)),
    P('Lampe', 'cuivre', (0.38, 0.30, 0.20), (0, 0.66, -0.93)),
    P('Lampe', 'cuivreF', (0.44, 0.07, 0.26), (0, 0.84, -0.93)),
    P('Cristal', 'cristal', (0.24, 0.20, 0.04), (0, 0.66, -1.04)),
    P('Barreau', 'cuivreF', (0.04, 0.26, 0.04), (0.06, 0.66, -1.07)),
])
LUEUR = dict(couleur=(110, 225, 255), portee=8, luminosite=1.4)

if __name__ == '__main__':
    export_lua(ID, 'Casque de mineur blindé', 'casque.py', PIECES, LUEUR)
    if en_blender():
        apercu_trois_vues(PIECES, ID + '.png', 2.35, 7.6, 0.2)
