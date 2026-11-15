#!/usr/bin/env bash
# step3 EKS·ECR 결과 결과 확인 스크립트 — apply 직후 이 단계의 리소스만 검증
# 사용법: ./check.sh [출력파일]   (기본: report.html)
set -u
cd "$(dirname "$0")"
REGION="ap-northeast-2"
OUT="${1:-report.html}"
NOW="$(date '+%Y-%m-%d %H:%M:%S')"
run() { local title="$1"; shift
  { echo "<h2>$title</h2><pre>"; "$@" 2>&1 | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; echo "</pre>"; } >> "$OUT.tmp"; }
cat > "$OUT.tmp" <<EOF
<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8"><title>step3 결과 — $NOW</title>
<style>
body{font-family:-apple-system,'Apple SD Gothic Neo','Noto Sans KR',sans-serif;background:#f8fafc;color:#122033;margin:0}
.bar{height:10px;background:#1769aa}main{max-width:1100px;margin:0 auto;padding:32px 40px 60px}
h1{font-size:28px;margin:8px 0 4px}.sub{color:#516174;font-size:14px;margin-bottom:28px}
h2{font-size:17px;color:#1769aa;border-bottom:1px solid #c9d5e1;padding-bottom:6px;margin-top:32px}
pre{background:#fff;border:1px solid #c9d5e1;border-radius:8px;padding:14px 16px;font-family:ui-monospace,Menlo,'SF Mono',monospace;font-size:12.5px;overflow-x:auto;white-space:pre}
</style></head><body><div class="bar"></div><main>
<h1>step3 — EKS·ECR 결과</h1><p class="sub">생성 시각: $NOW · 리전: $REGION · 디렉터리: $(pwd)</p>
EOF
run "terraform state list" terraform state list
run "EKS 클러스터" aws eks describe-cluster --region "$REGION" --name terraform-eks-cluster --query 'cluster.{name:name,status:status,version:version,endpoint:endpoint}' --output table
run "EKS 노드그룹" aws eks list-nodegroups --region "$REGION" --cluster-name terraform-eks-cluster --output table
run "노드 EC2 인스턴스" aws ec2 describe-instances --region "$REGION" --filters "Name=tag:kubernetes.io/cluster/terraform-eks-cluster,Values=owned,shared" --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,PrivateIpAddress]' --output table
run "EKS IAM 역할" aws iam list-roles --query 'Roles[?contains(RoleName,`terraform`)].RoleName' --output table
run "ECR 리포지토리" aws ecr describe-repositories --region "$REGION" --query 'repositories[*].[repositoryName,repositoryUri]' --output table
echo "</main></body></html>" >> "$OUT.tmp"
mv "$OUT.tmp" "$OUT"
echo "→ $OUT 생성 완료"
