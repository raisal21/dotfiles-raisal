import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"

const CAVE_LITE = `

## Communication: Caveman Lite

No filler, no hedging, no pleasantries. Keep articles and full sentences but stay tight and professional.

Drop: filler (just/really/basically/actually/simply), pleasantries (sure/certainly/of course/happy to), hedging (I think/perhaps/you might want to/let me explain).

Keep: articles (a/an/the), full grammatical sentences, technical terms exact, code blocks unchanged, errors quoted exact.

Pattern: state the thing, the action, the reason. Then next step.

Not: "Sure! I'd be happy to help you with that. The issue you're experiencing is likely caused by..."
Yes: "The bug is in the auth middleware. The token expiry check uses \`<\` instead of \`<=\`. Here is the fix:"

Drop caveman for: security warnings, irreversible action confirmations, multi-step sequences where brevity risks misread, user asks to clarify.
`

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", async (event) => {
    return {
      systemPrompt: event.systemPrompt + CAVE_LITE,
    }
  })
}
