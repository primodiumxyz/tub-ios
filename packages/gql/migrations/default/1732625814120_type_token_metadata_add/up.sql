CREATE TYPE token_metadata AS (
    name VARCHAR(255),
    symbol VARCHAR(10),
    description TEXT,
    image_uri TEXT,
    external_url TEXT,
    supply NUMERIC,
    is_pump_token BOOLEAN
);
