#!/bin/bash

sudo yum install epel-release

cat - <<\EOF
EPEL（Extra Packages for Enterprise Linux）是一个由 Fedora 社区维护的项目，它提供了一组对企业级 Linux 发行版额外的高质量包，这些包不会与官方仓库中的包冲突。要在 RHEL、CentOS 或其他兼容的发行版上安装 EPEL 仓库，请按照以下步骤操作：

对于 **CentOS 7** （或相似的旧版本），运行以下命令：

```bash
sudo yum install epel-release
```

对于 **CentOS 8** ，如果你使用的是 CentOS 8。则可以通过下面的命令安装 EPEL 仓库：

```bash
sudo dnf install epel-release
```

装 EPEL 之后，你可以像使用任何其他 yum 仓库一样使用它来搜索、安装和管理软件包。

请注意，如果您使用的是 RHEL 或基于 RHEL 的其他发行版（如 Oracle Linux），您可能需要先进行其他步骤，如订阅相关的渠道或仓库。在一些最小化安装的系统环境中，如果 `epel-release` 包不在默认仓库可用，你也可以直接下载该软件包并手动安装：

对于 CentOS 7，使用：

```bash
sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
```

对于 RHEL 7 或类似系统，确保你已订阅了额外的软件包通道，然后安装 `epel-release`：

```bash
sudo subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"
sudo yum install epel-release
```

另外，对于较新的 Fedora 版本，EPEL 仓库可能默认不可用或不兼容，因为 Fedora 已经提供了大多数包。不过，EPEL 项目针对 RHEL 和 CentOS 的版本通常会比较活跃。

完成安装后，可以通过运行 `yum repolist` 或 `dnf repolist` 来检查 EPEL 仓库是否已成功添加到系统。
EOF
