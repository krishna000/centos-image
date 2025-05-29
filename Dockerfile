FROM --platform=linux/amd64 centos:7

USER root

# Copy yum configuration files
COPY yum.conf /etc/yum.conf
COPY ./*.repo /etc/yum.repos.d/

# Set bash as shell for subsequent commands
SHELL ["/bin/bash", "-c"]
RUN curl -fsSL https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-SCLo -o /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo
# Install necessary dependencies
RUN yum install -y epel-release yum-utils curl centos-release-scl devtoolset-11 gcc gcc-c++ make wget tar \
    zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel libffi-devel xz-devel git

# Install OpenSSL from source
RUN cd /usr/local/src \
    && wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz \
    && tar xzf openssl-1.1.1w.tar.gz \
    && cd openssl-1.1.1w \
    && ./config --prefix=/opt/openssl --openssldir=/opt/openssl shared zlib \
    && make -j$(nproc) && make install \
    && cd .. && rm -rf openssl-1.1.1w*

# Set OpenSSL environment variables
ENV LD_LIBRARY_PATH=/opt/openssl/lib:$LD_LIBRARY_PATH
ENV CPPFLAGS="-I/opt/openssl/include"
ENV LDFLAGS="-L/opt/openssl/lib"
# Download and build Python 3.11.9
RUN wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz \
    && tar -xzf Python-3.11.9.tgz \
    && cd Python-3.11.9 \
    && ./configure --enable-shared --prefix=/usr/local --with-openssl=/opt/openssl \
    && make -j$(nproc) \
    && make altinstall \
    && rm -rf Python-3.11.9 Python-3.11.9.tgz

# Set runtime environment for Python
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
# Check Python and pip versions
RUN /usr/local/bin/python3.11 --version && /usr/local/bin/pip3.11 --version

# Bootstrap pip and upgrade
RUN /usr/local/bin/python3.11 -m ensurepip --upgrade && \
    /usr/local/bin/pip3.11 install --upgrade pip setuptools

# Install pyinstaller
RUN /usr/local/bin/pip3.11 install pyinstaller

# Create symlinks for python3 and pip3
RUN ln -s /usr/local/bin/python3.11 /usr/bin/python3 && \
    ln -s /usr/local/bin/pip3.11 /usr/bin/pip3

# Final check for python3 and pip3
RUN python3 --version && pip3 --version
