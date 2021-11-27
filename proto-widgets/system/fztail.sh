#!/bin/bash

# With "follow", preview window will automatically scroll to the bottom.
# "\033[2J" is an ANSI escape sequence for clearing the screen.
# When fzf reads this code it clears the previous preview contents.

fzf --preview-window follow --preview 'for i in $(seq 100000); do
echo "$i"
sleep 0.01
(( i % 300 == 0 )) && printf "\033[2J"
done'

# browse kubernetes pod logs
read -r tokens < <(
kubectl get pods --all-namespaces |
  fzf --info=inline --layout=reverse --header-lines=1 --border \
  --prompt "$(kubectl config current-context | sed 's/-context$//')> " \
  --header $'Press CTRL-O to open log in editor\n\n' \
  --bind ctrl-/:toggle-preview \
  --bind 'ctrl-o:execute:${EDITOR:-vim} <(kubectl logs --namespace {1} {2}) > /dev/tty' \
  --preview-window up,follow \
  --preview 'kubectl logs --follow --tail=100000 --namespace {1} {2}' "$@"
)
[ ${#tokens} -gt 1 ] &&
  kubectl exec -it --namespace "${tokens[0]}" "${tokens[1]}" -- bash
