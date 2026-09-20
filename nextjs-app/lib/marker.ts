// marker(): AGENTCELL_SAMPLE_MARKER if the deploy set one; otherwise a value generated once at
// container start and kept in /data/marker -- same contract as every sample here, so a redeploy
// (a new value, whichever source it came from) can be told from a restart (the same value, read
// back from /data). Cached in memory so a running server does not re-touch the file on every
// request.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

const DATA = process.env.AGENTCELL_DATA || "/data";
const MARKER_FILE = path.join(DATA, "marker");

let cached: string | null = null;

export function marker(): string {
  if (cached) {
    return cached;
  }

  const envMarker = process.env.AGENTCELL_SAMPLE_MARKER;
  if (envMarker) {
    cached = envMarker;
    return cached;
  }

  const generated = crypto.randomBytes(6).toString("hex");
  try {
    fs.mkdirSync(DATA, { recursive: true });
    if (fs.existsSync(MARKER_FILE)) {
      cached = fs.readFileSync(MARKER_FILE, "utf8").trim();
      return cached;
    }
    fs.writeFileSync(MARKER_FILE, generated + "\n");
  } catch (err) {
    // Printed rather than swallowed, same reasoning as infra/images/deploy-fixture/app.py: a cell
    // that cannot write its own /data must say so out loud rather than presenting as an
    // application bug. It still starts, with a marker that cannot be told from a restart.
    console.error(`cannot persist marker to ${MARKER_FILE}: ${err}`);
  }
  cached = generated;
  return cached;
}
