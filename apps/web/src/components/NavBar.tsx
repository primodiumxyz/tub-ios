import { useCallback } from "react";
import { Link, useLocation } from "react-router-dom";

export const NavBar = () => {
  const { pathname } = useLocation();
  console.log({pathname});
  const active = useCallback((path: string) => {
    console.log({ pathname, path });
    return pathname === path}, [pathname]);

  return (
    <nav className="bg-slate-300 p-4 rounded-xl shadow-md mb-4">
      <ul className="flex space-x-4">
        <li>
          <Link
            to="/counter"
            className={`text-gray-800 font-medium hover:text-blue-400 transition-colors ${
              active("/") ? "!text-blue-600" : ""
            }`}
          >
            Counter
          </Link>
        </li>
        <li>
          <Link
            to="/"
            className={`text-gray-800 font-medium hover:text-blue-400 transition-colors ${
              active("/") ? "!text-blue-600" : ""
            }`}
          >
            Coins
          </Link>
        </li>
      </ul>
    </nav>
  );
};