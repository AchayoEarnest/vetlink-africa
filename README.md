# VetLink Africa

Better Connections. Better Animal Care.

First vertical of the real app: accounts and roles, animal profiles, a health-record timeline with
verified-vet authorship, and PostGIS "vets near me" search.

```
prototypes/ Clickable HTML prototypes of every module (open in a browser, no setup)
backend/    Phoenix 1.7 JSON API (Elixir) + PostgreSQL/PostGIS
frontend/   Next.js 15, TypeScript, Tailwind
docker-compose.yml   PostGIS database
```

## Run it

Requirements: Elixir 1.16+, Node 20+, Docker.

```bash
docker compose up -d                 # PostGIS on :5432

cd backend
mix setup                            # deps, create DB, migrate, seed
mix phx.server                       # API on http://localhost:4000

cd ../frontend
cp .env.example .env.local
npm install
npm run dev                          # http://localhost:3000
```

Seed logins (password `password-1234`): `owner@example.com`, `vet@example.com` (verified, Kakamega).

Try the API:

```bash
curl localhost:4000/api/health
curl "localhost:4000/api/vets/nearby?lat=0.28&lng=34.75&radius_km=20"
```

## Run the tests

```bash
cd backend && mix test
```

## What is built

| Area | Endpoints |
|---|---|
| Auth | `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/me` |
| Animals | `GET/POST /api/animals`, `GET /api/animals/:id`, `POST /api/animals/:id/shares` |
| Records | `GET/POST /api/animals/:animal_id/records` |
| Vets | `GET /api/vets/nearby` (public, verified only, coordinates rounded to ~100 m), `GET/PUT /api/vets/me` |
| Messages | `GET /api/conversations`, `GET/POST /api/conversations/:id/messages`, WebSocket `/socket` (channel `conversation:ID`, token param) |
| Bookings | `GET/POST /api/bookings`, `PATCH /api/bookings/:id` with `action` = confirm, reschedule, start, complete, cancel |

## Rules enforced in code (see `backend/lib/vetlink/animals.ex`)

- Owners see only their own animals. Vets see only animals an owner has shared with them.
- Owners can add owner-type entries only. Diagnoses, treatments, lab tests and surgery need a
  **verified** vet with access, and are stamped `verified_author`.
- Registration can never create an `admin`. A vet starts `pending`; `verification_status` cannot
  be set through the API. Use `Vetlink.Vets.mark_verified/1` from an IEx console until an admin
  review flow exists.
- The nearby search returns verified vets only.
- A chat opens automatically when an owner books a vet. Only those two people can read or write in it; vets cannot cold-message owners. Messages are flagged server-side when they mention emergency signs, and the owner sees a "call a vet now" banner.
- Booking a vet needs a verified vet and your own animal, and shares that animal with the vet. Only the vet can accept, start or complete; either side can cancel or reschedule; completed visits cannot be cancelled.

Frontend pages: `/login`, `/animals`, `/animals/:id`, `/vets` (map, filters, booking), `/bookings`, `/messages`, `/profile` (vets).
The map uses Leaflet with OpenStreetMap tiles. Fine for development; use a hosted tile provider before heavy traffic.

## Honest status

- The backend was written without a compiler available (no Elixir, and hex.pm was unreachable in the
  build sandbox). Expect to fix a few compile or typo errors on first `mix compile`. Run `mix test` first.
- The frontend source is complete, but check `npm run typecheck` on your machine.
- Tokens are stored in `localStorage` for speed of development. Before launch, move to httpOnly
  cookies, add rate limiting on login, and set a real `SECRET_KEY_BASE`.

## Next steps (in order)

1. Run, compile and fix; add controller tests (ConnCase).
2. Document uploads (vaccination cards, lab reports) with object storage, then the vet verification review flow.
3. Message attachments, unread counts and push notifications.
4. Object storage uploads for vaccination cards and lab reports.
5. Vet verification workflow with document upload and admin review.
6. Notifications, M-Pesa (Daraja STK push) behind a payments behaviour, then marketplace, blog, community.
