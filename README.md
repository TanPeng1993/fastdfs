# fastdfs v5.1x
这是一个基于docker的fastdfs单机版,参考 https://blog.csdn.net/ty5546/article/details/79245648 的fastdfs集群搭建教程和dockerhub中liuhuiguo的fastdfs镜像。
已集成的镜像中各软件版本： centos:7 fastdfs：5.12 nginx:1.12.2 fastdfs-nginx-module:1.20  libfastcommon:1.38
软件下载目录：/usr/local/src

使用说明：
可以选择导入镜像或者执行dockerfile 方法自己查找
  启动tracker（可以修改机器外的目录，也可以修改dockerfile和conf中创建的目录或者不使用映射目录）
  docker run -itd --net=host --name tracker -v /home/fastdfs/tracker:/fastdfs/tracker fastdfs tracker  
  启动storage
  docker run -itd --net=host --name storage -v /home/fastdfs/storage:/fastdfs/storage fastdfs storage
  启动nginx
  docker run -itd --net=host --name nginx -v /home/fastdfs/storage:/fastdfs/storage fastdfs nginx
  测试客户端
  docker run -itd --net=host --name client fastdfs monitor
  
  可以选择启动storage-nginx而不单独启动nginx
  docker run -itd --net=host --name storage -v /home/fastdfs/storage:/fastdfs/storage fastdfs storage-nginx
  
  单机版中创建tracker和storage命令可直接指定参数TRACKER_SERVER的地址,GROUP和PORT,tracker配置文件没有TRACKER_SERVER，使用也无效。
  #启动storagr-nginx和nginx可以指定
  比如：
  docker run -itd --net=host --name tracker2 -e PORT=22222 -v /home/fastdfs/tracker:/fastdfs/tracker fastdfs tracker  
  docker run -itd --network=host --name storage2 -e TRACKER_SERVER=10.1.5.85:22122 -e GROUP_NAME=group2 -e PORT=22222 -v /var/fdfs/storage2:/var/fdfs luhuiguo/fastdfs storage
  
  
  
  
  
