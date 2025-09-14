import { supabase } from "../../lib/supabaseClient";

type PersistArgs = {
  userId: string;
  runId: string;
  blob: Blob;
  fileExt: string;
  durationMs: number;
};

export async function uploadAndRegister({
  userId,
  runId,
  blob,
  fileExt,
  durationMs,
}: PersistArgs) {
  const fileName = `${runId}.${fileExt}`;
  const storagePath = `user/${userId}/${fileName}`;

  const { error: upErr } = await supabase.storage
    .from("audio")
    .upload(storagePath, blob, {
      contentType: blob.type || "application/octet-stream",
      upsert: false,
    });
  if (upErr) throw upErr;

  const { error: dbErr } = await supabase.from("recordings").insert({
    user_id: userId,
    run_id: runId,
    storage_path: storagePath,
    duration_ms: durationMs,
    status: "uploaded",
  });
  if (dbErr) throw dbErr;

  return { storagePath, fileName };
}
