select * from dba_datapump_jobs

SYS_EXPORT_FULL_24 -- State EXECUTING

Go To OS


/*

Select * from dba_datapump_jobs

Get the job name and do the following on OS:

-bash-3.2$ expdp hrabaya attach=SYS_IMPORT_FULL_01

Export: Release 11.2.0.3.0 - Production on Wed May 11 02:27:35 2016

Copyright (c) 1982, 2011, Oracle and/or its affiliates.  All rights reserved.

Connected to: Oracle Database 11g Enterprise Edition Release 11.2.0.3.0 - 64bit Production
With the Partitioning, OLAP, Data Mining and Real Application Testing options

Job: SYS_EXPORT_FULL_24
  Owner: EXP
  Operation: EXPORT
  Creator Privs: TRUE
  GUID: 3285F15876D25D1BE0530582A00AEBFB
  Start Time: Wednesday, 11 May, 2016 2:06:26
  Mode: FULL
  Instance: RADIUS
  Max Parallelism: 1
  EXPORT Job Parameters:
  Parameter Name      Parameter Value:
     CLIENT_COMMAND        exp/******** logfile=radius-2016-05-11_02h00m.log dumpfile=radius-2016-05-11_02h00m.dmp full=y
  State: EXECUTING
  Bytes Processed: 0
  Current Parallelism: 1
  Job Error Count: 0
  Dump File: /u02/backup/dump/radius-2016-05-11_02h00m.dmp
    bytes written: 4,096

Worker 1 Status:
  Process Name: DW00
  State: EXECUTING
  Object Schema: AZZAM
  Object Name: POD_GEN
  Object Type: DATABASE_EXPORT/SCHEMA/PROCEDURE/ALTER_PROCEDURE
  Completed Objects: 80
  Worker Parallelism: 1

Export> kill
Are you sure you wish to stop this job ([yes]/no): yes

*/




