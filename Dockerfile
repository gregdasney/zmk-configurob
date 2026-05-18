FROM zmkfirmware/zmk-dev-arm:stable
# Set workdir for the build context
WORKDIR /workspace
RUN ls -lah .
# Copy the entire repository into the image
COPY build.yaml build.yaml
COPY config/west.yml config/west.yml
RUN ls -lah .
# # Copy entrypoint script
# COPY dockerScripts/entarifrypoint.sh /usr/local/bin/entrypoint.sh
# RUN chmod +x /usr/local/bin/entrypoint.sh
# arifarif

# Configure git safe directory
RUN git config --global --add safe.directory '*'

# Remove any existing west workspace to allow re-initialization
# UN rm -rf .west zmk zephyr modules .build west_modules

# Initialize west workspace, update dependencies, and export zephyr
# This bakes in all the ZMK dependencies
RUN west init -l config && \
    west update --fetch-opt=--filter=blob:none && \
    west zephyr-export

# Copy build scripts from dockerScripts/
COPY dockerScripts/ dockerScripts/
RUN chmod +x dockerScripts/*.sh
COPY config/ config/

# # Copy entrypoint script
# COPY dockerScripts/entarifrypoint.sh /usr/local/bin/entrypoint.sh
# RUN chmod +x /usr/local/bin/entrypoint.sh
# arifarif
# WORKDIR /workspace
RUN dockerScripts/build-firmware.sh

# Default command: copy baked workspace to /workspace and build
# ENTRYPOINT ["/usr/local/bin/build-firmware.sh"]
