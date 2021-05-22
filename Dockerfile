FROM ubuntu:bionic

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-arm64/jre
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_CONF_DIR /opt/hadoop/etc/hadoop
ENV SPARK_HOME /opt/spark
ENV PATH="${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"
ENV HADOOP_VERSION 2.7.0
ENV PYSPARK_DRIVER_PYTHON=jupyter
ENV PYSPARK_DRIVER_PYTHON_OPTS='notebook'
ENV PYSPARK_PYTHON=python3.8

RUN apt-get update && \
    apt-get install -y wget nano openjdk-8-jdk ssh openssh-server openjdk-8-jre
RUN apt update && apt install -y python3-pip python3.8-dev build-essential libssl-dev libffi-dev libpq-dev python3.8 python3.8-distutils curl
RUN apt-get install python3-pip
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python3.8 get-pip.py

COPY /confs/requirements.req /
RUN python3.8 -m pip install -r requirements.req
RUN python3.8 -m pip install dask[bag] --upgrade
RUN python3.8 -m pip install --upgrade toree
RUN python3.8 -m bash_kernel.install

RUN wget -P /tmp/ https://archive.apache.org/dist/hadoop/core/hadoop-2.7.0/hadoop-2.7.0.tar.gz
RUN tar xvf /tmp/hadoop-2.7.0.tar.gz -C /tmp && \
	mv /tmp/hadoop-2.7.0 /opt/hadoop

RUN wget -P /tmp/ https://archive.apache.org/dist/spark/spark-2.4.5/spark-2.4.5-bin-hadoop2.7.tgz
RUN tar xvf /tmp/spark-2.4.5-bin-hadoop2.7.tgz -C /tmp && \
    mv /tmp/spark-2.4.5-bin-hadoop2.7 ${SPARK_HOME}

RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
	cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
	chmod 600 ~/.ssh/authorized_keys
COPY /confs/config /root/.ssh
RUN chmod 600 /root/.ssh/config

COPY /confs/*.xml /opt/hadoop/etc/hadoop/
COPY /confs/slaves /opt/hadoop/etc/hadoop/
COPY /script_files/bootstrap.sh /
COPY /confs/spark-defaults.conf ${SPARK_HOME}/conf

RUN jupyter toree install --spark_home=${SPARK_HOME}
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> /etc/environment

EXPOSE 9000
EXPOSE 7077
EXPOSE 4040
EXPOSE 8020
EXPOSE 22

RUN mkdir lab
COPY notebooks/*.ipynb /root/lab/
COPY datasets /root/lab/datasets

ENTRYPOINT ["/bin/bash", "bootstrap.sh"]
