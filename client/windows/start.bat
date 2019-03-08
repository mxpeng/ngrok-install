@echo off

::set /p subdomain=请输入子域：

::获取日期 将格式设置为：20110820
set datevar=%date:~0,4%%date:~5,2%%date:~8,2%
::获取时间中的小时 将格式设置为：24小时制
set timevar=%time:~0,2%
if /i %timevar% LSS 10 (
set timevar=0%time:~1,1%
)
::获取时间中的分、秒 将格式设置为：3220 ，表示 32分20秒
set timevar=%timevar%%time:~3,2%%time:~6,2%

set log_dir=./log

if not exist "%log_dir%" md "%log_dir%"

::写入日志文件
echo %datevar%%timevar%>>"%log_dir%/ngrok_start_log.txt"

::启动
ngrok -log=./log/ngrok_%datevar%_%timevar%.log -config=./ngrok-cli.yml  start-all

