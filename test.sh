
echo "========== CloudCone -> Cloudflare 网络测试 =========="
date

for family in 4 6; do
  echo
  echo "========== IPv${family} =========="

  for url in \
    "https://cp.cloudflare.com/generate_204" \
    "https://www.cloudflare.com/cdn-cgi/trace"
  do
    echo
    echo "目标: $url"

    for i in 1 2 3 4 5; do
      env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY \
      curl -"$family" -sS -o /dev/null \
        --connect-timeout 8 --max-time 15 \
        -w "第${i}次 HTTP=%{http_code} IP=%{remote_ip} TCP=%{time_connect}s TLS=%{time_appconnect}s 首字节=%{time_starttransfer}s 总计=%{time_total}s\n" \
        "$url" 2>&1
    done
  done
done

echo
echo "========== Cloudflare 实际机房 =========="
env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY \
curl -4 -sS --connect-timeout 8 --max-time 15 \
https://www.cloudflare.com/cdn-cgi/trace

echo
echo "========== 路由信息 =========="
ip route get 1.1.1.1
ip -6 route get 2606:4700:4700::1111 2>&1
echo
echo "========== 测试结束 =========="
