create user bak_dump@'%' identified by "Bak.4dump";
GRANT SELECT, RELOAD, SHOW DATABASES, LOCK TABLES, SHOW VIEW,EXECUTE, REPLICATION CLIENT, EVENT ON *.* TO bak_dump@'%';
