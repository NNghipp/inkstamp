// Emulator SDK deliberately skips token signature verification. requireAuth
// independently verifies real cloud Firebase ID tokens in this mode.
export const localDevBackend =
  process.env.FUNCTIONS_EMULATOR === "true" &&
  process.env.DEV_BACKEND_MODE === "functions_emulator" &&
  process.env.GCLOUD_PROJECT === "inkstamp-dev";

// App Check attestation is NOT emulated. Local loopback transport only; cloud
// deployments always retain enforcement. This is not a production gate PASS.
export const enforceAppCheck = !localDevBackend;
