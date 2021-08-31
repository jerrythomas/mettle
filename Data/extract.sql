--extract.sql
SELECT '(SELECT id from core.task where name = ''' ||p.name||''')' as precursor
      ,'(SELECT id from core.task where name = ''' ||s.name||''')' as successor
      ,c.kind
      ,c.wait
      ,c.enabled
  FROM core.chain c
      ,core.task  p
      ,core.task  s
 WHERE c.successor_id =s.id
   AND c.precursor_id = p.id
   AND c.enabled;

select name
      ,task_type
    ,schedule_id
    ,executable
    ,process_mode
    , slicing_mode
    ,logging_mode
    ,slice_value
    ,slice_start
    ,max_retries
    ,max_running
    ,retain_period
    ,dynamic_split
    ,enabled
    ,next_run_on
  from core.task

copy core.task (
 name
,EXECUTABLE
,PRIORITY
,PROCESS_MODE
,SLICING_MODE
,SLICE_VALUE
,SLICE_START
,MAX_RETRIES
,PROCESS_OFFSET
)
from
E'E:\\Code\\CampFire\\Source\\SQL\\cdsmain.txt' ;
--'/volumes/Jovy 2GB/Code/Campfire/Source/SQL/cdsmain.csv';
update core.task set task_type = 'INTERFACE' where task_type is null;
update core.task set schedule_id = 6 where task_type = 'INTERFACE' and slice_value = '1 hour';

SELECT ob.short_desc
      ,ob.object_code        executable
      ,pipeline_priority
      ,'TIMED'               process_mode
      ,'TIME'                slicing_mode
      ,DECODE(ob.object_code,'LDFDA-D-EPSCDS-C','1 day'
                            ,'LFDA-D-CDSPCI','1 day'
                            ,'FF90D-D-XLSCDS','1 day'
                            ,'FPF7-D-CDSPCI','1 day'
                            ,'GRVIW-W-CDSIPF','1 week'
                            ,'PFDAM-D-ITRCDS-C','1 day'
                            ,'PFRTM-D-ITRCDS-C','1 day'
                            ,'LF7-D-CDSRO-C-4TRDG','1 day'
                            ,'LMPIN-H-PCICDS','1 hour'
                            ,'RTENA-H-CDSIPF','1 hour'
                            ,'GMS4S-H-GMSCDS','1 hour') slice_value
      ,'2009-05-04 00:00:00'                            slice_start
      ,2                                                max_retries
      ,DECODE(sign(execution_offset),-1,'-','') || DECODE(TRUNC(TRUNC(SYSDATE) + ABS(execution_offset))-trunc(sysdate),0,'',trunc(trunc(sysdate) + abs(execution_offset))-trunc(sysdate)||' days ')
                             || to_char(trunc(sysdate) + abs(execution_offset),'HH24:mi:SS')      process_offset
  FROM pptobject ob
      ,pptpipeline_attr pa
      ,pptobject po
 WHERE ob.object_type_id = 100014
   AND pa.PIPELINE_ID = ob.object_id
   AND pa.parent_pipeline_id = po.object_id
   AND ob.object_code IN ( 'LDFDA-D-EPSCDS-C'
                          ,'LFDA-D-CDSPCI'
                          ,'FF90D-D-XLSCDS'
                          ,'FPF7-D-CDSPCI'
                          ,'GRVIW-W-CDSIPF'
                          ,'PFDAM-D-ITRCDS-C'
                          ,'PFRTM-D-ITRCDS-C'
                          ,'LF7-D-CDSRO-C-4TRDG'
                          ,'LMPIN-H-PCICDS'
                          ,'RTENA-H-CDSIPF'
                          ,'GMS4S-H-GMSCDS'
                          ,'BS7-D-ENTRO-4TRDG'
                          ,'HLMT90-D-CDSRO-4TRDG'
                          ,'MTR6-D-CDSRO-4TRDG'
                          ,'BP7-D-ENTRO-4TRDG'
                          ,'BP90-D-ENTRO-4TRDG'
                          ,'BS90-D-ENTRO-4TRDG'
                          ,'HASP-H-PCICDS'
                          ,'ASCPR-D-PCICDS'
                          ,'ASCPI-H-PCICDS'
                          ,'LMPPR-D-PCICDS'
                          ,'MKTAW-D-PCICDS');

select '(SELECT id from core.task where name = ''' ||po.short_desc||''')' as precursor_id
      ,'(SELECT id from core.task where name = ''' ||ob.short_desc||''')' as successor_id
      ,'DEPENDENCY'
      ,'f'
      ,'t'
  from pptobject ob
      ,pptpipeline_attr pa
      ,pptobject po
 where ob.object_type_id = 100014
   and pa.PIPELINE_ID = ob.object_id
   and pa.parent_pipeline_id = po.object_id
   and po.short_desc <> 'System'
   and ob.object_code in ( 'LDFDA-D-EPSCDS-C'
                            ,'LFDA-D-CDSPCI'
                            ,'FF90D-D-XLSCDS'
                            ,'FPF7-D-CDSPCI'
                            ,'GRVIW-W-CDSIPF'
                            ,'PFDAM-D-ITRCDS-C'
                            ,'PFRTM-D-ITRCDS-C'
                            ,'LF7-D-CDSRO-C-4TRDG'
                            ,'LMPIN-H-PCICDS'
                            ,'RTENA-H-CDSIPF'
,'GMS4S-H-GMSCDS')
union all
select '(SELECT id from core.task where name = ''' ||obp.short_desc||''')' as precursor_id
      ,'(SELECT id from core.task where name = ''' ||ob.short_desc||''')' as successor_id
      ,'CONFLICT'
      ,'f'
      ,'t'
  from pptobject ob
      ,pptpipeline_attr pa
      ,pptpipeline_attr pb
      ,pptobject        obp
 where ob.object_type_id = 100014
   and pa.PIPELINE_ID = ob.object_id
   and ob.object_code in ( 'LDFDA-D-EPSCDS-C'
                            ,'LFDA-D-CDSPCI'
                            ,'FF90D-D-XLSCDS'
                            ,'FPF7-D-CDSPCI'
                            ,'GRVIW-W-CDSIPF'
                            ,'PFDAM-D-ITRCDS-C'
                            ,'PFRTM-D-ITRCDS-C'
                            ,'LF7-D-CDSRO-C-4TRDG'
                            ,'LMPIN-H-PCICDS'
                            ,'RTENA-H-CDSIPF'
                            ,'GMS4S-H-GMSCDS')
 and pa.storage_name = pb.storage_name
 and obp.object_id   = pb.pipeline_id
 and obp.object_id <> ob.object_id;

copy core.task (
 name,task_type,schedule_id,executable,process_mode,slicing_mode,logging_mode
,slice_value,slice_start,max_retries,max_running,process_offset,priority
)
from
E'E:\\Code\\CampFire\\Source\\SQL\\task.csv' WITH CSV HEADER ;
--'/volumes/Jovy 2GB/Code/Campfire/Source/SQL/task.csv';