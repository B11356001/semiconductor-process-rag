# ADR-001: Embedding Model Selection

## Context
本系統處理的資料具有以下特性：

- 中英混雜術語
- 高密度縮寫與設備代號
- 短技術片語頻繁出現
- 同名 defect 在不同 process stage 中語義不同
- retrieval 結果需與 metadata filter 與 reranker 配合

因此 embedding model 的選擇不能只看一般語意搜尋表現，還必須考慮：
1. 術語與縮寫對齊能力
2. 中英混合文本表現
3. 與 hybrid retrieval 的相容性
4. 部署與維護成本

## Decision
採用 BGE-M3 作為主要 embedding model。

## Status
Accepted

## Alternatives Considered

### Option A: BGE-M3
**Pros**
- 對多語與中英混雜術語較友善
- 對短技術片語、縮寫與檢索任務表現穩定
- 適合與 BM25 / metadata filter 組成 hybrid retrieval

**Cons**
- 需自行管理 embedding pipeline
- 模型版本更新與部署維護成本較高

### Option B: text-embedding-3-small
**Pros**
- API 使用簡單
- 成本較低
- 易於快速整合作業原型

**Cons**
- 對高度領域化縮寫與專有名詞的可控性較低
- 若要針對半導體術語做額外調整，彈性較少

### Option C: text-embedding-3-large
**Pros**
- 一般語意表現強
- 對複雜查詢可能有較穩定的向量表示

**Cons**
- 成本較高
- 對本作業而言，提升未必足以抵銷成本
- 仍需額外依賴 metadata 與 reranker 才能處理製程階段混淆

## Why This Decision Was Chosen
本作業重點不是追求最方便的 API，而是展示 domain-driven retrieval 設計。  
BGE-M3 較符合半導體場景中：
- 多語術語
- 縮寫對齊
- 技術片語檢索
- hybrid retrieval 擴充性

因此選擇 BGE-M3 作為主要 embedding model，並保留未來以商用 embedding API 做 baseline 對照評估的空間。

## Consequences

### Positive
- 有利於中英混雜術語對齊
- 更適合技術短語與 defect 名稱檢索
- 與 hybrid retrieval 設計一致
- 有助於展示領域化系統規劃能力

### Negative
- 部署與維護較複雜
- 與 API 型 embedding 相比，初期整合成本較高
- 若無標準 benchmark，模型優勢需靠後續 evaluation 證明