# hash:sha256:6bdfa7e6ed79d105c083653a13295029eda43de2d299e7b3d80b5a2542e98941
ARG REGISTRY_HOST
FROM $REGISTRY_HOST/codeocean/mosuite-minimal:v0.5.0-alpha

ARG DEBIAN_FRONTEND=noninteractive
ARG GIT_ASKPASS
COPY git-ask-pass /

ARG RCACHE_OPTIONS
RUN echo $RCACHE_OPTIONS >> $(Rscript -e 'cat(R.home())')/etc/Rprofile.site \
    && Rscript -e 'options(warn=2); install.packages("remotes")'
RUN Rscript -e 'remotes::install_version("remotes", "2.5.0")'

RUN --mount=type=secret,id=git-access-token \
    GITHUB_PAT="$(cat /run/secrets/git-access-token)" \
    Rscript -e 'remotes::install_github( \
        "CCBR/MOObject", \
        ref = "0c296b88c69e408d8f5e70c93af5878ec167db9a")'
