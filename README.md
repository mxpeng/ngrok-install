# ngrok安装脚本，适用于Centos7版本服务器

使用 https://github.com/prikevs/ngrok 增加身份验证的ngrok
> https://prikevs.github.io/2016/12/26/add-authentication-to-ngrok/

### 安装说明：
1. 授权

    ```bash
    chmod +x ngrok-install.sh
    ```
    
2. 运行安装脚本，按照提示输入

    ```bash
    ./ngrok-install.sh
    ```
    
3. 下载客户端

    前往 `/usr/local/ngrok/` 下载对应客户端 

### 使用说明
- 启动
    ```bash
    service ngrok start
    ```

- 停止
    ```bash
    service ngrok stop
    ```

- 重启
    ```bash
    service ngrok restart
    ```
- 开机启动
    ```bash
    systemctl enable ngrok.service
    ```

### 路径

- 安装路径
    ```bash
    /usr/local/ngrok
    ```

- 配置文件路径
    ```bash
    /etc/ngrok/
    ```
    - ngrok-cli.yml 客户端配置文件
    - ngrok-secrets 身份验证配置文件
    - ngrok-server 服务端配置文件
 
- 日志路径
    ```bash
    /var/log/ngrok/
    ```
    
### 其他
- [nginx 和 ngrok 同时使用](https://github.com/mxpeng/ngrok-install/tree/master/nginx)