🔹 Example Test

After running the script:

aws sqs receive-message --queue-url <EmailQueue-URL> --region ap-south-1


You should see:

{
  "Messages": [
    {
      "Body": "{\"orderId\":\"12345\",\"product\":\"Laptop\",\"quantity\":1}"
    }
  ]
}
