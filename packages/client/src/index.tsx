import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App.tsx";

// Import wallet adapter CSS
import "@solana/wallet-adapter-react-ui/styles.css";

// Custom CSS
import "./index.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>
);
