-- _UP_ (do not remove this comment)
-- Function to cast JSONB to token_metadata
CREATE OR REPLACE FUNCTION jsonb_to_token_metadata(data jsonb)
RETURNS token_metadata AS $$
SELECT ROW(
  (data->>'name')::VARCHAR(255),
  (data->>'symbol')::VARCHAR(10),
  (data->>'description')::TEXT,
  (data->>'image_uri')::TEXT,
  (data->>'external_url')::TEXT,
  (data->>'supply')::NUMERIC,
  (data->>'is_pump_token')::BOOLEAN
)::token_metadata;
$$ LANGUAGE SQL IMMUTABLE STRICT;

-- Create the cast
CREATE CAST (jsonb AS token_metadata) WITH FUNCTION jsonb_to_token_metadata(jsonb) AS IMPLICIT;

-- _DOWN_ (do not remove this comment)
DROP CAST (jsonb AS token_metadata);
DROP FUNCTION jsonb_to_token_metadata(jsonb);