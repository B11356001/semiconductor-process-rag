# ADR-003: Use Parent-Document Retrieval with Reranking

## Context
若只使用小 chunk 做最終回答，常會出現：
- 命中 symptom 但缺 cause
- 命中 cause 但缺 corrective action
- 命中局部片段但無 revision 與警告上下文

## Decision
採用「small chunk retrieval + parent-document expansion + reranker」策略。

## Status
### Alternatives Considered

#### Option A: Small Chunk Retrieval Only
**Pros**
- latency 較低
- 架構簡單

**Cons**
- 容易只召回 symptom 或 cause 的局部片段
- 缺少完整 corrective action 與 warning context

#### Option B: Large Chunk Retrieval
**Pros**
- 單次召回上下文較完整
- 不一定需要 parent expansion

**Cons**
- 容易降低精準命中率
- 不相關內容比例提高
- reranker 前的候選品質可能下降

#### Option C: Small Chunk + Parent Expansion + Reranker
**Pros**
- 保留小 chunk 的精準命中能力
- 生成前可回補完整上下文
- reranker 可排除 stage 不符的內容

**Cons**
- latency 增加
- parent-child mapping 需維護
- reranker 增加推論成本

### Why Not Chosen
未採 small chunk only，因為半導體 troubleshooting 常需要「symptom -> cause -> corrective action」完整鏈條，單一小塊常不足以支撐生成。  
未採 large chunk baseline 作為主方案，因為會稀釋檢索精度，增加不相關內容混入機率。

### Expected Trade-offs
此方案能改善 answer completeness 與 groundedness，但代價是：
- retrieval pipeline 較長
- parent-document lookup 成本增加
- reranker latency 需控制

### Operational Consequences
- 需要明確的 parent_doc_id mapping
- 需要保存 small chunk 與 parent doc 的關聯
- reranker 評估必須納入延遲與品質雙重指標

## Consequences
### Positive
- 保留小 chunk 命中率
- 生成時可取回較完整上下文
- reranker 可過濾語意相近但製程階段錯誤的片段

### Negative
- latency 增加
- parent-child mapping 需額外維護
- reranker 增加推論成本