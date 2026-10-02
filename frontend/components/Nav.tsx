"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { api, tokenStore } from "@/lib/api";

export default function Nav() {
  const router = useRouter();
  const [role, setRole] = useState<string | null>(null);
  useEffect(() => { if (tokenStore.get()) api.me().then((r) => setRole(r.user.role)).catch(() => {}); }, []);
  return (
    <nav className="flex items-center gap-4 text-sm font-semibold">
      <a href="/animals">My animals</a>
      <a href="/vets">Find a vet</a>
      <a href="/bookings">Appointments</a>
      <a href="/messages">Messages</a>
      {role === "vet" && <a href="/profile">My profile</a>}
      <button className="underline" onClick={() => { tokenStore.clear(); router.push("/login"); }}>Sign out</button>
    </nav>
  );
}
