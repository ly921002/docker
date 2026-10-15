#!/bin/bash
# ----------------------------------------------------------------------------
# register-box64.sh —— 在【本容器内】注册 box64 / box32 为 x86_64 的 binfmt 解释器
#
# 目的：让 docker-empty:box64 这个容器内部能透明运行 x86_64 程序（ELF 直接执行即可，
#       由 box64 翻译）。注册用的是【本容器自己的 box64】，服务本容器内的 x86_64 执行，
#       不是在宿主机做一次性全局注册。
#
# 运行环境：本镜像的特权容器内（compose 已 privileged: true；写 binfmt_misc 需要 SYS_ADMIN）。
# 说明：binfmt_misc 本质是内核级、全局的，但解释器路径指向【本容器的 box64】，
#       只有在本容器内 exec x86_64 时才会命中并成功；宿主机/其它容器并不因此获得 box64。
#       容器停止后规则仍留在内核但已失效（本容器 box64 路径消失），如需彻底清理：
#           echo -1 > /proc/sys/fs/binfmt_misc/box64
# ----------------------------------------------------------------------------
set -eu

echo ">> [box64 容器] 确保 binfmt_misc 已挂载"
if ! mountpoint -q /proc/sys/fs/binfmt_misc 2>/dev/null; then
  mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc || true
fi
[ -d /proc/sys/fs/binfmt_misc ] || { echo "!! /proc/sys/fs/binfmt_misc 不可用（需 privileged）"; exit 1; }

BOX64="$(command -v box64 || echo /usr/local/bin/box64)"
BOX32="$(command -v box32 || echo /usr/local/bin/box32)"

# ---------- 注册 box64（x86_64） ----------
echo ">> [box64 容器] 注册 box64 -> $BOX64"
MAGIC64=$'\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'
MASK64=$'\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff'
[ -e /proc/sys/fs/binfmt_misc/box64 ] && echo -1 > /proc/sys/fs/binfmt_misc/box64 2>/dev/null || true
# magic/mask 与 box64 官方一致，兼容 ET_EXEC(2) 与 ET_DYN(3)/PIE；
# 标志 OC：O 打开解释器保持 fd（本容器运行期间有效），C 透传凭据。
# 不用 F（fix-binary）——F 会让解释器在容器退出后仍常驻宿主内核，那正是要避免的。
printf ':box64:M::%s:%s:%s:OC\n' "$MAGIC64" "$MASK64" "$BOX64" > /proc/sys/fs/binfmt_misc/register 2>/dev/null || true

# ---------- 注册 box32（x86 32 位，可选） ----------
if [ -x "$BOX32" ]; then
  echo ">> [box64 容器] 注册 box32 -> $BOX32"
  MAGIC32=$'\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03\x00'
  MASK32=$'\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff'
  [ -e /proc/sys/fs/binfmt_misc/box32 ] && echo -1 > /proc/sys/fs/binfmt_misc/box32 2>/dev/null || true
  printf ':box32:M::%s:%s:%s:OC\n' "$MAGIC32" "$MASK32" "$BOX32" > /proc/sys/fs/binfmt_misc/register 2>/dev/null || true
fi

# ---------- 结果 ----------
echo "===== /proc/sys/fs/binfmt_misc ====="
ls -l /proc/sys/fs/binfmt_misc || true
if [ -e /proc/sys/fs/binfmt_misc/box64 ]; then
  echo "===== box64 规则 ====="
  cat /proc/sys/fs/binfmt_misc/box64
  echo ">> 本容器内 x86_64 程序将自动经 box64 运行。进入容器：docker exec -it box64 bash"
else
  echo "!! box64 注册失败（是否缺少特权？）。可改用显式调用：box64 <x86_64程序>（无需注册/特权）"
  exit 1
fi
