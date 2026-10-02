import type { Config } from "tailwindcss";

export default {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: { leaf: "#1f6b4f", leafsoft: "#d9ece3", ink: "#0f2a22", alert: "#c8321f" },
    },
  },
  plugins: [],
} satisfies Config;
