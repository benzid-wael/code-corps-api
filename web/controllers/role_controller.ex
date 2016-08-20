defmodule CodeCorps.RoleController do
  use CodeCorps.Web, :controller

  alias CodeCorps.Role
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create]

  def index(conn, _params) do
    roles = Repo.all(Role)
    render(conn, "index.json-api", data: roles)
  end

  def create(conn, %{"data" => data = %{"type" => "role", "attributes" => _role_params}}) do
    changeset = Role.changeset(%Role{}, Params.to_attributes(data))

    case Repo.insert(changeset) do
      {:ok, role} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", role_path(conn, :show, role))
        |> render("show.json-api", data: role)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CodeCorps.ChangesetView, "error.json-api", changeset: changeset)
    end
  end
end