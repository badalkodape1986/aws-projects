#!/bin/bash
# 🚀 Generator: AWS S3 Toolkit (Backup, Restore, Static Website Hosting)

set -e
BASE_DIR="02-aws-projects/s3-toolkit"
mkdir -p $BASE_DIR

# ===== Create Toolkit Script =====
cat > $BASE_DIR/aws-s3-toolkit.sh <<'EOF'
#!/bin/bash
# 🚀 AWS S3 Toolkit: Backup, Restore, and Website Hosting
# Author: You 😎

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

# ===== Functions =====

backup_to_s3() {
  echo -ne "${YELLOW}Enter S3 bucket name: ${NC}"
  read BUCKET
  echo -ne "${YELLOW}Enter source directory to backup: ${NC}"
  read SRC

  TIMESTAMP=$(date +%F-%H-%M-%S)
  echo "📦 Backing up $SRC to s3://$BUCKET/backup_$TIMESTAMP/"
  aws s3 cp --recursive "$SRC" "s3://$BUCKET/backup_$TIMESTAMP/"

  echo -e "${GREEN}✅ Backup completed!${NC}"
}

restore_from_s3() {
  echo -ne "${YELLOW}Enter S3 bucket name: ${NC}"
  read BUCKET
  echo -ne "${YELLOW}Enter destination directory to restore: ${NC}"
  read DEST

  echo "📥 Finding latest backup in s3://$BUCKET ..."
  LATEST=$(aws s3 ls s3://$BUCKET/ | grep backup_ | sort | tail -n 1 | awk '{print $2}')

  if [ -z "$LATEST" ]; then
    echo -e "${RED}❌ No backups found in bucket $BUCKET${NC}"
    return
  fi

  echo "📥 Restoring backup $LATEST to $DEST ..."
  aws s3 cp --recursive "s3://$BUCKET/$LATEST" "$DEST"

  echo -e "${GREEN}✅ Restore completed!${NC}"
}

host_static_website() {
  echo -ne "${YELLOW}Enter bucket name for website: ${NC}"
  read BUCKET
  echo -ne "${YELLOW}Enter path to index.html: ${NC}"
  read INDEX
  echo -ne "${YELLOW}Enter path to error.html: ${NC}"
  read ERROR

  echo "🌐 Creating S3 bucket: $BUCKET"
  aws s3 mb "s3://$BUCKET"

  echo "📥 Uploading website files..."
  aws s3 cp "$INDEX" "s3://$BUCKET/"
  aws s3 cp "$ERROR" "s3://$BUCKET/"

  echo "🔓 Enabling static website hosting..."
  aws s3 website "s3://$BUCKET/" --index-document "$(basename $INDEX)" --error-document "$(basename $ERROR)"

  REGION=$(aws configure get region)
  echo -e "${GREEN}✅ Website hosted at: http://$BUCKET.s3-website-$REGION.amazonaws.com${NC}"
}

# ===== Menu =====

while true; do
  echo -e "\n${GREEN}=== AWS S3 Toolkit ===${NC}"
  echo "1) Backup files to S3"
  echo "2) Restore files from S3"
  echo "3) Host static website on S3"
  echo "4) Quit"
  echo -ne "${YELLOW}Choose an option: ${NC}"
  read choice

  case $choice in
    1) backup_to_s3 ;;
    2) restore_from_s3 ;;
    3) host_static_website ;;
    4) echo "👋 Exiting..."; exit 0 ;;
    *) echo -e "${RED}Invalid choice. Try again.${NC}" ;;
  esac
done
EOF

chmod +x $BASE_DIR/aws-s3-toolkit.sh

# ===== Create README =====
cat > $BASE_DIR/README.md <<'EOF'
# ☁️ AWS S3 Toolkit

This project provides an **all-in-one AWS S3 automation script** that handles:

1. **Backup** → Upload files to S3 (with timestamp)  
2. **Restore** → Download the latest backup from S3  
3. **Static Website Hosting** → Host a website on S3 with index & error page  

---

## 🚀 Features
- Simple CLI menu for all operations
- Uses AWS CLI (must be configured with `aws configure`)
- Works with any bucket in your AWS account
- Supports automatic timestamped backups

---

## 📘 Usage

### 1. Run the toolkit
```bash
./aws-s3-toolkit.sh

