# Semiconductor Process Troubleshooting RAG Specification

## 1. Scope
本系統聚焦於半導體製程異常分析與知識檢索，不處理即時設備控制，不直接下達機台操作命令，僅提供檢索、證據整理與解釋性回答。

## 2. Input Data Types
- SOP / operation manuals
- alarm code manuals
- troubleshooting guides
- incident reports
- defect taxonomy documents
- process glossary
- revision notes

## 3. Chunking Strategy
本系統採用「Markdown / section-aware + semantic atomization + parent-document retrieval」混合切分策略。

### 3.1 Why not fixed-length only
固定長度切塊容易把：
- 異常現象
- 成因
- 修正動作
- 警告條件

切散到不同 chunk，導致召回後無法形成完整可解釋證據。

### 3.2 Actual Strategy
1. 先依標題、章節、表格、條列清單做結構切分
2. 再將內容轉為知識原子：
   - symptom
   - defect_type
   - process_step
   - parameter
   - cause
   - corrective_action
3. 小 chunk 用於初步召回
4. parent document 用於生成階段補足上下文

## 4. Metadata Schema
每個 knowledge atom 至少包含：
- atom_id
- source_id
- parent_doc_id
- title
- content
- process_stage
- tool_name
- chamber
- material
- defect_type
- parameter_name
- revision
- authority_level
- language
- embedding_vector

## 5. Embedding Model
本規劃選擇 BGE-M3 作為主要 embedding model。

### Selection Rationale
- 適合中英混雜的技術術語
- 對縮寫、專有名詞、簡短技術片語較友善
- 有利於半導體文件中的多語與術語對齊

## 6. Vector Database
採用 PostgreSQL + pgvector。
理由：
- 與 relational metadata 易整合
- 易於同時處理 vector search 與 structured filter
- 適合作為課程作業的單一後端

## 7. Retrieval Pipeline
1. Query understanding
2. Acronym normalization
3. Hybrid retrieval
   - BM25 top-20
   - Vector top-20
   - Metadata filtered top-20
4. Merge and deduplicate
5. Parent-document expansion
6. Reranking top-15 -> top-5
7. Evidence pack generation
8. LLM grounded answer

## 8. Performance Targets
- Retrieval latency (p95): <= 1.2 sec
- End-to-end answer latency (p95): <= 4.0 sec
- Top-5 retrieval hit rate: >= 0.85
- Context precision@5: >= 0.80
- Faithfulness score: >= 0.90
- Answer completeness score: >= 0.80

## 9. Evaluation Plan

### 9.1 Evaluation Data Format
每筆 evaluation 樣本使用 JSONL 儲存，至少包含下列欄位：

- `id`: 題目唯一識別碼
- `query`: 使用者問題
- `query_type`: 題型，例如 symptom_to_cause、alarm_to_action、insufficient_evidence
- `expected_answer_intent`: 預期回答行為
- `expected_evidence`: 預期應召回的證據類型或文件
- `gold_constraints`: 必須符合的 metadata 條件，例如 process_stage、defect_type、parameter
- `must_include`: 回答中必須出現的要素
- `must_not_do`: 回答中不應出現的錯誤行為

此格式的目的不是只評估最終答案字面是否相同，而是評估：
1. 是否召回正確上下文
2. 是否遵守領域限制條件
3. 是否在證據不足時正確表達不確定性

### 9.2 Offline Evaluation Set Design
建立 50 筆黃金測試集，並依題型配比：

- 15 題 symptom -> possible cause
- 10 題 alarm / defect code -> corrective action
- 10 題 parameter drift -> evidence retrieval
- 5 題術語縮寫對齊與 acronym disambiguation
- 5 題 conflicting evidence / revision conflict
- 5 題 evidence insufficiency / abstain

每題需由人工標註：
- 正確的 process_stage
- 允許的 defect_type / parameter
- 預期應召回的證據類型
- 合理回答範圍
- 不可接受的 hallucination 類型

資料集切分方式：
- development set: 30 題
- validation set: 10 題
- held-out test set: 10 題

### 9.3 Retrieval Metrics
- Top-1 / Top-3 / Top-5 Hit Rate  
  定義：正確 evidence 是否出現在前 K 筆召回結果中

- Context Precision@5  
  定義：前 5 筆 evidence 中，符合 gold_constraints 的比例

- Context Recall@5  
  定義：gold evidence 類型中，有多少被前 5 筆召回覆蓋

- Metadata Constraint Match Rate  
  定義：召回結果是否符合 process_stage、tool_name、defect_type、revision 等限制條件

- Parent Coverage Rate  
  定義：small chunk 命中後，是否成功回收對應 parent document

### 9.4 Generation Metrics
- Faithfulness  
  回答中的主張是否都能被 evidence pack 支持

- Response Relevancy  
  回答是否真正對應使用者問題，而非泛泛談論相似主題

- Answer Completeness  
  回答是否涵蓋該題型要求的必要元素，例如原因、檢查項、引用來源、不確定性揭露

- Groundedness  
  回答是否建立在檢索到的證據上，而不是模型常識補全

- Abstain Accuracy  
  對 evidence insufficiency 題型，系統是否能正確拒答或要求補充上下文

### 9.5 Evaluation Framework and Workflow
使用 RAGAS 與 TruLens 分工評估：

- RAGAS：
  - context precision
  - context recall
  - response relevancy
  - faithfulness

- TruLens：
  - context relevance
  - groundedness
  - answer relevance

評估流程如下：
1. 對每題 query 執行 retrieval pipeline
2. 保存 top-k retrieved chunks、parent documents 與 final evidence pack
3. 執行 grounded generation，輸出 final answer
4. 以 RAGAS 計算 retrieval 與 answer 指標
5. 以 TruLens 補充 groundedness 與 answer relevance
6. 對低分樣本進行人工複核，標記失敗原因：
   - wrong process stage
   - wrong revision
   - missing corrective action
   - unsupported claim
   - should abstain but answered

## 10. Failure Modes
- 製程階段判錯
- 同名 defect 在不同工具上下文混淆
- 舊版文件召回優先於新版文件
- 單一 chunk 缺少完整 corrective action
- LLM 依常識補出未被證據支持的答案

## 11. Mitigation
- metadata hard filter
- source authority ranking
- revision-based weighting
- parent-document retrieval
- reranker
- abstain policy
- citation-required generation

## 12. Acceptance Criteria
本系統視為達標，需同時滿足：

1. Architecture 文件明確標示：
   - ETL
   - semantic chunking
   - embedding boundary
   - hybrid retrieval
   - parent-document retrieval
   - reranking intervention point
   - grounded generation

2. Specs 文件明確定義：
   - chunking strategy
   - metadata schema
   - retrieval pipeline
   - latency target
   - evaluation dataset format
   - retrieval / generation metrics
   - abstain policy

3. Repository 至少包含：
   - architecture
   - specs
   - 至少 3 份 ADR
   - whitepaper
   - schema
   - SQL
   - evaluation example

4. 資料結構需支援：
   - parent document
   - source authority
   - revision metadata
   - structured filtering

5. Offline evaluation 達標門檻：
   - Top-5 Hit Rate >= 0.85
   - Context Precision@5 >= 0.80
   - Faithfulness >= 0.90
   - Answer Completeness >= 0.80
   - Abstain Accuracy >= 0.85

6. 所有 final answers 必須：
   - 帶 citation
   - 符合 process-stage constraints
   - 在證據不足時揭露不確定性或拒答