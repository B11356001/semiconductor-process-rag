# Evaluation Pilot Results

## 1. Purpose
本文件提供一份小型 pilot evaluation 結果範例，用於展示本系統的評估方式、人工檢核邏輯與 error analysis 結構。

**注意：**
本頁為小規模人工 walkthrough 結果，用於展示 evaluation design 如何落地；
並非完整 50 題 benchmark 的正式執行報告。

## 2. Pilot Scope
本次 pilot review 從 `examples/eval-set-example.jsonl` 中抽取 5 題代表性問題，涵蓋下列題型：

- symptom_to_cause
- alarm_to_action
- insufficient_evidence
- conflicting_evidence
- term_alignment

## 3. Review Method
對每一題，依下列標準進行人工檢核：

1. Retrieval 是否符合 process-stage constraint
2. Evidence type 是否與 query intent 對齊
3. Answer 是否有 citation / uncertainty disclosure
4. 是否出現 unsupported claim
5. 在證據不足時是否正確 abstain

## 4. Pilot Review Table

| ID | Query Type | Retrieval Constraint Match | Evidence Relevance | Answer Behavior | Verdict | Main Observation |
|---|---|---:|---:|---|---|---|
| Q001 | symptom_to_cause | Pass | Pass | Needs conditional answer, not single-cause answer | Pass | 必須明確限制在 Etch context，不能跨 stage 套用 roughness 知識 |
| Q003 | alarm_to_action | Pass | Pass | Must explain alarm meaning + first-check steps | Pass | alarm code 題型適合 hybrid retrieval，BM25 很重要 |
| Q005 | insufficient_evidence | Pass | Partial | Should request more context and avoid guessing | Pass | pressure drift 單獨不足以支撐根因結論，abstain policy 合理 |
| Q006 | conflicting_evidence | Partial | Pass | Must compare authority + revision + process stage | Partial | 衝突證據處理仍依賴明確 ranking rule，需補 arbitration logic |
| Q007 | term_alignment | Pass | Pass | Must disambiguate acronym using context | Pass | CD 的 acronym disambiguation 需依 tool / stage / neighboring terms |

## 5. Aggregated Pilot Summary
本次 5 題 pilot walkthrough 的人工判讀摘要如下：

- Retrieval constraint alignment：4 / 5 表現穩定
- Evidence relevance：4 / 5 表現穩定
- Proper abstain behavior：1 / 1 題符合預期
- Conflict handling：1 / 2 類情境仍需補強 rule clarity
- Term disambiguation：可行，但需仰賴 alias table 與 metadata

## 6. Main Failure Risks Observed
本次 pilot walkthrough 顯示，系統仍有三個主要風險：

1. **Cross-stage contamination**
   - 相似 defect 名稱可能被錯誤套用到不同 process stage

2. **Revision conflict arbitration**
   - 若不同版本文件都被召回，需要更清楚的優先順序

3. **Conflict explanation quality**
   - 系統不只要選邊，還要說明為何採某份證據而非另一份

## 7. Design Implication
根據本次 pilot 結果，後續優先補強方向為：

- 明確定義 authority ranking rule
- 明確定義 revision priority rule
- 在 answer template 中強化 conflict disclosure
- 將 abstain trigger 寫入 execution policy

## 8. Next Step
後續正式 evaluation 應擴充為：
- 50 題完整 benchmark
- RAGAS / TruLens 自動評估
- 低分案例 error analysis
- revision conflict 專項測試