# AI Reel Studio 🎬✨
**Production-Ready Story-to-Video and Reel Creation Studio for Android**  
*Built with Flutter, Material 3, Supabase PostgreSQL, SQLite, and FFmpeg.*

---

## 📌 Project Overview
**AI Reel Studio** is an advanced mobile creation suite that empowers creators to turn raw ideas into professional short and long-form video reels through a structured 8-stage workflow:

$$\text{Prompt} \longrightarrow \text{Story} \longrightarrow \text{Scenes} \longrightarrow \text{Images} \longrightarrow \text{Voiceover} \longrightarrow \text{Captions} \longrightarrow \text{Video Editing} \longrightarrow \text{MP4 Export}$$

---

## 🛠️ Technology Stack
- **Framework**: Flutter & Dart (Material 3 Dark/Light Theme)
- **Backend & Cloud Database**: Supabase PostgreSQL (11 tables with Row Level Security)
- **Authentication**: Supabase Auth (Email/Password & Offline Guest Mode)
- **Cloud Storage**: Supabase Storage (`reel-images`, `reel-audio`, `reel-videos`, `character-refs`)
- **Local Database**: SQLite (`sqflite`) for full offline resilience and caching
- **Video Rendering Engine**: Multi-Track FFmpeg pipeline (H.264 / AAC MP4)
- **Audio & Speech**: `record` microphone capture, `audioplayers`, and native offline TTS (`flutter_tts`)
- **Subtitles**: Full SRT import/export engine (`SrtParser`) with animated burn-in
- **Build Pipeline**: GitHub Actions automated CI/CD for Android Release APK

---

## 🌟 Strict Zero-Paid-API Compliance
1. **No Paid Dependencies**: Zero requirement for OpenAI API, paid video generators, or commercial voice subscriptions.
2. **Built-in Prompt Engineering Engine**: Formats hyper-detailed visual prompts with lighting, camera angles, aspect ratio tags (`--ar 9:16`, `--ar 16:9`), and negative prompts for one-click copy to ChatGPT, Midjourney, and Stable Diffusion.
3. **Local Story Synthesis**: Built-in multi-lingual story engine generating scene breakdowns, narration scripts, and character consistency descriptions in **English, Hindi (हिंदी), and Gujarati (ગુજરાતી)**.
4. **On-Device Rendering**: Video encoding, scaling, audio mixing, and subtitle burn-in run locally via the FFmpeg engine.

---

## 📱 Complete 23 Screens Inventory
| # | Screen | Description | File Path |
|---|---|---|---|
| 1 | **Splash Screen** | Animated gradient badge, system initialization | `lib/features/navigation/splash_screen.dart` |
| 2 | **Onboarding Screen** | 4-step creative walkthrough carousel | `lib/features/navigation/onboarding_screen.dart` |
| 3 | **Home Dashboard** | Hero creation card, workflow grid, recent projects | `lib/features/dashboard/screens/home_dashboard_screen.dart` |
| 4 | **Create New Project** | Title, aspect ratio (9:16, 16:9, 1:1), style picker | `lib/features/projects/screens/create_new_project_screen.dart` |
| 5 | **Story Prompt Screen** | Multi-lingual prompts, sample templates, ChatGPT copy | `lib/features/stories/screens/story_prompt_screen.dart` |
| 6 | **Story Editor** | Edit story title, synopsis, character cards, BGM | `lib/features/stories/screens/story_editor_screen.dart` |
| 7 | **Video Duration Screen** | 5s to 10m presets with automatic scene calculation | `lib/features/projects/screens/video_duration_screen.dart` |
| 8 | **Scene Manager** | Ordered list of scenes, duration, voiceover/image status | `lib/features/scenes/screens/scene_manager_screen.dart` |
| 9 | **Scene Prompt Editor** | Camera angles, lighting atmosphere, visual prompt tags | `lib/features/scenes/screens/scene_prompt_editor_screen.dart` |
| 10 | **Image Upload & Assets** | Pick from gallery/camera, attach to scenes, 9:16 preview | `lib/features/images/screens/image_upload_screen.dart` |
| 11 | **Character Reference Manager** | Visual consistency, outfit tags, reference photos | `lib/features/characters/screens/character_reference_screen.dart` |
| 12 | **Voiceover Studio** | Mic recording, audio upload, free native TTS preview | `lib/features/voiceover/screens/voiceover_studio_screen.dart` |
| 13 | **Subtitle Editor** | SRT import/export, timing, animated font styling | `lib/features/captions/screens/subtitle_editor_screen.dart` |
| 14 | **Music Library** | Royalty-free cinematic music presets, custom BGM | `lib/features/editor/screens/music_library_screen.dart` |
| 15 | **Video Timeline Editor** | Multi-track timeline (Video, Assets, VO, BGM, Captions) | `lib/features/editor/screens/video_timeline_editor_screen.dart` |
| 16 | **Effects & Transitions** | Fade, Crossfade, Slide Left/Right, Zoom In/Out | `lib/features/editor/screens/effects_transitions_screen.dart` |
| 17 | **Video Preview** | Fullscreen synchronized player with subtitles & VO | `lib/features/editor/screens/video_preview_screen.dart` |
| 18 | **Export Settings** | 720p/1080p, 24/30/60 FPS, social presets (Reels/Shorts) | `lib/features/export/screens/export_settings_screen.dart` |
| 19 | **Export Progress** | Real-time progress bar (0-100%), cancel, recovery | `lib/features/export/screens/export_progress_screen.dart` |
| 20 | **My Projects** | Search, filter by status, delete, open in timeline | `lib/features/projects/screens/my_projects_screen.dart` |
| 21 | **Project History** | Rendered video exports list with size, date & share | `lib/features/projects/screens/project_history_screen.dart` |
| 22 | **Social Media Share** | Android Share Sheet (Instagram, WhatsApp, YouTube) | `lib/features/sharing/screens/social_media_share_screen.dart` |
| 23 | **Settings & Storage** | MB used, clear cache, Supabase auth status | `lib/features/settings/screens/settings_storage_screen.dart` |

*Plus Authentication Screens:*
- **Login Screen**: `lib/features/auth/screens/login_screen.dart`
- **Register Screen**: `lib/features/auth/screens/register_screen.dart`

---

## 🗄️ Database Schema & RLS Setup
Run `supabase_schema.sql` in your Supabase SQL Editor to establish:
1. `profiles`: Creator profiles with language preference.
2. `projects`: Video projects with aspect ratio, resolution, duration, and status.
3. `stories`: Prompts, synopses, and genres.
4. `characters`: Character consistency anchors, visual prompts, and outfits.
5. `scenes`: Scene order, duration, transitions, camera angles, and lighting.
6. `scene_assets`: Visual images and graphics tied to scenes.
7. `voiceovers`: Audio recordings, upload paths, and volumes.
8. `captions`: Subtitle timecodes, font families, and animation styles.
9. `audio_tracks`: Background music and sound effect tracks.
10. `video_exports`: Rendered MP4 files, resolutions, and file sizes.
11. `social_accounts`: Future social platform connection tokens.

*Row Level Security (RLS) is enabled across all 11 tables with strict `auth.uid() = owner_id` enforcement.*

---

## 🚀 Building the Release APK
Push to GitHub to trigger `.github/workflows/build_apk.yml`:
```bash
git add .
git commit -m "feat: complete AI Reel Studio v1.0.0"
git push origin main
```
The workflow will compile the release APK and provide it in the GitHub Actions Artifacts tab for instant download and installation on any Android device!
