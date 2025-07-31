#!/usr/bin/env bash
set -euo pipefail

# 1. Update & install system packages
sudo dnf update -y
sudo dnf install -y python3 python3-pip git awscli

# 2. (Optional) Session Manager Plugin for AWS CLI v2
if ! command -v session-manager-plugin &> /dev/null; then
  curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" \
    -o /tmp/ssm-plugin.rpm
  sudo dnf install -y /tmp/ssm-plugin.rpm
  rm -f /tmp/ssm-plugin.rpm
fi

# 3. Create & activate Python venv
python3 -m venv /home/ec2-user/ansible-venv
source /home/ec2-user/ansible-venv/bin/activate

# 4. Install pip dependencies
pip install --upgrade pip
pip install -r /home/ec2-user/requirements.txt

# 5. Install Ansible collections
ansible-galaxy collection install -r /home/ec2-user/requirements.yml

# 6. Secure SSH key (if you’ll use SSH fallback)
chmod 600 ~/.ssh/mykey.pem || true

echo "✔ Controller is ready. To continue:"
echo "  source /home/ec2-user/ansible-venv/bin/activate"
echo "  cd /home/ec2-user/ansible"
echo "  ansible-playbook playbook.yml -i inventory_ssm.ini"
