#!/usr/bin/zsh

pick_torrent() LBUFFER="transmission-remote -t ${$({
  for torrent in ${(f)"$(transmission-remote -l)"}; do
    torrent_name=$torrent[73,-1]
    [[ $torrent_name != (Name|) ]] && echo ${${${(s. .)torrent}[1]}%\*} $torrent_name
  done
} | fzf)%% *} -"

zle -N pick_torrent
bindkey '^o' pick_torrent
