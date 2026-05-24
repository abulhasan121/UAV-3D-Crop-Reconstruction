@echo off
echo ============================================
echo   Crop Field 3DGS - COLMAP Pipeline
echo ============================================

:: Set COLMAP path
set COLMAP_BIN=E:\pecan_processing\new kg\colmap-x64-windows-cuda\bin
set PATH=%PATH%;%COLMAP_BIN%;C:\Windows\System32

:: Set dataset path
set DATASET=E:\gsplate\dataset

echo.
echo [1/3] Feature Extraction...
colmap feature_extractor ^
  --database_path "%DATASET%\database.db" ^
  --image_path "%DATASET%\images" ^
  --ImageReader.camera_model PINHOLE ^
  --ImageReader.single_camera 1 ^
  --SiftExtraction.max_num_features 8192

echo.
echo [2/3] Sequential Matching...
colmap sequential_matcher ^
  --database_path "%DATASET%\database.db" ^
  --SequentialMatching.overlap 20 ^
  --SequentialMatching.loop_detection 1

echo.
echo [3/3] Sparse Reconstruction (Mapper)...
mkdir "%DATASET%\sparse"
colmap mapper ^
  --database_path "%DATASET%\database.db" ^
  --image_path "%DATASET%\images" ^
  --output_path "%DATASET%\sparse" ^
  --Mapper.init_min_tri_angle 4

echo.
echo Converting model to TXT format...
colmap model_converter ^
  --input_path "%DATASET%\sparse\1" ^
  --output_path "%DATASET%\sparse\0" ^
  --output_type TXT

echo.
echo COLMAP done! Check sparse\0 for the reconstruction.
pause
