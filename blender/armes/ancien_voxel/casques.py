"""Aperçu comparatif des 3 casques par matériau portés sur une tête R15 grise (previews/armes/Casques.png).
Exporte aussi les 3 modules Luau. blender -b --factory-startup --python casques.py
Rangée du haut : 3/4 ; rangée du bas : face.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import armure_commun as A
import casque_charbon, casque_bronze, casque_fer

CASQUES = [casque_charbon, casque_bronze, casque_fer]
SCRIPTS = ['casque_charbon.py', 'casque_bronze.py', 'casque_fer.py']
A.COUL['_tete'] = ('Plastic', (120, 120, 128), 0, None)
A.COUL['_yeux'] = ('Plastic', (30, 30, 34), 0, None)
TETE = [A.P('Tete', '_tete', (1.2, 1.2, 1.2), (0, 0, 0)),
        A.P('Cou', '_tete', (0.6, 0.3, 0.6), (0, -0.75, 0)),
        A.P('Torse', '_tete', (2.0, 0.6, 1.0), (0, -1.2, 0)),
        A.P('Oeil', '_yeux', (0.14, 0.18, 0.02), (0.22, 0.08, -0.605)),
        A.P('Oeil', '_yeux', (0.14, 0.18, 0.02), (-0.22, 0.08, -0.605)),
        A.P('Bouche', '_yeux', (0.36, 0.05, 0.02), (0, -0.25, -0.605))]

if __name__ == '__main__':
    for m, s in zip(CASQUES, SCRIPTS):
        A.export_lua(m.ID, m.NOM, s, m.PIECES, m.LUEUR)
    if A.en_blender():
        A.scene((1500, 1100))
        for rangee, (z, rot) in enumerate(((1.6, 30), (-1.9, 0))):
            for i, m in enumerate(CASQUES):
                dx = (1 - i) * 2.7          # x Blender inversé vu de face : charbon à gauche
                A.poser(TETE, (dx, 0, z), rot)
                A.poser(m.PIECES, (dx, 0, z), rot)
        A.lumieres_et_camera(8.6, 0)
        A.rendre('Casques.png')
