我们是这样使用rebar更新Erlang代码的
========
在公司的Erlang团队中，我们采用rebar来管理依赖、构建、自动化测试、部署和升级。前面的
几个话题网上已经能搜到不少介绍的文章，这里就不做赘述了。本文主要集中介绍我们采用
rebar进行产品热更的实践，当然，如果你有更好、更方便的方法，欢迎交流。

### 目标
先来介绍目标, 假设第一个release版本为'1.0.0.0', 我需要这样的一个工具，它可以简单地执
行`upgrade.sh -n upgrade_demo -v 1.0.0.1`就将产品热更到新的版本。

### 问题
从rebar的wiki中我们能找到一个更新代码的简单教程，遗憾的是，在试用的时候总会有报错。
例如，它可以从1.0.0.0升级到1.0.0.1, 但是再往1.0.0.2升级的时候就会有异常抛出。通过翻rebar的
代码发现里边有一处明显的[bug](https://github.com/rebar/rebar/pull/303)。

### DEMO

#### 准备工作

OK, 下面我们用一个简单的例子来说明：

为了让读者有个感性的认识, 本repo demo分支的[commits](https://github.com/terrencehan/rebar_upgrade_demo/commits/demo)
仔细按照下文的步骤进行了调整，如果你熟悉git，希望能帮你节省一些时间。

首先你需要下载一个新版本的rebar（至少包含#commit [899d60c](https://github.com/rebar/rebar/commit/899d60cdb0e9238cff954add30c2f27e3644e0be)）。

为demo新建文件夹：

    mkdir upgrade_demo
    cd upgrade_demo
    mv path/to/your/new/rebar ./

创建app[#commit](https://github.com/terrencehan/rebar_upgrade_demo/commit/9e8f83cfb178cf331b434f8d09134e6bc884ed3c)

    ./rebar create-app appid=upgrade_demo

修改原始的版本号为'1.0.0.0'[#commit](https://github.com/terrencehan/rebar_upgrade_demo/commit/31bb12cdda2ea309437bdd210d9cb485ac8cb2d2)

    $EDITOR src/upgrade_demo.app.src
    ## 把vsn tuple中的默认版本号由1改为1.0.0.0保存即可

在`upgrade_demo_app.erl`中添加测试程序[#commit](https://github.com/terrencehan/rebar_upgrade_demo/commit/e74116cd25094244260e361cda5e067f4e1be267)

    $EDITOR src/upgrade_demo_app.erl

发布前准备node[#commit](https://github.com/terrencehan/rebar_upgrade_demo/commit/82dc6780eab06aa93a86c36f64d17d9d83d068a4)

    mkdir rel
    cd rel
    ../rebar create-node nodeid=upgrade_demo

这里生成的`rel/files/install_upgrade.escript`不符合需求，简单修改一下[#commit](https://github.com/terrencehan/rebar_upgrade_demo/commit/1a3eb1634f2ef15d709b4b5106993e93ff9a09cc)

    $EDITOR files/install_upgrade.escript

调整`reltool.config`中app位置[#commit](https://github.com/terrencehan/rebar_upgrade_demo/commit/7721f419d39b1ca74dc4e97b6f104fac587920f6)

    $EDITOR reltool.config

添加[升级辅助脚本](https://github.com/terrencehan/rebar_upgrade_demo/blob/demo/scripts/upgrade.sh)
和[rpc脚本](https://github.com/terrencehan/rebar_upgrade_demo/blob/demo/rpc_test.erl)

为了避免修改代码中版本号的繁琐，这里创建了两个.template文件，并设置锚点[#commit](https://github.com/terrencehan/rebar_upgrade_demo/commit/3c2f0611332d44499af7a2a1e627e90523ad4669)

另外在测试的时候发现目前rebar在处理nodetool有一处和文件位置相关的简单bug, 简单处理一下[#commit](https://github.com/terrencehan/rebar_upgrade_demo/commit/661faf14964d7c5e019d406ffa7a139ec3fe58d6)
并且调整了升级脚本（因为在我们这里产品的代码是放在apps/里面的，这和此demo代码树层级不符合）[#commit](https://github.com/terrencehan/rebar_upgrade_demo/commit/4c42ad783caa0e2046113fc723811f6651389019)

#### 升级测试

好了，经过上面有些麻烦的准备工作，下面我们可以体验简单的热更操作了。

现在使用master和demo分支应该都可以。

发布1.0.0.0

    cd path/to/upgrade_demo/
    ./reabr compile
    cd rel
    ../rebar generate

现在你应该在'当前目录(rel/)'中有`upgrade_demo`文件夹。

启动node

    cd path/to/upgrade_demo/
    ./rel/upgrade_demo/bin/upgrade_demo start

通过测试脚本调用hello()函数

    ./rpc_test.erl

输出结果

    hello() result: 1

修改hello()函数

    $EDITOR src/upgrade_demo_app.erl

    diff --git a/src/upgrade_demo_app.erl b/src/upgrade_demo_app.erl
    index 905e2fc..bcf7bc9 100644
    --- a/src/upgrade_demo_app.erl
    +++ b/src/upgrade_demo_app.erl
    @@ -16,4 +16,4 @@ stop(_State) ->
         ok.

     hello() ->
    -    1.
    +    2.

执行升级脚本, 升级到1.0.0.1版本

    ./scripts/upgrade.sh -n upgrade_demo -v 1.0.0.1

通过测试脚本调用hello()函数

    ./rpc_test.erl

输出结果

    hello() result: 2

再次修改hello()函数(因为之前这里有处不能继续升级的bug，重复测试一下，保证没有问题)

    $EDITOR src/upgrade_demo_app.erl

    diff --git a/src/upgrade_demo_app.erl b/src/upgrade_demo_app.erl
    index 905e2fc..bcf7bc9 100644
    --- a/src/upgrade_demo_app.erl
    +++ b/src/upgrade_demo_app.erl
    @@ -16,4 +16,4 @@ stop(_State) ->
         ok.

     hello() ->
    -    2.
    +    3.

执行升级脚本, 升级到1.0.0.1版本

    ./scripts/upgrade.sh -n upgrade_demo -v 1.0.0.2

通过测试脚本调用hello()函数

    ./rpc_test.erl

输出结果

    hello() result: 3

### __END__
至此你应该可以比较简洁的使用rebar热更产品了，当然，如果你发现了有什么不对的地方或者
有更好的方法，欢迎[交流](https://github.com/terrencehan/rebar_upgrade_demo/issues)。
