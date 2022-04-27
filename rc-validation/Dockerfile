FROM apachepulsar/pulsar:latest

# Switch to root user to download tools
USER 0

# Install your preferred utilities
RUN apt-get update \
     && apt-get install -y jq \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/*
     
# Assuming you still want to run as a non root user by default
USER 10000