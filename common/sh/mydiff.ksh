#!/bin/ksh

if [[ $# -lt 2 ]]; then
   echo "Invalid argument!"
   echo "Usage: $0 src tgt"
   exit 124
fi

typeset ret=0

SRC_FILE=$1
TGT_FILE=$2

#SRC_FILE_TMP=$MT_TMP/${SRC_FILE##*/}.$(date +'%H%M%S').$$.src
#TGT_FILE_TMP=$MT_TMP/${TGT_FILE##*/}.$(date +'%H%M%S').$$.tgt
SRC_FILE_TMP=$SRC_FILE
TGT_FILE_TMP=$TGT_FILE

#sed 's/ *$//' <$SRC_FILE >$SRC_FILE_TMP
#sed 's/ *$//' <$TGT_FILE >$TGT_FILE_TMP

#############################################
if [[ -n $MYDIFF_DEBUG ]]; then
	echo "****** $SRC_FILE_TMP ************************"
	cat $SRC_FILE_TMP
	echo "****** $TGT_FILE_TMP **********************"
	cat $TGT_FILE_TMP
	echo "******************************"
fi
#############################################

echo "******************************"
echo "diff $SRC_FILE_TMP $TGT_FILE_TMP"
diff $SRC_FILE_TMP $TGT_FILE_TMP 
if [[ $? -ne 0 ]];then
	ret=100
fi
echo "******************************"

#read
echo "ret=$ret"
exit $ret

# mydiff.ksh
