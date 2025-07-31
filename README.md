# Ansible Hardening Controller Setup

This repository contains everything you need to bootstrap an Ansible controller on Amazon Linux 2023 (via SSM) and run the `devsec.hardening` playbook against your EC2 fleet.

## Directory Structure

```
/home/ec2-user/ansible/
├── playbook.yml          # Main Ansible playbook
├── inventory_ssm.ini     # Inventory for SSM transport
├── requirements.txt      # pip dependencies
├── requirements.yml      # Ansible Galaxy collections
├── ansible.cfg           # Ansible configuration
└── prepare_controller.sh # Bootstrap script
```

## 1. Bootstrap the Controller

1. **Place files** under `/home/ec2-user/ansible/`.
2. Make the script executable:
   ```bash
   cd /home/ec2-user/ansible
   chmod +x prepare_controller.sh
   ```
3. Run the bootstrap script:
   ```bash
   ./prepare_controller.sh
   ```
   This will:
   - Update system packages
   - Install Python 3, pip, Git, AWS CLI
   - (Optionally) install the SSM Session Manager plugin
   - Create and activate a Python virtual environment at `~/ansible-venv`
   - Install pip packages (`ansible-core`, `boto3`)
   - Install Ansible Galaxy collections (`devsec.hardening`, `amazon.aws`, `community.aws`)

## 2. Activate the Virtual Environment

Whenever you return to this controller shell, activate the venv:

```bash
source /home/ec2-user/ansible-venv/bin/activate
```

Your prompt should change to `(ansible-venv)`, indicating the Ansible environment is active.

## 3. Configure Inventory

By default, `ansible.cfg` points at `inventory_ssm.ini`. Ensure this file lists your target instance IDs:

```ini
[amazon_linux_targets]
i-0123456789abcdef0 ansible_connection=community.aws.aws_ssm ansible_aws_ssm_region=us-east-1 ansible_aws_ssm_bucket_name=ansible-ssm-bucket-temporary
i-0fedcba9876543210 ansible_connection=community.aws.aws_ssm ansible_aws_ssm_region=us-east-1 ansible_aws_ssm_bucket_name=ansible-ssm-bucket-temporary
```

If you need SSH fallback, you can create `inventory_ssh.ini` and update `ansible.cfg` accordingly (change `inventory = inventory_ssm.ini` to `inventory = inventory_ssh.ini`).

## 4. Run the Playbook

With venv active and inventory configured:

```bash
cd /home/ec2-user/ansible
ansible-playbook playbook.yml -i inventory_ssm.ini
```

- Ansible will gather facts and apply the `devsec.hardening` roles.
- If SSM transport is configured correctly, you should see no `AccessDenied` errors.

## 5. Troubleshooting

- **SSM Permissions**: Ensure your controller IAM role has:

  - `ssm:StartSession` and related actions on the SSM document and EC2 instance ARNs
  - `ssmmessages:*` for data and control channels
  - `s3:*` permissions on the S3 bucket used by Ansible

- **Virtual Env Missing**: If you drop out of SSM session and lose venv activation, re-run:

  ```bash
  source /home/ec2-user/ansible-venv/bin/activate
  ```

- **Proxy or Region Issues**: Confirm AWS CLI default region is `us-east-1` or specify `--region us-east-1` in commands.

## 6. SSH Fallback (Optional)

1. Create `inventory_ssh.ini`:
   ```ini
   [amazon_linux_targets]
   10.0.1.12 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/mykey.pem ansible_python_interpreter=/usr/bin/python3
   10.0.1.13 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/mykey.pem ansible_python_interpreter=/usr/bin/python3
   ```
2. Update `ansible.cfg`:
   ```ini
   [defaults]
   inventory = inventory_ssh.ini
   ```
3. Run:
   ```bash
   ansible-playbook playbook.yml -i inventory_ssh.ini
   ```

---

Everything should now be ready to harden your EC2 instances securely and automatically. Good luck!
