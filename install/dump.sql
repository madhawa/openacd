--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: openacd
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO openacd;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: agents_logs; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE agents_logs (
    dt timestamp without time zone,
    agent integer,
    event integer,
    callid character varying(32),
    timer integer,
    acdgroup character varying(16) DEFAULT 0,
    exten text,
    beforeanswertime integer DEFAULT 0,
    dialstatus integer DEFAULT 0,
    dt_begin timestamp without time zone,
    record_id integer DEFAULT 0
);


ALTER TABLE public.agents_logs OWNER TO openacd;

--
-- Name: black_list; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE black_list (
    bll_id integer NOT NULL,
    bll_date timestamp without time zone,
    bll_number text,
    bll_count integer DEFAULT 0,
    bll_text text,
    bll_service text
);


ALTER TABLE public.black_list OWNER TO openacd;

--
-- Name: black_list_bll_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE black_list_bll_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.black_list_bll_id_seq OWNER TO openacd;

--
-- Name: black_list_bll_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE black_list_bll_id_seq OWNED BY black_list.bll_id;


--
-- Name: black_list_bll_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('black_list_bll_id_seq', 1, false);


--
-- Name: calls; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE calls (
    id1 integer NOT NULL,
    id bigint,
    dt timestamp without time zone,
    acdgroup character varying(10),
    agent integer,
    status smallint,
    beforeanswertime integer,
    answertime integer,
    queuetime integer,
    queuecount integer,
    callerid character varying(32),
    exten character varying,
    holdtime integer,
    crossid integer,
    operator character varying(1)
);


ALTER TABLE public.calls OWNER TO openacd;

--
-- Name: calls_id1_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE calls_id1_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.calls_id1_seq OWNER TO openacd;

--
-- Name: calls_id1_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('calls_id1_seq', 1, false);


--
-- Name: calls_id1_seq1; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE calls_id1_seq1
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.calls_id1_seq1 OWNER TO openacd;

--
-- Name: calls_id1_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE calls_id1_seq1 OWNED BY calls.id1;


--
-- Name: calls_id1_seq1; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('calls_id1_seq1', 46, true);


--
-- Name: destination; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE destination (
    dst_id integer NOT NULL,
    dst_name text,
    dst_ip inet
);


ALTER TABLE public.destination OWNER TO openacd;

--
-- Name: destination_dst_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE destination_dst_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.destination_dst_id_seq OWNER TO openacd;

--
-- Name: destination_dst_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE destination_dst_id_seq OWNED BY destination.dst_id;


--
-- Name: destination_dst_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('destination_dst_id_seq', 2, true);


--
-- Name: errors; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE errors (
    err_id integer NOT NULL,
    err_date text,
    err_text text
);


ALTER TABLE public.errors OWNER TO openacd;

--
-- Name: errors_err_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE errors_err_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.errors_err_id_seq OWNER TO openacd;

--
-- Name: errors_err_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE errors_err_id_seq OWNED BY errors.err_id;


--
-- Name: errors_err_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('errors_err_id_seq', 1, false);


--
-- Name: kouch; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE kouch (
    kch_id integer NOT NULL,
    kch_name text
);


ALTER TABLE public.kouch OWNER TO openacd;

--
-- Name: kouch_kch_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE kouch_kch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.kouch_kch_id_seq OWNER TO openacd;

--
-- Name: kouch_kch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE kouch_kch_id_seq OWNED BY kouch.kch_id;


--
-- Name: kouch_kch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('kouch_kch_id_seq', 1, false);


--
-- Name: languages; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE languages (
    lng_id integer NOT NULL,
    lng_name text,
    lng_name_short text
);


ALTER TABLE public.languages OWNER TO openacd;

--
-- Name: languages_lng_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE languages_lng_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.languages_lng_id_seq OWNER TO openacd;

--
-- Name: languages_lng_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE languages_lng_id_seq OWNED BY languages.lng_id;


--
-- Name: languages_lng_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('languages_lng_id_seq', 1, false);


--
-- Name: operators; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE operators (
    opr_id integer NOT NULL,
    opr_name text,
    opr_password text,
    opr_city integer,
    opr_graid smallint,
    opr_date_begin date,
    opr_date_end date,
    kch_id integer,
    opr_uvolen character varying(100),
    opr_1c_id integer,
    opr_lang_attest date,
    opr_outgoing_call smallint
);


ALTER TABLE public.operators OWNER TO openacd;

--
-- Name: operators_channels; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE operators_channels (
    opc_id integer NOT NULL,
    opr_id integer,
    opc_time timestamp without time zone,
    opc_channels text,
    opc_channels_check integer
);


ALTER TABLE public.operators_channels OWNER TO openacd;

--
-- Name: operators_channels_opc_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE operators_channels_opc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.operators_channels_opc_id_seq OWNER TO openacd;

--
-- Name: operators_channels_opc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE operators_channels_opc_id_seq OWNED BY operators_channels.opc_id;


--
-- Name: operators_channels_opc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('operators_channels_opc_id_seq', 1, false);


--
-- Name: operators_languages; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE operators_languages (
    opl_id integer NOT NULL,
    opr_id integer,
    lng_id integer
);


ALTER TABLE public.operators_languages OWNER TO openacd;

--
-- Name: operators_languages_opl_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE operators_languages_opl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.operators_languages_opl_id_seq OWNER TO openacd;

--
-- Name: operators_languages_opl_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE operators_languages_opl_id_seq OWNED BY operators_languages.opl_id;


--
-- Name: operators_languages_opl_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('operators_languages_opl_id_seq', 1, true);


--
-- Name: operators_login; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE operators_login (
    opl_id integer NOT NULL,
    opr_id integer,
    opl_time timestamp without time zone,
    opl_status integer,
    opl_destination text,
    opl_calls integer DEFAULT 0,
    opl_calls_time integer DEFAULT 0,
    opl_rate integer,
    opl_number text,
    srv_id integer,
    opl_channels text,
    opl_channels_check integer,
    opl_state smallint DEFAULT 0,
    opl_timestamp integer
);


ALTER TABLE public.operators_login OWNER TO openacd;

--
-- Name: operators_login_opl_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE operators_login_opl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.operators_login_opl_id_seq OWNER TO openacd;

--
-- Name: operators_login_opl_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE operators_login_opl_id_seq OWNED BY operators_login.opl_id;


--
-- Name: operators_login_opl_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('operators_login_opl_id_seq', 17, true);


--
-- Name: operators_opr_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE operators_opr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.operators_opr_id_seq OWNER TO openacd;

--
-- Name: operators_opr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE operators_opr_id_seq OWNED BY operators.opr_id;


--
-- Name: operators_opr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('operators_opr_id_seq', 2, true);


--
-- Name: operators_services; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE operators_services (
    ops_id integer NOT NULL,
    srv_id integer,
    opr_id integer,
    ops_value integer DEFAULT 0
);


ALTER TABLE public.operators_services OWNER TO openacd;

--
-- Name: operators_services_ops_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE operators_services_ops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.operators_services_ops_id_seq OWNER TO openacd;

--
-- Name: operators_services_ops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE operators_services_ops_id_seq OWNED BY operators_services.ops_id;


--
-- Name: operators_services_ops_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('operators_services_ops_id_seq', 3, true);


--
-- Name: queues; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE queues (
    que_id integer NOT NULL,
    srv_id integer,
    que_weight integer,
    que_bussy integer,
    que_time timestamp without time zone,
    que_number text,
    que_channel text,
    que_time_from timestamp without time zone,
    que_timestamp integer,
    que_timestamp_from integer
);


ALTER TABLE public.queues OWNER TO openacd;

--
-- Name: queues_que_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE queues_que_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.queues_que_id_seq OWNER TO openacd;

--
-- Name: queues_que_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE queues_que_id_seq OWNED BY queues.que_id;


--
-- Name: queues_que_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('queues_que_id_seq', 46, true);


--
-- Name: records; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE records (
    record_id integer NOT NULL,
    record_date timestamp without time zone,
    record_file_name character varying(100),
    record_uniqueid character varying(100),
    record_context character varying(100),
    record_extension character varying(100),
    record_callerid character varying(100)
);


ALTER TABLE public.records OWNER TO openacd;

--
-- Name: records_record_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE records_record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.records_record_id_seq OWNER TO openacd;

--
-- Name: records_record_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE records_record_id_seq OWNED BY records.record_id;


--
-- Name: records_record_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('records_record_id_seq', 35, true);


--
-- Name: services; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE services (
    srv_id integer NOT NULL,
    srv_name text,
    srv_weight integer,
    srv_message text,
    srv_order integer DEFAULT 0,
    srv_access_type smallint DEFAULT 0,
    srv_extensions character varying(60)[]
);


ALTER TABLE public.services OWNER TO openacd;

--
-- Name: services_srv_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE services_srv_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.services_srv_id_seq OWNER TO openacd;

--
-- Name: services_srv_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE services_srv_id_seq OWNED BY services.srv_id;


--
-- Name: services_srv_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('services_srv_id_seq', 5, true);


--
-- Name: summary_agents_calls_sac_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE summary_agents_calls_sac_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.summary_agents_calls_sac_id_seq OWNER TO openacd;

--
-- Name: summary_agents_calls_sac_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('summary_agents_calls_sac_id_seq', 1, false);


--
-- Name: white_list; Type: TABLE; Schema: public; Owner: openacd; Tablespace: 
--

CREATE TABLE white_list (
    wll_id integer NOT NULL,
    wll_date timestamp without time zone,
    wll_number text,
    wll_count integer DEFAULT 0,
    wll_text text,
    wll_service text
);


ALTER TABLE public.white_list OWNER TO openacd;

--
-- Name: white_list_wll_id_seq; Type: SEQUENCE; Schema: public; Owner: openacd
--

CREATE SEQUENCE white_list_wll_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.white_list_wll_id_seq OWNER TO openacd;

--
-- Name: white_list_wll_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: openacd
--

ALTER SEQUENCE white_list_wll_id_seq OWNED BY white_list.wll_id;


--
-- Name: white_list_wll_id_seq; Type: SEQUENCE SET; Schema: public; Owner: openacd
--

SELECT pg_catalog.setval('white_list_wll_id_seq', 1, false);


--
-- Name: bll_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE black_list ALTER COLUMN bll_id SET DEFAULT nextval('black_list_bll_id_seq'::regclass);


--
-- Name: id1; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE calls ALTER COLUMN id1 SET DEFAULT nextval('calls_id1_seq1'::regclass);


--
-- Name: dst_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE destination ALTER COLUMN dst_id SET DEFAULT nextval('destination_dst_id_seq'::regclass);


--
-- Name: err_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE errors ALTER COLUMN err_id SET DEFAULT nextval('errors_err_id_seq'::regclass);


--
-- Name: kch_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE kouch ALTER COLUMN kch_id SET DEFAULT nextval('kouch_kch_id_seq'::regclass);


--
-- Name: lng_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE languages ALTER COLUMN lng_id SET DEFAULT nextval('languages_lng_id_seq'::regclass);


--
-- Name: opr_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE operators ALTER COLUMN opr_id SET DEFAULT nextval('operators_opr_id_seq'::regclass);


--
-- Name: opc_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE operators_channels ALTER COLUMN opc_id SET DEFAULT nextval('operators_channels_opc_id_seq'::regclass);


--
-- Name: opl_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE operators_languages ALTER COLUMN opl_id SET DEFAULT nextval('operators_languages_opl_id_seq'::regclass);


--
-- Name: opl_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE operators_login ALTER COLUMN opl_id SET DEFAULT nextval('operators_login_opl_id_seq'::regclass);


--
-- Name: ops_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE operators_services ALTER COLUMN ops_id SET DEFAULT nextval('operators_services_ops_id_seq'::regclass);


--
-- Name: que_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE queues ALTER COLUMN que_id SET DEFAULT nextval('queues_que_id_seq'::regclass);


--
-- Name: record_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE records ALTER COLUMN record_id SET DEFAULT nextval('records_record_id_seq'::regclass);


--
-- Name: srv_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE services ALTER COLUMN srv_id SET DEFAULT nextval('services_srv_id_seq'::regclass);


--
-- Name: wll_id; Type: DEFAULT; Schema: public; Owner: openacd
--

ALTER TABLE white_list ALTER COLUMN wll_id SET DEFAULT nextval('white_list_wll_id_seq'::regclass);


--
-- Data for Name: black_list; Type: TABLE DATA; Schema: public; Owner: openacd
--

COPY black_list (bll_id, bll_date, bll_number, bll_count, bll_text, bll_service) FROM stdin;
\.


--
-- Data for Name: destination; Type: TABLE DATA; Schema: public; Owner: openacd
--

COPY destination (dst_id, dst_name, dst_ip) FROM stdin;
1	SIP/1000	192.168.0.101
2	SIP/2000	192.168.0.101
\.


--
-- Data for Name: errors; Type: TABLE DATA; Schema: public; Owner: openacd
--

COPY errors (err_id, err_date, err_text) FROM stdin;
\.


--
-- Data for Name: kouch; Type: TABLE DATA; Schema: public; Owner: openacd
--

COPY kouch (kch_id, kch_name) FROM stdin;
1	Sidorov Sidr
\.


--
-- Data for Name: languages; Type: TABLE DATA; Schema: public; Owner: openacd
--

COPY languages (lng_id, lng_name, lng_name_short) FROM stdin;
1	russian	ru
2	english	en
\.


--
-- Data for Name: operators; Type: TABLE DATA; Schema: public; Owner: openacd
--

COPY operators (opr_id, opr_name, opr_password, opr_city, opr_graid, opr_date_begin, opr_date_end, kch_id, opr_uvolen, opr_1c_id, opr_lang_attest, opr_outgoing_call) FROM stdin;
1	Ivanov Ivan	101	1	0	2011-03-22	\N	1	\N	\N	\N	1
2	Petrov Petr	202	1	0	2011-03-22	\N	1	\N	\N	\N	0
\.


--
-- Data for Name: operators_channels; Type: TABLE DATA; Schema: public; Owner: openacd
--

COPY operators_channels (opc_id, opr_id, opc_time, opc_channels, opc_channels_check) FROM stdin;
\.


--
-- Data for Name: operators_languages; Type: TABLE DATA; Schema: public; Owner: openacd
--

COPY operators_languages (opl_id, opr_id, lng_id) FROM stdin;
17	1	1
18	1	2
1	2	1
\.


--
-- Data for Name: operators_services; Type: TABLE DATA; Schema: public; Owner: openacd
--

COPY operators_services (ops_id, srv_id, opr_id, ops_value) FROM stdin;
1	2	1	50
2	1	1	100
3	2	2	100
\.


--
-- Data for Name: queues; Type: TABLE DATA; Schema: public; Owner: openacd
--

COPY queues (que_id, srv_id, que_weight, que_bussy, que_time, que_number, que_channel, que_time_from, que_timestamp, que_timestamp_from) FROM stdin;
\.

--
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: openacd
--

COPY services (srv_id, srv_name, srv_weight, srv_message, srv_order, srv_access_type, srv_extensions) FROM stdin;
1	555	50	555, %name%, %hello%	2	0	\N
2	444	20	Support service, %name%, %hello%	4	0	\N
\.


--
-- Data for Name: white_list; Type: TABLE DATA; Schema: public; Owner: openacd
--

COPY white_list (wll_id, wll_date, wll_number, wll_count, wll_text, wll_service) FROM stdin;
\.


--
-- Name: agents_logs_dt_key; Type: CONSTRAINT; Schema: public; Owner: openacd; Tablespace: 
--

ALTER TABLE ONLY agents_logs
    ADD CONSTRAINT agents_logs_dt_key UNIQUE (dt, agent, event, callid);


--
-- Name: destination_pkey; Type: CONSTRAINT; Schema: public; Owner: openacd; Tablespace: 
--

ALTER TABLE ONLY destination
    ADD CONSTRAINT destination_pkey PRIMARY KEY (dst_id);


--
-- Name: kouch_pkey; Type: CONSTRAINT; Schema: public; Owner: openacd; Tablespace: 
--

ALTER TABLE ONLY kouch
    ADD CONSTRAINT kouch_pkey PRIMARY KEY (kch_id);


--
-- Name: languages_pkey; Type: CONSTRAINT; Schema: public; Owner: openacd; Tablespace: 
--

ALTER TABLE ONLY languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (lng_id);


--
-- Name: operators_languages_pkey; Type: CONSTRAINT; Schema: public; Owner: openacd; Tablespace: 
--

ALTER TABLE ONLY operators_languages
    ADD CONSTRAINT operators_languages_pkey PRIMARY KEY (opl_id);


--
-- Name: operators_pkey; Type: CONSTRAINT; Schema: public; Owner: openacd; Tablespace: 
--

ALTER TABLE ONLY operators
    ADD CONSTRAINT operators_pkey PRIMARY KEY (opr_id);


--
-- Name: operators_services_pkey; Type: CONSTRAINT; Schema: public; Owner: openacd; Tablespace: 
--

ALTER TABLE ONLY operators_services
    ADD CONSTRAINT operators_services_pkey PRIMARY KEY (ops_id);


--
-- Name: queues_pkey; Type: CONSTRAINT; Schema: public; Owner: openacd; Tablespace: 
--

ALTER TABLE ONLY queues
    ADD CONSTRAINT queues_pkey PRIMARY KEY (que_id);


--
-- Name: records_pkey; Type: CONSTRAINT; Schema: public; Owner: openacd; Tablespace: 
--

ALTER TABLE ONLY records
    ADD CONSTRAINT records_pkey PRIMARY KEY (record_id);


--
-- Name: services_pkey; Type: CONSTRAINT; Schema: public; Owner: openacd; Tablespace: 
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_pkey PRIMARY KEY (srv_id);


--
-- Name: agents_logs_idx1; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX agents_logs_idx1 ON agents_logs USING btree (dt, event, agent);


--
-- Name: agents_logs_idx2; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX agents_logs_idx2 ON agents_logs USING btree (dt, event, agent, acdgroup);


--
-- Name: agents_logs_idx3; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX agents_logs_idx3 ON agents_logs USING btree (dt, event, agent, exten);


--
-- Name: agents_logs_idx4; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX agents_logs_idx4 ON agents_logs USING btree (dt, agent, event, dialstatus);


--
-- Name: agents_logs_idx5; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX agents_logs_idx5 ON agents_logs USING btree (dt, agent, event, acdgroup, dialstatus);


--
-- Name: agents_logs_idx6; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX agents_logs_idx6 ON agents_logs USING btree (dt, agent, event, dialstatus, exten);


--
-- Name: black_list_number_service_idx; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX black_list_number_service_idx ON black_list USING btree (bll_number, bll_service);


--
-- Name: calls_idx; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX calls_idx ON calls USING btree (dt);


--
-- Name: calls_idx1; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX calls_idx1 ON calls USING btree (callerid);


--
-- Name: dst_name; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX dst_name ON destination USING btree (dst_name);


--
-- Name: idx_agent; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX idx_agent ON agents_logs USING btree (agent);

ALTER TABLE agents_logs CLUSTER ON idx_agent;


--
-- Name: idx_dt; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX idx_dt ON agents_logs USING btree (dt);


--
-- Name: idx_event; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX idx_event ON agents_logs USING btree (event);


--
-- Name: idx_opl_destination; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX idx_opl_destination ON operators_login USING btree (opl_destination);


--
-- Name: idx_opl_status_opr_id; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX idx_opl_status_opr_id ON operators_login USING btree (opr_id, opl_status);


--
-- Name: idx_opr_id; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX idx_opr_id ON operators_services USING btree (opr_id);

ALTER TABLE operators_services CLUSTER ON idx_opr_id;


--
-- Name: idx_que_bussy_srv_id; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX idx_que_bussy_srv_id ON queues USING btree (que_bussy, srv_id);


--
-- Name: idx_que_time; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX idx_que_time ON queues USING btree (que_time);


--
-- Name: operators_idx; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX operators_idx ON operators USING btree (kch_id);


--
-- Name: operators_languages_idx1; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX operators_languages_idx1 ON operators_languages USING btree (opr_id);


--
-- Name: opr_id; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX opr_id ON operators_login USING btree (opr_id);


--
-- Name: opr_password; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX opr_password ON operators USING hash (opr_password);


--
-- Name: queue_srv_id_srv_weight_idx; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX queue_srv_id_srv_weight_idx ON queues USING btree (srv_id, que_weight);


--
-- Name: queues_bussy_que_id_srv_id; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX queues_bussy_que_id_srv_id ON queues USING btree (que_bussy, que_id, srv_id);


--
-- Name: record_file_name_idx; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX record_file_name_idx ON records USING btree (record_file_name);


--
-- Name: srv_name; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX srv_name ON services USING btree (srv_name);


--
-- Name: white_list_number_service_idx; Type: INDEX; Schema: public; Owner: openacd; Tablespace: 
--

CREATE INDEX white_list_number_service_idx ON white_list USING btree (wll_number, wll_service);


--
-- Name: operators_languages_lng_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openacd
--

ALTER TABLE ONLY operators_languages
    ADD CONSTRAINT operators_languages_lng_id_fkey FOREIGN KEY (lng_id) REFERENCES languages(lng_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: operators_languages_opr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openacd
--

ALTER TABLE ONLY operators_languages
    ADD CONSTRAINT operators_languages_opr_id_fkey FOREIGN KEY (opr_id) REFERENCES operators(opr_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: operators_services_opr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openacd
--

ALTER TABLE ONLY operators_services
    ADD CONSTRAINT operators_services_opr_id_fkey FOREIGN KEY (opr_id) REFERENCES operators(opr_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: operators_services_srv_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: openacd
--

ALTER TABLE ONLY operators_services
    ADD CONSTRAINT operators_services_srv_id_fkey FOREIGN KEY (srv_id) REFERENCES services(srv_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: operators; Type: ACL; Schema: public; Owner: openacd
--

REVOKE ALL ON TABLE operators FROM PUBLIC;
REVOKE ALL ON TABLE operators FROM openacd;
GRANT ALL ON TABLE operators TO openacd;


--
-- Name: records; Type: ACL; Schema: public; Owner: openacd
--

REVOKE ALL ON TABLE records FROM PUBLIC;
REVOKE ALL ON TABLE records FROM openacd;
GRANT ALL ON TABLE records TO openacd;


--
-- PostgreSQL database dump complete
--

