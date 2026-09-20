// worker-node: an HTTP server plus a background loop, the shape an agent-built app usually has --
// something long-running that does work on its own schedule, not only in response to a request.
//
// The loop writes a heartbeat timestamp to /data/heartbeat every 10 s; GET / serves the marker
// line every sample here serves, and GET /heartbeat serves the last timestamp the loop wrote, so
// a caller can tell the background loop is actually running rather than just the HTTP server.
//
// Node stdlib only (http, fs, crypto) -- no package.json dependency, same cold-start reasoning as
// every other sample here.

const http = require("http");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const DATA = process.env.AGENTCELL_DATA || "/data";
const PORT = parseInt(process.env.PORT || "8080", 10);
const MARKER_FILE = path.join(DATA, "marker");
const HEARTBEAT_FILE = path.join(DATA, "heartbeat");

function marker() {
  const envMarker = process.env.AGENTCELL_SAMPLE_MARKER;
  if (envMarker) {
    return envMarker;
  }
  const generated = crypto.randomBytes(6).toString("hex");
  try {
    fs.mkdirSync(DATA, { recursive: true });
    if (fs.existsSync(MARKER_FILE)) {
      return fs.readFileSync(MARKER_FILE, "utf8").trim();
    }
    fs.writeFileSync(MARKER_FILE, generated + "\n");
  } catch (err) {
    // Printed rather than swallowed, same reasoning as infra/images/deploy-fixture/app.py: a cell
    // that cannot write its own /data must say so out loud.
    console.error(`cannot persist marker to ${MARKER_FILE}: ${err}`);
  }
  return generated;
}

const MARKER = marker();

function writeHeartbeat() {
  try {
    fs.mkdirSync(DATA, { recursive: true });
    fs.writeFileSync(HEARTBEAT_FILE, new Date().toISOString() + "\n");
  } catch (err) {
    console.error(`cannot write heartbeat to ${HEARTBEAT_FILE}: ${err}`);
  }
}

// Write one immediately so /heartbeat has something to serve before the first 10 s tick.
writeHeartbeat();
setInterval(writeHeartbeat, 10_000);

const server = http.createServer((req, res) => {
  if (req.url === "/") {
    const body = `agentcell sample: worker-node ${MARKER}\n`;
    res.writeHead(200, { "Content-Type": "text/plain; charset=utf-8", "Content-Length": Buffer.byteLength(body) });
    res.end(body);
    return;
  }

  if (req.url === "/heartbeat") {
    let heartbeat;
    try {
      heartbeat = fs.readFileSync(HEARTBEAT_FILE, "utf8");
    } catch (err) {
      heartbeat = `unreadable: ${err}\n`;
    }
    res.writeHead(200, { "Content-Type": "text/plain; charset=utf-8", "Content-Length": Buffer.byteLength(heartbeat) });
    res.end(heartbeat);
    return;
  }

  res.writeHead(404);
  res.end();
});

// 0.0.0.0: a bind address inside the cell's own network namespace, not an address naming another
// service -- same note as every other sample here.
server.listen(PORT, "0.0.0.0", () => {
  console.log(`worker-node listening on 0.0.0.0:${PORT}`);
});
