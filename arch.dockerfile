# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_GO_VERSION=0

# APP
  ARG BUILD_SRC=PatchMon/PatchMon.git \
      BUILD_ROOT=/go/PatchMon \
      BUILD_BIN=/PatchMon

 # :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:localhealth AS distroless-localhealth

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: SSG
  FROM 11notes/go:${APP_GO_VERSION} AS ssg
  ARG APP_ROOT \
      BUILD_SRC=ComplianceAsCode/content.git \
      BUILD_ROOT=/go/content

  RUN set -eux; \
    SSG_VERSION=$(curl -s https://api.github.com/repos/ComplianceAsCode/content/releases/latest | jq -r '.tag_name' | sed 's|v||'); \
    eleven git clone ${BUILD_SRC} v${SSG_VERSION}; \
    mkdir -p /distroless/${APP_ROOT}/var/ssg-content; \
    find ${BUILD_ROOT} -name 'ssg-*-ds.xml' -exec cp {} /distroless/${APP_ROOT}/var/ssg-content/ ";"; \
    echo "${SSG_VERSION}" > /distroless/${APP_ROOT}/var/ssg-content/.ssg-version;


# :: PATCHMON
  FROM 11notes/go:${APP_GO_VERSION} AS build
  ARG APP_VERSION \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN

  RUN set -eux; \
    apk --update --no-cache add \
      make \
      nodejs \
      npm;

  RUN set -ex; \
    eleven git clone ${BUILD_SRC} v${APP_VERSION};

  RUN set -eux; \
    cd ${BUILD_ROOT}/frontend; \
    npm install --ignore-scripts --legacy-peer-deps --no-audit --force; \
    npm run build;

  RUN set -eux; \
    cd ${BUILD_ROOT}; \
    cp -af ./frontend/dist ./server-source-code/cmd/server/static/frontend/;

  RUN set -eux; \
    cd ${BUILD_ROOT}/agent-source-code; \
    make build-all-for-docker;

  RUN set -eux; \
    cd ${BUILD_ROOT}; \
    find ./agents-prebuilt -not -name "*.exe" -exec ds {} ";"; \
    ds --bye;

  RUN set -eux; \
    cd ${BUILD_ROOT}/server-source-code/cmd/server/; \
    eleven go build ${BUILD_BIN} .;

  RUN set -eux; \
    eleven distroless ${BUILD_BIN};


# :: FILE SYSTEM
  FROM alpine AS file-system
  ARG APP_ROOT

  RUN set -ex; \
    mkdir -p /distroless${APP_ROOT}/var;


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE \
        BUILD_ROOT

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: app specific environment
    ENV POSTGRES_HOST="postgres" \
        POSTGRES_USER="postgres" \
        POSTGRES_DB="postgres" \
        REDIS_HOST="redis" \
        REDIS_PORT=6379 \
        REDIS_DB=0 \
        ENABLE_LOGGING="true" \
        LOG_LEVEL="info" \
        APP_ENV="production" \
        SSG_CONTENT_DIR="${APP_ROOT}/var/ssg-content" \
        AGENTS_DIR="${APP_ROOT}/src/agents" \
        TRUST_PROXY="true"

  # :: multi-stage
    COPY --from=distroless / /
    COPY --from=distroless-localhealth / /
    COPY --from=build /distroless/ /
    COPY --from=build ${BUILD_ROOT}/agents-prebuilt ${APP_ROOT}/src/agents
    COPY --from=build ${BUILD_ROOT}/agents ${APP_ROOT}/src/agents
    COPY --from=ssg /distroless/ /
    COPY --from=file-system --chown=${APP_UID}:${APP_GID} /distroless/ /

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/var"]

# :: MONITORING
  HEALTHCHECK --interval=10s --timeout=5s --start-period=30s \
    CMD ["/usr/local/bin/localhealth", "http://127.0.0.1:3000/health"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/PatchMon"]