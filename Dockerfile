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

# Copy build scripts from dockerScripts/
COPY dockerScripts/build-firmware.sh /usr/local/bin/build-firmware.sh
RUN chmod +x /usr/local/bin/build-firmware.sh

# Copy entrypoint script
COPY dockerScripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

# Default command: copy baked workspace to /workspace and build
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
