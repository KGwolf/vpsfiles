
echo
echo "========================================"
echo " VPS 内部代理链路诊断"
echo "========================================"

echo
echo "===== 1. 系统负载 ====="
uptime
echo
free -h

echo
echo "===== 2. CPU 占用最高的进程 ====="
ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -12

echo
echo "===== 3. 服务状态 ====="
for svc in nginx x-ui; do
  echo "--- $svc ---"
  systemctl is-active "$svc" 2>&1
  systemctl show "$svc" -p ActiveState -p SubState -p MainPID 2>/dev/null
done

echo
echo "===== 4. 关键端口监听 ====="
ss -lntp | grep -E ':(443|10000)\b' || echo "未发现目标监听端口"

echo
echo "===== 5. TCP 连接统计 ====="
ss -s
echo
echo "--- 443 连接 ---"
ss -ant | grep -E '(:443[[:space:]]|:443$)' | head -30
echo
echo "--- Xray 10000 连接 ---"
ss -ant | grep -E '(:10000[[:space:]]|:10000$)' | head -30

echo
echo "===== 6. Nginx 配置检查 ====="
nginx -t 2>&1

echo
echo "===== 7. Nginx 最近错误 ====="
journalctl -u nginx --since "30 minutes ago" --no-pager -n 30 2>&1

echo
echo "===== 8. X-UI / Xray 最近日志 ====="
journalctl -u x-ui --since "30 minutes ago" --no-pager -n 40 2>&1

echo
echo "===== 9. Nginx error.log 最近记录 ====="
tail -20 /var/log/nginx/error.log 2>/dev/null

echo
echo "========================================"
echo " VPS 内部诊断结束"
echo "========================================"
