#!/usr/bin/env bash
# -*- +indent: 2 -*-

SEP=$'\t'

print_usage() {
  echo "Usage: ttls [-h] [-a] [-p] [-l] [-s SEP]"
}

print_help() {
  print_usage
  cat <<-EOF
  List available tmuxinator/tmuxp configurations.
Optional arguments:
  -h               Show this help message and exit.
  -a               List configs in projects as well using ls-project.
  -l               Flush standard output after each newline print.
  -s SEP           Set field separator on output to SEP.
  -p               Pretty print instead of passwd output format.
  -q               Supress any stderr output (silent mode).
EOF
}

all=0 pretty=0 line_buffer=0
while getopts 'halps:q' OPTION; do
  case "$OPTION" in
    h) print_help
       exit 0 ;;
    \?) print_usage >&2
        exit 1 ;;
    a) all=1 ;;
    s) SEP="$OPTARG" ;;
    l) line_buffer=1 ;;
    p) pretty=1 ;;
    q) exec 2>/dev/null ;;
  esac
done

#  _     _     _      ____                                          _
# | |   (_)___| |_   / ___|___  _ __ ___  _ __ ___   __ _ _ __   __| |___
# | |   | / __| __| | |   / _ \| '_ ` _ \| '_ ` _ \ / _` | '_ \ / _` / __|
# | |___| \__ \ |_  | |__| (_) | | | | | | | | | | | (_| | | | | (_| \__ \
# |_____|_|___/\__|  \____\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|\__,_|___/
#
# The following commands each list configurations for various session
# managers. Each command recieves a list of projects to also check for
# configs from standard input.
#
# The format of the output should be "backend:cmd:cmd-arg:[cd-dir]:id:[meta]".

list_tmux_sessions() {
  tmux \
    list-sessions \
    -F "tmux${SEP}tmux attach-session -t${SEP}#{session_id}${SEP}${SEP}#S${SEP}#{t:session_created}"
}

list_tmuxp() {
  local TMUXP_SCRIPT
  read -r -d '' TMUXP_SCRIPT <<-"EOF"
import os
import itertools
import sys
import tmuxp
sep = sys.argv[1]
def list_configs():
    root = tmuxp.cli.get_config_dir()
    if not (os.path.exists(root) and os.path.isdir(root)):
        return
    for f in sorted(os.listdir(root)):
        basename, ext = os.path.splitext(f)
        f = os.path.join(root, f)
        if os.path.isfile(f) and ext in tmuxp.cli.VALID_CONFIG_DIR_FILE_EXTENSIONS:
            yield f, '', basename, ''
def list_project_configs(dirs):
    EXTS = ['.tmuxp.yaml', '.tmuxp.yml', '.tmuxp.json']  # Copied from [[file:.local/lib/python3.9/site-packages/tmuxp/cli.py::for ext in \['.tmuxp.yaml', '.tmuxp.yml', '.tmuxp.json'\]][cli.py]].
    for proj_dir in dirs:
        for ext in EXTS:
            conf = os.path.join(proj_dir, ext)
            if not os.path.exists(conf):
                continue
            yield conf, proj_dir, os.path.basename(proj_dir), ''
    return []
for it in itertools.chain(
        list_configs(),
        list_project_configs(sys.stdin.read(-1).split('\n'))):
    print('tmuxp' + sep + 'tmuxp load -y' + sep + sep.join(it))
EOF

  python3 -c "$TMUXP_SCRIPT" "$SEP"
}

list_tmuxinator() {
  local TMUXINATOR_SCRIPT
  read -r -d '' TMUXINATOR_SCRIPT <<-"EOF"
# frozen_string_literal: true
# list tmuxinator configs both in the shared config
# folder and any project local configs (from the cwd).
require 'pathname'
require 'xdg'
require 'tmuxinator/config'
sep = ARGV[0]
CWD  = Pathname.new('./').expand_path
HOME = Pathname.new('~/').expand_path
# yields [config_path, project_name, project_path || config_path]
def each_config(cwd, paths = [])
  return unless block_given?
  Tmuxinator::Config.directories.map do |directory|
    Dir["#{directory}/**/*.yml"].map(&Pathname.method(:new)).map do |path|
      project_name = path.to_path.gsub("#{directory}/", '').gsub('.yml', '')
      yield path, '', project_name, ''
    end
  end
  [cwd, *paths].each do |path|
    local_path = Tmuxinator::Config::LOCAL_DEFAULTS
                   .map(&path.method(:join))
                   .find(&:readable?)
    yield local_path, path, path.basename.to_path, '' if local_path
  end
end
$stdout.sync = true
projects = STDIN.each_line.map { |path| Pathname.new(path.chomp) }
each_config(CWD, projects) do |*args|
  puts "tmuxinator#{sep}tmuxinator start --suppress-tmux-version-warning -p#{sep}#{args.join(sep)}"
end
EOF

  ruby -e "$TMUXINATOR_SCRIPT" "$SEP"
}

if [ "$all" -eq 1 ]; then ls-projects; fi |
  tee --output-error=warn-nopipe \
      >(list_tmuxp) \
      >(list_tmuxinator) \
      >(list_tmux_sessions) \
      >/dev/null |
  if [ "$pretty" -eq 0 ]; then
    cat
  else
    # Format "backend:cmd:cmd-arg:[cd-dir]:pretty_output"
    awk -F "$SEP" \
        -v color_dir=$'\e[0;32m' \
        -v color_conf=$'\e[0;34m' \
        -v color_meta=$'\e[0;35m' \
        -v color_reset=$'\e[0m' \
        -v line_buffer="$line_buffer" \
        -v home="$HOME" \
        -e '{
  printf("%s" FS "%s" FS "%s" FS "%s" FS, $1, $2, $3, $4)
  printf("%s", $5)
  if ($6) {
    printf(" [%s%s%s]", color_meta, $6, color_reset)
  } else if ($4) {
    dir = $4
    sub(home, "~", dir)
    printf(" [%s%s%s]", color_dir, dir, color_reset)
  } else if ($3) {
    conf = $3
    sub(home, "~", conf)
    printf(" [%s%s%s]", color_conf, conf, color_reset)
  }
  printf("\n")
  if (line_buffer)
    fflush(stdout)
}'
  fi
