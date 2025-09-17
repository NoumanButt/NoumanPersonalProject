# AI → YouTube Workflow (Free & Open-Source Guide)

This file captures our conversation about automating YouTube video creation using 100% free and open-source tools.

---

## ✅ Key Takeaways
- **Yes, it’s possible** to automate large parts of a YouTube workflow with AI + open tools.
- **But**: You must stay within YouTube’s rules—especially AI disclosure & anti-spam policies.
- **Goal**: Original, creative videos that add value. Avoid “detected/undetected” thinking.

---

## 📌 Step-by-Step Pipeline

### 1. Write the story & script
- Tools: **LM Studio, Ollama, GPT4All, KoboldAI, text-generation-webui**.
- Notes: Organize beats with **Obsidian/Joplin**.

### 2. Turn script into voice
- Tools: **Piper, Coqui-TTS, Mimic3, MaryTTS** (local TTS).  
- Optional: RVC/so-vits-svc for voice conversion (ethical use only).

### 3. Generate visuals
- **Images**: Stable Diffusion (**ComfyUI, Automatic1111, InvokeAI**) + **ControlNet/LoRA**.  
- **Videos**: AnimateDiff, Deforum, Stable Video Diffusion, ModelScope T2V, Open-Sora.  
- **Talking avatars**: SadTalker, LivePortrait, Wav2Lip.  
- **Enhancements**: Real-ESRGAN, Upscayl, RIFE, GFPGAN, CodeFormer.

### 4. Edit & assemble
- Editors: **Blender (VSE), Kdenlive, Shotcut, OpenShot, Olive**.  
- Compositing: **Natron**.  
- Music/SFX: **YouTube Audio Library, Free Music Archive, ccMixter, Freesound**.

### 5. Captions & accessibility
- Transcribe with **Whisper/Faster-Whisper/WhisperX**.  
- Edit with **Aegisub, Subtitle Edit**.  
- Burn-in with **ffmpeg**.

### 6. Thumbnails & metadata
- Tools: **GIMP, Krita, Photopea, Canva (Free)**.

### 7. Upload & automation
- Use **youtube-upload (Python)** or **YouTube Data API samples**.  
- Respect daily quotas (10k units/day; 1 upload ~1600 units).

### 8. Compliance checklist
- **Disclose AI-generated content** if realistic.  
- **Don’t spam** with repetitive or low-effort uploads.  
- **Always** add value and originality.

---

## 🎒 Starter Stacks

### Faceless explainer
- Script: LM Studio  
- Voice: Piper  
- Visuals: Stock + ComfyUI images  
- Editing: Kdenlive  
- Captions: Whisper  
- Upload: youtube-upload

### Animated story
- Script: GPT4All  
- Voice: Mimic3  
- Visuals: AnimateDiff/SD  
- Editing: Blender/Natron  
- Captions: WhisperX

### Talking-head avatar
- Script: Obsidian notes  
- Voice: Coqui-TTS  
- Avatar: SadTalker  
- Editing: Kdenlive  
- Captions: Whisper

---

## 📂 Tool Collection
A curated list of **100% free & open tools** for every stage (writing → voice → visuals → editing → captions → upload).  
👉 [Download CSV here](sandbox:/mnt/data/ai_youtube_free_tools.csv)

---

## ⚠️ Policy Notes
- **AI disclosure is mandatory** for realistic AI/altered content.  
- **Spam/inauthentic content** (mass uploads, repetitive scripts) is not allowed.  
- Automation via API is fine, but respect quotas and policies.

---

## 📌 Next Steps
When you want to dive deeper into a step (e.g., TTS, editing, thumbnails), just reference this file and we can expand with commands, workflows, or ComfyUI node graphs.
