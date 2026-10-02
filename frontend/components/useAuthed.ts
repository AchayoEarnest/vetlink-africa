"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { api, ApiError, tokenStore, type User } from "@/lib/api";

export function useAuthed() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  useEffect(() => {
    if (!tokenStore.get()) { router.replace("/login"); return; }
    api.me().then((r) => setUser(r.user)).catch((e) => {
      if (e instanceof ApiError && e.status === 401) { tokenStore.clear(); router.replace("/login"); }
    });
  }, [router]);
  return user;
}
