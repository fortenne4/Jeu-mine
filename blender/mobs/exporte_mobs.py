"""Exporte les mobs voxel vers le jeu + les aperçus.
py exporte_mobs.py
  out/<Name>/<Name>Data.luau + <Name>Clips.luau  ->  src/partage/MobsVoxels/<Name>.lua  (un module par mob, Data + Anim)
  out/<Name>/sheet.png + loop.gif                ->  previews/mobs/<Name>.png / <Name>_anim.gif
  + previews/mobs/Gamme.png (4 premiers) et Gamme2.png (tous) : les mobs de face à la même échelle, à côté d'un perso R15 (~5 studs).
"""
import ast, json, os, re, shutil
from PIL import Image, ImageFilter, ImageChops, ImageDraw

ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.abspath(os.path.join(ICI, '..', '..'))
DEST = os.path.join(JEU, 'src', 'partage', 'MobsVoxels')
APERCUS = os.path.join(JEU, 'previews', 'mobs')
# nom -> (fichier source, ortho, cible z du rendu) ; doit suivre PREVIEW de chaque fichier
MOBS = {'MineurZombie': ('mineur_zombie.py', 7.0, 2.75), 'BruteProfondeurs': ('brute_profondeurs.py', 12.5, 5.0),
        'RampantGaleries': ('rampant_galeries.py', 9.5, 1.4), 'ChauveSourisCave': ('chauve_souris_cave.py', 8.5, 3.4),
        'ZombieLame': ('zombie_lame.py', 8.5, 3.0), 'ZombieMutant': ('zombie_mutant.py', 9.0, 3.2),
        'ExecuteurMaudit': ('executeur_maudit.py', 8.5, 3.1)}


def module(nom):
    o = os.path.join(ICI, 'out', nom)
    data = open(os.path.join(o, nom + 'Data.luau'), encoding='utf8').read()
    clips = open(os.path.join(o, nom + 'Clips.luau'), encoding='utf8').read()
    J = json.load(open(os.path.join(o, nom.lower() + '.json'), encoding='utf8'))
    # hauteur (studs) : sommet de chaque boîte orientée = centre.Y + demi-étendue verticale
    haut = max(b[6] + 0.5 * (abs(b[9]) * b[2] + abs(b[12]) * b[3] + abs(b[15]) * b[4]) for b in J['boxes'])
    data = re.sub(r'^--.*\n', '', data).replace('return {', 'local Data = {', 1)
    clips = re.sub(r'^--.*\n', '', clips).replace('return {', 'Data.Anim = {', 1)
    entete = ('-- Généré par blender/mobs/exporte_mobs.py depuis blender/mobs/%s (%s, %d pièces, %d os, clips : %s).\n'
              '-- Ne pas modifier à la main : éditer le .py puis relancer run_mob.ps1 + exporte_mobs.py.\n'
              % (MOBS[nom][0], nom, len(J['boxes']), len(J['bones']), ', '.join(J['clips'])))
    src = open(os.path.join(ICI, MOBS[nom][0]), encoding='utf8').read()
    nostud = ast.literal_eval(re.search(r'^NOSTUD\s*=\s*(\(.*?\))', src, re.M).group(1))
    ns = 'Data.NoStud = {%s}\n' % ', '.join('%s = true' % k for k in nostud)
    txt = entete + data.rstrip() + '\nData.Hauteur = %.2f\n' % haut + ns + clips.rstrip() + '\nreturn Data\n'
    txt = txt.replace('\r\n', '\n')
    assert len(txt) < 199000, nom + ' trop gros pour un ModuleScript'
    open(os.path.join(DEST, nom + '.lua'), 'w', encoding='utf8', newline='\n').write(txt)
    return len(J['boxes']), len(J['bones']), list(J['clips']), haut, len(txt)


def gamme(noms, fichier):
    PX = 46                                            # pixels par stud
    tuiles = []
    for nom in noms:
        _, ortho, tz = MOBS[nom]
        r = os.path.join(ICI, 'out', nom, 'render')
        im = Image.open(os.path.join(r, 'view_front_ol.png')).convert('RGB')
        m = Image.open(os.path.join(r, 'view_front_mask.png')).getchannel('A').point(lambda v: 255 if v > 128 else 0)
        m = m.filter(ImageFilter.MaxFilter(9))
        k = PX * ortho / im.width
        im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
        m = m.resize(im.size, Image.NEAREST)
        sol = round(im.height / 2 + tz * PX * 0.985)      # ligne du sol dans l'image (caméra ortho, tangage 10 deg)
        bb = m.getbbox()
        tuiles.append((nom, im.crop((bb[0], 0, bb[2], sol)), m.crop((bb[0], 0, bb[2], sol))))
    W = sum(t[1].width for t in tuiles) + 60 * (len(tuiles) + 1) + 4 * PX + 40
    H = max(t[1].height for t in tuiles) + 90
    fond = Image.new('RGB', (W, H), (34, 32, 38)); d = ImageDraw.Draw(fond)
    sol = H - 50
    d.rectangle((0, sol, W, H), fill=(58, 52, 48))
    x = 60
    # perso R15 de référence (5 studs) : silhouette grise en blocs
    u = PX
    for (x0, x1, z0, z1) in ((0.0, 0.95, 0, 2), (1.05, 2.0, 0, 2), (0, 2, 2, 4), (-1.0, -0.05, 2, 4), (2.05, 3.0, 2, 4), (0.55, 1.45, 4, 5.1)):
        d.rectangle((x + u * (x0 + 1), sol - u * z1, x + u * (x1 + 1), sol - u * z0), fill=(120, 124, 132))
    d.text((x + u * 0.4, sol + 8), 'R15 (5 studs)', fill=(220, 220, 220))
    x += 4 * u + 40
    for nom, im, m in tuiles:
        fond.paste(im, (x, sol - im.height), m)
        d.text((x, sol + 8), nom, fill=(230, 230, 230))
        x += im.width + 60
    fond.save(os.path.join(APERCUS, fichier))


if __name__ == '__main__':
    os.makedirs(DEST, exist_ok=True); os.makedirs(APERCUS, exist_ok=True)
    for nom in MOBS:
        n, nb, clips, h, taille = module(nom)
        o = os.path.join(ICI, 'out', nom)
        shutil.copy(os.path.join(o, 'sheet.png'), os.path.join(APERCUS, nom + '.png'))
        if os.path.exists(os.path.join(o, 'loop.gif')):
            shutil.copy(os.path.join(o, 'loop.gif'), os.path.join(APERCUS, nom + '_anim.gif'))
        print('MOB', nom, n, 'pieces', nb, 'os', 'h=%.2f' % h, clips, taille, 'car.')
    gamme(list(MOBS)[:4], 'Gamme.png')
    gamme(list(MOBS), 'Gamme2.png')
    print('EXPORT_OK')
