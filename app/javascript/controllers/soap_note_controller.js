import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "input", "btn", "loader", "resultContainer", "emptyState",
    "subjective", "objective", "assessment", "plan", 
    "recordBtn", "recordText", "recordDot", "stopBtn"
  ]

  connect() {
    this.mediaRecorder = null;
    this.audioChunks = [];
    this.isRecording = false;
    this.timerInterval = null;
    this.startTime = null;
  }

  async startRecording() {
    if (this.isRecording) return;
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.mediaRecorder = new MediaRecorder(stream);
      this.audioChunks = [];

      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          this.audioChunks.push(event.data);
        }
      };

      this.mediaRecorder.onstop = async () => {
        let ext = "webm";
        if (this.mediaRecorder.mimeType.includes("mp4")) ext = "m4a";
        else if (this.mediaRecorder.mimeType.includes("ogg")) ext = "ogg";

        const audioBlob = new Blob(this.audioChunks, { type: this.mediaRecorder.mimeType });
        const audioFile = new File([audioBlob], `recording.${ext}`, { type: audioBlob.type });

        this.recordTextTarget.innerText = "Transcribing...";
        this.recordBtnTarget.classList.remove("recording");
        this.inputTarget.disabled = true;
        
        await this.transcribeAudio(audioFile);
        stream.getTracks().forEach(track => track.stop());
      };

      this.mediaRecorder.start();
      this.isRecording = true;
      
      this.recordBtnTarget.classList.add("recording");
      this.recordBtnTarget.disabled = true;
      this.stopBtnTarget.classList.remove("hidden");
      
      this.startTime = Date.now();
      this.updateTimer();
      this.timerInterval = setInterval(() => this.updateTimer(), 1000);
      
    } catch (err) {
      console.error("Error accessing microphone:", err);
      alert("Could not access microphone. Please ensure permissions are granted.");
    }
  }

  updateTimer() {
    const elapsed = Math.floor((Date.now() - this.startTime) / 1000);
    const mins = Math.floor(elapsed / 60);
    const secs = (elapsed % 60).toString().padStart(2, '0');
    this.recordTextTarget.innerText = `Recording · ${mins}:${secs}`;
  }

  stopRecording() {
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop();
      this.isRecording = false;
      clearInterval(this.timerInterval);
      this.stopBtnTarget.classList.add("hidden");
    }
  }

  async transcribeAudio(file) {
    const formData = new FormData();
    formData.append("audio", file);

    try {
      const response = await fetch('/api/transcribe', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: formData
      });

      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Failed to transcribe audio.");

      const existingText = this.inputTarget.value.trim();
      this.inputTarget.value = existingText ? existingText + " " + data.transcript : data.transcript;
    } catch (err) {
      alert("Transcription Error: " + err.message);
    } finally {
      this.recordBtnTarget.disabled = false;
      this.recordTextTarget.innerText = "Ready to record";
      this.inputTarget.disabled = false;
      this.inputTarget.focus();
    }
  }

  async generate() {
    const text = this.inputTarget.value.trim()
    if (!text) return alert("Please enter transcription text first.")

    this.btnTarget.classList.add("loading")
    this.btnTarget.disabled = true
    this.loaderTarget.classList.remove("hidden")
    this.emptyStateTarget.classList.add("hidden")
    this.resultContainerTarget.classList.add("hidden")

    try {
      const response = await fetch('/api/soap_notes', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ transcript: text })
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.error || "Failed to generate note.")

      this.subjectiveTarget.innerText = typeof data.subjective === 'string' ? data.subjective : JSON.stringify(data.subjective)
      this.objectiveTarget.innerText = typeof data.objective === 'string' ? data.objective : JSON.stringify(data.objective)
      this.assessmentTarget.innerText = typeof data.assessment === 'string' ? data.assessment : JSON.stringify(data.assessment)
      this.planTarget.innerText = typeof data.plan === 'string' ? data.plan : JSON.stringify(data.plan)

      this.resultContainerTarget.classList.remove("hidden")
    } catch (err) {
      alert("Error: " + err.message)
      this.emptyStateTarget.classList.remove("hidden")
    } finally {
      this.btnTarget.classList.remove("loading")
      this.btnTarget.disabled = false
      this.loaderTarget.classList.add("hidden")
    }
  }

  download() {
    const subjective = this.subjectiveTarget.innerText || "-";
    const objective = this.objectiveTarget.innerText || "-";
    const assessment = this.assessmentTarget.innerText || "-";
    const plan = this.planTarget.innerText || "-";

    const text = `SOAP Note\nDate: ${new Date().toLocaleDateString()}\n\n` +
                 `SUBJECTIVE (S)\n${subjective}\n\n` +
                 `OBJECTIVE (O)\n${objective}\n\n` +
                 `ASSESSMENT (A)\n${assessment}\n\n` +
                 `PLAN (P)\n${plan}\n`;

    const blob = new Blob([text], { type: "text/plain" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `SOAP_Note_${new Date().toISOString().split('T')[0]}.txt`;
    
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }
}
