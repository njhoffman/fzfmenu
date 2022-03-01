#!/bin/zsh

FZF_MODES=('containers' 'repos' 'images' 'networks' 'volumes')

_fzf_tabularize_header() {
  if [[ $# = 0 ]]; then
    cat
    return
  fi
  header="$1"
  shift

  awk \
    -v FS=${FS:- } \
    -v header="$header" \
    -v colors_args="$*" \
    -v reset="\033[0m" '
    BEGIN { split(colors_args, colors, " ") }
      {
        str = $0
        for (i = 1; i <= length(colors); ++i) {
          field_max[i] = length($i) > field_max[i] ? length($i) : field_max[i]
          fields[NR, i] = $i
          pos = index(str, FS)
          str = substr(str, pos + 1)
        }
        if (pos != 0) {
          fields[NR, i] = str
        }
      }
    END {
      for (i = 1; i <= NR; ++i) {
        for (j = 1; j <= length(colors); ++j) {
          if (i == 1) {
            printf "%s%s%-" field_max[j] "s%s", (j > 1 ? "  " : ""), header, fields[i, j], reset
          } else {
          printf "%s%s%-" field_max[j] "s%s", (j > 1 ? "  " : ""), colors[j], fields[i, j], reset
        }
      }
      printf "\n"
    }
  }
  '
}

_fzf-command() {
  # mode="$1" && shift
  selection="$*"
  mode="$1" && shift
  mode_name="${FZF_MODES[$mode]}"


  header=$'\e[31;1;4m' reset=$'\e[0m'
  case "$mode_name" in
    'containers')
      # containers=$(command docker ps -a -s --format='{{json .}}')
      cmd="
      docker container list --all \
        --format 'table {{.ID}};{{.Image}};{{.Command}};{{.RunningFor}};{{.Status}};{{.Ports}};{{.Names}}' 2> /dev/null \
        | FS=';' _fzf_tabularize_header $header $header $reset{,,,,,,}
      "
      echo "$cmd"
      ;;
    'repos')
      docker images  --filter 'dangling=false' \
        --format 'table {{.Repository}};{{.ID}};{{.Tag}};{{if .CreatedSince}}{{.CreatedSince}}{{else}}N/A{{end}};{{.Size}}' 2> /dev/null \
        | FS=';' _fzf_tabularize_header $_clr[header] $_clr[field_id] $_clr[rst]{,,}
      ;;
    'images')
      docker images --format 'table {{.ID}};{{.Repository}};{{.Tag}};{{if .CreatedSince}}{{.CreatedSince}}{{else}}N/A{{end}};{{.Size}}' 2> /dev/null \
        | FS=';' _fzf_tabularize_header $_clr[header] $_clr[field_id] $_clr[rst]{,,}
      # images=$(command docker images --all --digests --format='{{json .}}')
      # Containers, CreatedAt,  CreatedSince,  Digest,  ID,  Repository,  SharedSize,  Size,  Tag,  UniqueSize,  VirtualSize
      ;;
    'networks')
      docker network list --format 'table {{.ID}};{{.Name}};{{.Driver}};{{.Scope}}' 2> /dev/null \
        | FS=';' _fzf_tabularize_header $_clr[header]$_clr[field_id] $_clr[rst]{,}
      # networks=$(command docker network ls --format='{{json .}}')
      # CreatedAt, Driver, ID, IPv6, Internal, Labels, Name, Scope
      ;;
    'volumes')
      docker volume list --format 'table {{.Name}};{{.Driver}};{{.Scope}}' 2> /dev/null \
        | FS=';' _fzf_tabularize_header $_clr[header] $_clr[field_id] $_clr[rst]{,}
      # volumes=$(command docker volume ls --format='{{json .}}')
      # while read -r line; do
      #   fields=".Driver, .Labels, .Links, .Mountpoint, .Name, .Scope, .Size"
      #   # "Labels": "com.docker.compose.project=test,com.docker.compose.version=1.27.4,com.docker.compose.volume=my-app-data",

      #   IFS=$'\n' read -r -d '' driver labels links mountpoint name scope size \
      #     <<< "$(echo $line | jq -r $fields)"

      #   printf "%s\t%s\t%s\t%s\t%s\n" \
      #     $driver $name $scope $size $mountpoint

      # done <<< "$(echo "$volumes" | jq -c '.')"
      ;;
  esac
}


# docker container list --all \
#   --format 'table {{.ID}};{{.Image}};{{.Command}};{{.RunningFor}};{{.Status}};{{.Ports}};{{.Names}}' 2> /dev/null \
#   | FS=';' _fzf_tabularize_header $_clr[header] $_clr[field_id] $_clr[rst]{,,,,,,}
# _fzf-command 1
