const https = require("https");

function postJson(urlString, bodyObj) {
  const url = new URL(urlString);
  const body = JSON.stringify(bodyObj);

  const options = {
    method: "POST",
    hostname: url.hostname,
    path: url.pathname + url.search,
    headers: {
      "Content-Type": "application/json",
      "Content-Length": Buffer.byteLength(body),
    },
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => {
        data += chunk;
      });
      res.on("end", () => {
        const ok = res.statusCode >= 200 && res.statusCode < 300;
        if (!ok) {
          return reject(
            new Error(
              `Discord webhook failed: ${res.statusCode} ${res.statusMessage} - ${data}`
            )
          );
        }
        resolve({ statusCode: res.statusCode, body: data });
      });
    });

    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

exports.handler = async (event) => {
  const webhookUrl = process.env.DISCORD_WEBHOOK_URL;

  if (!webhookUrl) {
    console.warn("DISCORD_WEBHOOK_URL is empty; skipping.");
    return { ok: false, reason: "missing_webhook_url" };
  }

  const records = Array.isArray(event?.Records) ? event.Records : [];
  if (records.length === 0) {
    console.warn("No SNS records found.");
    return { ok: true, delivered: 0 };
  }

  let delivered = 0;

  for (const record of records) {
    const messageRaw = record?.Sns?.Message;
    if (!messageRaw) continue;

    let content;
    try {
      const parsed = JSON.parse(messageRaw);
      content = typeof parsed?.content === "string" ? parsed.content : messageRaw;
    } catch {
      content = messageRaw;
    }

    await postJson(webhookUrl, { content });
    delivered += 1;
  }

  return { ok: true, delivered };
};
