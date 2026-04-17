# Evaluation Results

## 1. Scope
本文件提供一份 **extended manual evaluation**，目的在於將先前的 pilot review 擴充為較正式的 evaluation artifact，展示本系統的評估流程、題型覆蓋與 error analysis 結構。

**Important note**  
本結果基於 `examples/eval-set-example.jsonl` 的 10 題樣本進行人工 walkthrough review。  
它不是完整 50 題 benchmark，也不是正式自動化 RAGAS / TruLens 報表；其用途是展示 evaluation design 已從規劃階段進一步落地到可檢核的結果文件。

## 2. Evaluation Method
每題依下列四個維度進行人工檢核：

1. **Retrieval Constraint Match**  
   是否符合 process stage / defect type / parameter / revision 等限制條件

2. **Evidence Relevance**  
   召回的證據類型是否與 query intent 對齊

3. **Answer Policy Compliance**  
   是否符合 grounded answer、citation、uncertainty disclosure、abstain policy 等要求

4. **Hallucination Risk Control**  
   是否避免 unsupported claim 或 cross-context misapplication

評分方式：
- Pass = 1
- Partial = 0.5
- Fail = 0

## 3. Question-Level Results

| ID | Query Type | Retrieval Constraint Match | Evidence Relevance | Answer Policy Compliance | Hallucination Risk Control | Verdict | Notes |
|---|---|---:|---:|---:|---:|---|---|
| Q001 | symptom_to_cause | 1 | 1 | 1 | 0.5 | Pass | 必須限制在 Etch context，避免跨 stage 套用 roughness 知識 |
| Q002 | defect_to_action | 1 | 1 | 1 | 1 | Pass | CMP scratch defect 題型可由 defect guide + checklist 支撐 |
| Q003 | alarm_to_action | 1 | 1 | 1 | 1 | Pass | Alarm code 題型明顯受益於 BM25 / precise match |
| Q004 | parameter_to_evidence | 1 | 1 | 1 | 1 | Pass | Overlay 題型適合 evidence-oriented answer |
| Q005 | insufficient_evidence | 1 | 0.5 | 1 | 1 | Pass | pressure drift 單獨不足以支撐根因分析，應要求補充上下文 |
| Q006 | conflict_resolution | 0.5 | 1 | 0.5 | 0.5 | Partial | 衝突處理仍依賴 authority ranking 與 revision priority |
| Q007 | term_alignment | 1 | 1 | 0.5 | 0.5 | Partial | CD 的 acronym disambiguation 需強依賴 stage / tool / neighboring terms |
| Q008 | conflicting_evidence | 0.5 | 1 | 0.5 | 0.5 | Partial | conflicting corrective action 題型仍需更強的 explanation template |
| Q009 | abstain_policy | 1 | 1 | 1 | 1 | Pass | 拒答條件與不確定性揭露可以被清楚定義 |
| Q010 | domain_reasoning | 1 | 1 | 1 | 1 | Pass | particle defect 跨 stage 不可直接共用答案，domain constraint 合理 |

## 4. Aggregate Summary

### 4.1 Per-Dimension Summary
- Retrieval Constraint Match: **8.0 / 10**
- Evidence Relevance: **9.0 / 10**
- Answer Policy Compliance: **7.5 / 10**
- Hallucination Risk Control: **7.0 / 10**

### 4.2 Overall Outcome
- **Pass:** 7 / 10
- **Partial:** 3 / 10
- **Fail:** 0 / 10

整體觀察：
- retrieval structure 與 metadata constraint 設計已具合理性
- abstain behavior 在 evidence insufficiency 題型中表現穩定
- conflict arbitration、acronym disambiguation、cross-context explanation quality 仍需補強

## 5. Retrieval Strategy Comparison

| Strategy | Exact Code / Alias Handling | Stage Constraint Control | Answer Completeness | Hallucination Risk | Observation |
|---|---:|---:|---:|---:|---|
| Pure Vector Retrieval | Low | Low | Low | High | 容易漏掉 alarm code、縮寫與 metadata constraint |
| Vector + Query Rewrite | Medium | Low | Medium | Medium | 可改善自然語言 query，但不足以支撐精準代碼與 stage filtering |
| Hybrid Retrieval | High | Medium | Medium | Medium | 對 alarm code / defect code / parameter name 題型更穩定 |
| Hybrid + Metadata + Parent Expansion + Reranker | High | High | High | Lower | 最符合本作業的 domain-driven requirement，但維護與 latency 成本較高 |

## 6. Failure Cases

### Failure Case 1: Conflict Resolution under Multiple Valid Sources
- **Example IDs:** Q006, Q008
- **Issue:** 當不同文件都提供合理 corrective action 時，系統若沒有明確 authority ranking / revision priority rule，容易只輸出單一答案而未揭露衝突。
- **Implication:** 需補強 conflict arbitration logic 與 answer template。

### Failure Case 2: Acronym Disambiguation under Sparse Context
- **Example ID:** Q007
- **Issue:** 縮寫如 CD 在不同製程與工具上下文中可能代表不同概念；若 query context 稀薄，容易發生語義誤判。
- **Implication:** 需更強的 alias table、neighboring term rule 與 process-stage-aware query understanding。

### Failure Case 3: Cross-Context Misapplication Risk
- **Example IDs:** Q001, Q010
- **Issue:** 即使引用了真實文件，也可能因 stage / tool / material context 不一致而被錯誤套用。
- **Implication:** hallucination 不只是不支持的捏造，也包括真實知識的錯誤上下文套用。

## 7. Main Findings
1. **Hybrid Retrieval + Metadata Filter + Parent Expansion + Reranker** 對半導體 troubleshooting 場景是合理設計。
2. **Abstain policy** 對 evidence insufficiency 題型屬必要機制。
3. 本領域最關鍵的 hallucination 風險是 **cross-context misapplication**。
4. 後續最需要補強的是：
   - conflict arbitration
   - acronym disambiguation
   - revision-aware answer explanation

## 8. Limitations
本文件為 manual evaluation artifact，而非 production benchmark report。  
目前尚未包含：
- 50 題完整 benchmark 統計
- 自動化 RAGAS / TruLens score export
- latency 實測報表
- 大規模 error distribution

## 9. Next Step
後續正式 evaluation 應補上：
- 50 題 benchmark
- RAGAS / TruLens score export
- latency measurement under fixed hardware assumption
- low-score sample error analysis
- revision conflict 專項測試