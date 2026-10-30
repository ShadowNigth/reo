#!/usr/bin/env python3
"""One-time preparation of DOWNLOADED assets. Does not generate replacement art.
Sources and pinned revisions are recorded in docs/THIRD_PARTY_NOTICES.md.
Set UMBRAL_DOWNLOADS to the directory containing hangar-source and kenney-all.
Requires Pillow. OBJ->glTF conversion preserves positions, normals and material colors.
"""
from pathlib import Path
import os, json, re, struct, shutil, base64
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'game/assets'
SRC = Path(os.environ.get('UMBRAL_DOWNLOADS', '/home/user/downloads'))

def copy(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.exists(): shutil.copy2(src, dst)

def prepare_textures():
    folder = SRC / 'hangar-source/Materials'
    pairs = [('Utrim_Concrete/utrim_concrete_1_Albedo.png', 'concrete_albedo.jpg', 2048),
             ('Utrim_Concrete/utrim_concrete_1_NormalMap.png', 'concrete_normal.jpg', 2048),
             ('Utrim_Concrete/utrim_concrete_1_ORM.png', 'concrete_orm.jpg', 1024),
             ('Utrim_SpaceShip/utrim_spaceship_1_Albedo.png', 'metal_albedo.jpg', 2048),
             ('Utrim_SpaceShip/utrim_spaceship_1_NormalMap.png', 'metal_normal.jpg', 2048),
             ('Utrim_SpaceShip/utrim_spaceship_1_ORM.png', 'metal_orm.jpg', 1024),
             ('Outside/brown_mud_leaves_01_diff_1k.jpg', 'ground_albedo.jpg', 1024),
             ('Outside/brown_mud_leaves_01_nor_gl_1k.png', 'ground_normal.jpg', 1024),
             ('Vegetation/Vegetation_Albedo.png', 'vegetation_albedo.png', 1024),
             ('Vegetation/Vegetation_Normal.png', 'vegetation_normal.jpg', 1024)]
    for src, name, size in pairs:
        p = folder / src
        if not p.exists(): continue
        im = Image.open(p)
        im.thumbnail((size, size), Image.Resampling.LANCZOS)
        alpha = im.mode == 'RGBA' and im.getchannel('A').getextrema()[0] < 255
        dest = OUT / 'world' / name
        if alpha and dest.suffix == '.png': im.save(dest, optimize=True)
        elif dest.suffix == '.png': im.convert('RGB').save(dest, optimize=True)
        else: im.convert('RGB').save(dest, quality=89, optimize=True)
    copy(folder.parent / 'LICENSE', OUT / 'world/HANGAR_LICENSE.txt')

def obj_to_glb(path, dest):
    mats = {}
    cur = 'default'
    groups = {}
    vs, ns = [], []
    for line in path.read_text(errors='replace').splitlines():
        a = line.split()
        if not a: continue
        if a[0] == 'mtllib':
            mp = path.parent / a[1]
            if mp.exists():
                for l in mp.read_text().splitlines():
                    b = l.split()
                    if not b: continue
                    if b[0] == 'newmtl': cur = b[1]
                    elif b[0] == 'Kd': mats[cur] = [float(x) for x in b[1:4]]
        elif a[0] == 'v': vs.append([float(x) for x in a[1:4]])
        elif a[0] == 'vn': ns.append([float(x) for x in a[1:4]])
        elif a[0] == 'usemtl': cur = a[1]
        elif a[0] == 'f':
            face = []
            for token in a[1:]:
                b = token.split('/')
                vi = int(b[0])-1
                ni = int(b[2])-1 if len(b[2:]) and b[2] else 0
                face.append((vi, ni))
            for k in range(1, len(face)-1):
                for vi, ni in (face[0], face[k], face[k+1]):
                    groups.setdefault(cur, []).append((vs[vi], ns[ni] if ns else [0,1,0]))
    doc = {'asset':{'version':'2.0','generator':'UMBRAL downloaded OBJ format conversion'},
           'scene':0,'scenes':[{'nodes':[0]}],'nodes':[{'mesh':0,'name':path.stem}],
           'meshes':[{'name':path.stem,'primitives':[]}],'materials':[], 'accessors':[], 'bufferViews':[], 'buffers':[]}
    blob = bytearray()
    def accessor(values, typ, bounds=False):
        nonlocal blob
        while len(blob)%4: blob.append(0)
        offset=len(blob)
        for v in values: blob.extend(struct.pack('<fff', *v))
        doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(blob)-offset,'target':34962})
        a={'bufferView':len(doc['bufferViews'])-1,'componentType':5126,'count':len(values),'type':typ}
        if bounds:
            a['min']=[min(v[i] for v in values) for i in range(3)]
            a['max']=[max(v[i] for v in values) for i in range(3)]
        doc['accessors'].append(a)
        return len(doc['accessors'])-1
    for name, verts in groups.items():
        color=mats.get(name,[.4,.4,.4])
        # Preserve relative paint shades; oxidized gunmetal rather than toy white.
        base=[.07+x*.33 for x in color]
        doc['materials'].append({'name':name,'pbrMetallicRoughness':{'baseColorFactor':base+[1], 'metallicFactor':.65,'roughnessFactor':.49},'doubleSided':True})
        p=accessor([v[0] for v in verts],'VEC3',True)
        n=accessor([v[1] for v in verts],'VEC3')
        doc['meshes'][0]['primitives'].append({'attributes':{'POSITION':p,'NORMAL':n},'material':len(doc['materials'])-1})
    doc['buffers']=[{'byteLength':len(blob)}]
    js=json.dumps(doc,separators=(',',':')).encode(); js+=b' '*((-len(js))%4)
    blob+=b'\0'*((-len(blob))%4)
    data=struct.pack('<III',0x46546c67,2,12+8+len(js)+8+len(blob))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(blob),0x004e4942)+blob
    dest.write_bytes(data)

def transform(values):
    a=[float(x) for x in values.split(',')][:12]
    if len(a) != 12: a = [1,0,0,0,1,0,0,0,1,0,0,0]
    return [a[0],a[3],a[6],a[1],a[4],a[7],a[2],a[5],a[8],a[9],a[10],a[11]]

def scene_instances(path, names):
    text=path.read_text()
    refs={i:p for p,i in re.findall(r'\[ext_resource[^\n]*path="([^"]+)"[^\n]*id="([^"]+)"',text)}
    result=[]
    for m in re.finditer(r'\[node name="([^"]+)"[^\n]*parent="([^"]+)"[^\n]*instance=ExtResource\("([^"]+)"\)[^\n]*\]([^\[]*)',text):
        name,parent,rid,body=m.groups()
        p=refs.get(rid,'')
        mesh=Path(p).stem
        aliases={'barrel':'Barrel','barrel_open':'Barrel_Open','container':'Container','largeContainer':'LargeContainer','cinderBlocks':'CinderBlocks','brokenChunks':'BrokenChunks','brokenPillar':'BrokenPillar','brokenSlabs':'BrokenSlab','rubble_large':'Rubble_large','rubble_medium':'Rubble_medium','rubble_pile':'Rubble_pile','rubble_small':'Rubble_small','rubble_small_wide':'Rubble_small_wide','steelPiece2':'SteelPiece2','pipe1':'Pipe1','pipe2':'Pipe2','pipe3':'Pipe3','pipe4':'Pipe4','ivy_tall':'Ivy_Tall','ivy_wide':'Ivy_Wide','ivy_corner':'Ivy_Corner','fern':'Fern'}
        mesh=aliases.get(mesh,mesh)
        if mesh not in names: continue
        tm=re.search(r'transform = Transform3D\(([^)]+)\)',body)
        result.append({'name':name,'parent':parent,'mesh':mesh,'transform':transform(tm.group(1)) if tm else [1,0,0,0,1,0,0,0,1,0,0,0]})
    return result

if __name__=='__main__':
    for d in ['world','weapons','audio','fx','models','fonts']: (OUT/d).mkdir(parents=True,exist_ok=True)
    prepare_textures()
    for name in ['SpaceCraftHangar','Objects','Outside']:
        copy(SRC/'hangar-source/Models'/f'{name}.glb',OUT/'world'/f'{name}.glb')
    names={'Barrel','Barrel_Open','Container','LargeContainer','CinderBlocks','BrokenChunks','BrokenPillar','BrokenSlab','Rubble_large','Rubble_medium','Rubble_pile','Rubble_small','Rubble_small_wide','SteelPiece2','Pipe1','Pipe2','Pipe3','Pipe4','Ivy_Tall','Ivy_Wide','Ivy_Corner','Fern'}
    props=scene_instances(SRC/'hangar-source/Scenes/Environment/objects.tscn',names)
    props+=scene_instances(SRC/'hangar-source/Scenes/Hangar.tscn',names)
    (OUT/'world/layout.json').write_text(json.dumps(props,indent=2))
    for p in (SRC/'kenney-all/weaponpack_assets/Models').glob('*.obj'):
        obj_to_glb(p,OUT/'weapons'/f'{p.stem}.glb')
    for p in (SRC/'assets').glob('*.glb'):
        copy(p,OUT/'models'/p.name)
    for p in (SRC/'kenney/models').glob('blaster*.glb'): copy(p,OUT/'weapons'/p.name)
    for p in (SRC/'kenney/sounds').glob('*.ogg'): copy(p,OUT/'audio'/p.name)
    for p in (SRC/'audio').glob('*__*'): copy(p,OUT/'audio'/p.name.split('__',1)[1])
    for name in ['circle_05','dirt_03','fire_01','flare_01','smoke_01','star_08','trace_01','slash_01','scorch_01','window_01']:
        for p in (SRC/'kenney-all/particlePack_1.1/PNG (Transparent)').glob(name+'*'):
            copy(p,OUT/'fx'/p.name)
    for p in (SRC/'kenney/fonts').glob('*.ttf'): copy(p,OUT/'fonts'/p.name)
    for src,dst in [('kenney-all/weaponpack_assets/License.txt','weapons/KENNEY_LICENSE.txt'),('kenney-all/particlePack_1.1/License.txt','fx/KENNEY_LICENSE.txt'),('sfx/ATTRIBUTION.md','audio/ATTRIBUTION.md'),('sfx/SOURCES.md','audio/SOURCES.md'),('assets/NOTICE.md','models/UPSTREAM_NOTICE.md')]:
        copy(SRC/src,OUT/dst)
    print(f'Prepared {len(props)} original map prop placements and downloaded asset conversions.')
