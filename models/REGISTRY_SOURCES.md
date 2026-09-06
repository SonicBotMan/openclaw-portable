# qwen3:1.7b — registry provenance

Fetched 2026-09-06 from `registry.ollama.ai/v2/library/qwen3/manifests/1.7b`.

| component | digest | size | notes |
| --- | --- | --- | --- |
| config | sha256:517ccaff…14ad8 | 487 B | format gguf, family qwen3, type 2.0B, file Q4_K_M |
| model (gguf) | sha256:3d0b7905…6ab6 | 1,359,279,776 B | == local `qwen3-1.7b.Q4_K_M.gguf` (sha256-verified) |
| template | sha256:ae370d88…fc4 | 1,723 B | qwen3 chat template, `.Tools`-aware (Jinja form embedded in GGUF) |
| params | sha256:cff3f395…bdb | 120 B | `{"repeat_penalty":1,"stop":["<\|im_start\|>","<\|im_end\|>"],"temperature":0.6,"top_k":20,"top_p":0.95}` |
| license | sha256:d18a5cc7…a12 | 11,338 B | Apache License 2.0 (full text in `LICENSE.qwen3`) |

Runtime parameters (`temperature` etc.) are served by Ollama's per-architecture
defaults; with `PARAMETER jinja true` the GGUF-embedded template is used, which
matches the registry template behavior.

If the upstream `qwen3:1.7b` registry entry ever changes (new template/params),
re-verify against this table and re-export the GGUF from the same digest.
