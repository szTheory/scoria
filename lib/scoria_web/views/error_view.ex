defmodule Scoria.ErrorView do
  def render("500.html", _assigns), do: "Internal Server Error"
  def render("404.html", _assigns), do: "Not Found"
  def template_not_found(_template, assigns), do: render("500.html", assigns)
end
