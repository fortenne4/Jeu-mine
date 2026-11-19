"""Casque de bronze (CasqueBronze) : casque à cimier en crin rouge, calotte en dôme étagé,
arcades sourcilières gravées, couvre-joues effilés, rosaces aux tempes, rivets dorés,
bandeau gravé et taches de patine vert-de-gris.
blender -b --factory-startup --python casque_bronze.py   (ou run_arme.ps1 casque_bronze.py)
-> src/partage/ArmuresVoxels/CasqueBronze.lua + previews/armes/CasqueBronze.png

Repère = Racine = centre de la tête R15 (tête 1.2 stud). Couleurs fixes (pas de teinte).
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from armure_commun import P, sym, export_lua, apercu_trois_vues, en_blender

ID = 'CasqueBronze'
NOM = 'Casque de bronze'
PIECES = sym([
    P('Interieur', 'lanière', (1.18, 1.0, 1.18), (0, 0.04, 0)),
    # calotte en dôme étagé
    P('Calotte', 'bronze', (1.48, 0.30, 1.50), (0, 0.62, 0.02)),
    P('Calotte', 'bronze', (1.20, 0.16, 1.24), (0, 0.85, 0.03)),
    P('Calotte', 'bronze', (0.82, 0.08, 0.90), (0, 0.97, 0.03)),
    # cimier : support + crin rouge en arc (avant bas, sommet, retombée arrière)
    P('Support', 'bronzeF', (0.18, 0.12, 1.04), (0, 1.06, 0.05)),
    P('Cimier', 'crin', (0.20, 0.30, 0.36), (0, 1.24, -0.40)),
    P('Cimier', 'crin', (0.22, 0.40, 0.52), (0, 1.36, 0.02)),
    P('Cimier', 'crinF', (0.20, 0.30, 0.36), (0, 1.26, 0.42)),
    P('Cimier', 'crinF', (0.16, 0.54, 0.16), (0, 0.98, 0.66)),
    # bandeau gravé + arcades sourcilières en V
    P('Bandeau', 'bronzeF', (1.52, 0.20, 0.14), (0, 0.44, -0.70)),
    P('Gravure', 'bronzeC', (0.34, 0.04, 0.02), (0.38, 0.47, -0.775)),
    P('Arcade', 'bronze', (0.52, 0.10, 0.12), (0.30, 0.30, -0.76), -10),
    P('Nasal', 'bronzeC', (0.12, 0.30, 0.08), (0, 0.20, -0.78)),
    # parois, couvre-nuque évasé
    P('Flanc', 'bronze', (0.12, 0.72, 1.00), (0.70, 0.14, 0.22)),
    P('Nuque', 'bronze', (1.40, 0.78, 0.12), (0, 0.10, 0.72)),
    P('CouvreNuque', 'bronzeF', (1.56, 0.12, 0.30), (0, -0.30, 0.78)),
    # couvre-joues effilés vers l'avant
    P('CouvreJoue', 'bronze', (0.12, 0.62, 0.56), (0.71, -0.14, -0.32)),
    P('CouvreJoue', 'bronzeC', (0.12, 0.22, 0.20), (0.66, -0.52, -0.56), -12),
    # rosaces aux tempes (croix de deux boîtes = disque)
    P('Rosace', 'bronzeC', (0.06, 0.24, 0.14), (0.79, 0.42, -0.26)),
    P('Rosace', 'bronzeF', (0.05, 0.14, 0.24), (0.785, 0.42, -0.26)),
    # rivets dorés
    P('Rivet', 'laiton', (0.08, 0.08, 0.05), (0.66, 0.44, -0.785)),
    P('Rivet', 'laiton', (0.05, 0.08, 0.08), (0.775, 0.18, 0.46)),
    P('CouvreJoue', 'bronze', (0.22, 0.46, 0.10), (0.60, -0.16, -0.63)),
    # patine vert-de-gris (asymétrique)
    P('Patine', 'patine', (0.22, 0.05, 0.30), (-0.38, 0.995, 0.24)),
    P('Patine', 'patine', (0.04, 0.16, 0.22), (-0.765, -0.02, 0.40)),
    P('Patine', 'patine', (0.30, 0.10, 0.03), (0.20, -0.20, 0.785)),
])
LUEUR = None

if __name__ == '__main__':
    export_lua(ID, NOM, 'casque_bronze.py', PIECES, LUEUR)
    if en_blender():
        apercu_trois_vues(PIECES, ID + '.png', 2.35, 7.6, 0.3)
