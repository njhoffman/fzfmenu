#!/bin/zsh

sudo netstat -tlnp | tail -n+3 | sort | awk '{for (i=4; i <= NF; i++) printf $i""FS; print""}' | grcat conf.netstat
