# AWS EC2 Security Groups Configuration

## Wymagane porty dla aplikacji BSIAW

### Inbound Rules (Reguły przychodzące)

| Port | Protocol | Source | Description |
|------|----------|---------|-------------|
| 22 | TCP | Your IP/0.0.0.0/0 | SSH access for deployment |
| 80 | TCP | 0.0.0.0/0 | HTTP traffic to application |
| 443 | TCP | 0.0.0.0/0 | HTTPS traffic (optional) |

### Outbound Rules (Reguły wychodzące)

| Port | Protocol | Destination | Description |
|------|----------|-------------|-------------|
| All traffic | All | 0.0.0.0/0 | Allow all outbound (default) |

## Konfiguracja w AWS Console

1. **Przejdź do EC2 Console**
2. **Security Groups** → **Create Security Group**
3. **Nazwa:** `bsiaw-app-sg`
4. **Description:** `Security group for BSIAW Django application`
5. **VPC:** Wybierz odpowiedni VPC

### Dodaj Inbound Rules:

```bash
# SSH (dla deploymentu)
Type: SSH
Protocol: TCP
Port: 22
Source: My IP (lub 0.0.0.0/0 dla dostępu globalnego)

# HTTP (aplikacja web)
Type: HTTP
Protocol: TCP
Port: 80
Source: Anywhere (0.0.0.0/0)

# HTTPS (opcjonalnie)
Type: HTTPS
Protocol: TCP
Port: 443
Source: Anywhere (0.0.0.0/0)
```

## RDS Security Group

Upewnij się, że Security Group dla RDS pozwala na połączenia z EC2:

### RDS Inbound Rules:

```bash
Type: PostgreSQL
Protocol: TCP
Port: 5432
Source: bsiaw-app-sg (Security Group ID aplikacji)
```

## Network ACLs

Domyślne Network ACLs zazwyczaj wystarczają. Upewnij się, że:
- Pozwalają na ruch HTTP/HTTPS (porty 80, 443)
- Pozwalają na ruch SSH (port 22)
- Pozwalają na połączenia z RDS (port 5432)

## IAM Role dla EC2

Utwórz IAM Role z uprawnieniami:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": [
                "arn:aws:secretsmanager:eu-north-1:*:secret:rds!db-87d84807-f2a0-4ca8-b0c2-d4f7bf7a0f66*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "rds:DescribeDBInstances"
            ],
            "Resource": "*"
        }
    ]
}
```

## Dodatkowe zabezpieczenia

### 1. Ograniczenie dostępu SSH

Zamiast `0.0.0.0/0` użyj konkretnych IP:
- Twoje IP publiczne
- IP serwera CI/CD GitHub Actions
- IP VPN firmy

### 2. CloudWatch Monitoring

Włącz monitoring dla:
- CPU Utilization
- Network In/Out
- Disk I/O
- Application logs

### 3. Auto Scaling (opcjonalnie)

Konfiguruj Auto Scaling Group dla wysokiej dostępności:
- Min: 1 instancja
- Max: 3 instancje
- Target: 2 instancje
