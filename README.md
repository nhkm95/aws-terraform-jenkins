# Terraform + Jenkins CI/CD Pipeline (Dev Environment)

This repository implements a complete CI/CD workflow for provisioning AWS
infrastructure using Terraform, with Jenkins acting as the automation engine.

This setup includes:

- Automatic pipeline trigger on **GitHub push to `main`** via webhook  
- Separate **Plan** and **Apply** workflows  
- Secure handling of Terraform state and plan artifacts in S3  
- `dev.tfvars` sourced **directly from S3** (no Jenkins credential updates required)  
- IMDSv2 + IAM instance profile authentication (no static AWS keys)  
- Manual approval gate before applying Terraform changes  

---

## 📁 Repository Structure

```
aws-terraform-jenkins/
├── env/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── backend.tf
│       └── scripts/
│           └── user_data_jenkins.yaml
└── modules/
    ├── vpc/
    ├── security_groups/
    └── jenkins_ec2/
```

---

## 🚀 CI/CD Workflow Overview

### 1. Push to GitHub → Webhook → Jenkins

A GitHub webhook (`/github-webhook/`) triggers the **TF-Plan-dev** job automatically
whenever a commit is pushed to the `main` branch.

---

## 🧩 TF-Plan-dev Job

This job performs:

1. **Checkout Code**
2. **Terraform Init** with backend config from Jenkins credentials  
3. **Terraform fmt & validate**
4. **Download latest dev.tfvars from S3**
5. **Generate tfplan.bin + tfplan.json**
6. **Upload plan artifacts to S3**
7. **Manual approval step**
8. **(Optional inside same pipeline) Apply**

Artifacts uploaded to S3:

```
s3://<tf-plan-bucket>/plans/dev/<BUILD_NUMBER>.tfplan
s3://<tf-plan-bucket>/plans/dev/<BUILD_NUMBER>.json
```

---

## 🧩 TF-Apply-dev Job (Separate Apply Job)

This is a manual or automated follow-up job that:

1. Accepts `PLAN_BUILD_ID` as a parameter  
2. Downloads the matched plan artifact from S3  
3. Runs:

```
terraform apply -auto-approve tfplan.bin
```

This ensures strict separation between planning and applying.

---

## 📦 Storing dev.tfvars in S3

To avoid updating Jenkins credentials every time variables change, the pipeline pulls
`dev.tfvars` directly from an S3 bucket.

### Example:

Bucket:

```
nhbs-dev-tfvars
```

Key:

```
dev/dev.tfvars
```

Upload/update variables:

```bash
aws s3 cp env/dev/dev.tfvars s3://nhbs-dev-tfvars/dev/dev.tfvars
```

---

## 🔐 Jenkins Credentials Used

| ID                | Type         | Purpose                                 |
|------------------|--------------|------------------------------------------|
| `tf_state_bucket` | Secret Text  | S3 backend bucket name                   |
| `tf_state_key`    | Secret Text  | S3 backend key path                      |
| `tf_plan_bucket`  | Secret Text  | S3 bucket for Terraform plan artifacts   |
| `tfvars_bucket_dev` | Secret Text | Name of bucket storing dev.tfvars       |
| `tfvars_key_dev`    | Secret Text | Key (path) to dev.tfvars                |

---

## 🔧 AWS IAM Roles Required

Jenkins EC2 instance uses an instance profile (`iamr-jenkins`) with:

### For Terraform state:

- `s3:GetObject`
- `s3:ListBucket`
- `s3:PutObject`

### For dev.tfvars:

```
s3:GetObject on arn:aws:s3:::nhbs-dev-tfvars/dev/*
```

### For Terraform-managed resources:

- EC2
- IAM
- VPC / subnet / SG / routing

---

## ⚙️ Jenkins Webhook Configuration

GitHub → Repository → **Settings → Webhooks → Add webhook**

```
Payload URL: http://<jenkins-ip>:8080/github-webhook/
Content type: application/json
Events: Just push events
```

---

## ▶️ Running the Pipeline

### 1. Update tfvars

```bash
vim env/dev/dev.tfvars
aws s3 cp env/dev/dev.tfvars s3://nhbs-dev-tfvars/dev/dev.tfvars
```

### 2. Push code

```bash
git add .
git commit -m "Update infra"
git push origin main
```

### 3. Jenkins auto-triggers TF-Plan-dev

You approve the plan manually.
Additonally, you view the plan before apply.
terraform show -no-color /mnt/c/Users/hakee/Downloads/<build_number>.tfplan

### 4. Apply job

Run **TF-Apply-dev** with parameter:

```
PLAN_BUILD_ID = <plan build number>
```

---

## 🧹 Auto Cleanup

Every pipeline run removes temporary files:

```
tfplan.bin
tfplan.json
backend.hcl
dev.tfvars
```

---

## 🏁 Summary

You now have a production-ready Terraform CI/CD system:

- Automated Plan on push  
- Manual-controlled Apply  
- S3 for plans and tfvars  
- No secrets in Jenkins  
- No AWS keys needed  
- Safe, reviewable infrastructure changes