import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  server: {
    host: "::",
    port: 8080,
  },
  plugins: [react(), mode === "development" && componentTagger()].filter(Boolean),
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  define: {
    // Replace environment variables with placeholders for Docker runtime replacement
    'import.meta.env.VITE_AWS_REGION': mode === 'production' 
      ? '"VITE_AWS_REGION_PLACEHOLDER"' 
      : 'import.meta.env.VITE_AWS_REGION',
    'import.meta.env.VITE_AWS_USER_POOL_ID': mode === 'production' 
      ? '"VITE_AWS_USER_POOL_ID_PLACEHOLDER"' 
      : 'import.meta.env.VITE_AWS_USER_POOL_ID',
    'import.meta.env.VITE_AWS_USER_POOL_CLIENT_ID': mode === 'production' 
      ? '"VITE_AWS_USER_POOL_CLIENT_ID_PLACEHOLDER"' 
      : 'import.meta.env.VITE_AWS_USER_POOL_CLIENT_ID',
    'import.meta.env.VITE_AWS_API_GATEWAY_URL': mode === 'production' 
      ? '"VITE_AWS_API_GATEWAY_URL_PLACEHOLDER"' 
      : 'import.meta.env.VITE_AWS_API_GATEWAY_URL',
    'import.meta.env.VITE_AWS_S3_BUCKET': mode === 'production' 
      ? '"VITE_AWS_S3_BUCKET_PLACEHOLDER"' 
      : 'import.meta.env.VITE_AWS_S3_BUCKET',
  },
}));
