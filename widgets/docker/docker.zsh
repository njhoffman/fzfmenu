#!/bin/zsh

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib"

FZF_MODES=('containers' 'repos' 'images' 'networks' 'volumes')

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[menu_id]="${lc}${CLR_ID:-38;5;30}${rc}"
  _clr[menu_desc]="${lc}${CLR_DESC:-38;5;8;3}${rc}"
  _clr[menu_number]="${lc}${CLR_DESC_NUMBER:-38;5;81}${rc}"
  # _clr[desc]="${lc}${CLR_DESC:-1;3;30}${rc}"
  # _clr[desc]="${lc}${CLR_DESC:-0}${rc}"
  _clr[selected]="${lc}${CLR_MODE_SELECTED:-38;5;8;3}${rc}"
  _clr[field_id]="${lc}${CLR_FIELD_ID:-38;5;30}${rc}"
  # _clr[number]="${lc}${CLR_DESC_NUMBER:-1;34}${rc}"
	_clr[header]="${lc}${CLR_HEADER:-38;5;3}${rc}"

}

_fzf-menu-description() {
  id="$1"
  mode="${FZF_DEFAULT_MODE:-}"
  [[ $id =~ containers$ ]] && mode="containers"
  [[ $id =~ images$ ]] && mode="images"
  [[ $id =~ networks$ ]] && mode="networks"
  [[ $id =~ volumes$ ]] && mode="volumes"

  msg="${_clr[rst]}${_clr[menu_number]}"
  case "$mode" in
    containers)
      # container=$(command docker container ls --format='{{json .}}')
      containers=$(command docker ps -a -s --format='{{json .}}')
      count=$(echo "${containers[@]}" | wc -l)
      msg="${msg}$(printf "%'d" $count)${_clr[menu_desc]} docker containers ${_clr[rst]}"
      ;;
    images)
      images=$(command docker images --all --digests --format='{{json .}}')
      count=$(echo "${images[@]}" | wc -l)
      msg="${msg}$(printf "%'d" $count)${_clr[menu_desc]} docker images ${_clr[rst]}"
      ;;
    networks)
      networks=$(command docker network ls --format='{{json .}}')
      count=$(echo "${networks[@]}" | wc -l)
      msg="${msg}$(printf "%'d" $count)${_clr[menu_desc]} docker networks ${_clr[rst]}"
      ;;
    volumes)
      volumes=$(command docker volume ls --format='{{json .}}')
      count=$(echo "${volumes[@]}" | wc -l)
      msg="${msg}$(printf "%'d" $count)${_clr[menu_desc]} docker volumes ${_clr[rst]}"
      ;;
  esac

  # return count, if 0 then non-zero exit to skip item
  [[ $count -ne 0 ]] && echo -e "$msg" && exit 0
  _fzf-log "skipping: $id - $count" && exit 1
}

function _docker_volume_sizes() {
  for d in `docker ps | awk '{print $1}' | tail -n +2`; do
    d_name=`docker inspect -f {{.Name}} $d`
    echo "========================================================="
    echo "$d_name ($d) container size:"
    sudo du -d 2 -h /var/lib/docker/volumes | grep `docker inspect -f "{{.Id}}" $d`
    echo "$d_name ($d) volumes:"
    for mount in `docker inspect -f "{{range .Mounts}} {{.Source}}:{{.Destination}}
      {{end}}" $d`; do
        size=`echo $mount | cut -d':' -f1 | sudo xargs du -d 0 -h`
        mnt=`echo $mount | cut -d':' -f2`
        echo "$size mounted on $mnt"
      done
    done
}

_fzf-prompt() {
	mode="$1" && shift
	mode_name="${FZF_MODES[$mode]}"
	case "$mode_name" in
	'containers')
		echo " ps❯ "
		;;
  'repos')
    echo " repo❯ "
    ;;
	'images')
		echo " ls❯ "
		;;
	'networks')
		echo " netp "
		;;
	'volumes')
		echo " vol❯ "
		;;
	esac
}

_fzf-extra-opts() {
	opts=""
	opts="${opts} --header-lines=1"
	# opts="${opts} --header-first"
	echo "$opts"
}

_fzf-command() {
  # mode="$1" && shift
  selection="$*"
	mode="$1" && shift
	mode_name="${FZF_MODES[$mode]}"
  header=$'\e[31;1;4m'
  reset=$'\e[0m'

  case "$mode_name" in
    'containers')
      # containers=$(command docker ps -a -s --format='{{json .}}')
      cmd="docker container list --all \
        --format 'table {{.ID}};{{.Image}};{{.Command}};{{.RunningFor}};{{.Status}};{{.Ports}};{{.Names}}' 2> /dev/null \
        | _fzf_tabularize \"$header\" \"$reset\"{,,}"
      printf "%s" "$cmd"
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
				| FS=';' _fzf_tabularize_header $_clr[header] $_clr[rst]{,}
      # networks=$(command docker network ls --format='{{json .}}')
      # CreatedAt, Driver, ID, IPv6, Internal, Labels, Name, Scope
      ;;
    'volumes')
			docker volume list --format 'table {{.Name}};{{.Driver}};{{.Scope}}' 2> /dev/null \
				| FS=';' _fzf_tabularize_header $_clr[header]  $_clr[rst]{,}
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


source "$FZF_LIB.zsh"
# _fzf-source 2
