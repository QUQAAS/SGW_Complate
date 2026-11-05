#!/usr/bin/env python3
"""
Her arabanın karoseri dokusundan (body.dds, skin_00.dds vb.)
seçilen renklerde yeni skin klasörleri üreten script.
Gereksinim: pip install pillow numpy
"""

import os
import shutil
from pathlib import Path
from PIL import Image
import numpy as np

CONTENT_CARS = Path(os.environ.get('AC_CARS_PATH', 'C:/Program Files (x86)/Steam/steamapps/common/assettocorsa/content/cars'))

SGW_COLORS = {
    'Kırmızı': (217, 38, 38),
    'Siyah': (20, 20, 20),
    'Beyaz': (245, 245, 245),
    'Gri': (120, 120, 120),
    'Altın': (255, 200, 0),
    'Mat_Siyah': (30, 30, 30),
    'Mat_Kırmızı': (180, 30, 30),
}

def find_body_texture(car_dir: Path) -> Path:
    patterns = ['*body*.dds', '*skin*.dds', '*paint*.dds', '*.dds']
    for pattern in patterns:
        files = list(car_dir.rglob(pattern))
        if files:
            return max(files, key=lambda f: f.stat().st_size)
    return None

def colorize_texture(source_path: Path, target_color: tuple, output_path: Path, preserve_alpha=True):
    img = Image.open(source_path).convert('RGBA')
    arr = np.array(img, dtype=np.float32) / 255.0

    target = np.array(target_color, dtype=np.float32) / 255.0

    luminance = 0.299 * arr[:,:,0] + 0.587 * arr[:,:,1] + 0.114 * arr[:,:,2]
    luminance = luminance[:,:,np.newaxis]

    saturation = np.max(arr[:,:,:3], axis=2) - np.min(arr[:,:,:3], axis=2)
    is_gray = saturation < 0.15

    new_arr = arr.copy()
    for c in range(3):
        new_arr[:,:,c] = np.where(is_gray, luminance[:,:,0] * target[c], arr[:,:,c])

    if preserve_alpha:
        new_arr[:,:,3] = arr[:,:,3]

    result = Image.fromarray((new_arr * 255).astype(np.uint8), 'RGBA')
    result.save(output_path, 'DDS' if output_path.suffix == '.dds' else 'PNG')

def generate_car_skins(car_dir: Path):
    car_name = car_dir.name
    body_tex = find_body_texture(car_dir)

    if not body_tex:
        print(f"  ✗ {car_name}: Karoseri dokusu bulunamadı")
        return

    print(f"  ✓ {car_name}: {body_tex.name} -> {len(SGW_COLORS)} renk")

    skins_dir = car_dir / 'skins'
    if not skins_dir.exists():
        skins_dir = car_dir

    template_ini = None
    for skin_folder in skins_dir.iterdir():
        if skin_folder.is_dir():
            ini_files = list(skin_folder.glob('skin.ini'))
            if ini_files:
                template_ini = ini_files[0]
                break

    for color_name, color_rgb in SGW_COLORS.items():
        safe_color = color_name.lower().replace(' ', '_').replace('ş', 's').replace('ı', 'i')
        new_skin_name = f"SGW_{safe_color}"
        new_skin_dir = skins_dir / new_skin_name

        if new_skin_dir.exists():
            shutil.rmtree(new_skin_dir)
        new_skin_dir.mkdir(parents=True)

        output_tex = new_skin_dir / body_tex.name
        colorize_texture(body_tex, color_rgb, output_tex)

        if template_ini:
            shutil.copy(template_ini, new_skin_dir / 'skin.ini')
            ini_content = (new_skin_dir / 'skin.ini').read_text(encoding='utf-8', errors='ignore')
            ini_content = ini_content.replace('name=', f'name={new_skin_name}\n')
            (new_skin_dir / 'skin.ini').write_text(ini_content, encoding='utf-8')
        else:
            (new_skin_dir / 'skin.ini').write_text(f"""[SKIN]
name={new_skin_name}
description=Sönmez Game World - {color_name}
""", encoding='utf-8')

        preview = new_skin_dir / 'preview.jpg'
        img = Image.open(body_tex)
        img.thumbnail((256, 144))
        img.convert('RGB').save(preview, 'JPEG', quality=85)

def main():
    print(f"Generating skins from: {CONTENT_CARS}")

    car_dirs = [d for d in CONTENT_CARS.iterdir() if d.is_dir()]

    for car_dir in car_dirs:
        try:
            generate_car_skins(car_dir)
        except Exception as e:
            print(f"  ✗ {car_dir.name}: Hata - {e}")

    print("\n=== TAMAMLANDI ===")

if __name__ == '__main__':
    main()