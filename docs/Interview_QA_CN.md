# L2 Cache UVM 项目面试深挖题库

> 口径基于当前已实测工程。回答时优先说机制、信号关系和验证方法，不要把 Vortex RTL 说成自己设计。

## 1. 这个项目为什么选 L2 Cache，而不是再做一个 AXI Bridge？

因为我已经有总线和 DMA 验证经历，继续做 Bridge 的增量比较小。L2 Cache 更能体现状态型控制验证，包括 Tag/Data、Replacement、MSHR、多 Outstanding、Same-line dependency、Refill、Writeback 和 Backpressure 的组合场景。这个项目的重点不是 Cache 基础命中功能，而是 non-blocking cache 在并发情况下资源生命周期是否正确。

## 2. DUT 的关键配置是什么？

256 KiB、4-way、64-byte Cache Line、4 Banks、2 个上游请求端口、64-bit word access。每个 Bank 有 8-entry MSHR，所以单 Bank 最多 8 个 outstanding miss，4 Bank 聚合容量是 32。策略是 Write-back + Write-allocate，Replacement 用 pseudo-LRU。

## 3. 为什么 8-entry MSHR 最后能看到 32 outstanding？

MSHR_SIZE=8 是 bank-local 参数，不是全局共享 8 个。4 个 Bank 每个都可以各自占满 8 个，因此地址均匀打到 4 Bank 时总 outstanding 可以达到 32。单 Bank MSHR Full testcase 则特意让 9 个不同 Line 都映射到同一个 Bank，用第 9 笔验证 backpressure。

## 4. MSHR 主要保存什么？

概念上要保存 miss 的 line address、原始请求上下文、pending-chain/依赖关系以及 refill 回来以后 replay 所需的信息。这个 DUT 的 Memory Tag 会带 bank/MSHR 上下文，因此 memory response 可以乱序回来，再定位到对应 MSHR。

## 5. Same-line Miss 为什么不能简单给两个请求各分一个完全独立 MSHR？

两个请求如果访问同一个缺失 Cache Line，重复向下游发两次 refill 会浪费带宽，还可能引入同一 Line 的更新顺序问题。Vortex 的 MSHR 支持 same-line pending/coalesce，把年轻请求链接到已有 miss 的 pending chain，等 fill 完成后按内部机制 replay/完成。

## 6. 你怎么验证 Same-line Pending？

两个 Core port 对同一个当前不 resident 的 line 发请求。Memory Monitor 观察实际 refill 数量，Core Monitor/Scoreboard 检查两笔请求最终都得到正确响应。当前 directed case 可以观察到 same-line pending，同时两笔 read 只需要一个 refill。

## 7. MSHR Full testcase 怎么构造？

固定 Bank index，只改变 Tag/Set 相关高位，连续发 9 个不同 Cache Line miss。Memory responder 增加 read latency，使前 8 个 MSHR 保持 occupied。覆盖统计观察到 peak outstanding=8，同时第 9 笔 core request 出现 ready 拉低，driver 按 valid/ready 规则保持 payload，直到 MSHR 被释放。

## 8. 第 9 个请求 backpressure 时你怎么保证没有丢请求？

Core interface 上有 SVA：当 req_valid=1 且 req_ready=0 时，下一拍 req_valid 必须继续保持，同时 rw/flush/address/data/byte-enable/tag 必须稳定。Driver 也是在真正 handshake 之后才 item_done，所以 sequence item 不会因为 ready=0 被提前释放。

## 9. Out-of-order refill 怎么验证？

Memory Agent 不按 request FIFO 顺序返回 read response，而是在多个 pending response 中选择已经到期的项返回，并保留原 Memory Tag。DUT 根据 tag 找回 bank/MSHR context。Scoreboard 不依赖 memory 返回顺序，而是最终通过 core 的 {port, tag} 去匹配预期数据，因此返回顺序改变不影响 checker。

## 10. 为什么 Scoreboard 不是简单 FIFO 比较？

因为两个 Core Port 可以并发，请求和 refill 都可能乱序。如果用 FIFO，会把合法乱序误报成错误。Scoreboard 用 {port_id, core_tag} 作为 read expectation key，response 到达后查对应 entry，而不是依赖发出顺序。

## 11. Scoreboard 的 reference memory 怎么做？

维护 byte-addressed associative array。未写过的地址按 deterministic pattern 生成默认 byte；Core write handshake 后按 byte-enable 更新 architectural image。Core read handshake 时 snapshot 出预期 64-bit word，等 response 回来再比较。

## 12. 为什么 Core write 一接受就更新 architectural model？如果 Cache 还没写回内存呢？

Scoreboard 的 architectural image 表示处理器可见的最新数据，不等价于 external DRAM 当前物理内容。Write-back Cache 的 dirty data 可以暂时只存在 Cache 内，所以 core write 被接受后 architectural value 就应该更新。之后发生 dirty eviction 时，再检查写回 payload 是否与 architectural image 一致。

## 13. Dirty Eviction 怎么检查？

构造同 set 多个 line，先把 resident way 写脏，再访问额外 line 触发 replacement。Memory Monitor 看到 write request 时，Scoreboard 对 writeback address、byte-enable 以及每个 enabled byte 做检查。Memory Model 随后把 writeback 提交到 backing storage。

## 14. Clean Eviction 和 Dirty Eviction 的主要区别？

Clean victim 可以直接替换，不需要向下游写回；Dirty victim 在 replacement 前/过程中必须产生 writeback。定向 testcase 会分别统计 memory writeback 数量，clean case 期望 0，dirty case 要看到真实 writeback 并校验 payload。

## 15. Partial Write 为什么容易出 bug？

64-bit word 有 8-bit byte-enable。如果 write miss/refill/merge 路径处理错误，可能把未使能 byte 覆盖掉。项目里既有 partial-write directed test，也有 1~255 非零 byte-enable exhaustive sweep，最终 readback 检查所有未更新 byte 仍保持旧值。

## 16. PLRU 怎么验证？

先控制同一个 set 内 4 个 way 的 residency 和访问顺序，再插入新 line 触发 replacement。验证重点不是假设一个理想化 textbook PLRU，而是根据 pinned RTL 的 replacement 实现和可观察 victim 行为建立 oracle，检查 victim selection 在固定访问序列下稳定一致。

## 17. 你怎么验证 Memory Request Backpressure？

Memory Agent 随机拉低 req_ready。Cache 如果保持 mem_req_valid，就必须保持 rw/address/data/byte-enable/tag 稳定。接口 SVA直接检查这个协议条件，同时 scoreboard 确认没有 request loss 和最终数据错误。

## 18. Core Response Backpressure 怎么验证？

Core driver 的 rsp_ready 可以按配置随机拉低。若 DUT rsp_valid 已经起来但 ready=0，SVA要求 rsp_valid 继续保持且 data/tag 稳定。等 ready 恢复以后 monitor 只在真实 handshake 时发送 transaction 给 scoreboard，避免重复计数。

## 19. 为什么 Memory Response Backpressure 最后标成 unreachable？

在当前 standalone 配置和所覆盖的 response traffic 下，Cache 内部 response queue 让外部 mem_rsp_ready 持续可接受，没有形成 externally observable response stall。这个不是“忘了覆盖”，而是经过 targeted testcase 后确认当前配置下该 raw bin 不可达，所以从 reachable functional coverage denominator 中排除，同时保留 bin 作为文档。

## 20. 55/55 Functional Coverage 是怎么理解的？

这是当前 vPlan 对应的 **reachable bins**，不是说所有可能状态空间都 100%。模型覆盖 operation、port、bank/set slice、outstanding depth、same-line pending、OOO、request/response stall 等。两个当前配置不可达的 mem_rsp_stall raw bins 被单独分类，不放进 52 个 closure target。

## 21. 为什么代码覆盖率不是 100%？

Cache RTL 是通用、参数化 RTL，包含当前配置未启用的路径以及很难靠合理场景触发的状态组合。当前 scoped cache RTL 是 Line 94.6%、Branch 84.7%、Expression 84.1%。我更关注 control-relevant hole review，而不是为了追数字去生成没有意义的随机 stimulus。

## 22. Toggle Coverage 为什么只有 61%？

Toggle 本身受总线宽度、状态空间和未使用组合影响很大，尤其参数化 Cache 里大量位不会在有限 regression 中全部翻转。它更适合做补充活动性指标，不适合作为单独的 verification quality 结论。所以简历主要写 line/branch 和 functional closure，不把 toggle 作为重点。

## 23. Flush 怎么验证？

先制造 dirty resident line，然后发 whole-cache flush。检查 flush completion、dirty writeback 数量和内容。Flush 完成后再次读取之前的地址，必须产生新的 refill，且数据仍与 writeback 后的 backing memory 一致。

## 24. Flush 历史 bug 是什么？

Vortex 上游曾修复过一个控制问题：Flush FSM 不能只等 MSHR empty，还必须等 bank pipeline/request queue 真正 quiescent。旧行为是 mshr_empty 就进入 FLUSH；正确条件是 mshr_empty && bank_empty。我们不声称原创发现，而是把旧行为作为 mutation 重新注入来验证环境检测能力。

## 25. 为什么原来的 end-to-end Flush testcase 没稳定抓住 mutation？

因为错误状态窗口很窄，而且非法 control transition 不一定每次都传播成最终数据 mismatch。后来把 bank latency 提到 4 来扩大 pipeline occupancy window，同时把 requirement 写成 white-box temporal assertion，直接观察 Flush WAIT1 的内部退出条件。

## 26. Flush mutation 最终怎么被抓到？

绑定到内部 Flush controller 的 SVA：如果处于 WAIT1，MSHR 已空但 bank 仍未空，那么下一周期必须继续停留 WAIT1。把 RTL 临时改回历史错误条件后，run #81 在精确违规周期触发 FLUSH_RACE assertion，mutation 被 kill。

## 27. 第二个 MSHR mutation 是什么？

上游历史问题是：新 allocation 可能和一个“同周期正在 finalize/release”的 MSHR entry 做 same-line match，然后把自己链接到这个 predecessor 后面。但那个 entry 因为 hit/release 不会再等 fill/dequeue，年轻 request 可能被 orphan。

## 28. 这个 MSHR bug 怎么验证？

用 back-to-back same-line traffic 压这个 lifetime window，并绑定 SVA：如果一个 entry 正在同周期 release，新 allocation 的 predecessor 不能指向它。把上游 release-exclusion guard 删除后，assertion 精确触发 MSHR_RELEASE_COALESCE。

## 29. 为什么要做 mutation verification？

普通 regression 全绿只能说明在已知 stimulus 下没有观察到错误，不能证明 checker 真能识别某类 bug。Mutation verification 相当于 negative control：人为恢复一个真实缺陷，如果 checker/assertion 能可靠把它打红，就能证明对应检查机制不是摆设。

## 30. 这个项目最难的地方是什么？

不是 UVM component 本身，而是理解 Cache 的资源生命周期和并发关系：一个 miss 从 request handshake、MSHR allocation、memory request、fill、pending replay 到 MSHR release；同时还会和 replacement、writeback、flush、backpressure 重叠。验证环境必须避免用 FIFO 这类过度简化假设，否则很容易把合法乱序当错误，或者漏掉真正的 lifetime bug。

## 31. 如果让你继续扩展，下一步是什么？

第一优先级不是继续堆普通 testcase，而是在有 VCS/Verdi license 的环境跑完整 34-run suite，确认商业仿真器兼容性和 URG coverage，并对 MSHR full、dirty eviction、mutation case 做波形 review。功能方向如果继续扩展，会考虑多 sector line、AMO 或 coherence，但这些应该作为独立 scope，不会在当前简历里假装已经完成。

## 32. 你这个项目和真实公司验证工作的相似点在哪里？

有明确 DUT scope 和 vPlan，有 active/passive transaction observation、reference model、scoreboard、SVA、coverage、directed + random regression、seed repeatability、CI、coverage closure 和 bug reproduction。尤其资源满、乱序、backpressure、lifetime race 都是典型模块级 DV 风险点，而不是只跑几组 hit/miss 波形。

## 33. 你自己真正写了什么？

开源 RTL 本身不是我写的。我做的是 DUT standalone wrapper 和参数配置、Core/Memory UVM Agent、reactive memory model、architectural scoreboard、functional coverage、SVA、29 类 testcase、多 seed regression、CI/coverage scripts、mutation verification 和最终 closure/debug 文档。

## 34. 为什么 Memory Side 没强行改成 AXI？

这个 Cache 原生 memory interface 已经有 valid/ready、tag、request/response，并支持 multiple outstanding 和 reorder，正好能直接验证 MSHR/refill 核心问题。如果再自己加 AXI adapter，会把主要验证工作变成 adapter protocol，而不是 Cache control。AXI 能力可以由其他项目单独证明。

## 35. 面试官问“项目里你发现了几个 bug”怎么回答？

不要说“我发现了 Vortex 两个 bug”。更准确的回答是：正常 regression 中我完成了 checker/assertion/coverage closure；另外我选了 Vortex 上游两个已公开修复的历史控制缺陷做 mutation target，重新注入旧行为，验证我搭的环境能稳定检测 Flush quiescence race 和 MSHR release/coalesce lifetime hazard。这两个属于 verification capability proof，不是原创 bug discovery。


## 36. Memory Refill Tag 的生命周期怎么检查？

Memory Monitor 在 MemRd 真正握手时，把 Memory Tag 和 Line 地址放进 Outstanding Table；如果 Tag 还在表里又来了新请求，就报 active-tag alias。响应回来用 Tag 查表并删除，未知或重复的 Completion 也会报错。MSHR Reuse 定向用例里实际观察到了 8 次释放后合法复用，收尾时还要求 Outstanding Table 为空。

## 37. Cache 运行中 Reset 怎么验证？

我先让 4 笔不同 Line 的 Miss 进入 MSHR，Memory Model 把 Refill 延迟到 Reset 之后，确认复位时有 4 个真实在途上下文。Reset 后 Scoreboard 清掉旧 Core Read 和 Memory Tag context，Memory Agent 丢掉尚未返回的旧 Refill，再用相同 Core Tag 发 4 笔新读，数据全部通过。这个场景只涉及干净的 Read Miss，不声称复位自动写回 Dirty Line。

## 38. 两个 Core Port 同时写同一个 Word，怎么确定结果？

我用互不重叠的 Byte Enable：Port 0 写低四字节，Port 1 写高四字节，这样无论内部先仲裁哪个 Port，最后 64-bit 数据都有唯一预期值。覆盖了四个 Bank 共 16 组同字写入，Monitor 实际确认两边都握手，然后读回逐字节比较。这避免了两个 Port 覆盖相同字节时无明确排序带来的错误 Oracle。

## 39. 新增三组验证后，覆盖率怎么变化？

GitHub Actions PR Run #91 有 29 类定向/压力用例加 5 个额外 Seed，共 34 次正常仿真，功能覆盖 55/55；Cache RTL Line 94.6%、Branch 84.7%、Expression 84.4%。说明增加的是针对 Reset、Tag 生命周期及跨端口写合并的验证深度，而不是靠堆随机数去刷 Branch Coverage。
