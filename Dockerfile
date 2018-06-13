#版本 1.0.0

#基础镜像Centos7
FROM centos:7

MAINTAINER tanp "t798197079@live.cn"

#使用root账号
USER root

#一些基础操作
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
RUN yum update
#RUN yum -y groupinstall 'Development Tools'
RUN yum -y install git gcc gcc-c++ make automake autoconf libtool pcre pcre-devel zlib zlib-devel openssl-devel wget vim net-tools

#创建storage和tracker的存放目录
RUN mkdir -p /fastdfs/tracker
RUN mkdir -p /fastdfs/storage
RUN mkdir -p /root/upload_test 
#RUN mkdir -p /home/yuqing/fastdfs
#RUN mkdir -p /logs
  
#切换到安装目录准备下载安装包
WORKDIR /usr/local/src
#安装libfatscommon
RUN git clone https://github.com/happyfish100/libfastcommon.git --depth 1
WORKDIR /usr/local/src/libfastcommon/
RUN ./make.sh && ./make.sh install

#切换到安装目录准备下载安装包
WORKDIR /usr/local/src
#安装FastDFS
RUN git clone https://github.com/happyfish100/fastdfs.git --depth 1
WORKDIR /usr/local/src/fastdfs/
RUN ./make.sh && ./make.sh install

#配置文件准备
#COPY /etc/fdfs/tracker.conf.sample /etc/fdfs/tracker.conf
#COPY /etc/fdfs/storage.conf.sample /etc/fdfs/storage.conf
#客户端文件，测试用
#COPY /etc/fdfs/client.conf.sample /etc/fdfs/client.conf
#供nginx访问使用
#COPY /usr/local/src/fastdfs/conf/http.conf /etc/fdfs/
#供nginx访问使用
#COPY /usr/local/src/fastdfs/conf/mime.types /etc/fdfs/

#切换到安装目录准备下载安装包
WORKDIR /usr/local/src
#安装fastdfs-nginx-module
RUN git clone https://github.com/happyfish100/fastdfs-nginx-module.git --depth 1
#COPY /usr/local/src/fastdfs-nginx-module/src/mod_fastdfs.conf /etc/fdfs

#安装nginx
RUN wget http://nginx.org/download/nginx-1.12.2.tar.gz
RUN tar -zxvf nginx-1.12.2.tar.gz
WORKDIR /usr/local/src/nginx-1.12.2/
#添加fastdfs-nginx-module模块
RUN ./configure --add-module=/usr/local/src/fastdfs-nginx-module/src/
RUN make && make install

#替换掉nginx默认配置文件
RUN rm -f /usr/local/nginx/conf/nginx.conf
COPY nginx.conf /usr/local/nginx/conf/nginx.conf

#替换默认配置
#RUN sed "s|base_path=/home/yuqing/fastdfs|base_path=/fastdfs/tracker|g" /etc/fdfs/tracker.conf
#RUN sed "s|base_path=/home/yuqing/fastdfs|base_path=/fastdfs/storage|g" /etc/fdfs/storage.conf
#RUN sed "s|store_path0=/home/yuqing/fastdfs|store_path0=/fastdfs/storage|g" /etc/fdfs/storage.conf
#RUN sed "s|url_have_group_name=false|url_have_group_name=true|g" /etc/fdfs/mod_fastdfs.conf
#RUN sed "s|store_path0=/home/yuqing/fastdfs|store_path0=/fastdfs/storage|g" /etc/fdfs/mod_fastdfs.conf
#RUN sed "s|base_path=/home/yuqing/fastdfs|base_path=/fastdfs/tracker|g" /etc/fdfs/client.conf
COPY conf/*.* /etc/fdfs/

#添加启动脚本
COPY start.sh /usr/bin/
#ADD stop.sh /usr/bin/

#添加说明文档
COPY README.md /root

#将工作目录置为root
WORKDIR /root

#添加执行权限
RUN chmod +x /usr/bin/start.sh
#RUN chmod +x /usr/bin/stop.sh

#暴露端口
EXPOSE 22122 23000 8080 8888

#启动fastdfs
ENTRYPOINT ["/usr/bin/start.sh"]

CMD  ["tracker"]
