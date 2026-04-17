# ADR-004: Restrict Generation to Grounded Evidence

## Context
在製程異常場景中，若 LLM 依一般常識補全答案，可能產生未經證據支持的成因推測或錯誤修正建議，造成高 hallucination 風險。

## Decision
生成層只允許使用 evidence pack 中的內容；若證據不足，系統必須明示不確定性或拒答。

## Status
Accepted

## Consequences
### Positive
- 降低 hallucination
- 提高可追溯性
- 更符合工程知識輔助系統定位

### Negative
- 回答可能較保守
- 在 evidence 不足時會出現較多 abstain
- 使用者可能覺得答案不夠「聰明」