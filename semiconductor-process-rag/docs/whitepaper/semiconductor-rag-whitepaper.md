# 半導體製程異常分析 RAG 系統白皮書

## 1. 摘要
本白皮書提出一套以半導體製程異常分析為核心場景的領域驅動 RAG 系統。系統目標不是取代工程師，而是將分散於 SOP、alarm manual、troubleshooting guide、incident report 與 glossary 中的知識，轉化為可檢索、可排序、可解釋、可追溯的知識系統。

## 2. 問題定義
一般 RAG 在半導體製程領域面臨兩大困難：
1. 語意相似不代表製程正確
2. 同一 defect 名稱在不同製程階段可能代表不同成因

例如使用者詢問「Etch 後 CD drift 並伴隨 sidewall roughness，可能原因是什麼？」  
如果系統只依語意相似檢索，可能抓到一般的 roughness 或 CD bias 文章，但忽略：
- process stage
- material stack
- recipe window
- chamber condition
- revision-specific troubleshooting guideline

因此，半導體場景需要的不只是 embedding search，而是結合術語對齊、metadata filter、parent context 與 reranking 的領域驅動 RAG。

## 3. Representation 的理論難點
### 3.1 術語多義與縮寫對齊
半導體文件高度依賴縮寫與簡寫，例如 CD、CMP、EPI、LWR、FDC。  
同一縮寫在不同文件、不同團隊、不同製程節點下，可能有語義偏移。  
因此知識表徵不能只保留原文字串，還需建立 alias normalization 與 glossary mapping。

### 3.2 因果鏈不是平面文本
製程異常通常具有「現象 -> 可能成因 -> 檢查項 -> 修正動作」的鏈式結構。  
若僅以固定長度 chunk 切分，可能把完整因果鏈切碎，導致召回後缺少足夠證據支持生成。

### 3.3 數值參數具有上下文依賴
同一數值偏移在不同 tool、不同 chamber、不同 step 下代表不同意義。  
因此參數必須與 process stage、tool metadata 綁定，而不是獨立存在。

### 3.4 文件版本衝突
工程文件常有 revision。舊版 corrective action 與新版 SOP 可能不一致。  
若系統未處理 authority ranking 與 revision priority，就容易產生引用衝突。

### 3.5 Typed Relations and Non-Flat Knowledge
半導體製程知識的核心問題之一，在於知識單元之間不是平面並列關係，而是帶有型別的關聯，例如：

- symptom -> suggests -> possible_root_cause
- root_cause -> verified_by -> evidence
- root_cause -> mitigated_by -> corrective_action
- parameter_shift -> constrained_by -> process_stage
- corrective_action -> valid_under -> tool_family / revision

因此，若系統只將文件表示成無結構的 chunk 集合，就容易在生成時混淆「症狀」、「成因」、「檢查證據」與「修正動作」。  
這也是本系統採用 knowledge atomization、metadata binding 與 parent-document retrieval 的理論基礎。

## 4. 系統設計原則
本系統採取以下設計原則：
1. Ontology-aware representation
2. Hybrid retrieval
3. Parent-document retrieval
4. Reranking before generation
5. Citation-required grounded generation
6. Abstain when evidence is insufficient

## 5. 如何降低 Hallucination
### 5.1 Evidence-only generation
LLM 不得根據一般常識自行補全製程知識，所有關鍵結論必須可在 evidence pack 中找到支持。

### 5.2 Revision-aware retrieval
若多版本文件衝突，系統優先採較新 revision 與高 authority source。

### 5.3 Reranker as semantic gate
reranker 用來過濾看起來相似、但實際上 process stage 不符的片段。

### 5.4 Explicit uncertainty
當證據不足、文件互相矛盾、或 metadata 不完整時，系統必須明示不確定性，而不是強行回答。

### 5.5 Hallucination as Cross-Context Misapplication
在半導體場景中，hallucination 不只是「捏造不存在的知識」，更常見的是將原本在某一 process stage、tool family、material stack 或 revision 下成立的內容，錯誤套用到另一個上下文。  
因此，本系統將 hallucination 定義為兩類：

1. Unsupported fabrication  
   回答中的主張沒有任何 evidence pack 支持

2. Cross-context misapplication  
   回答雖然引用了真實文件，但引用的內容不適用於目前的 process stage、tool、revision 或 defect context

這也是本系統強調 metadata constraint、revision-aware retrieval、authority ranking 與 abstain policy 的原因。

## 6. 冷啟動與專有名詞對齊問題
半導體領域的冷啟動不只是資料量不足，更是：
- 縮寫表尚未建立
- defect taxonomy 未統一
- process stage 命名不一致
- 中英文術語混用

本系統的冷啟動策略如下：
1. 先建立 glossary 與 alias table
2. 先匯入高權威 SOP 與 troubleshooting guide
3. 先做人工作標註的小型黃金資料集
4. 先完成高頻 defect / parameter / action 的知識原子化
5. 逐步擴充 incident report 與歷史案例

## 7. 評估方法
本系統以離線評估為主，建立 50 筆黃金測試集。  
檢索階段使用 Top-K hit rate、context precision、context recall。  
生成階段使用 faithfulness、response relevancy、groundedness 與 answer completeness。

## 8. 系統限制
本系統不能替代實際機台診斷流程，也不應作為自動控制系統。  
其定位是知識檢索、證據整理與工程決策輔助。

## 9. 結論
半導體製程知識具有高度術語密集、因果鏈複雜、版本敏感與上下文依賴的特性。  
因此，一個高品質 RAG 系統必須超越單純向量檢索，轉向 domain-driven representation、hybrid retrieval 與 grounded generation 的整體設計。