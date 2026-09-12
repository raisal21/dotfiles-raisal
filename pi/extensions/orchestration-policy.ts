import type { BuildSystemPromptOptions, ExtensionAPI } from "@earendil-works/pi-coding-agent";

type Profile = "off" | "normal" | "research" | "review" | "autonomous";

const PROFILE_NAMES: Profile[] = ["off", "normal", "research", "review", "autonomous"];
const PROFILE_ENTRY = "orchestration-profile";

const PROFILE_GUIDANCE: Record<Exclude<Profile, "off">, string> = {
	normal: `
- Prefer direct built-in tools for focused coding tasks.
- Use specialized tools only when their capability is needed.
- Use the workflow tool for genuinely decomposable, multi-angle work, not for a simple edit.
- Keep /goal, deep research, and other long-running operations explicit; do not start them merely because they are available.
`,
	research: `
- For current or external facts, prefer web_search, source_check, and fetch_content when available.
- For multi-source or multi-angle research, use the workflow tool or /deep-research and preserve citations.
- Separate sourced facts from inference. Do not use web tools for facts already available in the repository.
- Keep file mutations explicit and verify claims before presenting them as facts.
`,
	review: `
- Treat the task as an audit: inspect broadly, identify concrete evidence, and distinguish findings from suggestions.
- For substantial or multi-angle code review, use the workflow tool or /code-review.
- Prefer read-only inspection first. Verify important findings with tests, call sites, or a second code path.
- Report file paths, severity, impact, and a practical fix for each finding.
`,
	autonomous: `
- The user has opted into autonomous routing for this session, but do not invent work or continue after the requested objective is complete.
- Use the workflow tool for decomposable work when it improves coverage.
- Use /goal or Goal mode only when the user explicitly requests a persistent objective, repeated execution, or work-until-verified behavior.
- Still stop for destructive, irreversible, security-sensitive, or materially ambiguous decisions.
`,
};

function isProfile(value: unknown): value is Profile {
	return typeof value === "string" && PROFILE_NAMES.includes(value as Profile);
}

function readStoredProfile(ctx: { sessionManager: { getBranch(): readonly unknown[] } }): Profile {
	let profile: Profile = "normal";

	for (const entry of ctx.sessionManager.getBranch()) {
		if (!entry || typeof entry !== "object") continue;
		const candidate = entry as {
			type?: unknown;
			customType?: unknown;
			data?: unknown;
		};

		if (candidate.type !== "custom" || candidate.customType !== PROFILE_ENTRY) continue;
		if (!candidate.data || typeof candidate.data !== "object") continue;
		const stored = (candidate.data as { profile?: unknown }).profile;
		if (isProfile(stored)) profile = stored;
	}

	return profile;
}

function hasTool(options: BuildSystemPromptOptions, ...names: string[]): boolean {
	const selected = new Set(options.selectedTools ?? []);
	return names.some((name) => selected.has(name));
}

function capabilityGuidance(options: BuildSystemPromptOptions): string {
	const lines: string[] = [];

	if (hasTool(options, "ask_user_question")) {
		lines.push("- `ask_user_question`: use when the request requires a real user decision or clarification.");
	}
	if (hasTool(options, "bm25_search")) {
		lines.push("- `bm25_search`: use for semantic codebase search when exact grep is insufficient.");
	}
	if (hasTool(options, "web_search", "fetch_content", "source_check")) {
		lines.push("- Web tools: use for current external information, URLs, and source verification; do not browse by default.");
	}
	if (hasTool(options, "workflow")) {
		lines.push("- `workflow`: use for decomposable work that benefits from independent agents or staged verification.");
	}
	if (hasTool(options, "kb_search", "kb_read")) {
		lines.push("- `kb_search`/`kb_read`: search the configured knowledge vault before creating or repeating durable notes.");
	}

	return lines.length > 0 ? `\nAvailable routing capabilities:\n${lines.join("\n")}` : "";
}

function buildPolicy(profile: Exclude<Profile, "off">, options: BuildSystemPromptOptions): string {
	return `

## Orchestration Policy

The user selected the **${profile}** routing profile for this session. Choose the smallest capable mechanism, keep expensive or autonomous operations deliberate, and explain when a specialized tool is unavailable.
${PROFILE_GUIDANCE[profile]}${capabilityGuidance(options)}
`;
}

function updateStatus(ctx: { ui: { setStatus(id: string, text: string | undefined): void } }, profile: Profile): void {
	ctx.ui.setStatus("orchestration-policy", profile === "off" ? "route: off" : `route: ${profile}`);
}

function capabilitySummary(activeTools: string[]): string {
	const active = new Set(activeTools);
	const capabilities: string[] = [];

	if (active.has("ask_user_question")) capabilities.push("questions");
	if (active.has("bm25_search")) capabilities.push("code-search");
	if (["web_search", "fetch_content", "source_check"].some((name) => active.has(name))) capabilities.push("web");
	if (active.has("workflow")) capabilities.push("workflow");
	if (["kb_search", "kb_read"].some((name) => active.has(name))) capabilities.push("napkin");

	return capabilities.length > 0 ? capabilities.join(", ") : "direct tools only";
}

export default function orchestrationPolicy(pi: ExtensionAPI) {
	let profile: Profile = "normal";

	pi.on("session_start", async (_event, ctx) => {
		profile = readStoredProfile(ctx);
		updateStatus(ctx, profile);
	});

	pi.on("before_agent_start", async (event) => {
		if (profile === "off") return;

		return {
			systemPrompt: event.systemPrompt + buildPolicy(profile, event.systemPromptOptions),
		};
	});

	pi.registerCommand("profile", {
		description: "Show or set the orchestration routing profile",
		getArgumentCompletions: (prefix) => {
			const values = ["status", ...PROFILE_NAMES];
			const matches = values.filter((value) => value.startsWith(prefix.toLowerCase()));
			return matches.length > 0 ? matches.map((value) => ({ value, label: value })) : null;
		},
		handler: async (args, ctx) => {
			const requested = args.trim().toLowerCase();

			if (!requested || requested === "status") {
				ctx.ui.notify(
					`Routing profile: ${profile}\nActive routing capabilities: ${capabilitySummary(pi.getActiveTools())}\nProfiles: ${PROFILE_NAMES.join(", ")}`,
					"info",
				);
				return;
			}

			if (!isProfile(requested)) {
				ctx.ui.notify(`Unknown profile: ${requested}. Use: ${PROFILE_NAMES.join(", ")}`, "error");
				return;
			}

			profile = requested;
			pi.appendEntry(PROFILE_ENTRY, { profile });
			updateStatus(ctx, profile);
			ctx.ui.notify(
				profile === "off"
					? "Orchestration policy disabled."
					: `Orchestration profile set to ${profile}. Specialized tools remain available; routing is now guided for this session.`,
				"info",
			);
		},
	});
}
