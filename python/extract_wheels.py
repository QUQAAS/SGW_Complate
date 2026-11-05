#!/usr/bin/env python3
"""
KN5 dosyalarından jant mesh'lerini (lastiksiz) ayıran script.
Assetto Corsa content/cars klasörünü tarar.
Gereksinim: pip install pyassimp numpy
"""

import os
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import pyassimp
import numpy as np

CONTENT_CARS = Path(os.environ.get('AC_CARS_PATH', 'C:/Program Files (x86)/Steam/steamapps/common/assettocorsa/content/cars'))
OUTPUT_DIR = Path(__file__).parent / 'output'
OUTPUT_DIR.mkdir(exist_ok=True)

WHEEL_KEYWORDS = ['RIM', 'WHEEL', 'JANT', 'DISC', 'BRAKE', 'CALIPER']
TIRE_KEYWORDS = ['TYRE', 'TIRE', 'LASTIK', 'SIDEWALL']

def is_wheel_mesh(name: str) -> bool:
    name_upper = name.upper()
    if any(kw in name_upper for kw in TIRE_KEYWORDS):
        return False
    return any(kw in name_upper for kw in WHEEL_KEYWORDS)

def get_wheel_position(mesh) -> Tuple[float, float, float]:
    if mesh.vertices.size == 0:
        return (0, 0, 0)
    verts = mesh.vertices
    center = np.mean(verts, axis=0)
    return (float(center[0]), float(center[1]), float(center[2]))

def estimate_wheel_radius(mesh) -> float:
    if mesh.vertices.size == 0:
        return 0.33
    verts = mesh.vertices
    center_xz = np.mean(verts[:, [0, 2]], axis=0)
    distances = np.linalg.norm(verts[:, [0, 2]] - center_xz, axis=1)
    return float(np.max(distances))

def parse_tyres_ini(car_path: Path) -> dict:
    tyres_path = car_path / 'data' / 'tyres.ini'
    if not tyres_path.exists():
        return {'radius': 0.33, 'width': 0.25}

    data = {'radius': 0.33, 'width': 0.25}
    current_section = ''

    with open(tyres_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if line.startswith('[') and line.endswith(']'):
                current_section = line[1:-1]
            elif '=' in line and current_section.startswith('TYRE'):
                key, val = line.split('=', 1)
                key = key.strip().upper()
                val = val.strip()
                if key == 'RADIUS':
                    data['radius'] = float(val)
                elif key == 'WIDTH':
                    data['width'] = float(val)
    return data

def parse_suspensions_ini(car_path: Path) -> dict:
    susp_path = car_path / 'data' / 'suspensions.ini'
    if not susp_path.exists():
        return {'front_track': 1.5, 'rear_track': 1.5}

    data = {'front_track': 1.5, 'rear_track': 1.5}
    current_section = ''

    with open(susp_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if line.startswith('[') and line.endswith(']'):
                current_section = line[1:-1]
            elif '=' in line:
                key, val = line.split('=', 1)
                key = key.strip().upper()
                val = val.strip()
                if current_section == 'FRONT' and key == 'TRACK':
                    data['front_track'] = float(val)
                elif current_section == 'REAR' and key == 'TRACK':
                    data['rear_track'] = float(val)
    return data

def extract_car_wheels(car_dir: Path) -> Optional[dict]:
    kn5_files = list(car_dir.glob('*.kn5'))
    if (car_dir / 'kn5').exists():
        kn5_files += list((car_dir / 'kn5').glob('*.kn5'))

    if not kn5_files:
        return None

    main_kn5 = max(kn5_files, key=lambda f: f.stat().st_size)

    try:
        scene = pyassimp.load(str(main_kn5), processing=pyassimp.postprocess.aiProcess_Triangulate)
    except Exception as e:
        print(f"  ✗ KN5 yüklenemedi: {main_kn5.name} - {e}")
        return None

    car_name = car_dir.name
    tyre_data = parse_tyres_ini(car_dir)
    susp_data = parse_suspensions_ini(car_dir)

    wheels = []
    for mesh in scene.meshes:
        if is_wheel_mesh(mesh.name):
            pos = get_wheel_position(mesh)
            radius = estimate_wheel_radius(mesh)

            wheel_type = 'unknown'
            if pos[0] > 0 and pos[2] > 0: wheel_type = 'FL'
            elif pos[0] < 0 and pos[2] > 0: wheel_type = 'FR'
            elif pos[0] > 0 and pos[2] < 0: wheel_type = 'RL'
            elif pos[0] < 0 and pos[2] < 0: wheel_type = 'RR'

            wheels.append({
                'mesh_name': mesh.name,
                'type': wheel_type,
                'position': pos,
                'estimated_radius': radius,
                'vertex_count': len(mesh.vertices),
                'face_count': len(mesh.faces) if hasattr(mesh, 'faces') else 0
            })

    pyassimp.release(scene)

    if not wheels:
        return None

    return {
        'car': car_name,
        'kn5_file': main_kn5.name,
        'tyre_radius': tyre_data['radius'],
        'tyre_width': tyre_data['width'],
        'front_track': susp_data['front_track'],
        'rear_track': susp_data['rear_track'],
        'wheels': wheels
    }

def main():
    print(f"Scanning: {CONTENT_CARS}")
    print(f"Output: {OUTPUT_DIR}")

    all_wheels = {}
    failed = []
    car_dirs = [d for d in CONTENT_CARS.iterdir() if d.is_dir()]

    for i, car_dir in enumerate(car_dirs):
        print(f"[{i+1}/{len(car_dirs)}] {car_dir.name}...", end=' ')
        result = extract_car_wheels(car_dir)
        if result:
            all_wheels[car_dir.name] = result
            print(f"✓ {len(result['wheels'])} jant bulundu")
        else:
            failed.append(car_dir.name)
            print("✗ Jant bulunamadı/KN5 yok")

    index_file = OUTPUT_DIR / 'wheels_index.json'
    with open(index_file, 'w', encoding='utf-8') as f:
        json.dump(all_wheels, f, indent=2, ensure_ascii=False)

    failed_file = OUTPUT_DIR / 'failed_cars.txt'
    with open(failed_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(failed))

    print(f"\n=== TAMAMLANDI ===")
    print(f"Başarılı: {len(all_wheels)} araç")
    print(f"Başarısız: {len(failed)} araç")
    print(f"Index: {index_file}")
    print(f"Failed list: {failed_file}")

if __name__ == '__main__':
    main()