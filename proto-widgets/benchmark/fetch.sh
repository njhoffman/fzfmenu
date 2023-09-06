#!/bin/bash

curl 'https://www.cpubenchmark.net/cpu_list.php'
cat cpu_list.html | pup '#cputable tr td text{}'
cpu=$(lspcu | grep 'Model name:' | cut -d':' -f2 | xargs)
# 11th Gen Intel(R) Core(TM) i7-1195G7 @ 2.90GHz
# https://www.videocardbenchmark.net/gpu_list.php
