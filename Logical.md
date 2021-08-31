# ERD

- Source Systems

  - id
  - name
  - desc
  - attributes ?

- Connections

  - ID
  - sys ID?
  - name
  - Type -> Oracle/DB2/......
  - URN/URL
  - User
  - Pwd
  - Instance
  - connectString
  - connect using:

- Logical Groups
- Objects

  - ID
  - Name
  - Type [table/view/file]
  - System
  - Connection [filepath in the case of files]
  - Schema [what about db2/mysql/sqlite/Postgresql/Teradata]

- OBJECT_Columns

  - ID
  - objectID
  - Name {can contain a pattern/regex "mmddyyyy" specified in curly braces}
  - owner
  - Data_Type
  - Data_Length
  - Precision
  - Scale
  - nullable
  - default length
  - data_default
  - low_value
  - high_value
  - character_set name

- Relations

  - ID
  - Name
  - child_Object_ID
  - Parent_Object_ID
  - Relation Type [Derivation] Example src to target.
  - Relation 0:1, n:1, 1:n

- Relation columns

  - rel id
  - child_column
  - parent_column
  - Parent_value [for constant values]

- Constraints
  - object_id
  - owner
  - constraint name
  - type [ C->constraint , P primary key, R referential, U unique ]
  - column_ID

* Indexes
  - index_id
  - owner
  - index_name
  - object_id
  - column_id
  - sequence
  - function? indexes
