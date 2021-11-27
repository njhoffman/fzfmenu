#!/bin/bash

# Regex Definitions
WORDREGEX='\w+'
IDENTREGEX='[A-Za-z]+([_-][A-Za-z0-9]+)*[A-Za-z0-9]*'
IDENTREGEXWITHDOT='[A-Za-z]+([._-][A-Za-z0-9]+)*[A-Za-z0-9]*'
NOSPACEREGEX='\S+'
NUMREGEX='[0-9]+'

# URLREGEX='[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)'
URLREGEX='https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)'
GITURLREGEX='(git@|https:\/\/)([\w\.@]+)(\/|:)([\w,\-,\_]+)\/([\w,\-,\_]+)(.git){0,1}((\/){0,1})'

## technically all numbers match a basic hashregex
## but let us only match hashes that has
## atleast one alphabet in it
HASHREGEX='(([a-f0-9]*[a-f][a-f0-9]*)|([A-F0-9]*[A-F][A-F0-9]*))\b'

IPV4REGEX='[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
IPV6REGEX='[a-fA-F0-9]+:[a-fA-F0-9:]{2,}'
IPCOMBINED="(("$IPV4REGEX")|("$IPV6REGEX"))"
PREFIXCOMBINED="(("$IPV4REGEX")|("$IPV6REGEX"))(/[0-9]{1,3})?"
