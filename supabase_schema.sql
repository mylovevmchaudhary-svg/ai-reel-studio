-- =========================================================================
-- AI REEL STUDIO - COMPLETE SUPABASE POSTGRESQL DATABASE SCHEMA & POLICIES
-- =========================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Function to handle updated_at timestamps automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------------------
-- 1. PROFILES TABLE
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    preferred_language VARCHAR(10) DEFAULT 'en',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_profiles_modtime
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name, preferred_language)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
        'en'
    ) ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- -------------------------------------------------------------------------
-- 2. PROJECTS TABLE
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT 'Untitled Project',
    description TEXT,
    aspect_ratio VARCHAR(10) NOT NULL DEFAULT '9:16', -- '9:16', '16:9', '1:1'
    target_duration_seconds INTEGER NOT NULL DEFAULT 15,
    fps INTEGER NOT NULL DEFAULT 30,
    resolution VARCHAR(10) NOT NULL DEFAULT '1080p', -- '720p', '1080p'
    status VARCHAR(20) NOT NULL DEFAULT 'draft', -- 'draft', 'generating', 'editing', 'exported'
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_projects_owner ON public.projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_updated_at ON public.projects(updated_at DESC);

CREATE TRIGGER update_projects_modtime
    BEFORE UPDATE ON public.projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------------------
-- 3. STORIES TABLE
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    prompt_text TEXT NOT NULL,
    prompt_language VARCHAR(10) NOT NULL DEFAULT 'en', -- 'en', 'hi', 'gu'
    story_title TEXT NOT NULL,
    synopsis TEXT,
    genre VARCHAR(50) DEFAULT 'Cinematic',
    tone VARCHAR(50) DEFAULT 'Engaging',
    raw_response JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stories_project ON public.stories(project_id);
CREATE INDEX IF NOT EXISTS idx_stories_owner ON public.stories(owner_id);

CREATE TRIGGER update_stories_modtime
    BEFORE UPDATE ON public.stories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------------------
-- 4. CHARACTERS TABLE
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.characters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    role TEXT,
    visual_description TEXT NOT NULL,
    outfit TEXT,
    reference_image_url TEXT,
    voice_persona TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_characters_project ON public.characters(project_id);
CREATE INDEX IF NOT EXISTS idx_characters_owner ON public.characters(owner_id);

CREATE TRIGGER update_characters_modtime
    BEFORE UPDATE ON public.characters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------------------
-- 5. SCENES TABLE
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.scenes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    scene_index INTEGER NOT NULL,
    title TEXT,
    narration TEXT,
    dialogue TEXT,
    visual_prompt TEXT NOT NULL,
    negative_prompt TEXT,
    camera_angle VARCHAR(50) DEFAULT 'Cinematic Medium Shot',
    lighting VARCHAR(50) DEFAULT 'Golden Hour Dramatic',
    duration_seconds NUMERIC(5,2) NOT NULL DEFAULT 5.0,
    transition_type VARCHAR(30) DEFAULT 'fade', -- 'none', 'fade', 'crossfade', 'slide_left', 'slide_right', 'zoom_in', 'zoom_out'
    transition_duration NUMERIC(4,2) DEFAULT 0.5,
    status VARCHAR(20) DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scenes_project ON public.scenes(project_id);
CREATE INDEX IF NOT EXISTS idx_scenes_owner ON public.scenes(owner_id);
CREATE INDEX IF NOT EXISTS idx_scenes_index ON public.scenes(project_id, scene_index ASC);

CREATE TRIGGER update_scenes_modtime
    BEFORE UPDATE ON public.scenes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------------------
-- 6. SCENE ASSETS TABLE (Images/Graphics for each scene)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.scene_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scene_id UUID NOT NULL REFERENCES public.scenes(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    asset_type VARCHAR(30) NOT NULL DEFAULT 'image', -- 'image', 'video', 'generated_image'
    asset_url TEXT NOT NULL,
    local_path TEXT,
    aspect_ratio VARCHAR(10) DEFAULT '9:16',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scene_assets_scene ON public.scene_assets(scene_id);
CREATE INDEX IF NOT EXISTS idx_scene_assets_project ON public.scene_assets(project_id);
CREATE INDEX IF NOT EXISTS idx_scene_assets_owner ON public.scene_assets(owner_id);

-- -------------------------------------------------------------------------
-- 7. VOICEOVERS TABLE (Audio tracks attached to scenes)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.voiceovers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scene_id UUID NOT NULL REFERENCES public.scenes(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    audio_url TEXT,
    local_path TEXT,
    duration_seconds NUMERIC(6,2) DEFAULT 5.0,
    source_type VARCHAR(20) NOT NULL DEFAULT 'recorded', -- 'recorded', 'uploaded', 'tts'
    voice_id TEXT,
    language VARCHAR(10) DEFAULT 'en', -- 'en', 'hi', 'gu'
    volume NUMERIC(4,2) DEFAULT 1.0,
    fade_in_ms INTEGER DEFAULT 100,
    fade_out_ms INTEGER DEFAULT 100,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_voiceovers_scene ON public.voiceovers(scene_id);
CREATE INDEX IF NOT EXISTS idx_voiceovers_project ON public.voiceovers(project_id);

CREATE TRIGGER update_voiceovers_modtime
    BEFORE UPDATE ON public.voiceovers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------------------
-- 8. CAPTIONS TABLE (Subtitles & Text Overlays)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.captions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    scene_id UUID REFERENCES public.scenes(id) ON DELETE SET NULL,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    start_time_ms INTEGER NOT NULL DEFAULT 0,
    end_time_ms INTEGER NOT NULL DEFAULT 5000,
    text TEXT NOT NULL,
    font_family VARCHAR(50) DEFAULT 'Roboto',
    font_size INTEGER DEFAULT 24,
    text_color VARCHAR(10) DEFAULT '#FFFFFF',
    background_color VARCHAR(10) DEFAULT '#00000088',
    animation_type VARCHAR(30) DEFAULT 'pop', -- 'none', 'pop', 'fade', 'typewriter', 'word_by_word'
    position VARCHAR(20) DEFAULT 'bottom', -- 'top', 'center', 'bottom'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_captions_project ON public.captions(project_id);
CREATE INDEX IF NOT EXISTS idx_captions_time ON public.captions(project_id, start_time_ms ASC);

CREATE TRIGGER update_captions_modtime
    BEFORE UPDATE ON public.captions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------------------
-- 9. AUDIO TRACKS TABLE (Background Music & Sound Effects)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.audio_tracks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    track_type VARCHAR(20) NOT NULL DEFAULT 'bgm', -- 'bgm', 'sfx'
    audio_url TEXT,
    local_path TEXT,
    duration_seconds NUMERIC(6,2) DEFAULT 30.0,
    volume NUMERIC(4,2) DEFAULT 0.35, -- lower than voiceover by default
    loop BOOLEAN DEFAULT true,
    fade_in_ms INTEGER DEFAULT 500,
    fade_out_ms INTEGER DEFAULT 1000,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audio_tracks_project ON public.audio_tracks(project_id);

CREATE TRIGGER update_audio_tracks_modtime
    BEFORE UPDATE ON public.audio_tracks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------------------------------------
-- 10. VIDEO EXPORTS TABLE (Rendered Final MP4 records)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.video_exports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    export_url TEXT,
    local_path TEXT,
    resolution VARCHAR(10) NOT NULL DEFAULT '1080p',
    fps INTEGER NOT NULL DEFAULT 30,
    aspect_ratio VARCHAR(10) NOT NULL DEFAULT '9:16',
    duration_seconds NUMERIC(6,2),
    file_size_bytes BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'completed', -- 'processing', 'completed', 'failed'
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_video_exports_project ON public.video_exports(project_id);
CREATE INDEX IF NOT EXISTS idx_video_exports_owner ON public.video_exports(owner_id);

-- -------------------------------------------------------------------------
-- 11. SOCIAL ACCOUNTS TABLE (For social media presets and accounts)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.social_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    platform VARCHAR(30) NOT NULL, -- 'youtube', 'instagram', 'facebook', 'tiktok'
    account_name TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'connected',
    connected_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_social_accounts_owner ON public.social_accounts(owner_id);

-- =========================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =========================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scenes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scene_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voiceovers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.captions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audio_tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_exports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_accounts ENABLE ROW LEVEL SECURITY;

-- 1. Profiles Policies
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- 2. Projects Policies
CREATE POLICY "Users can view own projects"
    ON public.projects FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can create own projects"
    ON public.projects FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own projects"
    ON public.projects FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own projects"
    ON public.projects FOR DELETE
    USING (auth.uid() = owner_id);

-- 3. Stories Policies
CREATE POLICY "Users can view own stories"
    ON public.stories FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can create own stories"
    ON public.stories FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own stories"
    ON public.stories FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own stories"
    ON public.stories FOR DELETE
    USING (auth.uid() = owner_id);

-- 4. Characters Policies
CREATE POLICY "Users can view own characters"
    ON public.characters FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can create own characters"
    ON public.characters FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own characters"
    ON public.characters FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own characters"
    ON public.characters FOR DELETE
    USING (auth.uid() = owner_id);

-- 5. Scenes Policies
CREATE POLICY "Users can view own scenes"
    ON public.scenes FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can create own scenes"
    ON public.scenes FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own scenes"
    ON public.scenes FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own scenes"
    ON public.scenes FOR DELETE
    USING (auth.uid() = owner_id);

-- 6. Scene Assets Policies
CREATE POLICY "Users can view own scene assets"
    ON public.scene_assets FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can create own scene assets"
    ON public.scene_assets FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own scene assets"
    ON public.scene_assets FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own scene assets"
    ON public.scene_assets FOR DELETE
    USING (auth.uid() = owner_id);

-- 7. Voiceovers Policies
CREATE POLICY "Users can view own voiceovers"
    ON public.voiceovers FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can create own voiceovers"
    ON public.voiceovers FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own voiceovers"
    ON public.voiceovers FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own voiceovers"
    ON public.voiceovers FOR DELETE
    USING (auth.uid() = owner_id);

-- 8. Captions Policies
CREATE POLICY "Users can view own captions"
    ON public.captions FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can create own captions"
    ON public.captions FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own captions"
    ON public.captions FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own captions"
    ON public.captions FOR DELETE
    USING (auth.uid() = owner_id);

-- 9. Audio Tracks Policies
CREATE POLICY "Users can view own audio tracks"
    ON public.audio_tracks FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can create own audio tracks"
    ON public.audio_tracks FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own audio tracks"
    ON public.audio_tracks FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own audio tracks"
    ON public.audio_tracks FOR DELETE
    USING (auth.uid() = owner_id);

-- 10. Video Exports Policies
CREATE POLICY "Users can view own video exports"
    ON public.video_exports FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can create own video exports"
    ON public.video_exports FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own video exports"
    ON public.video_exports FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own video exports"
    ON public.video_exports FOR DELETE
    USING (auth.uid() = owner_id);

-- 11. Social Accounts Policies
CREATE POLICY "Users can view own social accounts"
    ON public.social_accounts FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can create own social accounts"
    ON public.social_accounts FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own social accounts"
    ON public.social_accounts FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own social accounts"
    ON public.social_accounts FOR DELETE
    USING (auth.uid() = owner_id);

-- =========================================================================
-- SUPABASE STORAGE BUCKETS SETUP & SECURITY POLICIES
-- =========================================================================

-- Insert Storage Buckets (if storage schema exists)
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('reel-images', 'reel-images', false),
    ('reel-audio', 'reel-audio', false),
    ('reel-videos', 'reel-videos', false),
    ('character-refs', 'character-refs', false)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies
CREATE POLICY "Authenticated users can upload reel-images"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'reel-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can read own reel-images"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'reel-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Authenticated users can upload reel-audio"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'reel-audio' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can read own reel-audio"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'reel-audio' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Authenticated users can upload reel-videos"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'reel-videos' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can read own reel-videos"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'reel-videos' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Authenticated users can upload character-refs"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'character-refs' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can read own character-refs"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'character-refs' AND auth.uid()::text = (storage.foldername(name))[1]);
