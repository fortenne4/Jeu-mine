"""Jambières du mineur-guerrier (Jambieres) : paire de grèves + cuissards, genouillères à bossette,
plaques extérieures, sangles de cuir à boucle cuivre, revers de cheville, rivets.
blender -b --factory-startup --python jambieres.py   (ou run_arme.ps1 jambieres.py)
-> src/partage/ArmuresVoxels/Jambieres.lua + previews/armes/Jambieres.png

Repère = Racine = centre de la paire, entre les deux jambes (hanche y = +1, cheville y = -1).
Jambes R15 (1 x 2 x 1) : JambeG centrée en x = -0.5 (gauche du perso), JambeD en x = +0.5.
Genou à y = 0 (jonction UpperLeg / LowerLeg).
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from armure_commun import P, export_lua, apercu_trois_vues, en_blender

ID = 'Jambieres'
CENTRES = {'JambeG': (-0.5, 0, 0), 'JambeD': (0.5, 0, 0)}

# Une jambe en repère local : x > 0 = côté extérieur.
JAMBE = [
    ('Interieur', 'lanière', (0.96, 1.90, 0.96), (0, 0, 0)),
    # grève (tibia) + cuissard (cuisse)
    ('Greve', 'acier', (0.92, 0.88, 0.14), (0, -0.48, -0.58)),
    ('Greve', 'acierF', (0.16, 0.70, 0.06), (0, -0.46, -0.67)),
    ('Cuissard', 'acier', (0.94, 0.72, 0.14), (0, 0.54, -0.58)),
    ('Cuissard', 'acierF', (1.00, 0.12, 0.20), (0, 0.94, -0.58)),
    # genouillère à bossette
    ('Genouillere', 'acierF', (0.74, 0.40, 0.20), (0, 0.04, -0.66)),
    ('Genouillere', 'acier', (0.40, 0.24, 0.10), (0, 0.04, -0.80)),
    ('Genouillere', 'acierF', (0.18, 0.30, 0.56), (0.55, 0.04, -0.30)),
    # plaque extérieure + revers de cheville
    ('Plaque', 'acier', (0.12, 0.86, 0.86), (0.56, -0.48, 0.02)),
    ('Cheville', 'acierF', (1.04, 0.16, 1.14), (0.04, -0.94, 0)),
    # sangles de cuir (tibia et cuisse) + boucles
    ('Sangle', 'cuir', (1.04, 0.12, 1.10), (0.02, -0.66, 0.02)),
    ('Sangle', 'cuir', (1.02, 0.12, 1.10), (0.01, 0.42, 0.02)),
    ('Boucle', 'cuivre', (0.06, 0.18, 0.18), (0.63, -0.66, 0.10)),
    ('Boucle', 'cuivre', (0.06, 0.18, 0.18), (0.56, 0.42, 0.10)),
    # rivets
    ('Rivet', 'cuivre', (0.09, 0.09, 0.06), (0.30, -0.18, -0.66)),
    ('Rivet', 'cuivre', (0.09, 0.09, 0.06), (-0.30, -0.18, -0.66)),
    ('Rivet', 'cuivre', (0.09, 0.09, 0.06), (0.32, 0.74, -0.66)),
]


def construire():
    pieces = []
    for g, (cx, cy, cz) in CENTRES.items():
        s = -1 if g == 'JambeG' else 1
        for nom, k, t, p in JAMBE:
            pieces.append(P(nom, k, t, (cx + s * p[0], cy + p[1], cz + p[2]), 0, g))
    # une tache de patine, seulement à gauche (asymétrie d'usure)
    pieces.append(P('Patine', 'patine', (0.10, 0.08, 0.04), (-0.66, -0.70, -0.66), 0, 'JambeG'))
    return pieces


PIECES = construire()

if __name__ == '__main__':
    export_lua(ID, 'Jambières du mineur-guerrier', 'jambieres.py', PIECES, None, CENTRES)
    if en_blender():
        apercu_trois_vues(PIECES, ID + '.png', 3.0, 9.6, 0.0)
