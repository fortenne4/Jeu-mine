"""Convertit les pioches voxel (pioches_brick.py) en blocs Roblox, sans import dans Studio.

Chaque pioche est reconstruite dans la grille de briques, réduite (F x F x F briques par bloc),
puis les blocs de même matière et couleur sont fusionnés en grands pavés (maillage glouton 3D).
Sortie : src/partage/PiochesVoxels/<Id>.lua (données lues par src/partage/PiochesVoxels/init.lua).

    "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" -b --factory-startup --python blender/pioches/exporte_blocs.py -- [F] [Id...]
"""
import os, sys
import numpy as np

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ICI)
import pioches_brick as PB  # noqa: E402  (n'exécute rien : __name__ != '__main__')

SORTIE = os.path.normpath(os.path.join(ICI, '..', '..', 'src', 'partage', 'PiochesVoxels'))
HAUTEUR = 5.3          # hauteur de la pioche en jeu (studs), comme la pioche en blocs
SEUIL = 0.34           # part de briques pleines pour garder un bloc
QUANT = 10 / 255       # palier de couleur (fusion des blocs voisins presque identiques)

# matière Blender -> matériau Roblox
ROBLOX = {1: 'Metal', 2: 'Metal', 3: 'Metal', 4: 'Metal', 5: 'Fabric', 6: 'Slate', 7: 'Glass', 8: 'Glass',
          9: 'Neon', 10: 'SmoothPlastic', 11: 'SmoothPlastic', 12: 'Metal', 13: 'SmoothPlastic', 14: 'SmoothPlastic',
          15: 'Wood', 16: 'Fabric', 17: 'Metal', 18: 'SmoothPlastic', 19: 'SmoothPlastic', 20: 'Neon'}
METAUX_CLAIRS = (2, 3, 12)  # acier, or, mithril : un peu de reflet


def reduire(w, F):
    """Grille F fois plus grossière : plein, matière, partie (manche/tête), couleur moyenne."""
    pad = [(0, (-n) % F) for n in PB.N]
    M = np.pad(w.mat, pad); P = np.pad(w.part, pad); C = np.pad(w.col, pad + [(0, 0)])
    n = [s // F for s in M.shape]

    def blocs(a):
        return a.reshape(n[0], F, n[1], F, n[2], F, *a.shape[3:]).swapaxes(1, 2).swapaxes(2, 4).swapaxes(3, 4) \
            .reshape(n[0], n[1], n[2], F ** 3, *a.shape[3:])
    Mb, Pb, Cb = blocs(M), blocs(P), blocs(C)
    plein = (Mb > 0).mean(-1) >= SEUIL
    mat = np.zeros(n, np.int64); part = np.zeros(n, np.int64); col = np.zeros(n + [3])
    for idx in zip(*np.nonzero(plein)):
        m = Mb[idx]; ok = m > 0
        vals, cnt = np.unique(m[ok], return_counts=True)
        # les lueurs et gemmes (petites mais importantes) l'emportent dès qu'elles sont bien présentes
        best = int(vals[np.argmax(cnt)])
        for v, c in zip(vals, cnt):
            if v in (9, 20) and c >= 0.3 * ok.sum():
                best = int(v)
        sel = m == best
        mat[idx] = best
        part[idx] = int(np.bincount(Pb[idx][ok]).argmax())
        col[idx] = Cb[idx][sel].mean(0)
    return plein, mat, part, col


def glouton(cle, visible, plein):
    """Pavés couvrant toutes les cellules visibles ; les cellules cachées (intérieures) servent de joker."""
    nx, ny, nz = cle.shape
    fait = ~visible.copy()
    joker = plein & ~visible
    boites = []

    def ok(x0, x1, y0, y1, z0, z1, k):
        c = cle[x0:x1, y0:y1, z0:z1]; j = joker[x0:x1, y0:y1, z0:z1]; v = visible[x0:x1, y0:y1, z0:z1]
        return bool(np.all(j | (v & (c == k))))
    for x in range(nx):
        for y in range(ny):
            for z in range(nz):
                if fait[x, y, z]:
                    continue
                k = cle[x, y, z]
                x1, y1, z1 = x + 1, y + 1, z + 1
                while x1 < nx and ok(x1, x1 + 1, y, y1, z, z1, k): x1 += 1
                while y1 < ny and ok(x, x1, y1, y1 + 1, z, z1, k): y1 += 1
                while z1 < nz and ok(x, x1, y, y1, z1, z1 + 1, k): z1 += 1
                fait[x:x1, y:y1, z:z1] = True
                boites.append((x, y, z, x1, y1, z1, int(k)))
    return boites


def convertir(nom, F):
    ID, fn = PB.DESIGNS[nom]
    w = PB.W(); fn(w); PB.finish(w, seed=len(ID))
    plein, mat, part, col = reduire(w, F)
    p = np.pad(plein, 1)
    cache = p[2:, 1:-1, 1:-1] & p[:-2, 1:-1, 1:-1] & p[1:-1, 2:, 1:-1] & p[1:-1, :-2, 1:-1] & p[1:-1, 1:-1, 2:] & p[1:-1, 1:-1, :-2]
    visible = plein & ~cache

    q = np.round(col / QUANT).astype(np.int64)
    code = (mat << 30) | (q[..., 0] << 20) | (q[..., 1] << 10) | q[..., 2]
    codes, cle = np.unique(np.where(plein, code, -1), return_inverse=True)
    cle = cle.reshape(plein.shape)
    boites = glouton(cle, visible, plein)

    # palette : matière Roblox + couleur moyenne réelle des cellules de cette clé
    palette, index = [], {}
    for b in boites:
        k = b[6]
        if k in index: continue
        sel = (cle == k) & plein
        m = int(mat[sel][0]); c = np.clip(col[sel].mean(0), 0, 1)
        index[k] = len(palette) + 1
        palette.append((ROBLOX[m], tuple(int(round(v * 255)) for v in c), 0.15 if m in METAUX_CLAIRS else 0))

    # repère du jeu : Y = manche (hauteur HAUTEUR, centré), pic vers -Z
    xs, ys, zs = np.nonzero(plein)
    tete = plein & (part == 1)
    tx = np.nonzero(tete)[0]
    cx = (PB.N[0] / 2) / F                            # x = 0 de la grille (axe du manche)
    sens = 1 if (tx.max() + 1 - cx) >= (cx - tx.min()) else -1   # côté du pic : +x ou -x
    y0, y1 = ys.min(), ys.max() + 1
    k = HAUTEUR / (y1 - y0)
    cz = (PB.N[2] / 2) / F
    cy = (y0 + y1) / 2

    def jeu(gx, gy, gz):
        # rotation d'un quart de tour autour de Y : le pic (+x ou -x) part vers -Z
        return ((gz - cz) * sens * k, (gy - cy) * k, -(gx - cx) * sens * k)

    lignes = []
    for (x0, y0_, z0, x1, y1_, z1, kk) in boites:
        a = jeu(x0, y0_, z0); b = jeu(x1, y1_, z1)
        pos = [(a[i] + b[i]) / 2 for i in range(3)]
        tai = [abs(b[i] - a[i]) for i in range(3)]
        lignes.append('%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%d' % (*pos, *tai, index[kk]))

    # points d'accroche des effets
    hx, hy, hz = np.nonzero(tete)
    pts = np.array([jeu(x + .5, y + .5, z + .5) for x, y, z in zip(hx, hy, hz)])
    pmn, pmx = pts.min(0), pts.max(0)
    centre = (0, (pmn[1] + pmx[1]) / 2, 0)
    pointe = (0, centre[1] - (pmx[1] - pmn[1]) * 0.15, pmn[2])
    talon = (0, pmx[1], pmx[2] * 0.3)

    def v3(t): return 'Vector3.new(%.3f, %.3f, %.3f)' % tuple(t)
    txt = ['-- Généré par blender/pioches/exporte_blocs.py (%s, %d blocs). Ne pas modifier à la main.' % (ID, len(boites)),
           'return {', '\tpointe = %s,' % v3(pointe), '\tcentre = %s,' % v3(centre), '\ttalon = %s,' % v3(talon), '\tpalette = {']
    for mname, c, refl in palette:
        txt.append('\t\t{"%s", %d, %d, %d, %g},' % (mname, *c, refl))
    txt.append('\t},')
    txt.append('\t-- x, y, z, largeur, hauteur, profondeur, couleur (indice dans la palette)')
    txt.append('\tblocs = {')
    for i in range(0, len(lignes), 4):
        txt.append('\t\t' + ', '.join(lignes[i:i + 4]) + ',')
    txt.append('\t},')
    txt.append('}')
    os.makedirs(SORTIE, exist_ok=True)
    with open(os.path.join(SORTIE, nom + '.lua'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(txt) + '\n')
    print('BLOCS', nom, 'F', F, 'cellules', int(plein.sum()), 'visibles', int(visible.sum()), 'blocs', len(boites), 'couleurs', len(palette))


if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    F = next((int(a) for a in argv if a.isdigit()), 4)
    noms = [a for a in argv if a in PB.DESIGNS] or list(PB.DESIGNS)
    for nom in noms:
        convertir(nom, F)
