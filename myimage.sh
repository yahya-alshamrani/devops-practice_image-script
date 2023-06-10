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

# Allow non-root to deploy the application
# Change default webport 80 to 8080
sed -i '/listen/ s/80/8080/' $scratchmnt/etc/nginx/nginx.conf
sed -i '/^pid/ s/.*/pid \/tmp\/nginx.pid;/' $scratchmnt/etc/nginx/nginx.conf
sed -i '/^user nginx*/ d' $scratchmnt/etc/nginx/nginx.conf

rm -rf /tmp/website/

# set some config info
buildah config --label name=nginx $newcontainer
buildah config --cmd "nginx -g 'daemon off;'" $newcontainer

# Commit the image
buildah unmount $newcontainer
buildah commit $newcontainer nginx

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
