"""Planche de comparaison maquette / rendu des 12 épées de minerais -> previews/armes/epees_minerais/comparaison.png"""
import os
from PIL import Image
ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.abspath(os.path.join(ICI, '..', '..'))
D = os.path.join(JEU, 'previews', 'armes', 'epees_minerais')
IDS = ['Quartz', 'Soufre', 'Argent', 'Obsidienne', 'Givrite', 'Emeraude', 'Rubis', 'Lunarite',
       'Magmaite', 'Diamant', 'Orichalque', 'Neantite']
im = Image.open(os.path.join(JEU, 'previews', 'minerais', 'maquette-casques-epees.png')).convert('RGB')
cols = [240, 620, 1000, 1380]
rows = [125, 405, 685]
W, H = 260, 500
out = Image.new('RGB', (4 * 2 * W, 3 * H), (20, 20, 24))
for k, n in enumerate(IDS):
    r, c = divmod(k, 4)
    ref = im.crop((cols[c], rows[r], cols[c] + 130, rows[r] + 250)).resize((W, H), Image.LANCZOS)
    ren = Image.open(os.path.join(D, 'Epee%s.png' % n)).convert('RGB').resize((W, H), Image.LANCZOS)
    out.paste(ref, (c * 2 * W, r * H))
    out.paste(ren, (c * 2 * W + W, r * H))
out.save(os.path.join(D, 'comparaison.png'))
print('ok')
