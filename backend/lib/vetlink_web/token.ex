defmodule VetlinkWeb.Token do
  @salt "vetlink user auth"
  @max_age 60 * 60 * 24 * 14

  def sign(user), do: Phoenix.Token.sign(VetlinkWeb.Endpoint, @salt, user.id)

  def verify(token) do
    Phoenix.Token.verify(VetlinkWeb.Endpoint, @salt, token, max_age: @max_age)
  end
end
