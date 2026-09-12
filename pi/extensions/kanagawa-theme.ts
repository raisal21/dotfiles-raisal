import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const THEME_NAME = "kanagawa-dragon";

function applyTheme(ctx: any, notify = false) {
  if (ctx?.hasUI === false) return;
  const setTheme = ctx?.ui?.setTheme;
  if (typeof setTheme !== "function") return;

  const result = setTheme.call(ctx.ui, THEME_NAME);
  if (notify && result && !result.success) {
    ctx.ui.notify(`Failed to apply theme ${THEME_NAME}: ${result.error}`, "error");
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    applyTheme(ctx, true);
  });

  pi.registerCommand("kanagawa", {
    description: "Force-apply the kanagawa-dragon theme",
    handler: async (_args, ctx) => {
      applyTheme(ctx, true);
      ctx.ui.notify(`Applied theme: ${THEME_NAME}`, "success");
    },
  });
}
