import { useEffect, useRef, useState } from "react";
import { AudioRecorder, newRunId } from "./recorder";
import { uploadAndRegister } from "./persist";
import { supabase } from "../../lib/supabaseClient";

export default function RecorderWidget({
  onReadyForSummary,
}: {
  onReadyForSummary: (runId: string) => void;
}) {
  const recRef = useRef(new AudioRecorder());
  const [state, setState] = useState<"idle" | "recording" | "stopping">("idle");
  const [err, setErr] = useState<string | null>(null);
  const [timer, setTimer] = useState(0);
  const timerRef = useRef<number | null>(null);

  useEffect(() => {
    return () => {
      if (timerRef.current) window.clearInterval(timerRef.current);
    };
  }, []);

  const startTimer = () => {
    setTimer(0);
    timerRef.current = window.setInterval(() => setTimer((t) => t + 1), 1000);
  };

  const stopTimer = () => {
    if (timerRef.current) {
      window.clearInterval(timerRef.current);
      timerRef.current = null;
    }
  };

  async function getUserId(): Promise<string> {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error) throw error;
    if (!user?.id) throw new Error("Not authenticated");
    return user.id;
  }

  async function handleStart() {
    setErr(null);
    try {
      if (!recRef.current.supported) throw new Error("Recording not supported in this browser");
      await recRef.current.start();
      setState("recording");
      startTimer();
    } catch (e: any) {
      setErr(e?.message ?? "Failed to start recording");
      setState("idle");
    }
  }

  async function handleStop() {
    setState("stopping");
    stopTimer();
    try {
      const { blob, durationMs, fileExt } = await recRef.current.stop();
      const runId = newRunId();
      const userId = await getUserId();

      await uploadAndRegister({ userId, runId, blob, fileExt, durationMs });

      onReadyForSummary(runId);
      setState("idle");
    } catch (e: any) {
      setErr(e?.message ?? "Failed to stop/save");
      setState("idle");
    }
  }

  return (
    <div className="p-4 rounded-2xl bg-gray-50 border">
      <div className="text-sm text-gray-600 mb-2">Status: {state}</div>
      <div className="text-2xl font-semibold tabular-nums mb-4">{timer}s</div>

      {state !== "recording" ? (
        <button onClick={handleStart} className="px-4 py-2 rounded-xl bg-black text-white">
          Record
        </button>
      ) : (
        <button onClick={handleStop} className="px-4 py-2 rounded-xl bg-red-600 text-white">
          Stop
        </button>
      )}

      {err && <div className="mt-3 text-red-600 text-sm">{err}</div>}
    </div>
  );
}
