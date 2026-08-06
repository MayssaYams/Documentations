-- =====================================================
-- 06_messages.sql
-- Tables conversations, messages, participants et analytics
-- =====================================================

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: conversations (conversations entre utilisateurs)
-- =====================================================

CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_type VARCHAR(20) DEFAULT 'direct', -- 'direct', 'group', 'support'
    title VARCHAR(255), -- Titre pour les conversations de groupe
    description TEXT, -- Description pour les conversations de groupe
    is_active BOOLEAN DEFAULT TRUE,
    is_archived BOOLEAN DEFAULT FALSE,
    last_message_at TIMESTAMP WITH TIME ZONE,
    last_message_id UUID, -- Référence vers le dernier message
    created_by INTEGER REFERENCES accounts_user(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE conversations IS 'Conversations entre utilisateurs (direct, groupe, support)';
COMMENT ON COLUMN conversations.conversation_type IS 'Type de conversation (direct, group, support)';
COMMENT ON COLUMN conversations.last_message_at IS 'Timestamp du dernier message pour tri';

-- =====================================================
-- TABLE: conversation_participants (participants aux conversations)
-- =====================================================

CREATE TABLE IF NOT EXISTS conversation_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member', -- 'admin', 'member', 'moderator'
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    left_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    last_read_at TIMESTAMP WITH TIME ZONE,
    unread_count INTEGER DEFAULT 0,
    notification_preferences JSONB, -- Préférences de notification
    metadata JSONB,
    
    UNIQUE(conversation_id, user_id)
);

COMMENT ON TABLE conversation_participants IS 'Participants aux conversations avec rôles et préférences';
COMMENT ON COLUMN conversation_participants.role IS 'Rôle dans la conversation (admin, member, moderator)';
COMMENT ON COLUMN conversation_participants.unread_count IS 'Nombre de messages non lus';

-- =====================================================
-- TABLE: messages (messages dans les conversations)
-- =====================================================

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    message_type VARCHAR(20) DEFAULT 'text', -- 'text', 'image', 'file', 'system', 'order'
    content TEXT NOT NULL,
    content_metadata JSONB, -- Métadonnées du contenu (URLs, dimensions, etc.)
    reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL, -- Message auquel on répond
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by INTEGER REFERENCES accounts_user(id) ON DELETE SET NULL,
    delivery_status VARCHAR(20) DEFAULT 'sent', -- 'sent', 'delivered', 'read'
    read_by JSONB, -- {user_id: timestamp} des utilisateurs qui ont lu
    metadata JSONB, -- Métadonnées supplémentaires
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE messages IS 'Messages dans les conversations avec statuts et métadonnées';
COMMENT ON COLUMN messages.message_type IS 'Type de message (text, image, file, system, order)';
COMMENT ON COLUMN messages.read_by IS 'JSON des utilisateurs qui ont lu le message avec timestamps';

-- =====================================================
-- TABLE: message_attachments (pièces jointes des messages)
-- =====================================================

CREATE TABLE IF NOT EXISTS message_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    file_type VARCHAR(100), -- MIME type
    file_size_bytes BIGINT,
    thumbnail_url VARCHAR(500), -- URL de la miniature pour les images
    metadata JSONB, -- Dimensions, durée, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE message_attachments IS 'Pièces jointes des messages (images, fichiers)';
COMMENT ON COLUMN message_attachments.thumbnail_url IS 'URL de la miniature pour les images';

-- =====================================================
-- TABLE: message_reactions (réactions aux messages)
-- =====================================================

CREATE TABLE IF NOT EXISTS message_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    reaction_type VARCHAR(20) NOT NULL, -- 'like', 'love', 'laugh', 'angry', 'sad', 'wow'
    emoji VARCHAR(10), -- Emoji utilisé
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(message_id, user_id, reaction_type)
);

COMMENT ON TABLE message_reactions IS 'Réactions des utilisateurs aux messages';
COMMENT ON COLUMN message_reactions.reaction_type IS 'Type de réaction (like, love, laugh, angry, sad, wow)';

-- =====================================================
-- TABLE: message_analytics_daily (analytics quotidiennes des messages)
-- =====================================================

CREATE TABLE IF NOT EXISTS message_analytics_daily (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    -- Métriques d'envoi
    messages_sent INTEGER DEFAULT 0,
    messages_received INTEGER DEFAULT 0,
    conversations_started INTEGER DEFAULT 0,
    conversations_joined INTEGER DEFAULT 0,
    -- Métriques d'engagement
    messages_read INTEGER DEFAULT 0,
    reactions_given INTEGER DEFAULT 0,
    reactions_received INTEGER DEFAULT 0,
    attachments_sent INTEGER DEFAULT 0,
    -- Métriques de performance
    average_response_time_minutes DECIMAL(8,2) DEFAULT 0,
    response_rate DECIMAL(5,2) DEFAULT 0, -- % de messages auxquels l'utilisateur répond
    -- Métadonnées
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, date)
);

COMMENT ON TABLE message_analytics_daily IS 'Analytics quotidiennes des messages par utilisateur';
COMMENT ON COLUMN message_analytics_daily.response_rate IS 'Pourcentage de messages auxquels l utilisateur répond';

-- =====================================================
-- TABLE: conversation_templates (modèles de messages)
-- =====================================================

CREATE TABLE IF NOT EXISTS conversation_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_type VARCHAR(50) NOT NULL, -- 'greeting', 'order_inquiry', 'delivery_info', 'support'
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    variables JSONB, -- Variables disponibles dans le template
    is_active BOOLEAN DEFAULT TRUE,
    usage_count INTEGER DEFAULT 0,
    created_by INTEGER REFERENCES accounts_user(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE conversation_templates IS 'Modèles de messages prédéfinis';
COMMENT ON COLUMN conversation_templates.template_type IS 'Type de template (greeting, order_inquiry, delivery_info, support)';
COMMENT ON COLUMN conversation_templates.variables IS 'Variables disponibles dans le template';

-- =====================================================
-- TABLE: message_notifications (notifications de messages)
-- =====================================================

CREATE TABLE IF NOT EXISTS message_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER REFERENCES accounts_user(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL, -- 'new_message', 'mention', 'reaction', 'attachment'
    is_read BOOLEAN DEFAULT FALSE,
    is_sent BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE message_notifications IS 'Notifications de messages pour les utilisateurs';
COMMENT ON COLUMN message_notifications.notification_type IS 'Type de notification (new_message, mention, reaction, attachment)';

-- =====================================================
-- INDEX pour les performances
-- =====================================================

-- Index pour conversations
CREATE INDEX IF NOT EXISTS idx_conversations_type ON conversations(conversation_type);
CREATE INDEX IF NOT EXISTS idx_conversations_active ON conversations(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_conversations_last_message ON conversations(last_message_at);
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON conversations(created_at);

-- Index pour conversation_participants
CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation_id ON conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_user_id ON conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_active ON conversation_participants(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_conversation_participants_unread ON conversation_participants(user_id, unread_count) WHERE unread_count > 0;

-- Index pour messages
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(message_type);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_messages_reply_to ON messages(reply_to_id);
CREATE INDEX IF NOT EXISTS idx_messages_not_deleted ON messages(conversation_id, created_at) WHERE is_deleted = FALSE;

-- Index pour message_attachments
CREATE INDEX IF NOT EXISTS idx_message_attachments_message_id ON message_attachments(message_id);
CREATE INDEX IF NOT EXISTS idx_message_attachments_file_type ON message_attachments(file_type);

-- Index pour message_reactions
CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id ON message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_user_id ON message_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_type ON message_reactions(reaction_type);

-- Index pour message_analytics_daily
CREATE INDEX IF NOT EXISTS idx_message_analytics_daily_user_id ON message_analytics_daily(user_id);
CREATE INDEX IF NOT EXISTS idx_message_analytics_daily_date ON message_analytics_daily(date);

-- Index pour conversation_templates
CREATE INDEX IF NOT EXISTS idx_conversation_templates_type ON conversation_templates(template_type);
CREATE INDEX IF NOT EXISTS idx_conversation_templates_active ON conversation_templates(is_active) WHERE is_active = TRUE;

-- Index pour message_notifications
CREATE INDEX IF NOT EXISTS idx_message_notifications_user_id ON message_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_message_notifications_conversation_id ON message_notifications(conversation_id);
CREATE INDEX IF NOT EXISTS idx_message_notifications_unread ON message_notifications(user_id, is_read) WHERE is_read = FALSE;

-- =====================================================
-- TRIGGERS pour updated_at et compteurs
-- =====================================================

-- Trigger pour conversations
CREATE OR REPLACE FUNCTION update_conversations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_conversations_updated_at ON conversations;
CREATE TRIGGER trigger_conversations_updated_at
    BEFORE UPDATE ON conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_conversations_updated_at();

-- Trigger pour messages
CREATE OR REPLACE FUNCTION update_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_messages_updated_at ON messages;
CREATE TRIGGER trigger_messages_updated_at
    BEFORE UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_messages_updated_at();

-- Trigger pour conversation_templates
CREATE OR REPLACE FUNCTION update_conversation_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_conversation_templates_updated_at ON conversation_templates;
CREATE TRIGGER trigger_conversation_templates_updated_at
    BEFORE UPDATE ON conversation_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_templates_updated_at();

-- Trigger pour message_analytics_daily
CREATE OR REPLACE FUNCTION update_message_analytics_daily_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_message_analytics_daily_updated_at ON message_analytics_daily;
CREATE TRIGGER trigger_message_analytics_daily_updated_at
    BEFORE UPDATE ON message_analytics_daily
    FOR EACH ROW
    EXECUTE FUNCTION update_message_analytics_daily_updated_at();

-- Trigger pour mettre à jour les compteurs et timestamps
CREATE OR REPLACE FUNCTION update_message_counters()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'messages' THEN
        IF TG_OP = 'INSERT' THEN
            -- Mettre à jour le dernier message de la conversation
            UPDATE conversations SET 
                last_message_at = NEW.created_at,
                last_message_id = NEW.id,
                updated_at = NOW()
            WHERE id = NEW.conversation_id;
            
            -- Incrémenter le compteur de messages non lus pour tous les participants sauf l'expéditeur
            UPDATE conversation_participants SET 
                unread_count = unread_count + 1
            WHERE conversation_id = NEW.conversation_id 
            AND user_id != NEW.sender_id 
            AND is_active = TRUE;
            
        ELSIF TG_OP = 'UPDATE' THEN
            -- Si le message est marqué comme lu
            IF OLD.delivery_status != 'read' AND NEW.delivery_status = 'read' THEN
                -- Décrémenter le compteur de messages non lus pour l'utilisateur qui a lu
                UPDATE conversation_participants SET 
                    unread_count = GREATEST(unread_count - 1, 0),
                    last_read_at = NOW()
                WHERE conversation_id = NEW.conversation_id 
                AND user_id = NEW.sender_id 
                AND is_active = TRUE;
            END IF;
        END IF;
        
    ELSIF TG_TABLE_NAME = 'conversation_participants' THEN
        IF TG_OP = 'UPDATE' THEN
            -- Si l'utilisateur marque tous les messages comme lus
            IF NEW.last_read_at IS NOT NULL AND OLD.last_read_at IS NULL THEN
                NEW.unread_count = 0;
            END IF;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_messages_counters ON messages;
CREATE TRIGGER trigger_messages_counters
    AFTER INSERT OR UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_message_counters();

DROP TRIGGER IF EXISTS trigger_conversation_participants_counters ON conversation_participants;
CREATE TRIGGER trigger_conversation_participants_counters
    BEFORE UPDATE ON conversation_participants
    FOR EACH ROW
    EXECUTE FUNCTION update_message_counters();

-- =====================================================
-- VUES utiles
-- =====================================================

-- Vue pour les conversations avec informations complètes
CREATE OR REPLACE VIEW conversations_complete AS
SELECT 
    c.*,
    cb.first_name as created_by_first_name,
    cb.last_name as created_by_last_name,
    cb.email as created_by_email,
    COUNT(DISTINCT cp.user_id) as participants_count,
    COUNT(DISTINCT m.id) as messages_count,
    MAX(m.created_at) as actual_last_message_at
FROM conversations c
LEFT JOIN accounts_user cb ON c.created_by = cb.id
LEFT JOIN conversation_participants cp ON c.id = cp.conversation_id AND cp.is_active = TRUE
LEFT JOIN messages m ON c.id = m.conversation_id AND m.is_deleted = FALSE
WHERE c.is_active = TRUE
GROUP BY c.id, cb.first_name, cb.last_name, cb.email;

-- Vue pour les messages avec informations utilisateur
CREATE OR REPLACE VIEW messages_with_users AS
SELECT 
    m.*,
    au.first_name as sender_first_name,
    au.last_name as sender_last_name,
    au.email as sender_email,
    au.profile_image_url as sender_profile_image,
    COUNT(DISTINCT ma.id) as attachments_count,
    COUNT(DISTINCT mr.id) as reactions_count,
    c.conversation_type
FROM messages m
JOIN accounts_user au ON m.sender_id = au.id
JOIN conversations c ON m.conversation_id = c.id
LEFT JOIN message_attachments ma ON m.id = ma.message_id
LEFT JOIN message_reactions mr ON m.id = mr.message_id
WHERE m.is_deleted = FALSE
GROUP BY m.id, au.first_name, au.last_name, au.email, au.profile_image_url, c.conversation_type;

-- Vue pour les conversations non lues par utilisateur
CREATE OR REPLACE VIEW user_unread_conversations AS
SELECT 
    cp.user_id,
    cp.conversation_id,
    c.conversation_type,
    c.title,
    c.last_message_at,
    cp.unread_count,
    m.content as last_message_content,
    m.message_type as last_message_type,
    au.first_name as last_sender_first_name,
    au.last_name as last_sender_last_name
FROM conversation_participants cp
JOIN conversations c ON cp.conversation_id = c.id
LEFT JOIN messages m ON c.last_message_id = m.id
LEFT JOIN accounts_user au ON m.sender_id = au.id
WHERE cp.is_active = TRUE 
AND cp.unread_count > 0
AND c.is_active = TRUE
ORDER BY c.last_message_at DESC;

-- Vue pour les statistiques des messages par utilisateur
CREATE OR REPLACE VIEW user_message_stats AS
SELECT 
    au.id as user_id,
    au.email,
    au.first_name,
    au.last_name,
    COUNT(DISTINCT m.id) as total_messages_sent,
    COUNT(DISTINCT c.id) as total_conversations,
    COUNT(DISTINCT cp.conversation_id) as total_conversations_participated,
    COUNT(DISTINCT mr.id) as total_reactions_given,
    COUNT(DISTINCT ma.id) as total_attachments_sent,
    MAX(m.created_at) as last_message_sent,
    NULL::DECIMAL(8,2) as avg_response_time_minutes -- Calculé séparément dans analytics
FROM accounts_user au
LEFT JOIN messages m ON au.id = m.sender_id AND m.is_deleted = FALSE
LEFT JOIN conversations c ON au.id = c.created_by
LEFT JOIN conversation_participants cp ON au.id = cp.user_id AND cp.is_active = TRUE
LEFT JOIN message_reactions mr ON au.id = mr.user_id
LEFT JOIN messages m2 ON au.id = m2.sender_id AND m2.is_deleted = FALSE
LEFT JOIN message_attachments ma ON m2.id = ma.message_id
GROUP BY au.id, au.email, au.first_name, au.last_name;

COMMENT ON VIEW conversations_complete IS 'Conversations avec informations complètes et compteurs';
COMMENT ON VIEW messages_with_users IS 'Messages avec informations utilisateur et métadonnées';
COMMENT ON VIEW user_unread_conversations IS 'Conversations non lues par utilisateur';
COMMENT ON VIEW user_message_stats IS 'Statistiques des messages par utilisateur';
