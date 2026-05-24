"""
prepare_dataset.py
------------------
Prepares the crop field dataset for 3DGS training:
1. Combines nadir and oblique images into one folder
2. Creates downscaled versions (images_2, images_4)

Usage:
    python prepare_dataset.py --src_nadir PATH --src_oblique PATH --dst PATH
"""

import os
import argparse
import shutil
from PIL import Image
from tqdm import tqdm


def combine_images(src_nadir, src_oblique, dst):
    os.makedirs(dst, exist_ok=True)
    all_files = []

    for folder in [src_nadir, src_oblique]:
        files = [f for f in os.listdir(folder) if f.upper().endswith('.JPG')]
        for f in files:
            all_files.append(os.path.join(folder, f))

    print(f"Copying {len(all_files)} images to {dst}...")
    for src_file in tqdm(all_files):
        shutil.copy2(src_file, dst)

    print(f"Done. {len(all_files)} images copied.")
    return len(all_files)


def downscale_images(src, dst, factor):
    os.makedirs(dst, exist_ok=True)
    files = [f for f in os.listdir(src) if f.upper().endswith('.JPG')]

    print(f"Downscaling {len(files)} images by {factor}x to {dst}...")
    for f in tqdm(files):
        img = Image.open(os.path.join(src, f))
        w, h = img.size
        img = img.resize((w // factor, h // factor), Image.LANCZOS)
        img.save(os.path.join(dst, f))

    print(f"Done. {len(files)} images saved at 1/{factor} resolution.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--src_nadir", required=True, help="Path to nadir images folder")
    parser.add_argument("--src_oblique", required=True, help="Path to oblique images folder")
    parser.add_argument("--dst", required=True, help="Output dataset folder")
    args = parser.parse_args()

    images_dir = os.path.join(args.dst, "images")
    combine_images(args.src_nadir, args.src_oblique, images_dir)

    downscale_images(images_dir, os.path.join(args.dst, "images_2"), factor=2)
    downscale_images(images_dir, os.path.join(args.dst, "images_4"), factor=4)

    print("\nDataset ready! Run COLMAP next.")
