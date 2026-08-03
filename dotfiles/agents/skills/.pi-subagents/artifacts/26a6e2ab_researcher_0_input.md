# Task for researcher

Research how to enable video file thumbnail previews in GNOME Nautilus on NixOS (and generally Linux/GNOME).

Focus on PRIMARY SOURCES only:
- GNOME Nautilus docs/source
- GNOME thumbnailer specs (Thumbnail Managing Standard, gnome-desktop thumbnail factory)
- totem-video-thumbnailer / ffmpegthumbnailer / gst-libav package docs
- NixOS/nixpkgs modules and packages related to nautilus thumbnails
- xdg thumbnailer desktop files

Answer:
1. What component generates video thumbnails for Nautilus?
2. What packages must be installed on NixOS/Home Manager for video thumbs?
3. Exact nix config snippets (systemPackages, home.packages, services, programs)
4. Common failure modes (missing codecs, sandbox, cache dir ~/.cache/thumbnails, MIME handlers, flatpak vs system nautilus)
5. How to regenerate/clear thumbnails
6. Whether gst-libav, ffmpegthumbnailer, totem, gnome.totem, or nautilus-python is needed

Write full findings with citations (URLs + what each source says) suitable for saving to RESEARCH_nautilus-video-thumbnails.md

Return structured findings with:
- Summary recommendation for NixOS user running Nautilus
- Required packages
- Config
- Verify steps
- Sources

---
**Output:**
Write your findings to exactly this path: /home/aron/coding/nix-aron/dotfiles/agents/skills/.pi-subagents/artifacts/outputs/26a6e2ab/research.md
This path is authoritative for this run.
Ignore any other output filename or output path mentioned elsewhere, including output destinations in the base agent prompt, system prompt, or task instructions.

## Acceptance Contract
Acceptance level: attested
Completion is not accepted from prose alone. End with a structured acceptance report.

Criteria:
- criterion-1: Return concrete findings with file paths and severity when applicable

Required evidence: review-findings, residual-risks

Finish with a fenced JSON block tagged `acceptance-report` in this shape:
Use empty arrays when no items apply; array fields contain strings unless object entries are shown.
`criteriaSatisfied[].status` must be exactly one of: satisfied, not-satisfied, not-applicable.
`commandsRun[].result` must be exactly one of: passed, failed, not-run.
`manualNotes` and `notes` are optional strings; an empty string means no note and does not satisfy `manual-notes` evidence.
```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "specific proof"
    }
  ],
  "changedFiles": [
    "src/file.ts"
  ],
  "testsAddedOrUpdated": [
    "test/file.test.ts"
  ],
  "commandsRun": [
    {
      "command": "command",
      "result": "passed",
      "summary": "short result"
    }
  ],
  "validationOutput": [
    "validation output or concise summary"
  ],
  "residualRisks": [
    "none"
  ],
  "noStagedFiles": true,
  "diffSummary": "short description of the diff",
  "reviewFindings": [
    "blocker: file.ts:12 - issue found, or no blockers"
  ],
  "manualNotes": "anything else the parent should know"
}
```