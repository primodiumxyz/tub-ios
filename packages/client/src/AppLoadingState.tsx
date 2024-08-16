import { BrowserRouter, Route, Routes } from "react-router-dom";
import { Home } from "./screens/Home";

export default function AppLoadingState() {
  return (
    <BrowserRouter>
      <TubRoutes />
    </BrowserRouter>
  );
}
const TubRoutes = () => {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
    </Routes>
  );
};
