-- ip_address values match demo-net (10.20.30.0/24, gateway .1, toolbox .2).
-- postgres-db (.3) is pinned in compose.yml; nginx/apache2/bastion (.4-.6) are
-- reserved addresses -- those containers don't exist yet (Phases 3-5).
INSERT INTO server (name, ip_address) VALUES
    ('nginx-proxy-passthru', '10.20.30.4'),
    ('apache2-python',       '10.20.30.5'),
    ('ansible-bastion',      '10.20.30.6'),
    ('postgres-db',          '10.20.30.3')
    ON CONFLICT( name ) DO NOTHING;

-- Roles
INSERT INTO role (name) VALUES
    ('admin'),
    ('db-admin'),
    ('developer')
    ON CONFLICT( name ) DO NOTHING;

-- Users -- public keys are the throwaway ed25519 keys under keys/users/
INSERT INTO app_user (email_address, username, public_key) VALUES
    ('alice@example.com',   'alice',   'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLREtXVgLZutBdhLiLsoewcVjN+KKzsF0yPYl3G36rC alice@demo'),
    ('bob@example.com',     'bob',     'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPINhSuKndrGh9shT//DOcHF/w0uU42ewQsALnmXLwLg bob@demo'),
    ('charlie@example.com', 'charlie', 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuJYxBYcsAZTjxXgEyHeQ+27ijsGgN29zHWVAP2nm4B charlie@demo'),
    ('david@example.com',   'david',   'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMu8t8xTnfwYvW/50/e+LIPWvtByCqw9rF5Yxr0VBU90 david@demo'),
    ('eve@example.com',     'eve',     'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH26iEs+8M1HTHUStHJGdcD7tuCqZHR5mydXTuJNQcSS eve@demo')
    ON CONFLICT( email_address ) DO NOTHING;

-- server_to_role: nginx->admin; apache2->admin, developer; bastion->admin; postgres-db->admin, db-admin
-- login_account is NULL everywhere except nginx/admin: postgres-db needs alice/bob to log in as
-- themselves (plan.md:472, privilege comes from sudoers, not the account), nginx demonstrates the
-- shared-account case (every admin on nginx logs in as admin_user, not as their own username).
INSERT INTO server_to_role (server_id, role_id, login_account)
    SELECT s.id, r.id, v.login_account
    FROM (VALUES
        ('nginx-proxy-passthru', 'admin',     'admin_user'),
        ('apache2-python',       'admin',     'admin_user'),
        ('apache2-python',       'developer', NULL),
        ('ansible-bastion',      'admin',     'admin_user'),
        ('postgres-db',          'admin',     'admin_user'),
        ('postgres-db',          'db-admin',  'db_admin')
    ) AS v(server_name, role_name, login_account)
    JOIN server s ON s.name = v.server_name
    JOIN role   r ON r.name = v.role_name
    ON CONFLICT( server_id, role_id ) DO NOTHING;

-- role_to_user: admin->alice; db-admin->bob; developer->charlie, david, eve
INSERT INTO role_to_user (role_id, user_id)
    SELECT r.id, u.id FROM role r, app_user u WHERE
        (r.name = 'admin'     AND u.username = 'alice') OR
        (r.name = 'db-admin'  AND u.username = 'bob') OR
        (r.name = 'developer' AND u.username IN ('charlie', 'david', 'eve') )
    ON CONFLICT( role_id, user_id ) DO NOTHING;
