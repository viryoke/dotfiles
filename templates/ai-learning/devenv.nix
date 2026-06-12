{ pkgs, lib, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  commonRequirements = ''
    jupyterlab
    notebook
    transformers
    datasets
    accelerate
    scikit-learn
    pandas
    numpy
    matplotlib
    seaborn
    tensorboard
  '';

  darwinRequirements = ''
    torch
    torchvision
    torchaudio
  '';

  linuxRequirements = ''
    --extra-index-url https://download.pytorch.org/whl/cu124
    torch
    torchvision
    torchaudio
  '';
in
{
  languages.python = {
    enable = true;
    version = "3.11";
    venv = {
      enable = true;
      requirements = commonRequirements + (if isDarwin then darwinRequirements else linuxRequirements);
    };
  };

  env = {
    PIP_INDEX_URL = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple";
    PIP_TRUSTED_HOST = "mirrors.tuna.tsinghua.edu.cn";
    HF_ENDPOINT = "https://hf-mirror.com";
    PRJ_ROOT = "$PWD";
    DATA_DIR = "$PWD/data";
    MODEL_DIR = "$PWD/models";
  } // lib.optionalAttrs isLinux {
    CUDA_HOME = "/usr/local/cuda";
  };

  enterShell = ''
    mkdir -p data models notebooks
    ${lib.optionalString isDarwin "echo 'Backend: MPS (Apple Silicon)'"}
    ${lib.optionalString isLinux "echo 'Backend: CUDA'"}
  '';

  scripts.jupyter.exec = "jupyter lab --notebook-dir=.";
}
