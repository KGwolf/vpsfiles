
echo
echo "===== 入站链路抓包准备 ====="

if ! command -v timeout >/dev/null 2>&1 || ! command -v tcpdump >/dev/null 2>&1; then
  echo "缺少 timeout 或 tcpdump，无法执行抓包"
else
  echo "请在接下来 30 秒内，让电脑上的 FClash 通过当前节点访问一次网站。"
  echo "开始抓取 VPS 443 入站流量..."

  timeout 30 tcpdump -ni eth0 -nn -tttt \
    'tcp dst port 443 and (tcp[tcpflags] & tcp-syn != 0 or tcp[tcpflags] & tcp-ack != 0)' \
    -c 100 2>&1

  echo
  echo "===== 抓包结束 ====="
fi
