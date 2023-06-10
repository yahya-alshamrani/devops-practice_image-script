#!/bin/bash

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
git clone git@github.com:yahya-alshamrani/devops-practice_website.git /tmp/website
cp /tmp/website/webpage/index.html $scratchmnt/usr/share/nginx/html/

rm -rf /tmp/website/

# set some config info
buildah config --label name=nginx $newcontainer
buildah config --cmd "nginx -g 'daemon off;'" $newcontainer

# commit the image
buildah unmount $newcontainer
buildah commit $newcontainer nginx
