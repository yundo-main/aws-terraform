#!/usr/bin/env bash
# 03_aws 실습 결과 확인 스크립트
# terraform state + AWS CLI 조회 결과를 하나의 HTML 리포트로 생성한다.
# 사용법: ./check.sh [출력파일]   (기본: report.html)
set -u
cd "$(dirname "$0")"

REGION="ap-northeast-2"
OUT="${1:-report.html}"
NOW="$(date '+%Y-%m-%d %H:%M:%S')"

# 각 항목: "제목|명령어 문자열" — 실패해도 계속 진행
run() {
  local title="$1"; shift
  {
    echo "<h2>$title</h2>"
    echo "<pre>"
    "$@" 2>&1 | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
    echo "</pre>"
  } >> "$OUT.tmp"
}

cat > "$OUT.tmp" <<EOF
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<title>03_aws 실습 결과 — $NOW</title>
<style>
  body { font-family: -apple-system, 'Apple SD Gothic Neo', 'Noto Sans KR', sans-serif;
         background: #f8fafc; color: #122033; margin: 0; }
  .bar { height: 10px; background: #1769aa; }
  main { max-width: 1100px; margin: 0 auto; padding: 32px 40px 60px; }
  h1 { font-size: 28px; margin: 8px 0 4px; }
  .sub { color: #516174; font-size: 14px; margin-bottom: 28px; }
  h2 { font-size: 17px; color: #1769aa; border-bottom: 1px solid #c9d5e1;
       padding-bottom: 6px; margin-top: 32px; }
  pre { background: #fff; border: 1px solid #c9d5e1; border-radius: 8px;
        padding: 14px 16px; font-family: ui-monospace, Menlo, 'SF Mono', monospace;
        font-size: 12.5px; overflow-x: auto; white-space: pre; }
  .warn { color: #b86e00; }
</style>
</head>
<body>
<div class="bar"></div>
<main>
<h1>03_aws — Terraform 실습 결과</h1>
<p class="sub">생성 시각: $NOW · 리전: $REGION · 디렉터리: $(pwd)</p>
EOF

# --- Terraform 쪽 ---
run "terraform state list" terraform state list
run "terraform validate" terraform validate

# --- AWS CLI 쪽 ---
run "VPC" aws ec2 describe-vpcs --region "$REGION" \
  --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table

run "Subnets" aws ec2 describe-subnets --region "$REGION" \
  --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' --output table

run "Internet Gateway" aws ec2 describe-internet-gateways --region "$REGION" \
  --query 'InternetGateways[*].[InternetGatewayId,Attachments[0].VpcId]' --output table

run "NAT Gateway" aws ec2 describe-nat-gateways --region "$REGION" \
  --filter "Name=state,Values=available" \
  --query 'NatGateways[*].[NatGatewayId,State,SubnetId]' --output table

run "Elastic IP" aws ec2 describe-addresses --region "$REGION" \
  --query 'Addresses[*].[AllocationId,PublicIp]' --output table

run "Route Tables" aws ec2 describe-route-tables --region "$REGION" \
  --query 'RouteTables[*].[RouteTableId,Routes[*].[DestinationCidrBlock,GatewayId,NatGatewayId]|[]]' --output table

run "Security Groups" aws ec2 describe-security-groups --region "$REGION" \
  --query 'SecurityGroups[*].[GroupId,GroupName,Description]' --output table

run "EC2 (running)" aws ec2 describe-instances --region "$REGION" \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,PublicIpAddress,KeyName,Tags[?Key==`Name`].Value|[0]]' --output table

run "RDS" aws rds describe-db-instances --region "$REGION" \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine,EngineVersion,Endpoint.Address]' --output table

run "Key Pairs" aws ec2 describe-key-pairs --region "$REGION" \
  --query 'KeyPairs[*].[KeyName,CreateTime]' --output table

echo '</main></body></html>' >> "$OUT.tmp"
mv "$OUT.tmp" "$OUT"
echo "생성 완료: $(pwd)/$OUT"
