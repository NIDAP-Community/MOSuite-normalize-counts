# hash:sha256:f2156087a09d1bf0aa6e8cfaf2da7f9ed1e6a1fe1faee3dbd603d7220e456867
ARG REGISTRY_HOST
FROM $REGISTRY_HOST/codeocean/mosuite-minimal:v0.5.0-alpha

ARG DEBIAN_FRONTEND=noninteractive
ARG GIT_ASKPASS
COPY git-ask-pass /

RUN --mount=type=secret,id=git-access-token \
    GITHUB_PAT="$(cat /run/secrets/git-access-token)" \
    Rscript -e 'remotes::install_github( \
        "MOObject", \
        ref = "main")'
