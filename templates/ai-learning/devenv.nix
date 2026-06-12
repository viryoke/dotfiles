{ pkgs, ... }: {
  languages.python = {
    enable = true;
    version = "3.11";
    venv = {
      enable = true;
      requirements = ''
        jupyterlab
        notebook
        torch
        torchvision
        torchaudio
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
    };
  };

  env = {
    PIP_INDEX_URL = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple";
    PIP_TRUSTED_HOST = "mirrors.tuna.tsinghua.edu.cn";
    HF_ENDPOINT = "https://hf-mirror.com";
    PRJ_ROOT = "$PWD";
    DATA_DIR = "$PWD/data";
    MODEL_DIR = "$PWD/models";
  };

  enterShell = ''
    mkdir -p data models notebooks
  '';

  scripts.jupyter.exec = "jupyter lab --notebook-dir=.";
}
