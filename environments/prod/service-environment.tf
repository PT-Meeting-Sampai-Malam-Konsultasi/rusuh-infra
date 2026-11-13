# Non-secret service config lives here, in git, so every task definition
# revision Terraform registers carries it. Secrets stay in Secrets Manager
# (*_secrets); *_extra_environment in tfvars is only for overrides.
# Never edit env on a task definition by hand: CD copies the latest
# revision, so a hand edit is lost on the next apply.
locals {
  queue_environment = {
    # Core account tokens (apps/auth): Ed25519 public JWKS, kid akun-202611-01.
    # Public key only; the private half is msmk-prod-auth-jwt-private-key.
    CORE_JWKS               = jsonencode({ keys = [{ kty = "OKP", crv = "Ed25519", kid = "akun-202611-01", x = "8WuHRGc0WLxS0VezP7ePf9_z83M4VOGK2PFoCX0KptA" }] })
    CORE_ISSUER             = "rusuh-auth"
    CORE_AUDIENCE           = "rusuh-api"
    CORE_ACCESS_REQUIRE_OTP = "false"
    # Core holds the admission for the payment step after the order window.
    CORE_PAYMENT_WINDOW = "10m"
    # Device registration skips Turnstile and attestation; rate limits still
    # apply. Back to "enforce" once a real TURNSTILE_SECRET is in place.
    DEVICE_VERIFICATION = "off"
  }
}
