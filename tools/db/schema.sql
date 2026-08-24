-- Entity tables
CREATE TABLE IF NOT EXISTS server (
    id         serial PRIMARY KEY,
    name       text NOT NULL,
    ip_address inet NOT NULL,

    CONSTRAINT server_name_unique UNIQUE (name),
    CONSTRAINT server_ip_address_unique UNIQUE (ip_address)
);

CREATE TABLE IF NOT EXISTS role (
    id         serial PRIMARY KEY,
    name       text NOT NULL,

    CONSTRAINT role_name_unique UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS app_user (
    id serial PRIMARY KEY,
    email_address text NOT NULL,
    username text NOT NULL,
    public_key text NOT NULL,

    CONSTRAINT app_user_email_address_unique UNIQUE (email_address),
    CONSTRAINT app_user_username_unique UNIQUE (username),
    CONSTRAINT app_user_public_key_unique UNIQUE (public_key),
    CONSTRAINT app_user_username_matches_email
        CHECK (username = split_part(email_address, '@', 1))
);

-- Relational tables
CREATE TABLE IF NOT EXISTS server_to_role (
    server_id int NOT NULL,
    role_id int NOT NULL,
    -- NULL = each entitled user logs in as themselves (app_user.username);
    -- non-NULL = every user holding this role on this server shares this one account.
    login_account text,

    CONSTRAINT server_to_role_pk PRIMARY KEY (server_id, role_id),
    CONSTRAINT server_to_role_server_fk FOREIGN KEY (server_id) REFERENCES server(id) ON DELETE CASCADE,
    CONSTRAINT server_to_role_role_fk FOREIGN KEY (role_id) REFERENCES role(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS role_to_user (
    role_id int NOT NULL,
    user_id int NOT NULL,

    CONSTRAINT role_to_user_pk PRIMARY KEY (role_id, user_id),
    CONSTRAINT role_to_user_role_fk FOREIGN KEY (role_id) REFERENCES role(id) ON DELETE CASCADE,
    CONSTRAINT role_to_user_user_fk FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE
);