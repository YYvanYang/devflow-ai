# DevFlow·AI

> **在 JS、CSS 与智能代理的涌流中划桨  
> 分享一线前端工程实践与自动化工作流**  

一个采用 **Hugo Extended + PaperMod** 搭建的技术博客，专注前端开发与 AI Agent（Cursor、Claude Code、Kiro 等）辅助编程实践。静态文件托管在 **Cloudflare Workers Static Assets**，同时通过 Worker 脚本为同域 `/api/*` 路由提供轻量后端能力。

---

## 快速启动

### 1. 环境要求

| 工具 | 版本 | macOS 安装示例 |
| ---- | ---- | -------------- |
| Go | ≥ 1.22 | `brew install go` |
| Hugo Extended | ≥ 0.148 | `brew install hugo` |
| Node.js | ≥ 18 | `brew install node` |
| Wrangler CLI | ≥ 4.24 | `npm i -g wrangler` |

> **已有 Hugo？** `hugo version` ≥ 0.148 即可省略脚本中自动下载步骤。  

### 2. 本地预览

```bash
git clone https://github.com/yourname/devflow.git
cd devflow

# 初始化 Hugo Module 依赖
hugo mod tidy

# 启动本地服务器（含草稿）
hugo server -D
```

浏览器访问 [http://localhost:1313](http://localhost:1313) 查看效果，修改内容将自动热更新。

---

## 云端部署（概览）

> 详细步骤请见 [docs/cloudflare-workers-deploy.md](docs/cloudflare-workers-deploy.md)。

```bash
# 登录并绑定账户
wrangler login

# 预览（Miniflare 沙盒）
wrangler dev

# 构建 & 发布到 Workers + 自定义域
wrangler deploy
```

* **静态资源**：`hugo --gc --minify` 输出到 `public/`，由 Wrangler 的 `[assets]` 配置自动上传到边缘节点。
* **动态脚本**：`src/worker.js` 注入中间件 / API，并通过 `env.ASSETS.fetch()` 回退静态文件。

---

## 目录结构

```
devflow/
├─ config/                  # Hugo TOML 分层配置
│  └─ _default/
│     ├─ hugo.toml
│     ├─ params.toml
│     └─ menus.toml
├─ docs/
│  └─ cloudflare-workers-deploy.md
├─ src/
│  └─ worker.js             # 自定义 Worker 逻辑
├─ public/                  # Hugo 输出（构建时生成）
├─ build.sh                 # 无需 sudo 的 Hugo 构建脚本
├─ wrangler.jsonc           # Cloudflare Workers 配置
└─ README.md
```

---

## 常用脚本

| 命令                | 功能                           |
| ----------------- | ---------------------------- |
| `hugo mod tidy`   | 拉取 & 清理 Hugo Module 依赖       |
| `hugo server -D`  | 本地开发预览（含草稿）                  |
| `bash build.sh`   | 执行 Hugo 构建（CI / Wrangler 调用） |
| `wrangler dev`    | 本地 Workers 沙盒预览              |
| `wrangler deploy` | 部署到 Cloudflare Workers       |

---

## TODO

* [ ] Algolia instant‑search 集成
* [ ] 评论系统（Giscus）
* [ ] 每日构建 Github Actions CI
* [ ] 自动化 Lighthouse 报告

---

## License

MIT © 2025 Yvan
