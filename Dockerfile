FROM zmkfirmware/zmk-dev-arm:stable

# Set workdir for the build context
WORKDIR /build-context

# Copy the entire repository into the image
COPY . .

# Configure git safe directory
RUN git config --global --add safe.directory '*'

# Remove any existing west workspace to allow re-initialization
RUN rm -rf .west zmk zephyr modules .build west_modules

# Initialize west workspace, update dependencies, and export zephyr
# This bakes in all the ZMK dependencies
RUN west init -l config && \
    west update --fetch-opt=--filter=blob:none && \
    west zephyr-export

# Create build script that will be used at runtime
RUN echo '#!/bin/bash\nset -euo pipefail\n\n\
echo "Building firmware..."\n\n\
# Build Corne left\n\
west build -s zmk/app -d .build/corne_left -b nice_nano//zmk -- \\\n\
    -DZMK_CONFIG=$(pwd)/config \\\n\
    -DSHIELD=corne_left\n\
mkdir -p firmware\n\
if [ -f .build/corne_left/zephyr/zmk.uf2 ]; then\n\
    cp .build/corne_left/zephyr/zmk.uf2 firmware/corne_left.uf2\n\
    echo "Built firmware/corne_left.uf2"\n\
elif [ -f .build/corne_left/zephyr/zmk.bin ]; then\n\
    cp .build/corne_left/zephyr/zmk.bin firmware/corne_left.bin\n\
    echo "Built firmware/corne_left.bin"\n\
fi\n\n\
# Build Corne right\n\
west build -s zmk/app -d .build/corne_right -b nice_nano//zmk -- \\\n\
    -DZMK_CONFIG=$(pwd)/config \\\n\
    -DSHIELD=corne_right\n\
if [ -f .build/corne_right/zephyr/zmk.uf2 ]; then\n\
    cp .build/corne_right/zephyr/zmk.uf2 firmware/corne_right.uf2\n\
    echo "Built firmware/corne_right.uf2"\n\
elif [ -f .build/corne_right/zephyr/zmk.bin ]; then\n\
    cp .build/corne_right/zephyr/zmk.bin firmware/corne_right.bin\n\
    echo "Built firmware/corne_right.bin"\n\
fi\n\n\
echo "Build complete! Firmware files are in /build-context/firmware/"\n\
ls -la firmware/' > /usr/local/bin/build-firmware.sh && \
    chmod +x /usr/local/bin/build-firmware.sh

WORKDIR /workspace

# Default command: copy baked workspace to /workspace and build
ENTRYPOINT ["/bin/bash", "-c", "\
    if [ ! -d /workspace/.west ]; then\n\
        echo 'Copying pre-built ZMK workspace...'\n\
        cp -r /build-context/. /workspace/ 2>/dev/null || true\n\
        cp -r /build-context/.build /workspace/ 2>/dev/null || true\n\
        cp -r /build-context/zmk /workspace/ 2>/dev/null || true\n\
        cp -r /build-context/zephyr /workspace/ 2>/dev/null || true\n\
        cp -r /build-context/modules /workspace/ 2>/dev/null || true\n\
    fi\n\
    cd /workspace && /usr/local/bin/build-firmware.sh\n\
"]
