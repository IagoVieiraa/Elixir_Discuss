defmodule DiscussWeb.AuthController do
  use DiscussWeb, :controller
  plug Ueberauth
  alias DiscussWeb.Router.Helpers, as: Routes
  alias Discuss.User
  alias Discuss.Repo

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_params = %{token: auth.credentials.token, email: auth.info.email, provider: "github"}
    changeset = User.changeset(%User{}, user_params)

    signin(conn, changeset)
  end

  def signout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: Routes.topic_path(conn, :index))
  end

  defp signin(conn, changeset) do
    case insert_or_update_user(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        # any signed in user should have some data in their cookies tied to our domain with their id cuz of this line
        |> put_session(:user_id, user.id)
        |> redirect(to: Routes.topic_path(conn, :index))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Error signing in")
        |> redirect(to: Routes.topic_path(conn, :index))
    end
  end

  # this is intended to be a stand alone helper function for the auth controller
  defp insert_or_update_user(changeset) do
    # the goal of this func is to check for any pre-existing users that are similar to a new one being added
    case Repo.get_by(User, email: changeset.changes.email) do
      nil ->
        # this is how we add records to our db
        Repo.insert(changeset)

      user ->
        {:ok, user}
    end
  end
end
