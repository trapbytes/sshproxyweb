%% -*- coding: utf-8 -*-
-module(wterm_app_sup).

-compile([{parse_transform, lager_transform}]).

-behaviour(supervisor).


-export([start_link/0]).

-export([init/1]).


-define(WORKER_WAIT, 10500).


-spec start_link() -> {ok, pid()}.
start_link() ->
   supervisor:start_link({local, ?MODULE}, ?MODULE, []).



init([]) ->
   %
   MaxRestart = 1,
   MaxTime = 3600,
   Procs = [],

   {ok, {{one_for_one, MaxRestart, MaxTime}, Procs}}.
