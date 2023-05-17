defmodule Chat.Repo.Migrations.AddViewLastSubMessages do
  use Ecto.Migration

  def up do
    execute("""
    CREATE VIEW last_sub_messages AS
      SELECT
        sm.*
      FROM
        sub_messages sm
      LEFT JOIN sub_messages _sm ON sm.message_id = _sm.message_id
        AND sm.inserted_at < _sm.inserted_at
      WHERE
        _sm.id IS NULL;
    """)
  end

  def down do
    execute("DROP VIEW last_sub_messages;")
  end
end
