"use client";

import { useChat } from "ai/react";
import { ChatContainer } from "@/components/chat";

export default function ChatPage() {
  const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat();

  const handleSend = (message: string) => {
    handleInputChange({ target: { value: message } } as React.ChangeEvent<HTMLInputElement>);
    handleSubmit(new Event("submit") as unknown as React.FormEvent<HTMLFormElement>);
  };

  const formattedMessages = messages.map((m) => ({
    id: m.id,
    role: m.role as "user" | "assistant",
    content: m.content,
  }));

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
