/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_AWS_REGION: string;
  readonly VITE_AWS_API_GATEWAY_URL: string;
  readonly VITE_AWS_USER_POOL_ID: string;
  readonly VITE_AWS_USER_POOL_CLIENT_ID: string;
  // Add other environment variables here as needed
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

