defmodule IexLineBotWeb.Router do
  use IexLineBotWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", IexLineBotWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/", IexLineBotWeb do
    pipe_through :api

    post "/", PageController, :line
  end

  # Other scopes may use custom stacks.
  # scope "/api", IexLineBotWeb do
  #   pipe_through :api
  # end
end
