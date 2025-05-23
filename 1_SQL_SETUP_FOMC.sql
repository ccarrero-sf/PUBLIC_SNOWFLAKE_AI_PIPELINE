--authors: John Heisler & Garrett Frere
-- Modified by Carlos Carrero to include Git integration & Native PDF read capabilities


--Create our warehouse
CREATE OR REPLACE WAREHOUSE gen_ai_fsi_wh
    WAREHOUSE_SIZE = 'medium';

--Create our database
CREATE OR REPLACE DATABASE gen_ai_fsi;

--create your schema
CREATE OR REPLACE SCHEMA gen_ai_fsi.fomc;

CREATE OR REPLACE API INTEGRATION git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/ccarrero-sf/')
  ENABLED = TRUE;

CREATE OR REPLACE GIT REPOSITORY git_repo
    api_integration = git_api_integration
    origin = 'https://github.com/ccarrero-sf/PUBLIC_SNOWFLAKE_AI_PIPELINE';

-- Make sure we get the latest files
ALTER GIT REPOSITORY git_repo FETCH;

--create stage fed_logic;
CREATE OR REPLACE STAGE gen_ai_fsi.fomc.fed_logic
    DIRECTORY = (ENABLE = TRUE);

--create stage fed_pdf;
CREATE OR REPLACE STAGE gen_ai_fsi.fomc.fed_pdf
    DIRECTORY = (ENABLE = TRUE);

-- create a stream on the directory
CREATE OR REPLACE STREAM gen_ai_fsi.fomc.fomc_stream on DIRECTORY(@gen_ai_fsi.fomc.fed_pdf);

-- Create sequences
CREATE OR REPLACE SEQUENCE gen_ai_fsi.fomc.fed_pdf_full_text_sequence;
CREATE OR REPLACE SEQUENCE gen_ai_fsi.fomc.fed_pdf_chunk_sequence;

--store model data for meta analysis
CREATE OR REPLACE TABLE gen_ai_fsi.fomc.models (
    model          VARCHAR,
    context_window INT
);

--insert values into models table
INSERT INTO gen_ai_fsi.fomc.models (model, context_window)
VALUES ('mistral-large', 32000),
       ('reka-flash', 100000),
       ('reka-core', 32000),
       ('jamba-instruct', 256000),
       ('mixtral-8x7b', 32000),
       ('llama2-70b-chat', 4096),
       ('llama3-8b', 8000),
       ('llama3-70b', 8000),
       ('llama3.1-8b', 128000),
       ('llama3.1-70b', 128000),
       ('llama3.1-405b', 128000),
       ('mistral-7b', 32000),
       ('gemma-7b', 8000);

--create our full text table
CREATE OR REPLACE TABLE gen_ai_fsi.fomc.pdf_full_text (
    id            NUMBER(19, 0),
    relative_path VARCHAR(16777216),
    size          NUMBER(38, 0),
    last_modified TIMESTAMP_TZ(3),
    md5           VARCHAR(16777216),
    etag          VARCHAR(16777216),
    file_url      VARCHAR(16777216),
    file_text     VARCHAR(16777216),
    file_date     DATE,
    sentiment     VARCHAR(16777216)
);

CREATE OR REPLACE TABLE gen_ai_fsi.fomc.pdf_chunks (
    id            NUMBER(19, 0),
    full_text_fk  NUMBER(19, 0),
    relative_path VARCHAR(16777216),
    file_date     DATE,
    chunk         VARCHAR(16777216)
);

