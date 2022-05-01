# GCP Service dependencies

The MC depends on the following GCP services to run its data platform services.

| Resource | Description |
|---|---|
| Cloud Storage bucket | <ul><li>`imc-data-${GCP_PROJECT_ID}`</li></ul> |
|  Pub/Sub Topics  |  <ul><li>`input-messages`</li></ul>   |
|  CloudSQL  |  <ul><li>`imc-db`</li></ul>   |
|  GCP public IP  |  <ul><li>`imc-ingress-ip`</li><li>`imc-remote-ip`</li></ul>   |
|  GCP Service account  |  <ul><li>`imc-app`</li></ul>   |
