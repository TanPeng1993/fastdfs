#版本 1.2.0

#基础镜像Centos7
FROM centos:7

MAINTAINER tanp "t798197079@live.cn"

#使用root账号
USER root

#一些基础操作
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
#RUN echo "nameserver 114.114.114.114">>/etc/resolv.conf
RUN yum -y update
#RUN yum -y groupinstall 'Development Tools'
RUN yum -y install git gcc gcc-c++ make automake autoconf libtool pcre pcre-devel zlib zlib-devel openssl-devel wget vim net-tools libevent libvent-devel

#创建相关目录
RUN mkdir -p /fastdfs/tracker
RUN mkdir -p /fastdfs/storage
RUN mkdir -p /root/upload_test 
RUN mkdir -p /usr/local/src/fdfs_nginx_conf
RUN mkdir -p /fastdfs/cache/nginx/proxy_cache/tmp
RUN mkdir -p /etc/fdht
RUN mkdir -p /fastdfs/fastdht
#RUN mkdir -p /fastdfs/nginx_read

#创建软连接
#RUN ln -s /fastdfs/storage /fastdfs/nginx_read/storage

#程序安装 
#切换到下载目录准备下载安装包
WORKDIR /usr/local/src
#安装libfatscommon
RUN git clone https://github.com/happyfish100/libfastcommon.git --depth 1
WORKDIR /usr/local/src/libfastcommon/
RUN ./make.sh && ./make.sh install

#切换到下载目录准备下载安装包
WORKDIR /usr/local/src
#安装FastDFS
RUN git clone https://github.com/happyfish100/fastdfs.git --depth 1
WORKDIR /usr/local/src/fastdfs/
RUN ./make.sh && ./make.sh install

#放入配置文件到指定目录
RUN cp /etc/fdfs/tracker.conf.sample /etc/fdfs/tracker.conf
RUN cp /etc/fdfs/storage.conf.sample /etc/fdfs/storage.conf
#客户端文件，测试用
RUN cp /etc/fdfs/client.conf.sample /etc/fdfs/client.conf
#供nginx访问使用
RUN cp /usr/local/src/fastdfs/conf/http.conf /etc/fdfs/
#供nginx访问使用
RUN cp /usr/local/src/fastdfs/conf/mime.types /etc/fdfs/

#切换到下载目录准备下载安装包
WORKDIR /usr/local/src
#下载fastdfs-nginx-module插件
RUN git clone https://github.com/happyfish100/fastdfs-nginx-module.git --depth 1
RUN cp /usr/local/src/fastdfs-nginx-module/src/mod_fastdfs.conf /etc/fdfs/
#下载ngx_cache_purge插件(如有需要可指定版本)
#RUN git clone -b 2.3 https://github.com/FRiCKLE/ngx_cache_purge.git --depth 1
RUN git clone https://github.com/FRiCKLE/ngx_cache_purge.git --depth 1

#安装nginx  带上插件
RUN wget http://nginx.org/download/nginx-1.12.2.tar.gz
RUN tar -zxvf nginx-1.12.2.tar.gz
WORKDIR /usr/local/src/nginx-1.12.2/
#添加fastdfs-nginx-module模块和ngx_cache_purge
RUN ./configure --add-module=/usr/local/src/fastdfs-nginx-module/src/ --add-module=/usr/local/src/ngx_cache_purge/
RUN make && make install

#切换到下载目录准备下载安装包
WORKDIR /usr/local/src
#RUN wget http://download.oracle.com/berkeley-db/db-6.2.32.tar.gz
COPY fastDHT/db-6.2.32.tar.gz /usr/local/src/db-6.2.32.tar.gz
RUN tar -zxvf db-6.2.32.tar.gz
WORKDIR /usr/local/src/db-6.2.32/build_unix
RUN ../dist/configure --prefix=/usr/local/db-6.2.32
RUN make && make install
RUN echo '/usr/local/db-6.2.32/lib/' >> /etc/ld.so.conf
RUN /sbin/ldconfig
#RUN ln -s /usr/local/db-6.2.32/lib/libdb-6.2.so /usr/lib/libdb-6.2.so 
#RUN ln -s /usr/local/db-6.2.32/lib/libdb-6.2.so /usr/lib64/libdb-6.2.so

#切换到下载目录准备下载安装包
WORKDIR /usr/local/src
RUN git clone https://github.com/happyfish100/fastdht.git --depth 1
#RUN rm -f /usr/local/src/fastdht/make.sh
#COPY fastDHT/make.sh /usr/local/src/fastdht/make.sh
RUN sed -i "s|'-Wall -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE'|'-Wall -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE -I/usr/local/db-6.2.32/include/ -L/usr/local/db-6.2.32/lib/'|g" /usr/local/src/fastdht/make.sh
WORKDIR /usr/local/src/fastdht
RUN ./make.sh
RUN ./make.sh install
#拷贝fastdht配置文件到指定目录
RUN cp /usr/local/src/fastdht/conf/fdht_client.conf /etc/fdht
RUN cp /usr/local/src/fastdht/conf/fdhtd.conf /etc/fdht
RUN cp /usr/local/src/fastdht/conf/fdht_servers.conf /etc/fdht


#软件配置
#替换掉nginx默认配置文件
#RUN rm -f /usr/local/nginx/conf/nginx.conf
#COPY nginxconf/nginx_storage.conf /usr/local/nginx/conf/nginx.conf
#拷贝nginx的Storage配置和Tracker配置
COPY nginxconf/*.* /usr/local/src/fdfs_nginx_conf/

#替换默认配置
RUN sed -i "s|base_path=/home/yuqing/fastdfs|base_path=/fastdfs/tracker|g" /etc/fdfs/tracker.conf
RUN sed -i -e "s|base_path=/home/yuqing/fastdfs|base_path=/fastdfs/storage|g" -e "s|store_path0=/home/yuqing/fastdfs|store_path0=/fastdfs/storage|g" /etc/fdfs/storage.conf
RUN sed -i -e "s|url_have_group_name = false|url_have_group_name = true|g" -e "s|store_path0=/home/yuqing/fastdfs|store_path0=/fastdfs/storage|g" /etc/fdfs/mod_fastdfs.conf
#RUN sed "s|url_have_group_name=false|url_have_group_name=true|g" /etc/fdfs/mod_fastdfs.conf
RUN sed -i "s|base_path=/home/yuqing/fastdfs|base_path=/fastdfs/tracker|g" /etc/fdfs/client.conf
#开启token验证
#RUN sed -i -e "s|http.anti_steal.check_token=false|http.anti_steal.check_token=true|g" -e "s|http.anti_steal.secret_key=FastDFS1234567890|http.anti_steal.secret_key=Bidhelper_FastDFS_CQCCC|g" -e "s|http.anti_steal.token_check_fail=/home/yuqing/fastdfs/conf/anti-steal.jpg|http.anti_steal.token_check_fail=/root/upload_test/testimg.gif|g" /etc/fdfs/http.conf

#修改fdht配置
RUN sed -i "s|base_path=/home/yuqing/fastdht|base_path=/fastdfs/fastdht|g" /etc/fdht/fdhtd.conf
#RUN sed -i -e "s|192.168.0.196|10.205.50.52|g" -e "s|192.168.0.116|10.205.50.61|g" /etc/fdht/fdht_servers.conf
RUN sed -i -e "s|base_path=/home/yuqing/fastdht|base_path=/fastdfs/fastdht|g" -e "s|keep_alive=0|keep_alive=1|g" /etc/fdht/fdht_client.conf
#RUN sed -i -e "s|check_file_duplicate=0|check_file_duplicate=1|g" -e "s|keep_alive=0|keep_alive=1|g" -e "s|##include /home/yuqing/fastdht/conf/fdht_servers.conf|#include /etc/fdht/fdht_servers.conf|g" /etc/fdfs/storage.conf


#简单配置单机参考,请注释上面的替换默认配置部分和前面的放入配置文件部分COPY命令,包括mod_fastdfs.conf配置文件，修改fdfsconf文件夹中对应文件的IP地址
#COPY fdfsconf/*.* /etc/fdfs/

#简单集群配置参考,请注释上面的替换默认配置部分和前面的放入配置文件部分COPY命令,包括mod_fastdfs.conf配置文件，修改colony_fdfsconf文件夹中对应文件的IP地址
#COPY colony_fdfsconf/*.* /etc/fdfs/

#启用带fdht的集群，请注释上面的替换默认配置部分和前面的放入配置文件部分COPY命令,包括mod_fastdfs.conf配置文件以及拷贝fastdht配置部分，修改fdhtconf文件夹中对应文件的IP地址
#COPY colony_fdfsconf_dht/*.* /etc/fdfs/
#COPY fdhtconf/*.* /etc/fdht/


#添加启动脚本
COPY start.sh /usr/bin/
#COPY old_start.sh /usr/bin/
#ADD stop.sh /usr/bin/

#添加测试文件
COPY upload_demo/*.* /root/upload_test

#添加说明文档
COPY README.md /root

#将工作目录置为root
WORKDIR /root

#添加执行权限
RUN chmod +x /usr/bin/start.sh
#RUN chmod +x /usr/bin/old_start.sh
#RUN chmod +x /usr/bin/stop.sh

#暴露端口
EXPOSE 22122 23000 8080 8888

#启动fastdfs
ENTRYPOINT ["/usr/bin/start.sh"]
#ENTRYPOINT ["/usr/bin/old_start.sh"]
CMD  ["storage"]


