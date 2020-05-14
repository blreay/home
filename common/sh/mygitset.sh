#!/bin/bash

git config --global alias.st status
git config --global alias.co checkout
git config --global alias.ci commit
git config --global alias.br branch
git config --global receive.denyCurrentBranch ignore

if [[ "$(uname)" == "Linux" ]]; then
	#seems don't need this wrapper
	#git config --global diff.tool diffmerge
	#git config --global difftool.prompt true
	#git config --global difftool.diffmerge.cmd 'mygit_diffmerge_wrapper.sh diff $LOCAL $REMOTE'
	#git config --global merge.tool diffmerge
	#git config --global mergetool.prompt true
	#git config --global mergetool.diffmerge.cmd 'mygit_diffmerge_wrapper.sh merge $LOCAL $REMOTE $BASE $MERGED'
	git config --global diff.tool diffmerge
	git config --global difftool.diffmerge.cmd "diffmerge \"\$LOCAL\" \"\$REMOTE\""
	git config --global merge.tool diffmerge
	git config --global mergetool.diffmerge.trustExitCode true
	git config --global mergetool.diffmerge.cmd "diffmerge --merge --result=\"\$MERGED\"  \"\$LOCAL\" \"\$BASE\" \"\$REMOTE\""
else
    git config --global diff.tool bc4
    git config --global difftool.prompt true
    git config --global difftool.bc4.cmd '"/cygdrive/c/Program Files/Beyond Compare 4/BCompare.exe" "$(cygpath -w $LOCAL)" "$(cygpath -w $REMOTE)"'
    git config --global merge.tool bc4
    git config --global mergetool.prompt true
    git config --global mergetool.bc4.cmd '"/cygdrive/c/Program Files/Beyond Compare 4/BCompare.exe" "$(cygpath -w $LOCAL)" ""$(cygpath -w $REMOTE)" "$(cygpath -w $BASE)" "$(cygpath -w $MERGED)"'
fi
