import { useEffect, useState } from "react";

type WindowDimensions = {
  width: number;
  height: number;
};

/**
 * Hook to get the current window dimensions
 *
 * @returns The current {@link WindowDimensions}
 */
export function useWindowDimensions(): WindowDimensions {
  const [width, setWidth] = useState(window.innerWidth);
  const [height, setHeight] = useState(window.innerHeight);

  useEffect(() => {
    const handleResize = () => {
      setWidth(window.innerWidth);
      setHeight(window.innerHeight);
    };

    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  return { width, height };
}
