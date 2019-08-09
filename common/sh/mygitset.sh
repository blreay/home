#!/bin/bash

git config --global alias.st status
git config --global alias.co checkout
git config --global alias.ci commit
git config --global alias.br branch

if [[ "$(uname)" == "Linux" ]]; then
	git config --global diff.tool diffmerge
	git config --global difftool.prompt true
	git config --global difftool.diffmerge.cmd 'diffmerge $LOCAL $REMOTE'
	git config --global merge.tool diffmerge
	git config --global mergetool.prompt true
	git config --global mergetool.diffmerge.cmd 'diffmerge $LOCAL $REMOTE $BASE $MERGED'
else
    git config --global diff.tool bc4
    git config --global difftool.prompt true
    git config --global difftool.bc4.cmd '"/cygdrive/c/Program Files/Beyond Compare 4/BCompare.exe" "$(cygpath -w $LOCAL)" "$(cygpath -w $REMOTE)"'
    git config --global merge.tool bc4
    git config --global mergetool.prompt true
    git config --global mergetool.bc4.cmd '"/cygdrive/c/Program Files/Beyond Compare 4/BCompare.exe" "$(cygpath -w $LOCAL)" ""$(cygpath -w $REMOTE)" "$(cygpath -w $BASE)" "$(cygpath -w $MERGED)"'
fi
