import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Vite writes the site to dist/, the first place AgentCell looks for a built site's index.html.
export default defineConfig({
  plugins: [react()],
});
