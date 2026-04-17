# ADR-003: Use Parent-Document Retrieval with Reranking

## Context
若只使用小 chunk 做最終回答，常會出現：
- 命中 symptom 但缺 cause
- 命中 cause 但缺 corrective action
- 命中局部片段但無 revision 與警告上下文

## Decision
採用「small chunk retrieval + parent-document expansion + reranker」策略。

## Status
Accepted

## Consequences
### Positive
- 保留小 chunk 命中率
- 生成時可取回較完整上下文
- reranker 可過濾語意相近但製程階段錯誤的片段

### Negative
- latency 增加
- parent-child mapping 需額外維護
- reranker 增加推論成本