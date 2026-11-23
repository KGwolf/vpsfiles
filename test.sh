
# ============================================================
# VPS 443 入站 TCP 专项诊断
# 只读抓包，不修改 Nginx / Xray / 防火墙配置
# ============================================================

echo
echo "============================================================"
echo "          VPS 443 入站 TCP 专项诊断"
echo "============================================================"

PCAP="/tmp/proxy-inbound-$(date +%Y%m%d-%H%M%S).pcap"

echo
echo "===== 1. 检查抓包工具 ====="

if ! command -v tcpdump >/dev/null 2>&1; then
    echo "FAIL: 未安装 tcpdump，本轮无法抓包。"
    exit 0
fi

if ! command -v timeout >/dev/null 2>&1; then
    echo "FAIL: 未找到 timeout。"
    exit 0
fi

echo "tcpdump: $(command -v tcpdump)"
echo "timeout: $(command -v timeout)"

echo
echo "===== 2. 当前 443 连接情况 ====="

ss -ant | grep -E '(:443[[:space:]]|:443$)' | head -30

echo
echo "===== 3. 开始抓取 443 入站流量 ====="
echo
echo "请现在在电脑上使用 FClash 当前节点访问网站。"
echo "抓包持续 25 秒，请尽量在这段时间内产生实际流量。"
echo

timeout 25 tcpdump \
    -ni eth0 \
    -nn \
    -s 0 \
    -U \
    -w "$PCAP" \
    'tcp dst port 443' 2>&1

echo
echo "===== 4. 抓包文件信息 ====="

if [ ! -s "$PCAP" ]; then
    echo "FAIL: 抓包文件不存在或为空。"
    exit 0
fi

ls -lh "$PCAP"

echo
echo "===== 5. TCP 抓包基本统计 ====="

tcpdump -nn -r "$PCAP" 2>/dev/null | wc -l | awk '{print "数据包数量:", $1}'

echo
echo "===== 6. TCP 重传 / 重复 ACK / 乱序分析 ====="

if command -v tshark >/dev/null 2>&1; then

    echo "--- 重传 ---"
    tshark -r "$PCAP" \
      -Y 'tcp.analysis.retransmission || tcp.analysis.fast_retransmission' \
      -T fields \
      -e frame.time_relative \
      -e ip.src \
      -e tcp.srcport \
      -e tcp.dstport | head -40

    echo
    echo "--- 重复 ACK ---"
    tshark -r "$PCAP" \
      -Y 'tcp.analysis.duplicate_ack' \
      -T fields \
      -e frame.time_relative \
      -e ip.src \
      -e tcp.srcport \
      -e tcp.dstport | head -40

    echo
    echo "--- 乱序 ---"
    tshark -r "$PCAP" \
      -Y 'tcp.analysis.out_of_order' \
      -T fields \
      -e frame.time_relative \
      -e ip.src \
      -e tcp.srcport \
      -e tcp.dstport | head -40

    echo
    echo "===== 7. TCP 分析汇总 ====="

    tshark -r "$PCAP" -q -z io,stat,1 2>&1 | tail -35

else
    echo "未安装 tshark，本轮不安装软件。"
    echo "已保存原始抓包文件，可供后续分析。"

    echo
    echo "--- 抓包中的 TCP 标志 ---"
    tcpdump -nn -tt -r "$PCAP" 2>/dev/null | \
      grep -E 'Flags \[S|Flags \[P|Flags \[R|Flags \[F' | head -40
fi

echo
echo "===== 8. 结束 ====="
echo "抓包文件: $PCAP"
echo "本次诊断没有修改任何网络配置。"
echo "============================================================"

# ============================================================
# 修正版：只抓 VPS IPv4 入站 443
# ============================================================

echo
echo "================================================"
echo " VPS IPv4 入站 443 专项抓包"
echo "================================================"

PCAP="/tmp/proxy-inbound-v2-$(date +%Y%m%d-%H%M%S).pcap"

echo
echo "===== 1. 确认本机公网 IPv4 ====="
ip -4 addr show dev eth0

echo
echo "===== 2. 开始抓包 ====="
echo "请在接下来 30 秒内，通过 FClash 当前节点访问网站。"
echo

timeout 30 tcpdump \
  -ni eth0 \
  -nn \
  -s 0 \
  -U \
  -w "$PCAP" \
  'host 64.112.41.121 and tcp port 443' 2>&1

echo
echo "===== 3. 抓包结果 ====="
ls -lh "$PCAP"

echo
echo "===== 4. 入站数据包明细 ====="
tcpdump -nn -tttt -r "$PCAP" 2>/dev/null | head -100

echo
echo "===== 5. TCP 标志统计 ====="
tcpdump -nn -r "$PCAP" 2>/dev/null |
awk '
/Flags \[S\]/ {syn++}
/Flags \[S\.\]/ {synack++}
/Flags \[P\.\]/ {data++}
/Flags \[R/ {rst++}
/Flags \[F/ {fin++}
END {
  print "SYN:", syn+0
  print "SYN-ACK:", synack+0
  print "数据包:", data+0
  print "RST:", rst+0
  print "FIN:", fin+0
}'

echo
echo "===== 6. TCP 连接状态 ====="
ss -ant | grep '64.112.41.121:443' | head -30

echo
echo "抓包文件：$PCAP"
echo "诊断结束"
echo "================================================"


echo
echo "========== Cloudflare IPv4 / IPv6 对照 =========="

for family in -4 -6; do
  echo
  echo "===== $family cp.cloudflare.com ====="

  curl "$family" -sS -o /dev/null \
    --connect-timeout 5 \
    --max-time 10 \
    -w "HTTP=%{http_code} IP=%{remote_ip} TCP=%{time_connect}s TLS=%{time_appconnect}s FIRST=%{time_starttransfer}s TOTAL=%{time_total}s\n" \
    https://cp.cloudflare.com/generate_204

  echo
  echo "===== $family www.cloudflare.com ====="

  curl "$family" -sS -o /dev/null \
    --connect-timeout 5 \
    --max-time 10 \
    -w "HTTP=%{http_code} IP=%{remote_ip} TCP=%{time_connect}s TLS=%{time_appconnect}s FIRST=%{time_starttransfer}s TOTAL=%{time_total}s\n" \
    https://www.cloudflare.com/cdn-cgi/trace
done
