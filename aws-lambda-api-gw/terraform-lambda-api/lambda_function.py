import json
import boto3
import uuid

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("Orders")

def lambda_handler(event, context):
    body = json.loads(event["body"])
    order_id = str(uuid.uuid4())
    
    table.put_item(Item={
        "orderId": order_id,
        "product": body["product"],
        "quantity": body["quantity"],
        "status": "PLACED"
    })
    
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Order placed successfully", "orderId": order_id})
    }
