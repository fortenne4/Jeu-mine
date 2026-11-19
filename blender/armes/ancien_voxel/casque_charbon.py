"""Casque de charbon (CasqueCharbon) : casque primitif taillé dans la roche noire.
Blocs anthracite irréguliers (légèrement tournés, asymétriques), deux moignons de corne rocheuse,
veines de braise orange (Neon fin) + un coeur de braise serti au front, jugulaire en corde.
blender -b --factory-startup --python casque_charbon.py   (ou run_arme.ps1 casque_charbon.py)
-> src/partage/ArmuresVoxels/CasqueCharbon.lua + previews/armes/CasqueCharbon.png

Repère = Racine = centre de la tête R15 (tête 1.2 stud : x, y, z dans [-0.6, 0.6]). Couleurs fixes (pas de teinte).
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from armure_commun import P, sym, export_lua, apercu_trois_vues, en_blender

ID = 'CasqueCharbon'
NOM = 'Casque de charbon'
PIECES = [
    P('Interieur', 'lanière', (1.18, 1.0, 1.18), (0, 0.04, 0)),
    # calotte : gros bloc + éboulis irréguliers au sommet
    P('Calotte', 'charbon', (1.52, 0.36, 1.48), (0, 0.64, 0.02)),
    P('Calotte', 'charbonC', (1.02, 0.22, 0.96), (-0.08, 0.92, 0.06), 7),
    P('Calotte', 'charbon', (0.56, 0.18, 0.54), (0.22, 1.08, -0.04), -14),
    P('Calotte', 'charbonF', (0.40, 0.14, 0.42), (-0.30, 1.06, 0.26), 11),
    # moignons de corne rocheuse (asymétriques)
    P('Corne', 'charbonF', (0.26, 0.30, 0.26), (0.56, 0.98, 0.10), 18),
    P('Corne', 'charbon', (0.16, 0.20, 0.16), (0.60, 1.22, 0.12), 30),
    P('Corne', 'charbonF', (0.24, 0.24, 0.24), (-0.58, 0.94, 0.04), -12),
    P('Corne', 'charbonC', (0.14, 0.16, 0.14), (-0.62, 1.12, 0.04), -25),
    # front : arcade lourde (bord vers les sourcils) + éclat saillant
    P('Front', 'charbonF', (1.58, 0.26, 0.20), (0, 0.40, -0.72)),
    P('Eclat', 'charbon', (0.44, 0.32, 0.24), (-0.50, 0.44, -0.78), 8),
    P('Eclat', 'charbonC', (0.30, 0.20, 0.20), (0.48, 0.36, -0.78), -6),
    # flancs inégaux, nuque, éclats bas
    P('Flanc', 'charbon', (0.20, 0.80, 1.30), (-0.72, 0.14, 0.05)),
    P('Flanc', 'charbonC', (0.18, 0.64, 1.22), (0.71, 0.20, 0.02), 3),
    P('Nuque', 'charbon', (1.42, 0.80, 0.18), (0, 0.12, 0.72)),
    P('Eclat', 'charbonF', (0.62, 0.26, 0.22), (0.30, -0.34, 0.74), -5),
    P('Eclat', 'charbonF', (0.24, 0.34, 0.40), (-0.74, -0.38, 0.30), 4),
    # veines de braise (fines, à fleur des blocs) + fond rougeoyant autour du coeur
    P('Braise', 'braise', (0.42, 0.04, 0.03), (0.16, 0.46, -0.83)),
    P('Braise', 'braise', (0.30, 0.04, 0.03), (-0.20, 0.72, -0.755)),
    P('Braise', 'braise', (0.03, 0.40, 0.05), (-0.83, 0.18, -0.30)),
    P('Braise', 'braise', (0.03, 0.04, 0.46), (0.81, 0.40, 0.18)),
    P('Braise', 'braise', (0.04, 0.03, 0.40), (0.06, 0.84, 0.05), 7),
    P('Braise', 'braise', (0.40, 0.04, 0.03), (-0.10, 0.20, 0.82)),
    P('Socle', 'braiseF', (0.24, 0.20, 0.04), (0.02, 0.62, -0.75)),
    P('Coeur', 'braise', (0.14, 0.12, 0.04), (0.02, 0.62, -0.77)),
    P('Sertissure', 'charbonF', (0.30, 0.06, 0.08), (0.02, 0.74, -0.76)),
    # jugulaire en corde nouée
    P('Jugulaire', 'corde', (1.46, 0.07, 0.14), (0, -0.62, -0.22)),
    P('Noeud', 'corde', (0.16, 0.16, 0.18), (0.74, -0.56, -0.22)),
]
LUEUR = dict(couleur=(255, 120, 40), portee=6, luminosite=0.8, piece='Coeur')

if __name__ == '__main__':
    export_lua(ID, NOM, 'casque_charbon.py', PIECES, LUEUR)
    if en_blender():
        apercu_trois_vues(PIECES, ID + '.png', 2.35, 7.6, 0.25)
