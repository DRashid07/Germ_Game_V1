# Kirpiklinin 3D vizual prototipi — Blender qurma skripti (design/proto3d/README.md).
#
# Bu, PROSEDUR modeldir — peşəkar rəssamın hazırladığı asset deyil. Məqsəd indiki 2D GPU
# görüntüsü ilə həcmli 3D yolu müqayisə etməkdir. Skript mənbədir: modeli yenidən qurur,
# redaktə edilən .blend-i və Godot-un idxal etdiyi .glb-ni yazır.
#
#   blender -b --factory-startup --python design/proto3d/build_ciliate3d.py -- \
#       game/assets/proto3d/ciliate3d.glb design/proto3d/ciliate3d.blend
#
# Obyektlər (adlar Godot tərəfində axtarılır, bax game/scripts/tools/germ3d_stand.gd):
#   Body      — aşağı poliqonlu yumşaq gövdə (radius 1), şəkil açarları: Fire (ön məsamə
#               açılır), Squash (X boyu sıxılma — zərbə), Tension (dolu: dartılmış, yumru),
#               Breath (zəif nəfəs).
#   Pore      — gövdəyə bağlı bioloji atəş çıxışı (ön məsamənin dodağı), silah deyil.
#   Nucleus   — içəridə görünən nüvə.
#   Ball      — bir daxili top (Godot onu MultiMesh ilə top sayı qədər təkrarlayır).
#   Cilium    — bir kirpik (Godot MultiMesh ilə gövdənin ətrafına düzür və döyündürür).
#   Flagellum — qamçı, 5 sümüklü armatura ilə (FlagellumRig) — gecikən yelləmə prosedurdur.
#   Mucus, Bush, Brittle — xəritə nümunələri: selik ləkəsi, kol, kövrək qabıq.
# Ox: +X — mikrobun "önü" (nişan istiqaməti), +Z — yuxarı (kameraya). Vahid: 1 = gövdə radiusu.

import math
import sys

import bpy
import bmesh
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT_GLB = argv[0] if len(argv) > 0 else "ciliate3d.glb"
OUT_BLEND = argv[1] if len(argv) > 1 else "ciliate3d.blend"

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def link(obj):
    scene.collection.objects.link(obj)
    return obj


def mesh_obj(name, bm):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    return link(bpy.data.objects.new(name, me))


def material(name, rgba):
    # glTF rəngi Principled BSDF-in "Base Color"-undan götürür (görüntü rəngi ixrac olunmur).
    m = bpy.data.materials.new(name)
    m.diffuse_color = rgba
    try:
        m.use_nodes = True
    except Exception:
        pass
    if m.node_tree is not None:
        for node in m.node_tree.nodes:
            if node.type == "BSDF_PRINCIPLED":
                node.inputs["Base Color"].default_value = rgba
                node.inputs["Roughness"].default_value = 0.45
    return m


# ---------------------------------------------------------------- gövdə
bm = bmesh.new()
bmesh.ops.create_uvsphere(bm, u_segments=28, v_segments=18, radius=1.0, calc_uvs=True)
# Yumurtavarı və bir az yastı: üstdən baxanda kirpiklinin hamar oval forması.
for v in bm.verts:
    v.co.x *= 1.12
    v.co.z *= 0.78
body = mesh_obj("Body", bm)
body.data.materials.append(material("Jelly", (0.62, 0.95, 0.35, 0.85)))

body.shape_key_add(name="Basis")


def add_key(name, fn):
    key = body.shape_key_add(name=name, from_mix=False)
    for i, v in enumerate(body.data.vertices):
        key.data[i].co = fn(Vector(v.co))
    return key


def fire_key(co):
    # Ön məsamə açılır: +X-ə yaxın nöqtələr irəli və yana açılır, ortada çökəklik.
    k = max(0.0, co.x / 1.12)
    w = k ** 6
    out = Vector(co)
    out.x += 0.16 * w
    rad = math.hypot(co.y, co.z)
    if rad > 1e-4:
        out.y += co.y / rad * 0.10 * w
        out.z += co.z / rad * 0.10 * w
    if k > 0.97:
        out.x -= 0.22 * (k - 0.97) / 0.03
    return out


def squash_key(co):
    out = Vector(co)
    out.x *= 0.80
    out.y *= 1.10
    out.z *= 1.06
    return out


def tension_key(co):
    # Dolu: membran dartılır — daha yumru və bir az böyük.
    out = Vector(co)
    out.x = co.x / 1.12 * 1.08
    out.y *= 1.06
    out.z = co.z / 0.78 * 0.92
    return out


def breath_key(co):
    out = Vector(co)
    out *= 1.035
    return out


add_key("Fire", fire_key)
add_key("Squash", squash_key)
add_key("Tension", tension_key)
add_key("Breath", breath_key)

# ---------------------------------------------------------------- məsamə (atəş çıxışı)
bm = bmesh.new()
bmesh.ops.create_cone(bm, cap_ends=False, segments=16, radius1=0.20, radius2=0.12, depth=0.16)
bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0),
                 matrix=__import__("mathutils").Matrix.Rotation(math.radians(90), 3, "Y"))
for v in bm.verts:
    v.co.x += 1.10
pore = mesh_obj("Pore", bm)
pore.data.materials.append(material("PoreLip", (0.36, 0.62, 0.18, 1.0)))

# ---------------------------------------------------------------- nüvə və top
bm = bmesh.new()
bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=0.30, calc_uvs=True)
for v in bm.verts:
    v.co.x *= 1.25
    v.co.x -= 0.25
nucleus = mesh_obj("Nucleus", bm)
nucleus.data.materials.append(material("Nucleus", (0.30, 0.50, 0.20, 1.0)))

bm = bmesh.new()
bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=6, radius=0.11, calc_uvs=True)
ball = mesh_obj("Ball", bm)
ball.data.materials.append(material("Ball", (0.95, 1.0, 0.85, 1.0)))

# ---------------------------------------------------------------- kirpik
bm = bmesh.new()
bmesh.ops.create_cone(bm, cap_ends=True, segments=5, radius1=0.035, radius2=0.010, depth=0.42)
for v in bm.verts:
    v.co.z += 0.21          # kök mənşədədir, uc +Z boyu
cil = mesh_obj("Cilium", bm)
cil.data.materials.append(material("Cilium", (0.74, 0.96, 0.55, 1.0)))

# ---------------------------------------------------------------- qamçı + armatura
SEGS = 5
SEG_LEN = 0.34
bm = bmesh.new()
rings = []
for i in range(SEGS * 2 + 1):
    t = i / (SEGS * 2)
    r = 0.07 * (1.0 - 0.8 * t)
    ring = []
    for k in range(6):
        a = math.tau * k / 6
        ring.append(bm.verts.new((-t * SEG_LEN * SEGS, math.cos(a) * r, math.sin(a) * r)))
    rings.append(ring)
for i in range(len(rings) - 1):
    for k in range(6):
        bm.faces.new((rings[i][k], rings[i][(k + 1) % 6], rings[i + 1][(k + 1) % 6], rings[i + 1][k]))
flag = mesh_obj("Flagellum", bm)
flag.data.materials.append(material("Flagellum", (0.66, 0.92, 0.42, 1.0)))
flag.location = (-1.02, 0.0, 0.0)

arm_data = bpy.data.armatures.new("FlagellumRig")
arm = link(bpy.data.objects.new("FlagellumRig", arm_data))
arm.location = flag.location
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
prev = None
for i in range(SEGS):
    b = arm_data.edit_bones.new("seg%d" % i)
    b.head = (-i * SEG_LEN, 0.0, 0.0)
    b.tail = (-(i + 1) * SEG_LEN, 0.0, 0.0)
    if prev is not None:
        b.parent = prev
        b.use_connect = True
    prev = b
bpy.ops.object.mode_set(mode="OBJECT")
# Hər halqa ən yaxın sümüyə bağlanır (sərt çəki — sadə və təkrar qurulan).
for i in range(SEGS):
    flag.vertex_groups.new(name="seg%d" % i)
for v in flag.data.vertices:
    seg = min(SEGS - 1, int(-v.co.x / SEG_LEN))
    flag.vertex_groups["seg%d" % seg].add([v.index], 1.0, "REPLACE")
mod = flag.modifiers.new("Rig", "ARMATURE")
mod.object = arm
flag.parent = arm
flag.location = (0.0, 0.0, 0.0)

# ---------------------------------------------------------------- xəritə nümunələri
bm = bmesh.new()
bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=10, radius=1.0, calc_uvs=True)
for v in bm.verts:
    v.co.z *= 0.35
    v.co.x *= 1.0 + 0.08 * math.sin(v.co.y * 5.0)
mucus = mesh_obj("Mucus", bm)
mucus.data.materials.append(material("Mucus", (0.10, 0.22, 0.27, 1.0)))

bm = bmesh.new()
for k in range(9):
    a = math.tau * k / 9
    r = 0.55 if k % 2 else 0.35
    m = __import__("mathutils").Matrix.Translation((math.cos(a) * r, math.sin(a) * r, 0.2 + 0.1 * (k % 3)))
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.42, matrix=m)
bush = mesh_obj("Bush", bm)
bush.data.materials.append(material("Bush", (0.22, 0.52, 0.34, 1.0)))

bm = bmesh.new()
bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.05], context="VERTS")
brittle = mesh_obj("Brittle", bm)
for p in brittle.data.polygons:
    p.use_smooth = False   # kövrək qabıq — fasetli, çatlı
brittle.data.materials.append(material("Brittle", (0.82, 0.58, 0.27, 1.0)))

# Nümunələr yan-yana (Godot onları ayrıca götürür, yer orada verilir).
for i, o in enumerate([mucus, bush, brittle]):
    o.location = (4.0 + 3.0 * i, 0.0, 0.0)

# ---------------------------------------------------------------- yazılış
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
bpy.ops.export_scene.gltf(filepath=OUT_GLB, export_format="GLB", export_apply=False,
                          export_morph=True, export_skins=True, export_animations=False,
                          export_yup=True)
print("[build_ciliate3d] yazıldı:", OUT_GLB, OUT_BLEND)
