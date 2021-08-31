-- $Header LinksDDL.sql 0.01 11-Dec-2007 Jerry
/*
 * File Name  : LinksDDL.sql
 * Purpose    : Represent Relationships in database
 * Author     : Jerry Thomas
 * Version    : 0.01
 * Created On : 11-Dec-2007
 *
 *
 * ETL is commonly used to consolidate the data from multiple sources into a single system
 * which is usually a data warehouse. There are cases where ETL is used as a mechanism to
 * ease the repetitive transfer of data between different systems or differrent ways of storing
 * data like flat files (XML, CSV, TXT) or database systems (Oracle, Teradata, SQL Server,
 * PostgreSQL, MySQL)
 *
 *
 * Concept
 *   => Store the entities and relationships for each system accessed
 *   => Store relationships between flat files
 *   => Store connection details of each system
 *   => Each Environment should have it's own set of systems, however environment seggregation
 *      need not be done in the ERD, but can be handled in the configuration of the ETL environs
 *   =>
 *
 * Features
 *   => Import/infer relations from the database constraints & indexes
 *   => Allow user to create relations not imposed by the database/system (in case of files)
 *   =>
 *   =>
 *   =>
 *
 * Advantages
 *   => Once the ERD of any system is in place the ETL app can easily infer relations and assist
 *      the user by automatically adding key building components, thus reducing the time to develop
 *      ETL interfaces.
 *   => Provides a mechanism of automating the testing of rules and a degree of data quality assurance.
 *      As an example a user defined constraint not enforced by the system can be verified automatically
 *      by the tool when the constraint is defined.
 *   => Detect changes in the system constraints and raise alerts
 *   => Assist in automation of testing and heuristic data analysis
 *   =>
 *   =>
 *
 * Disadvantages
 *   => One extra and tedious set up task, although it pays in the end
 *   => One more place to maintain the ERD
 *
 ERD



   Logical Groups
   Objects
     ID
     Name
     Type  [table/view/file]
     System
     Connection [filepath in the case of files]
     Schema [what about db2/mysql/sqlite/Postgresql/Teradata]

   OBJECT_Columns
     ID
     objectID
     Name         {can contain a pattern/regex "mmddyyyy" specified in curly braces}
     owner
     Data_Type
     Data_Length
     Precision
     Scale
     nullable
     default length
     data_default
     low_value
     high_value
     character_set name

   Relations
     ID
     Name
     child_Object_ID
     Parent_Object_ID
     Relation Type       [Derivation] Example src to target.
     Relation 0:1, n:1, 1:n

   Relation columns
     rel id
     child_column
     parent_column
     Parent_value        [for constant values]

   Constraints
     object_id
     owner
     constraint name
     type [ C->constraint , P primary key, R referential, U unique ]
     column_ID


   Indexes
     index_id
     owner
     index_name
     object_id
     column_id
     sequence
     function? indexes


 */

--
CREATE TABLE Systems
(
    id              INTEGER
   ,name            VARCHAR(30)
   ,desc            VARCHAR(200)
   ,type            VARCHAR(10)        -- text,COBOL,Oracle, postgresql
   ,attributes      VARCHAR(20)
);

CREATE TABLE Connection
(
    ID
    system_id             REFERENCES db_systems(id)
    name
    Type                  VARCHAR(20)-> Oracle/DB2/......
    URN/URL               VARCHAR(100)
    User                  VARCHAR(20)
    Pwd                   VARCHAR(100)
    Instance              VARCHAR(100)
    connectString         VARCHAR(200)
    connect_using         VARCHAR(100)
    Pool_Size             integer
);

CREATE TABLE IKNADM_ENTITY_RELATIONS_ADM
(
   ENTITY_RELATION_ID         NUMBER(15)                   NOT NULL,
   SOURCE_ID                  NUMBER(15)                   NOT NULL,
   TARGET_ID                  NUMBER(15)                   NOT NULL,
   RELATION_TYPE              VARCHAR2(30)                 NOT NULL,
   KEY_TYPE                   VARCHAR2(1)     DEFAULT 'N'  NOT NULL,
   CREATION_DATE              DATE                         NOT NULL,
   LAST_UPDATE_DATE           DATE                         NOT NULL,
   CREATED_BY                 NUMBER(15)                   NOT NULL,
   LAST_UPDATED_BY            NUMBER(15)                   NOT NULL,
   INSTANCE_ID                NUMBER(15)                   NULL,
   ALT_INSTANCE_ID            NUMBER(15)                   NULL,
   KEY_SEQUENCE               NUMBER(3)                    NULL,
   STAGING_SFK                VARCHAR2(240)                NULL,
   STAGING_TFK                VARCHAR2(30)                 NULL,
   DIMENSION_PK               VARCHAR2(30)                 NULL,
   STG_DIM_JOIN_CLAUSE        VARCHAR2(2000)               NULL,
   NA_SRC_WHERE_CLAUSE        VARCHAR2(2000)               NULL,
   NA_UD_DIM_WHERE_CLAUSE     VARCHAR2(2000)               NULL,
   ATTRIBUTE1                 VARCHAR2(30)                 NULL,
   ATTRIBUTE2                 VARCHAR2(30)                 NULL,
   ATTRIBUTE3                 VARCHAR2(30)                 NULL,
   ATTRIBUTE4                 VARCHAR2(30)                 NULL,
   ATTRIBUTE5                 VARCHAR2(30)                 NULL
);
