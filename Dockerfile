# --- Stage 1: ZMK build for firmware & processed device tree ---
FROM zmkfirmware/zmk-dev-arm:stable AS firmware

WORKDIR /workspace

# Copy ZMK west manifest, build scripts, configs, and overlays
COPY build.yaml build.yaml
COPY config/west.yml config/west.yml
COPY dockerScripts/build-firmware.sh dockerScripts/build-firmware.sh
COPY dockerScripts/entrypoint.sh dockerScripts/entrypoint.sh
COPY dockerScripts/pre-build.sh dockerScripts/pre-build.sh
COPY dockerScripts/overlays/ dockerScripts/overlays/

COPY config/ config/

RUN chmod +x dockerScripts/*.sh

# Zephyr expects a "safe" workspace
RUN git config --global --add safe.directory '*'

# Init west workspace, update deps, and export Zephyr
RUN west init -l config && \
    west update --fetch-opt=--filter=blob:none && \
    west zephyr-export

# Build firmware and device tree with local script
RUN dockerScripts/build-firmware.sh

# --- Stage 2: SVG Drawing ---
FROM python:3.12-slim AS draw

# Install helpers and keymap-drawer
RUN apt-get update && \
    apt-get install -y --no-install-recommends jq yq sed git && \
    rm -rf /var/lib/apt/lists/*
RUN pip install --upgrade pip && \
    pip install keymap-drawer

WORKDIR /workspace

# Copy firmware and processed device tree from previous stage
COPY --from=firmware /workspace/.build/corne_left/zephyr/zephyr.dts ./zephyr_left.dts
COPY --from=firmware /workspace/.build/corne_right/zephyr/zephyr.dts ./zephyr_right.dts
COPY --from=firmware /workspace/firmware/ ./firmware/
COPY --from=firmware /workspace/config/ ./config
COPY draw/ ./draw
COPY dockerScripts/ dockerScripts/
RUN ls -la /workspace
RUN ls -la /workspace/dockerScripts
RUN mkdir -p /workspace/drawings

RUN dockerScripts/draw-and-export.sh


# Create SVG drawing
CMD ["bash", "/workspace/dockerScripts/draw-and-export.sh"]
