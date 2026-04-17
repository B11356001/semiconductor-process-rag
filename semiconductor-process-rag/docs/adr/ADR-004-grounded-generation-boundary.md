# ADR-004: Restrict Generation to Grounded Evidence

## Context
在製程異常場景中，若 LLM 依一般常識補全答案，可能產生未經證據支持的成因推測或錯誤修正建議，造成高 hallucination 風險。

## Decision
生成層只允許使用 evidence pack 中的內容；若證據不足，系統必須明示不確定性或拒答。

## Status
Accepted

## Alternatives Considered

### Option A: Free-form Generation
**Pros**
- 回答較流暢
- 使用者主觀感受可能較好

**Cons**
- 高 hallucination 風險
- 容易把不適用的製程知識套到錯誤上下文

### Option B: Grounded Generation with Soft Evidence Requirement
**Pros**
- 較有彈性
- 可在 evidence 不完整時仍提供候選答案

**Cons**
- 容易讓模型補出未被明確支持的內容
- 不確定性界線模糊

### Option C: Grounded Generation with Explicit Abstain Policy
**Pros**
- 可追溯性高
- 更適合高風險技術領域
- 可明確控制 unsupported claim

**Cons**
- 回答較保守
- evidence 不足時使用者體感較差

## Why Not Chosen
未採 free-form generation，因為本系統屬於工程知識輔助場景，錯誤建議成本高。  
未採 soft evidence requirement 作為主策略，因為半導體場景的 hallucination 常表現為 cross-context misapplication，不適合放寬證據門檻。

## Expected Trade-offs
嚴格 grounded generation 可提升 faithfulness 與 citation quality，但會：
- 增加 abstain 比例
- 使回答較保守
- 需要更完整的 retrieval evidence

## Operational Consequences
- 必須定義 minimum evidence threshold
- 必須在 answer template 中加入 uncertainty disclosure
- evaluation 必須額外追蹤 abstain accuracy

## Consequences
### Positive
- 降低 hallucination
- 提高可追溯性
- 更符合工程知識輔助系統定位

### Negative
- 回答可能較保守
- 在 evidence 不足時會出現較多 abstain
- 使用者可能覺得答案不夠「聰明」

## Decision Drivers
本決策主要由以下因素驅動：

1. 半導體 troubleshooting 屬高風險知識輔助場景
2. hallucination 在本領域常表現為 cross-context misapplication，而不只是捏造內容
3. citation-required generation 有助於提高可追溯性與人工複核效率
4. abstain policy 能避免 evidence insufficiency 下的錯誤自信回答

## Failure Conditions
若出現以下情況，需重新檢討本決策：

- abstain rate 過高，導致系統實用性明顯下降
- 使用者大量需要 exploratory answer 而非嚴格 grounded answer
- retrieval evidence 長期不足，使生成層過度保守
- citation requirement 顯著降低回答可讀性

## Revisit Triggers
當以下條件成立時，應重新評估 generation boundary：

- evidence quality 顯著提升，可支撐更細緻的生成策略
- 已建立更成熟的 confidence calibration 機制
- 使用情境從工程輔助轉向教育或探索型問答