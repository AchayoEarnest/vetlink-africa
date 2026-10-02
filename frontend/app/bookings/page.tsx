"use client";
import { useEffect, useState } from "react";
import { api, type Booking, type BookingAction } from "@/lib/api";
import { useAuthed } from "@/components/useAuthed";

const LABEL: Record<string, string> = { requested: "Requested", confirmed: "Confirmed", rescheduled: "Rescheduled", in_progress: "In progress", completed: "Completed", cancelled: "Cancelled" };

// Which buttons each side sees for each status. The server enforces the same rules.
function actionsFor(role: string, status: string): [BookingAction, string][] {
  const vet = role === "vet";
  const out: [BookingAction, string][] = [];
  if (vet && ["requested", "rescheduled"].includes(status)) out.push(["confirm", "Accept"]);
  if (vet && ["confirmed", "rescheduled"].includes(status)) out.push(["start", "Start visit"]);
  if (vet && status === "in_progress") out.push(["complete", "Mark completed"]);
  if (["requested", "confirmed"].includes(status)) out.push(["reschedule", "Reschedule"]);
  if (["requested", "confirmed", "rescheduled"].includes(status)) out.push(["cancel", "Cancel"]);
  return out;
}

export default function Bookings() {
  const user = useAuthed();
  const [rows, setRows] = useState<Booking[] | null>(null);
  const [error, setError] = useState("");

  const load = () => api.bookings().then((r) => setRows(r.data)).catch((e) => setError(e.message));
  useEffect(() => { if (user) load(); }, [user]);

  async function act(b: Booking, action: BookingAction) {
    setError("");
    let when: string | undefined;
    if (action === "reschedule") {
      const v = prompt("New date and time (YYYY-MM-DD HH:MM)");
      if (!v) return;
      const d = new Date(v.replace(" ", "T"));
      if (Number.isNaN(d.getTime())) { setError("That date is not valid."); return; }
      when = d.toISOString();
    }
    try { await api.bookingAction(b.id, action, when); load(); }
    catch (e) { setError(e instanceof Error ? e.message : "Could not update the appointment."); }
  }

  if (!user) return <p className="mt-6">Loading…</p>;
  return (
    <div className="mt-4">
      <h1 className="text-2xl font-bold">Appointments</h1>
      {error && <p role="alert" className="mt-2 text-alert">{error}</p>}
      {rows?.length === 0 && <p className="mt-3 text-[#52665e]">Nothing booked yet. Find a vet to request an appointment.</p>}
      <ul className="mt-4 space-y-3">
        {rows?.map((b) => (
          <li key={b.id} className="rounded-xl border border-[#d5ded8] bg-white p-4">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <b>{b.animal_name} <span className="font-normal text-[#52665e]">({b.species})</span></b>
              <span className="rounded-full bg-leafsoft px-2 py-0.5 text-xs font-semibold text-leaf">{LABEL[b.status] ?? b.status}</span>
            </div>
            <div className="text-sm">{new Date(b.scheduled_at).toLocaleString()}. {b.service.replace("_", " ")}. {user.role === "vet" ? `Owner: ${b.owner_name}` : `Vet: ${b.vet_name}`}</div>
            {b.urgency !== "routine" && <div className="text-sm font-semibold text-alert">{b.urgency}</div>}
            {b.notes && <p className="mt-1 text-sm">{b.notes}</p>}
            <div className="mt-3 flex flex-wrap gap-2">
              {actionsFor(user.role, b.status).map(([a, label]) => (
                <button key={a} className={a === "cancel" ? "btn-alt" : "btn"} onClick={() => act(b, a)}>{label}</button>
              ))}
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
