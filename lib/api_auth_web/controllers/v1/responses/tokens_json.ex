defmodule ApiAuthWeb.V1.Responses.TokensJSON do
  def index(%{tokens: tokens}) do
    %{data: tokens_info(tokens)}
  end

  defp tokens_info(%{api_access_token: access_token, api_renewal_token: renewal_token}) do
    %{
      access_token: access_token,
      renewal_token: renewal_token
    }
  end
end
