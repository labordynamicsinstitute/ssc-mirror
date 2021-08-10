#!/bin/bash
SRCURL=http://fmwww.bc.edu/repec/bocode/
if [[ -z $1 ]]
then
cat << EOF

   $0 start

   mirror $SRCURL to this directory

EOF
exit 0
fi
#wget --mirror --convert-links --adjust-extension --page-requisites --no-parent $SRCURL
wget --mirror --convert-links --page-requisites --no-parent $SRCURL
# clean up
rm fmwww.bc.edu/repec/repec.css
rm fmwww.bc.edu/ecstyle.css
find fmwww.bc.edu -name index.html\* -exec rm {} \;
# put a note
sed "s/XXDATEXX/$(date +%F)/" stata.toc > fmwww.bc.edu/repec/bocode/stata.toc

