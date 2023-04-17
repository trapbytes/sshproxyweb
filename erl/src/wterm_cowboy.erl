-module(wterm_cowboy).

-compile([{parse_transform, lager_transform}]).


-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).




%%
%%
start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).


%%
%%
init([]) ->
  MaxRestart = wterm_utils:get_config_val(cowboy_max_restart),
  MaxTime = wterm_utils:get_config_val(cowboy_max_time),
  %
  {ok, {{one_for_one, MaxRestart, MaxTime}, []}}.
