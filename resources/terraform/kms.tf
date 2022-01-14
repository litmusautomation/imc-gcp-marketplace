data "google_kms_key_ring" "vault-keyring" {
  name     = "imc-vault-kr"
  location = "global"
}

data "google_kms_crypto_key" "vault-unseal" {
  name = "imc-vault-unseal"
  key_ring = data.google_kms_key_ring.vault-keyring.id
}

data "google_iam_policy" "imc-vault" {
  binding {
    role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    members = [
      "serviceAccount:${google_service_account.imc_sa.email}",
    ]
  }
}

resource "google_kms_crypto_key_iam_policy" "crypto_key" {
  crypto_key_id = data.google_kms_crypto_key.vault-unseal.id
  policy_data = data.google_iam_policy.imc-vault.policy_data
}
