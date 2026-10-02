"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { api, tokenStore } from "@/lib/api";

export default function Login() {
  const router = useRouter();
  const [mode, setMode] = useState<"login" | "register">("login");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setBusy(true); setError("");
    const f = new FormData(e.currentTarget);
    const email = String(f.get("email")), password = String(f.get("password"));
    try {
      const res = mode === "login"
        ? await api.login({ email, password })
        : await api.register({ email, password, name: String(f.get("name")), phone: String(f.get("phone") || "") || undefined, role: String(f.get("role")) });
      tokenStore.set(res.token);
      router.push("/animals");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong. Try again.");
    } finally { setBusy(false); }
  }

  return (
    <form onSubmit={submit} className="mx-auto mt-6 max-w-sm space-y-3 rounded-2xl border border-[#d5ded8] bg-white p-6">
      <h1 className="text-2xl font-bold">{mode === "login" ? "Sign in" : "Create your account"}</h1>
      {mode === "register" && (
        <>
          <label className="block text-sm font-semibold">Name<input name="name" required className="input mt-1" /></label>
          <label className="block text-sm font-semibold">Phone (optional)<input name="phone" inputMode="tel" placeholder="07XX XXX XXX" className="input mt-1" /></label>
          <label className="block text-sm font-semibold">I am a
            <select name="role" className="input mt-1"><option value="owner">Animal owner</option><option value="vet">Veterinarian</option><option value="clinic">Clinic or pharmacy</option><option value="organization">Shelter or organisation</option></select>
          </label>
        </>
      )}
      <label className="block text-sm font-semibold">Email<input name="email" type="email" required autoComplete="email" className="input mt-1" /></label>
      <label className="block text-sm font-semibold">Password<input name="password" type="password" required minLength={10} autoComplete={mode === "login" ? "current-password" : "new-password"} className="input mt-1" /></label>
      {error && <p role="alert" className="rounded-lg bg-red-50 p-2 text-sm text-alert">{error}</p>}
      <button className="btn w-full" disabled={busy}>{busy ? "Please wait…" : mode === "login" ? "Sign in" : "Create account"}</button>
      <button type="button" className="w-full text-sm underline" onClick={() => setMode(mode === "login" ? "register" : "login")}>
        {mode === "login" ? "New here? Create an account" : "Have an account? Sign in"}
      </button>
    </form>
  );
}
