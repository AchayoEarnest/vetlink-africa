"use client";
import { useEffect, useState } from "react";
import { api, type VetProfile } from "@/lib/api";
import { useAuthed } from "@/components/useAuthed";

const SPECIES = ["dog", "cat", "cattle", "goat", "sheep", "poultry", "horse", "rabbit", "pig"];
const STATUS: Record<string, string> = {
  pending: "Pending review. You are not shown in search yet.",
  verified: "Verified Veterinary Professional",
  rejected: "Not verified. Contact support to resubmit.",
  suspended: "Suspended",
};

export default function Profile() {
  const user = useAuthed();
  const [p, setP] = useState<VetProfile | null>(null);
  const [species, setSpecies] = useState<string[]>([]);
  const [coords, setCoords] = useState<{ lat: number | null; lng: number | null }>({ lat: null, lng: null });
  const [msg, setMsg] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    if (user?.role !== "vet") return;
    api.vetProfile().then((r) => { setP(r.data); setSpecies(r.data.species); setCoords({ lat: r.data.lat, lng: r.data.lng }); })
      .catch((e) => setError(e.message));
  }, [user]);

  function locate() {
    navigator.geolocation?.getCurrentPosition(
      (pos) => setCoords({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
      () => setError("Could not read your location. Allow location access and try again."),
    );
  }

  async function save(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault(); setError(""); setMsg("");
    const f = new FormData(e.currentTarget);
    try {
      const r = await api.saveVetProfile({
        clinic_name: String(f.get("clinic") || ""), specialty: String(f.get("specialty") || ""),
        registration_number: String(f.get("reg") || ""), species,
        home_visits: f.get("home") === "on", emergency: f.get("emergency") === "on",
        ...(coords.lat !== null && coords.lng !== null ? { lat: coords.lat, lng: coords.lng } : {}),
      });
      setP(r.data); setMsg("Profile saved.");
    } catch (err) { setError(err instanceof Error ? err.message : "Could not save your profile."); }
  }

  if (!user) return <p className="mt-6">Loading…</p>;
  if (user.role !== "vet") return <p className="mt-6">This page is for veterinarians.</p>;
  if (!p) return <p className="mt-6">{error || "Loading…"}</p>;

  return (
    <form onSubmit={save} className="mx-auto mt-4 max-w-lg space-y-3 rounded-2xl border border-[#d5ded8] bg-white p-6">
      <h1 className="text-2xl font-bold">Your professional profile</h1>
      <p className="rounded-lg bg-leafsoft p-3 text-sm"><b>Status:</b> {STATUS[p.verification_status]}</p>
      <label className="block text-sm font-semibold">Clinic or practice<input name="clinic" defaultValue={p.clinic_name ?? ""} className="input mt-1" /></label>
      <label className="block text-sm font-semibold">Specialty<input name="specialty" defaultValue={p.specialty ?? ""} className="input mt-1" /></label>
      <label className="block text-sm font-semibold">Registration number<input name="reg" defaultValue={p.registration_number ?? ""} className="input mt-1" />
        <span className="font-normal text-[#52665e]">Used by our team to verify you. It is never shown publicly.</span></label>
      <fieldset><legend className="text-sm font-semibold">Animals you treat</legend>
        <div className="mt-1 flex flex-wrap gap-2">{SPECIES.map((s) => (
          <label key={s} className="flex items-center gap-1 text-sm"><input type="checkbox" checked={species.includes(s)}
            onChange={(e) => setSpecies((cur) => e.target.checked ? [...cur, s] : cur.filter((x) => x !== s))} /> {s}</label>
        ))}</div></fieldset>
      <label className="flex items-center gap-2 text-sm font-semibold"><input name="home" type="checkbox" defaultChecked={p.home_visits} /> I do home and farm visits</label>
      <label className="flex items-center gap-2 text-sm font-semibold"><input name="emergency" type="checkbox" defaultChecked={p.emergency} /> I take emergency calls</label>
      <div className="text-sm">
        <b>Location:</b> {coords.lat !== null ? `${coords.lat.toFixed(3)}, ${coords.lng!.toFixed(3)}` : "not set. You will not appear in search until you set it."}
        <button type="button" className="btn-alt ml-3" onClick={locate}>Use my current location</button>
      </div>
      {error && <p role="alert" className="text-sm text-alert">{error}</p>}
      {msg && <p role="status" className="text-sm text-leaf">{msg}</p>}
      <button className="btn w-full">Save profile</button>
    </form>
  );
}
