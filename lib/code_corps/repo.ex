defmodule CodeCorps.Repo do
  use Ecto.Repo, otp_app: :code_corps
  use Scrivener, page_size: 10
end
