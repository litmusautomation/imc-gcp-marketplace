# GCP Service dependencies

The IMC depends on the following GCP services to run its data platform services.

| Resource | Description |
|---|---|
| Cloud Storage buckets | <ul><li>`imc-data-${GCP_PROJECT_ID}`</li><li>`imc-vault-${GCP_PROJECT_ID}`</li></ul> |
|  Pub/Sub Topics  |  <ul><li>`input-messages`</li></ul>   |
|  CloudSQL  |  <ul><li>`imc-db`</li></ul>   |
|  GCP secrets  |  <ul><li>`imc-oauth-client-id`</li><li>`imc-oauth-client-secret`</li></ul>   |
|  GCP KMS keyring  |  <ul><li>`imc-vault-kr`</li></ul>   |
|  GCP KMS key |  <ul><li>`imc-vault-unseal`</li></ul>   |
|  GCP public IP  |  <ul><li>`imc-ingress-ip`</li><li>`imc-remote-ip`</li></ul>   |
|  GCP Service account  |  <ul><li>`imc-app`</li></ul>   |
