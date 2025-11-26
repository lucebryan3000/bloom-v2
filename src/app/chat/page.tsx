"use client";

import { useChat } from "@ai-sdk/react";
import { ChatContainer } from "@/components/chat";

export default function ChatPage() {
  const { messages, sendMessage, status } = useChat();
  const isLoading = status === "streaming";

  const handleSend = (message: string) => {
    void sendMessage({ text: message });
  };

  const formattedMessages = messages.map((m) => {
    const parts: any[] | undefined = (m as any).parts;
    const textFromParts =
      Array.isArray(parts) && parts.length
        ? parts
            .map((p: any) => ("text" in p ? p.text : ""))
            .filter(Boolean)
            .join(" ")
        : undefined;
    const content = (m as any).content ?? (m as any).text ?? textFromParts ?? "";

    return {
      id: m.id,
      role: m.role as "user" | "assistant",
      content,
    };
  });

  return (
    <div className="container mx-auto h-[calc(100vh-4rem)] max-w-4xl py-4">
      <div className="flex h-full flex-col rounded-lg border shadow-sm">
        <div className="border-b px-4 py-3">
          <h1 className="text-lg font-semibold">Chat</h1>
        </div>
        <ChatContainer
          messages={formattedMessages}
          onSend={handleSend}
          isLoading={isLoading}
        />
      </div>
    </div>
  );
}
