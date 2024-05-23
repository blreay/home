#!/bin/bash

#为了在基于 RPM 的 Linux 发行版（如 CentOS、RHEL）上安装 devtoolset-9，你需要确保系统已经配置了能够访问到 devtoolset-9 的仓库。devtoolset-9 是 Red Hat Developer Toolset 的一部分，它提供了比系统默认仓库更新的开发工具（如 GCC）。在 CentOS 和 RHEL 上，这通常意味着启用 Software Collections (SCL) 仓库。
#以下步骤展示了如何在 CentOS 或 RHEL 系统上启用 SCL 仓库，并安装 devtoolset-9。
#启用 SCL 仓库
#对于 CentOS，你可以使用以下命令启用 SCL 仓库：
sudo yum install centos-release-scl

#如果你使用的是 RHEL (Red Hat Enterprise Linux)，你可能需要先订阅到额外的软件仓库，使用 RHEL 的用户可以这样启用：
#sudo yum-config-manager --enable rhel-server-rhscl-7-rpms

sudo yum install devtoolset-9-gcc
sudo yum install devtoolset-9-gdb
sudo yum install devtoolset-9-gcc-c++ #need install g++

#记住，使用 scl enable devtoolset-9 bash 启动的 shell 会话是临时的
#当你退出会话或者开启新的终端窗口时，devtoolset-9 的环境设置不会自动应用。
#如果你希望在每次登录时自动启用 devtoolset-9，你可以将 scl enable devtoolset-9 bash 命令添加到你的 ~/.bashrc 或 ~/.bash_profile 文件中。
#以上步骤在 CentOS 和 RHEL 7 上通常可以工作。操作步骤可能会根据你的具体系统版本而稍有不同。此外，RHEL 用户可能需要有活跃的订阅才能访问到所有的软件仓库。

# use deltoolset
scl enable devtoolset-9 bash

yum info ${package_name}

cat - <<EOF

为了确定一个已安装的软件包是从哪个 yum 仓库安装的，你可以使用 `yum` 工具的一些选项来查询包信息。下面的命令将显示软件包的来源仓库：

```bash
yum info <package_name>
```

或者，具体要显示安装来源：

```bash
yum list installed <package_name>
```

在上述命令中，请将 `<package_name>` 替换为你感兴趣的软件包的名称。这些命令将显示软件包的详细信息，包括版本号、安装大小、仓库名等。

例如：

```bash
yum list installed devtoolset-9-gcc
```

在显示的信息中，你会找到一列名为“Repository”的输出，它会告诉你软件包的来源仓库。

另外，如果你希望看到所有已安装包的信息以及它们的仓库来源，可以执行：

```bash
yum list installed
```

如果你正在使用的是较新的系统，或者你有 `dnf` 可用，那你也可以使用与之类似的 `dnf` 命令得到同样的信息：

```bash
dnf repoquery --installed --queryformat '%{ui_from_repo} %{name}-%{version}-%{release}' <package_name>
```

在上述 `dnf` 命令中，`%{ui_from_repo}` 代表仓库名称，`%{name}`、`%{version}` 和 `%{release}` 分别代表软件包的名称、版本和发布号。这个命令不仅会告诉你软件包来自哪个仓库，还会告诉你包的完整名称和版本信息。如果你想查询所有已安装软件包的来源仓库，请省略 `<package_name>` 参数。
EOF
