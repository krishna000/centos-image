FROM --platform=linux/amd64 centos:7

USER root

COPY yum.conf /etc/yum.conf

COPY ./*.repo /etc/yum.repos.d/

SHELL ["/bin/bash", "-c"]

RUN yum install -y epel-release

RUN yum install -y yum-utils

RUN yum install -y curl

# Download valid GPG key for CentOS SCLo from CentOS official site (correct URL & flags)
RUN curl -fsSL https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-SCLo -o /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

RUN yum install -y centos-release-scl

RUN yum install -y devtoolset-11

RUN yum install -y gcc gcc-c++ make wget tar zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel libffi-devel xz-devel git openssl11 openssl11-devel

# Set OpenSSL 1.1 environment variables for build and runtime
ENV LD_LIBRARY_PATH=/usr/lib64/openssl11
ENV CPPFLAGS="-I/usr/include/openssl11"
ENV LDFLAGS="-L/usr/lib64/openssl11"
ENV PATH=/opt/rh/devtoolset-11/root/usr/bin:$PATH

# Download Python source
RUN wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz

# Extract source
RUN tar -xzf Python-3.11.9.tgz

RUN ls -l Python-3.11.9

# Configure Python build with OpenSSL paths
RUN cd Python-3.11.9 && ./configure --prefix=/usr/local --enable-optimizations --with-openssl=/usr/include/openssl11 --with-openssl-rpath=/usr/lib64/openssl11

# Build Python (parallel make)
RUN cd Python-3.11.9 && make -j$(nproc)

# Install Python
RUN cd Python-3.11.9 && make altinstall

# Cleanup source and tarball
RUN rm -rf Python-3.11.9 Python-3.11.9.tgz

# Check Python version
RUN /usr/local/bin/python3.11 --version

# Bootstrap pip for Python 3.11
RUN /usr/local/bin/python3.11 -m ensurepip --upgrade

# Upgrade pip explicitly
RUN /usr/local/bin/pip3.11 install --upgrade pip

# Check pip version
RUN /usr/local/bin/pip3.11 --version

# Check that SSL module loads and OpenSSL version prints correctly
# RUN /usr/local/bin/python3.11 -c "import ssl; print(ssl.OPENSSL_VERSION)"

# Install pyinstaller via pip
RUN /usr/local/bin/pip3.11 install pyinstaller
# RUN /usr/local/bin/pip3.11 install pyinstaller==6.13.0 --trusted-host pypi.org --trusted-host files.pythonhosted.org --index-url http://pypi.org/simple

# Check pyinstaller version
# RUN /usr/local/bin/pyinstaller --version

# Create convenient symlinks
RUN ln -s /usr/local/bin/python3.11 /usr/bin/python3

RUN ln -s /usr/local/bin/pip3.11 /usr/bin/pip3

RUN python3 --version && pip3 --version
