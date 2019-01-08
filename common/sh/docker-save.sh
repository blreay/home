# docker-save.sh
#!/bin/bash -ex
# Wrapper for 'docker save' fixing,
# https://github.com/dotcloud/docker/issues/3877
# In addition: this script will always save exactly one image (possibly
# multiple tags).

set -vx

IMAGE=${1?"no image"}
NEWTAG=${2?"no new tag"}
TARGET=${3?"no tar file name"}

NAME=`echo $IMAGE | awk -F':' '{print $1}'`
ID=`docker inspect $IMAGE | jq -r '.[0].Id'`
ID=$IMAGE
TAGS=`docker images --no-trunc | grep $ID | awk '{print $2}'`
DIR=`mktemp -d --suffix=-docker-save`
pushd $DIR

docker save $ID > $TARGET
cp $TARGET $TARGET.bk
tar xvf $TARGET repositories  manifest.json

cat manifest.json | jq -c '.[0].RepoTags[0]="'"$NEWTAG"'"' > manifest.json.new
mv manifest.json manifest.json.old
mv manifest.json.new manifest.json
cat manifest.json

cat repositories | jq '.'"${NEWTAG%%:*}"'.'"${NEWTAG##*:}"'=.'"${IMAGE%%:*}"'.'"${IMAGE##*:}"' | del(.'"${IMAGE%%:*}"')' > repositories.new
mv repositories repositories.old
mv repositories.new repositories
cat repositories

#tar --update -v -f $TARGET repositories manifest.json 

tar --delete --posix --owner=0 --group=0 -vf $TARGET repositories  manifest.json
#tar tvf $TARGET
#python -c "import tarfile; def reset(tarinfo): \
#    tarinfo.uid = tarinfo.gid = 0; \
#	    tarinfo.uname = tarinfo.gname = "root"; \
#		    return tarinfo; f=tarfile.open('$TARGET', 'a'); f.add('repositories'); f.add('manifest.json'); f.close()"
python <<EOF
import tarfile; 
def reset(tarinfo): 
	tarinfo.uid = tarinfo.gid = 0
	tarinfo.uname = tarinfo.gname = "0"
	return tarinfo
f=tarfile.open('$TARGET', 'a')
f.add('repositories', filter=reset)
f.add('manifest.json', filter=reset)
f.close()
EOF
tar tvf $TARGET
pwd
popd
#rm -rf $DIR
