-- =================================
-- Database Initialization Script
-- =================================

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create application schema
CREATE SCHEMA IF NOT EXISTS app;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Create sessions table for tracking
CREATE TABLE IF NOT EXISTS sessions (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) UNIQUE NOT NULL,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_sessions_session_id ON sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_active ON sessions(is_active);

-- Create audit log table
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    old_values JSONB,
    new_values JSONB,
    user_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_log_table_name ON audit_log(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_operation ON audit_log(operation);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at);

-- Create metrics table for application metrics
CREATE TABLE IF NOT EXISTS app_metrics (
    id SERIAL PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL,
    metric_value NUMERIC NOT NULL,
    metric_type VARCHAR(50) NOT NULL, -- counter, gauge, histogram
    labels JSONB,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_app_metrics_name ON app_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_app_metrics_recorded_at ON app_metrics(recorded_at);

-- Create trigger function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for users table
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    old_data JSONB;
    new_data JSONB;
BEGIN
    -- Capture old and new data
    IF TG_OP = 'DELETE' THEN
        old_data = to_jsonb(OLD);
        new_data = NULL;
    ELSIF TG_OP = 'UPDATE' THEN
        old_data = to_jsonb(OLD);
        new_data = to_jsonb(NEW);
    ELSIF TG_OP = 'INSERT' THEN
        old_data = NULL;
        new_data = to_jsonb(NEW);
    END IF;

    -- Insert audit record
    INSERT INTO audit_log (table_name, operation, old_values, new_values)
    VALUES (TG_TABLE_NAME, TG_OP, old_data, new_data);

    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create audit triggers for users table
DROP TRIGGER IF EXISTS users_audit_trigger ON users;
CREATE TRIGGER users_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION audit_trigger_function();

-- Insert initial data
INSERT INTO users (name, email) VALUES 
    ('Admin User', 'admin@example.com'),
    ('Test User', 'test@example.com'),
    ('Demo User', 'demo@example.com'),
    ('Load Test User', 'loadtest@example.com')
ON CONFLICT (email) DO NOTHING;

-- Create database health check function
CREATE OR REPLACE FUNCTION health_check()
RETURNS TABLE (
    check_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- Check database connectivity
    RETURN QUERY SELECT 
        'database_connectivity'::TEXT,
        'healthy'::TEXT,
        'Database is responding'::TEXT;
    
    -- Check table counts
    RETURN QUERY SELECT 
        'users_count'::TEXT,
        'healthy'::TEXT,
        'Users: ' || (SELECT count(*)::TEXT FROM users);
    
    -- Check recent activity
    RETURN QUERY SELECT 
        'recent_audit_activity'::TEXT,
        CASE 
            WHEN (SELECT count(*) FROM audit_log WHERE created_at > NOW() - INTERVAL '1 hour') > 0 
            THEN 'active'::TEXT
            ELSE 'quiet'::TEXT
        END,
        'Audit entries in last hour: ' || (SELECT count(*)::TEXT FROM audit_log WHERE created_at > NOW() - INTERVAL '1 hour');
    
    -- Check database size
    RETURN QUERY SELECT 
        'database_size'::TEXT,
        'info'::TEXT,
        'Size: ' || pg_size_pretty(pg_database_size(current_database()));
        
END;
$$ LANGUAGE plpgsql;

-- Create stored procedure for cleanup old sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM sessions 
    WHERE expires_at < CURRENT_TIMESTAMP 
       OR (created_at < CURRENT_TIMESTAMP - INTERVAL '30 days');
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Log the cleanup
    INSERT INTO app_metrics (metric_name, metric_value, metric_type, labels)
    VALUES ('sessions_cleaned', deleted_count, 'counter', '{"operation": "cleanup"}');
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Create function to get database statistics
CREATE OR REPLACE FUNCTION get_database_stats()
RETURNS TABLE (
    stat_name TEXT,
    stat_value TEXT
) AS $$
BEGIN
    RETURN QUERY SELECT 
        'total_users'::TEXT,
        (SELECT count(*)::TEXT FROM users);
    
    RETURN QUERY SELECT 
        'active_users'::TEXT,
        (SELECT count(*)::TEXT FROM users WHERE is_active = true);
    
    RETURN QUERY SELECT 
        'total_sessions'::TEXT,
        (SELECT count(*)::TEXT FROM sessions);
    
    RETURN QUERY SELECT 
        'active_sessions'::TEXT,
        (SELECT count(*)::TEXT FROM sessions WHERE is_active = true AND expires_at > CURRENT_TIMESTAMP);
    
    RETURN QUERY SELECT 
        'audit_entries_today'::TEXT,
        (SELECT count(*)::TEXT FROM audit_log WHERE created_at > CURRENT_DATE);
    
    RETURN QUERY SELECT 
        'database_version'::TEXT,
        version();
        
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT USAGE ON SCHEMA public TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO postgres;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- Create read-only user for reporting
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'readonly') THEN
        CREATE ROLE readonly;
    END IF;
END
$$;

GRANT CONNECT ON DATABASE prodapp TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;

-- Final message
DO $$
BEGIN
    RAISE NOTICE 'Database initialization completed successfully!';
    RAISE NOTICE 'Total users: %', (SELECT count(*) FROM users);
    RAISE NOTICE 'Database size: %', pg_size_pretty(pg_database_size(current_database()));
END
$$; 