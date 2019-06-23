set -e

# If TRAVIS_TAG is not set, we recuperate the last tag for the repo
: ${TRAVIS_TAG:=$(git describe --abbrev=0 --tags)}

# If the tag does not start with image- we ignore it
[ "${TRAVIS_TAG::1}" != v ] && exit 0

for df in Dockerfile*
do
    echo
    printf '%40s\n' | tr ' ' -
    printf "Processing file $df\n"
    tag=${df:13}
    tag=${tag,,}
    [ -z ${tag} ] || tag=-${tag}
    travis_tag=${TRAVIS_TAG:1}
    travis_maj_min=${travis_tag%.*}
    version=coveo/tgf:${travis_tag}${tag}
    version_mm=coveo/tgf:${travis_maj_min}${tag}
    latest=${tag:1}
    latest=coveo/tgf:${latest:-latest}

    # We do not want to tag latest if this is not an official version number
    [[ $travis_tag == *-* ]] && unset latest
    
    dockerfile=dockerfile.temp
    # We replace the TRAVIS_TAG variable if any (case where the image is build from another image)
    # The result file is simply named Dockerfile
    cat $df | sed -e "s/\${TRAVIS_TAG}/$travis_tag/" | sed -e "s/\TGF_IMAGE_MAJ_MIN=/TGF_IMAGE_MAJ_MIN=$travis_maj_min/" > $dockerfile

    docker build -f $dockerfile -t $version . && rm $dockerfile
    docker push $version
    if [ -n "$latest" ]
    then 
        # docker tag $version $latest && docker push $latest (we do not update latest on old version)
        docker tag $version $version_mm && docker push $version_mm
    fi
done
