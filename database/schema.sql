-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE,
    campus_id TEXT NOT NULL CHECK (campus_id IN ('seoul', 'daejeon', 'gwangju', 'gumi', 'busan')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create menus table
CREATE TABLE IF NOT EXISTS menus (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    campus_id TEXT NOT NULL CHECK (campus_id IN ('seoul', 'daejeon', 'gwangju', 'gumi', 'busan')),
    items_a TEXT[] DEFAULT '{}',
    items_b TEXT[] DEFAULT '{}',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by TEXT, -- 사용자 이메일 또는 이름 (선택사항)
    
    -- Composite unique constraint for date + campus (하나의 캠퍼스에 하루에 하나의 메뉴만)
    UNIQUE(date, campus_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_menus_date_campus ON menus(date, campus_id);
CREATE INDEX IF NOT EXISTS idx_menus_campus_date ON menus(campus_id, date);
CREATE INDEX IF NOT EXISTS idx_users_campus ON users(campus_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_menus_updated_at BEFORE UPDATE ON menus
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE menus ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Create policies for menus table (누구나 읽기/쓰기 가능)
CREATE POLICY "Anyone can view menus" ON menus
    FOR SELECT USING (true);

CREATE POLICY "Anyone can insert menus" ON menus
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can update menus" ON menus
    FOR UPDATE USING (true);

-- Create function to get menu for a date and campus (덮어씌우기 구조)
CREATE OR REPLACE FUNCTION get_menu_for_date_campus(p_date DATE, p_campus_id TEXT)
RETURNS TABLE (
    id UUID,
    date DATE,
    campus_id TEXT,
    items_a TEXT[],
    items_b TEXT[],
    updated_at TIMESTAMP WITH TIME ZONE,
    updated_by TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT m.id, m.date, m.campus_id, m.items_a, m.items_b, m.updated_at, m.updated_by
    FROM menus m
    WHERE m.date = p_date AND m.campus_id = p_campus_id;
END;
$$ LANGUAGE plpgsql;

-- Insert sample data for testing (optional)
-- INSERT INTO users (email, campus_id) VALUES ('test@example.com', 'seoul');
-- INSERT INTO menus (date, campus_id, items_a, items_b, updated_by) 
-- VALUES ('2024-01-01', 'seoul', ARRAY['백미밥', '미역국', '제육볶음'], ARRAY['잡곡밥', '된장국', '닭볶음'], 'test@example.com');
