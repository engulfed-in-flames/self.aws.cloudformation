import os
import json
import boto3
import botocore


region_name = "ap-northeast-1"


def lambda_handler(event, context):
    if not ("httpMethod" in event and event["httpMethod"] == "GET"):
        return {
            "statusCode": 400,
            "headers": {},
            "body": json.dumps({"msg": "Bad Request"}),
        }

    try:
        bucket_name = event["detail"]["bucket"]["name"]
        object_key = event["detail"]["object"]["key"]
        target_lambda_function_name = zip_to_pascal_name(object_key)

        lambda_client = boto3.client("lambda", region_name=region_name)

        # Check the specified lambda function exists or not
        lambda_client.get_function(FunctionName=target_lambda_function_name)

        # Update the target lambda function
        lambda_client.update_function_code(
            FunctionName=target_lambda_function_name,
            S3Bucket=bucket_name,
            S3Key=object_key,
        )

        return json.dumps({
            "statusCode": 200,
            "body": {
                "msg": "Successfully executed.",
            },
        })
    except KeyError:
        return json.dumps({
            "statusCode": 500,
            "body": {
                "msg": "The bucket name or object key is not found.",
            }
        })
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "ResourceNotFoundException":
            return json.dumps({
                "statusCode": 400,
                "body": {
                    "msg": "There is no lambda function linked to the given object."
                }
            })
        else:
            return json.dumps({
                "statusCode": 400,
                "body": {
                    "msg": f"{e}"
                }
            })
    except Exception as e:
        return json.dumps({
            "statusCode": 500,
            "body": {
                "event": event,
                "exception": str(e),
            }
        })


def zip_to_pascal_name(filename: str) -> str:
    name, _ = os.path.splitext(filename)
    words: list[str] = name.split("-")[:-1]
    pascal_case_words = [word.title() for word in words]

    return "".join(pascal_case_words)
