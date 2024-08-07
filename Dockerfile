FROM ubuntu:22.04

# Install OpenJDK-8
RUN apt-get update --fix-missing && \
    apt-get install -y openjdk-8-jdk && \
    apt-get install -y ant && \
    apt-get install -y curl && \
    apt-get clean;
    
# Fix certificate issues
RUN apt-get update && \
    apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f;

# Instalar Python 2.7 e pip
RUN apt-get update && \
    apt-get install -y python2.7 && \
    apt-get install -y python-pip && \
    apt-get clean

# Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

# Downloading and installing Maven
## 1- Define a constant with the version of maven you want to install
ARG MAVEN_VERSION=3.8.8

## 2- Define a constant with the working directory
ARG USER_HOME_DIR="/root"

## 3- Define the SHA key to validate the maven download
ARG SHA=b4880fb7a3d81edd190a029440cdf17f308621af68475a4fe976296e71ff4a4b546dd6d8a58aaafba334d309cc11e638c52808a4b0e818fc0fd544226d952544

## 4- Define the URL where maven can be downloaded from
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

## 5- Create the directories, download maven, validate the download, install it, remove downloaded file and set links
RUN mkdir -p /usr/share/maven /usr/share/maven/ref && \
    curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 && \
    rm -f /tmp/apache-maven.tar.gz && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

## 6- Define environmental variables required by Maven, like Maven_Home directory and where the maven repo is located
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

# Install git
RUN apt-get -y install git && \
    apt-get clean;

# Install vim
RUN apt-get -y install vim && \
    apt-get clean;

# Clone repos
RUN git clone --recursive  --branch main --depth 1 https://github.com/galilasmb/joana_execution /home/joana_execution
# clone mergedataset to /home/joana_execution/conflicts_analyzer/downloads
RUN git clone --branch sdg-dataset --depth 1 https://github.com/galilasmb/mergedataset /home/joana_execution/conflicts_analyzer/downloads

RUN git clone --branch sdg-dataset --depth 1 https://github.com/galilasmb/mergedataset /home/temp_dataset && \
    mv /home/temp_dataset/* /home/joana_execution/conflicts_analyzer/downloads/ && \
    rm -rf /home/temp_dataset

# Add settings.xml
ADD ./settings.xml $USER_HOME_DIR/.m2/

# Run Build Union Script in mergedaset project
# Some build files are larger than 100 MB, not supported by Github, so they were separated using split, to union them, 
# run the script located at the root with the following command:
RUN cd /home/joana_execution/conflicts_analyzer/downloads && ./prepareDataset.sh
RUN cd /home/joana_execution/conflicts_analyzer/downloads && ./extract_jar.sh
