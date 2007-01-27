#!/bin/sh
# Nico Schottelius
# Standard release script for dummies like me
#

if [ $# -ne 1 ]; then
   echo "$0: ccollect dir"
   exit 23
fi

echo "Did you change version and date information in the script?"
read bla

NAME=$1
TARNAME=${NAME}.tar.bz2

DHOST=nico@home.schottelius.org
DDIR=www/org/schottelius/unix/www/ccollect/
DESTINATION="$DHOST:$DDIR"

# create documentation for the end user
(
   cd "$NAME"
   make dist
   make publish-doc
)

tar cvfj "$TARNAME" \
   --exclude=.git \
   --exclude="conf/sources/*/destination/*" "$NAME"

scp "${TARNAME}" "$DESTINATION"

ssh "$DHOST" "( cd $DDIR; tar xfj \"$TARNAME\" )"

echo "setting paranoid permissions to public..."
ssh "$DHOST" "( cd $DDIR; find -type d -exec chmod 0755 {} \; )"
ssh "$DHOST" "( cd $DDIR; find -type f -exec chmod 0644 {} \; )"

cat "${NAME}/doc/release-checklist"
