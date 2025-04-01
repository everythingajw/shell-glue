#!/bin/bash

# function updatevim
#     set -lx SHELL (which sh)
#     vim +BundleInstall! +BundleClean +qall
# end

export SHELL="$(which sh)"
vim +BundleInstall! +BundleClean +qall

