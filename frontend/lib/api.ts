const BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:4000/api";

export type User = { id: number; name: string; email: string; role: string; county: string | null };
export type Animal = {
  id: number; name: string; species: string; breed: string | null; sex: string | null;
  date_of_birth: string | null; weight_kg: string | null; allergies: string | null;
};
export type HealthRecord = {
  id: number; kind: string; title: string; notes: string | null; occurred_on: string;
  follow_up_on: string | null; author_role: "owner" | "vet"; verified_author: boolean;
};

export type NearbyVet = {
  id: number; name: string; clinic: string | null; specialty: string | null; species: string[];
  services: string[]; home_visits: boolean; emergency: boolean; verified: true; distance_km: number;
  lat: number; lng: number;
};
export type Booking = {
  id: number; animal_id: number; vet_id: number; owner_id: number; service: string; urgency: string;
  scheduled_at: string; status: string; notes: string | null;
  animal_name: string; species: string; owner_name: string; vet_name: string;
};
export type Conversation = { id: number; owner_id: number; vet_id: number; owner_name: string; vet_name: string; updated_at: string };
export type Message = { id: number; conversation_id: number; sender_id: number; body: string; inserted_at: string; urgent_hint: boolean };
export const WS_URL = process.env.NEXT_PUBLIC_WS_URL ?? "ws://localhost:4000/socket";
export type VetProfile = {
  clinic_name: string | null; specialty: string | null; species: string[]; services: string[];
  home_visits: boolean; emergency: boolean; registration_number: string | null;
  verification_status: "pending" | "verified" | "rejected" | "suspended"; lat: number | null; lng: number | null;
};
export type Doc = {
  id: number; animal_id: number; kind: string; original_name: string; content_type: string;
  byte_size: number; uploader_role: "owner" | "vet"; inserted_at: string;
};
export type BookingAction = "confirm" | "reschedule" | "start" | "complete" | "cancel";

export class ApiError extends Error {
  constructor(public status: number, public body: { error?: string; errors?: Record<string, string[]> }) {
    super(body.error ?? Object.entries(body.errors ?? {}).map(([k, v]) => `${k} ${v.join(", ")}`).join("; ") ?? "Request failed");
  }
}

export const tokenStore = {
  get: () => (typeof window === "undefined" ? null : window.localStorage.getItem("vl_token")),
  set: (t: string) => window.localStorage.setItem("vl_token", t),
  clear: () => window.localStorage.removeItem("vl_token"),
};

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = tokenStore.get();
  const res = await fetch(`${BASE}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init.headers,
    },
  });
  if (res.status === 204) return undefined as T;
  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw new ApiError(res.status, body);
  return body as T;
}

export const api = {
  register: (b: { name: string; email: string; password: string; phone?: string; role: string }) =>
    request<{ token: string; user: User }>("/auth/register", { method: "POST", body: JSON.stringify(b) }),
  login: (b: { email: string; password: string }) =>
    request<{ token: string; user: User }>("/auth/login", { method: "POST", body: JSON.stringify(b) }),
  me: () => request<{ user: User }>("/me"),
  animals: () => request<{ data: Animal[] }>("/animals"),
  animal: (id: string) => request<{ data: Animal; access: "owner" | "vet" }>(`/animals/${id}`),
  createAnimal: (b: Partial<Animal>) => request<{ data: Animal }>("/animals", { method: "POST", body: JSON.stringify(b) }),
  records: (id: string) => request<{ data: HealthRecord[] }>(`/animals/${id}/records`),
  addRecord: (id: string, b: { kind: string; title: string; notes?: string; occurred_on: string }) =>
    request<{ data: HealthRecord }>(`/animals/${id}/records`, { method: "POST", body: JSON.stringify(b) }),
  nearbyVets: (q: { lat: number; lng: number; radius_km: number; species?: string; emergency?: boolean; home_visits?: boolean }) => {
    const p = new URLSearchParams({ lat: String(q.lat), lng: String(q.lng), radius_km: String(q.radius_km) });
    if (q.species) p.set("species", q.species);
    if (q.emergency) p.set("emergency", "true");
    if (q.home_visits) p.set("home_visits", "true");
    return request<{ data: NearbyVet[] }>(`/vets/nearby?${p}`);
  },
  bookings: () => request<{ data: Booking[] }>("/bookings"),
  createBooking: (b: { vet_id: number; animal_id: number; service: string; urgency: string; scheduled_at: string; notes?: string }) =>
    request<{ data: Booking }>("/bookings", { method: "POST", body: JSON.stringify(b) }),
  bookingAction: (id: number, action: BookingAction, scheduled_at?: string) =>
    request<{ data: Booking }>(`/bookings/${id}`, { method: "PATCH", body: JSON.stringify({ action, scheduled_at }) }),
  conversations: () => request<{ data: Conversation[] }>("/conversations"),
  messages: (id: number) => request<{ data: Message[] }>(`/conversations/${id}/messages`),
  sendMessage: (id: number, body: string) =>
    request<{ data: Message }>(`/conversations/${id}/messages`, { method: "POST", body: JSON.stringify({ body }) }),
  vetProfile: () => request<{ data: VetProfile }>("/vets/me"),
  saveVetProfile: (b: Partial<VetProfile>) => request<{ data: VetProfile }>("/vets/me", { method: "PUT", body: JSON.stringify(b) }),
  documents: (animalId: string) => request<{ data: Doc[] }>(`/animals/${animalId}/documents`),
  deleteDocument: (id: number) => request<void>(`/documents/${id}`, { method: "DELETE" }),
  // Multipart upload: let the browser set the Content-Type boundary.
  uploadDocument: async (animalId: string, file: File, kind: string) => {
    const body = new FormData();
    body.append("file", file);
    body.append("kind", kind);
    const token = tokenStore.get();
    const res = await fetch(`${BASE}/animals/${animalId}/documents`, {
      method: "POST", body, headers: token ? { Authorization: `Bearer ${token}` } : {},
    });
    const json = await res.json().catch(() => ({}));
    if (!res.ok) throw new ApiError(res.status, json);
    return json as { data: Doc };
  },
  // Files need the auth header, so fetch as a blob and save it from the browser.
  downloadDocument: async (doc: Doc) => {
    const token = tokenStore.get();
    const res = await fetch(`${BASE}/documents/${doc.id}/download`, { headers: token ? { Authorization: `Bearer ${token}` } : {} });
    if (!res.ok) throw new ApiError(res.status, await res.json().catch(() => ({})));
    const url = URL.createObjectURL(await res.blob());
    const a = document.createElement("a");
    a.href = url; a.download = doc.original_name; a.click();
    URL.revokeObjectURL(url);
  },
};
