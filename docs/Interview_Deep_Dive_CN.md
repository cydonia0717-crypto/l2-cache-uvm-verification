# L2 Cache 项目面试深挖题库

下面的回答口径只使用当前项目已经实现或实测过的内容。

## 1. 为什么选择 L2 Cache，而不是再做一个总线项目？

这个项目主要补 CPU/SoC Memory Subsystem 验证。Cache 里同时有状态、资源和并发问题，比如 MSHR、同 Line 依赖、Replacement、Dirty Writeback、Refill 和 Backpressure，比单纯协议连通更容易体现复杂控制逻辑验证能力。

## 2. DUT 的关键参数是什么？

256KB、4-way、64B Cache Line、4 Bank、2 个上游请求端口、64-bit Word，每个 Bank 8-entry MSHR，Write-back + Write-allocate，Replacement 用 Pseudo-LRU。

## 3. 8-entry MSHR 是全局 8 个吗？

不是，是每个 Bank 8 个。4 个 Bank 理论上可以同时占用 32 个 MSHR。same-bank MSHR Full 测试做到 8 个后观察第 9 笔 Backpressure，全局压力测试实际做到 32 个 outstanding。

## 4. MSHR 主要保存什么？

从功能上它保存一个未完成 miss 的上下文，包括 Line 地址、原请求的读写属性、Word Offset、Byte Enable、Data、Tag/Port 路由信息，以及同一 Line 后续请求形成的 pending chain。Fill 回来后通过 MSHR 上下文恢复并 replay 原请求。

## 5. 为什么同一个 Line 的第二个 miss 不应该再发一笔 Memory Read？

因为对应 Line 已经有一个 miss 在处理。后来的请求应该挂到已有 MSHR 的 pending chain，等同一份 refill 回来后再 replay；否则既浪费 Memory Bandwidth，也会让同一 Line 的更新次序更难保证。

## 6. Same-line pending 怎么验证？

两个 Core Port 对同一条未命中的 Line 发请求，Memory Monitor 观察只产生一笔 refill，同时两个 Core 请求都最终完成且数据正确。Functional Coverage 还记录 same-line pending 是否真实出现。

## 7. 第 9 个同 Bank miss 会发生什么？

前 8 个独立 Line 已经占满这个 Bank 的 8 个 MSHR 后，Bank 的资源压力会传到 req_ready，第 9 个请求保持 valid 和 payload 不变，等某个 MSHR release 后才能 handshake。SVA 同时检查 valid&&!ready 时 payload 稳定。

## 8. 为什么全局能看到 32 outstanding？

4 个 Bank 是相对独立的 MSHR 资源池，每 Bank 8 个。全局压力 case 把地址分散到 4 Bank，让每个 Bank 都达到 8 个 outstanding，因此合计 32。

## 9. Memory Response 可以乱序，DUT 怎么知道回给谁？

Memory Request 带内部 tag。当前配置里 tag 包含 MSHR 和 Bank 路由上下文；Memory Agent 即使改变 response 返回顺序，也会保留原 tag。DUT 根据 tag 先路由到对应 Bank，再定位 MSHR，最终 replay 并返回原 Core Port/Tag。

## 10. Scoreboard 为什么按 {port, tag} 匹配，而不是 FIFO？

因为两个 Port 可以并发，而且不同 miss 的 refill 可以乱序。如果按 FIFO 比对，会把合法乱序当成错误。Scoreboard 对 accepted read 在发出时 snapshot 预期数据，用 {port_id, core_tag} 存起来，response 到来后按 key 查找。

## 11. Reference Model 怎么做？

项目没有复制一个 cycle-accurate Cache 微架构，而是维护 byte-addressed architectural memory image。Core Write 更新架构模型，Core Read handshake 时 snapshot 该地址应该返回的 64-bit 数据；这样检查的是外部可见语义，不要求 reference model 和 DUT 使用相同 replacement/MSHR 实现。

## 12. Dirty Writeback 怎么独立检查？

Memory Monitor 看到写回请求后，Scoreboard 用 Writeback 地址、Byte Enable 和每个有效 Byte 的 Payload 和 architectural memory image 比较。即使 Core Response 没暴露错误，脏数据写回错地址或错内容也能被发现。

## 13. Clean Eviction 和 Dirty Eviction 怎么区分？

同一 Set 填入超过 4 条 Line 会发生 replacement。Clean victim 不应该产生 writeback；Dirty victim 必须产生 64B writeback。两个 testcase 分开统计 refill/writeback，并检查写回数据。

## 14. 怎么构造同一个 Set 的地址？

当前映射下 Bank 是 byte address [7:6]，Set Index 是 [15:8]。固定低 16 位中的 Bank/Set 部分时，地址增加 64KiB 会改变 Tag，但保持同 Bank、同 Set，很适合构造 4-way conflict。

## 15. PLRU 怎么验证？

先把同一 Set 的 4 个 Way 填满，然后按控制顺序访问其中部分 Line 改变 replacement state，再插入第 5 条 Line。测试根据 pinned RTL 的 PLRU 行为检查 victim，并结合 dirty victim writeback 地址确认被替换的 Line。

## 16. Memory Backpressure 怎么注入？

Reactive Memory Agent 会按配置随机拉低 req_ready。DUT 一旦出现 mem_req_valid && !mem_req_ready，Memory-side SVA 要求 request 地址、读写属性、Data、Byte Enable 和 Tag 保持稳定直到 handshake。

## 17. Core Response Backpressure 怎么注入？

Core Driver 的 response-ready 线程可以按概率拉低 rsp_ready。SVA 检查 rsp_valid 下的 Data/Tag 必须稳定，也不能丢失或重复 response。

## 18. 为什么有两个 mem_rsp_stall bin 被分类为 unreachable？

在当前 standalone Cache 配置和内部 response queue 深度下，实际 closure 中外部 mem_rsp_ready 对构造的 traffic 始终能够接收 response。项目没有为了把数字做成 100% 而伪造场景，而是保留两个 raw bin 并标记当前配置不可达，reachable bins 统计为 55/55。

## 19. Flush 怎么验证？

先在不同 Bank 制造 Dirty Line，再发送 whole-cache flush；检查 dirty writeback 数量和 flush completion。Flush 后重新读取原地址，必须重新产生 refill，并读回之前写入的数据，证明 dirty data 已落到 backing memory 且 Cache Line 已失效。

## 20. Flush historical mutation 是什么？

Vortex 历史修复把 Flush WAIT1 的退出条件从只看 mshr_empty 改成 mshr_empty && bank_empty。只等 MSHR 可能在 Bank Pipeline 还有事务时提前开始 eviction。我们把旧逻辑临时注入，并把 Bank Latency 调到 4 扩大窗口，white-box SVA 会在错误 RTL 提前离开 WAIT1 的那个 cycle 报 FLUSH_RACE。

## 21. 为什么需要 white-box SVA，Scoreboard 不够吗？

Scoreboard 适合验证最终 architectural correctness，但一些控制 race 只持续一两个 cycle，而且不一定每次都传播成外部数据 mismatch。White-box SVA 可以直接把微架构 requirement 写成 invariant，在非法状态第一次出现时报错。两者互补。

## 22. MSHR release/coalesce historical mutation 是什么？

一个 younger same-line request 可能在 predecessor 正好同周期 finalize/release 时错误地 coalesce 到这个 entry 后面。被 release 的 entry 不会再等到 fill，所以 younger request 可能 orphan。我们用同 Line 高密度 traffic 加 SVA，要求 allocation 不能链接到同周期正在 release 的 MSHR entry。

## 23. Mutation Verification 有什么价值？

它不是为了宣称发现了 Vortex 的 bug，而是给验证环境做 negative control：正常 RTL 必须通过，把已知缺陷重新注入后环境必须失败。这样能证明 checker/assertion 对目标 bug class 有真实检测能力。

## 24. Coverage 为什么不只看一个总百分比？

Functional Coverage 回答 vPlan 场景有没有真正发生；Code Coverage 帮助找 RTL 未触达区域；Assertions 检查协议和控制 invariant。三者意义不同。项目单独报告 reachable functional 55/55，以及 Cache RTL scope 的 Line/Branch/Expression/Toggle，不把 UVM 和通用 library 混进去。

## 25. 当前 Coverage 结果是多少？

Verilator/UVM 绿色基线中，reachable functional coverage 55/55；Cache RTL scope Line 94.6%、Branch 84.7%、Expression 84.4%、Toggle 61.2%。这些数字来自 GitHub Actions 实际回归。

## 26. Toggle 只有 61%，会不会说明验证不足？

不能单看 Toggle 下结论。Cache RTL 有宽数据位、状态空间和参数化路径，Toggle 很容易被数据模式影响。项目主要按功能风险检查 control path、branch/expression 和 vPlan closure，并对未覆盖区域分类，而不是为了提升 Toggle 百分比做无意义随机翻转。

## 27. 这个项目里你写了什么、没写什么？

Vortex Cache RTL 不是我写的。我做的是 DUT 参数化和 wrapper、UVM Core/Memory Agent、Memory Model、Scoreboard、SVA、Functional Coverage、Sequence/Test、Regression/Coverage 自动化以及 closure/debug。面试时明确区分开源 RTL 和自己的验证工作。

## 28. 为什么没有接 AXI？

这个版本直接验证 Vortex 原生 tagged Memory Request/Response 接口，因为重点是 Cache 内部的 Non-blocking 控制、MSHR 和 Refill。再套一层自写 AXI Adapter 会把项目重点带到协议转换上。AXI 能力可以由其他项目单独体现。

## 29. 如果再扩展一版，优先做什么？

优先上有 license 的 VCS/Verdi 环境跑完整回归和 URG，然后再考虑 ECC/Parity、sector 配置、prefetch、coherence interface 或更完整的 reset/error injection。当前项目不宣称 MESI/CHI coherence verification。

## 30. 最值得讲的三条结果是什么？

第一，单 Bank 8-entry MSHR Full 和 4 Bank 32 aggregate outstanding 都有实测；第二，正常 34 次仿真 0 UVM_ERROR/FATAL，reachable functional 55/55；第三，用 mutation + white-box SVA 成功 kill 两个 Vortex 已公开的历史 Cache 控制缺陷。
