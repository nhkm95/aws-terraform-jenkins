# AWS Terraform + Jenkins Automation (NHBS / Dev)

This repository provisions a complete Terraform-managed infrastructure in AWS and deploys a Jenkins CI/CD server (running on EC2) to automatically plan/apply Terraform changes.
All values are passed through **tfvars**, all naming is fully dynamic, and no secrets or environment-specific data are stored in Git.

---

## 📦 Project Overview

This project contains:

- **Bootstrap stack** (local state) → creates the S3 backend for Terraform
- **Environment stack** (remote state) → VPC, subnets, SGs, IAM role, Jenkins EC2
- **Reusable Terraform modules** (VPC, EC2, SG, IAM)
- **Cloud-init Jenkins installation**
- **Jenkins pipeline** to automate Terraform plan/apply
- **Strict git hygiene** (tfvars/backend/keys ignored)

All parameter values (CIDRs, ports, instance types, AMI filters, IPs, etc.) are defined in **env-specific tfvars**.

---

## 📁 Repository Structure

```
aws-terraform-jenkins/
├─ bootstrap/
│  ├─ main.tf
│  ├─ variables.tf
│  ├─ providers.tf
│  └─ bootstrap.tfvars.example
│
├─ modules/
│  ├─ vpc/
│  ├─ security_group/
│  └─ ec2_instance/
│
├─ envs/
│  └─ dev/
│     ├─ main.tf
│     ├─ backend.tf
│     ├─ variables.tf
│     ├─ dev.tfvars.example
│     └─ user_data_jenkins.yaml
│
├─ jenkins/
│  └─ Jenkinsfile
│
└─ .gitignore
```

---

## 🚀 Deployment Workflow

### **Step 1 — Bootstrap S3 Backend (Local State)**

Bootstrap uses **local state** to create the remote S3 bucket.

1. Copy the example:

```
cp bootstrap/bootstrap.tfvars.example bootstrap/bootstrap.tfvars
```

2. Fill in real values (account ID, bucket name, region).  
   These files are git-ignored.

3. Run:

```
cd bootstrap
terraform init
terraform apply -var-file=bootstrap.tfvars
```

Creates:

- S3 bucket for state  
- Versioning  
- Encryption  

---

### **Step 2 — Prepare Environment Files (Remote State)**

In `envs/dev/` create:

- `dev.tfvars` — real values, not committed  
- `backend-dev.hcl` — backend config, not committed  

Example config includes:

- VPC CIDR  
- Public subnets (dynamic keys)  
- Security groups (dynamic keys)  
- Jenkins EC2 instance parameters  
- State bucket + key  

Only **dev.tfvars.example** is committed.

---

### **Step 3 — Deploy Infrastructure**

```
cd envs/dev
terraform init -backend-config=backend-dev.hcl
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars -auto-approve
```

This provisions:

- VPC  
- IGW  
- Route tables  
- Subnets  
- Security groups  
- Jenkins IAM role  
- Jenkins EC2 instance (Ubuntu 22.04 via Cloud-init)

Outputs include:

- Jenkins Public IP
- Jenkins Public DNS

---

### **Step 4 — Access Jenkins**

1. SSH into instance:

```
ssh -i jenkins-kp.pem ubuntu@<public-ip>
```

2. Retrieve initial password:

```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

3. Login at:

```
http://<public-dns>:8080
```

Finish setup and create admin user.

---

### **Step 5 — Configure Jenkins Pipeline**

Jenkinsfile (`jenkins/Jenkinsfile`) performs:

- Checkout  
- Terraform init (backend config from Jenkins credentials)  
- fmt / validate  
- plan → upload plan to S3  
- manual approval  
- apply  

#### Jenkins Credentials Required

You must create **Secret Text** credentials:

| ID               | Value                               | Purpose                   |
|------------------|---------------------------------------|---------------------------|
| `tf_state_bucket` | Backend S3 bucket name                | For terraform init        |
| `tf_state_key`    | Backend state key (path in bucket)    | For terraform init        |
| `tf_plan_bucket`  | Bucket for storing plan artifacts     | Optional (can reuse state)|

After creating credentials, Jenkins can run Terraform securely without hardcoding secrets.

---

## 🔐 Security

### What Never Goes Into Git

The `.gitignore` protects:

- `*.tfvars` (real values)
- `backend*.hcl`
- SSH keys (`*.pem`)
- State files
- Plans (`*.tfplan`, `.bin`, `.json`)
- Crash logs
- Sensitive backend or pipeline configs

### IAM Role Hardening

Jenkins EC2 uses a **least-privilege policy**, granting only:

- Required S3 access (state + plans)
- Required EC2/VPC permissions
- Permission to manage **only its own role**
- `iam:PassRole` for its own instance profile

No `AdministratorAccess`.

---

## 🧩 Customization

You can scale dynamically by modifying only **dev.tfvars**:

- Add more subnets:  
  `public_subnets = { "public-a" = {...}, "public-b" = {...} }`
- Add more SGs:  
  `security_groups = { "jenkins" = {...}, "web" = {...} }`
- Add more EC2 instances:  
  `ec2_instances = { "jenkins" = {...}, "web01" = {...} }`

Modules automatically name resources using:

```
<project>-<environment>-<key>
```

---

## ⚙️ Requirements

- Terraform ≥ 1.9  
- AWS CLI  
- SSH client  
- Jenkins (installed via cloud-init)  
- GitHub repo (for Jenkins pipeline)

---

## 🚧 Notes

- All real environment values must be kept in **local tfvars**, not committed.
- All modules are fully reusable, no hardcoding.
- The design is future-proof for adding ALB, Route53, RDS, or multi-environment (prod/stage).

