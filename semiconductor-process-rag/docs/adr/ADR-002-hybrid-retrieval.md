# ADR-002: Adopt Hybrid Retrieval Instead of Pure Vector RAG

## Context
半導體製程知識中，大量關鍵訊息來自：
- alarm code
- defect code
- 設備型號
- recipe parameter
- chamber name
- process stage

這些資訊不一定適合只靠語意向量比對。

## Decision
採用 Hybrid Retrieval，結合：
- vector retrieval
- BM25 / keyword retrieval
- metadata filtering

## Status
Accepted

## Consequences
### Positive
- 可同時處理語意相似與精準字串匹配
- 降低縮寫、代號、參數名漏召回問題
- 更適合異常分析情境

### Negative
- 檢索流程較複雜
- 需要額外設計合併與排序策略
- 除錯成本上升