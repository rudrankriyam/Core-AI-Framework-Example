# Model Asset Policy

Core AI Lab intentionally keeps a small number of bundled model resources for
local Chatterbox and diarization workflows. Those assets are allowed only when
their provenance and license are documented, and large binary payloads must be
stored through Git LFS rather than normal Git blobs.

## Current tracked large assets

As of this audit, the only tracked files over 10 MiB in the working tree are
Git LFS-attributed `main.mlirb` resources:

| Size | Path |
| ---: | --- |
| 234 MiB | `CoreAILab/Resources/Chatterbox/ChatterboxTurboS3Gen.aimodel/main.mlirb` |
| 233 MiB | `CoreAILab/Resources/Chatterbox/ChatterboxTurboT3TransformerInt4.aimodel/main.mlirb` |
| 117 MiB | `CoreAILab/Resources/Chatterbox/ChatterboxTurboT3Embeddings.aimodel/main.mlirb` |
| 42 MiB | `CoreAILab/Resources/Chatterbox/ChatterboxTurboVocoder.aimodel/main.mlirb` |
| 14 MiB | `CoreAILab/Resources/Diarization/CAMPPlus192_float16_600f.aimodel/main.mlirb` |

Do not rewrite repository history to remove older blobs without an owner-level
cleanup plan. History cleanup needs coordination because it changes every clone,
branch, tag, fork, and open pull request.

## Adding or refreshing assets

- Prefer documented fetch or conversion steps over committing generated weights.
- Keep external model downloads outside the repository unless a bundled fixture
  is explicitly required for product behavior or tests.
- Store any intentional large binary asset through Git LFS and document its
  source, license, and generation command in the nearest README or notice file.
- Do not commit build products, downloaded checkpoints, local virtual
  environments, result bundles, or ad-hoc exported model directories.
- Run the large-file guard before pushing:

  ```bash
  python3 Scripts/check_large_files.py
  ```

The guard fails when a tracked file over 10 MiB is not covered by a Git LFS
attribute. `.gitattributes` already routes common Core AI, Core ML, tensor, and
checkpoint formats through Git LFS for future commits.
