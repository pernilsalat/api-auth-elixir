defmodule ApiAuthWeb.V1.Responses.ErrorResponse do
  @base_fields [status: nil, message: nil, errors: nil]

  defmacro __using__(fields) do
    fields = Keyword.merge(@base_fields, fields)

    quote do
      @derive Jason.Encoder
      defstruct unquote(fields)
    end
  end
end

defmodule ApiAuthWeb.V1.Responses.ErrorResponse.Unauthorized do
  alias ApiAuthWeb.V1.Responses.ErrorResponse

  use ErrorResponse, status: 401, message: "Unauthorized"
end
