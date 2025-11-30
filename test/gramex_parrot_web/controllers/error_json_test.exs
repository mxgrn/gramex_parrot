defmodule GramexParrotWeb.ErrorJSONTest do
  use GramexParrotWeb.ConnCase, async: true

  test "renders 404" do
    assert GramexParrotWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert GramexParrotWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
