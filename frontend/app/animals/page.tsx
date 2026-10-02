"use client";
import { useEffect, useState } from "react";
import { api, type Animal } from "@/lib/api";
import { useAuthed } from "@/components/useAuthed";

const SPECIES = ["dog", "cat", "cattle", "goat", "sheep", "poultry", "horse", "rabbit", "pig", "fish", "other"];

export default function Animals() {
  const user = useAuthed();
  const [animals, setAnimals] = useState<Animal[] | null>(null);
  const [error, setError] = useState("");

  const load = () => api.animals().then((r) => setAnimals(r.data)).catch((e) => setError(e.message));
  useEffect(() => { if (user) load(); }, [user]);

  async function add(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault(); setError("");
    const form = e.currentTarget;
    const f = new FormData(form);
    try {
      await api.createAnimal({ name: String(f.get("name")), species: String(f.get("species")), breed: String(f.get("breed") || "") || null });
      form.reset(); load();
    } catch (err) { setError(err instanceof Error ? err.message : "Could not save the animal."); }
  }

  if (!user) return <p className="mt-6">Loading…</p>;
  return (
    <div className="mt-4 grid gap-6 md:grid-cols-[1.4fr_1fr]">
      <section>
        <h1 className="mb-3 text-2xl font-bold">My animals</h1>
        {animals?.length === 0 && <p className="text-[#52665e]">No animals yet. Add your first one.</p>}
        <ul className="space-y-2">
          {animals?.map((a) => (
            <li key={a.id}><a href={`/animals/${a.id}`} className="block rounded-xl border border-[#d5ded8] bg-white p-4 hover:border-leaf">
              <b>{a.name}</b> <span className="text-[#52665e]">{a.species}{a.breed ? `, ${a.breed}` : ""}</span>
            </a></li>
          ))}
        </ul>
      </section>
      <form onSubmit={add} className="h-fit space-y-3 rounded-2xl border border-[#d5ded8] bg-white p-5">
        <h2 className="text-lg font-bold">Add an animal</h2>
        <label className="block text-sm font-semibold">Name<input name="name" required className="input mt-1" /></label>
        <label className="block text-sm font-semibold">Species<select name="species" className="input mt-1">{SPECIES.map((s) => <option key={s}>{s}</option>)}</select></label>
        <label className="block text-sm font-semibold">Breed<input name="breed" className="input mt-1" /></label>
        {error && <p role="alert" className="text-sm text-alert">{error}</p>}
        <button className="btn w-full">Save animal</button>
      </form>
    </div>
  );
}
