"use client";
import { useEffect, useState } from "react";
import { api, type Doc } from "@/lib/api";

const KINDS: [string, string][] = [
  ["vaccination_card", "Vaccination card"], ["lab_report", "Lab report"], ["prescription", "Prescription"],
  ["xray", "X-ray"], ["image", "Photo"], ["certificate", "Certificate"], ["other", "Other"],
];
const MAX = 10_000_000;
const size = (n: number) => (n >= 1e6 ? `${(n / 1e6).toFixed(1)} MB` : `${Math.max(1, Math.round(n / 1e3))} KB`);

export default function Documents({ animalId, access }: { animalId: string; access: "owner" | "vet" }) {
  const [docs, setDocs] = useState<Doc[]>([]);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const load = () => api.documents(animalId).then((r) => setDocs(r.data)).catch((e) => setError(e.message));
  useEffect(() => { load(); }, [animalId]);

  async function upload(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault(); setError("");
    const form = e.currentTarget;
    const f = new FormData(form);
    const file = f.get("file") as File;
    if (!file || file.size === 0) { setError("Choose a file first."); return; }
    if (file.size > MAX) { setError("That file is over 10 MB. Try a smaller scan or photo."); return; }
    setBusy(true);
    try { await api.uploadDocument(animalId, file, String(f.get("kind"))); form.reset(); await load(); }
    catch (err) { setError(err instanceof Error ? err.message : "Upload failed. Try again."); }
    finally { setBusy(false); }
  }

  async function remove(d: Doc) {
    if (!confirm(`Delete ${d.original_name}?`)) return;
    try { await api.deleteDocument(d.id); load(); } catch (err) { setError(err instanceof Error ? err.message : "Could not delete."); }
  }

  return (
    <section className="mt-8">
      <h2 className="mb-3 text-lg font-bold">Documents</h2>
      {docs.length === 0 && <p className="text-[#52665e]">No documents yet. Add vaccination cards, lab reports or prescriptions.</p>}
      <ul className="space-y-2">
        {docs.map((d) => (
          <li key={d.id} className="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-[#d5ded8] bg-white p-3">
            <span>
              <b>{d.original_name}</b>
              <span className="block text-xs text-[#52665e]">
                {KINDS.find(([k]) => k === d.kind)?.[1] ?? d.kind}. {size(d.byte_size)}. Added by {d.uploader_role === "vet" ? "a vet" : "the owner"}.
              </span>
            </span>
            <span className="flex gap-2">
              <button className="btn-alt" onClick={() => api.downloadDocument(d).catch((err) => setError(err.message))}>Download</button>
              {(access === "owner" || d.uploader_role === access) && <button className="btn-alt" onClick={() => remove(d)}>Delete</button>}
            </span>
          </li>
        ))}
      </ul>
      <form onSubmit={upload} className="mt-4 space-y-2 rounded-xl border border-dashed border-[#d5ded8] p-4">
        <div className="flex flex-wrap gap-2">
          <select name="kind" className="input w-auto" aria-label="Document type">{KINDS.map(([k, l]) => <option key={k} value={k}>{l}</option>)}</select>
          <input name="file" type="file" accept=".pdf,.jpg,.jpeg,.png,.webp,application/pdf,image/jpeg,image/png,image/webp" className="input w-auto flex-1" aria-label="File" />
        </div>
        {error && <p role="alert" className="text-sm text-alert">{error}</p>}
        <button className="btn" disabled={busy}>{busy ? "Uploading…" : "Upload"}</button>
        <p className="text-xs text-[#52665e]">PDF, JPEG, PNG or WebP, up to 10 MB. Only you and vets you share this animal with can open these files.</p>
      </form>
    </section>
  );
}
