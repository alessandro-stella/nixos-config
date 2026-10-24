function parseKeyValue(raw) {
  let next = {};
  let lines = String(raw || "").split("\n");
  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];
    if (!line) continue;
    let idx = line.indexOf("\t");
    if (idx === -1) continue;
    let key = line.substring(0, idx);
    let value = line.substring(idx + 1);
    next[key] = value.trim();
  }
  return next;
}

function throughputState(previous, next, now) {
  let prev = previous || {};
  let sample = next || {};
  let iface = sample.iface || "";
  let rx = parseFloat(sample.rx_bytes || "0");
  let tx = parseFloat(sample.tx_bytes || "0");
  let previousTime = Number(prev.prevSampleTime || 0);

  if (iface !== (prev.prevIface || "") || previousTime === 0) {
    return {
      prevIface: iface,
      prevRxBytes: rx,
      prevTxBytes: tx,
      prevSampleTime: now,
      downloadRate: 0,
      uploadRate: 0,
    };
  }

  let downloadRate = 0;
  let uploadRate = 0;
  let dt = now - previousTime;
  if (dt > 0) {
    downloadRate = Math.max(0, (rx - Number(prev.prevRxBytes || 0)) / dt);
    uploadRate = Math.max(0, (tx - Number(prev.prevTxBytes || 0)) / dt);
  }

  return {
    prevIface: iface,
    prevRxBytes: rx,
    prevTxBytes: tx,
    prevSampleTime: now,
    downloadRate: downloadRate,
    uploadRate: uploadRate,
  };
}

function formatBytes(bytes) {
  let n = Number(bytes);
  if (!isFinite(n) || n < 0) n = 0;
  if (n < 1024) return Math.round(n) + " B";
  if (n < 1024 * 1024) return (n / 1024).toFixed(1) + " KB";
  if (n < 1024 * 1024 * 1024) return (n / (1024 * 1024)).toFixed(1) + " MB";
  return (n / (1024 * 1024 * 1024)).toFixed(2) + " GB";
}

function formatRate(bytesPerSec) {
  return formatBytes(bytesPerSec) + "/s";
}

function wifiIconFor(strength) {
  let icons = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"];
  let index = Math.max(0, Math.min(4, Math.ceil(strength / 20) - 1));
  return icons[index];
}

function wifiRow(network) {
  if (!network) return null;
  return {
    connected: !!network.connected,
    known: !!network.known,
    ssid: network.name || "",
    signal: Math.round((network.signalStrength || 0) * 100),
    security: network.security,
  };
}

function sortWifiRows(rows) {
  let nets = Array.isArray(rows) ? rows.slice() : [];
  nets.sort(function (a, b) {
    if (a.connected !== b.connected) return a.connected ? -1 : 1;
    if (a.known !== b.known) return a.known ? -1 : 1;
    return b.signal - a.signal;
  });
  return nets;
}
