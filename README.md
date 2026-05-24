# Crop Field 3D Gaussian Splatting Reconstruction

A 3D reconstruction of a crop field using drone imagery and 3D Gaussian Splatting (3DGS). This project uses the [gsplat 3DGUT](https://github.com/jonstephens85/gsplat_3dgut) framework to reconstruct a photorealistic 3D scene from 248 DJI drone images.

## 📽️ Result Preview

[![Crop Field 3DGS Preview](https://img.youtube.com/vi/-NlKIbTkc24/0.jpg)](https://www.youtube.com/watch?v=-NlKIbTkc24)

## Dataset

| Property | Value |
|---|---|
| Camera | DJI Drone |
| Images | 248 (86 nadir + 162 oblique) |
| Resolution | 5472 × 3078 px |
| Focal Length | 3482.29 px (PINHOLE) |
| Location | Spain (LAT ~41.444, LON ~-4.898) |
| Altitude | ~797 m |

---

## Methodology

The project follows a classic photogrammetry-to-neural-rendering pipeline:

```
Drone Images → COLMAP SfM → Sparse Point Cloud → 3D Gaussian Splatting → 3D Scene
```

### Step 1 — Image Preparation
- Combined 86 nadir (top-down) and 162 oblique drone images into a single folder
- Images were captured by a DJI drone at ~797m altitude over a crop field in Spain
- GPS coordinates and gravity vectors were embedded in the EXIF metadata and used by COLMAP as pose priors

### Step 2 — Structure from Motion (SfM) with COLMAP
- **Feature Extraction:** SIFT features extracted from all 248 images (8,000–13,000 keypoints per image) using GPU-accelerated COLMAP
- **Feature Matching:** Sequential matcher was chosen over exhaustive matcher because drone survey images follow a flight path — sequential matching connects adjacent frames efficiently and uses loop detection to close the trajectory
- **Sparse Reconstruction (Mapper):** COLMAP's incremental mapper registered 247/248 images and triangulated 202,472 3D points from the matched features
- **Key fix:** COLMAP produced two reconstructions (`sparse/0` with 4 images, `sparse/1` with 247 images) — the larger reconstruction in `sparse/1` was used for training

### Step 3 — Image Downscaling
- Original images (5472×3078) were downscaled by 4× to 1368×770 to fit within 8GB VRAM
- Downscaled images stored in `images_4/` folder for training

### Step 4 — 3D Gaussian Splatting Training
- **Initialization:** 202,472 Gaussians initialized from the COLMAP sparse point cloud
- **Optimization:** 30,000 steps of gradient descent optimizing position, scale, rotation, opacity, and spherical harmonic color coefficients of each Gaussian
- **Densification:** Gaussians are periodically split, duplicated, and pruned based on gradient magnitude and opacity thresholds
- **Strategy:** Default 3DGS densification strategy following the original paper
- By step 1999, the model grew from 202,472 to 1,781,742 Gaussians

### Step 5 — Evaluation & Visualization
- Metrics computed: PSNR, SSIM, LPIPS on held-out test images
- Trajectory video rendered along an interpolated camera path
- PLY files exportable for viewing in SuperSplat or MeshLab

---

## Pipeline Commands

### 1. Environment Setup

- Windows 11
- NVIDIA RTX 2000 Ada (8GB VRAM)
- CUDA Toolkit 12.6 — download from [NVIDIA CUDA Downloads](https://developer.nvidia.com/cuda-downloads)
- Visual Studio 2026 (MSVC 14.36)
- Python 3.10 (Miniconda)

```bash
# Verify CUDA installation
nvcc --version

# Set CUDA environment variables (Windows)
set CUDA_HOME=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.6
set CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.6
set DISTUTILS_USE_SDK=1

# Create conda environment
conda create -n gsplat python=3.10
conda activate gsplat

# Activate Visual Studio compiler (required for Windows CUDA builds)
call "C:\Program Files\Microsoft Visual Studio\18\Professional\VC\Auxiliary\Build\vcvarsall.bat" x64 -vcvars_ver=14.36

# Clone and install gsplat
git clone https://github.com/jonstephens85/gsplat_3dgut
cd gsplat_3dgut
pip install -e .
```

### 2. COLMAP Reconstruction

```bash
# Feature extraction
colmap feature_extractor \
  --database_path dataset/database.db \
  --image_path dataset/images \
  --ImageReader.camera_model PINHOLE \
  --ImageReader.single_camera 1 \
  --SiftExtraction.max_num_features 8192

# Sequential matching with loop detection
colmap sequential_matcher \
  --database_path dataset/database.db \
  --SequentialMatching.overlap 20 \
  --SequentialMatching.loop_detection 1

# Sparse reconstruction
colmap mapper \
  --database_path dataset/database.db \
  --image_path dataset/images \
  --output_path dataset/sparse \
  --Mapper.init_min_tri_angle 4

# Convert binary to text format
colmap model_converter \
  --input_path dataset/sparse/1 \
  --output_path dataset/sparse/0 \
  --output_type TXT
```

**Result:** 247/248 images registered, 202,472 3D points

### 3. Downscale Images

```bash
python -c "
import os
from PIL import Image
os.makedirs('dataset/images_4', exist_ok=True)
src = 'dataset/images'
dst = 'dataset/images_4'
files = [f for f in os.listdir(src) if f.endswith('.JPG')]
for i, f in enumerate(files):
    img = Image.open(os.path.join(src, f))
    w, h = img.size
    img = img.resize((w//4, h//4), Image.LANCZOS)
    img.save(os.path.join(dst, f))
    print(f'[{i+1}/{len(files)}] {f}')
print('Done!')
"
```

### 4. 3D Gaussian Splatting Training

```bash
set PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

python examples/simple_trainer.py default \
  --data_dir "dataset" \
  --data_factor 4 \
  --result_dir "results/cropfield" \
  --camera_model pinhole \
  --save_ply \
  --save-steps 7000 30000 \
  --ply-steps 7000 30000 \
  --packed \
  --disable-viewer
```

---

## 📊 Results

| Step | PSNR | SSIM | LPIPS | # Gaussians |
|------|------|------|-------|-------------|
| 1999 | 20.97 | 0.457 | 0.666 | 1,781,742 |

---

## Hardware Requirements

| Component | Minimum | Used |
|---|---|---|
| GPU VRAM | 8 GB | 8 GB (RTX 2000 Ada) |
| RAM | 16 GB | 31.5 GB |
| Storage | 20 GB | ~10 GB |

---

## Output Files

```
results/cropfield/
├── ckpts/          # Model checkpoints (.pt files)
├── ply/            # Gaussian splat point clouds (.ply files)
├── videos/         # Rendered trajectory videos (.mp4)
└── stats/          # Training metrics (PSNR, SSIM, LPIPS)
```

---

## Viewing Results

### Online Viewer (No Install)
Upload the `.ply` file to **[SuperSplat](https://supersplat.playcanvas.com/)** and view in the browser.

### Live Viewer During Training
Open `http://localhost:8080` in your browser while training is running.

## References

- [gsplat 3DGUT](https://github.com/jonstephens85/gsplat_3dgut)
- [3D Gaussian Splatting (Kerbl et al., 2023)](https://arxiv.org/abs/2308.04079)
- [COLMAP SfM](https://colmap.github.io/)
- [SuperSplat Viewer](https://supersplat.playcanvas.com/)
- [Dataset — Crop Field Drone Images (Zenodo)](https://zenodo.org/records/7271542#.Y2ZE03bMJhE)

---

## License

MIT License
