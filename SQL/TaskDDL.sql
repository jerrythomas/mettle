-- $Header TasksDDL.sql 0.01 11-Dec-2007 Jerry
/*
 * File Name  : TasksDDL.sql
 * Purpose    : Table definitions for tracking progress of data transfer processes.
 * Author     : Jerry Thomas
 * Version    : 0.01
 * Created On : 11-Dec-2007
 */
/*
[client side only]
------------------

repository
  id
  server
  server ip
  user
  authentication method?

Local config

[Server side]
------------------
  Project
    id
    name
    notes
    type [Dev/Test/UAT/PROD]
    Server IP
    Server Port
    Server Name
    [OS]
    OS Version
    CPU [Model/Speed,N cores/N processors]
    RAM
    Disk_Size
    Disk_type [San/SAS]
    Scratch_Area
    PathToExecutables
    ExecutingUserID/PWD

  Users
    id
    fname
    lname
    mname
    xname [Extended Name?]
    pathforExecutable

  Roles
    id


  Access
    proj_id
    role_id
    R-W-X-D

  Locks
    Object_ID
    Mapping_ID
    Lock User
    Lock Mode
    Lock Reason

  Mapping/Task/Workflow/Flow/Process

  // ideally each mapping should be associated with only one target entity
           // however there is a possibility that a single source can contain data destined for multiple targets
           // in such a situation extraction should be done only once (reduces stress on source)
           and generate multiple intermediate files to be used for subsequent ETL
           (now we have one to one for src to target)
    id
    name
    Type [incremental/auto,on-demand,scheduled]
    slicing mode [time/number]
    dynamic split [y/n]
    process_mode [incremental/full]
    incremental_option [change capture/diff/audit columns]
    keep_together [y/n]
    max retries [0 indicates no retries]
    mode [debug/trace/prod]


   dynamic split
     map_id
     object_id
     column_id
     slice_mode
     default_slice
     optimal_volume
     threshold size [for dynamic split]


   Mapping entities
     object_id
     type [Src/Target]
     slice_column_id [for the slicing]
     primary [ for single target/single source]
     schedule

   Dependency
     rule 1: if any src of a mapping [A] is the target of another [B] then map [A] should ideally run only after successful completion of the map [B]. applicable to maps with same schedule. [Avoid circular dependencies]

     rule 2:

     UI for showing auto generated dependencies and allow creation of more.

     ID
     Type [Waiting/ Non Waiting]

   Components
     id
     type
     sort [y/n]
     filter [y/n]
     join [y/n]

   Module [ Query
     id
     map_id
     type [E,V,T,L]
     component/module type
     implementation [in memory/use DB features]

   Module Columns
     sequence
     src_object_id
     src_column_id
     tgt_expression
     sort order [ 0 -> no sort]
     sort type  [ asc/desc/none]


   module chain
     chain id
     map id
     mod_id
     sequence
     map_by_name
     exceptions [y/n]

   module_chain columns
     chain id
     seq
     src_mod_col_id
     tgt_mod_col_id



  Task
    map_id
    Compiled prg/Executable






  Map Screens
    Design
    Dependencies
    Progress (w/wo history)
    Performance
    Perf chart [ time v/s records @ map level, @ component level over a period ]


*/

SET search_path        TO core,public;
SET default_tablespace = cf_core_dat;

DROP TABLE IF EXISTS chain cascade;
DROP TABLE IF EXISTS task cascade;
DROP SEQUENCE IF EXISTS chain_id_sq;
DROP SEQUENCE IF EXISTS task_id_sq;

CREATE SEQUENCE task_id_sq
     START WITH 1
   INCREMENT BY 1;

-- DDL for the Task 
CREATE TABLE task
(
   id                       NUMERIC(10)     PRIMARY KEY DEFAULT NEXTVAL('task_id_sq')
  ,name                     VARCHAR(150)
  ,task_type                VARCHAR(15)      --[Dimension, Fact, Relational, App etc]
  ,schedule_id              NUMERIC(10)      -- Actual schedule for execution
  ,executable               VARCHAR(50)      -- executable file name
  ,process_mode             VARCHAR(15)     DEFAULT 'AUTO' --[AUTO/INCR/TIMED/EVENT]
  ,slicing_mode             VARCHAR(10)     DEFAULT 'TIME' --[time/number]
  ,logging_mode             INTEGER         DEFAULT 2      --[TRACE-5/DEBUG-4/INFO-3/PACE-2/WARN-1/ERROR-0]
  ,ts_start_with            TIMESTAMP       DEFAULT '01-01-2000'
  ,ts_increment_by          INTERVAL        DEFAULT '00:00:00'  -- Assume no increment for next run
--  ,ns_start_with            NUMERIC
--  ,ns_increment_by          NUMERIC -- not required as we can simulate time based slicing even if source does not have timestamp
  ,max_retries              NUMERIC(5)      -- [0 indicates no retries]
  ,max_running              NUMERIC(5)      DEFAULT 0 -- [Number of parallel instances, 0 indicates unlimited]
  ,incremental_option       NUMERIC(5)                          -- Method of identifying change capture [diff/audit columns] stream, gg etc
  ,process_offset           INTERVAL        DEFAULT '00:00:00'  -- 
  ,retry_interval           INTERVAL        DEFAULT '5 minutes' -- Time between retries for failed tasks
  ,retain_period            INTERVAL        DEFAULT '7 days'    -- Staging data retention period
  ,dynamic_split            BOOLEAN         DEFAULT FALSE       -- Enable auto split data in case of spikes in volumes
  ,process_rowlimit         NUMERIC         DEFAULT 0           -- Volume spike threshold for Auto split. 0 => disabled
  ,enabled                  BOOLEAN         DEFAULT TRUE
  ,visible                  BOOLEAN         DEFAULT TRUE        -- In case duplicate tasks are required (will require reference to self)
  ,hold_applied             BOOLEAN         DEFAULT FALSE  
  ,allow_gaps               BOOLEAN         DEFAULT FALSE       -- similar to keep together?
  ,allow_parallel_load      BOOLEAN         DEFAULT FALSE  
  ,keep_together            BOOLEAN         DEFAULT TRUE        -- [y/n]
  ,priority                 INTEGER
  ,pattern_match            VARCHAR(500)
  ,pattern_replace          VARCHAR(25)    -- use YYYY-MM-DD+HH24:MI:SS allows split by time part which can be taken as interval to handle hours >= 24
  ,date_format              VARCHAR(25)    -- use YYYY-MM-DD+HH24:MI:SS
  ,notes                    VARCHAR
  ,currently_running        INTEGER         DEFAULT 0
  ,awaiting_reprocess       INTEGER         DEFAULT 0 
  ,modified_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  ,modified_by              VARCHAR(50)              DEFAULT CURRENT_USER
);

ALTER INDEX task_pkey SET TABLESPACE cf_core_idx;

ALTER TABLE task
        ADD CONSTRAINT task_sked_fkey
               FOREIGN KEY (schedule_id)
            REFERENCES schedule (id);

CREATE INDEX task_sked_fkey
          ON task(schedule_id)
  TABLESPACE cf_core_idx;

-- Created for improving performance of the timed schedules
CREATE INDEX task_tsw_perf_key
          ON task(ts_start_with)
  TABLESPACE cf_core_idx;


CREATE SEQUENCE chain_id_sq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE chain
(
   id                       NUMERIC(10)     PRIMARY KEY DEFAULT NEXTVAL('chain_id_sq')
  ,precursor_id             NUMERIC(10)
  ,successor_id             NUMERIC(10)
  ,kind                     VARCHAR(25)     -- KEY,CONFLICT,DEPENDENCY,CASCADE
  ,precursor_status         VARCHAR         -- to be used with regex comparison on precursor status
  ,wait                     BOOLEAN                  DEFAULT FALSE
  ,enabled                  BOOLEAN                  DEFAULT TRUE  -- When disabling any task disable the dependency if it has wait = TRUE
  ,modified_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  ,modified_by              VARCHAR(50)              DEFAULT CURRENT_USER
);

ALTER INDEX chain_pkey SET TABLESPACE cf_core_idx;

ALTER TABLE chain
        ADD CONSTRAINT chain_precursor_fk
               FOREIGN KEY (precursor_id)
            REFERENCES task (id);

CREATE INDEX chain_precursor_fk
          ON chain(precursor_id)
  TABLESPACE cf_core_idx;

ALTER TABLE chain
        ADD CONSTRAINT chain_successor_fk
               FOREIGN KEY (successor_id)
            REFERENCES task (id);

CREATE INDEX chain_successor_fk
          ON chain(successor_id)
  TABLESPACE cf_core_idx;

-- Think of workflows too
/*

A task can be part of a workflow
a workflow can

*/
/*
-- option to be explored for greater flexibility in using optional parameters when executing manual tasks
-- this may impact the way the task has to be initiated.
-- manual executions would be run using the anytime schedule
-- any restrictions on the number of running processes?

-- List of optional parameters
CREATE SEQUENCE parameter_id_sq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE parameter
(
   id                       NUMERIC(10)     PRIMARY KEY DEFAULT NEXTVAL('parameter_id_sq')
  ,task_id                  NUMERIC(10)
  ,kind                     VARCHAR(25)     -- 'OPTIONAL, stage? can this be used in one of the filter stages?'
  ,entity_name              VARCHAR(50)     -- source entity this applies to
  ,field_name               VARCHAR(50)     -- source entity field this applies to
  ,data_type                VARCHAR(25)     -- data type of the field
  ,condition                VARCHAR(25)     -- IN, Not IN, = , like, <> between
  ,enabled                  BOOLEAN                  DEFAULT TRUE
  ,modified_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  ,modified_by              VARCHAR(50)              DEFAULT CURRENT_USER
);

ALTER INDEX parameter_pkey SET TABLESPACE cf_core_idx;

ALTER TABLE parameter
        ADD CONSTRAINT parameter_precursor_fk
               FOREIGN KEY (task_id)
            REFERENCES task (id);
*/