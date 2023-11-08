import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

/**
 * https://vitejs.dev/config/
 * @type { import('vite').UserConfig }
 */
export default {
  plugins: [
    react({
      include: ["**/*.bs.mjs"],
    }),
    VitePWA({
      includeAssets: [
        "icon.svg",
        "favicon.ico",
        "robots.txt",
        "apple-touch-icon.png",
      ],
      manifest: {
        name: "Quick Translate",
        short_name: "QT",
        description: "Translate multiple languages at once in a spreadsheet",
        theme_color: "#93dcd0",
        icons: [
          {
            src: "icon-192.png",
            sizes: "192x192",
            type: "image/png",
          },
          {
            src: "icon-512.png",
            sizes: "512x512",
            type: "image/png",
          },
          {
            src: "icon-512.png",
            sizes: "512x512",
            type: "image/png",
            purpose: "any maskable",
          },
        ],
      },
    }),
  ],
};
