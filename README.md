我们是这样使用rebar更新Erlang代码的
========
在公司的Erlang团队中，我们采用rebar来管理依赖、构建、自动化测试、部署和升级。前面的
几个话题在最初接触rebar的时候网上已经能搜到不少介绍的文章，这里就不做赘述了。本文主要
集中介绍我们采用rebar进行产品热更的实践，当然，如果你有更好、更方便的方法，欢迎交流。

### 目标
先来介绍我们的目标, 假设我们的第一个release版本为'1.0.0.0', 我需要这样的一个工具，它可以
简单地执行`upgrade 1.0.0.1`就将热更升级到新的版本。

### 问题
从rebar的wiki中我们可以找到一个更新代码的简单教程，遗憾的是，在试用的时候总会有报错。
例如，可以从1.0.0.0升级到1.0.0.1但是再往1.0.0.2升级的时候就会有异常抛出。通过翻rebar的
代码可以看到里边有一处明显的[bug](https://github.com/rebar/rebar/pull/303)，看来这个
功能几乎没有人用过:(

### DEMO
Ok, 下面我们用一个简单的例子来说明：

为了让读者有个感性的认识, 本repo的[commit](https://github.com/terrencehan/rebar_upgrade_demo/commits/master)
仔细按照下文的步骤进行了调整，如果你熟悉 使用git，希望能帮你节省一些时间。

首先你需要下载一个新版本的rebar（至少包含commit [899d60c](https://github.com/rebar/rebar/commit/899d60cdb0e9238cff954add30c2f27e3644e0be)）。

为demo新建文件夹：

    mkdir upgrade_demo
    cd upgrade_demo
    mv path/to/your/new/rebar ./

创建app

    ./rebar create-app appid=upgrade_demo

修改原始的版本号为'1.0.0.0'

    $EDITOR vim src/upgrade_demo.app.src
    ## 把vsn tuple中的默认版本号由1改为1.0.0.0保存即可

发布demo

    mkdir rel
    cd rel
    ../rebar create-node nodeid=upgrade_demo

这里生成的`rel/files/install_upgrade.escript`不符合需求，简单修改了一下[diff]()
