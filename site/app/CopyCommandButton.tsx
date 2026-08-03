"use client";

import { useState } from "react";

export function CopyCommandButton({ command }: { command: string }) {
  const [copied, setCopied] = useState(false);

  async function copyCommand() {
    await navigator.clipboard.writeText(command);
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1800);
  }

  return (
    <button className="copyCommand" type="button" onClick={copyCommand} aria-label="コマンドをコピー">
      <span aria-hidden="true">{copied ? "✓" : "⧉"}</span>
      {copied ? "コピー済み" : "コピー"}
    </button>
  );
}
