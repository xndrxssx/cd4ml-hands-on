#!/usr/bin/env bash

# Ativa o ambiente virtual
source venv/bin/activate

# Ignora warnings do numpy
export PYTHONWARNINGS="ignore:numpy"

# Executa os testes
command="python -m pytest --cov=cd4ml --cov-report html:cov_html test"
echo "$command"
eval "$command"

echo
echo Flake8 comments:

# Ignora print() statements e ajusta limite de linhas
flake8 --extend-ignore T001 --max-line-length=120 cd4ml
