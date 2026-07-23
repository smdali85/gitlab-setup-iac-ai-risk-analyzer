import json
import boto3

# Clients
s3 = boto3.client("s3")
bedrock = boto3.client("bedrock-runtime")

MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0"

def lambda_handler(event, context):

    # -----------------------------
    # 1. Read input from event
    # -----------------------------
    bucket = event.get("s3_bucket")
    key = event.get("s3_key")

    if not bucket or not key:
        return {
            "status": "ERROR",
            "message": "Missing s3_bucket or s3_key in input"
        }

    try:
        # -----------------------------
        # 2. Fetch Terraform plan from S3
        # -----------------------------
        obj = s3.get_object(Bucket=bucket, Key=key)
        plan_data = obj["Body"].read().decode("utf-8")

        # -----------------------------
        # 3. Trim payload (important)
        # -----------------------------
        plan_data = plan_data[:4000]

    except Exception as e:
        return {
            "status": "ERROR",
            "message": f"Failed to read from S3: {str(e)}"
        }

    # -----------------------------
    # 4. Build AI prompt
    # -----------------------------
    prompt = f"""
You are an expert cloud infrastructure risk analyzer.

Analyze the Terraform plan and identify:

1. Security risks (e.g., public exposure, open access)
2. Destructive changes (resource deletion/replacement)
3. Misconfigurations (performance, best practices)

Classify overall risk as:
- LOW
- MEDIUM
- HIGH

Rules:
- Public access (0.0.0.0/0) → HIGH
- Resource deletion → HIGH
- Weak instance types → MEDIUM
- Best practice issues → MEDIUM or LOW

Respond ONLY in valid JSON:

{{
  "risk": "LOW | MEDIUM | HIGH",
  "summary": "Short summary",
  "issues": [
    {{
      "type": "Security | Misconfiguration | Destructive",
      "description": "",
      "impact": "",
      "recommendation": ""
    }}
  ]
}}

Terraform Plan:
{plan_data}
"""

    try:
        # -----------------------------
        # 5. Call Bedrock
        # -----------------------------
        response = bedrock.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 800,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            }),
            contentType="application/json",
            accept="application/json"
        )

        result = json.loads(response["body"].read())

        # Extract response text
        output_text = result["content"][0]["text"]

        return {
            "status": "SUCCESS",
            "analysis": output_text
        }

    except Exception as e:
        return {
            "status": "ERROR",
            "message": f"Bedrock invocation failed: {str(e)}"
        }