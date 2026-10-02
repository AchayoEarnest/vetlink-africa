defmodule Vetlink.Storage do
  @moduledoc """
  File storage behind a small behaviour. Development and tests use the local disk adapter.
  For production, add an S3-compatible adapter (for example with ex_aws_s3) and set
  `config :vetlink, :storage_adapter, Vetlink.Storage.S3`.
  """
  @callback put(key :: String.t(), binary()) :: :ok | {:error, term()}
  @callback get(key :: String.t()) :: {:ok, binary()} | {:error, term()}
  @callback delete(key :: String.t()) :: :ok | {:error, term()}

  def put(key, bin), do: adapter().put(key, bin)
  def get(key), do: adapter().get(key)
  def delete(key), do: adapter().delete(key)

  defp adapter, do: Application.get_env(:vetlink, :storage_adapter, Vetlink.Storage.Local)
end
