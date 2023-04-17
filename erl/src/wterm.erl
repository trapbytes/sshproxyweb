% -*- coding: utf-8 -*-
-module(wterm).

-mode(compile).

-compile([{parse_transform, lager_transform}]).


-export([main/1]).



option_spec_list() ->
 % get current user 
 CurrentUser = case os:getenv("USER") of
                 false -> "user";
                 User  -> User
               end,
 %
 [
  {help, $?, "help", undefined, "Show program options"},
  {port, $p, "port", string, "wterm host port"},
  {verbose, $v, "verbose", integer, "Verbosity level"},
  {username, $u, "username", {string,CurrentUser}, "Username to execute as"}
 ].



handle_options(Args) ->
  OptSpec = option_spec_list(),
  io:format("For command line: ~p~n"
            "getopt:parse/2 returns:~n~n", [Args]),

  case getopt:parse(OptSpec, Args) of
    {ok, {Options, NonOptArgs}} ->
         io:format("Options:~n  ~p~n~nNon-option arguments:~n  ~p~n", [Options, NonOptArgs]);

    {error, {OptReason, Data}} ->
         io:format("Error: ~s ~p~n~n", [OptReason, Data]), getopt:usage(OptSpec, "ex1")
  end,
  ok.



main([]) ->
  getopt:usage(option_spec_list(), escript:script_name());


main(Args) ->
   try
     application:ensure_all_started(lager),

     application:start(getopt),

     application:start(sasl),

     application:start(ssh),

     application:start(crypto),

     handle_options(Args),

     application:ensure_all_started(cowboy),

     application:start(wterm)

   catch 
     _:Reason ->
       io:format("Error: reason '~p'\n", [Reason]),
       usage()
   end.



usage() ->
    io:format("Usage: wterm <ARGS>\n"),
    halt(1).
