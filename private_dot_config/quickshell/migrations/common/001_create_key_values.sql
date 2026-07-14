CREATE TABLE IF NOT EXISTS key_values (
  namespace TEXT NOT NULL,
  key TEXT NOT NULL,
  value BLOB NOT NULL,
  PRIMARY KEY (namespace, key)
);
