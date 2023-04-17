%% -*- coding: utf-8 -*-
-module(wterm_javascript).

-compile([{parse_transform, lager_transform}]).

-description('erlang calls to eval user side javascript').


-export([eval/2, console/2]).



%% @doc send a msg to execute some javascript on the client browser
eval(WSPid, JavaScript) ->
  erlang:send(WSPid, {eval, JavaScript}).


console(WSPid, Text) ->
  JavaScript = ["console.log('",Text,"');"],
  erlang:send(WSPid, JavaScript).
