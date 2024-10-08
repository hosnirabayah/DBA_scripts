set linesize 132
set pagesize 1000
set pages 34
set lines 160
spool daily_check_PRDOFM.txt 

set heading off



prompt "****************************** Database Status ************************************"

select 'Hostname      : ' || host_name
      ,'Instance Name : ' || instance_name
      ,'Status        : ' || status
      ,'Started At    : ' || to_char(startup_time,'DD-MON-YYYY HH24:MI:SS') stime
      ,'Uptime        : ' || floor(sysdate - startup_time) || ' days(s) ' ||
       trunc( 24*((sysdate-startup_time) -
       trunc(sysdate-startup_time))) || ' hour(s) ' ||
       mod(trunc(1440*((sysdate-startup_time) -
       trunc(sysdate-startup_time))), 60) ||' minute(s) ' ||
       mod(trunc(86400*((sysdate-startup_time) -
       trunc(sysdate-startup_time))), 60) ||' seconds' uptime
from sys.v$instance;
set heading on
prompt "*********************************** SGA *******************************************"
show sga;
prompt
prompt

set heading on
prompt "******************************  Database Size **************************************"
prompt
select  substr(to_char(sum(bytes)/1024/1024/1024, '999,999.99'), 1, 11) "TOT GBYTES"
from    sys.dba_data_files;

prompt "****************************  ASM DISKGROUP FREESPACE  *****************************"

select name, round(total_mb/1024) as "TOTAL_GB" , round(free_mb/1024) as "FREE_GB"
from v$asm_diskgroup;

prompt "****************************** Invalid Objects *************************************"

select owner||'   '||object_type||'    '||object_name
from sys.dba_objects
where status='INVALID' and owner='WPT_DWH'
order by owner,object_type;

prompt
prompt
prompt "****************************** Recover files  ***************************************"
prompt
select * from sys.v_$recover_file;
prompt
prompt
prompt "************************ Free Space in Tablespaces **********************************"

WITH tbs_auto AS (SELECT   DISTINCT tablespace_name, autoextensible
                    FROM   dba_data_files
                   WHERE   autoextensible = 'YES'),
    files
        AS (  SELECT   tablespace_name,
                       COUNT ( * ) tbs_files,
                       SUM (bytes) / 1024 / 1024 / 1024 total_tbs_bytes
                FROM   dba_data_files
            GROUP BY   tablespace_name),
    fragments AS (  SELECT   tablespace_name,
                             COUNT ( * ) tbs_fragments,
                             SUM (bytes) / 1024 / 1024 / 1024 total_tbs_free_bytes,
                             MAX (bytes) / 1024 / 1024 / 1024 max_free_chunk_bytes
                      FROM   dba_free_space
                  GROUP BY   tablespace_name),
    autoextend
        AS (  SELECT   tablespace_name, SUM (size_to_grow) total_growth_tbs
                FROM   (  SELECT   tablespace_name,
                                   SUM (maxbytes) / 1024 / 1024 / 1024 size_to_grow
                            FROM   dba_data_files
                           WHERE   autoextensible = 'YES'
                        GROUP BY   tablespace_name
                        UNION
                          SELECT   tablespace_name,
                                   SUM (bytes) / 1024 / 1024 / 1024 size_to_grow
                            FROM   dba_data_files
                           WHERE   autoextensible = 'NO'
                        GROUP BY   tablespace_name)
            GROUP BY   tablespace_name)
SELECT   RPAD(a.tablespace_name, 15, '*'),
         CASE tbs_auto.autoextensible WHEN 'YES' THEN 'YES' ELSE 'NO' END
             AS autoextensible,
         round(files.total_tbs_bytes,2) TOTAL__GB,
         round(autoextend.total_growth_tbs,2) MAX_GB,
          round((files.total_tbs_bytes - fragments.total_tbs_free_bytes),2)
             USED_GB,
         round(fragments.total_tbs_free_bytes,2) FREE_GB,
         round(((fragments.total_tbs_free_bytes/files.total_tbs_bytes)*100),2) as "free%"
  FROM   dba_tablespaces a,
         files,
         fragments,
         autoextend,
         tbs_auto
WHERE       a.tablespace_name = files.tablespace_name
         AND a.tablespace_name = fragments.tablespace_name
         AND a.tablespace_name = autoextend.tablespace_name
         AND a.tablespace_name = tbs_auto.tablespace_name(+);
         

prompt "************************** Free space in Tablespace  *********************************"


Select tablespace_name,sum(bytes/1024/1024) as FreeSpaceMB from sys.dba_free_space  group by tablespace_name order by FreeSpaceMB;
prompt
prompt
prompt "************* Rololback segement must have ONLINE status, not OFFLINE or FULL ********"
select segment_id,owner, tablespace_name,status from dba_rollback_segs;
prompt
prompt #----------------------------------------- ********** Max Extent Status********** -------------------------------------------#

prompt
prompt
select segment_name, segment_type, extents, max_extents from sys.dba_segments where max_extents-extents<100;
prompt
prompt "**************************************************MON EXT*****************************************************"
prompt
-- monext.sql
prompt -- Displays segments for which the number of extents approaches the maximum value
set serveroutput on
col owner format a12
col segment_name format a30
col segment_type format a30
col partition_name format a30
select owner, segment_name, segment_type, partition_name, extents, max_extents, bytes/1024/1024 as TableSize
from dba_segments
where max_extents - 7 < extents
and owner <> 'SYS';


prompt "************************************************** MonSeg ******************************************************"
-- monseg.sql
prompt  Displays segments that can't be extended because of the next_extent parameter large value'
col owner format a8
col tbspace format a8
col segment_name format a25
col segment_type format a16
col partition_name format a25
select ds.owner,
ds.tablespace_name tbspace,
ds.segment_name,
ds.segment_type,
ds.partition_name,
ds.next_extent / 1024 next,
ds.pct_increase pct,
ds.extents extents
from dba_segments ds
where ds.next_extent > (
select nvl( max( dfs.bytes ), 0 )
from dba_free_space dfs
where ds.tablespace_name = dfs.tablespace_name(+) )
and owner <> 'SYS'
order by 2, 1, 6 desc;

prompt "************************ Any partitioned Object approaching to max extents ********************************"
prompt
SELECT PARTITION_NAME,EXTENTS,MAX_EXTENTS,NEXT_EXTENT,max_extents-nvl(next_extent,0) FROM sys.dba_segments
where max_extents-nvl(next_extent,0) < 1000
and partition_name is not null;
prompt
prompt
prompt
prompt "*****************************************  buffer cache hit ratio ******************************************"
prompt
select (1- (sum(decode(a.name,'physical reads',value,0)))/
        (sum(decode(a.name,'db block gets',value,0)) +
        sum(decode(a.name,'consistent gets',value,0)))) * 100 pct
        from v$sysstat a;

prompt
prompt "************************************** cache Misses in v$librarycache **************************************"
select sum(pins) "executions",sum(reloads) "cache Misses",sum(reloads)/sum(pins)*100 "Ratio" from v$librarycache;
prompt
prompt "**************************************** Get miss ratio from v$rowcache  ************************************"
prompt
select (sum(getmisses)/sum(gets)) * 100 "Hit Ratio" from v$rowcache;
prompt
prompt "******************************** Redo log space request ratio in v$systat ***********************************"
prompt
select (req.value*5000)/entries.value "ratio"
from v$sysstat req,v$sysstat entries
where req.name='redo log space requests' and entries.name='redo entries' ;
prompt
prompt  "******************************************** RBS Contention *************************************************"
prompt
select sum(waits)/sum(gets)*100 from v$rollstat;

prompt
prompt "********************************************** sorts stats ****************************************************"
prompt
Select * from v$sysstat where name like '%sorts%';

prompt
prompt
prompt "*********************************************primary database**************************************************"

Select * FROM
(SELECT first_time, sequence#, applied FROM V$ARCHIVED_LOG where to_char(first_time,'DDMMYYYY') = to_char(sysdate,'DDMMYYYY')
Order BY SEQUENCE# desc,first_time)
where rownum <=10
Order By SEQUENCE#,first_time desc;


prompt "******************************************* F L A S H B A C K **************************************************"
conn sys/admin2bcc  as sysdba
set pagesize 30
set linesize 160
prompt .>>>>>> FLASHBACK

SELECT substr(name,1,50) name, (space_limit/(1024*1024*1024)) AS quotaGB,
(space_used/(1024*1024*1024)) AS usedGB,
(space_reclaimable/(1024*1024*1024)) AS reclaimableGB,
number_of_files AS files
FROM v$recovery_file_dest ;
prompt
prompt "**************************************** R E S O U R C E L I M I T **********************************************"
SELECT * FROM v$resource_limit
  Where resource_name in ('processes','sessions') ;



prompt #---------------------- ****** The largest 10 tables/column in the database**** ------------------#
set pagesize 30
set linesize 160
col owner format a10
col table_name format a20
col column_name format a25
col segment_name format a25
col g format 9999.9999

select owner, table_name, column_name, segment_name,g
from(
select
l.owner, l.table_name, l.column_name, l.segment_name, round(s.bytes/1024/1024/1024,1) g from dba_lobs l, dba_segments s
where
s.segment_name=l.segment_name and
 s.owner=l.owner
order by g desc
)
where rownum < 25;




prompt #---------------------- ****** The largest 10 segments in the database**** ------------------#
set pagesize 30
set linesize 160
col owner format a10
col segment_name format a25
col segment_type  format a20
col gb format 9999.9999
select  owner
,     segment_name
,     segment_type
,    gb
from  (
      select      owner
      ,     segment_name
      ,     segment_type
      ,     bytes / 1024 / 1024 /1024 gb
      from  dba_segments
      order by gb desc
      )
where rownum < 25;

prompt #---------------------------- ********************************************************************** ------------------#

spool off
exit

