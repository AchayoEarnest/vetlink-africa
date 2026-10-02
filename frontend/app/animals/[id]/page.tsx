"use client";
import { use, useEffect, useState } from "react";
import { api, type Animal, type HealthRecord } from "@/lib/api";
import { useAuthed } from "@/components/useAuthed";
import Documents from "@/components/Documents";

const OWNER_KINDS = ["note", "vaccination", "weight", "feed", "medication", "document", "breeding", "mortality"];
const VET_KINDS = ["consultation", "diagnosis", "treatment", "lab_test", "surgery", "follow_up", "vaccination", "medication", "breeding"];

export default function AnimalPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const user = useAuthed();
  const [animal, setAnimal] = useState<Animal | null>(null);
  const [access, setAccess] = useState<"owner" | "vet">("owner");
  const [records, setRecords] = useState<HealthRecord[]>([]);
  const [error, setError] = useState("");

  const load = async () => {
    try {
      const [a, r] = await Promise.all([api.animal(id), api.records(id)]);
      setAnimal(a.data); setAccess(a.access); setRecords(r.data);
    } catch (e) { setError(e instanceof Error ? e.message : "Could not load this animal."); }
  };
  useEffect(() => { if (user) load(); }, [user, id]);

  async function add(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault(); setError("");
    const form = e.currentTarget;
    const f = new FormData(form);
    try {
      await api.addRecord(id, { kind: String(f.get("kind")), title: String(f.get("title")), notes: String(f.get("notes") || ""), occurred_on: String(f.get("occurred_on")) });
      form.reset(); load();
    } catch (err) { setError(err instanceof Error ? err.message : "Could not save the record."); }
  }

  if (error && !animal) return <p role="alert" className="mt-6 text-alert">{error}</p>;
  if (!animal) return <p className="mt-6">Loading…</p>;
  const kinds = access === "owner" ? OWNER_KINDS : VET_KINDS;

  return (
    <div className="mt-4 grid gap-6 md:grid-cols-[1.4fr_1fr]">
      <section>
        <a href="/animals" className="text-sm underline">Back to my animals</a>
        <h1 className="mt-2 text-3xl font-bold">{animal.name}</h1>
        <p className="text-[#52665e]">{animal.species}{animal.breed ? `, ${animal.breed}` : ""}</p>
        <h2 className="mb-3 mt-6 text-lg font-bold">Health timeline</h2>
        {records.length === 0 && <p className="text-[#52665e]">No records yet.</p>}
        <ol className="space-y-4 border-l-2 border-leafsoft pl-5">
          {records.map((r) => (
            <li key={r.id}>
              <b>{r.title}</b> <span className="rounded-full bg-leafsoft px-2 py-0.5 text-xs font-semibold text-leaf">{r.kind.replace("_", " ")}</span>
              <div className="text-sm text-[#52665e]">{r.occurred_on}</div>
              <div className={`text-xs font-semibold ${r.verified_author ? "text-leaf" : "text-[#52665e]"}`}>
                {r.verified_author ? "Verified veterinary professional" : "Owner entry"}
              </div>
              {r.notes && <p className="mt-1">{r.notes}</p>}
            </li>
          ))}
        </ol>
        <Documents animalId={id} access={access} />
      </section>
      <form onSubmit={add} className="h-fit space-y-3 rounded-2xl border border-[#d5ded8] bg-white p-5">
        <h2 className="text-lg font-bold">Add a record</h2>
        <label className="block text-sm font-semibold">Type<select name="kind" className="input mt-1">{kinds.map((k) => <option key={k} value={k}>{k.replace("_", " ")}</option>)}</select></label>
        <label className="block text-sm font-semibold">Title<input name="title" required className="input mt-1" /></label>
        <label className="block text-sm font-semibold">Date<input name="occurred_on" type="date" required className="input mt-1" /></label>
        <label className="block text-sm font-semibold">Notes<textarea name="notes" rows={3} className="input mt-1" /></label>
        {error && <p role="alert" className="text-sm text-alert">{error}</p>}
        <button className="btn w-full">Save record</button>
        <p className="text-xs text-[#52665e]">Diagnoses and treatments can only be added by a verified vet you have shared this animal with.</p>
      </form>
    </div>
  );
}
