@echo off
echo ============================================
echo   Crop Field 3DGS - Training Script
echo ============================================

:: Activate Miniconda
call C:\Users\%USERNAME%\AppData\Local\miniconda3\Scripts\activate.bat
call conda activate gsplat

:: Activate Visual Studio compiler
call "C:\Program Files\Microsoft Visual Studio\18\Professional\VC\Auxiliary\Build\vcvarsall.bat" x64 -vcvars_ver=14.36

:: Set environment variables
set DISTUTILS_USE_SDK=1
set CUDA_HOME=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.6
set CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.6
set PATH=%PATH%;C:\Windows\System32
set PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

:: Go to gsplat directory
cd C:\Users\%USERNAME%\gsplat

echo.
echo Starting training...
echo Results will be saved to E:\gsplate\results\cropfield
echo.

python examples/simple_trainer.py default ^
  --data_dir "E:\gsplate\dataset" ^
  --data_factor 4 ^
  --result_dir "E:\gsplate\results\cropfield" ^
  --camera_model pinhole ^
  --save_ply ^
  --save-steps 7000 30000 ^
  --ply-steps 7000 30000 ^
  --packed ^
  --disable-viewer

echo.
echo Training complete!
pause
