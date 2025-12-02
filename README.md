# Queue Infrastructure

게임 서버 대기열 시스템의 인프라 코드입니다.

## 아키텍처

```mermaid
flowchart TB
    subgraph AWS["AWS Cloud"]
        subgraph EKS["EKS Cluster"]
            subgraph QS["queue-system namespace"]
                QA[queue-api]
                QM[queue-manager]
                CS[chat-server]
            end
            subgraph OBS["observability namespace"]
                ALLOY[Grafana Alloy]
                PROM[Prometheus]
                LOKI[Loki]
                GRAF[Grafana]
                RE[Redis Exporter]
            end
        end
        
        VALKEY[(ElastiCache<br/>Valkey)]
        S3[(S3<br/>Loki Storage)]
    end

    QA --> VALKEY
    QM --> VALKEY
    CS --> VALKEY
    
    QA -->|OTLP HTTP| ALLOY
    QM -->|OTLP HTTP| ALLOY
    CS -->|OTLP gRPC| ALLOY
    
    ALLOY -->|Remote Write| PROM
    ALLOY --> LOKI
    LOKI --> S3
    RE -->|Scrape| VALKEY
    ALLOY -->|Scrape| RE
    
    PROM --> GRAF
    LOKI --> GRAF
```

## 컴포넌트

| 컴포넌트 | 유형 | 배포 방식 |
|----------|------|-----------|
| VPC, EKS, ElastiCache | AWS 인프라 | Terraform |
| S3 (Loki Storage) | AWS 인프라 | Terraform |
| Grafana Alloy | EKS 워크로드 | Helm (grafana/alloy) |
| Prometheus | EKS 워크로드 | Helm (prometheus-community/prometheus) |
| Loki | EKS 워크로드 | Helm (grafana/loki) |
| Grafana | EKS 워크로드 | Helm (grafana/grafana) |
| Redis Exporter | EKS 워크로드 | Helm (prometheus-community/prometheus-redis-exporter) |
| queue-api, queue-manager, chat-server | EKS 워크로드 | Kustomize |

## 디렉토리 구조

```plaintext
queue-infra/
├── ecr/                      # ECR 리포지토리 (독립 배포)
│   ├── main.tf
│   └── outputs.tf
├── terraform/                # AWS 인프라
│   ├── dev.tfvars            # 개발 환경 설정
│   ├── prod.tfvars           # 운영 환경 설정
│   ├── sample.tfvars         # 환경 설정 템플릿
│   ├── configs/              # Helm values 파일
│   ├── dashboards/           # Grafana 대시보드
│   ├── modules/
│   │   ├── eks/
│   │   └── vpc/
│   └── *.tf
└── k8s/
    ├── base/                 # Kustomize base (공통)
    └── overlays/
        ├── dev/              # 개발 환경 오버레이
        └── prod/             # 운영 환경 오버레이
```

## 환경별 설정

| 설정 | dev (최소 비용) | prod (운영) |
|------|----------------|-------------|
| EKS 노드 | t4g.small × 2 | t4g.large × 3 |
| Valkey | cache.t4g.micro, 단일 노드 | cache.t4g.medium, Multi-AZ |
| queue-api replicas | 1 | 3 |
| HPA max | 5 | 100 |

### 커스텀 환경 생성

`terraform/sample.tfvars`를 복사하여 새 환경을 생성할 수 있습니다:

```bash
cd terraform
cp sample.tfvars staging.tfvars
# staging.tfvars 편집 후
terraform apply -var-file staging.tfvars
```

## 사전 요구사항

- AWS CLI 설정 완료
- Terraform >= 1.4
- kubectl
- Helm >= 3.0

## 배포 가이드

### 1. ECR 리포지토리 생성 (최초 1회)

```bash
cd ecr

terraform init
terraform plan
terraform apply
```

**생성되는 ECR 리포지토리:**

- queue-api
- queue-manager
- chat-server

### 2. 컨테이너 이미지 빌드 및 푸시

```bash
# ECR 로그인
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin <ECR_REGISTRY>

# 각 서비스 이미지 빌드 및 푸시
docker build -t <ECR_REGISTRY>/queue-api:latest ./queue-api
docker push <ECR_REGISTRY>/queue-api:latest

docker build -t <ECR_REGISTRY>/queue-manager:latest ./queue-manager
docker push <ECR_REGISTRY>/queue-manager:latest

docker build -t <ECR_REGISTRY>/chat-server:latest ./chat-server
docker push <ECR_REGISTRY>/chat-server:latest
```

### 3. Terraform으로 인프라 배포

```bash
cd terraform
terraform init

# 개발 환경 배포
terraform apply -var-file dev.tfvars

# 또는 운영 환경 배포
terraform apply -var-file prod.tfvars
```

**Terraform이 자동으로 배포하는 리소스:**

**AWS 인프라:**

- VPC, Subnets, NAT Gateway
- EKS Cluster + Node Group
- ElastiCache (Valkey)
- S3 Bucket (Loki 로그 저장소)
- IAM Roles (IRSA)

**Helm Charts (EKS에 자동 설치):**

- Grafana Alloy
- Loki
- Prometheus
- Grafana
- Metrics Server
- Redis Exporter

**Terraform 출력값 확인:**

```bash
terraform output valkey_endpoint
terraform output grafana_url  # ALB를 통해 접근 가능한 Grafana URL
```

**Grafana 접속:**
- URL: Terraform output의 `grafana_url` 또는 `kubectl get ingress -n observability`로 확인
- 기본 계정: admin / admin

### 4. kubectl 설정

```bash
# dev 환경
aws eks update-kubeconfig --name team3-dev-eks-cluster --region ap-northeast-2

# prod 환경
aws eks update-kubeconfig --name team3-prod-eks-cluster --region ap-northeast-2
```

### 5. Queue System 배포 (Kustomize)

```bash
# 개발 환경
kubectl apply -k k8s/overlays/dev

# 운영 환경
kubectl apply -k k8s/overlays/prod
```

### 6. 배포 확인

```bash
kubectl get pods -n queue-system
kubectl get pods -n observability
kubectl get ingress -n queue-system
```

## 배포 방식

### Terraform이 자동 배포하는 항목

| 컴포넌트 | 배포 방식 | 설명 |
|----------|-----------|------|
| VPC, EKS, ElastiCache | Terraform | AWS 인프라 |
| Grafana Alloy | Terraform + Helm | OTLP 수신 → Prometheus/Loki |
| Loki | Terraform + Helm | 로그 저장소 (S3) |
| Prometheus | Terraform + Helm | 메트릭 저장소 |
| Grafana | Terraform + Helm | 대시보드 (ALB Ingress로 외부 노출) |
| Redis Exporter | Terraform + Helm | Valkey 메트릭 수집 |

### Kustomize로 배포하는 항목

| 컴포넌트 | 배포 방식 | 설명 |
|----------|-----------|------|
| queue-api | Kustomize | 대기열 API (HPA 지원) |
| queue-manager | Kustomize | 티켓 발급 스케줄러 |
| chat-server | Kustomize | WebSocket 게임 서버 |

## 모니터링 데이터 흐름

```mermaid
flowchart LR
    subgraph Apps["Applications (EKS)"]
        QA[queue-api]
        QM[queue-manager]
        CS[chat-server]
    end

    subgraph Collectors["Collectors (EKS)"]
        ALLOY[Grafana Alloy]
        RE[Redis Exporter]
    end

    subgraph Storage["Storage (EKS)"]
        PROM[Prometheus]
        LOKI[Loki] --> S3[(S3)]
        GRAF[Grafana]
    end

    QA & QM -->|OTLP HTTP :4318| ALLOY
    CS -->|OTLP gRPC :4317| ALLOY
    ALLOY -->|Scrape| RE
    ALLOY -->|Remote Write| PROM
    ALLOY -->|Push| LOKI
    PROM & LOKI --> GRAF
```

## 배포 순서

```mermaid
flowchart TD
    A[1. ECR 배포] -->|terraform apply| B[ECR 리포지토리 생성]
    B --> C[2. 이미지 빌드/푸시]
    C --> D[docker build & push]
    D --> E[3. Terraform Apply]
    E -->|AWS 인프라 + Helm| F[자동 배포 완료]
    F --> F1[EKS, VPC, Valkey]
    F --> F2[Prometheus, Grafana]
    F --> F3[Alloy, Loki, Redis Exporter]
    
    F --> G[4. kubectl 설정]
    G --> H[5. Kustomize로 앱 배포]
    H --> I[kubectl apply -k]
```

## 정리 (삭제)

```bash
# 애플리케이션 삭제
kubectl delete -k k8s/overlays/dev  # 또는 prod

# 서비스 인프라 삭제
cd terraform
terraform destroy -var-file=dev.tfvars  # 또는 prod.tfvars

# ECR 삭제 (이미지가 있으면 먼저 삭제 필요)
cd ../ecr
terraform destroy
```

## 트러블슈팅

### Pod이 시작되지 않는 경우

```bash
kubectl describe pod <POD_NAME> -n <NAMESPACE>
kubectl logs <POD_NAME> -n <NAMESPACE>
```

### Valkey 연결 오류

```bash
terraform output -raw valkey_endpoint
kubectl get secret valkey-secret -n queue-system -o yaml
```

### Alloy가 Prometheus에 연결되지 않는 경우

```bash
kubectl describe sa alloy -n observability
kubectl logs -l app.kubernetes.io/name=alloy -n observability
```

### Helm 배포(Loki 등)가 오래 걸리거나 실패하는 경우

Loki와 같은 무거운 Helm 차트 배포 시 `Pending` 상태로 멈추거나 타임아웃이 발생한다면, EKS 노드의 리소스 부족 또는 Pod 개수 제한(Max Pods)에 도달했을 가능성이 높습니다.

**해결 방법:**

1. **노드 인스턴스 타입 상향**: `t4g.small` 등 작은 인스턴스는 노드당 실행 가능한 Pod 수가 적습니다 (예: t4g.small은 11개). `t4g.medium` 이상으로 변경하세요.
2. **노드 수 증가**: 노드 그룹의 `desired_size`를 늘려 Pod를 분산시키세요.

