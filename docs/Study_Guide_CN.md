# 项目学习顺序（面试准备版）

目标不是把所有 RTL 都背下来，而是能独立解释请求从 Core 到 Cache、MSHR、Memory，再返回 Core 的完整路径，并能把验证点和代码对应起来。

## 第一遍：先建立系统图

先看：

1. `docs/DUT_Architecture.md`
2. `docs/Address_Mapping_and_Tagging.md`
3. `docs/TB_Architecture.md`

第一遍只需要回答四个问题：请求怎么进 Bank；Hit/Miss 在哪里分流；Miss 用什么上下文跟踪；Response 怎么回到原请求。

## 第二遍：看 UVM 主干

按这个顺序读：

1. `tb/tb_top.sv`：DUT、interface、config_db 从哪里连起来。
2. `tb/l2_uvm_pkg.sv`：所有类的编译/依赖顺序。
3. `tb/env/l2_env.sv`：Agent、Scoreboard、Coverage 怎么连接。
4. `tb/agents/core/`：请求如何 handshake，response ready 如何做 backpressure。
5. `tb/agents/mem/`：Memory Model 如何延迟、乱序返回、处理 writeback。
6. `tb/scoreboard/l2_scoreboard.sv`：为什么按 `{port,tag}` 匹配，架构内存如何维护。
7. `tb/coverage/l2_coverage.sv`：哪些场景是真正从 monitor 观察到的。

读完后应该能画出：`Sequence -> Core Driver -> DUT -> Memory Responder -> DUT -> Core Monitor -> Scoreboard`。

## 第三遍：掌握 6 个核心 testcase

优先吃透下面六个，不用先背完 27 个：

- `l2_smoke_test`：基本 miss/hit/read/write。
- `l2_mshr_full_test`：同 Bank 8-entry MSHR + 第 9 笔 backpressure。
- `l2_same_line_merge_test`：同 Line pending/coalesce。
- `l2_ooo_refill_test`：Memory response 乱序。
- `l2_dirty_eviction_test`：4-way conflict + dirty writeback。
- `l2_flush_pipeline_race_test`：Flush 和 Bank pipeline quiescence。

每个 testcase 都按三个问题准备：怎么构造地址/时序；期望 DUT 做什么；checker/coverage 怎么证明做对了。

## 第四遍：把地址映射算熟

当前配置下直接记住：

`[63:16] Tag | [15:8] Set | [7:6] Bank | [5:3] Word | [2:0] Byte`

关键推导：

- 64B Line -> 6 bit line offset。
- 8B Word -> 3 bit word offset。
- 4 Bank -> 2 bit bank select。
- 256KB / 4 Bank / 4 Way / 64B = 256 sets per bank -> 8 bit set index。
- 同 Bank 同 Set不同 Tag：地址间隔 64KiB。

面试官如果让你现场构造 conflict 地址，这一部分必须能手算。

## 第五遍：理解 MSHR 生命周期

重点看 Vortex `VX_cache_mshr.sv` 和 `VX_cache_bank.sv` 中：

- allocate
- same-line match / pending chain
- finalize
- dequeue/replay
- release
- MSHR full / almost-full backpressure

不要把 MSHR 说成单纯的“地址表”。它本质上是在 Miss 未完成期间保存 transaction context，并承担同 Line 请求依赖和 replay 链管理。

## 第六遍：准备两个 Debug Story

看：

- `docs/Debug_Report.md`
- `docs/Historical_Bug_Reproduction.md`
- `docs/Historical_MSHR_Bug_Reproduction.md`

Flush Race 要讲清楚：为什么 `mshr_empty` 不等于 Bank 真正 quiescent；为什么把 pipeline latency 拉到 4；为什么最终用 white-box SVA 而不是只依赖 readback mismatch。

MSHR Release/Coalesce 要讲清楚：为什么一个正在 release 的 entry 不能成为 younger request 的 predecessor；否则 younger request 为什么可能 orphan。

## 第七遍：最后再背数字

只背已经实测的数字：

- 29 类 testcase + 5 extra random seeds
- 32 次正常仿真，0 UVM_ERROR / 0 UVM_FATAL
- 8 same-bank outstanding，32 aggregate outstanding
- 1,234 read checks
- 871 refills
- 14 writebacks
- Reachable functional coverage 55/55
- Cache RTL Line/Branch/Expression 94.6% / 84.7% / 84.4%

## 面试前自测

如果下面这些能不看文档直接回答，项目就基本能上场：

1. 为什么第 9 个 same-bank miss 会 stall？
2. 两个 same-line miss 为什么只需要一笔 refill？
3. OOO refill 靠什么关联回正确 MSHR？
4. 为什么 Scoreboard 不能按 FIFO 对 response？
5. 64KiB 为什么能构造同 Bank/同 Set/不同 Tag？
6. Dirty Eviction 的地址和数据如何检查？
7. Flush 为什么必须同时等 MSHR 和 Bank Pipeline 排空？
8. Mutation verification 和普通 testcase 的区别是什么？
9. 94.6% Line Coverage 和 100% Functional Coverage 为什么不矛盾？
10. 哪些代码是你写的，哪些是开源 DUT？
