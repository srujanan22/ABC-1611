# Stage 1: Base Stage (Building the environment)
FROM ubuntu:latest AS base-stage

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install cron and other necessary packages
RUN apt-get update && \
    apt-get install -y cron && \
    apt-get clean

# Create 'abc' user
RUN useradd -m abc

# Create the folder /aa/bb/cc and set ownership to the 'abc' user
RUN mkdir -p /aa/bb/cc && \
    chown -R abc:abc /aa/bb/cc

# Stage 2: Intermediate Stage (Copy the shell script and setup cron)
FROM base-stage AS intermediate-stage

# Copy the shell script into the container
COPY script.sh /path/to/your/script.sh

# Change permissions to make the script executable
RUN chmod +x /path/to/your/script.sh

# Setup a cron job to run the script with input '0' (to delete folder)
RUN echo "*/5 * * * * abc /path/to/your/script.sh 0" > /etc/cron.d/run_script

# Stage 3: Cleanup Stage (Run the script initially as cron with '0' input)
FROM intermediate-stage AS cleanup-stage

# Ensure the folder has proper permissions for the 'abc' user to delete it
RUN chown -R abc:abc /aa/bb/cc

# Install cron and run the cron jobs
RUN crontab /etc/cron.d/run_script && \
    cron && \
    su - abc -c "/path/to/your/script.sh 0"

# Stage 4: Create Stage (Setup another cron job to run the script with input '1')
FROM cleanup-stage AS create-stage

# Add another cron job to run the script with input '1' (to create folder and file)
RUN echo "@reboot abc /path/to/your/script.sh 1" >> /etc/cron.d/run_script

# Final Stage: Run cron in the foreground
FROM create-stage AS final-stage

# Keep the container running with cron jobs
CMD ["cron", "-f"]

