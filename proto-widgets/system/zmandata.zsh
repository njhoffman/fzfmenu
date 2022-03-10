#!/usr/bin/env zsh

0=${(%):-%N}
PRJ_HOME=${0:a:h:h}
VENV_HOME=$PRJ_HOME/bin/.venv

# setup venv
if [[ -d $VENV_HOME ]]; then
  source $VENV_HOME/bin/activate
else
  python3 -m venv $VENV_HOME
  source $VENV_HOME/bin/activate
  pip install --upgrade pip
  pip install -r ${0:a:h}/requirements.txt
fi

# update pip requirements
if [[ $1 == "--pipup" ]]; then
  echo "Updating pip requirements..."
  pip list --format freeze --outdated | sed 's/=.*//g' | xargs -n1 pip install -U
  pip freeze > $PRJ_HOME/bin/requirements.txt
  deactivate
  return
fi

# download the latest docs
if [[ $1 == "--refresh" ]]; then
  echo "dowloading latest docs..."
  curl -fsSL http://zsh.sourceforge.net/Doc/zsh_html.tar.gz -o $PRJ_HOME/docs/zsh_html.tar.gz
  rm -rf $PRJ_HOME/docs/zsh_html
  tar -zxf $PRJ_HOME/docs/zsh_html.tar.gz --directory $PRJ_HOME/docs
fi

python $PRJ_HOME/bin/zmandata.py
deactivate
