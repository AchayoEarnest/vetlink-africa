"use client";
import { useEffect, useRef } from "react";
import "leaflet/dist/leaflet.css";
import type { NearbyVet } from "@/lib/api";

type Props = { center: { lat: number; lng: number }; radiusKm: number; vets: NearbyVet[] };

export default function VetMap({ center, radiusKm, vets }: Props) {
  const el = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let map: import("leaflet").Map | undefined;
    let cancelled = false;

    import("leaflet").then((L) => {
      if (cancelled || !el.current) return;
      map = L.map(el.current, { scrollWheelZoom: false }).setView([center.lat, center.lng], 11);
      L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
        maxZoom: 19,
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      }).addTo(map);

      const circle = L.circle([center.lat, center.lng], { radius: radiusKm * 1000, color: "#1f6b4f", weight: 1, fillOpacity: 0.05 }).addTo(map);
      L.circleMarker([center.lat, center.lng], { radius: 7, color: "#0f2a22", fillColor: "#f2b33d", fillOpacity: 1 }).addTo(map).bindTooltip("You");

      vets.forEach((v, i) => {
        const icon = L.divIcon({
          className: "",
          iconSize: [28, 28],
          html: `<div style="width:28px;height:28px;border-radius:50%;background:${v.emergency ? "#c8321f" : "#1f6b4f"};color:#fff;font:700 13px sans-serif;display:grid;place-items:center;border:2px solid #fff">${i + 1}</div>`,
        });
        const pop = document.createElement("div");
        const b = document.createElement("b"); b.textContent = v.name;       // textContent: names are user data
        const d = document.createElement("div"); d.textContent = `${v.distance_km} km${v.emergency ? ", emergency" : ""}`;
        pop.append(b, d);
        L.marker([v.lat, v.lng], { icon, title: v.name }).addTo(map!).bindPopup(pop);
      });

      map.fitBounds(circle.getBounds(), { padding: [10, 10] });
    });

    return () => { cancelled = true; map?.remove(); };
  }, [center.lat, center.lng, radiusKm, vets]);

  return <div ref={el} className="h-72 w-full overflow-hidden rounded-2xl border border-[#d5ded8]" role="img" aria-label="Map of verified vets near you" />;
}
