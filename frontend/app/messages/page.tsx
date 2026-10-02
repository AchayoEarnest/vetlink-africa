"use client";
import { useEffect, useRef, useState } from "react";
import { Socket } from "phoenix";
import { api, tokenStore, WS_URL, type Conversation, type Message } from "@/lib/api";
import { useAuthed } from "@/components/useAuthed";

export default function Messages() {
  const user = useAuthed();
  const [convs, setConvs] = useState<Conversation[] | null>(null);
  const [active, setActive] = useState<number | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [text, setText] = useState("");
  const [live, setLive] = useState(false);
  const [error, setError] = useState("");
  const endRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!user) return;
    api.conversations().then((r) => { setConvs(r.data); if (r.data[0]) setActive((a) => a ?? r.data[0].id); })
      .catch((e) => setError(e.message));
  }, [user]);

  // Load history, then listen for new messages in real time.
  useEffect(() => {
    if (!user || active === null) return;
    let cancelled = false;
    setMessages([]); setLive(false);
    api.messages(active).then((r) => { if (!cancelled) setMessages(r.data); }).catch((e) => setError(e.message));

    const socket = new Socket(WS_URL, { params: { token: tokenStore.get() ?? "" } });
    socket.connect();
    const channel = socket.channel(`conversation:${active}`, {});
    channel.on("new_message", (m: Message) =>
      setMessages((prev) => (prev.some((x) => x.id === m.id) ? prev : [...prev, m])));
    channel.join().receive("ok", () => setLive(true)).receive("error", () => setLive(false));
    return () => { cancelled = true; channel.leave(); socket.disconnect(); };
  }, [user, active]);

  useEffect(() => { endRef.current?.scrollIntoView({ behavior: "smooth" }); }, [messages]);

  async function send(e: React.FormEvent) {
    e.preventDefault();
    const body = text.trim();
    if (!body || active === null) return;
    setError("");
    try {
      const r = await api.sendMessage(active, body);
      setMessages((prev) => (prev.some((x) => x.id === r.data.id) ? prev : [...prev, r.data]));
      setText("");
    } catch (err) { setError(err instanceof Error ? err.message : "Message not sent. Try again."); }
  }

  if (!user) return <p className="mt-6">Loading…</p>;
  const other = (c: Conversation) => (c.owner_id === user.id ? c.vet_name : c.owner_name);
  const current = convs?.find((c) => c.id === active);
  const lastOwn = [...messages].reverse().find((m) => m.sender_id === user.id);

  return (
    <div className="mt-4">
      <h1 className="text-2xl font-bold">Messages</h1>
      {convs?.length === 0 && <p className="mt-3 text-[#52665e]">No conversations yet. A chat opens when you book a vet.</p>}
      {error && <p role="alert" className="mt-2 text-alert">{error}</p>}
      {!!convs?.length && (
        <div className="mt-4 grid gap-4 md:grid-cols-[240px_1fr]">
          <ul className="space-y-2">
            {convs.map((c) => (
              <li key={c.id}>
                <button onClick={() => setActive(c.id)} aria-current={c.id === active}
                  className={`w-full rounded-xl border p-3 text-left ${c.id === active ? "border-leaf bg-leafsoft" : "border-[#d5ded8] bg-white"}`}>
                  <b>{other(c)}</b>
                </button>
              </li>
            ))}
          </ul>
          <section className="flex h-[70vh] flex-col rounded-2xl border border-[#d5ded8] bg-white">
            <div className="flex items-center justify-between border-b border-[#d5ded8] p-3">
              <b>{current ? other(current) : ""}</b>
              <span className="text-xs text-[#52665e]">{live ? "Live" : "Reconnecting…"}</span>
            </div>
            {user.role !== "vet" && lastOwn?.urgent_hint && (
              <p role="alert" className="m-3 rounded-lg border-l-4 border-alert bg-red-50 p-3 text-sm">
                <b>This may be an emergency.</b> Do not wait for a reply. Call a vet or animal hospital now.
              </p>
            )}
            <div className="flex-1 space-y-2 overflow-y-auto p-3" aria-live="polite">
              {messages.map((m) => (
                <div key={m.id} className={`max-w-[80%] whitespace-pre-wrap rounded-2xl px-3 py-2 ${m.sender_id === user.id ? "ml-auto bg-leaf text-white" : "bg-leafsoft"}`}>
                  {m.body}
                  <div className="mt-1 text-[11px] opacity-70">{new Date(m.inserted_at).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}</div>
                </div>
              ))}
              <div ref={endRef} />
            </div>
            <form onSubmit={send} className="flex gap-2 border-t border-[#d5ded8] p-3">
              <input className="input" value={text} onChange={(e) => setText(e.target.value)} maxLength={4000} aria-label="Message" placeholder="Write a message" />
              <button className="btn" disabled={!text.trim()}>Send</button>
            </form>
          </section>
        </div>
      )}
      <p className="mt-3 text-xs text-[#52665e]">Phone numbers and addresses are not shared. Keep contact details in VetLink until your appointment is confirmed.</p>
    </div>
  );
}
