--
-- Profiles Table
-- Stores public user information.
--
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE,
    referral_code TEXT UNIQUE,
    referral_count INTEGER DEFAULT 0 NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    role TEXT
);
COMMENT ON TABLE public.profiles IS 'Public profile information for each user.';

--
-- Products Table
-- Stores the products listed for sale.
--
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    price NUMERIC NOT NULL,
    image_url TEXT NOT NULL,
    description TEXT,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    category TEXT,
    view_count INTEGER DEFAULT 0,
    message_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
COMMENT ON TABLE public.products IS 'Products listed for sale by users.';

--
-- Managed Ads Table
-- Stores advertisements managed by the application administrators.
--
CREATE TABLE public.managed_ads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    image_url TEXT NOT NULL,
    target_url TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
COMMENT ON TABLE public.managed_ads IS 'Managed advertisements displayed in the app.';

--
-- Chat Rooms Table
-- Defines a chat room between two users.
--
CREATE TABLE public.chat_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participant1_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    participant2_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE (participant1_id, participant2_id)
);
COMMENT ON TABLE public.chat_rooms IS 'A chat room between two participants.';

--
-- Messages Table
-- Stores messages sent within a chat room.
--
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
COMMENT ON TABLE public.messages IS 'Messages within a chat room.';
