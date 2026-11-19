"""Rochers, falaises stratifiées et aiguilles pour habiller les montagnes.
Taillés par plans de coupe (facettes nettes de roche fracturée) + bruit fractal + strates.
Chaque modèle = <Nom>_Roche (flancs) et <Nom>_Dessus (faces tournées vers le ciel : neige ou mousse,
choisi par le jeu selon l'altitude). Base à y = 0 (repère L), le jeu enfonce un peu dans le terrain.
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import math, random
import bmesh
from mathutils import Vector, noise
from commun import *


def tailler(bm, rng, coupes, force=0.55):
    """Plans de coupe aléatoires : aplatit tout ce qui dépasse => facettes de roche."""
    plans = []
    for _ in range(coupes):
        n = Vector((rng.uniform(-1, 1), rng.uniform(-0.6, 1), rng.uniform(-1, 1))).normalized()
        plans.append((n, rng.uniform(force, force + 0.3)))
    for v in bm.verts:
        for n, d in plans:
            p = v.co.dot(n)
            if p > d:
                v.co -= n * (p - d)


def bruiter(bm, rng, ampl, echelle, octaves=4):
    o = Vector((rng.uniform(-50, 50), rng.uniform(-50, 50), rng.uniform(-50, 50)))
    for v in bm.verts:
        n = noise.fractal(v.co * echelle + o, 0.6, 2.0, octaves)
        v.co += v.co.normalized() * n * ampl


def strates(bm, rng, ep, retrait):
    """Bancs de roche horizontaux : chaque couche est plus ou moins en retrait."""
    couches = {}
    o = rng.uniform(0, 100)
    for v in bm.verts:
        k = math.floor((v.co.y + 0.25 * noise.noise(Vector((v.co.x * 0.4, o, v.co.z * 0.4)))) / ep)
        if k not in couches:
            couches[k] = 1 - rng.uniform(0, retrait)
        s = couches[k]
        v.co.x *= s
        v.co.z *= s


def assise(bm, y_bas):
    for v in bm.verts:
        if v.co.y < y_bas:
            v.co.y = y_bas


def separer_dessus(ob, seuil=0.62):
    """Coupe l'objet en _Roche et _Dessus (faces dont la normale pointe vers le haut du repère L)."""
    nom = ob.name
    # repère L : haut = +y L = +z Blender
    roche = bmesh.new(); roche.from_mesh(ob.data)
    dessus = roche.copy()
    roche.normal_update(); dessus.normal_update()
    roche.faces.index_update(); dessus.faces.index_update()
    # normales lissées sur le voisinage (évite le damier neige/roche)
    nz = [f.normal.z for f in roche.faces]
    roche.faces.ensure_lookup_table()
    for _ in range(3):
        nv = {}
        for f in roche.faces:
            for v in f.verts:
                s, n = nv.get(v.index, (0.0, 0))
                nv[v.index] = (s + nz[f.index], n + 1)
        nz = [sum(nv[v.index][0] / nv[v.index][1] for v in f.verts) / len(f.verts) for f in roche.faces]
    haut = {i for i, z in enumerate(nz) if z > seuil}
    roche.faces.ensure_lookup_table(); dessus.faces.ensure_lookup_table()
    bmesh.ops.delete(roche, geom=[f for f in roche.faces if f.index in haut], context='FACES')
    bmesh.ops.delete(dessus, geom=[f for f in dessus.faces if f.index not in haut], context='FACES')
    res = []
    for suffixe, bm, mat in (("_Roche", roche, materiau("Roche", (112, 106, 100))),
                             ("_Dessus", dessus, materiau("Dessus", (230, 234, 240)))):
        me = bpy.data.meshes.new(nom + suffixe)
        bm.to_mesh(me); bm.free()
        o = lier(bpy.data.objects.new(nom + suffixe, me))
        o.matrix_world = ob.matrix_world.copy()
        me.materials.append(mat)
        if me.polygons:
            lisse(o, angle=38)
            centrer_origine(o)
            res.append(o)
        else:
            bpy.data.objects.remove(o)
    bpy.data.objects.remove(ob)
    return res


def base_taillee(rng, subdiv, coupes, distance, echelle):
    """Sphère unité taillée (facettes) puis étirée à la forme voulue."""
    bm = bm_ico(T(), subdiv)
    tailler(bm, rng, coupes, distance)
    bruiter(bm, rng, 0.05, 2.2, 3)
    bmesh.ops.transform(bm, matrix=T(echelle=echelle), verts=bm.verts)
    return bm


def rocher(nom, graine, decal):
    rng = random.Random(graine)
    bm = base_taillee(rng, 4, rng.randint(9, 13), 0.62,
                      (rng.uniform(1.0, 1.4), rng.uniform(0.7, 1.0), rng.uniform(0.9, 1.2)))
    for v in bm.verts:
        v.co.y += 0.4
    assise(bm, 0.0)
    ob = objet(nom, bm, materiau("Roche", (112, 106, 100)), decal=decal)
    decimer(ob, 1500)
    return separer_dessus(ob)


def falaise(nom, graine, decal, hauteur=7.0):
    rng = random.Random(graine)
    bm = base_taillee(rng, 5, 12, 0.6, (rng.uniform(3.2, 4.2), hauteur / 2, rng.uniform(1.8, 2.4)))
    strates(bm, rng, rng.uniform(0.6, 0.9), 0.13)
    bruiter(bm, rng, 0.22, 0.45, 4)
    for v in bm.verts:
        v.co.y += hauteur / 2 - 0.5
        h = max(0.0, v.co.y / hauteur)
        v.co.x *= 1 - 0.3 * h * h
        v.co.z *= 1 - 0.25 * h * h
    assise(bm, 0.0)
    ob = objet(nom, bm, materiau("Roche", (112, 106, 100)), decal=decal)
    decimer(ob, 4000)
    return separer_dessus(ob, 0.5)


def aiguille(nom, graine, decal):
    rng = random.Random(graine)
    bm = base_taillee(rng, 5, 10, 0.62, (2.4, 5.0, 2.1))
    for v in bm.verts:
        t = (v.co.y + 5) / 10
        v.co.x *= 1.1 - 0.7 * t
        v.co.z *= 1.1 - 0.7 * t
        v.co.y += 4.6
    strates(bm, rng, 0.7, 0.1)
    bruiter(bm, rng, 0.15, 0.6, 4)
    assise(bm, 0.0)
    ob = objet(nom, bm, materiau("Roche", (112, 106, 100)), decal=decal)
    decimer(ob, 2800)
    return separer_dessus(ob, 0.5)

def construire():
    vider()
    tous = []
    x = 0
    for i in range(5):
        tous += rocher(f"Rocher{i + 1}", 100 + i * 7, (-x, 0, 0))
        x += 3.5
    x += 2
    for i in range(3):
        tous += falaise(f"Falaise{i + 1}", 300 + i * 11, (-x - 4, 0, 0), hauteur=[7, 9, 6][i])
        x += 9.5
    tous += aiguille("Aiguille1", 500, (-x - 2, 0, 0))
    for o in tous:
        print("  ", o.name, triangles(o))
    print("OBJETS", len(tous), "TRIANGLES", sum(triangles(o) for o in tous))
    exporter_fbx("Rochers.fbx", tous)
    rendu("rochers.png", direction=(-0.3, -1, 0.35), largeur=1800, hauteur=700)


construire()
