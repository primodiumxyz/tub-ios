import CounterState from "./CounterState";
import IncrementButton from "./IncrementButton";

export default function IncrementForm() {
  return (
    <div className="w-[350px] shadow-md flex flex-row justify-center gap-10 items-center bg-slate-300 rounded-xl p-2">
      <IncrementButton />
      <CounterState />
    </div>
  );
}
