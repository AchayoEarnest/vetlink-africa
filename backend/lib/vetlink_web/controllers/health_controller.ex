defmodule VetlinkWeb.HealthController do
  use VetlinkWeb, :controller
  def show(conn, _), do: json(conn, %{status: "ok"})
end
