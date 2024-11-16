# Stage 1: Base Stage (Building the environment)
FROM ubuntu:22.04 AS base

# Install cron and other necessary utilities
RUN apt-get update && \
    apt-get install -y cron sudo && \
    apt-get clean

# Create the 'abc' user and set up the directory with specific permissions
RUN useradd -m abc && \
    mkdir -p /home/abc/Test && \
    chown -R abc:abc /home/abc/Test

# Set the working directory to /home/abc
WORKDIR /home/abc

# Stage 2: Intermediate Stage (Copy the script and setup cron job)
FROM base AS intermediate

# Switch to root user for copying files and setting permissions
USER root

# Copy the shell script to the container
COPY ./shell_script.sh /home/abc/

# Make the shell script executable
RUN chmod +x /home/abc/shell_script.sh

# Set up a cron job to run the script (with input 1) every minute
RUN (echo "* * * * * /home/abc/shell_script.sh 1 >> /home/abc/cron.log 2>&1") | crontab -u abc -

# Stage 3: Final Stage - Run cron job
FROM intermediate AS final

# Set proper permissions for /home/abc
RUN chown -R abc:abc /home/abc

# Start cron in the foreground
CMD ["cron", "-f"]
