#!/bin/bash
SRCURL=http://fmwww.bc.edu/repec/bocode/

# if we are on Codespaces or in a Github Action environment, remove the prior download
arg=$1
[[ -z $CODESPACES ]] || clean=yes
[[ -z $GITHUB_WORKFLOW ]] && clean=$clean || clean=yes
[[ "$arg" == "clean" ]] && clean=yes || clean=$clean

[[ -z $arg ]] && arg=$clean || arg=$arg

if [[ -z $arg ]]
then
cat << EOF

   $0 start|clean

   mirror $SRCURL to this directory

EOF
exit 0
fi

# removing the prior download

[[ "$clean" == "yes" ]] && \rm -rf fmwww.bc.edu

# Downloading afresh

# --adjust-extension removed, as it converted .do files to HTML
wget --mirror --convert-links --page-requisites --no-parent $SRCURL
# clean up
[[ -f fmwww.bc.edu/repec/repec.css ]] && rm fmwww.bc.edu/repec/repec.css
[[ -f fmwww.bc.edu/ecstyle.css ]]     && rm fmwww.bc.edu/ecstyle.css
find fmwww.bc.edu -name index.html\* -exec rm {} \;
# put a note
sed "s/XXDATEXX/$(date +%F)/" stata.toc.template > fmwww.bc.edu/repec/bocode/stata.toc
# list all files
find fmwww.bc.edu/repec/bocode -type f > sscfiles.txt


