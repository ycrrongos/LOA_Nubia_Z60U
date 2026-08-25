const statusText = document.getElementById("statusText");
const dot = document.getElementById("dot");
const logEl = document.getElementById("log");

const timers = {};

function setLog(msg) {
  logEl.textContent = msg;
  logEl.classList.remove("flash");
  void logEl.offsetWidth;
  logEl.classList.add("flash");
}

function clampAngle(n) {
  const v = Number(n);
  if (Number.isNaN(v)) return 90;
  return Math.max(0, Math.min(180, Math.round(v)));
}

function applyAnglesToUi(angles) {
  if (!angles) return;
  for (const [servo, key] of [
    ["volup", "volup"],
    ["voldown", "voldown"],
    ["power", "power"],
  ]) {
    if (angles[key] == null) continue;
    const range = document.querySelector(`input[data-servo="${servo}"]`);
    const num = document.querySelector(`input[data-servo-num="${servo}"]`);
    if (range) range.value = angles[key];
    if (num) num.value = angles[key];
  }
  document.querySelectorAll("[data-cfg]").forEach((el) => {
    const k = el.dataset.cfg;
    if (angles[k] != null) el.value = angles[k];
  });
}

async function refreshStatus() {
  try {
    const res = await fetch("/api/status");
    const data = await res.json();
    if (data.connected) {
      dot.className = "dot ok";
      statusText.textContent = `已连接 ${data.port} @ ${data.baud}`;
    } else {
      dot.className = "dot bad";
      statusText.textContent = `未连接 ${data.port}`;
    }
    applyAnglesToUi(data.angles);
  } catch (err) {
    dot.className = "dot bad";
    statusText.textContent = "后端不可达";
  }
}

async function press(button, el) {
  el.classList.add("busy");
  setLog(`执行 ${button}…`);
  try {
    const res = await fetch(`/api/press/${encodeURIComponent(button)}`, {
      method: "POST",
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      setLog(`失败: ${data.detail || res.statusText}`);
      return;
    }
    setLog(data.reply || "OK");
    applyAnglesToUi(data.angles);
  } catch (err) {
    setLog(`请求失败: ${err.message || err}`);
  } finally {
    el.classList.remove("busy");
    refreshStatus();
  }
}

async function setServoAngle(servo, angle) {
  const a = clampAngle(angle);
  setLog(`设置 ${servo} = ${a}°…`);
  const res = await fetch("/api/angle", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ servo, angle: a }),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    setLog(`失败: ${data.detail || res.statusText}`);
    return;
  }
  setLog(data.reply || "OK");
  applyAnglesToUi(data.angles);
}

function bindAngleControls() {
  document.querySelectorAll("input[data-servo]").forEach((range) => {
    const servo = range.dataset.servo;
    const num = document.querySelector(`input[data-servo-num="${servo}"]`);

    const syncAndSend = (value, immediate = false) => {
      const a = clampAngle(value);
      range.value = a;
      if (num) num.value = a;
      clearTimeout(timers[servo]);
      const run = () => setServoAngle(servo, a).catch((e) => setLog(String(e)));
      if (immediate) run();
      else timers[servo] = setTimeout(run, 80);
    };

    range.addEventListener("input", () => syncAndSend(range.value, false));
    range.addEventListener("change", () => syncAndSend(range.value, true));
    if (num) {
      num.addEventListener("change", () => syncAndSend(num.value, true));
    }
  });
}

async function refreshAnglesFromDevice() {
  setLog("读取角度…");
  try {
    const res = await fetch("/api/angles");
    const data = await res.json();
    if (!res.ok) {
      setLog(`失败: ${data.detail || res.statusText}`);
      return;
    }
    applyAnglesToUi(data.angles);
    setLog(data.reply || "OK");
  } catch (err) {
    setLog(`请求失败: ${err.message || err}`);
  }
}

async function applyCalib() {
  const body = {};
  document.querySelectorAll("[data-cfg]").forEach((el) => {
    body[el.dataset.cfg] = clampAngle(el.value);
  });
  setLog("写入点按参数…");
  try {
    const res = await fetch("/api/angles", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      setLog(`失败: ${data.detail || res.statusText}`);
      return;
    }
    applyAnglesToUi(data.angles);
    setLog((data.replies && data.replies.join(" | ")) || "OK");
  } catch (err) {
    setLog(`请求失败: ${err.message || err}`);
  }
}

document.querySelectorAll("[data-btn]").forEach((btn) => {
  btn.addEventListener("click", () => press(btn.dataset.btn, btn));
});

document.getElementById("refreshAngles").addEventListener("click", refreshAnglesFromDevice);
document.getElementById("applyCalib").addEventListener("click", applyCalib);

bindAngleControls();
refreshStatus();
refreshAnglesFromDevice();
setInterval(refreshStatus, 4000);
