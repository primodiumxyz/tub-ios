import { useContext } from "react";
import { Tub, TubContext } from "../providers/TubProvider";

/**
 * Provides access to the CoreContext.
 * Throws an error if used outside of a Core Provider.
 * @returns The value from the CoreContext.
 * @throws {Error} If used outside of a Core Provider.
 */
export const useTub = (): Tub => {
  const value = useContext(TubContext);
  if (!value) throw new Error("Must be used within a Tub Provider");
  return value;
};
