CREATE TABLE source_documents (
    source_id TEXT PRIMARY KEY,
    source_title TEXT NOT NULL,
    source_type TEXT NOT NULL,
    authority_level TEXT NOT NULL,
    revision TEXT,
    revision_date DATE,
    language TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE parent_documents (
    parent_doc_id TEXT PRIMARY KEY,
    source_id TEXT NOT NULL REFERENCES source_documents(source_id),
    section_title TEXT,
    section_order INT,
    content TEXT NOT NULL
);

CREATE TABLE knowledge_atoms (
    atom_id TEXT PRIMARY KEY,
    parent_doc_id TEXT NOT NULL REFERENCES parent_documents(parent_doc_id),
    source_id TEXT NOT NULL REFERENCES source_documents(source_id),
    atom_type TEXT NOT NULL,
    title TEXT,
    content TEXT NOT NULL,
    process_stage TEXT,
    tool_name TEXT,
    chamber TEXT,
    material TEXT,
    defect_type TEXT,
    parameter_name TEXT,
    revision TEXT,
    revision_date DATE,
    authority_level TEXT,
    language TEXT,
    source_section TEXT,
    embedding VECTOR(1024)
);

CREATE TABLE term_aliases (
    alias_id TEXT PRIMARY KEY,
    canonical_term TEXT NOT NULL,
    alias TEXT NOT NULL,
    process_stage TEXT,
    notes TEXT
);

CREATE INDEX idx_knowledge_atoms_process_stage ON knowledge_atoms(process_stage);
CREATE INDEX idx_knowledge_atoms_defect_type ON knowledge_atoms(defect_type);
CREATE INDEX idx_knowledge_atoms_parameter_name ON knowledge_atoms(parameter_name);
CREATE INDEX idx_knowledge_atoms_revision_date ON knowledge_atoms(revision_date);