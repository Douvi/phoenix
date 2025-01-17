defmodule Phoenix.Endpoint do
  @moduledoc ~S"""
  Defines a Phoenix endpoint.

  The endpoint is the boundary where all requests to your
  web application start. It is also the interface your
  application provides to the underlying web servers.

  Overall, an endpoint has three responsibilities:

    * to provide a wrapper for starting and stopping the
      endpoint as part of a supervision tree

    * to define an initial plug pipeline for requests
      to pass through

    * to host web specific configuration for your
      application

  ## Endpoints

  An endpoint is simply a module defined with the help
  of `Phoenix.Endpoint`. If you have used the `mix phx.new`
  generator, an endpoint was automatically generated as
  part of your application:

      defmodule YourApp.Endpoint do
        use Phoenix.Endpoint, otp_app: :your_app

        # plug ...
        # plug ...

        plug YourApp.Router
      end

  Endpoints must be explicitly started as part of your application
  supervision tree. Endpoints are added by default
  to the supervision tree in generated applications. Endpoints can be
  added to the supervision tree as follows:

      children = [
        YourApp.Endpoint
      ]

  ### Endpoint configuration

  All endpoints are configured in your application environment.
  For example:

      config :your_app, YourApp.Endpoint,
        secret_key_base: "kjoy3o1zeidquwy1398juxzldjlksahdk3"

  Endpoint configuration is split into two categories. Compile-time
  configuration means the configuration is read during compilation
  and changing it at runtime has no effect. The compile-time
  configuration is mostly related to error handling.

  Runtime configuration, instead, is accessed during or
  after your application is started and can be read through the
  `c:config/2` function:

      YourApp.Endpoint.config(:port)
      YourApp.Endpoint.config(:some_config, :default_value)

  ### Dynamic configuration

  For dynamically configuring the endpoint, such as loading data
  from environment variables or configuration files, Phoenix invokes
  the `init/2` callback on the endpoint, passing a `:supervisor`
  atom as first argument and the endpoint configuration as second.

  All of Phoenix configuration, except the Compile-time configuration
  below can be set dynamically from the `c:init/2` callback.

  ### Compile-time configuration

    * `:code_reloader` - when `true`, enables code reloading functionality.
      For code the list of code reloader configuration options see
      `Phoenix.CodeReloader.reload!/1`

    * `:debug_errors` - when `true`, uses `Plug.Debugger` functionality for
      debugging failures in the application. Recommended to be set to `true`
      only in development as it allows listing of the application source
      code during debugging. Defaults to `false`

    * `:render_errors` - responsible for rendering templates whenever there
      is a failure in the application. For example, if the application crashes
      with a 500 error during a HTML request, `render("500.html", assigns)`
      will be called in the view given to `:render_errors`. Defaults to:

          [view: MyApp.ErrorView, accepts: ~w(html), layout: false]

      The default format is used when none is set in the connection

  ### Runtime configuration

    * `:cache_static_manifest` - a path to a json manifest file that contains
      static files and their digested version. This is typically set to
      "priv/static/cache_manifest.json" which is the file automatically generated
      by `mix phx.digest`

    * `:check_origin` - configure transports to check `origin` header or not. May
      be `false`, `true`, a list of hosts that are allowed, or a function provided as
      MFA tuple. Hosts also support wildcards.

      For example, using a list of hosts:

          check_origin: ["//phoenixframework.org", "//*.example.com"]

      or a custom MFA function:

          check_origin: {MyAppWeb.Auth, :my_check_origin?, []}

      The MFA is invoked with the request `%URI{}` as the first argument,
      followed by arguments in the MFA list

      Defaults to `true`.

    * `:http` - the configuration for the HTTP server. Currently uses
      Cowboy and accepts all options as defined by
      [`Plug.Cowboy`](https://hexdocs.pm/plug_cowboy/). Defaults to `false`

    * `:https` - the configuration for the HTTPS server. Currently uses
      Cowboy and accepts all options as defined by
      [`Plug.Cowboy`](https://hexdocs.pm/plug_cowboy/). Defaults to `false`

    * `:force_ssl` - ensures no data is ever sent via HTTP, always redirecting
      to HTTPS. It expects a list of options which are forwarded to `Plug.SSL`.
      By default it sets the "strict-transport-security" header in HTTPS requests,
      forcing browsers to always use HTTPS. If an unsafe request (HTTP) is sent,
      it redirects to the HTTPS version using the `:host` specified in the `:url`
      configuration. To dynamically redirect to the `host` of the current request,
      set `:host` in the `:force_ssl` configuration to `nil`

    * `:secret_key_base` - a secret key used as a base to generate secrets
      for encrypting and signing data. For example, cookies and tokens
      are signed by default, but they may also be encrypted if desired.
      Defaults to `nil` as it must be set per application

    * `:server` - when `true`, starts the web server when the endpoint
      supervision tree starts. Defaults to `false`. The `mix phx.server`
      task automatically sets this to `true`

    * `:url` - configuration for generating URLs throughout the app.
      Accepts the `:host`, `:scheme`, `:path` and `:port` options. All
      keys except `:path` can be changed at runtime. Defaults to:

          [host: "localhost", path: "/"]

      The `:port` option requires either an integer, string, or
      `{:system, "ENV_VAR"}`. When given a tuple like `{:system, "PORT"}`,
      the port will be referenced from `System.get_env("PORT")` at runtime
      as a workaround for releases where environment specific information
      is loaded only at compile-time.

      The `:host` option requires a string or `{:system, "ENV_VAR"}`. Similar
      to `:port`, when given a tuple like `{:system, "HOST"}`, the host
      will be referenced from `System.get_env("HOST")` at runtime.

      The `:scheme` option accepts `"http"` and `"https"` values. Default value
      is infered from top level `:http` or `:https` option. It is useful
      when hosting Phoenix behind a load balancer or reverse proxy and
      terminating SSL there.

      The `:path` option can be used to override root path. Useful when hosting
      Phoenix behind a reverse proxy with URL rewrite rules

    * `:static_url` - configuration for generating URLs for static files.
      It will fallback to `url` if no option is provided. Accepts the same
      options as `url`

    * `:watchers` - a set of watchers to run alongside your server. It
      expects a list of tuples containing the executable and its arguments.
      Watchers are guaranteed to run in the application directory, but only
      when the server is enabled. For example, the watcher below will run
      the "watch" mode of the webpack build tool when the server starts.
      You can configure it to whatever build tool or command you want:

          [node: ["node_modules/webpack/bin/webpack.js", "--mode", "development",
              "--watch-stdin"]]

      The `:cd` option can be used on a watcher to override the folder from
      which the watcher will run. By default this will be the project's root:
      `File.cwd!()`

          [node: ["node_modules/webpack/bin/webpack.js", "--mode", "development",
              "--watch-stdin"], cd: "my_frontend"]

    * `:live_reload` - configuration for the live reload option.
      Configuration requires a `:patterns` option which should be a list of
      file patterns to watch. When these files change, it will trigger a reload.
      If you are using a tool like [pow](http://pow.cx) in development,
      you may need to set the `:url` option appropriately.

          live_reload: [
            url: "ws://localhost:4000",
            patterns: [
              ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
              ~r{web/views/.*(ex)$},
              ~r{web/templates/.*(eex)$}
            ]
          ]

    * `:pubsub` - configuration for this endpoint's pubsub adapter.
      Configuration either requires a `:name` of the registered pubsub
      server or a `:name` and `:adapter` pair. The pubsub name and adapter
      are compile time configuration, while the remaining options are runtime.
      The given adapter and name pair will be started as part of the supervision
      tree. If no adapter is specified, the pubsub system will work by sending
      events and subscribing to the given name. Defaults to:

          [adapter: Phoenix.PubSub.PG2, name: MyApp.PubSub]

      It also supports custom adapter configuration:

          [name: :my_pubsub, adapter: Phoenix.PubSub.Redis,
           host: "192.168.100.1"]

  ## Endpoint API

  In the previous section, we have used the `c:config/2` function that is
  automatically generated in your endpoint. Here's a list of all the functions
  that are automatically defined in your endpoint:

    * for handling paths and URLs: `c:struct_url/0`, `c:url/0`, `c:path/1`,
      `c:static_url/0`,`c:static_path/1`, and `c:static_integrity/1`
    * for handling channel subscriptions: `c:subscribe/2` and `c:unsubscribe/1`
    * for broadcasting to channels: `c:broadcast/3`, `c:broadcast!/3`,
      `c:broadcast_from/4`, and `c:broadcast_from!/4`
    * for configuration: `c:start_link/0`, `c:config/2`, and `c:config_change/2`
    * as required by the `Plug` behaviour: `c:Plug.init/1` and `c:Plug.call/2`

  ## Instrumentation

  Phoenix uses the `:telemetry` library for instrumentation. The following events
  are published by Phoenix with the following measurements and metadata:

    * `[:phoenix, :endpoint, :start]` - dispatched by `Plug.Telemetry` in your
      endpoint at the beginning of every request.
      * Measurement: `%{time: System.monotonic_time}`
      * Metadata: `%{conn: Plug.Conn.t}`

    * `[:phoenix, :endpoint, :stop]` - dispatched by `Plug.Telemetry` in your
      endpoint whenever the response is sent
      * Measurement: `%{duration: native_time}`
      * Metadata: `%{conn: Plug.Conn.t}`

    * `[:phoenix, :router_dispatch, :start]` - dispatched by `Phoenix.Router`
      before dispatching to a matched route
      * Measurement: `%{time: System.monotonic_time}`
      * Metadata: `%{conn: Plug.Conn.t, route: binary, plug: module, plug_opts: term, path_params: map, pipe_through: [atom]}`

    * `[:phoenix, :router_dispatch, :stop]` - dispatched by `Phoenix.Router`
      after successfully dispatching to a matched route
      * Measurement: `%{duration: native_time}`
      * Metadata: `%{conn: Plug.Conn.t, route: binary, plug: module, plug_opts: term, path_params: map, pipe_through: [atom]}`

    * `[:phoenix, :error_rendered]` - dispatched at the end of an error view being rendered
      * Measurement: `%{duration: native_time}`
      * Metadata: `%{status: Plug.Conn.status, kind: Exception.kind, reason: term, stacktrace: Exception.stacktrace}`

    * `[:phoenix, :socket_connected]` - dispatched at the end of a socket connection
      * Measurement: `%{duration: native_time}`
      * Metadata: `%{endpoint: atom, transport: atom, params: term, connect_info: map, vsn: binary, user_socket: atom, result: :ok | :error, serializer: atom}`

    * `[:phoenix, :channel_joined]` - dispatched at the end of a channel join
      * Measurement: `%{duration: native_time}`
      * Metadata: `%{params: term, socket: Phoenix.Socket.t}`

    * `[:phoenix, :channel_handled_in]` - dispatched at the end of a channel handle in
      * Measurement: `%{duration: native_time}`
      * Metadata: `%{event: binary, params: term, socket: Phoenix.Socket.t}`

  """

  @type topic :: String.t
  @type event :: String.t
  @type msg :: map

  require Logger

  # Configuration

  @doc """
  Starts the endpoint supervision tree.

  Starts endpoint's configuration cache and possibly the servers for
  handling requests.
  """
  @callback start_link() :: Supervisor.on_start

  @doc """
  Access the endpoint configuration given by key.
  """
  @callback config(key :: atom, default :: term) :: term

  @doc """
  Reload the endpoint configuration on application upgrades.
  """
  @callback config_change(changed :: term, removed :: term) :: term

  @doc """
  Initialize the endpoint configuration.

  Invoked when the endpoint supervisor starts, allows dynamically
  configuring the endpoint from system environment or other runtime sources.
  """
  @callback init(:supervisor, config :: Keyword.t) :: {:ok, Keyword.t}

  # Paths and URLs

  @doc """
  Generates the endpoint base URL, but as a `URI` struct.
  """
  @callback struct_url() :: URI.t

  @doc """
  Generates the endpoint base URL without any path information.
  """
  @callback url() :: String.t

  @doc """
  Generates the path information when routing to this endpoint.
  """
  @callback path(path :: String.t) :: String.t

  @doc """
  Generates the static URL without any path information.
  """
  @callback static_url() :: String.t

  @doc """
  Generates a route to a static file in `priv/static`.
  """
  @callback static_path(path :: String.t) :: String.t

  @doc """
  Generates an integrity hash to a static file in `priv/static`.
  """
  @callback static_integrity(path :: String.t) :: String.t | nil

  @doc """
  Generates a two item tuple containing the `static_path` and `static_integrity`.
  """
  @callback static_lookup(path :: String.t) :: {String.t, String.t} | {String.t, nil}

  # Channels

  @doc """
  Subscribes the caller to the given topic.

  See `Phoenix.PubSub.subscribe/3` for options.
  """
  @callback subscribe(topic, opts :: Keyword.t) :: :ok | {:error, term}

  @doc """
  Unsubscribes the caller from the given topic.
  """
  @callback unsubscribe(topic) :: :ok | {:error, term}

  @doc """
  Broadcasts a `msg` as `event` in the given `topic`.
  """
  @callback broadcast(topic, event, msg) :: :ok | {:error, term}

  @doc """
  Broadcasts a `msg` as `event` in the given `topic`.

  Raises in case of failures.
  """
  @callback broadcast!(topic, event, msg) :: :ok | no_return

  @doc """
  Broadcasts a `msg` from the given `from` as `event` in the given `topic`.
  """
  @callback broadcast_from(from :: pid, topic, event, msg) :: :ok | {:error, term}

  @doc """
  Broadcasts a `msg` from the given `from` as `event` in the given `topic`.

  Raises in case of failures.
  """
  @callback broadcast_from!(from :: pid, topic, event, msg) :: :ok | no_return

  @doc false
  defmacro __using__(opts) do
    quote do
      @behaviour Phoenix.Endpoint

      unquote(config(opts))
      unquote(pubsub())
      unquote(plug())
      unquote(server())
    end
  end

  defp config(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app] || raise "endpoint expects :otp_app to be given"
      var!(config) = Phoenix.Endpoint.Supervisor.config(@otp_app, __MODULE__)
      var!(code_reloading?) = var!(config)[:code_reloader]

      # Avoid unused variable warnings
      _ = var!(code_reloading?)

      @doc false
      def init(_key, config) do
        {:ok, config}
      end

      defoverridable init: 2
    end
  end

  @doc false
  def __pubsub_server__!(module) do
    if server = module.__pubsub_server__() do
      server
    else
      raise ArgumentError, """
      no :pubsub server configured at, please setup :pubsub in your config.

      By default this looks like:

          config :my_app, MyApp.PubSub,
            ...,
            pubsub: [name: MyApp.PubSub,
            adapter: Phoenix.PubSub.PG2]

      """
    end
  end

  defp pubsub() do
    quote do
      def __pubsub_server__ do
        Phoenix.Config.cache(__MODULE__,
          :__phoenix_pubsub_server__,
          &Phoenix.Endpoint.Supervisor.pubsub_server/1)
      end

      # TODO v2: Remove pid version
      @doc false
      def subscribe(pid, topic) when is_pid(pid) and is_binary(topic) do
        IO.warn "#{__MODULE__}.subscribe/2 is deprecated, please use subscribe/1"
        Phoenix.PubSub.subscribe(Phoenix.Endpoint.__pubsub_server__!(__MODULE__), pid, topic, [])
      end
      def subscribe(pid, topic, opts) when is_pid(pid) and is_binary(topic) and is_list(opts) do
        Phoenix.PubSub.subscribe(Phoenix.Endpoint.__pubsub_server__!(__MODULE__), pid, topic, opts)
      end
      def subscribe(topic) when is_binary(topic) do
        Phoenix.PubSub.subscribe(Phoenix.Endpoint.__pubsub_server__!(__MODULE__), topic, [])
      end
      def subscribe(topic, opts) when is_binary(topic) and is_list(opts) do
        Phoenix.PubSub.subscribe(Phoenix.Endpoint.__pubsub_server__!(__MODULE__), topic, opts)
      end

      # TODO v2: Remove pid version
      @doc false
      def unsubscribe(pid, topic) do
        IO.warn "#{__MODULE__}.unsubscribe/2 is deprecated, please use unsubscribe/1"
        Phoenix.PubSub.unsubscribe(Phoenix.Endpoint.__pubsub_server__!(__MODULE__), topic)
      end
      def unsubscribe(topic) do
        Phoenix.PubSub.unsubscribe(Phoenix.Endpoint.__pubsub_server__!(__MODULE__), topic)
      end

      def broadcast_from(from, topic, event, msg) do
        Phoenix.Channel.Server.broadcast_from(Phoenix.Endpoint.__pubsub_server__!(__MODULE__), from, topic, event, msg)
      end

      def broadcast_from!(from, topic, event, msg) do
        Phoenix.Channel.Server.broadcast_from!(Phoenix.Endpoint.__pubsub_server__!(__MODULE__), from, topic, event, msg)
      end

      def broadcast(topic, event, msg) do
        Phoenix.Channel.Server.broadcast(Phoenix.Endpoint.__pubsub_server__!(__MODULE__), topic, event, msg)
      end

      def broadcast!(topic, event, msg) do
        Phoenix.Channel.Server.broadcast!(Phoenix.Endpoint.__pubsub_server__!(__MODULE__), topic, event, msg)
      end
    end
  end

  defp plug() do
    quote location: :keep do
      use Plug.Builder, init_mode: Phoenix.plug_init_mode()
      import Phoenix.Endpoint

      Module.register_attribute(__MODULE__, :phoenix_sockets, accumulate: true)

      if force_ssl = Phoenix.Endpoint.__force_ssl__(__MODULE__, var!(config)) do
        plug Plug.SSL, force_ssl
      end

      if var!(config)[:debug_errors] do
        use Plug.Debugger,
          otp_app: @otp_app,
          banner: {Phoenix.Endpoint.RenderErrors, :__debugger_banner__, []},
          style: [
            primary: "#EB532D",
            logo: "data:image/png;base64,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"
          ]
      end

      # Compile after the debugger so we properly wrap it.
      @before_compile Phoenix.Endpoint
      @phoenix_render_errors var!(config)[:render_errors]
    end
  end

  defp server() do
    quote location: :keep, unquote: false do
      @doc """
      Returns the child specification to start the endpoint
      under a supervision tree.
      """
      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      @doc """
      Starts the endpoint supervision tree.
      """
      def start_link(_opts \\ []) do
        Phoenix.Endpoint.Supervisor.start_link(@otp_app, __MODULE__)
      end

      @doc """
      Returns the endpoint configuration for `key`

      Returns `default` if the key does not exist.
      """
      def config(key, default \\ nil) do
        case :ets.lookup(__MODULE__, key) do
          [{^key, val}] -> val
          [] -> default
        end
      end

      @doc """
      Reloads the configuration given the application environment changes.
      """
      def config_change(changed, removed) do
        Phoenix.Endpoint.Supervisor.config_change(__MODULE__, changed, removed)
      end

      @doc """
      Generates the endpoint base URL without any path information.

      It uses the configuration under `:url` to generate such.
      """
      def url do
        Phoenix.Config.cache(__MODULE__,
          :__phoenix_url__,
          &Phoenix.Endpoint.Supervisor.url/1)
      end

      @doc """
      Generates the static URL without any path information.

      It uses the configuration under `:static_url` to generate
      such. It falls back to `:url` if `:static_url` is not set.
      """
      def static_url do
        Phoenix.Config.cache(__MODULE__,
          :__phoenix_static_url__,
          &Phoenix.Endpoint.Supervisor.static_url/1)
      end

      @doc """
      Generates the endpoint base URL but as a `URI` struct.

      It uses the configuration under `:url` to generate such.
      Useful for manipulating the URL data and passing it to
      URL helpers.
      """
      def struct_url do
        Phoenix.Config.cache(__MODULE__,
          :__phoenix_struct_url__,
          &Phoenix.Endpoint.Supervisor.struct_url/1)
      end

      @doc """
      Returns the host for the given endpoint.
      """
      def host do
        Phoenix.Config.cache(__MODULE__,
          :__phoenix_host__,
          &Phoenix.Endpoint.Supervisor.host/1)
      end

      @doc """
      Generates the path information when routing to this endpoint.
      """
      def path(path) do
        Phoenix.Config.cache(__MODULE__,
          :__phoenix_path__,
          &Phoenix.Endpoint.Supervisor.path/1) <> path
      end

      @doc """
      Generates the script name.
      """
      def script_name do
        Phoenix.Config.cache(__MODULE__,
          :__phoenix_script_name__,
          &Phoenix.Endpoint.Supervisor.script_name/1)
      end

      @doc """
      Generates a route to a static file in `priv/static`.
      """
      def static_path(path) do
        Phoenix.Config.cache(__MODULE__, :__phoenix_static__,
                             &Phoenix.Endpoint.Supervisor.static_path/1) <>
        elem(static_lookup(path), 0)
      end

      @doc """
      Generates a base64-encoded cryptographic hash (sha512) to a static file
      in `priv/static`. Meant to be used for Subresource Integrity with CDNs.
      """
      def static_integrity(path) do
        elem(static_lookup(path), 1)
      end

      @doc """
      Returns a two item tuple with the first item being the `static_path`
      and the second item being the `static_integrity`.
      """
      def static_lookup(path) do
        Phoenix.Config.cache(__MODULE__, {:__phoenix_static__, path},
                             &Phoenix.Endpoint.Supervisor.static_lookup(&1, path))
      end
    end
  end

  @doc false
  def __force_ssl__(module, config) do
    if force_ssl = config[:force_ssl] do
      Keyword.put_new(force_ssl, :host, {module, :host, []})
    end
  end

  @doc false
  defmacro __before_compile__(%{module: module}) do
    sockets = Module.get_attribute(module, :phoenix_sockets)
    otp_app = Module.get_attribute(module, :otp_app)
    instrumentation = Phoenix.Endpoint.Instrument.definstrument(otp_app, module)

    dispatches =
      for {path, socket, socket_opts} <- sockets,
          {path, type, conn_ast, socket, opts} <- socket_paths(module, path, socket, socket_opts) do
        quote do
          defp do_handler(unquote(path), conn, _opts) do
            {unquote(type), unquote(conn_ast), unquote(socket), unquote(Macro.escape(opts))}
          end
        end
      end

    quote do
      defoverridable [call: 2]

      # Inline render errors so we set the endpoint before calling it.
      def call(conn, opts) do
        conn = put_in conn.secret_key_base, config(:secret_key_base)
        conn = put_in conn.script_name, script_name()
        conn = Plug.Conn.put_private(conn, :phoenix_endpoint, __MODULE__)

        try do
          super(conn, opts)
        rescue
          e in Plug.Conn.WrapperError ->
            %{conn: conn, kind: kind, reason: reason, stack: stack} = e
            Phoenix.Endpoint.RenderErrors.__catch__(conn, kind, reason, stack, @phoenix_render_errors)
        catch
          kind, reason ->
            stack = System.stacktrace()
            Phoenix.Endpoint.RenderErrors.__catch__(conn, kind, reason, stack, @phoenix_render_errors)
        end
      end

      @doc false
      def __sockets__, do: unquote(Macro.escape(sockets))

      @doc false
      def __handler__(%{path_info: path} = conn, opts), do: do_handler(path, conn, opts)

      unquote(instrumentation)

      unquote(dispatches)
      defp do_handler(_path, conn, opts), do: {:plug, conn, __MODULE__, opts}
    end
  end

  defp socket_paths(endpoint, path, socket, opts) do
    paths = []
    websocket = Keyword.get(opts, :websocket, true)
    longpoll = Keyword.get(opts, :longpoll, false)

    paths =
      if websocket do
        config = Phoenix.Socket.Transport.load_config(websocket, Phoenix.Transports.WebSocket)
        {conn_ast, match_path} = socket_path(path, config)
        [{match_path, :websocket, conn_ast, socket, config} | paths]
      else
        paths
      end

    paths =
      if longpoll do
        config = Phoenix.Socket.Transport.load_config(longpoll, Phoenix.Transports.LongPoll)
        plug_init = {endpoint, socket, config}
        {conn_ast, match_path} = socket_path(path, config)
        [{match_path, :plug, conn_ast, Phoenix.Transports.LongPoll, plug_init} | paths]
      else
        paths
      end

    paths
  end

  defp socket_path(path, config) do
    end_path_fragment = Keyword.fetch!(config, :path)

    {vars, path} =
      String.split(path <> "/" <> end_path_fragment, "/", trim: true)
      |> Enum.join("/")
      |> Plug.Router.Utils.build_path_match()

      conn_ast =
        if vars == [] do
          quote do
            conn
          end
        else
          params_map = {:%{}, [], Plug.Router.Utils.build_path_params_match(vars)}
          quote do
            params = unquote(params_map)
            %{conn | path_params: params, params: params}
          end
        end

    {conn_ast, path}
  end

  ## API

  @doc """
  Defines a websocket/longpoll mount-point for a socket.

  Note: for backwards compatibility purposes, the `:websocket`
  and `:longpoll` options only have an effect if the socket
  given as argument has no `transport` declarations in it.

  ## Options

    * `:websocket` - controls the websocket configuration.
      Defaults to `true`. May be false or a keyword list
      of options. See "Shared configuration" and
      "WebSocket configuration" for the whole list

    * `:longpoll` - controls the longpoll configuration.
      Defaults to `false`. May be true or a keyword list
      of options. See "Shared configuration" and
      "Longpoll configuration" for the whole list

    * `:shutdown` - the maximum shutdown time of each channel
      when the endpoint is shutting down. Applies only to
      channel-based sockets

  ## Examples

      socket "/ws", MyApp.UserSocket

      socket "/ws/admin", MyApp.AdminUserSocket,
        longpoll: true,
        websocket: [compress: true]

  ## Path params

  It is possible to include variables in the path, these will be
  available in the `params` that are passed to the socket.

      socket "/ws/:user_id", MyApp.UserSocket,
        websocket: [path: "/project/:project_id"]

  Note: This feature is not supported with the Cowboy 1 adapter.

  ## Shared configuration

  The configuration below can be given to both `:websocket` and
  `:longpoll` keys:

    * `:path` - the path to use for the transport. Will default
       to the transport name ("/websocket" or "/longpoll")

    * `:serializer` - a list of serializers for messages. See
      `Phoenix.Socket` for more information

    * `:transport_log` - if the transport layer itself should log and,
      if so, the level

    * `:check_origin` - if we should check the origin of requests when the
      origin header is present. It defaults to true and, in such cases,
      it will check against the host value in `YourApp.Endpoint.config(:url)[:host]`.
      It may be set to `false` (not recommended) or to a list of explicitly
      allowed origins.

          check_origin: ["https://example.com",
                         "//another.com:888", "//other.com"]

      Note: To connect from a native app be sure to either have the native app
      set an origin or allow any origin via `check_origin: false`

    * `:code_reloader` - enable or disable the code reloader. Defaults to your
      endpoint configuration

    * `:connect_info` - a list of keys that represent data to be copied from
      the transport to be made available in the user socket `connect/3` callback

      The valid keys are:

        * `:peer_data` - the result of `Plug.Conn.get_peer_data/1`
        * `:headers` - all request headers
        * `:uri` - a `%URI{}` with information from the conn
        * `{:session, session_config}` - the session information from `Plug.Conn`.
          The `session_config` is an exact copy of the arguments given to `Plug.Session`.
          This requires the "_csrf_token" to be given as request parameter with
          the value of `URI.encode_www_form(Plug.CSRFProtection.get_csrf_token())`
          when connecting to the socket. Otherwise the session will be `nil`.

      Arbitrary keywords may also appear following the above valid keys, which
      is useful for passing custom connection information to the socket.

      For example:

          socket "/socket", AppWeb.UserSocket,
            websocket: [
              connect_info: [:peer_data, :headers, :uri, session: [store: :cookie]]
            ]

      With arbitrary keywords:

          socket "/socket", AppWeb.UserSocket,
            websocket: [
              connect_info: [:uri, custom_value: "abcdef"]
            ]


  ## Websocket configuration

  The following configuration applies only to `:websocket`.

    * `:timeout` - the timeout for keeping websocket connections
      open after it last received data, defaults to 60_000ms

    * `:max_frame_size` - the maximum allowed frame size in bytes.
      Supported from Cowboy 2.3 onwards, defaults to "infinity"

    * `:compress` - whether to enable per message compresssion on
      all data frames, defaults to false

  ## Longpoll configuration

  The following configuration applies only to `:longpoll`:

    * `:window_ms` - how long the client can wait for new messages
      in its poll request

    * `:pubsub_timeout_ms` - how long a request can wait for the
      pubsub layer to respond

    * `:crypto` - options for verifying and signing the token, accepted
      by `Phoenix.Token`. By default tokens are valid for 2 weeks

  """
  defmacro socket(path, module, opts \\ []) do
    # Tear the alias to simply store the root in the AST.
    # This will make Elixir unable to track the dependency
    # between endpoint <-> socket and avoid recompiling the
    # endpoint (alongside the whole project ) whenever the
    # socket changes.
    module = tear_alias(module)

    quote do
      @phoenix_sockets {unquote(path), unquote(module), unquote(opts)}
    end
  end

  @doc false
  defmacro instrument(endpoint_or_conn_or_socket, event, runtime \\ Macro.escape(%{}), fun) do
    compile = Phoenix.Endpoint.Instrument.strip_caller(__CALLER__) |> Macro.escape()

    quote do
      case Phoenix.Endpoint.Instrument.extract_endpoint(unquote(endpoint_or_conn_or_socket)) do
        nil -> unquote(fun).()
        endpoint -> endpoint.instrument(unquote(event), unquote(compile), unquote(runtime), unquote(fun))
      end
    end
  end

  @doc """
  Checks if Endpoint's web server has been configured to start.

    * `otp_app` - The OTP app running the endpoint, for example `:my_app`
    * `endpoint` - The endpoint module, for example `MyApp.Endpoint`

  ## Examples

      iex> Phoenix.Endpoint.server?(:my_app, MyApp.Endpoint)
      true

  """
  def server?(otp_app, endpoint) when is_atom(otp_app) and is_atom(endpoint) do
    Phoenix.Endpoint.Supervisor.server?(otp_app, endpoint)
  end

  defp tear_alias({:__aliases__, meta, [h|t]}) do
    alias = {:__aliases__, meta, [h]}
    quote do
      Module.concat([unquote(alias)|unquote(t)])
    end
  end
  defp tear_alias(other), do: other
end
