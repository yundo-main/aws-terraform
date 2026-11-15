#!/usr/bin/env bash
# step1 네트워크 결과 결과 확인 스크립트 — apply 직후 이 단계의 리소스만 검증
# 사용법: ./check.sh [출력파일]   (기본: report.html)
set -u
cd "$(dirname "$0")"
REGION="ap-northeast-2"
OUT="${1:-report.html}"
NOW="$(date '+%Y-%m-%d %H:%M:%S')"
run() { local title="$1"; shift
  { echo "<h2>$title</h2><pre>"; "$@" 2>&1 | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; echo "</pre>"; } >> "$OUT.tmp"; }
cat > "$OUT.tmp" <<EOF
<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8"><title>step1 결과 — $NOW</title>
<style>
body{font-family:-apple-system,'Apple SD Gothic Neo','Noto Sans KR',sans-serif;background:#f8fafc;color:#122033;margin:0}
.bar{height:10px;background:#1769aa}main{max-width:1100px;margin:0 auto;padding:32px 40px 60px}
h1{font-size:28px;margin:8px 0 4px}.sub{color:#516174;font-size:14px;margin-bottom:28px}
h2{font-size:17px;color:#1769aa;border-bottom:1px solid #c9d5e1;padding-bottom:6px;margin-top:32px}
pre{background:#fff;border:1px solid #c9d5e1;border-radius:8px;padding:14px 16px;font-family:ui-monospace,Menlo,'SF Mono',monospace;font-size:12.5px;overflow-x:auto;white-space:pre}
</style></head><body><div class="bar"></div><main>
<h1>step1 — 네트워크 결과</h1><p class="sub">생성 시각: $NOW · 리전: $REGION · 디렉터리: $(pwd)</p>
EOF
run "terraform state list" terraform state list
run "terraform output (VPC·서브넷 ID)" terraform output
run "VPC" aws ec2 describe-vpcs --region "$REGION" --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table
run "Subnets" aws ec2 describe-subnets --region "$REGION" --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch,Tags[?Key==`Name`].Value|[0]]' --output table
run "Internet Gateway" aws ec2 describe-internet-gateways --region "$REGION" --query 'InternetGateways[*].[InternetGatewayId,Attachments[0].VpcId,Tags[?Key==`Name`].Value|[0]]' --output table
run "NAT Gateway + EIP" aws ec2 describe-nat-gateways --region "$REGION" --filter "Name=state,Values=available,pending" --query 'NatGateways[*].[NatGatewayId,State,SubnetId]' --output table
run "Elastic IP" aws ec2 describe-addresses --region "$REGION" --query 'Addresses[*].[AllocationId,PublicIp,NetworkBorderGroup]' --output table
run "Route Tables" aws ec2 describe-route-tables --region "$REGION" --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0],Routes[*].[DestinationCidrBlock,GatewayId,NatGatewayId]]' --output table
echo "</main></body></html>" >> "$OUT.tmp"
mv "$OUT.tmp" "$OUT"
echo "→ $OUT 생성 완료"
