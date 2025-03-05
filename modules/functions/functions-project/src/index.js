const functions = require("@google-cloud/functions-framework");
const axios = require("axios");
require("dotenv").config();

async function sendToDiscord() {
  const maskedUrl = process.env.DISCORD_WEBHOOK_URL.replace(
    /(https:\/\/discord\.com\/api\/webhooks\/)(.*?)(\/.*)/,
    "$1****/****"
  );
  try {
    // FIXME: avater_urlがDiscord Botに反映されていないので修正する（優先度・低）
    await axios.post(process.env.DISCORD_WEBHOOK_URL, {
      username: "Google Cloud Billing Alert Bot",
      avater_url:
        "https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEhzMqkpQ7vLUKvumbm6AFwTLQiCe7tlDb2Q0MAiISLsesZHnhj0kbRjB4U3se3UrDIHfIy0hlahyphenhyphenQu-V2tOR2LcV_lX7U8P5a8jtqPYv3Ah4L-JoYi8PhoaoehumGIdp2vrsX0rRyhXqwA/s800/mark_chuui.png",
      content: "Google Cloudの請求額が予算額を超過！！！！",
    });
    console.log("Message sent to Discord");
  } catch (error) {
    console.error("Failed to send message to Discord", error);
  }
}

export const helloWorldToDiscord = async (req, res) => {
  await sendToDiscord();
  res.status(200).send("Message sent to Discord: " + maskedUrl);
};
