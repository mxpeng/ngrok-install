# nginx 和 ngrok 同时使用

nginx 和 ngrok 同时使用时，但是只有一个80和443端口，换用其他端口的话，url 上带上端口比较丑，是强迫症不能忍受的，所以可以通过使用 nginx 进行反向代理进行隐藏

```text
server {
    listen 80;
    server_name *.ngrok.mxpeng.com; 

    location / {
        proxy_set_header Host  $http_host:81;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Nginx-Proxy true;
        proxy_set_header Connection "";
        
        proxy_pass      http://127.0.0.1:81;
    }
}
```

注意
> ngrokd 里面有一层自己的 Host 处理，于是 proxy_set_header Host 必须带上 ngrokd 所监听的端口，否则就算请求被转发到对应端口上， ngrokd 也不会正确的处理。

但是带上端口号又有重定向错误问题
> 带上端口号又会导致了另一个操蛋的问题：你请求的时候是 sub.yii.im，你在 web 应用中获取到的 Host 是 sub.yii.im:8081，如果你的程序里面有基于 Request Host 的重定向，就会被重定向到 sub.yii.im:8081 下面去。

于是参看这位博主的 `端口问题（可选）` 部分进行修改
> https://yii.im/posts/pretty-self-hosted-ngrokd/

可能是因为弹性ip, `ifconfig` 并没有显示出 公网ip

于是采用 内网ip：xxx.xxx.xxx.xxx 和 127.0.0.1， nginx 监听内网ip，ngrok监听 127.0.0.1

## 步骤
使用 ngrok-install.sh 安装ngrok 后的流程

1. 停止 nginx 参考当前目录下的 `ngrok.conf` 修改配置

2. 停止 ngrok 修改 ngrok 端口

```bash
service ngrok stop

vim /etc/ngrok/ngrok-server

# 修改下列2项
ngrok_http_port=127.0.0.1:80
ngrok_https_port=127.0.0.1:443
```

3. 重启nginx 和 ngrok