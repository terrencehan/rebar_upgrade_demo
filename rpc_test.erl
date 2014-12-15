#!/usr/bin/env escript
%%! -name upgrade_demo_test@127.0.0.1 -setcookie upgrade_demo

main(_Args) ->
    R = rpc:call('upgrade_demo@127.0.0.1', upgrade_demo_app, hello, []),
    io:format("hello() result: ~p~n", [R]).
