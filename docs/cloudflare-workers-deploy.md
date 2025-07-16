# DevFlow·AI — Hugo × PaperMod 全流程 + Cloudflare Workers 部署指北（2025 最新版）

---

## 一、环境准备

| 工具                      | 最低版本                     | 作用              | macOS 安装示例          |
| ----------------------- | ------------------------ | --------------- | ------------------- |
| **Go**                  | 1.22                     | Hugo Module 拉包  | `brew install go`   |
| **Hugo Extended**       | 0.148+                   | 静态站点生成          | `brew install hugo` |
| **Node + Wrangler CLI** | Node 18 + Wrangler 4.24  | Workers 构建 & 发布 | `npm i -g wrangler` |
| **Git**                 | 任意                       | 版本管理            | `brew install git`  |

---

## 二、新建 Hugo 项目

```bash
hugo new site devflow --format toml
cd devflow
git init
hugo mod init devflow.950288.xyz/blog     # 初始化 Go module
```

---

## 三、添加 PaperMod（Hugo Module 方式）

**`config/_default/module.toml`**

```toml
[[imports]]
path = "github.com/adityatelange/hugo-PaperMod"
```

接着拉包并清理：

```bash
hugo mod get github.com/adityatelange/hugo-PaperMod
hugo mod tidy
```

---

## 四、TOML 配置目录

> Hugo 支持把不同 root‑key 拆成多个文件，官方示例结构如下：`config/_default/hugo.toml · params.toml · menus.toml`([gohugo.io][1])

```
config/
└── _default/
    ├── hugo.toml     # 站点元信息
    ├── params.toml   # 主题参数
    └── menus.toml    # 菜单（可选）
└── production/
    └── hugo.toml     # 生产环境覆盖项
```

**`config/_default/hugo.toml`（核心）**

```toml
baseURL  = "https://devflow.950288.xyz/"
title    = "DevFlow·AI"
paginate = 10
defaultContentLanguage = "zh"

[module]
  [[module.imports]]
    path = "github.com/adityatelange/hugo-PaperMod"

[outputs]
  home = ["HTML","RSS","JSON"]
```

**`config/_default/params.toml`**

```toml
[homeInfoParams]
Title    = "DevFlow·AI"
Subtitle = "在 JS、CSS 与智能代理的涌流中划桨，分享一线前端工程实践与自动化工作流"

ShowReadingTime = true
defaultTheme    = "auto"
```

如需 GA 等生产机密，只放 `config/production/hugo.toml`；构建时：

```bash
hugo --environment production --minify
```

---

## 五、首篇文章 & 本地预览

```bash
hugo new posts/hello-world.md
# 编辑 front‑matter 将 draft = false
hugo server -D         # http://localhost:1313
```

---

## 六、Cloudflare Workers 部署（方案二：Assets + Worker 脚本）

### 1. 项目文件概览

```
devflow/
├── build.sh           # Hugo 构建脚本（无 root 权限）
├── wrangler.jsonc     # Workers 配置
├── src/
│   └── worker.js      # Worker 逻辑（可选 API、中间件…）
├── config/…           # Hugo 配置目录
└── public/            # Hugo 输出（构建后生成）
```

### 2. `build.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
HUGO_VERSION="0.148.1"

if command -v hugo &>/dev/null; then
  echo "➡ Using $(hugo version)"
  hugo --gc --minify
  exit 0
fi

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
[[ "$ARCH" == "x86_64" ]] && ARCH="amd64"
[[ "$ARCH" == "arm64"  ]] && ARCH="arm64"

TMPDIR="$(mktemp -d)"
curl -sSL -o "${TMPDIR}/hugo.tgz" \
  "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_${OS}-${ARCH}.tar.gz"
tar -xf "${TMPDIR}/hugo.tgz" -C "${TMPDIR}" hugo
"${TMPDIR}/hugo" --gc --minify
```

### 3. `src/worker.js`

```js
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // 示例：简单 API
    if (url.pathname.startsWith("/api/time")) {
      return new Response(JSON.stringify({ now: Date.now() }), {
        headers: { "content-type": "application/json" },
      });
    }

    // 未匹配则回退到静态资源
    return env.ASSETS.fetch(request);
  },
};
```

### 4. `wrangler.jsonc`

```jsonc
{
  "name": "devflow-ai",
  "account_id": "YOUR_ACCOUNT_ID",
  "compatibility_date": "2025-07-16",

  "main": "src/worker.js",

  "build": { "command": "bash build.sh" },

  "assets": {
    "directory": "./public",
    "binding": "ASSETS",
    "html_handling": "auto-trailing-slash",
    "not_found_handling": "404-page"
  },

  "routes": [
    { "pattern": "devflow.950288.xyz/*", "custom_domain": true }
  ]
}
```

> 只要你 **声明了 `binding` 就必须同时有 `main` 脚本**；否则 Wrangler 会报 *“Cannot use assets with a binding in an assets‑only Worker”* 错误。官方文档明确 `binding` 让脚本里用 `env.ASSETS.fetch()` 访问资源；若未提供脚本应仅写 `directory`。([Cloudflare Docs][2])
> 静态资源优先，匹配失败才执行 Worker 脚本([Cloudflare Docs][3])

### 5. 运行 & 部署

```bash
wrangler dev        # 本地沙盒 http://127.0.0.1:8787
wrangler deploy     # 推送到 devflow-ai.workers.dev
```

---

## 七、Git 忽略 & CI

`.gitignore` 关键行：

```
/public/
/resources/
/.wrangler/
```

GitHub Actions (`.github/workflows/deploy.yml`)：

```yaml
name: Deploy
on:
  push: { branches: [main] }
jobs:
  worker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm i -g wrangler
      - run: wrangler deploy --minify
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CF_API_TOKEN }}
```

---

## 八、后续可拓展

| 需求                  | 做法                                                                 |
| ------------------- | ------------------------------------------------------------------ |
| **评论 / Algolia 搜索** | 直接在 `params.toml` 打开 PaperMod 对应开关                                 |
| **自定义短代码 / 组件**     | 新建 `themes/devflow-components` 并在 `module.toml` 再加一条 `[[imports]]` |
| **中间件 / 鉴权**        | 在 `src/worker.js` 里先处理，再 `env.ASSETS.fetch()`                      |
| **多环境变量**           | `wrangler secrets put` 储存在 Workers KV，中脚本读取                        |

---

### 参考文档

* Hugo 配置目录官方说明
* Cloudflare Static Assets 配置与 binding 规则
* Worker‑Assets 调度顺序

---

至此，你已拥有：

1. **面向未来的 Hugo TOML 分层配置**
2. **Hugo Modules 管理的 PaperMod**
3. **Cloudflare Workers Static Assets + Worker 脚本** 同站部署

直接跟着步骤复制黏贴即可快速上线 ✨。如有新功能需求，随时回来加料！

[1]: https://gohugo.io/configuration/introduction/ "Introduction"
[2]: https://developers.cloudflare.com/workers/static-assets/binding/ "Configuration and Bindings · Cloudflare Workers docs"
[3]: https://developers.cloudflare.com/workers/static-assets/routing/worker-script/ "Worker script · Cloudflare Workers docs"
