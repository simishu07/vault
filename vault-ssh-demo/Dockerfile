# Use Ubuntu x86_64 architecture for compatibility with the SSH secrets engine
FROM --platform=linux/amd64 ubuntu:20.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages: OpenSSH and Vault dependencies
RUN apt-get update && \
    apt-get install -y openssh-server curl vim && \
    mkdir /var/run/sshd

# Set root password
RUN echo 'root:rootpassword' | chpasswd

# Expose SSH port
EXPOSE 22

# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]
