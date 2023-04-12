#  Copyright (c) University College London Hospitals NHS Foundation Trust
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# This is only required while we have to call the GH API manually
# It can be removed when we can apply branch policies via Terraform following merge of
# https://github.com/integrations/terraform-provider-github/pull/1530

import jwt
import time
import sys
import requests
import json

# Get PEM string, App Id and App Installation Id
app_id = sys.argv[1]
installation_id = sys.argv[2]
pem_string = sys.argv[3]

# Create JWK
pem_bytes = bytes(pem_string, "ascii")
signing_key = jwt.jwk_from_pem(pem_bytes)

payload = {
    # Issued at time
    "iat": int(time.time()),
    # JWT expiration time (10 minutes maximum)
    "exp": int(time.time()) + 600,
    # GitHub App's identifier
    "iss": app_id,
}

# Create JWT
jwt_instance = jwt.JWT()
encoded_jwt = jwt_instance.encode(payload, signing_key, alg="RS256")

# Use JWT to get GH access token
headers = {
    "Accept": "application/vnd.github+json",
    "Authorization": f"Bearer {encoded_jwt}",
    "X-GitHub-Api-Version": "2022-11-28",
}

url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
response = requests.post(url, headers=headers)

if not response.ok:
    raise Exception("Error getting GitHub access token", response)

# Output JSON string with token for Terraform to use
token = response.json()["token"]
output = {"token": token}
sys.stdout.write(json.dumps(output))
