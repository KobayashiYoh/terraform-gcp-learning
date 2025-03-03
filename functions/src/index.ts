import { CloudEvent, cloudEvent } from "@google-cloud/functions-framework";
import axios from "axios";

const DISCORD_WEBHOOK_URL = process.env.DISCORD_WEBHOOK_URL;

interface MessageData {
  costAmount: string;
}

export const sendAlert = cloudEvent<CloudEvent<MessageData>>(
  "sendAlert",
  async (event: any) => {
    if (!DISCORD_WEBHOOK_URL) {
      console.error("DISCORD_WEBHOOK_URL is not set.");
      return;
    }

    try {
      // Base64 エンコードされたデータをデコードして JSON に変換
      const data = event.data?.message?.data
        ? JSON.parse(Buffer.from(event.data.message.data, "base64").toString())
        : null;

      if (!data || !data.costAmount) {
        console.warn("Invalid message format:", data);
        return;
      }

      const costAmount = parseFloat(data.costAmount);

      if (costAmount > 1) {
        await axios.post(DISCORD_WEBHOOK_URL, {
          content: `⚠️ 請求額が ${costAmount} 円を超えました！`,
        });
        console.log(`Sent alert for cost: ${costAmount}円`);
      }
    } catch (error) {
      console.error("Error processing billing alert:", error);
    }
  }
);
