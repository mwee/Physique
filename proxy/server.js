// Physique Coach proxy — holds the Anthropic API key and forwards to the
// Messages API. The iOS app NEVER sees the key; it only calls this server.
//
// Routes (match Physique/Services/Coach/CoachAPIClient.swift):
//   POST /plan  { system, user }                  -> { text }  (strict JSON plan)
//   POST /ask   { question, plan, goal, level }   -> { text }  (chat answer)
//
// Run:
//   cd proxy
//   npm install
//   ANTHROPIC_API_KEY=sk-ant-... npm start
//
// The key comes from the environment — it is never hardcoded or committed.

import express from "express";
import Anthropic from "@anthropic-ai/sdk";

const apiKey = process.env.ANTHROPIC_API_KEY;
if (!apiKey) {
  console.error("Missing ANTHROPIC_API_KEY environment variable.");
  process.exit(1);
}

const client = new Anthropic({ apiKey });
const MODEL = process.env.COACH_MODEL || "claude-opus-4-6";

const app = express();
app.use(express.json({ limit: "1mb" }));

// Pull the assistant's text out of a Messages API response.
function textFromMessage(message) {
  return (message.content || [])
    .filter((block) => block.type === "text")
    .map((block) => block.text)
    .join("");
}

// POST /plan — generate a weekly plan as strict JSON.
app.post("/plan", async (req, res) => {
  const { system, user } = req.body ?? {};
  if (typeof system !== "string" || typeof user !== "string") {
    return res.status(400).json({ error: "Expected { system, user } strings." });
  }
  try {
    const message = await client.messages.create({
      model: MODEL,
      max_tokens: 4096,
      system,
      messages: [{ role: "user", content: user }],
    });
    res.json({ text: textFromMessage(message) });
  } catch (err) {
    console.error("/plan failed:", err);
    res.status(502).json({ error: "Upstream LLM error." });
  }
});

// POST /ask — answer a coaching question in plain text.
app.post("/ask", async (req, res) => {
  const { question, plan, goal, level } = req.body ?? {};
  if (typeof question !== "string") {
    return res.status(400).json({ error: "Expected { question } string." });
  }
  const system =
    "You are an expert, encouraging strength coach. Answer the user's question " +
    "in 2-4 warm, concrete sentences. No markdown.";
  const context =
    `The user is following the plan "${plan ?? "their plan"}" ` +
    `(goal: ${goal ?? "general fitness"}, level: ${level ?? "beginner"}).\n\n` +
    `Question: ${question}`;
  try {
    const message = await client.messages.create({
      model: MODEL,
      max_tokens: 512,
      system,
      messages: [{ role: "user", content: context }],
    });
    res.json({ text: textFromMessage(message) });
  } catch (err) {
    console.error("/ask failed:", err);
    res.status(502).json({ error: "Upstream LLM error." });
  }
});

const port = process.env.PORT || 8787;
app.listen(port, () => {
  console.log(`Coach proxy listening on http://localhost:${port}`);
});
