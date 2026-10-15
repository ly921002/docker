# docker（box64 容器：免特权，显式 box64 跑 x86_64）

`ghcr.io/ly921002/docker-empty:box64` —— 一个 **arm64 容器**，用 **box64** 跑 **x86_64** 程序。

- 基底：`ubuntu:22.04` **arm64**
- 从源码编译 **box64 / box32**（`ARM_DYNAREC=ON`、`BOX32=ON`，JIT/Dynarec，比 QEMU 快很多）
- 附带 `binfmt-support` / `qemu-user-static` / 常用构建与网络工具
- 由 `.github/workflows/main.yml` 自动构建并推送到 GHCR（`linux/arm64`）

## 方式：免特权，显式 box64

**不注册 binfmt、不用 `privileged`**。x86_64 程序用显式调用运行：

```bash
box64 <x86_64程序> [参数...]
```

box64 是纯用户态翻译器，已装在镜像 `PATH` 中，跑 x86_64 不需要任何特权、也不动内核 `binfmt_misc`。

## 用法

```bash
docker login ghcr.io                 # 镜像私有；同源 GitHub 账号可拉
docker compose up -d                 # 构建(如需)并常驻运行
docker exec -it box64 bash           # 进容器
box64 ./steamcmd                     # 容器内显式跑 x86_64 程序
# 或不进交互 shell，直接：
docker exec box64 box64 /root/steamcmd/steamcmd +quit
```

## 要点

- **仅 arm64 宿主**有效；x86_64 宿主原生跑 x86_64，无需 box64。
- **动态链接**的 x86_64 程序（如 SteamCMD）所需的 **x86_64 运行库**（`libc6` / `libstdc++6` / `libgcc-s1` / `libcurl4` / `libssl3` / `zlib1g` 的 amd64 版）已**固化进镜像**（amd64 多架构），拉起来即可直接跑动态 x86_64 程序；静态链接的开箱即用。
- **想要「直接 `./程序`」透明运行**（不用每次加 `box64` 前缀）？那需要容器内注册 binfmt + `privileged`，属于另一种方式，可参考 [ly921002/gsm-box64](https://github.com/ly921002/gsm-box64) 的 `start-x64.sh`。

## 文件

- `Dockerfile` —— box64 基础镜像构建
- `docker-compose.yml` —— 常驻 box64 容器（免特权，显式 `box64`）
