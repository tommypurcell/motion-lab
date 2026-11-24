"""Docker logo morph v5: starts flat on the exact old logo, goes 3D, ends flat on the exact new logo. original lockup (old whale + old wordmark) -> letters pop off ->
whale spins into the new whale -> new wordmark rises in.

Run:  Blender -b --python docker_morph.py -- frames_dir [samples] [width] [height] [step] [only_frame]
"""
import bpy, json, math, os, sys
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
A = os.path.join(HERE, "assets", "docker")
args = sys.argv[sys.argv.index("--") + 1:]
frames_dir = args[0]
samples = int(args[1]) if len(args) > 1 else 128
res_x = int(args[2]) if len(args) > 2 else 1920
res_y = int(args[3]) if len(args) > 3 else 1080
step = int(args[4]) if len(args) > 4 else 1
only = int(args[5]) if len(args) > 5 else 0

outl = json.load(open(os.path.join(A, "outlines_v2.json")))
old_words = json.load(open(os.path.join(A, "wordmark_old.json")))
words = json.load(open(os.path.join(A, "wordmark.json")))

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.device = "GPU"
prefs = bpy.context.preferences.addons["cycles"].preferences
prefs.compute_device_type = "METAL"
prefs.get_devices()
for d in prefs.devices:
    d.use = True
scene.cycles.samples = samples
scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = res_x, res_y
scene.view_settings.view_transform = "Standard"   # exact brand hex on flat backgrounds
scene.view_settings.look = "None"
scene.render.fps = 30
scene.render.use_motion_blur = True
scene.render.motion_blur_shutter = 0.35


def srgb(h):
    def c(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    return (c(int(h[0:2], 16)), c(int(h[2:4], 16)), c(int(h[4:6], 16)), 1)


# official palettes: 2023-25 brand page (archived) and the 2026 brand guidelines
OLD_BLUE = srgb("1D63ED")       # Moby Blue
OLD_LIGHT = srgb("E5F2FC")      # Light Blue (old background)
OLD_INK = srgb("17191E")        # Off Black (old wordmark)
NEW_BLUE = srgb("101010")       # Ether (new logo)
BASE = srgb("6172FF")           # Base (new background) -> "Ether on Base"

# ---------- materials ----------
blue = bpy.data.materials.new("Blue")
blue.use_nodes = True
n, l = blue.node_tree.nodes, blue.node_tree.links
bsdf = n["Principled BSDF"]
bsdf.inputs["Roughness"].default_value = 0.22
bsdf.inputs["Coat Weight"].default_value = 1.0
bsdf.inputs["Coat Roughness"].default_value = 0.03
bsdf.inputs["Subsurface Weight"].default_value = 0.15
bsdf.inputs["Subsurface Scale"].default_value = 0.05
mix = n.new("ShaderNodeMix")
mix.data_type = "RGBA"
mix.inputs["A"].default_value = OLD_BLUE
mix.inputs["B"].default_value = NEW_BLUE
l.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
flat_facs = []


def add_flat_switch(mat, color_socket=None, color=None):
    """Mix the material into flat emission of its own color; animated at the end."""
    nn, ll = mat.node_tree.nodes, mat.node_tree.links
    out = nn["Material Output"]
    shader = out.inputs["Surface"].links[0].from_socket
    em_ = nn.new("ShaderNodeEmission")
    if color_socket is not None:
        ll.new(color_socket, em_.inputs["Color"])
    else:
        em_.inputs["Color"].default_value = color
    mx_ = nn.new("ShaderNodeMixShader")
    ll.new(shader, mx_.inputs[1])
    ll.new(em_.outputs["Emission"], mx_.inputs[2])
    ll.new(mx_.outputs["Shader"], out.inputs["Surface"])
    flat_facs.append(mx_.inputs["Fac"])
color_fac = mix.inputs["Factor"]

def solid(name, color):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = color
    b.inputs["Roughness"].default_value = 0.3
    b.inputs["Coat Weight"].default_value = 0.6
    return m


old_ink = solid("OldInk", OLD_INK)
ether = solid("Ether", NEW_BLUE)
eb = ether.node_tree.nodes["Principled BSDF"]
eb.inputs["Coat Weight"].default_value = 1.0
eb.inputs["Coat Roughness"].default_value = 0.04
eb.inputs["Roughness"].default_value = 0.25
add_flat_switch(blue, color_socket=mix.outputs["Result"])
add_flat_switch(ether, color=NEW_BLUE)
add_flat_switch(old_ink, color=OLD_INK)


def curve_obj(name, loops, mat, extrude=0.16, bevel=0.06):
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "2D"
    cu.fill_mode = "BOTH"
    cu.extrude = extrude
    cu.bevel_depth = bevel
    cu.bevel_resolution = 6
    cu.resolution_u = 1
    for pts in loops:
        sp = cu.splines.new("POLY")
        sp.points.add(len(pts) - 1)
        for p, (x, y) in zip(sp.points, pts):
            p.co = (x, y, 0, 1)
        sp.use_cyclic_u = True
    obj = bpy.data.objects.new(name, cu)
    scene.collection.objects.link(obj)
    cu.materials.append(mat)
    obj.rotation_euler = (math.radians(90), 0, 0)   # stand up, facing -Y (camera)
    return obj


# pivot that the whole mark spins around
pivot = bpy.data.objects.new("Pivot", None)
scene.collection.objects.link(pivot)

# ---------- the whale: one outline, shape-keyed from old to new ----------
whale = curve_obj("Whale", [outl["old"]], blue)
whale.parent = pivot
whale.shape_key_add(name="Basis")
key = whale.shape_key_add(name="New")
for p, (x, y) in zip(key.data, outl["new"]):
    p.co = (x, y, 0)
morph = whale.data.shape_keys.key_blocks["New"]

# ---------- containers ----------
containers = []
for cx, cy, s in outl["containers"]:
    bpy.ops.mesh.primitive_cube_add(size=1)
    c = bpy.context.object
    c.scale = (s * 0.86, s * 0.86, 0.34)
    bpy.ops.object.transform_apply(scale=True)
    m = c.modifiers.new("Bevel", "BEVEL")
    m.width, m.segments = 0.045, 5
    c.data.materials.append(blue)
    for poly in c.data.polygons:
        poly.use_smooth = True
    c.rotation_euler = (math.radians(90), 0, 0)
    c.location = (cx, 0, cy)
    c.parent = pivot
    containers.append(c)

# ---------- wordmark ----------
word = curve_obj("Wordmark", words["loops"], ether, extrude=0.12, bevel=0.035)

# ---------- original wordmark, one object per letter ----------
def bbox(loop):
    xs = [p[0] for p in loop]; ys = [p[1] for p in loop]
    return min(xs), min(ys), max(xs), max(ys)


groups = []
for loop in sorted(old_words["loops"], key=lambda lp: -(bbox(lp)[2] - bbox(lp)[0]) * (bbox(lp)[3] - bbox(lp)[1])):
    b0 = bbox(loop)
    for g in groups:
        gb = bbox(g[0])
        if gb[0] <= b0[0] and gb[1] <= b0[1] and gb[2] >= b0[2] and gb[3] >= b0[3]:
            g.append(loop)
            break
    else:
        groups.append([loop])
groups.sort(key=lambda g: bbox(g[0])[0])
old_letters = []
for i, g in enumerate(groups):
    cx = (bbox(g[0])[0] + bbox(g[0])[2]) / 2
    cy = (bbox(g[0])[1] + bbox(g[0])[3]) / 2
    letter = curve_obj(f"OldLetter{i}", [[(x - cx, y - cy) for x, y in lp] for lp in g], old_ink, extrude=0.12, bevel=0.035)
    old_letters.append((letter, Vector((cx, 0, cy))))
xs_all = [p[0] for g in groups for lp in g for p in lp] + [p[0] for p in outl["old"]]
OLD_LOCK_X = -(min(xs_all) + max(xs_all)) / 2      # centers the original lockup

# ---------- backdrop + floor reflection ----------
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 30, 0), rotation=(math.radians(90), 0, 0))
bd = bpy.context.object
bg_facs = []


def bg_color_node(nodes, links):
    mx = nodes.new("ShaderNodeMix")
    mx.data_type = "RGBA"
    mx.inputs["A"].default_value = OLD_LIGHT
    mx.inputs["B"].default_value = BASE
    bg_facs.append(mx.inputs["Factor"])
    return mx.outputs["Result"]


vig_socks = []


def vignetted(nodes, links, color_out, scale, amount):
    """color * (1 - amount * (1 - radial)): exact color at the center, darker toward the edges."""
    tc_ = nodes.new("ShaderNodeTexCoord")
    mp_ = nodes.new("ShaderNodeMapping")
    mp_.inputs["Scale"].default_value = scale
    gr_ = nodes.new("ShaderNodeTexGradient")
    gr_.gradient_type = "QUADRATIC_SPHERE"
    links.new(tc_.outputs["Object"], mp_.inputs["Vector"])
    links.new(mp_.outputs["Vector"], gr_.inputs["Vector"])
    inv = nodes.new("ShaderNodeMath"); inv.operation = "SUBTRACT"; inv.inputs[0].default_value = 1.0
    links.new(gr_.outputs["Fac"], inv.inputs[1])
    amt = nodes.new("ShaderNodeMath"); amt.operation = "MULTIPLY"; amt.inputs[1].default_value = amount
    links.new(inv.outputs["Value"], amt.inputs[0])
    vig_socks.append((amt.inputs[1], amount))
    keep = nodes.new("ShaderNodeMath"); keep.operation = "SUBTRACT"; keep.inputs[0].default_value = 1.0
    links.new(amt.outputs["Value"], keep.inputs[1])
    mul = nodes.new("ShaderNodeMix"); mul.data_type = "RGBA"; mul.blend_type = "MULTIPLY"
    mul.inputs["Factor"].default_value = 1.0
    links.new(color_out, mul.inputs["A"])
    links.new(keep.outputs["Value"], mul.inputs["B"])
    return mul.outputs["Result"]


m = bpy.data.materials.new("Backdrop")
m.use_nodes = True
n, l = m.node_tree.nodes, m.node_tree.links
n.remove(n["Principled BSDF"])
em = n.new("ShaderNodeEmission")
l.new(vignetted(n, l, bg_color_node(n, l), (0.035, 0.035, 0.06), 0.28), em.inputs["Color"])
l.new(em.outputs["Emission"], n["Material Output"].inputs["Surface"])
bd.data.materials.append(m)
bd.visible_diffuse = bd.visible_shadow = False

# floor: same flat color as the backdrop, with a faint mirror for the logo's reflection
bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, -1.9))
floor = bpy.context.object
m = bpy.data.materials.new("Floor")
m.use_nodes = True
n, l = m.node_tree.nodes, m.node_tree.links
n.remove(n["Principled BSDF"])
em = n.new("ShaderNodeEmission")
ao = n.new("ShaderNodeAmbientOcclusion")
ao.inputs["Distance"].default_value = 1.4
ao.samples = 16
floor_col = vignetted(n, l, bg_color_node(n, l), (0.05, 0.05, 0.05), 0.35)
l.new(floor_col, ao.inputs["Color"])
shade = n.new("ShaderNodeMix"); shade.data_type = "RGBA"      # AO darkens the floor under the logo
l.new(floor_col, shade.inputs["A"])
l.new(ao.outputs["Color"], shade.inputs["B"])
shade.inputs["Factor"].default_value = 0.8
ao_fac = shade.inputs["Factor"]
l.new(shade.outputs["Result"], em.inputs["Color"])
gloss = n.new("ShaderNodeBsdfGlossy")
gloss.inputs["Roughness"].default_value = 0.08
ms = n.new("ShaderNodeMixShader")
ms.inputs["Fac"].default_value = 0.42
floor_gloss = ms.inputs["Fac"]
l.new(em.outputs["Emission"], ms.inputs[1])
l.new(gloss.outputs["BSDF"], ms.inputs[2])
l.new(ms.outputs["Shader"], n["Material Output"].inputs["Surface"])
floor.data.materials.append(m)

# ---------- world + lights ----------
world = bpy.data.worlds.new("W")
scene.world = world
world.use_nodes = True
n, l = world.node_tree.nodes, world.node_tree.links
env = n.new("ShaderNodeTexEnvironment")
env.image = bpy.data.images.load(os.path.join(HERE, "assets", "studio_small_09.hdr"))
l.new(env.outputs["Color"], n["Background"].inputs["Color"])
n["Background"].inputs["Strength"].default_value = 0.35


def area(loc, energy, sx, sy, color=(1, 1, 1), target=(0, 0, 0)):
    bpy.ops.object.light_add(type="AREA", location=loc)
    L = bpy.context.object
    L.data.shape = "RECTANGLE"
    L.data.size, L.data.size_y = sx, sy
    L.data.energy = energy
    L.data.color = color
    L.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    return L


area((-8, -10, 9), 2200, 8, 5)                                  # key
area((10, -4, 3), 900, 0.8, 14, (0.85, 0.92, 1))                # right strip
area((-10, 4, 3), 900, 0.8, 14, (0.85, 0.92, 1))                # left back strip
area((0, 8, 7), 1600, 12, 3, (0.4, 0.6, 1))                     # blue rim from behind
sweep = area((-14, -9, 1), 0, 1.2, 12, (1, 1, 1))               # light sweep at the reveal

# lights only touch the logo, so the mirror floor shows just the logo's reflection
logo = bpy.data.collections.new("Logo")
for o in [whale, word] + containers + [lt for lt, _ in old_letters]:
    logo.objects.link(o)
for o in scene.objects:
    if o.type == "LIGHT":
        o.light_linking.receiver_collection = logo

# ---------- camera ----------
bpy.ops.object.camera_add()
cam = bpy.context.object
cam.data.lens = 50
scene.camera = cam

# ---------- compositor bloom ----------
ng = bpy.data.node_groups.new("Comp", "CompositorNodeTree")
ng.interface.new_socket("Image", in_out="OUTPUT", socket_type="NodeSocketColor")
scene.compositing_node_group = ng
rl = ng.nodes.new("CompositorNodeRLayers")
gl = ng.nodes.new("CompositorNodeGlare")
gl.inputs["Type"].default_value = "Bloom"
gl.inputs["Threshold"].default_value = 1.0
gl.inputs["Strength"].default_value = 0.03
o = ng.nodes.new("NodeGroupOutput")
ng.links.new(rl.outputs["Image"], gl.inputs["Image"])
ng.links.new(gl.outputs["Image"], o.inputs[0])

# ---------- animation ----------
PRE = 30             # v5: hold the flat old logo, then ease into 3D
TOTAL = 240 + PRE
scene.frame_start, scene.frame_end = 1, TOTAL
LOCK_X = -4.52          # where the new mark sits when the new lockup is centered
D = 30                  # v2 adds this many frames up front for the original lockup + letter exit


def clamp01(t):
    return max(0.0, min(1.0, t))


def ease(t):
    t = clamp01(t)
    return t * t * (3 - 2 * t)


def ease_io(t):
    t = clamp01(t)
    return 4 * t ** 3 if t < 0.5 else 1 - (-2 * t + 2) ** 3 / 2


def back_out(t, k=1.6):
    t = clamp01(t)
    return 1 + (k + 1) * (t - 1) ** 3 + k * (t - 1) ** 2


home = [c.location.copy() for c in containers]
belly = Vector((0.2, 0, -0.4))

for fr in range(1, TOTAL + 1):
    f = fr - PRE                                   # v4 timing, shifted after the flat intro
    flat_in = 1 - ease((fr - 14) / 26)             # 1 = flat old logo, eases to 3D
    # 0. original lockup, centered; then the whale glides to center as the letters leave
    tcen = ease_io((f - 34) / 32)
    base_x = OLD_LOCK_X * (1 - tcen)
    for i, (lt, rest) in enumerate(old_letters):
        t = clamp01((f - 30 - i * 3) / 18)
        hop = math.sin(math.pi * min(t * 1.6, 1)) * 0.5               # small pop up...
        lt.location = Vector((OLD_LOCK_X, 0, 0)) + rest + Vector((0.6 * ease(t), -1.5 * ease(t), hop - 1.6 * ease(t) ** 2))
        lt.rotation_euler = (math.radians(90) - 2.2 * ease(t), 0, 0.6 * ease(t))   # ...then tumbles away
        sc = 1 - ease((t - 0.3) / 0.7)
        lt.scale = (sc, sc, sc)
        lt.keyframe_insert("location", frame=fr)
        lt.keyframe_insert("rotation_euler", frame=fr)
        lt.keyframe_insert("scale", frame=fr)
    # 1. idle: slow turn
    turn = (math.radians(-14) + math.radians(8) * ease(f / (40 + D))) * (1 - flat_in)   # dead straight while flat
    # 2. containers lift off, spin and shrink into the whale (staggered)
    for i, c in enumerate(containers):
        t = clamp01((f - 34 - D - i * 2.5) / 26)
        lift = math.sin(math.pi * min(t * 1.4, 1)) * 0.9
        c.location = home[i].lerp(belly, ease(t)) + Vector((0, 0, lift))
        c.rotation_euler = (math.radians(90) + 3 * ease(t), 2 * ease(t), 0)
        sc = 1 - ease((t - 0.35) / 0.65)
        c.scale = (sc, sc, sc)
        c.keyframe_insert("location", frame=fr)
        c.keyframe_insert("rotation_euler", frame=fr)
        c.keyframe_insert("scale", frame=fr)
    # 3. morph with a full spin around the vertical axis
    morph.value = ease_io((f - 62 - D) / 48)
    morph.keyframe_insert("value", frame=fr)
    cf = ease((f - 74 - D) / 30)
    color_fac.default_value = cf
    color_fac.keyframe_insert("default_value", frame=fr)
    # final second: ease everything into flat, exact "Ether on Base"
    fl = max(ease((f - 206) / 22), flat_in)
    for fs in flat_facs:
        fs.default_value = fl
        fs.keyframe_insert("default_value", frame=fr)
    for sock, amount in vig_socks:
        sock.default_value = amount * (1 - fl)
        sock.keyframe_insert("default_value", frame=fr)
    floor_gloss.default_value = 0.42 * (1 - fl)
    floor_gloss.keyframe_insert("default_value", frame=fr)
    ao_fac.default_value = 0.8 * (1 - fl)
    ao_fac.keyframe_insert("default_value", frame=fr)
    for bf in bg_facs:
        bf.default_value = cf
        bf.keyframe_insert("default_value", frame=fr)
    spin = 2 * math.pi * ease_io((f - 58 - D) / 56)
    pop = 1 + 0.08 * math.sin(math.pi * clamp01((f - 104 - D) / 16))
    pivot.rotation_euler = (0, 0, turn * (1 - ease((f - 110 - D) / 20)) + spin)
    pivot.scale = (pop, pop, pop)
    # 4. slide left as the new wordmark rises in
    ts = ease_io((f - 122 - D) / 34)
    pivot.location = (base_x + LOCK_X * ts, 0, 0)
    pivot.keyframe_insert("rotation_euler", frame=fr)
    pivot.keyframe_insert("scale", frame=fr)
    pivot.keyframe_insert("location", frame=fr)
    tw = back_out((f - 130 - D) / 26, 1.2)
    word.location = (LOCK_X * ts, 0, -1.4 * (1 - tw))
    ws = clamp01(tw)
    word.scale = (ws, ws, ws)
    word.keyframe_insert("location", frame=fr)
    word.keyframe_insert("scale", frame=fr)
    # light sweep across the new logo (softer than v1)
    sw = clamp01((f - 108 - D) / 26)
    sweep.location = (-14 + 28 * sw, -9, 1)
    sweep.data.energy = 320 * math.sin(math.pi * sw)
    sweep.rotation_euler = (Vector((0, 0, 0)) - sweep.location).to_track_quat("-Z", "Y").to_euler()
    sweep.keyframe_insert("location", frame=fr)
    sweep.keyframe_insert("rotation_euler", frame=fr)
    sweep.data.keyframe_insert("energy", frame=fr)
    # camera: wide on the original lockup, pushes in for the morph, pulls back for the new lockup
    push = ease_io((f - 34) / 34)
    pull = ease_io((f - 118 - D) / 40)
    dist = 25 - 11 * push + 11 * pull
    cam.location = (0, -dist, 0.8 + 0.6 * (dist - 14) / 11)
    cam.rotation_euler = (Vector((0, 0, -0.1)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.keyframe_insert("location", frame=fr)
    cam.keyframe_insert("rotation_euler", frame=fr)

os.makedirs(frames_dir, exist_ok=True)
frames = [only] if only else range(1, TOTAL + 1, step)
for f in frames:
    scene.frame_set(f)
    scene.render.filepath = os.path.join(frames_dir, f"{f:04d}.png")
    bpy.ops.render.render(write_still=True)
