
program xclock19

version 11

quietly {

capture label drop xclock19

label define xclock19 ///
0	"	19:00	"	///
1	"	19:01	"	///
2	"	19:02	"	///
3	"	19:03	"	///
4	"	19:04	"	///
5	"	19:05	"	///
6	"	19:06	"	///
7	"	19:07	"	///
8	"	19:08	"	///
9	"	19:09	"	///
10	"	19:10	"	///
11	"	19:11	"	///
12	"	19:12	"	///
13	"	19:13	"	///
14	"	19:14	"	///
15	"	19:15	"	///
16	"	19:16	"	///
17	"	19:17	"	///
18	"	19:18	"	///
19	"	19:19	"	///
20	"	19:20	"	///
21	"	19:21	"	///
22	"	19:22	"	///
23	"	19:23	"	///
24	"	19:24	"	///
25	"	19:25	"	///
26	"	19:26	"	///
27	"	19:27	"	///
28	"	19:28	"	///
29	"	19:29	"	///
30	"	19:30	"	///
31	"	19:31	"	///
32	"	19:32	"	///
33	"	19:33	"	///
34	"	19:34	"	///
35	"	19:35	"	///
36	"	19:36	"	///
37	"	19:37	"	///
38	"	19:38	"	///
39	"	19:39	"	///
40	"	19:40	"	///
41	"	19:41	"	///
42	"	19:42	"	///
43	"	19:43	"	///
44	"	19:44	"	///
45	"	19:45	"	///
46	"	19:46	"	///
47	"	19:47	"	///
48	"	19:48	"	///
49	"	19:49	"	///
50	"	19:50	"	///
51	"	19:51	"	///
52	"	19:52	"	///
53	"	19:53	"	///
54	"	19:54	"	///
55	"	19:55	"	///
56	"	19:56	"	///
57	"	19:57	"	///
58	"	19:58	"	///
59	"	19:59	"	///
60	"	20:00	"	///
61	"	20:01	"	///
62	"	20:02	"	///
63	"	20:03	"	///
64	"	20:04	"	///
65	"	20:05	"	///
66	"	20:06	"	///
67	"	20:07	"	///
68	"	20:08	"	///
69	"	20:09	"	///
70	"	20:10	"	///
71	"	20:11	"	///
72	"	20:12	"	///
73	"	20:13	"	///
74	"	20:14	"	///
75	"	20:15	"	///
76	"	20:16	"	///
77	"	20:17	"	///
78	"	20:18	"	///
79	"	20:19	"	///
80	"	20:20	"	///
81	"	20:21	"	///
82	"	20:22	"	///
83	"	20:23	"	///
84	"	20:24	"	///
85	"	20:25	"	///
86	"	20:26	"	///
87	"	20:27	"	///
88	"	20:28	"	///
89	"	20:29	"	///
90	"	20:30	"	///
91	"	20:31	"	///
92	"	20:32	"	///
93	"	20:33	"	///
94	"	20:34	"	///
95	"	20:35	"	///
96	"	20:36	"	///
97	"	20:37	"	///
98	"	20:38	"	///
99	"	20:39	"	///
100	"	20:40	"	///
101	"	20:41	"	///
102	"	20:42	"	///
103	"	20:43	"	///
104	"	20:44	"	///
105	"	20:45	"	///
106	"	20:46	"	///
107	"	20:47	"	///
108	"	20:48	"	///
109	"	20:49	"	///
110	"	20:50	"	///
111	"	20:51	"	///
112	"	20:52	"	///
113	"	20:53	"	///
114	"	20:54	"	///
115	"	20:55	"	///
116	"	20:56	"	///
117	"	20:57	"	///
118	"	20:58	"	///
119	"	20:59	"	///
120	"	21:00	"	///
121	"	21:01	"	///
122	"	21:02	"	///
123	"	21:03	"	///
124	"	21:04	"	///
125	"	21:05	"	///
126	"	21:06	"	///
127	"	21:07	"	///
128	"	21:08	"	///
129	"	21:09	"	///
130	"	21:10	"	///
131	"	21:11	"	///
132	"	21:12	"	///
133	"	21:13	"	///
134	"	21:14	"	///
135	"	21:15	"	///
136	"	21:16	"	///
137	"	21:17	"	///
138	"	21:18	"	///
139	"	21:19	"	///
140	"	21:20	"	///
141	"	21:21	"	///
142	"	21:22	"	///
143	"	21:23	"	///
144	"	21:24	"	///
145	"	21:25	"	///
146	"	21:26	"	///
147	"	21:27	"	///
148	"	21:28	"	///
149	"	21:29	"	///
150	"	21:30	"	///
151	"	21:31	"	///
152	"	21:32	"	///
153	"	21:33	"	///
154	"	21:34	"	///
155	"	21:35	"	///
156	"	21:36	"	///
157	"	21:37	"	///
158	"	21:38	"	///
159	"	21:39	"	///
160	"	21:40	"	///
161	"	21:41	"	///
162	"	21:42	"	///
163	"	21:43	"	///
164	"	21:44	"	///
165	"	21:45	"	///
166	"	21:46	"	///
167	"	21:47	"	///
168	"	21:48	"	///
169	"	21:49	"	///
170	"	21:50	"	///
171	"	21:51	"	///
172	"	21:52	"	///
173	"	21:53	"	///
174	"	21:54	"	///
175	"	21:55	"	///
176	"	21:56	"	///
177	"	21:57	"	///
178	"	21:58	"	///
179	"	21:59	"	///
180	"	22:00	"	///
181	"	22:01	"	///
182	"	22:02	"	///
183	"	22:03	"	///
184	"	22:04	"	///
185	"	22:05	"	///
186	"	22:06	"	///
187	"	22:07	"	///
188	"	22:08	"	///
189	"	22:09	"	///
190	"	22:10	"	///
191	"	22:11	"	///
192	"	22:12	"	///
193	"	22:13	"	///
194	"	22:14	"	///
195	"	22:15	"	///
196	"	22:16	"	///
197	"	22:17	"	///
198	"	22:18	"	///
199	"	22:19	"	///
200	"	22:20	"	///
201	"	22:21	"	///
202	"	22:22	"	///
203	"	22:23	"	///
204	"	22:24	"	///
205	"	22:25	"	///
206	"	22:26	"	///
207	"	22:27	"	///
208	"	22:28	"	///
209	"	22:29	"	///
210	"	22:30	"	///
211	"	22:31	"	///
212	"	22:32	"	///
213	"	22:33	"	///
214	"	22:34	"	///
215	"	22:35	"	///
216	"	22:36	"	///
217	"	22:37	"	///
218	"	22:38	"	///
219	"	22:39	"	///
220	"	22:40	"	///
221	"	22:41	"	///
222	"	22:42	"	///
223	"	22:43	"	///
224	"	22:44	"	///
225	"	22:45	"	///
226	"	22:46	"	///
227	"	22:47	"	///
228	"	22:48	"	///
229	"	22:49	"	///
230	"	22:50	"	///
231	"	22:51	"	///
232	"	22:52	"	///
233	"	22:53	"	///
234	"	22:54	"	///
235	"	22:55	"	///
236	"	22:56	"	///
237	"	22:57	"	///
238	"	22:58	"	///
239	"	22:59	"	///
240	"	23:00	"	///
241	"	23:01	"	///
242	"	23:02	"	///
243	"	23:03	"	///
244	"	23:04	"	///
245	"	23:05	"	///
246	"	23:06	"	///
247	"	23:07	"	///
248	"	23:08	"	///
249	"	23:09	"	///
250	"	23:10	"	///
251	"	23:11	"	///
252	"	23:12	"	///
253	"	23:13	"	///
254	"	23:14	"	///
255	"	23:15	"	///
256	"	23:16	"	///
257	"	23:17	"	///
258	"	23:18	"	///
259	"	23:19	"	///
260	"	23:20	"	///
261	"	23:21	"	///
262	"	23:22	"	///
263	"	23:23	"	///
264	"	23:24	"	///
265	"	23:25	"	///
266	"	23:26	"	///
267	"	23:27	"	///
268	"	23:28	"	///
269	"	23:29	"	///
270	"	23:30	"	///
271	"	23:31	"	///
272	"	23:32	"	///
273	"	23:33	"	///
274	"	23:34	"	///
275	"	23:35	"	///
276	"	23:36	"	///
277	"	23:37	"	///
278	"	23:38	"	///
279	"	23:39	"	///
280	"	23:40	"	///
281	"	23:41	"	///
282	"	23:42	"	///
283	"	23:43	"	///
284	"	23:44	"	///
285	"	23:45	"	///
286	"	23:46	"	///
287	"	23:47	"	///
288	"	23:48	"	///
289	"	23:49	"	///
290	"	23:50	"	///
291	"	23:51	"	///
292	"	23:52	"	///
293	"	23:53	"	///
294	"	23:54	"	///
295	"	23:55	"	///
296	"	23:56	"	///
297	"	23:57	"	///
298	"	23:58	"	///
299	"	23:59	"	///
300	"	00:00	"	///
301	"	00:01	"	///
302	"	00:02	"	///
303	"	00:03	"	///
304	"	00:04	"	///
305	"	00:05	"	///
306	"	00:06	"	///
307	"	00:07	"	///
308	"	00:08	"	///
309	"	00:09	"	///
310	"	00:10	"	///
311	"	00:11	"	///
312	"	00:12	"	///
313	"	00:13	"	///
314	"	00:14	"	///
315	"	00:15	"	///
316	"	00:16	"	///
317	"	00:17	"	///
318	"	00:18	"	///
319	"	00:19	"	///
320	"	00:20	"	///
321	"	00:21	"	///
322	"	00:22	"	///
323	"	00:23	"	///
324	"	00:24	"	///
325	"	00:25	"	///
326	"	00:26	"	///
327	"	00:27	"	///
328	"	00:28	"	///
329	"	00:29	"	///
330	"	00:30	"	///
331	"	00:31	"	///
332	"	00:32	"	///
333	"	00:33	"	///
334	"	00:34	"	///
335	"	00:35	"	///
336	"	00:36	"	///
337	"	00:37	"	///
338	"	00:38	"	///
339	"	00:39	"	///
340	"	00:40	"	///
341	"	00:41	"	///
342	"	00:42	"	///
343	"	00:43	"	///
344	"	00:44	"	///
345	"	00:45	"	///
346	"	00:46	"	///
347	"	00:47	"	///
348	"	00:48	"	///
349	"	00:49	"	///
350	"	00:50	"	///
351	"	00:51	"	///
352	"	00:52	"	///
353	"	00:53	"	///
354	"	00:54	"	///
355	"	00:55	"	///
356	"	00:56	"	///
357	"	00:57	"	///
358	"	00:58	"	///
359	"	00:59	"	///
360	"	01:00	"	///
361	"	01:01	"	///
362	"	01:02	"	///
363	"	01:03	"	///
364	"	01:04	"	///
365	"	01:05	"	///
366	"	01:06	"	///
367	"	01:07	"	///
368	"	01:08	"	///
369	"	01:09	"	///
370	"	01:10	"	///
371	"	01:11	"	///
372	"	01:12	"	///
373	"	01:13	"	///
374	"	01:14	"	///
375	"	01:15	"	///
376	"	01:16	"	///
377	"	01:17	"	///
378	"	01:18	"	///
379	"	01:19	"	///
380	"	01:20	"	///
381	"	01:21	"	///
382	"	01:22	"	///
383	"	01:23	"	///
384	"	01:24	"	///
385	"	01:25	"	///
386	"	01:26	"	///
387	"	01:27	"	///
388	"	01:28	"	///
389	"	01:29	"	///
390	"	01:30	"	///
391	"	01:31	"	///
392	"	01:32	"	///
393	"	01:33	"	///
394	"	01:34	"	///
395	"	01:35	"	///
396	"	01:36	"	///
397	"	01:37	"	///
398	"	01:38	"	///
399	"	01:39	"	///
400	"	01:40	"	///
401	"	01:41	"	///
402	"	01:42	"	///
403	"	01:43	"	///
404	"	01:44	"	///
405	"	01:45	"	///
406	"	01:46	"	///
407	"	01:47	"	///
408	"	01:48	"	///
409	"	01:49	"	///
410	"	01:50	"	///
411	"	01:51	"	///
412	"	01:52	"	///
413	"	01:53	"	///
414	"	01:54	"	///
415	"	01:55	"	///
416	"	01:56	"	///
417	"	01:57	"	///
418	"	01:58	"	///
419	"	01:59	"	///
420	"	02:00	"	///
421	"	02:01	"	///
422	"	02:02	"	///
423	"	02:03	"	///
424	"	02:04	"	///
425	"	02:05	"	///
426	"	02:06	"	///
427	"	02:07	"	///
428	"	02:08	"	///
429	"	02:09	"	///
430	"	02:10	"	///
431	"	02:11	"	///
432	"	02:12	"	///
433	"	02:13	"	///
434	"	02:14	"	///
435	"	02:15	"	///
436	"	02:16	"	///
437	"	02:17	"	///
438	"	02:18	"	///
439	"	02:19	"	///
440	"	02:20	"	///
441	"	02:21	"	///
442	"	02:22	"	///
443	"	02:23	"	///
444	"	02:24	"	///
445	"	02:25	"	///
446	"	02:26	"	///
447	"	02:27	"	///
448	"	02:28	"	///
449	"	02:29	"	///
450	"	02:30	"	///
451	"	02:31	"	///
452	"	02:32	"	///
453	"	02:33	"	///
454	"	02:34	"	///
455	"	02:35	"	///
456	"	02:36	"	///
457	"	02:37	"	///
458	"	02:38	"	///
459	"	02:39	"	///
460	"	02:40	"	///
461	"	02:41	"	///
462	"	02:42	"	///
463	"	02:43	"	///
464	"	02:44	"	///
465	"	02:45	"	///
466	"	02:46	"	///
467	"	02:47	"	///
468	"	02:48	"	///
469	"	02:49	"	///
470	"	02:50	"	///
471	"	02:51	"	///
472	"	02:52	"	///
473	"	02:53	"	///
474	"	02:54	"	///
475	"	02:55	"	///
476	"	02:56	"	///
477	"	02:57	"	///
478	"	02:58	"	///
479	"	02:59	"	///
480	"	03:00	"	///
481	"	03:01	"	///
482	"	03:02	"	///
483	"	03:03	"	///
484	"	03:04	"	///
485	"	03:05	"	///
486	"	03:06	"	///
487	"	03:07	"	///
488	"	03:08	"	///
489	"	03:09	"	///
490	"	03:10	"	///
491	"	03:11	"	///
492	"	03:12	"	///
493	"	03:13	"	///
494	"	03:14	"	///
495	"	03:15	"	///
496	"	03:16	"	///
497	"	03:17	"	///
498	"	03:18	"	///
499	"	03:19	"	///
500	"	03:20	"	///
501	"	03:21	"	///
502	"	03:22	"	///
503	"	03:23	"	///
504	"	03:24	"	///
505	"	03:25	"	///
506	"	03:26	"	///
507	"	03:27	"	///
508	"	03:28	"	///
509	"	03:29	"	///
510	"	03:30	"	///
511	"	03:31	"	///
512	"	03:32	"	///
513	"	03:33	"	///
514	"	03:34	"	///
515	"	03:35	"	///
516	"	03:36	"	///
517	"	03:37	"	///
518	"	03:38	"	///
519	"	03:39	"	///
520	"	03:40	"	///
521	"	03:41	"	///
522	"	03:42	"	///
523	"	03:43	"	///
524	"	03:44	"	///
525	"	03:45	"	///
526	"	03:46	"	///
527	"	03:47	"	///
528	"	03:48	"	///
529	"	03:49	"	///
530	"	03:50	"	///
531	"	03:51	"	///
532	"	03:52	"	///
533	"	03:53	"	///
534	"	03:54	"	///
535	"	03:55	"	///
536	"	03:56	"	///
537	"	03:57	"	///
538	"	03:58	"	///
539	"	03:59	"	///
540	"	04:00	"	///
541	"	04:01	"	///
542	"	04:02	"	///
543	"	04:03	"	///
544	"	04:04	"	///
545	"	04:05	"	///
546	"	04:06	"	///
547	"	04:07	"	///
548	"	04:08	"	///
549	"	04:09	"	///
550	"	04:10	"	///
551	"	04:11	"	///
552	"	04:12	"	///
553	"	04:13	"	///
554	"	04:14	"	///
555	"	04:15	"	///
556	"	04:16	"	///
557	"	04:17	"	///
558	"	04:18	"	///
559	"	04:19	"	///
560	"	04:20	"	///
561	"	04:21	"	///
562	"	04:22	"	///
563	"	04:23	"	///
564	"	04:24	"	///
565	"	04:25	"	///
566	"	04:26	"	///
567	"	04:27	"	///
568	"	04:28	"	///
569	"	04:29	"	///
570	"	04:30	"	///
571	"	04:31	"	///
572	"	04:32	"	///
573	"	04:33	"	///
574	"	04:34	"	///
575	"	04:35	"	///
576	"	04:36	"	///
577	"	04:37	"	///
578	"	04:38	"	///
579	"	04:39	"	///
580	"	04:40	"	///
581	"	04:41	"	///
582	"	04:42	"	///
583	"	04:43	"	///
584	"	04:44	"	///
585	"	04:45	"	///
586	"	04:46	"	///
587	"	04:47	"	///
588	"	04:48	"	///
589	"	04:49	"	///
590	"	04:50	"	///
591	"	04:51	"	///
592	"	04:52	"	///
593	"	04:53	"	///
594	"	04:54	"	///
595	"	04:55	"	///
596	"	04:56	"	///
597	"	04:57	"	///
598	"	04:58	"	///
599	"	04:59	"	///
600	"	05:00	"	///
601	"	05:01	"	///
602	"	05:02	"	///
603	"	05:03	"	///
604	"	05:04	"	///
605	"	05:05	"	///
606	"	05:06	"	///
607	"	05:07	"	///
608	"	05:08	"	///
609	"	05:09	"	///
610	"	05:10	"	///
611	"	05:11	"	///
612	"	05:12	"	///
613	"	05:13	"	///
614	"	05:14	"	///
615	"	05:15	"	///
616	"	05:16	"	///
617	"	05:17	"	///
618	"	05:18	"	///
619	"	05:19	"	///
620	"	05:20	"	///
621	"	05:21	"	///
622	"	05:22	"	///
623	"	05:23	"	///
624	"	05:24	"	///
625	"	05:25	"	///
626	"	05:26	"	///
627	"	05:27	"	///
628	"	05:28	"	///
629	"	05:29	"	///
630	"	05:30	"	///
631	"	05:31	"	///
632	"	05:32	"	///
633	"	05:33	"	///
634	"	05:34	"	///
635	"	05:35	"	///
636	"	05:36	"	///
637	"	05:37	"	///
638	"	05:38	"	///
639	"	05:39	"	///
640	"	05:40	"	///
641	"	05:41	"	///
642	"	05:42	"	///
643	"	05:43	"	///
644	"	05:44	"	///
645	"	05:45	"	///
646	"	05:46	"	///
647	"	05:47	"	///
648	"	05:48	"	///
649	"	05:49	"	///
650	"	05:50	"	///
651	"	05:51	"	///
652	"	05:52	"	///
653	"	05:53	"	///
654	"	05:54	"	///
655	"	05:55	"	///
656	"	05:56	"	///
657	"	05:57	"	///
658	"	05:58	"	///
659	"	05:59	"	///
660	"	06:00	"	///
661	"	06:01	"	///
662	"	06:02	"	///
663	"	06:03	"	///
664	"	06:04	"	///
665	"	06:05	"	///
666	"	06:06	"	///
667	"	06:07	"	///
668	"	06:08	"	///
669	"	06:09	"	///
670	"	06:10	"	///
671	"	06:11	"	///
672	"	06:12	"	///
673	"	06:13	"	///
674	"	06:14	"	///
675	"	06:15	"	///
676	"	06:16	"	///
677	"	06:17	"	///
678	"	06:18	"	///
679	"	06:19	"	///
680	"	06:20	"	///
681	"	06:21	"	///
682	"	06:22	"	///
683	"	06:23	"	///
684	"	06:24	"	///
685	"	06:25	"	///
686	"	06:26	"	///
687	"	06:27	"	///
688	"	06:28	"	///
689	"	06:29	"	///
690	"	06:30	"	///
691	"	06:31	"	///
692	"	06:32	"	///
693	"	06:33	"	///
694	"	06:34	"	///
695	"	06:35	"	///
696	"	06:36	"	///
697	"	06:37	"	///
698	"	06:38	"	///
699	"	06:39	"	///
700	"	06:40	"	///
701	"	06:41	"	///
702	"	06:42	"	///
703	"	06:43	"	///
704	"	06:44	"	///
705	"	06:45	"	///
706	"	06:46	"	///
707	"	06:47	"	///
708	"	06:48	"	///
709	"	06:49	"	///
710	"	06:50	"	///
711	"	06:51	"	///
712	"	06:52	"	///
713	"	06:53	"	///
714	"	06:54	"	///
715	"	06:55	"	///
716	"	06:56	"	///
717	"	06:57	"	///
718	"	06:58	"	///
719	"	06:59	"	///
720	"	07:00	"	///
721	"	07:01	"	///
722	"	07:02	"	///
723	"	07:03	"	///
724	"	07:04	"	///
725	"	07:05	"	///
726	"	07:06	"	///
727	"	07:07	"	///
728	"	07:08	"	///
729	"	07:09	"	///
730	"	07:10	"	///
731	"	07:11	"	///
732	"	07:12	"	///
733	"	07:13	"	///
734	"	07:14	"	///
735	"	07:15	"	///
736	"	07:16	"	///
737	"	07:17	"	///
738	"	07:18	"	///
739	"	07:19	"	///
740	"	07:20	"	///
741	"	07:21	"	///
742	"	07:22	"	///
743	"	07:23	"	///
744	"	07:24	"	///
745	"	07:25	"	///
746	"	07:26	"	///
747	"	07:27	"	///
748	"	07:28	"	///
749	"	07:29	"	///
750	"	07:30	"	///
751	"	07:31	"	///
752	"	07:32	"	///
753	"	07:33	"	///
754	"	07:34	"	///
755	"	07:35	"	///
756	"	07:36	"	///
757	"	07:37	"	///
758	"	07:38	"	///
759	"	07:39	"	///
760	"	07:40	"	///
761	"	07:41	"	///
762	"	07:42	"	///
763	"	07:43	"	///
764	"	07:44	"	///
765	"	07:45	"	///
766	"	07:46	"	///
767	"	07:47	"	///
768	"	07:48	"	///
769	"	07:49	"	///
770	"	07:50	"	///
771	"	07:51	"	///
772	"	07:52	"	///
773	"	07:53	"	///
774	"	07:54	"	///
775	"	07:55	"	///
776	"	07:56	"	///
777	"	07:57	"	///
778	"	07:58	"	///
779	"	07:59	"	///
780	"	08:00	"	///
781	"	08:01	"	///
782	"	08:02	"	///
783	"	08:03	"	///
784	"	08:04	"	///
785	"	08:05	"	///
786	"	08:06	"	///
787	"	08:07	"	///
788	"	08:08	"	///
789	"	08:09	"	///
790	"	08:10	"	///
791	"	08:11	"	///
792	"	08:12	"	///
793	"	08:13	"	///
794	"	08:14	"	///
795	"	08:15	"	///
796	"	08:16	"	///
797	"	08:17	"	///
798	"	08:18	"	///
799	"	08:19	"	///
800	"	08:20	"	///
801	"	08:21	"	///
802	"	08:22	"	///
803	"	08:23	"	///
804	"	08:24	"	///
805	"	08:25	"	///
806	"	08:26	"	///
807	"	08:27	"	///
808	"	08:28	"	///
809	"	08:29	"	///
810	"	08:30	"	///
811	"	08:31	"	///
812	"	08:32	"	///
813	"	08:33	"	///
814	"	08:34	"	///
815	"	08:35	"	///
816	"	08:36	"	///
817	"	08:37	"	///
818	"	08:38	"	///
819	"	08:39	"	///
820	"	08:40	"	///
821	"	08:41	"	///
822	"	08:42	"	///
823	"	08:43	"	///
824	"	08:44	"	///
825	"	08:45	"	///
826	"	08:46	"	///
827	"	08:47	"	///
828	"	08:48	"	///
829	"	08:49	"	///
830	"	08:50	"	///
831	"	08:51	"	///
832	"	08:52	"	///
833	"	08:53	"	///
834	"	08:54	"	///
835	"	08:55	"	///
836	"	08:56	"	///
837	"	08:57	"	///
838	"	08:58	"	///
839	"	08:59	"	///
840	"	09:00	"	///
841	"	09:01	"	///
842	"	09:02	"	///
843	"	09:03	"	///
844	"	09:04	"	///
845	"	09:05	"	///
846	"	09:06	"	///
847	"	09:07	"	///
848	"	09:08	"	///
849	"	09:09	"	///
850	"	09:10	"	///
851	"	09:11	"	///
852	"	09:12	"	///
853	"	09:13	"	///
854	"	09:14	"	///
855	"	09:15	"	///
856	"	09:16	"	///
857	"	09:17	"	///
858	"	09:18	"	///
859	"	09:19	"	///
860	"	09:20	"	///
861	"	09:21	"	///
862	"	09:22	"	///
863	"	09:23	"	///
864	"	09:24	"	///
865	"	09:25	"	///
866	"	09:26	"	///
867	"	09:27	"	///
868	"	09:28	"	///
869	"	09:29	"	///
870	"	09:30	"	///
871	"	09:31	"	///
872	"	09:32	"	///
873	"	09:33	"	///
874	"	09:34	"	///
875	"	09:35	"	///
876	"	09:36	"	///
877	"	09:37	"	///
878	"	09:38	"	///
879	"	09:39	"	///
880	"	09:40	"	///
881	"	09:41	"	///
882	"	09:42	"	///
883	"	09:43	"	///
884	"	09:44	"	///
885	"	09:45	"	///
886	"	09:46	"	///
887	"	09:47	"	///
888	"	09:48	"	///
889	"	09:49	"	///
890	"	09:50	"	///
891	"	09:51	"	///
892	"	09:52	"	///
893	"	09:53	"	///
894	"	09:54	"	///
895	"	09:55	"	///
896	"	09:56	"	///
897	"	09:57	"	///
898	"	09:58	"	///
899	"	09:59	"	///
900	"	10:00	"	///
901	"	10:01	"	///
902	"	10:02	"	///
903	"	10:03	"	///
904	"	10:04	"	///
905	"	10:05	"	///
906	"	10:06	"	///
907	"	10:07	"	///
908	"	10:08	"	///
909	"	10:09	"	///
910	"	10:10	"	///
911	"	10:11	"	///
912	"	10:12	"	///
913	"	10:13	"	///
914	"	10:14	"	///
915	"	10:15	"	///
916	"	10:16	"	///
917	"	10:17	"	///
918	"	10:18	"	///
919	"	10:19	"	///
920	"	10:20	"	///
921	"	10:21	"	///
922	"	10:22	"	///
923	"	10:23	"	///
924	"	10:24	"	///
925	"	10:25	"	///
926	"	10:26	"	///
927	"	10:27	"	///
928	"	10:28	"	///
929	"	10:29	"	///
930	"	10:30	"	///
931	"	10:31	"	///
932	"	10:32	"	///
933	"	10:33	"	///
934	"	10:34	"	///
935	"	10:35	"	///
936	"	10:36	"	///
937	"	10:37	"	///
938	"	10:38	"	///
939	"	10:39	"	///
940	"	10:40	"	///
941	"	10:41	"	///
942	"	10:42	"	///
943	"	10:43	"	///
944	"	10:44	"	///
945	"	10:45	"	///
946	"	10:46	"	///
947	"	10:47	"	///
948	"	10:48	"	///
949	"	10:49	"	///
950	"	10:50	"	///
951	"	10:51	"	///
952	"	10:52	"	///
953	"	10:53	"	///
954	"	10:54	"	///
955	"	10:55	"	///
956	"	10:56	"	///
957	"	10:57	"	///
958	"	10:58	"	///
959	"	10:59	"	///
960	"	11:00	"	///
961	"	11:01	"	///
962	"	11:02	"	///
963	"	11:03	"	///
964	"	11:04	"	///
965	"	11:05	"	///
966	"	11:06	"	///
967	"	11:07	"	///
968	"	11:08	"	///
969	"	11:09	"	///
970	"	11:10	"	///
971	"	11:11	"	///
972	"	11:12	"	///
973	"	11:13	"	///
974	"	11:14	"	///
975	"	11:15	"	///
976	"	11:16	"	///
977	"	11:17	"	///
978	"	11:18	"	///
979	"	11:19	"	///
980	"	11:20	"	///
981	"	11:21	"	///
982	"	11:22	"	///
983	"	11:23	"	///
984	"	11:24	"	///
985	"	11:25	"	///
986	"	11:26	"	///
987	"	11:27	"	///
988	"	11:28	"	///
989	"	11:29	"	///
990	"	11:30	"	///
991	"	11:31	"	///
992	"	11:32	"	///
993	"	11:33	"	///
994	"	11:34	"	///
995	"	11:35	"	///
996	"	11:36	"	///
997	"	11:37	"	///
998	"	11:38	"	///
999	"	11:39	"	///
1000	"	11:40	"	///
1001	"	11:41	"	///
1002	"	11:42	"	///
1003	"	11:43	"	///
1004	"	11:44	"	///
1005	"	11:45	"	///
1006	"	11:46	"	///
1007	"	11:47	"	///
1008	"	11:48	"	///
1009	"	11:49	"	///
1010	"	11:50	"	///
1011	"	11:51	"	///
1012	"	11:52	"	///
1013	"	11:53	"	///
1014	"	11:54	"	///
1015	"	11:55	"	///
1016	"	11:56	"	///
1017	"	11:57	"	///
1018	"	11:58	"	///
1019	"	11:59	"	///
1020	"	12:00	"	///
1021	"	12:01	"	///
1022	"	12:02	"	///
1023	"	12:03	"	///
1024	"	12:04	"	///
1025	"	12:05	"	///
1026	"	12:06	"	///
1027	"	12:07	"	///
1028	"	12:08	"	///
1029	"	12:09	"	///
1030	"	12:10	"	///
1031	"	12:11	"	///
1032	"	12:12	"	///
1033	"	12:13	"	///
1034	"	12:14	"	///
1035	"	12:15	"	///
1036	"	12:16	"	///
1037	"	12:17	"	///
1038	"	12:18	"	///
1039	"	12:19	"	///
1040	"	12:20	"	///
1041	"	12:21	"	///
1042	"	12:22	"	///
1043	"	12:23	"	///
1044	"	12:24	"	///
1045	"	12:25	"	///
1046	"	12:26	"	///
1047	"	12:27	"	///
1048	"	12:28	"	///
1049	"	12:29	"	///
1050	"	12:30	"	///
1051	"	12:31	"	///
1052	"	12:32	"	///
1053	"	12:33	"	///
1054	"	12:34	"	///
1055	"	12:35	"	///
1056	"	12:36	"	///
1057	"	12:37	"	///
1058	"	12:38	"	///
1059	"	12:39	"	///
1060	"	12:40	"	///
1061	"	12:41	"	///
1062	"	12:42	"	///
1063	"	12:43	"	///
1064	"	12:44	"	///
1065	"	12:45	"	///
1066	"	12:46	"	///
1067	"	12:47	"	///
1068	"	12:48	"	///
1069	"	12:49	"	///
1070	"	12:50	"	///
1071	"	12:51	"	///
1072	"	12:52	"	///
1073	"	12:53	"	///
1074	"	12:54	"	///
1075	"	12:55	"	///
1076	"	12:56	"	///
1077	"	12:57	"	///
1078	"	12:58	"	///
1079	"	12:59	"	///
1080	"	13:00	"	///
1081	"	13:01	"	///
1082	"	13:02	"	///
1083	"	13:03	"	///
1084	"	13:04	"	///
1085	"	13:05	"	///
1086	"	13:06	"	///
1087	"	13:07	"	///
1088	"	13:08	"	///
1089	"	13:09	"	///
1090	"	13:10	"	///
1091	"	13:11	"	///
1092	"	13:12	"	///
1093	"	13:13	"	///
1094	"	13:14	"	///
1095	"	13:15	"	///
1096	"	13:16	"	///
1097	"	13:17	"	///
1098	"	13:18	"	///
1099	"	13:19	"	///
1100	"	13:20	"	///
1101	"	13:21	"	///
1102	"	13:22	"	///
1103	"	13:23	"	///
1104	"	13:24	"	///
1105	"	13:25	"	///
1106	"	13:26	"	///
1107	"	13:27	"	///
1108	"	13:28	"	///
1109	"	13:29	"	///
1110	"	13:30	"	///
1111	"	13:31	"	///
1112	"	13:32	"	///
1113	"	13:33	"	///
1114	"	13:34	"	///
1115	"	13:35	"	///
1116	"	13:36	"	///
1117	"	13:37	"	///
1118	"	13:38	"	///
1119	"	13:39	"	///
1120	"	13:40	"	///
1121	"	13:41	"	///
1122	"	13:42	"	///
1123	"	13:43	"	///
1124	"	13:44	"	///
1125	"	13:45	"	///
1126	"	13:46	"	///
1127	"	13:47	"	///
1128	"	13:48	"	///
1129	"	13:49	"	///
1130	"	13:50	"	///
1131	"	13:51	"	///
1132	"	13:52	"	///
1133	"	13:53	"	///
1134	"	13:54	"	///
1135	"	13:55	"	///
1136	"	13:56	"	///
1137	"	13:57	"	///
1138	"	13:58	"	///
1139	"	13:59	"	///
1140	"	14:00	"	///
1141	"	14:01	"	///
1142	"	14:02	"	///
1143	"	14:03	"	///
1144	"	14:04	"	///
1145	"	14:05	"	///
1146	"	14:06	"	///
1147	"	14:07	"	///
1148	"	14:08	"	///
1149	"	14:09	"	///
1150	"	14:10	"	///
1151	"	14:11	"	///
1152	"	14:12	"	///
1153	"	14:13	"	///
1154	"	14:14	"	///
1155	"	14:15	"	///
1156	"	14:16	"	///
1157	"	14:17	"	///
1158	"	14:18	"	///
1159	"	14:19	"	///
1160	"	14:20	"	///
1161	"	14:21	"	///
1162	"	14:22	"	///
1163	"	14:23	"	///
1164	"	14:24	"	///
1165	"	14:25	"	///
1166	"	14:26	"	///
1167	"	14:27	"	///
1168	"	14:28	"	///
1169	"	14:29	"	///
1170	"	14:30	"	///
1171	"	14:31	"	///
1172	"	14:32	"	///
1173	"	14:33	"	///
1174	"	14:34	"	///
1175	"	14:35	"	///
1176	"	14:36	"	///
1177	"	14:37	"	///
1178	"	14:38	"	///
1179	"	14:39	"	///
1180	"	14:40	"	///
1181	"	14:41	"	///
1182	"	14:42	"	///
1183	"	14:43	"	///
1184	"	14:44	"	///
1185	"	14:45	"	///
1186	"	14:46	"	///
1187	"	14:47	"	///
1188	"	14:48	"	///
1189	"	14:49	"	///
1190	"	14:50	"	///
1191	"	14:51	"	///
1192	"	14:52	"	///
1193	"	14:53	"	///
1194	"	14:54	"	///
1195	"	14:55	"	///
1196	"	14:56	"	///
1197	"	14:57	"	///
1198	"	14:58	"	///
1199	"	14:59	"	///
1200	"	15:00	"	///
1201	"	15:01	"	///
1202	"	15:02	"	///
1203	"	15:03	"	///
1204	"	15:04	"	///
1205	"	15:05	"	///
1206	"	15:06	"	///
1207	"	15:07	"	///
1208	"	15:08	"	///
1209	"	15:09	"	///
1210	"	15:10	"	///
1211	"	15:11	"	///
1212	"	15:12	"	///
1213	"	15:13	"	///
1214	"	15:14	"	///
1215	"	15:15	"	///
1216	"	15:16	"	///
1217	"	15:17	"	///
1218	"	15:18	"	///
1219	"	15:19	"	///
1220	"	15:20	"	///
1221	"	15:21	"	///
1222	"	15:22	"	///
1223	"	15:23	"	///
1224	"	15:24	"	///
1225	"	15:25	"	///
1226	"	15:26	"	///
1227	"	15:27	"	///
1228	"	15:28	"	///
1229	"	15:29	"	///
1230	"	15:30	"	///
1231	"	15:31	"	///
1232	"	15:32	"	///
1233	"	15:33	"	///
1234	"	15:34	"	///
1235	"	15:35	"	///
1236	"	15:36	"	///
1237	"	15:37	"	///
1238	"	15:38	"	///
1239	"	15:39	"	///
1240	"	15:40	"	///
1241	"	15:41	"	///
1242	"	15:42	"	///
1243	"	15:43	"	///
1244	"	15:44	"	///
1245	"	15:45	"	///
1246	"	15:46	"	///
1247	"	15:47	"	///
1248	"	15:48	"	///
1249	"	15:49	"	///
1250	"	15:50	"	///
1251	"	15:51	"	///
1252	"	15:52	"	///
1253	"	15:53	"	///
1254	"	15:54	"	///
1255	"	15:55	"	///
1256	"	15:56	"	///
1257	"	15:57	"	///
1258	"	15:58	"	///
1259	"	15:59	"	///
1260	"	16:00	"	///
1261	"	16:01	"	///
1262	"	16:02	"	///
1263	"	16:03	"	///
1264	"	16:04	"	///
1265	"	16:05	"	///
1266	"	16:06	"	///
1267	"	16:07	"	///
1268	"	16:08	"	///
1269	"	16:09	"	///
1270	"	16:10	"	///
1271	"	16:11	"	///
1272	"	16:12	"	///
1273	"	16:13	"	///
1274	"	16:14	"	///
1275	"	16:15	"	///
1276	"	16:16	"	///
1277	"	16:17	"	///
1278	"	16:18	"	///
1279	"	16:19	"	///
1280	"	16:20	"	///
1281	"	16:21	"	///
1282	"	16:22	"	///
1283	"	16:23	"	///
1284	"	16:24	"	///
1285	"	16:25	"	///
1286	"	16:26	"	///
1287	"	16:27	"	///
1288	"	16:28	"	///
1289	"	16:29	"	///
1290	"	16:30	"	///
1291	"	16:31	"	///
1292	"	16:32	"	///
1293	"	16:33	"	///
1294	"	16:34	"	///
1295	"	16:35	"	///
1296	"	16:36	"	///
1297	"	16:37	"	///
1298	"	16:38	"	///
1299	"	16:39	"	///
1300	"	16:40	"	///
1301	"	16:41	"	///
1302	"	16:42	"	///
1303	"	16:43	"	///
1304	"	16:44	"	///
1305	"	16:45	"	///
1306	"	16:46	"	///
1307	"	16:47	"	///
1308	"	16:48	"	///
1309	"	16:49	"	///
1310	"	16:50	"	///
1311	"	16:51	"	///
1312	"	16:52	"	///
1313	"	16:53	"	///
1314	"	16:54	"	///
1315	"	16:55	"	///
1316	"	16:56	"	///
1317	"	16:57	"	///
1318	"	16:58	"	///
1319	"	16:59	"	///
1320	"	17:00	"	///
1321	"	17:01	"	///
1322	"	17:02	"	///
1323	"	17:03	"	///
1324	"	17:04	"	///
1325	"	17:05	"	///
1326	"	17:06	"	///
1327	"	17:07	"	///
1328	"	17:08	"	///
1329	"	17:09	"	///
1330	"	17:10	"	///
1331	"	17:11	"	///
1332	"	17:12	"	///
1333	"	17:13	"	///
1334	"	17:14	"	///
1335	"	17:15	"	///
1336	"	17:16	"	///
1337	"	17:17	"	///
1338	"	17:18	"	///
1339	"	17:19	"	///
1340	"	17:20	"	///
1341	"	17:21	"	///
1342	"	17:22	"	///
1343	"	17:23	"	///
1344	"	17:24	"	///
1345	"	17:25	"	///
1346	"	17:26	"	///
1347	"	17:27	"	///
1348	"	17:28	"	///
1349	"	17:29	"	///
1350	"	17:30	"	///
1351	"	17:31	"	///
1352	"	17:32	"	///
1353	"	17:33	"	///
1354	"	17:34	"	///
1355	"	17:35	"	///
1356	"	17:36	"	///
1357	"	17:37	"	///
1358	"	17:38	"	///
1359	"	17:39	"	///
1360	"	17:40	"	///
1361	"	17:41	"	///
1362	"	17:42	"	///
1363	"	17:43	"	///
1364	"	17:44	"	///
1365	"	17:45	"	///
1366	"	17:46	"	///
1367	"	17:47	"	///
1368	"	17:48	"	///
1369	"	17:49	"	///
1370	"	17:50	"	///
1371	"	17:51	"	///
1372	"	17:52	"	///
1373	"	17:53	"	///
1374	"	17:54	"	///
1375	"	17:55	"	///
1376	"	17:56	"	///
1377	"	17:57	"	///
1378	"	17:58	"	///
1379	"	17:59	"	///
1380	"	18:00	"	///
1381	"	18:01	"	///
1382	"	18:02	"	///
1383	"	18:03	"	///
1384	"	18:04	"	///
1385	"	18:05	"	///
1386	"	18:06	"	///
1387	"	18:07	"	///
1388	"	18:08	"	///
1389	"	18:09	"	///
1390	"	18:10	"	///
1391	"	18:11	"	///
1392	"	18:12	"	///
1393	"	18:13	"	///
1394	"	18:14	"	///
1395	"	18:15	"	///
1396	"	18:16	"	///
1397	"	18:17	"	///
1398	"	18:18	"	///
1399	"	18:19	"	///
1400	"	18:20	"	///
1401	"	18:21	"	///
1402	"	18:22	"	///
1403	"	18:23	"	///
1404	"	18:24	"	///
1405	"	18:25	"	///
1406	"	18:26	"	///
1407	"	18:27	"	///
1408	"	18:28	"	///
1409	"	18:29	"	///
1410	"	18:30	"	///
1411	"	18:31	"	///
1412	"	18:32	"	///
1413	"	18:33	"	///
1414	"	18:34	"	///
1415	"	18:35	"	///
1416	"	18:36	"	///
1417	"	18:37	"	///
1418	"	18:38	"	///
1419	"	18:39	"	///
1420	"	18:40	"	///
1421	"	18:41	"	///
1422	"	18:42	"	///
1423	"	18:43	"	///
1424	"	18:44	"	///
1425	"	18:45	"	///
1426	"	18:46	"	///
1427	"	18:47	"	///
1428	"	18:48	"	///
1429	"	18:49	"	///
1430	"	18:50	"	///
1431	"	18:51	"	///
1432	"	18:52	"	///
1433	"	18:53	"	///
1434	"	18:54	"	///
1435	"	18:55	"	///
1436	"	18:56	"	///
1437	"	18:57	"	///
1438	"	18:58	"	///
1439	"	18:59	"	///
1440	"	19:00	"	

}

end
