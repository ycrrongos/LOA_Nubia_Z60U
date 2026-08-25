# AOSP cellular round-trip evidence (2026-08-18)

Target: manifest-locked onlyaosp Cerro userdebug Android 17, active slot `a`.

Key result:

- MPSS remoteproc becomes running at kernel time 7.373996s; SMD QRTR probes at 7.399817s.
- Stock AP advertises QRTR service 52/version 1/instance 1 on node 1, port 16400 (`Dynamic Heap Memory Sharing`).
- At 7.676068s, `msm_memshare` successfully answers the modem's client-1 query with 5,242,880 bytes.
- At 7.676152s, it receives a client-1/proc-0 allocation request for 5,242,880 bytes; at 7.681134s the response reports `result: 0` and the same allocated size.
- IPA modem initialization follows at 7.744231–7.766968s; QMI DMS service connects at 8.386367s.
- Android reports SIM state `LOADED` for slot 1, network type `NR_SA`, and data connection state 2; no subscriber or device identifier was queried or saved.

The live DT has the five stock `qcom,memshare-peripheral` clients. Client ID 1 is allocate-on-request with size 0x00500000; IDs 5 and 6 are shared allocate-on-request clients of 16MiB and 4MiB. Both `msm_memshare` and `heap_mem_ext_v01` are loaded. This directly proves that Cerro MPSS requests Dynamic Heap Memory Sharing during startup and that stock answers successfully before DMS appears. It makes the missing Debian DT/driver/service path a concrete initialization dependency, though a controlled A/B test is still required to claim sole causality for Debian DMS fail-reason 1.

Existing boot logs already contained the complete query/request/success sequence, so the authorized dynamic-debug change and one-time MPSS restart were not used.

One collection glob also followed the `driver` and `subsystem` symlink names and printed two harmless permission-denied messages while trying to read their `uevent`; the actual device and child uevents were captured successfully.
