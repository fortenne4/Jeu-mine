# Helpers partagés des mobs (box rig du pack LihFolk). Unités = studs (STUDS = 1), Z haut, devant = -Y, gauche = +X.
import math
from mathutils import Vector, Matrix

EASE = lambda u: u * u * (3 - 2 * u)


def kf(f, keys):
    """Interpolation lissée entre clés [(frame, valeur)], valeur = nombre ou tuple."""
    if f <= keys[0][0]:
        return keys[0][1]
    for (f0, v0), (f1, v1) in zip(keys, keys[1:]):
        if f <= f1:
            u = EASE(max(0.0, min(1.0, (f - f0) / (f1 - f0)))) if f1 > f0 else 1.0
            if isinstance(v0, tuple):
                return tuple(a + (b - a) * u for a, b in zip(v0, v1))
            return v0 + (v1 - v0) * u
    return keys[-1][1]


def pose(f, table):
    """table = {bone: [(frame, (rx, ry, rz)), ...], 'root_loc': [...]} -> pose dict"""
    return {b: kf(f, k) for b, k in table.items()}


def chain(K, a, b, n, bone, keys=('CH', 'C2'), w=0.22, t=0.08):
    """Chaîne de a à b : n maillons allongés, alternés de 90 deg autour de l'axe."""
    a, b = Vector(a), Vector(b); d = (b - a)
    z = d.normalized(); up = Vector((0, 0, 1)) if abs(z.z) < 0.95 else Vector((0, 1, 0))
    x = up.cross(z).normalized(); y = z.cross(x)
    R0 = Matrix((x, y, z)).transposed()
    L = d.length / n
    for i in range(n):
        R = R0 @ Matrix.Rotation(math.radians(90 * (i % 2)), 3, 'Z')
        K.box(tuple(a + d * ((i + 0.5) / n)), (w, t, L * 1.25), keys[i % 2], bone, R=R)


def flame(K, base, h, w, bone, keys=('AU1', 'AU2', 'AU3'), lean=(0, 0.25, 0)):
    """Flamme d'aura en 3 marches (large -> pointe), pointe déportée de `lean` par marche."""
    x, y, z = base
    for i, (s, hh, k) in enumerate(zip((1, .62, .32), (.42, .33, .25), keys)):
        K.box((x + lean[0] * i, y + lean[1] * i, z + h * hh / 2), (w * s, w * s, h * hh), k, bone)
        z += h * hh


def crystal(K, base, d, L, w, bone, keys=('C2', 'CR', 'CR'), socket=None):
    """Cristal facetté : 3 boîtes effilées tournées de 45 deg autour de leur axe, socle de roche optionnel."""
    d = Vector(d).normalized()
    R = Vector((0, 0, 1)).rotation_difference(d).to_matrix() @ Matrix.Rotation(math.radians(45), 3, 'Z')
    if socket:
        K.box(tuple(Vector(base) - d * w * 0.15), (w * 1.25, w * 1.25, w * 0.5), socket, bone, R=R)
    for (t0, t1, s), k in zip(((0, .5, 1), (.5, .8, .7), (.8, 1, .38)), keys):
        K.box(tuple(Vector(base) + d * (L * (t0 + t1) / 2)), (w * s, w * s, L * (t1 - t0) + .04), k, bone, R=R)
