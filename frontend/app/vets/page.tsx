"use client";
import dynamic from "next/dynamic";
import { useEffect, useState } from "react";
import { api, type Animal, type NearbyVet } from "@/lib/api";
import { useAuthed } from "@/components/useAuthed";

const VetMap = dynamic(() => import("@/components/VetMap"), { ssr: false, loading: () => <div className="h-72 rounded-2xl bg-leafsoft" /> });

// Kakamega town centre, used when location permission is denied.
const FALLBACK = { lat: 0.2827, lng: 34.7519 };
const SPECIES = ["", "dog", "cat", "cattle", "goat", "sheep", "poultry", "horse", "rabbit", "pig"];
const SERVICES = [["physical", "Clinic visit"], ["home_visit", "Home visit"], ["farm_visit", "Farm visit"], ["online", "Online consultation"], ["emergency", "Emergency"]];

export default function Vets() {
  const user = useAuthed();
  const [pos, setPos] = useState(FALLBACK);
  const [usingFallback, setUsingFallback] = useState(false);
  const [radius, setRadius] = useState(20);
  const [species, setSpecies] = useState("");
  const [emergency, setEmergency] = useState(false);
  const [home, setHome] = useState(false);
  const [vets, setVets] = useState<NearbyVet[] | null>(null);
  const [animals, setAnimals] = useState<Animal[]>([]);
  const [booking, setBooking] = useState<NearbyVet | null>(null);
  const [error, setError] = useState("");
  const [done, setDone] = useState("");

  useEffect(() => {
    navigator.geolocation?.getCurrentPosition(
      (p) => setPos({ lat: p.coords.latitude, lng: p.coords.longitude }),
      () => setUsingFallback(true),
    );
  }, []);

  useEffect(() => {
    if (!user) return;
    api.nearbyVets({ ...pos, radius_km: radius, species: species || undefined, emergency, home_visits: home })
      .then((r) => setVets(r.data)).catch((e) => setError(e.message));
  }, [user, pos, radius, species, emergency, home]);

  useEffect(() => { if (user) api.animals().then((r) => setAnimals(r.data)); }, [user]);

  async function book(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault(); setError("");
    const f = new FormData(e.currentTarget);
    try {
      await api.createBooking({
        vet_id: booking!.id, animal_id: Number(f.get("animal")), service: String(f.get("service")),
        urgency: String(f.get("urgency")), notes: String(f.get("notes") || ""),
        scheduled_at: new Date(String(f.get("when"))).toISOString(),
      });
      setDone(`Request sent to ${booking!.name}. You will see the reply under Appointments.`);
      setBooking(null);
    } catch (err) { setError(err instanceof Error ? err.message : "Could not send the request."); }
  }

  if (!user) return <p className="mt-6">Loading…</p>;
  return (
    <div className="mt-4">
      <h1 className="text-2xl font-bold">Find a vet near you</h1>
      {usingFallback && <p className="mt-1 text-sm text-[#52665e]">Location is off, so results are around Kakamega. Allow location to search near you.</p>}
      <div className="mt-4 flex flex-wrap gap-3">
        <label className="text-sm font-semibold">Radius
          <select className="input mt-1" value={radius} onChange={(e) => setRadius(Number(e.target.value))}>{[5, 20, 50, 100].map((r) => <option key={r} value={r}>{r} km</option>)}</select></label>
        <label className="text-sm font-semibold">Animal
          <select className="input mt-1" value={species} onChange={(e) => setSpecies(e.target.value)}>{SPECIES.map((s) => <option key={s} value={s}>{s || "Any"}</option>)}</select></label>
        <label className="flex items-end gap-2 pb-2 text-sm font-semibold"><input type="checkbox" checked={emergency} onChange={(e) => setEmergency(e.target.checked)} /> Emergency</label>
        <label className="flex items-end gap-2 pb-2 text-sm font-semibold"><input type="checkbox" checked={home} onChange={(e) => setHome(e.target.checked)} /> Home visits</label>
      </div>
      {vets && <div className="mt-4"><VetMap center={pos} radiusKm={radius} vets={vets} /></div>}
      {done && <p role="status" className="mt-4 rounded-lg bg-leafsoft p-3">{done}</p>}
      {error && <p role="alert" className="mt-4 text-alert">{error}</p>}
      <ul className="mt-4 space-y-3">
        {vets?.length === 0 && <li className="text-[#52665e]">No verified vets match. Try a wider radius or fewer filters.</li>}
        {vets?.map((v) => (
          <li key={v.id} className="rounded-xl border border-[#d5ded8] bg-white p-4"><span className="float-left mr-3 grid h-7 w-7 place-items-center rounded-full bg-leaf text-sm font-bold text-white" aria-hidden>{vets.indexOf(v) + 1}</span>
            <div className="flex items-start justify-between gap-3">
              <div>
                <b>{v.name}</b> <span className="rounded-full bg-leafsoft px-2 py-0.5 text-xs font-semibold text-leaf">Verified Veterinary Professional</span>
                <div className="text-sm text-[#52665e]">{[v.specialty, v.clinic].filter(Boolean).join(", ")}</div>
                <div className="mt-1 text-sm">{v.species.join(", ")}{v.home_visits ? ". Home visits" : ""}{v.emergency ? ". Emergency" : ""}</div>
              </div>
              <div className="whitespace-nowrap font-bold">{v.distance_km} km</div>
            </div>
            <button className="btn mt-3" onClick={() => { setBooking(v); setDone(""); }}>Request appointment</button>
          </li>
        ))}
      </ul>

      {booking && (
        <form onSubmit={book} className="fixed inset-x-4 bottom-4 mx-auto max-w-md space-y-3 rounded-2xl border border-[#d5ded8] bg-white p-5 shadow-xl">
          <h2 className="text-lg font-bold">Book {booking.name}</h2>
          {animals.length === 0 ? <p>Add an animal first, then come back to book.</p> : (
            <>
              <label className="block text-sm font-semibold">Animal<select name="animal" className="input mt-1">{animals.map((a) => <option key={a.id} value={a.id}>{a.name} ({a.species})</option>)}</select></label>
              <label className="block text-sm font-semibold">Service<select name="service" className="input mt-1">{SERVICES.map(([v, l]) => <option key={v} value={v}>{l}</option>)}</select></label>
              <label className="block text-sm font-semibold">When<input name="when" type="datetime-local" required className="input mt-1" /></label>
              <label className="block text-sm font-semibold">Urgency<select name="urgency" className="input mt-1"><option value="routine">Routine</option><option value="soon">Soon</option><option value="urgent">Urgent</option></select></label>
              <label className="block text-sm font-semibold">What is the concern?<textarea name="notes" rows={3} className="input mt-1" /></label>
              <p className="rounded-lg bg-red-50 p-2 text-xs">For breathing trouble, heavy bleeding, seizures, poisoning or a difficult birth, call a vet or animal hospital now instead of waiting for a booking.</p>
              <button className="btn w-full">Send request</button>
            </>
          )}
          <button type="button" className="btn-alt w-full" onClick={() => setBooking(null)}>Cancel</button>
        </form>
      )}
    </div>
  );
}
