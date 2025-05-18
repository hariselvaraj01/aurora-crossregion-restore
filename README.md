# Aurora Cross-Account Snapshot Restore & Column Encryption

This project provides a complete, automated solution to:
- Restore an encrypted Aurora MySQL snapshot from another AWS account **without sharing the original KMS key**
- Provision a new cluster and instance in the target account
- Run a **MySQL stored procedure** via **AWS Lambda** to encrypt sensitive columns using AES encryption

---

## Why This Project?

Typical snapshot sharing fails when the snapshot is encrypted with a **Customer Managed Key (CMEK)**. This solution:
- Uses a new KMS key in **Account B**
- **Re-encrypts the snapshot**
- Automates deployment with CloudFormation
- Encrypts sensitive DB columns (like `email`, `password`) securely

---

## Architecture

1. **Account A**: Shares a snapshot to Account B
2. **Account B**:
   - Copies and re-encrypts the snapshot using its own KMS key
   - Deploys Aurora from the copied snapshot
   - Uses Lambda to run a stored procedure that encrypts columns

---

## Folder Structure

```
aurora-crossaccount-restore-encrypt/
├── template.yaml                 # CloudFormation template
├── lambda/
│   ├── index.py                  # Lambda function to connect to Aurora and encrypt data
│   └── encrypt_column_proc.sql   # MySQL stored procedure to encrypt columns dynamically
```

---

## Prerequisites

- An **Aurora MySQL snapshot** shared from another AWS account
- A **KMS key in Account B** to re-encrypt the snapshot
- An **S3 bucket** in Account B to upload the zipped Lambda code
- Subnet IDs and security group ID in a VPC where Aurora can be deployed
- AWS CLI configured with permissions to deploy CloudFormation and RDS

---

## Deployment Steps

### 1. Zip and Upload Lambda

```bash
cd lambda
zip -r ../encrypt.zip .
aws s3 cp ../encrypt.zip s3://<your-bucket-name>/lambda/encrypt.zip
```

> Note: Update `template.yaml` to replace `PLACEHOLDER_BUCKET` with your actual S3 bucket.

---

### 2. Deploy CloudFormation Stack

```bash
aws cloudformation deploy   --template-file template.yaml   --stack-name aurora-restore-encrypt   --capabilities CAPABILITY_NAMED_IAM   --parameter-overrides     SnapshotIdentifier=arn:aws:rds:us-east-1:111111111111:cluster-snapshot:shared-snapshot     DBClusterIdentifier=my-restored-cluster     DBInstanceIdentifier=my-instance     KmsKeyId=arn:aws:kms:us-east-1:222222222222:key/abc-1234-xyz     DBName=mydb     MasterUsername=admin     MasterUserPassword=MySecurePass123     DBInstanceClass=db.r6g.large     SubnetIds='["subnet-abc123", "subnet-def456"]'     SecurityGroupIds='["sg-0a1b2c3d4e"]'     LambdaEncryptionKey=mysecretkey
```

---

## Lambda Details

- **index.py** connects to the Aurora cluster
- Runs the procedure in **encrypt_column_proc.sql**
- Encrypts columns like `email`, `password` using `AES_ENCRYPT()` and `TO_BASE64()`

You can change the table name, column list, or encryption key by updating Lambda environment variables in the CloudFormation stack.

---

## Security Notes

- Avoid hardcoding DB credentials; consider **AWS Secrets Manager** for production
- Ensure the **KMS key** is securely managed and rotated
- The Lambda role is scoped for basic logging and RDS access; restrict further as needed

---

## Output

- A restored Aurora MySQL cluster
- A Lambda function ready to encrypt data
- Columns like `email` and `password` will be AES-encrypted with your provided key

---

## License

This project is licensed under the [MIT License](LICENSE)

---

## Contributors

Built with OpenAI GPT, customized and maintained by [Your Name]

---

## Want More?

- [ ] Add GitHub Actions workflow for deployment
- [ ] Extend to support decryption
- [ ] Parameterize column/table selection via Secrets Manager or EventBridge

Pull requests and issues are welcome!
