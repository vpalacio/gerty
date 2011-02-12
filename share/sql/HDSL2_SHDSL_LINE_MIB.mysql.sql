/* Mysql table definitions for
   Gerty::SNMP::Postprocess::HDSL2_SHDSL_LINE_MIB_dbstore
*/



/* ***********  RSSI per-minute history  ************ */

CREATE TABLE HDSL_XTUC_15MIN_COUNTERS
(
  HOSTNAME              VARCHAR(150) NOT NULL,
  INTF_NAME             VARCHAR(60) NOT NULL,
  WIREPAIR              INTEGER NOT NULL,
  MEASURE_TS            DATETIME NOT NULL,
  ES_COUNT              INTEGER,
  SES_COUNT             INTEGER,
  CRCA_COUNT            INTEGER,
  LOSWS_COUNT           INTEGER,
  UAS_COUNT             INTEGER,                   
  CONSTRAINT HDSL_XTUC_15MIN_COUNTERS_UC01 UNIQUE
      (HOSTNAME, INTF_NAME, WIREPAIR, MEASURE_TS)
);

CREATE INDEX HDSL_XTUC_15MIN_COUNTERS_I01
  ON HDSL_XTUC_15MIN_COUNTERS(MEASURE_TS);



