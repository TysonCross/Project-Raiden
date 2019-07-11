#!/bin/bash
nvcc -V
echo ' '
cat /usr/local/cuda/version.txt
echo ' '
cat /usr/local/cuda/include/cudnn.h | grep CUDNN_MAJOR -A 2
echo ' '
nvidia-smi
echo ' '
echo "python version:"
python --version
echo ' '
echo "tensorflow version:"
python -c 'import tensorflow as tf; print(tf.__version__)'
