defmodule GramexParrotWeb.PageController do
  use GramexParrotWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
