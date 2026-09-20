// output: "standalone" -- next build emits .next/standalone with a pruned node_modules and a
// server.js entrypoint, so the runtime image (this app's Dockerfile, second stage) does not carry
// the dev toolchain or the full npm tree, only what actually runs.
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
};

module.exports = nextConfig;
