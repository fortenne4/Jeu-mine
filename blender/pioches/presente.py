"""Planches de présentation des pioches (après pioches_brick.py ... render) :
    py blender/pioches/presente.py [ID ...]        (sans argument : toutes les pioches rendues)
Par vue : fond de studio neutre + contour sombre fin + halo des lueurs (passe _glow) -> render/<ID>_<vue>_fx.png
Par pioche : planche face / 3-4 / gros plan -> blender/apercus/pioches/<ID>.png ; plus Collection.png (toutes en 3/4).
"""
import os, sys, glob
import numpy as np
from PIL import Image, ImageFilter, ImageChops, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
APERCUS = os.path.join(HERE, '..', 'apercus', 'pioches')

INFOS = {
    'PiocheDemon': ('Pioche démoniaque', 'Fer noir · lames d\'acier sanglant dentelées · œil infernal · cornes annelées · flammes'),
    'PiocheVolcan': ('Pioche volcanique', 'Basalte éclaté · fissures de magma · cratère de lave · coulées incandescentes'),
    'PiocheGivre': ('Pioche glaciale', 'Acier argenté · pic et fourche de cristaux de glace · couronne de givre · saphir'),
    'PiocheCeleste': ('Pioche céleste', 'Or · ailes de plumes · lames de cristal blanc · soleil divin · auréole'),
    'PiocheNeant': ('Pioche du Néant', 'Métal violet-noir · faux fracturée · portail du vide · cristaux en orbite'),
    'PiocheLegende': ('Pioche légendaire', 'Mithril et or · grand diamant serti · rubis, saphir, émeraude · filigrane'),
    'PiocheBois': ('Pioche du bûcheron', 'Branche de chêne · pointes durcies au feu · ligature de corde croisée · jeune pousse'),
    'PiochePierre': ('Pioche de silex', 'Silex taillé à éclats · mâchoire de bois · lanières de cuir · coin en os · dent porte-bonheur'),
    'PiocheCuivre': ('Pioche de cuivre', 'Cuivre coulé · nervures et rivets · vert-de-gris · poinçon du fondeur'),
    'PiocheFer': ('Pioche de fer', 'Fer forgé martelé · pic et herminette à tranchants d\'acier · attelles rivetées · cuir cousu'),
    'PiocheQuartz': ('Pioche de quartz', 'Acier poli · pic et bouquet de quartz rose · améthyste sertie · pommeau de cristal'),
}
ORDRE = list(INFOS)


def font(sz, bold=False):
    for f in (('georgiab.ttf' if bold else 'georgia.ttf'), ('segoeuib.ttf' if bold else 'segoeui.ttf'), 'arial.ttf'):
        try: return ImageFont.truetype(os.path.join(r'C:\Windows\Fonts', f), sz)
        except OSError: pass
    return ImageFont.load_default()


def backdrop(w, h, c0=(74, 77, 86), c1=(24, 25, 30)):
    y, x = np.mgrid[0:h, 0:w]
    r = np.sqrt(((x - w / 2) / (w * .62)) ** 2 + ((y - h * .45) / (h * .62)) ** 2)
    t = np.clip(r, 0, 1)[..., None] ** 1.4
    return np.array(c0, np.float32) * (1 - t) + np.array(c1, np.float32) * t


def fx(path):
    im = Image.open(path).convert('RGBA'); W, H = im.size
    a = np.asarray(im)[..., 3].astype(np.float32) / 255
    rgb = np.asarray(im)[..., :3].astype(np.float32)
    out = backdrop(W, H) * (1 - a[..., None]) + rgb * a[..., None]
    A = Image.fromarray(((a > .5) * 255).astype('uint8'))
    ring = np.asarray(ImageChops.subtract(A.filter(ImageFilter.MaxFilter(5)), A)) > 0
    out[ring] = out[ring] * .25 + np.array((8, 8, 10)) * .75                # contour sombre fin
    sh = np.asarray(A.filter(ImageFilter.GaussianBlur(28))).astype(np.float32)[..., None] / 255
    out = out * (1 - .35 * sh * (1 - a[..., None]))                         # ombre douce autour de l'objet
    gp = path[:-4] + '_glow.png'
    if os.path.exists(gp):
        g = np.asarray(Image.open(gp).convert('RGB')).astype(np.float32)
        on = g.max(-1, keepdims=True) > 40
        g = np.where(on, g, 0)
        gi = Image.fromarray(g.astype('uint8'))
        bloom = sum(np.asarray(gi.filter(ImageFilter.GaussianBlur(r))).astype(np.float32) * k for r, k in ((4, .35), (12, .35), (32, .3), (80, .22)))
        out = np.where(on & (a[..., None] > .5), g, out + bloom)            # la lueur garde sa couleur exacte, halo autour
    return Image.fromarray(np.clip(out, 0, 255).astype('uint8'))


def planche(ID, ren):
    vues = [('face', 'Vue de face'), ('34', 'Vue 3/4'), ('tete', 'Gros plan de la tête')]
    imgs = []
    for v, _ in vues:
        p = os.path.join(ren, '%s_%s.png' % (ID, v))
        im = fx(p); im.save(p[:-4] + '_fx.png'); imgs.append(im)
    w, h = imgs[0].size; m = 40; top = 190; bot = 70
    sheet = Image.new('RGB', (3 * w + 4 * m, h + top + bot), (18, 19, 23))
    d = ImageDraw.Draw(sheet)
    titre, sous = INFOS.get(ID, (ID, ''))
    d.text((m, 40), titre, font=font(72, True), fill=(236, 230, 214))
    d.text((m + 4, 128), sous, font=font(30), fill=(165, 168, 178))
    for i, (im, (_, lab)) in enumerate(zip(imgs, vues)):
        x = m + i * (w + m); sheet.paste(im, (x, top))
        d.text((x + 6, top + h + 16), lab, font=font(28), fill=(140, 143, 152))
    os.makedirs(APERCUS, exist_ok=True)
    sheet.save(os.path.join(APERCUS, ID + '.png')); print('PLANCHE', ID)
    return imgs[1]


if __name__ == '__main__':
    ids = sys.argv[1:] or [i for i in ORDRE if os.path.exists(os.path.join(HERE, 'out_' + i, 'render', i + '_34.png'))]
    vues34 = {}
    for ID in ids:
        vues34[ID] = planche(ID, os.path.join(HERE, 'out_' + ID, 'render'))
    tous = [i for i in ORDRE if os.path.exists(os.path.join(HERE, 'out_' + i, 'render', i + '_34_fx.png'))]
    if len(tous) > 1:
        ims = [Image.open(os.path.join(HERE, 'out_' + i, 'render', i + '_34_fx.png')).resize((500, 650), Image.LANCZOS) for i in tous]
        cols = 3; rows = (len(ims) + cols - 1) // cols
        col = Image.new('RGB', (cols * 520 + 20, rows * 720 + 120), (18, 19, 23)); d = ImageDraw.Draw(col)
        d.text((24, 30), 'Collection de pioches', font=font(54, True), fill=(236, 230, 214))
        for k, (i, im) in enumerate(zip(tous, ims)):
            x, y = 20 + (k % cols) * 520, 110 + (k // cols) * 720
            col.paste(im, (x, y)); d.text((x + 8, y + 656), INFOS[i][0], font=font(30, True), fill=(200, 196, 186))
        col.save(os.path.join(APERCUS, 'Collection.png')); print('COLLECTION', len(ims))
