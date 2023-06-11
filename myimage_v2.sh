#!/bin/bash

# Get the new version for the docker image
VER="${1}"
if [[ -z "${VER}" ]]
then
  echo "You have to add version when you run the script!" >&2
  exit 0
fi

newcontainer=$(buildah from scratch)
scratchmnt=$(buildah mount $newcontainer)

yum install -y epel-release
yum update -y
yum install bash coreutils nginx --installroot $scratchmnt --releasever 8.8\
  --setopt install_weak_deps=false --setopt=tsflags=nodocs -y

yum clean all -y --installroot $scratchmnt --releasever 8.8
rm -rf $scratchmnt/var/cache/yum

# get the latest web files
rm -rf /tmp/website/ > /dev/null
git clone https://github.com/yahya-alshamrani/devops-practice_website.git /tmp/website
cp /tmp/website/webpage/index.html $scratchmnt/usr/share/nginx/html/

## set some config info
buildah config --label name=nginx $newcontainer
buildah config --entrypoint "/usr/sbin/nginx -g 'daemon off;'" $newcontainer
buildah config --cmd "/usr/sh -c EXPOSE 80" $newcontainer
buildah config --cmd "/usr/sbin/nginx -g 'daemon off;'" $newcontainer

# commit the image
buildah unmount $newcontainer
buildah commit $newcontainer yahya/nginx

DOCKER_TOKEN="${XDG_RUNTIME_DIR}/containers/auth.json"
if [[ -f "${DOCKER_TOKEN}" ]]
then
  buildah push nginx yahyaalshamrani/devops-practice:"${VER}"
else
  echo "You have to add the docker token to the path ${DOCKER_TOKEN}" >&2
fi

# Remove the local containers
buildah rm $newcontainer
# Remove the local image
buildah rmi nginx
