FROM ubuntu:24.04

# Install prerequisites
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    wget \
    tftpd-hpa \
    apache2 \
    && rm -rf /var/lib/apt/lists/*

# Download Talos Linux files
RUN mkdir /talos
WORKDIR /talos
RUN curl -L https://github.com/siderolabs/talos/releases/download/v1.9.0/vmlinuz-amd64 -o vmlinuz-amd64
RUN curl -L https://github.com/siderolabs/talos/releases/download/v1.9.0/initramfs-amd64.xz -o initramfs-amd64.xz

# Copy Talos files to TFTP and Apache directories
RUN mkdir -p /var/lib/tftpboot/talos
RUN cp vmlinuz-amd64 /var/lib/tftpboot/talos/vmlinuz
RUN cp initramfs-amd64.xz /var/lib/tftpboot/talos/initrd.xz
RUN mkdir -p /var/www/html/talos
RUN cp vmlinuz-amd64 initramfs-amd64.xz /var/www/html/talos/

# Configure TFTP server
RUN echo "RUN_DIRECTORIES="/var/lib/tftpboot"" >> /etc/default/tftpd-hpa

# Configure Apache server
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN echo "<Directory /var/www/html/talos>" >> /etc/apache2/apache2.conf
RUN echo "    Options Indexes FollowSymLinks" >> /etc/apache2/apache2.conf
RUN echo "    Require all granted" >> /etc/apache2/apache2.conf
RUN echo "</Directory>" >> /etc/apache2/apache2.conf

# Expose ports
EXPOSE 69/udp
EXPOSE 80

# Start services
CMD /usr/sbin/in.tftpd --listen --user nobody --address 0.0.0.0:69 --secure /var/lib/tftpboot & \
    /usr/sbin/apache2ctl -D FOREGROUND

