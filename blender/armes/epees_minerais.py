"""12 épées des minerais (Quartz ... Néantite), reproduites d'après previews/minerais/maquette-casques-epees.png.

Génère src/partage/ArmesVoxels/Epee<Minerai>.lua (Parts Roblox, aucun asset importé) et, lancé dans Blender,
des aperçus previews/armes/epees_minerais/<Id>.png.

    python epees_minerais.py                      -> modules Luau seulement
    blender -b --factory-startup --python epees_minerais.py   -> modules + aperçus

Repère = Poignee : origine au centre de la prise, lame vers +Y, plat de la lame face à -Z, unités = studs.
Format des pièces : voir ArmesVoxels/init.lua (pc[6] = rotation Z, pc[7] = "Coin" (WedgePart) ou "Boule").
"""
import math, os, sys

ICI = os.path.dirname(os.path.abspath(__file__))
JEU = os.path.abspath(os.path.join(ICI, '..', '..'))
SORTIE_LUA = os.path.join(JEU, 'src', 'partage', 'ArmesVoxels')
SORTIE_PNG = os.path.join(JEU, 'previews', 'armes', 'epees_minerais')
ECHELLE = 0.9  # mesures prises sur la maquette (1 unité ~ 1/4.3 de l'épée de Quartz) -> studs

# coin = coin à angle droit du triangle : bd (bas-droite), bg, hd (haut-droite), hg
CONVERSION_COIN = {'bd': (90, 0), 'bg': (-90, 0), 'hg': (90, 180), 'hd': (-90, 180)}
MIROIR_COIN = {'bd': 'bg', 'bg': 'bd', 'hd': 'hg', 'hg': 'hd'}


class Epee:
    def __init__(self, id, nom):
        self.id, self.nom = id, nom
        self.couleurs = {}
        self.pieces = []  # (nom, cle, (sx, sy, sz), (x, y, z), rz, forme)
        self.lueur = None
        self.particules = None
        self.trail = (0.8, 3.0)

    def coul(self, cle, mat, rgb, refl=0):
        self.couleurs[cle] = (mat, rgb, refl)

    # --- primitives ---
    def box(self, nom, cle, sx, sy, sz, x, y, z=0, rz=0):
        self.pieces.append((nom, cle, (sx, sy, sz), (x, y, z), rz, None))

    def tri(self, nom, cle, x0, x1, y0, y1, ep, coin, z=0):
        """Triangle rectangle dans le plan de la lame, angle droit au coin donné."""
        self.pieces.append((nom, cle, (x1 - x0, y1 - y0, ep), ((x0 + x1) / 2, (y0 + y1) / 2, z), 0, coin))

    def boule(self, nom, cle, d, x, y, z=0):
        self.pieces.append((nom, cle, (d, d, d), (x, y, z), 0, 'Boule'))

    def seg(self, nom, cle, x1, y1, x2, y2, larg, ep):
        l = math.hypot(x2 - x1, y2 - y1)
        a = math.degrees(math.atan2(y2 - y1, x2 - x1))
        self.box(nom, cle, l + larg * 0.6, larg, ep, (x1 + x2) / 2, (y1 + y2) / 2, 0, a)

    def miroir(self, depuis):
        """Duplique en miroir (x -> -x) les pièces ajoutées depuis l'indice donné."""
        for nom, cle, t, (x, y, z), rz, forme in self.pieces[depuis:]:
            if abs(x) < 1e-6 and forme not in MIROIR_COIN:
                continue
            self.pieces.append((nom, cle, t, (-x, y, z), -rz, MIROIR_COIN.get(forme, forme)))

    # --- éléments composés ---
    def pointe(self, nom, cg, cd, w, y0, h, ep, x=0):
        self.tri(nom, cg, x - w / 2, x, y0, y0 + h, ep, 'bd')
        self.tri(nom, cd, x, x + w / 2, y0, y0 + h, ep, 'bg')

    def losange(self, nom, cg, cd, x, y, w, hh, hb, ep, milieu=0):
        """Gemme : pointe en haut (hh), bande centrale (milieu), pointe en bas (hb)."""
        if milieu > 0:
            self.box(nom, cg, w / 2, milieu, ep, x - w / 4, y)
            self.box(nom, cd, w / 2, milieu, ep, x + w / 4, y)
        yh, yb = y + milieu / 2, y - milieu / 2
        if hh > 0:
            self.tri(nom, cg, x - w / 2, x, yh, yh + hh, ep, 'bd')
            self.tri(nom, cd, x, x + w / 2, yh, yh + hh, ep, 'bg')
        if hb > 0:
            self.tri(nom, cg, x - w / 2, x, yb - hb, yb, ep, 'hd')
            self.tri(nom, cd, x, x + w / 2, yb - hb, yb, ep, 'hg')

    def poignee(self, cle, cle_lien, y0=-0.4, y1=0.4, larg=0.26, n=4, angle=22):
        self.box('Poignee', cle, larg, y1 - y0, larg, 0, (y0 + y1) / 2)
        pas = (y1 - y0) / n
        for i in range(n):
            self.box('Lien', cle_lien, larg + 0.05, 0.075, larg + 0.05, 0, y0 + pas * (i + 0.5), 0, angle)

    def bras(self, nom, cle, x0, y0, longueur, angle, h, ep, bout=True, cle_bout=None):
        """Barre partant de (x0, y0) dans la direction angle (degrés) ; bout pointu en losange."""
        a = math.radians(angle)
        x1, y1 = x0 + math.cos(a) * longueur, y0 + math.sin(a) * longueur
        self.box(nom, cle, longueur + 0.02, h, ep, (x0 + x1) / 2, (y0 + y1) / 2, 0, angle)
        if bout:
            c = h / math.sqrt(2) * 1.05
            self.box(nom, cle_bout or cle, c, c, ep * 0.95, x1, y1, 0, angle + 45)
        return x1, y1

    def facettes_lame(self, w, y0, y1, ep, cle, cle_clair, cle_arete=None, x=0):
        self.box('Lame', cle, w, y1 - y0, ep, x, (y0 + y1) / 2)
        self.box('Facette', cle_clair, w / 2, y1 - y0, ep + 0.02, x - w / 4, (y0 + y1) / 2)
        if cle_arete:
            self.box('Arete', cle_arete, 0.05, y1 - y0, ep + 0.04, x, (y0 + y1) / 2)

    # --- sortie Luau ---
    def luau(self, script_nom):
        f = lambda v: ('%.3f' % (v * ECHELLE)).rstrip('0').rstrip('.').replace('-0', '-0') if abs(v) > 1e-9 else '0'
        g = lambda v: ('%.3f' % v).rstrip('0').rstrip('.') if abs(v) > 1e-9 else '0'
        L = ['-- Généré par blender/armes/%s (%s, %d pièces). Ne pas modifier à la main.' % (script_nom, self.id, len(self.pieces)),
             '-- Reproduit l\'épée « %s » de previews/minerais/maquette-casques-epees.png.' % self.nom,
             '-- Repère = Poignee : origine au centre de la prise, lame vers +Y, unités = studs.',
             'return {', '\tNom = "%s",' % self.nom, '\tCouleurs = {']
        for cle, (mat, (r, gg, b), refl) in self.couleurs.items():
            L.append('\t\t["%s"] = {"%s", %d, %d, %d, %s},' % (cle, mat, r, gg, b, g(refl)))
        L.append('\t},')
        L.append('\t-- nom, couleur, taille, position, rotation Y, [rotation Z, forme]')
        L.append('\tPieces = {')
        for nom, cle, (sx, sy, sz), (x, y, z), rz, forme in self.pieces:
            ry = 0
            if forme in CONVERSION_COIN:
                ry, rz0 = CONVERSION_COIN[forme]
                rz = rz + rz0
                sx, sz = sz, sx  # coin : épaisseur sur X local, largeur sur Z local (tourné de 90° en Y)
            rz = ((rz + 180) % 360) - 180
            s = '\t\t{"%s", "%s", Vector3.new(%s, %s, %s), Vector3.new(%s, %s, %s), %s' % (
                nom, cle, f(sx), f(sy), f(sz), f(x), f(y), f(z), g(ry))
            if abs(rz) > 1e-6 or forme:
                s += ', %s' % g(rz)
            if forme in CONVERSION_COIN:
                s += ', "Coin"'
            elif forme == 'Boule':
                s += ', "Boule"'
            L.append(s + '},')
        L.append('\t},')
        L.append('\tTrailA = Vector3.new(0, %s, 0),' % f(self.trail[0]))
        L.append('\tTrailB = Vector3.new(0, %s, 0),' % f(self.trail[1]))
        if self.lueur:
            (r, gg, b), portee, lum = self.lueur
            L.append('\tLueur = {Couleur = Color3.fromRGB(%d, %d, %d), Portee = %s, Luminosite = %s},' % (r, gg, b, g(portee), g(lum)))
        if self.particules:
            (r, gg, b), taux, taille = self.particules
            L.append('\tParticules = {Couleur = Color3.fromRGB(%d, %d, %d), Taux = %s, Taille = %s},' % (r, gg, b, g(taux), g(taille)))
        L.append('}')
        return '\n'.join(L) + '\n'


EPEES = []


def epee(fn):
    EPEES.append(fn)
    return fn


# ============================================================ 1. QUARTZ
@epee
def quartz():
    e = Epee('EpeeQuartz', 'Épée de quartz')
    e.coul('quartz', 'SmoothPlastic', (214, 188, 200), 0.05)
    e.coul('quartzC', 'SmoothPlastic', (238, 220, 229), 0.05)
    e.coul('quartzF', 'SmoothPlastic', (190, 160, 176), 0)
    e.coul('arete', 'SmoothPlastic', (250, 242, 246), 0)
    e.coul('pierre', 'Slate', (132, 112, 112), 0)
    e.coul('pierreC', 'Slate', (156, 136, 134), 0)
    e.coul('pierreF', 'Slate', (98, 82, 84), 0)
    e.coul('cuir', 'Fabric', (82, 52, 40), 0)
    e.coul('lien', 'Fabric', (132, 84, 62), 0)
    # lame droite en prisme de quartz rose, pointe en biseau
    ep = 0.16
    e.facettes_lame(0.6, 0.68, 2.68, ep, 'quartz', 'quartzC', 'arete')
    e.pointe('Pointe', 'quartzC', 'quartz', 0.6, 2.68, 0.62, ep)
    e.seg('Facette', 'quartzF', 0.05, 1.2, 0.28, 1.55, 0.03, ep + 0.03)
    e.seg('Facette', 'quartzF', -0.28, 2.05, -0.05, 2.35, 0.03, ep + 0.03)
    # garde : barre de pierre droite, bouts évasés
    e.box('Garde', 'pierre', 1.3, 0.24, 0.32, 0, 0.56)
    e.box('Garde', 'pierreC', 1.3, 0.06, 0.34, 0, 0.66)
    e.box('Garde', 'pierreF', 0.1, 0.1, 0.36, 0, 0.55, 0, 45)
    i = len(e.pieces)
    e.box('Garde', 'pierreF', 0.16, 0.34, 0.36, 0.7, 0.56)
    e.tri('Garde', 'pierreF', 0.62, 0.78, 0.73, 0.79, 0.36, 'bg')
    e.miroir(i)
    e.poignee('cuir', 'lien', -0.4, 0.44)
    # pommeau : gemme de quartz hexagonale
    e.box('Pommeau', 'pierreF', 0.3, 0.1, 0.3, 0, -0.45)
    e.losange('Gemme', 'quartzC', 'quartz', 0, -0.74, 0.48, 0.16, 0.22, 0.32, milieu=0.2)
    e.trail = (0.8, 3.25)
    return e


# ============================================================ 2. SOUFRE
@epee
def soufre():
    e = Epee('EpeeSoufre', 'Épée de soufre')
    e.coul('soufre', 'Sandstone', (210, 158, 70), 0)
    e.coul('soufreC', 'Sandstone', (228, 184, 92), 0)
    e.coul('fissure', 'Sandstone', (150, 104, 42), 0)
    e.coul('fer', 'Metal', (108, 94, 90), 0.05)
    e.coul('ferF', 'Metal', (78, 66, 64), 0)
    e.coul('rivet', 'Metal', (60, 52, 52), 0.1)
    e.coul('cuir', 'Fabric', (100, 62, 40), 0)
    e.coul('lien', 'Fabric', (66, 40, 26), 0)
    ep = 0.18
    # lame large et plate, bout coupé en biais (plus haut à droite)
    w = 0.84
    e.box('Lame', 'soufre', w, 2.36, ep, 0, 0.68 + 1.18)
    e.box('Facette', 'soufreC', 0.3, 2.3, ep + 0.02, -0.25, 1.85)
    e.tri('Pointe', 'soufre', -w / 2, w / 2, 3.04, 3.34, ep, 'bd')
    # bords irréguliers
    e.box('Bord', 'soufre', 0.06, 0.5, ep, -0.44, 1.4)
    e.box('Bord', 'soufre', 0.05, 0.6, ep, 0.44, 2.5)
    # fissures de pierre (réseau)
    for (x1, y1, x2, y2) in [(-0.3, 0.95, 0.05, 1.15), (0.05, 1.15, 0.32, 1.0), (0.05, 1.15, -0.05, 1.6),
                             (-0.05, 1.6, 0.3, 1.8), (-0.05, 1.6, -0.35, 1.9), (0.3, 1.8, 0.2, 2.3),
                             (-0.35, 1.9, -0.15, 2.4), (-0.15, 2.4, 0.2, 2.3), (0.2, 2.3, 0.33, 2.75),
                             (-0.15, 2.4, -0.3, 2.9), (0.33, 2.75, 0.05, 3.0)]:
        e.seg('Fissure', 'fissure', x1, y1, x2, y2, 0.035, ep + 0.03)
    # garde : barre de fer sombre à 3 rivets
    e.box('Garde', 'fer', 1.36, 0.3, 0.34, 0, 0.53)
    e.box('Garde', 'ferF', 1.36, 0.06, 0.36, 0, 0.41)
    for x in (-0.48, 0, 0.48):
        e.box('Rivet', 'rivet', 0.1, 0.1, 0.42, x, 0.54)
    e.poignee('cuir', 'lien', -0.55, 0.38, n=5)
    e.box('Pommeau', 'ferF', 0.28, 0.08, 0.28, 0, -0.58)
    e.losange('Gemme', 'soufreC', 'soufre', 0, -0.8, 0.42, 0.18, 0.2, 0.28, milieu=0.08)
    e.trail = (0.8, 3.25)
    return e


# ============================================================ 3. ARGENT
@epee
def argent():
    e = Epee('EpeeArgent', 'Épée d\'argent')
    e.coul('argent', 'Metal', (196, 200, 212), 0.25)
    e.coul('argentC', 'Metal', (226, 229, 236), 0.3)
    e.coul('argentF', 'Metal', (150, 154, 168), 0.1)
    e.coul('gravure', 'Metal', (112, 116, 134), 0)
    e.coul('cuir', 'Fabric', (98, 108, 132), 0)
    e.coul('lien', 'Fabric', (132, 142, 166), 0)
    e.coul('gemme', 'Neon', (176, 124, 236), 0)
    ep = 0.13
    e.facettes_lame(0.48, 0.7, 2.8, ep, 'argent', 'argentC')
    e.pointe('Pointe', 'argentC', 'argent', 0.48, 2.8, 0.62, ep)
    # gorge gravée : canal sombre semé de petits losanges
    e.box('Gorge', 'gravure', 0.12, 1.9, ep + 0.03, 0, 1.75)
    for y in (1.05, 1.45, 1.85, 2.25):
        e.box('Gravure', 'argentC', 0.07, 0.07, ep + 0.05, 0, y, 0, 45)
    # garde : bras droits finis en flèche, losange central à gemme violette
    i = len(e.pieces)
    e.box('Garde', 'argent', 0.62, 0.22, 0.28, 0.42, 0.55)
    e.box('Garde', 'argentF', 0.62, 0.06, 0.3, 0.42, 0.46)
    e.tri('Garde', 'argentC', 0.72, 1.0, 0.55, 0.74, 0.28, 'bg')
    e.tri('Garde', 'argentF', 0.72, 1.0, 0.36, 0.55, 0.28, 'hg')
    e.miroir(i)
    # support de gemme en losange allongé qui remonte sur le talon de la lame
    e.losange('Garde', 'argentC', 'argentC', 0, 0.58, 0.60, 0.40, 0.28, 0.32)
    e.losange('Gemme', 'gemme', 'gemme', 0, 0.58, 0.25, 0.12, 0.10, 0.34)
    e.box('Cristal', 'gemme', 0.24, 0.24, 0.36, 0, 0.58, 0, 45)
    e.poignee('cuir', 'lien', -0.42, 0.36)
    e.box('Pommeau', 'argentF', 0.28, 0.08, 0.28, 0, -0.45)
    e.losange('Pommeau', 'argentC', 'argent', 0, -0.58, 0.34, 0.08, 0.3, 0.26)
    e.lueur = ((176, 124, 236), 3, 0.8)
    e.trail = (0.8, 3.35)
    return e


# ============================================================ 4. OBSIDIENNE
@epee
def obsidienne():
    e = Epee('EpeeObsidienne', 'Épée d\'obsidienne')
    e.coul('obsi', 'Glass', (38, 26, 48), 0.1)
    e.coul('obsiC', 'Glass', (64, 46, 82), 0.1)
    e.coul('fissure', 'Neon', (182, 92, 255), 0)
    e.coul('garde', 'Metal', (58, 40, 72), 0.1)
    e.coul('gardeC', 'Metal', (86, 62, 104), 0.1)
    e.coul('cuir', 'Fabric', (52, 34, 62), 0)
    e.coul('lien', 'Fabric', (84, 54, 100), 0)
    e.coul('gemme', 'Neon', (196, 104, 255), 0)
    ep = 0.16
    e.facettes_lame(0.56, 0.7, 2.66, ep, 'obsi', 'obsiC')
    e.pointe('Pointe', 'obsiC', 'obsi', 0.56, 2.66, 0.8, ep)
    # fissures violettes lumineuses
    for (x1, y1, x2, y2) in [(-0.12, 0.85, -0.05, 1.3), (-0.05, 1.3, -0.18, 1.75), (-0.18, 1.75, -0.08, 2.2),
                             (-0.08, 2.2, -0.15, 2.7), (-0.15, 2.7, -0.04, 3.05), (0.16, 1.0, 0.1, 1.5),
                             (0.1, 1.5, 0.2, 2.0), (-0.05, 1.3, 0.1, 1.5), (0.2, 2.0, 0.12, 2.5)]:
        e.seg('Fissure', 'fissure', x1, y1, x2, y2, 0.03, ep + 0.03)
    # garde sombre : bras en flèche + petite épine montante
    i = len(e.pieces)
    e.box('Garde', 'garde', 0.64, 0.24, 0.3, 0.42, 0.53)
    e.box('Garde', 'gardeC', 0.64, 0.06, 0.32, 0.42, 0.63)
    e.tri('Garde', 'gardeC', 0.73, 1.0, 0.53, 0.72, 0.3, 'bg')
    e.tri('Garde', 'garde', 0.73, 1.0, 0.34, 0.53, 0.3, 'hg')
    e.tri('Garde', 'gardeC', 0.5, 0.64, 0.64, 0.82, 0.26, 'bg')
    e.miroir(i)
    # support de gemme en losange allongé qui remonte sur le talon de la lame
    e.losange('Garde', 'gardeC', 'gardeC', 0, 0.57, 0.62, 0.42, 0.29, 0.32)
    e.losange('Gemme', 'gemme', 'gemme', 0, 0.57, 0.28, 0.14, 0.11, 0.34)
    e.box('Cristal', 'gemme', 0.27, 0.27, 0.36, 0, 0.57, 0, 45)
    e.poignee('cuir', 'lien', -0.4, 0.36)
    # pommeau : long cristal noir
    e.box('Pommeau', 'garde', 0.26, 0.08, 0.26, 0, -0.44)
    e.losange('Pommeau', 'obsiC', 'obsi', 0, -0.7, 0.36, 0.12, 0.28, 0.26, milieu=0.22)
    e.box('Fissure', 'fissure', 0.03, 0.3, 0.27, -0.06, -0.7)
    e.lueur = ((182, 92, 255), 5, 1.2)
    e.trail = (0.8, 3.4)
    return e


def dents(e, cle, cote, x_bord, ys, haut, saillie, ep):
    """Dents en escalier le long d'un bord (cote = -1 gauche, +1 droite) : larges en bas, s'affinant vers le haut."""
    for y in ys:
        if cote < 0:
            e.tri('Eclat', cle, x_bord - saillie, x_bord, y, y + haut, ep, 'bd')
        else:
            e.tri('Eclat', cle, x_bord, x_bord + saillie, y, y + haut, ep, 'bg')


# ============================================================ 5. GIVRITE
@epee
def givrite():
    e = Epee('EpeeGivrite', 'Épée de givrite')
    e.coul('glace', 'Ice', (176, 212, 244), 0.1)
    e.coul('glaceC', 'Ice', (214, 234, 254), 0.1)
    e.coul('glaceF', 'Ice', (140, 182, 228), 0)
    e.coul('arete', 'SmoothPlastic', (240, 248, 255), 0)
    e.coul('garde', 'Metal', (192, 202, 218), 0.25)
    e.coul('gardeF', 'Metal', (140, 152, 176), 0.1)
    e.coul('cuir', 'Fabric', (88, 102, 134), 0)
    e.coul('lien', 'Fabric', (124, 140, 172), 0)
    e.coul('gemme', 'Neon', (150, 222, 255), 0)
    ep = 0.16
    e.facettes_lame(0.5, 0.7, 2.55, ep, 'glace', 'glaceC', 'arete')
    e.pointe('Pointe', 'glaceC', 'glace', 0.5, 2.55, 0.75, ep)
    # bords en éclats de glace (escalier)
    dents(e, 'glaceC', -1, -0.25, (0.85, 1.45, 2.05), 0.55, 0.09, ep)
    dents(e, 'glace', 1, 0.25, (0.85, 1.45, 2.05), 0.55, 0.09, ep)
    e.seg('Facette', 'glaceF', 0.04, 1.3, 0.24, 1.6, 0.03, ep + 0.03)
    e.seg('Facette', 'glaceF', -0.24, 2.0, -0.04, 2.3, 0.03, ep + 0.03)
    # garde argent glacé : bras relevés en pointes
    i = len(e.pieces)
    x, y = e.bras('Garde', 'garde', 0.15, 0.52, 0.4, 0, 0.24, 0.28, bout=False)
    e.bras('Garde', 'garde', x - 0.04, y + 0.02, 0.4, 32, 0.2, 0.28)
    e.box('Garde', 'gardeF', 0.4, 0.06, 0.3, 0.35, 0.41)
    e.miroir(i)
    # support de gemme en losange allongé qui remonte sur le talon de la lame
    e.losange('Garde', 'garde', 'garde', 0, 0.58, 0.70, 0.46, 0.32, 0.32)
    e.losange('Gemme', 'gemme', 'gemme', 0, 0.58, 0.32, 0.15, 0.12, 0.34)
    e.box('Cristal', 'gemme', 0.3, 0.3, 0.36, 0, 0.58, 0, 45)
    e.poignee('cuir', 'lien', -0.42, 0.3)
    e.box('Pommeau', 'gardeF', 0.28, 0.08, 0.28, 0, -0.46)
    e.losange('Pommeau', 'glaceC', 'glace', 0, -0.66, 0.42, 0.14, 0.3, 0.26, milieu=0.06)
    e.lueur = ((150, 222, 255), 5, 1.2)
    e.trail = (0.8, 3.25)
    return e


# ============================================================ 6. EMERAUDE
@epee
def emeraude():
    e = Epee('EpeeEmeraude', 'Épée d\'émeraude')
    e.coul('bord', 'Slate', (70, 78, 72), 0)
    e.coul('bordC', 'Slate', (104, 112, 104), 0)
    e.coul('emer', 'Glass', (34, 140, 62), 0.1)
    e.coul('emerC', 'Glass', (82, 200, 104), 0.1)
    e.coul('arete', 'SmoothPlastic', (160, 240, 170), 0)
    e.coul('garde', 'Metal', (74, 80, 74), 0.1)
    e.coul('gardeC', 'Metal', (110, 116, 108), 0.1)
    e.coul('cuir', 'Fabric', (66, 66, 44), 0)
    e.coul('lien', 'Fabric', (98, 96, 62), 0)
    e.coul('gemme', 'Neon', (60, 232, 112), 0)
    ep = 0.16
    # lame : cadre de pierre sombre, cœur d'émeraude, bords en escalier
    e.box('Lame', 'bord', 0.58, 1.95, ep, 0, 0.7 + 0.975)
    e.box('Coeur', 'emer', 0.4, 1.95, ep + 0.02, 0, 1.675)
    e.box('Facette', 'emerC', 0.2, 1.95, ep + 0.03, -0.1, 1.675)
    e.box('Arete', 'arete', 0.04, 1.95, ep + 0.05, 0, 1.675)
    e.pointe('Pointe', 'bordC', 'bord', 0.58, 2.65, 0.7, ep)
    e.pointe('Pointe', 'emerC', 'emer', 0.4, 2.6, 0.55, ep + 0.02)
    dents(e, 'bordC', -1, -0.29, (0.9, 1.5, 2.1), 0.5, 0.08, ep)
    dents(e, 'bord', 1, 0.29, (0.9, 1.5, 2.1), 0.5, 0.08, ep)
    # garde sombre : bras tombants en griffe
    i = len(e.pieces)
    x, y = e.bras('Garde', 'garde', 0.15, 0.55, 0.42, 0, 0.24, 0.28, bout=False)
    e.bras('Garde', 'gardeC', x - 0.04, y, 0.4, -24, 0.2, 0.28)
    e.tri('Garde', 'gardeC', 0.2, 0.42, 0.63, 0.75, 0.22, 'bg')
    e.miroir(i)
    # support de gemme en losange allongé qui remonte sur le talon de la lame
    e.losange('Garde', 'gardeC', 'gardeC', 0, 0.58, 0.72, 0.48, 0.33, 0.32)
    e.losange('Gemme', 'gemme', 'gemme', 0, 0.58, 0.34, 0.16, 0.13, 0.36)
    e.box('Cristal', 'gemme', 0.32, 0.32, 0.38, 0, 0.58, 0, 45)
    e.poignee('cuir', 'lien', -0.48, 0.32, n=5)
    e.box('Pommeau', 'garde', 0.28, 0.08, 0.28, 0, -0.52)
    e.losange('Gemme', 'emerC', 'emer', 0, -0.72, 0.38, 0.12, 0.26, 0.26)
    e.lueur = ((60, 232, 112), 5, 1.2)
    e.trail = (0.8, 3.3)
    return e


# ============================================================ 7. RUBIS
@epee
def rubis():
    e = Epee('EpeeRubis', 'Épée de rubis')
    e.coul('rubis', 'Glass', (172, 22, 54), 0.1)
    e.coul('rubisC', 'Glass', (218, 52, 84), 0.1)
    e.coul('rubisF', 'Glass', (120, 12, 38), 0)
    e.coul('arete', 'SmoothPlastic', (246, 120, 142), 0)
    e.coul('garde', 'Metal', (96, 66, 52), 0.1)
    e.coul('gardeC', 'Metal', (136, 98, 74), 0.1)
    e.coul('cuir', 'Fabric', (92, 56, 38), 0)
    e.coul('lien', 'Fabric', (128, 82, 54), 0)
    e.coul('gemme', 'Neon', (240, 40, 80), 0)
    ep = 0.17
    # lame de rubis : partie basse large, haut décalé (cran à droite), sommet coupé en biais
    e.facettes_lame(0.62, 0.7, 2.25, ep, 'rubis', 'rubisC', 'arete')
    e.box('Lame2', 'rubis', 0.54, 0.62, ep, -0.04, 2.56)
    e.box('Facette', 'rubisC', 0.27, 0.62, ep + 0.02, -0.175, 2.56)
    e.box('Arete', 'arete', 0.05, 0.62, ep + 0.04, 0, 2.56)
    e.tri('Pointe', 'rubisC', -0.31, -0.1, 2.87, 3.3, ep + 0.02, 'bd')
    e.tri('Pointe', 'rubis', -0.1, 0.23, 2.87, 3.3, ep, 'bg')
    e.tri('Pointe', 'rubisF', 0.23, 0.31, 2.17, 2.3, ep, 'hg')
    e.seg('Facette', 'rubisF', 0.06, 1.3, 0.28, 1.6, 0.03, ep + 0.03)
    # garde bronze sombre : bras tombants, pointes
    i = len(e.pieces)
    x, y = e.bras('Garde', 'garde', 0.15, 0.53, 0.44, 0, 0.24, 0.28, bout=False)
    e.bras('Garde', 'gardeC', x - 0.04, y, 0.4, -22, 0.2, 0.28)
    e.box('Garde', 'gardeC', 0.42, 0.05, 0.3, 0.36, 0.64)
    e.miroir(i)
    # support de gemme en losange allongé qui remonte sur le talon de la lame
    e.losange('Garde', 'gardeC', 'gardeC', 0, 0.58, 0.70, 0.46, 0.32, 0.32)
    e.losange('Gemme', 'gemme', 'gemme', 0, 0.58, 0.34, 0.16, 0.13, 0.36)
    e.box('Cristal', 'gemme', 0.32, 0.32, 0.38, 0, 0.58, 0, 45)
    e.poignee('cuir', 'lien', -0.42, 0.34)
    e.box('Pommeau', 'garde', 0.28, 0.08, 0.28, 0, -0.46)
    e.losange('Gemme', 'rubisC', 'rubis', 0, -0.66, 0.4, 0.12, 0.3, 0.26, milieu=0.06)
    e.lueur = ((240, 40, 80), 5, 1.1)
    e.trail = (0.8, 3.2)
    return e


# ============================================================ 8. LUNARITE
@epee
def lunarite():
    e = Epee('EpeeLunarite', 'Épée de lunarite')
    e.coul('lune', 'SmoothPlastic', (222, 212, 238), 0.05)
    e.coul('luneC', 'SmoothPlastic', (244, 240, 252), 0.05)
    e.coul('arete', 'Neon', (236, 226, 255), 0)
    e.coul('nacre', 'Metal', (214, 208, 214), 0.3)
    e.coul('nacreF', 'Metal', (164, 156, 168), 0.1)
    e.coul('cuir', 'Fabric', (128, 128, 144), 0)
    e.coul('lien', 'Fabric', (168, 166, 182), 0)
    e.coul('orbe', 'Neon', (228, 212, 255), 0)
    ep = 0.14
    e.facettes_lame(0.54, 0.7, 2.75, ep, 'lune', 'luneC')
    e.box('Arete', 'arete', 0.04, 2.0, ep + 0.03, 0, 1.75)
    e.pointe('Pointe', 'luneC', 'lune', 0.54, 2.75, 0.62, ep)
    # garde en croissant de lune : bras qui remontent en cornes
    i = len(e.pieces)
    x, y = e.bras('Garde', 'nacre', 0.18, 0.5, 0.34, 0, 0.22, 0.26, bout=False)
    x, y = e.bras('Garde', 'nacre', x - 0.04, y, 0.28, 30, 0.19, 0.26, bout=False)
    x, y = e.bras('Garde', 'nacre', x - 0.03, y, 0.24, 66, 0.15, 0.24, bout=False)
    e.tri('Garde', 'nacre', x - 0.09, x + 0.05, y - 0.02, y + 0.2, 0.22, 'bg')
    e.box('Garde', 'nacreF', 0.32, 0.05, 0.26, 0.34, 0.43)
    e.miroir(i)
    e.box('Garde', 'nacre', 0.46, 0.46, 0.28, 0, 0.55)
    e.box('Garde', 'nacre', 0.46, 0.46, 0.28, 0, 0.55, 0, 45)
    e.boule('Cristal', 'orbe', 0.36, 0, 0.55)
    e.poignee('cuir', 'lien', -0.42, 0.32)
    # pommeau : orbe de lune dans un anneau de nacre
    e.box('Pommeau', 'nacreF', 0.24, 0.1, 0.24, 0, -0.46)
    e.box('Pommeau', 'nacre', 0.4, 0.4, 0.18, 0, -0.68)
    e.box('Pommeau', 'nacre', 0.4, 0.4, 0.18, 0, -0.68, 0, 45)
    e.boule('Orbe', 'orbe', 0.32, 0, -0.68)
    e.lueur = ((228, 212, 255), 6, 1.3)
    e.trail = (0.8, 3.3)
    return e


# ============================================================ 9. MAGMAITE
@epee
def magmaite():
    e = Epee('EpeeMagmaite', 'Épée de magmaïte')
    e.coul('roche', 'Basalt', (58, 44, 42), 0)
    e.coul('rocheC', 'Basalt', (88, 66, 58), 0)
    e.coul('lave', 'Neon', (255, 118, 28), 0)
    e.coul('laveC', 'Neon', (255, 180, 60), 0)
    e.coul('garde', 'Basalt', (72, 56, 52), 0)
    e.coul('gardeC', 'Basalt', (100, 78, 70), 0)
    e.coul('cuir', 'Fabric', (82, 54, 40), 0)
    e.coul('lien', 'Fabric', (120, 80, 56), 0)
    e.coul('gemme', 'Neon', (255, 150, 40), 0)
    ep = 0.2
    # lame large de basalte, plus étroite au talon, pointe en biseau
    e.facettes_lame(0.96, 1.05, 2.6, ep, 'roche', 'rocheC')
    e.box('Talon', 'roche', 0.76, 0.4, ep, 0, 0.88)
    e.box('Facette', 'rocheC', 0.38, 0.4, ep + 0.02, -0.19, 0.88)
    e.tri('Talon', 'roche', 0.38, 0.48, 0.68, 1.05, ep, 'hg')
    e.tri('Talon', 'rocheC', -0.48, -0.38, 0.68, 1.05, ep + 0.02, 'hd')
    e.pointe('Pointe', 'rocheC', 'roche', 0.96, 2.6, 0.85, ep)
    # fissures de lave (réseau de plaques)
    for (x1, y1, x2, y2) in [(-0.35, 0.8, -0.1, 1.05), (-0.1, 1.05, 0.25, 0.95), (-0.1, 1.05, -0.2, 1.5),
                             (0.25, 0.95, 0.35, 1.45), (-0.2, 1.5, 0.15, 1.6), (0.15, 1.6, 0.35, 1.45),
                             (-0.2, 1.5, -0.42, 1.85), (0.15, 1.6, 0.1, 2.05), (-0.42, 1.85, -0.15, 2.2),
                             (-0.15, 2.2, 0.1, 2.05), (0.1, 2.05, 0.42, 2.25), (-0.15, 2.2, -0.05, 2.65),
                             (0.42, 2.25, 0.2, 2.7), (-0.05, 2.65, 0.2, 2.7), (-0.05, 2.65, -0.3, 2.9),
                             (0.2, 2.7, 0.12, 3.15)]:
        e.seg('Fissure', 'lave', x1, y1, x2, y2, 0.045, ep + 0.03)
    # garde de roche massive, bouts pointus, gemme de lave
    i = len(e.pieces)
    x, y = e.bras('Garde', 'garde', 0.2, 0.56, 0.66, 6, 0.32, 0.34, cle_bout='gardeC')
    e.box('Garde', 'gardeC', 0.55, 0.06, 0.34, 0.48, 0.66, 0, 4)
    e.seg('Fissure', 'lave', 0.3, 0.5, 0.6, 0.55, 0.035, 0.36)
    e.miroir(i)
    # support de gemme en losange allongé qui remonte sur le talon de la lame
    e.losange('Garde', 'gardeC', 'gardeC', 0, 0.6, 0.77, 0.51, 0.35, 0.38)
    e.losange('Gemme', 'gemme', 'gemme', 0, 0.6, 0.36, 0.17, 0.14, 0.42)
    e.box('Cristal', 'gemme', 0.34, 0.34, 0.44, 0, 0.6, 0, 45)
    e.poignee('cuir', 'lien', -0.45, 0.3)
    e.box('Pommeau', 'garde', 0.3, 0.1, 0.3, 0, -0.5)
    e.losange('Gemme', 'laveC', 'lave', 0, -0.76, 0.42, 0.16, 0.32, 0.28)
    e.lueur = ((255, 130, 40), 7, 1.6)
    e.particules = ((255, 140, 40), 4, 0.18)
    e.trail = (0.9, 3.4)
    return e


# ============================================================ 10. DIAMANT
@epee
def diamant():
    e = Epee('EpeeDiamant', 'Épée de diamant')
    e.coul('diam', 'Glass', (212, 226, 246), 0.2)
    e.coul('diamC', 'Glass', (242, 247, 255), 0.2)
    e.coul('diamF', 'Glass', (178, 200, 236), 0.1)
    e.coul('arete', 'SmoothPlastic', (255, 255, 255), 0)
    e.coul('argent', 'Metal', (204, 210, 222), 0.3)
    e.coul('argentF', 'Metal', (150, 158, 176), 0.1)
    e.coul('cuir', 'Fabric', (150, 156, 172), 0)
    e.coul('lien', 'Fabric', (196, 200, 214), 0)
    e.coul('gemme', 'Neon', (168, 220, 255), 0)
    e.coul('scintille', 'Neon', (240, 248, 255), 0)
    ep = 0.17
    e.facettes_lame(0.62, 0.7, 2.75, ep, 'diam', 'diamC', 'arete')
    e.pointe('Pointe', 'diamC', 'diam', 0.62, 2.75, 0.7, ep)
    for (x1, y1, x2, y2) in [(0.05, 1.0, 0.3, 1.35), (-0.3, 1.6, -0.05, 1.95), (0.05, 2.1, 0.3, 2.45),
                             (-0.3, 2.5, -0.05, 2.75)]:
        e.seg('Facette', 'diamF', x1, y1, x2, y2, 0.03, ep + 0.03)
    # garde d'argent à bouts en flèche, diamant bleuté au centre
    i = len(e.pieces)
    e.box('Garde', 'argent', 0.6, 0.22, 0.28, 0.4, 0.56)
    e.box('Garde', 'argentF', 0.6, 0.06, 0.3, 0.4, 0.47)
    e.tri('Garde', 'argent', 0.69, 0.98, 0.56, 0.76, 0.28, 'bg')
    e.tri('Garde', 'argentF', 0.69, 0.98, 0.36, 0.56, 0.28, 'hg')
    e.miroir(i)
    # support de gemme en losange allongé qui remonte sur le talon de la lame
    e.losange('Garde', 'argent', 'argent', 0, 0.6, 0.67, 0.45, 0.31, 0.32)
    e.losange('Gemme', 'gemme', 'gemme', 0, 0.6, 0.32, 0.15, 0.12, 0.34)
    e.box('Cristal', 'gemme', 0.3, 0.3, 0.36, 0, 0.6, 0, 45)
    e.poignee('cuir', 'lien', -0.45, 0.34)
    e.box('Pommeau', 'argentF', 0.28, 0.08, 0.28, 0, -0.49)
    e.losange('Gemme', 'diamC', 'diam', 0, -0.68, 0.42, 0.14, 0.3, 0.26)
    # étincelles en étoile à 4 branches autour de la lame
    for (x, y, t) in [(0.62, 3.05, 0.26), (-0.6, 2.1, 0.2), (0.62, 1.75, 0.16), (-0.5, 0.95, 0.18)]:
        e.box('Etoile', 'scintille', 0.035, t, 0.035, x, y)
        e.box('Etoile', 'scintille', t, 0.035, 0.035, x, y)
    e.lueur = ((190, 228, 255), 6, 1.3)
    e.particules = ((230, 245, 255), 3, 0.2)
    e.trail = (0.8, 3.4)
    return e


# ============================================================ 11. ORICHALQUE
@epee
def orichalque():
    e = Epee('EpeeOrichalque', 'Épée d\'orichalque')
    e.coul('or', 'Metal', (226, 164, 40), 0.25)
    e.coul('orC', 'Metal', (250, 204, 76), 0.3)
    e.coul('orF', 'Metal', (176, 112, 26), 0.1)
    e.coul('canal', 'Neon', (255, 224, 96), 0)
    e.coul('rune', 'Metal', (214, 140, 30), 0)
    e.coul('cuir', 'Fabric', (156, 98, 36), 0)
    e.coul('lien', 'Fabric', (206, 146, 54), 0)
    e.coul('soleil', 'Neon', (255, 216, 70), 0)
    ep = 0.18
    # lame large dorée : cadre en relief, panneau clair, canal lumineux à runes
    e.box('Lame', 'orF', 1.1, 2.1, ep, 0, 1.75)
    e.box('Panneau', 'or', 0.84, 2.0, ep + 0.02, 0, 1.75)
    e.box('Facette', 'orC', 0.12, 2.1, ep + 0.04, -0.49, 1.75)
    e.box('Facette', 'orC', 0.12, 2.1, ep + 0.04, 0.49, 1.75)
    e.box('Canal', 'canal', 0.16, 2.2, ep + 0.04, 0, 1.85)
    for (x1, y1, x2, y2) in [(-0.04, 1.1, 0.04, 1.25), (0.04, 1.25, -0.04, 1.4), (-0.04, 1.75, 0.04, 1.9),
                             (0.04, 1.9, -0.04, 2.05), (-0.04, 2.4, 0.04, 2.55)]:
        e.seg('Rune', 'rune', x1, y1, x2, y2, 0.025, ep + 0.06)
    e.pointe('Pointe', 'orC', 'orF', 1.1, 2.8, 0.66, ep)
    e.pointe('Pointe', 'or', 'or', 0.84, 2.75, 0.5, ep + 0.02)
    e.pointe('Pointe', 'canal', 'canal', 0.16, 2.95, 0.12, ep + 0.04)
    # garde : cornes dorées relevées, petites pointes tombantes, soleil lumineux au centre
    i = len(e.pieces)
    x, y = e.bras('Garde', 'or', 0.22, 0.58, 0.4, 0, 0.26, 0.3, bout=False)
    x, y = e.bras('Garde', 'orC', x - 0.04, y, 0.36, 38, 0.22, 0.3, bout=False)
    x, y = e.bras('Garde', 'orC', x - 0.03, y, 0.3, 72, 0.17, 0.28, bout=False)
    e.tri('Garde', 'orC', x - 0.1, x + 0.06, y - 0.02, y + 0.24, 0.26, 'bg')
    e.bras('Garde', 'orF', 0.3, 0.48, 0.32, -42, 0.13, 0.26)
    e.miroir(i)
    e.box('Garde', 'orF', 0.58, 0.58, 0.32, 0, 0.62)
    e.box('Garde', 'or', 0.58, 0.58, 0.32, 0, 0.62, 0, 45)
    for a in (0, 90):
        e.box('Garde', 'orC', 0.08, 0.84, 0.3, 0, 0.62, 0, a)
    e.boule('Cristal', 'soleil', 0.42, 0, 0.62)
    e.poignee('cuir', 'lien', -0.44, 0.3)
    e.box('Pommeau', 'orF', 0.3, 0.1, 0.3, 0, -0.48)
    e.losange('Gemme', 'orC', 'or', 0, -0.7, 0.42, 0.16, 0.3, 0.28)
    e.lueur = ((255, 210, 80), 7, 1.6)
    e.particules = ((255, 220, 110), 3, 0.18)
    e.trail = (0.9, 3.4)
    return e


# ============================================================ 12. NEANTITE
@epee
def neantite():
    e = Epee('EpeeNeantite', 'Épée de néantite')
    e.coul('neant', 'Glass', (54, 24, 74), 0.1)
    e.coul('neantC', 'Glass', (82, 42, 108), 0.1)
    e.coul('fil', 'Neon', (200, 64, 255), 0)
    e.coul('etoile', 'Neon', (246, 214, 255), 0)
    e.coul('garde', 'Metal', (86, 44, 116), 0.15)
    e.coul('gardeC', 'Metal', (124, 70, 160), 0.15)
    e.coul('cuir', 'Fabric', (48, 28, 60), 0)
    e.coul('lien', 'Fabric', (84, 50, 106), 0)
    e.coul('gemme', 'Neon', (216, 80, 255), 0)
    ep = 0.18
    # lame large violet sombre, fils lumineux sur les bords et au centre
    e.facettes_lame(0.94, 0.75, 2.75, ep, 'neant', 'neantC')
    e.pointe('Pointe', 'neantC', 'neant', 0.94, 2.75, 0.75, ep)
    e.box('Fil', 'fil', 0.04, 2.0, ep + 0.03, -0.38, 1.75)
    e.box('Fil', 'fil', 0.04, 2.0, ep + 0.03, 0.38, 1.75)
    e.box('Fil', 'fil', 0.04, 2.3, ep + 0.03, 0, 1.75)
    e.seg('Fil', 'fil', -0.38, 2.75, -0.02, 3.35, 0.04, ep + 0.03)
    e.seg('Fil', 'fil', 0.38, 2.75, 0.02, 3.35, 0.04, ep + 0.03)
    e.box('Etoile', 'etoile', 0.05, 0.36, ep + 0.06, 0, 2.95)
    e.box('Etoile', 'etoile', 0.24, 0.05, ep + 0.06, 0, 2.95)
    # garde violette en ailes tombantes
    i = len(e.pieces)
    x, y = e.bras('Garde', 'garde', 0.2, 0.6, 0.52, 0, 0.28, 0.32, bout=False)
    e.bras('Garde', 'gardeC', x - 0.05, y, 0.48, -30, 0.24, 0.32)
    e.box('Garde', 'gardeC', 0.48, 0.05, 0.32, 0.45, 0.7)
    e.tri('Garde', 'gardeC', 0.22, 0.48, 0.71, 0.86, 0.26, 'bg')
    e.miroir(i)
    # support de gemme en losange allongé qui remonte sur le talon de la lame
    e.losange('Garde', 'gardeC', 'gardeC', 0, 0.64, 0.79, 0.53, 0.36, 0.36)
    e.losange('Gemme', 'gemme', 'gemme', 0, 0.64, 0.38, 0.18, 0.14, 0.40)
    e.box('Cristal', 'gemme', 0.36, 0.36, 0.42, 0, 0.64, 0, 45)
    e.poignee('cuir', 'lien', -0.5, 0.32, n=5)
    e.box('Pommeau', 'garde', 0.3, 0.1, 0.3, 0, -0.55)
    e.losange('Gemme', 'neantC', 'neant', 0, -0.8, 0.34, 0.12, 0.3, 0.26, milieu=0.14)
    e.box('Fil', 'fil', 0.03, 0.34, 0.29, 0, -0.8)
    # éclats de néantite qui flottent autour
    for (x, y, t) in [(-0.82, 1.75, 0.2), (0.86, 2.15, 0.17), (-0.7, -0.1, 0.15), (0.72, 0.2, 0.13)]:
        e.box('Eclat', 'gemme', t, t * 1.5, 0.08, x, y, 0, 0)
        e.box('Eclat', 'gemme', t * 0.7, t * 0.7, 0.09, x, y + t * 0.75, 0, 45)
        e.box('Eclat', 'gemme', t * 0.7, t * 0.7, 0.09, x, y - t * 0.75, 0, 45)
    e.lueur = ((200, 70, 255), 7, 1.6)
    e.particules = ((210, 90, 255), 4, 0.18)
    e.trail = (0.9, 3.45)
    return e


# ====================================================================== écriture
def ecrire_modules():
    nom_script = os.path.basename(__file__)
    res = []
    for fn in EPEES:
        e = fn()
        chemin = os.path.join(SORTIE_LUA, e.id + '.lua')
        with open(chemin, 'w', encoding='utf8', newline='\n') as f:
            f.write(e.luau(nom_script))
        print('ARME_OK %s %d pieces' % (e.id, len(e.pieces)))
        res.append(e)
    return res


# ====================================================================== aperçus Blender
def rendre(epees):
    import bpy
    from mathutils import Matrix, Vector
    os.makedirs(SORTIE_PNG, exist_ok=True)

    def lin(c):
        c = c / 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    C = Matrix.Rotation(math.radians(90), 4, 'X')  # Roblox (x, y, z) -> Blender (x, -z, y)

    for e in epees:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        sc = bpy.context.scene
        try:
            sc.render.engine = 'BLENDER_EEVEE'
        except TypeError:
            sc.render.engine = 'BLENDER_EEVEE_NEXT'
        sc.render.resolution_x, sc.render.resolution_y = 520, 1000
        sc.view_settings.view_transform = 'Standard'
        w = bpy.data.worlds.new('m')
        sc.world = w
        w.use_nodes = True
        w.node_tree.nodes['Background'].inputs[0].default_value = (0.035, 0.035, 0.04, 1)
        w.node_tree.nodes['Background'].inputs[1].default_value = 1.0
        mats = {}
        for cle, (mat, (r, g, b), refl) in e.couleurs.items():
            m = bpy.data.materials.new(cle)
            m.use_nodes = True
            bsdf = m.node_tree.nodes['Principled BSDF']
            col = (lin(r), lin(g), lin(b), 1)
            bsdf.inputs['Base Color'].default_value = col
            if mat == 'Neon':
                bsdf.inputs['Emission Color'].default_value = col
                bsdf.inputs['Emission Strength'].default_value = 1.6
            bsdf.inputs['Metallic'].default_value = 0.55 if mat == 'Metal' else 0.0
            bsdf.inputs['Roughness'].default_value = {'Metal': 0.35, 'Fabric': 0.9, 'Glass': 0.15, 'Ice': 0.2,
                                                     'Basalt': 0.85, 'Slate': 0.8, 'Sandstone': 0.85}.get(mat, 0.45)
            mats[cle] = m
        for k, (nom, cle, (sx, sy, sz), (x, y, z), rz, forme) in enumerate(e.pieces):
            ry = 0
            if forme in CONVERSION_COIN:
                ry, rz0 = CONVERSION_COIN[forme]
                rz += rz0
                sx, sz = sz, sx
            if forme == 'Boule':
                bpy.ops.mesh.primitive_uv_sphere_add(radius=sx / 2, segments=24, ring_count=12)
                ob = bpy.context.active_object
                bpy.ops.object.shade_smooth()
                ob.matrix_world = C @ Matrix.Translation(Vector((x, y, z)) * ECHELLE) @ Matrix.Scale(ECHELLE, 4)
            else:
                hx, hy, hz = sx / 2, sy / 2, sz / 2
                if forme in CONVERSION_COIN:  # WedgePart : face haute à +Z, pente vers -Z
                    vs = [(-hx, -hy, -hz), (hx, -hy, -hz), (-hx, -hy, hz), (hx, -hy, hz), (-hx, hy, hz), (hx, hy, hz)]
                    fs = [(0, 1, 3, 2), (2, 3, 5, 4), (0, 4, 5, 1), (0, 2, 4), (1, 5, 3)]
                else:
                    vs = [(a * hx, b * hy, c * hz) for a in (-1, 1) for b in (-1, 1) for c in (-1, 1)]
                    fs = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
                me = bpy.data.meshes.new(nom)
                me.from_pydata(vs, [], fs)
                me.update()
                me.validate()
                ob = bpy.data.objects.new('%s_%d' % (nom, k), me)
                sc.collection.objects.link(ob)
                M = (Matrix.Translation(Vector((x, y, z)) * ECHELLE) @ Matrix.Rotation(math.radians(rz), 4, 'Z')
                     @ Matrix.Rotation(math.radians(ry), 4, 'Y') @ Matrix.Scale(ECHELLE, 4))
                ob.matrix_world = C @ M
            ob.data.materials.append(mats[cle])
        # recalcul des normales (ordre des faces non garanti)
        for ob in sc.collection.objects:
            if ob.type == 'MESH':
                bpy.context.view_layer.objects.active = ob
                ob.select_set(True)
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.mesh.normals_make_consistent(inside=False)
        bpy.ops.object.mode_set(mode='OBJECT')
        # caméra orthographique de face (Roblox -Z), légère rotation 3/4
        cy = 1.25 * ECHELLE
        cam_d = bpy.data.cameras.new('cam')
        cam_d.type = 'ORTHO'
        cam_d.ortho_scale = 5.2 * ECHELLE
        cam = bpy.data.objects.new('cam', cam_d)
        sc.collection.objects.link(cam)
        yaw = math.radians(12)
        cam.location = (math.sin(yaw) * 10, -10 * math.cos(yaw), cy + 1.2)
        cam.rotation_euler = (math.radians(83.2), 0, yaw)
        sc.camera = cam
        for nom_l, rot, en in [('cle', (math.radians(50), 0, math.radians(-20)), 3.2),
                                ('appoint', (math.radians(70), 0, math.radians(120)), 1.2),
                                ('dos', (math.radians(110), 0, math.radians(160)), 1.5)]:
            ld = bpy.data.lights.new(nom_l, 'SUN')
            ld.energy = en
            lo = bpy.data.objects.new(nom_l, ld)
            lo.rotation_euler = rot
            sc.collection.objects.link(lo)
        sc.render.filepath = os.path.join(SORTIE_PNG, e.id + '.png')
        bpy.ops.render.render(write_still=True)
        print('ARME_PNG', sc.render.filepath)


if __name__ == '__main__':
    epees = ecrire_modules()
    try:
        import bpy  # noqa
        rendre(epees)
    except ImportError:
        pass
