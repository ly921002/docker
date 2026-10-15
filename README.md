# docker（box64 容器：让这个容器本身能跑 x86_64）

`ghcr.io/ly921002/docker-empty:box64` —— 一个 **arm64 容器**，内部通过 **box64** 透明运行 **x86_64** 程序。

- 基底：`ubuntu:22.04` **arm64**
- 从源码编译 **box64 / box32**（`ARM_DYNAREC=ON`、`BOX32=ON`，JIT/Dynarec，比 QEMU 快很多）
- 附带 `binfmt-support` / `qemu-user-static` / 常用构建与网络工具
- 由 `.github/workflows/main.yml` 自动构建并推送到 GHCR（`linux/arm64`）

## 用法（compose，常驻 box64 容器）

```bash
docker login ghcr.io                 # 镜像私有；同源 GitHub 账号可拉
docker compose up -d                 # 构建(如需)并常驻运行
docker compose logs -f box64         # 看 box64 注册结果
docker exec -it box64 bash           # 进容器，直接跑 x86_64 程序（如 ./steamcmd）
```

容器启动时会在**本容器内**把 box64 注册为 x86_64 的 binfmt 解释器（`register-box64.sh`），
解释器用的是**本容器自己的 box64**，服务的是本容器内的 x86_64 执行——不是在宿主机做一次性全局注册。

## 要点

- **仅 arm64 宿主**有效；x86_64 宿主原生跑 x86_64，无需 box64。
- 需要 `privileged: true`（容器内写 `binfmt_misc` 要 `SYS_ADMIN`）；容器 restart 会重新注册。
- **动态链接**的 x86_64 程序（如 SteamCMD）还需 **x86_64 运行库**，本镜像未内置，需在容器内加：
  ```bash
  dpkg --add-architecture amd64 && apt-get update && apt-get install -y \
    libc6:amd64 libstdc++6:amd64 libgcc-s1:amd64 zlib1g:amd64
  ```
  （可参考 [ly921002/box64-arm64-deb](https://github.com/ly921002/box64-arm64-deb)；静态链接的 x86_64 程序开箱即用。）
- **不想用特权 / 完全不动 binfmt**：删掉 compose 里的 `privileged` 与注册步骤，改用显式调用
  `box64 <x86_64程序>`（box64 已装好，无需任何注册）。
- **清理注册**（`docker compose down` 后规则仍留在内核但已失效，可手动清）：
  ```bash
  echo -1 | sudo tee /proc/sys/fs/binfmt_misc/box64
  ```

## 文件

- `Dockerfile` —— box64 基础镜像构建
- `docker-compose.yml` —— 常驻 box64 容器（容器内注册 box64）
- `register-box64.sh` —— 容器内注册 box64 / box32 的脚本（compose 挂载使用）
