from wl3pc import docs_check

WORKFLOW = """---
type: guide
status: active
updated: 2026-10-01
tags: [workflow]
---
# Workflow

## Tag vocabulary

- `workflow`
- `research`
"""


def write(root, relative, text):
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def messages(root):
    return [(p.path, p.message, p.warning) for p in docs_check.run(root)]


def test_valid_links_anchors_and_properties(tmp_path):
    write(tmp_path, "docs/04-development/workflow.md", WORKFLOW)
    write(tmp_path, "docs/00-home.md", "# Home\n\n[Workflow](04-development/workflow.md#tag-vocabulary)\n"
          "[Note](02-research/a%20note.md) [web](https://example.com)\n")
    write(tmp_path, "docs/02-research/a note.md", "---\ntype: research\nstatus: draft\nupdated: 2026-10-01\n"
          "tags:\n  - research\n---\n# A note\n\n```\n[not a link](missing.md) [[nor this]]\n```\n"
          "`[code](missing.md)` back to [home](../00-home.md)\n")
    assert messages(tmp_path) == []


def test_reports_broken_links_wikilinks_absolute_paths_and_anchors(tmp_path):
    write(tmp_path, "docs/04-development/workflow.md", WORKFLOW)
    write(tmp_path, "docs/00-home.md", "# Home\n[x](missing.md)\n[[wiki]]\n[abs](/home/user/x.md)\n"
          "[a](04-development/workflow.md#no-such-heading)\n[w](04-development/workflow.md)\n")
    found = {m for _, m, _ in messages(tmp_path)}
    assert "broken link 'missing.md'" in found
    assert "wikilink found; use a relative Markdown link" in found
    assert "absolute or file link '/home/user/x.md'; use a relative path" in found
    assert any(m.startswith("missing anchor #no-such-heading") for m in found)


def test_property_and_tag_rules_and_orphans(tmp_path):
    write(tmp_path, "docs/04-development/workflow.md", WORKFLOW)
    write(tmp_path, "docs/00-home.md", "# Home\n[w](04-development/workflow.md)\n")
    write(tmp_path, "docs/02-research/orphan.md", "---\ntype: research\nstatus: draft\nupdated: Oct 1\n"
          "tags: [made-up]\n---\n# Orphan\n")
    write(tmp_path, "docs/90-templates/research.md", "---\ntype: research\nstatus: draft\nupdated: {{date}}\n"
          "tags: []\n---\n# {{title}}\n")
    found = messages(tmp_path)
    paths = {(p, m) for p, m, _ in found}
    assert ("docs/02-research/orphan.md", "`updated` must be YYYY-MM-DD, got 'Oct 1'") in paths
    assert any("'made-up' is not in the vocabulary" in m for _, m in paths)
    assert ("docs/02-research/orphan.md", "note is not linked from any other note", True) in found
    assert not any(p.startswith("docs/90-templates") for p, _ in paths)


def test_slugify_matches_github_style():
    assert docs_check.slugify("ADR-0001: Native port strategy") == "adr-0001-native-port-strategy"
    assert docs_check.slugify("Verified `code` & *emphasis*") == "verified-code--emphasis"
