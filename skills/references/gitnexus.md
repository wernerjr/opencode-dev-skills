# GitNexus Guidance

Detect GitNexus through available MCP tools (`query`, `context`, `impact`, `trace`, or `detect_changes`), the `gitnexus` executable, or GitNexus skill files. Run `scripts/detect-capabilities.mjs` for a quiet local signal.

- `query`: find ranked execution flows for a concept.
- `context`: inspect a symbol's callers, callees, imports, and process membership.
- `impact`: measure upstream or downstream blast radius. Run it before editing a function, class, or method.
- `trace`: find a shortest call path between symbols.
- `detect_changes`: review changed symbols and affected flows before committing.
- Cypher: use only when the graph query needs relationships not covered by the focused tools.

If MCP does not respond, use the repository's normal search tools and say that graph evidence was unavailable. Do not reindex the world automatically. If the index is stale, suggest `gitnexus analyze` in the current repository and run it only if the user agrees.
