import Config
port = System.get_env("PORT")
base_path = "tmp/mnesia_db_#{port}"
# Указываем директорию для mnesia
config :mnesia, dir: String.to_charlist(base_path)
