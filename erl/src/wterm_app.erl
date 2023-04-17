%% -*- coding: utf-8 -*-
-module(wterm_app).

-compile([{parse_transform, lager_transform}]).

-behaviour(application).

-export([start/2, stop/1]).



-define(OUR_LISTENER, sshproxyweb_http_listener).

-define(INDEX_HTML, "/static/index.html").





%%
%%
start(_Type, _Args) ->
  %
  PrivDir = wterm_utils:priv_dir(),
  lager:info("wterm_app: PRIV_DIR '~p'", [PrivDir]),
  %
  case wterm_utils:read_configuration_file() of
     {ok, FileData} ->
          wterm_utils:create_config_ets_table(),
          wterm_utils:write_config_to_ets_table(sshproxyweb, FileData);
     {error, _} -> 
          lager:debug("Error: could not read configuration file"),
          halt(1)
  end,
  %
  IndexRes = PrivDir ++ ?INDEX_HTML,
  %
  DirMimeTypes = [{mimetypes, cow_mimetypes, all}],
  %
  WwwPaths = [{"/",          cowboy_static,  {file, IndexRes}},
              {"/ws/[...]",  ws_int_handler, []},
              {"/ws2/[...]", ws_usr_handler, []},
              {"/[...]",     cowboy_static,  {dir, PrivDir, DirMimeTypes}}
             ],
  %
  Dispatch = cowboy_router:compile([ {'_', WwwPaths} ]),
  %
  try
    [Port] = wterm_utils:get_config_val(cowboy_port),

    CowPort = [{port, Port}],

    CowEnv = #{env => #{dispatch => Dispatch}},

    {ok, _} = cowboy:start_clear(?OUR_LISTENER, CowPort, CowEnv),

    wterm_app_sup:start_link()
  catch
    _:Reason ->
      lager:debug("Error: no webserver port supplied reason '~p'\n", [Reason]),
      halt(1)
  end.



%%
%%
stop(State) ->
  lager:debug("sshproxyweb: STOP '~p'~n", [State]),
  ok = cowboy:stop_listener(?OUR_LISTENER).
