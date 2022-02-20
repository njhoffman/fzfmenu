#!/bin/bash
avahi-browse --parsable --all --resolve 2>/dev/null | fzf