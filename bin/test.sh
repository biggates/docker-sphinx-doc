#!/usr/bin/env sh
# This file:
#
#  - Run smoke tests in Docker container
#
# Usage:
#
#  ./bin/test.sh [TAG]

# Exit on error. Append "|| true" if you expect an error.
set -e
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail

image="sphinx-doc"
tag=$*

test_image()
{
    cmd=$3
    image=$1
    tag=$2

    rm -fr docs

    docker run \
        --interactive \
        --tty \
        "${image}:${tag}" \
        sh -c "sphinx-quickstart --author=me --project=smoke-test --quiet docs \
            && ${cmd}"
    container=$(docker ps --all --filter ancestor="${image}:${tag}" --format "{{.Names}}")
    docker cp "${container}:/app/docs" "$(pwd)"
    docker rm "${container}"
}

echo "Running smoke tests for ${image}:${tag}."
echo

test_image "${image}" "${tag}" "make --directory=docs html"

[ -f docs/conf.py ] && [ -f docs/Makefile ] && [ -f docs/_build/html/index.html ]

if [ "${tag}" = "latex" ]; then
    test_image "${image}" "${tag}" "make --directory=docs latexpdf LATEXMKOPTS='-silent'"

    [ -f docs/_build/latex/smoke-test.pdf ]
fi

docker ps --all --filter ancestor="${image}"
