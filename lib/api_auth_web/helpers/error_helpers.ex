defmodule ApiAuthWeb.Helpers.ErrorHelpers do
  # import ApiAuthWeb.Gettext

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(ApiAuthWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ApiAuthWeb.Gettext, "errors", msg, opts)
    end
  end
end
