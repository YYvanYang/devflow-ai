export default {
    async fetch(request, env) {
      // 若匹配不到静态文件，就交给 assets 处理
      return env.ASSETS.fetch(request);
    },
  };
  