import { v4 as uuidv4 } from "uuid";

export type RecordingState = "idle" | "recording" | "stopping";

export class AudioRecorder {
  private mediaRecorder?: MediaRecorder;
  private chunks: BlobPart[] = [];
  private startedAt = 0;
  private mimeType: string = "audio/webm";

  get supported(): boolean {
    if (!navigator.mediaDevices?.getUserMedia) return false;
    if (MediaRecorder && MediaRecorder.isTypeSupported("audio/webm")) {
      this.mimeType = "audio/webm";
      return true;
    }
    if (MediaRecorder && MediaRecorder.isTypeSupported("audio/mp4")) {
      this.mimeType = "audio/mp4";
      return true;
    }
    return !!MediaRecorder;
  }

  async start(): Promise<void> {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    this.chunks = [];
    this.mediaRecorder = new MediaRecorder(stream, { mimeType: this.mimeType });
    this.mediaRecorder.ondataavailable = (e) => {
      if (e.data && e.data.size > 0) this.chunks.push(e.data);
    };
    this.mediaRecorder.start(1000);
    this.startedAt = Date.now();
  }

  async stop(): Promise<{ blob: Blob; durationMs: number; fileExt: string }> {
    return new Promise((resolve, reject) => {
      if (!this.mediaRecorder) return reject(new Error("No recorder"));
      const mr = this.mediaRecorder;
      const tracks = mr.stream.getTracks();

      mr.onstop = () => {
        tracks.forEach((t) => t.stop());
        const durationMs = Math.max(0, Date.now() - this.startedAt);
        const type = mr.mimeType || "audio/webm";
        const fileExt = type.includes("mp4") ? "m4a" : "webm";
        const blob = new Blob(this.chunks, { type });
        resolve({ blob, durationMs, fileExt });
      };

      try {
        mr.stop();
      } catch (e) {
        reject(e);
      }
    });
  }
}

export function newRunId(): string {
  return uuidv4();
}
