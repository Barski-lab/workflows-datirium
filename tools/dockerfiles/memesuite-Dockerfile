#################################################################
# Dockerfile
#
# Software:         MEME Suite
# Software Version: v0.0.1
# Description:      Dockerized version of MEME Suite
# Website:          http://meme-suite.org/index.html
# Provides:         MEME Suite 5.1.0
# Base Image:       biowardrobe2/scidap:v0.0.3
# Build Cmd:        docker build --rm -t biowardrobe2/memesuite:v0.0.1 -f memesuite-Dockerfile .
# Pull Cmd:         docker pull biowardrobe2/memesuite:v0.0.1
# Run Cmd:          docker run --rm -ti biowardrobe2/memesuite:v0.0.1
#################################################################
#
# v0.0.1
#   None of the databases are installed. Image is build mainly for
#   MEME-ChIP tool. Additional modifications are required to run
#   other tools from the MEME Suite.
#
#################################################################

### Base Image
FROM biowardrobe2/scidap:v0.0.3
LABEL maintainer="misha.kotliar@gmail.com"
ENV DEBIAN_FRONTEND noninteractive

ENV VER_MEME 5.1.0
ENV URL_MEME http://meme-suite.org/meme-software/${VER_MEME}/meme-${VER_MEME}.tar.gz
ENV DIR_MEME /opt/meme

ENV PATH ${DIR_MEME}/bin:${DIR_MEME}/libexec/meme-${VER_MEME}:$PATH

################## BEGIN INSTALLATION ######################
WORKDIR /tmp

### Install required packages
RUN apt-get update && \
    apt-get install -y wget build-essential zlib1g-dev libexpat-dev libxml2-dev mpich ghostscript imagemagick && \
    cpan File::Which && \
    cpan HTML::PullParser && \ 
    cpan HTML::Template && \
    cpan HTML::TreeBuilder && \
    cpan JSON && \
    cpan XML::Simple && \
    cpan XML::Parser::Expat && \
    cpan Math::CDF && \
    cpan XML::Compile::SOAP11 && \
    cpan XML::Compile::WSDL11 && \
    cpan XML::Compile::Transport::SOAPHTTP && \
### Installing MEME Suite
    wget -q -O - $URL_MEME | tar -zxv && \
    cd meme-${VER_MEME} && \
    ./configure --prefix=${DIR_MEME} --with-url=http://meme-suite.org/ --enable-build-libxml2 --enable-build-libxslt && \
    make && \
    make install && \
    cd .. && \
    rm -rf meme-${VER_MEME} && \
### Cleaning
    apt-get clean && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* && \
    strip /usr/local/bin/*; true
