CREATE SCHEMA lab02;

CREATE TABLE lab02.training_catalog (
    training_id   INTEGER,
    title         CHARACTER VARYING(100) NOT NULL,
    price         NUMERIC(8, 2) NOT NULL,
    is_available  BOOLEAN NOT NULL,
    training_date DATE NOT NULL,
    start_time    TIME NOT NULL,
    created_at    TIMESTAMP NOT NULL,
    weekdays      TEXT[],
    details       JSONB,
    description   TEXT,

    CONSTRAINT pk_training_catalog PRIMARY KEY (training_id)
);

SELECT column_name,
       data_type,
       character_maximum_length,
       numeric_precision,
       numeric_scale,
       is_nullable
FROM information_schema.columns
WHERE table_schema = 'lab02'
  AND table_name = 'training_catalog'
ORDER BY ordinal_position;
