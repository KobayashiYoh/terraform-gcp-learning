const functions = require("@google-cloud/functions-framework");
const axios = require("axios");
require("dotenv").config();

async function sendToDiscord() {
  try {
    await axios.post(process.env.DISCORD_WEBHOOK_URL, {
      content: "Hello, World",
    });
    console.log("Message sent to Discord");
  } catch (error) {
    console.error("Failed to send message to Discord", error);
  }
}

export const helloWorldToDiscord = async (req, res) => {
  await sendToDiscord();
  res.status(200).send("Message sent");
};
