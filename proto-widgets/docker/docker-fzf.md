# Overview of available commands

| command | description                                                                        | fzf mode | command arguments (optional)                                                                                 |
| ------- | ---------------------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------ |
| dr      | docker restart && open logs (in follow mode)                                       | multiple |                                                                                                              |
| dl      | docker logs (in follow mode)                                                       | multiple | time interval - e.g.: `1m` for 1 minute - (defaults to all available logs)                                   |
| dla     | docker logs (in follow mode) all containers                                        |          | time interval - e.g.: `1m` for 1 minute - (defaults to all available logs)                                   |
| de      | docker exec in interactive mode                                                    | single   | command to exec (default - see below)                                                                        |
| drm     | docker remove container (with force)                                               | multiple |                                                                                                              |
| drma    | docker remove all containers (with force)                                          |          |                                                                                                              |
| ds      | docker stop                                                                        | multiple |                                                                                                              |
| dsa     | docker stop all running containers                                                 |          |                                                                                                              |
| dsrm    | docker stop and remove container                                                   | multiple |                                                                                                              |
| dsrma   | docker stop and remove all container                                               |          |
| dk      | docker kill                                                                        | multiple |                                                                                                              |
| dka     | docker kill all containers                                                         |          |                                                                                                              |
| dkrm    | docker kill and remove container                                                   | multiple |                                                                                                              |
| dkrma   | docker kill and remove all container                                               |          |                                                                                                              |
| drmi    | docker remove image (with force). This includes options to remove dangling images. | multiple |                                                                                                              |
| drmia   | docker remove all images (with force). This includes dangling images.              |          |                                                                                                              |
| dclean  | `dsrma` and `drmia`                                                                |          |                                                                                                              |
| dcu     | docker-compose up (in detached mode)                                               | multiple | path to docker-compose file (defaults to recursive search for `docker-compose.yml` or `docker-compose.yaml`) |
| dcua    | docker-compose up all services (in detached mode)                                  |          | path to docker-compose file (defaults to recursive search for `docker-compose.yml` or `docker-compose.yaml`) |
| dcb     | docker-compose build (with --no-cache and --pull)                                  | multiple | path to docker-compose file (defaults to recursive search for `docker-compose.yml` or `docker-compose.yaml`) |
| dcba    | docker-compose build (with --no-cache and --pull) all                              |          | path to docker-compose file (defaults to recursive search for `docker-compose.yml` or `docker-compose.yaml`) |
| dcp     | docker-compose pull                                                                | multiple | path to docker-compose file (defaults to recursive search for `docker-compose.yml` or `docker-compose.yaml`) |
| dcpa    | docker-compose pull all services                                                   |          | path to docker-compose file (defaults to recursive search for `docker-compose.yml` or `docker-compose.yaml`) |
| dcupd   | docker-compose update image (rebuild or pull)                                      | multiple | path to docker-compose file (defaults to recursive search for `docker-compose.yml` or `docker-compose.yaml`) |
| dcupda  | `dcba` and `dcpa`                                                                  |          | path to docker-compose file (defaults to recursive search for `docker-compose.yml` or `docker-compose.yaml`) |

## Default command for `de`
The command used to `exec` into a container is dependent on the base image.
The fallback command used to `exec` into a container is similar to `zsh || bash || ash || sh`.
Useful standards are already implemented for images like `mysql` or `mongo` (PRs to add more default commands are appreciated).

You may however add custom commands that `de` will then use to `exec` into a container. To do this
1. `cd /path/to/docker-fuzzy-search-commands`
1. copy the `.docker-fuzzy-search-exec.template` to your home directory, omitting the `.template` extension:
`cp {,~/}.docker-fuzzy-search-exec.template && mv ~/.docker-fuzzy-search-exec{.template,}`
1. Customize the script as described in the file.

# Learning by doing
### fzf mode = single
The image below shows a user `exec`ing into the container `infrastructure_some-mysql_1_6fe4edd94d07` container with the `de` command.
Because this script has a sensible default command registered for the base image of this container, `mysql` is directly opened (with the password set in the environment variable).

The command `de` was entered into a terminal. The user now typed `sql` to narrow the search for containers that contain that phrase. When the correct container was selected by the user pressing `Enter`.
Alternatively, the user could have used the arrow keys to select the correct container name.

![example gif](single.gif)

### optional command arguments
This image shows the `dl` command executed with `10m` as an optional argument.
Therefore the command will only show the logs of the selected container produced in the last 10 minutes, instead of all available logs for this container.

![example gif](args.gif)

### fzf mode = multiple

The image below shows a user starting the services `whiteboard-1.0` and `redis` with the `dcu` command.
To mark a containers/services in fzf, press on the `tab` key. To deselect, press `shift + tab`.
To remove the input, press `Alt + Backspace`.
Finally, press `Enter` to start the command. Note that when pressing `Enter`, the selected item will *not* be added automatically to your selection.
If you only want to mark one container, you don't have to select it with tab - you can follow the instructions of fzf single mode.

![example gif](multiple.gif)
