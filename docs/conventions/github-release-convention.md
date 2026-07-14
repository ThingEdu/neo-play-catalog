# GitHub Release Convention v1.0.0 (open-source NEO app repos)

How NEO app releases are published on GitHub. The release artifact itself is
specified in [`app-entry-convention.md`](app-entry-convention.md); this document
covers the GitHub side: tags, release entries, assets, and notes.

---

## 1. Repository

- **Public, open source** — the store only distributes apps whose source and
  packaging can be audited.
- The canonical repo lives in the **ThingEdu org** (not a personal fork); all
  URLs in scripts and store entries point at the org repo.
- Building the `.deb` on tag push via CI (GitHub Actions) is the recommended
  setup, so every release is reproducible from its tag.

## 2. Tags

- Release tags are **`vX.Y.Z`** — the `v` prefix on the tag only, never inside
  package metadata or asset file names.
- A tag is immutable: never move, delete, or reuse one. Fixes get a new version.

## 3. The release entry

- Created **from the tag** `vX.Y.Z`, titled `vX.Y.Z` (optionally with a short
  codename).
- **Assets**: the `.deb` named exactly **`<pkg>_<X.Y.Z>_<arch>.deb`**. Tools
  construct the download URL from this pattern:
  `https://github.com/<org>/<repo>/releases/download/vX.Y.Z/<pkg>_<X.Y.Z>_<arch>.deb`
- Never replace or re-upload an asset after publishing — the store pins its
  sha256. A broken asset means a new patch release.
- Mark work-in-progress builds as **Pre-release**; only full releases are
  candidates for the store.

## 4. Release notes

- A short, human-readable changelog: what changed for teachers/students
  (features, fixes), not raw commit titles.
- Vietnamese or bilingual is fine — the audience is the NEO community.

## 5. Checklist

- [ ] Tag `vX.Y.Z` pushed on the exact commit the `.deb` was built from.
- [ ] Release created from that tag with `<pkg>_<X.Y.Z>_<arch>.deb` attached.
- [ ] Release notes describe user-facing changes.
- [ ] Not a pre-release (for store submission).
