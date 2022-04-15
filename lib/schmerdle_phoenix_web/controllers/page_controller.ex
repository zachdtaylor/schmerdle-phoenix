defmodule SchmerdlePhoenixWeb.PageController do
  use SchmerdlePhoenixWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
