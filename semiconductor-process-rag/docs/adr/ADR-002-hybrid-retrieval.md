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

## Alternatives Considered

### Option A: Pure Vector Retrieval
**Pros**
- Pipeline 較簡單
- 維護成本較低

**Cons**
- 對 alarm code、defect code、parameter name 這類精準字串不穩
- 容易漏掉縮寫與設備代號
- 不利於高術語密度領域

### Option B: Vector Retrieval + Query Rewrite
**Pros**
- 可改善自然語言 query 的召回
- 不需維護多套索引

**Cons**
- query rewrite 可能引入額外誤差
- 對精確代碼與 metadata constraint 支援不足
- 仍難處理 process-stage 過濾

### Option C: Hybrid Retrieval
**Pros**
- 同時涵蓋語意召回與精準匹配
- 能與 metadata filter 搭配
- 較適合半導體 troubleshooting 場景

**Cons**
- 系統較複雜
- 需額外設計 merge 與 ranking 策略

## Why Not Chosen
未採 pure vector retrieval，因為半導體場景中大量關鍵資訊來自 alarm code、設備型號、參數名稱與 defect code，若僅依靠向量相似度，容易漏召回或錯召回。  
未採 vector + query rewrite 作為主方案，因為 rewrite 雖能改善自然語言表達，但無法取代 BM25 對精準代碼與縮寫的優勢。

## Expected Trade-offs
採 Hybrid Retrieval 可提升召回品質與 metadata 一致性，但代價是：
- merge logic 更複雜
- latency 較高
- 除錯成本增加

## Operational Consequences
- 必須維護 vector index 與 full-text index
- 必須設計 deduplication 與 score fusion
- 必須與 metadata filtering 一起測試

## Consequences
### Positive
- 可同時處理語意相似與精準字串匹配
- 降低縮寫、代號、參數名漏召回問題
- 更適合異常分析情境

### Negative
- 檢索流程較複雜
- 需要額外設計合併與排序策略
- 除錯成本上升

## Decision Drivers
本決策主要由以下因素驅動：

1. 半導體場景中存在大量精準字串查詢，例如 alarm code、defect code、parameter name、tool model
2. 純 vector retrieval 對縮寫與代碼召回不穩
3. metadata constraint 在 process-stage-sensitive 場景中屬於必要條件，而不是可選增強
4. query rewrite 雖可改善語句表達，但無法取代 BM25 對精準匹配的作用

## Failure Conditions
若出現以下情況，需重新檢討本決策：

- BM25 與 metadata filter 對召回品質提升不明顯
- Hybrid merge logic 帶來過高 latency
- score fusion 難以穩定調參
- 系統主要查詢型態轉向長篇自然語言描述，精準代碼查詢比例下降

## Revisit Triggers
當以下條件成立時，應重新評估是否維持 Hybrid Retrieval：

- 建立了更完整的 query rewrite 與 acronym normalization pipeline
- 有 benchmark 顯示 pure vector + reranker 已可達同等品質
- latency target 無法在現有架構下滿足