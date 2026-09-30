# L2 Cache 项目面试口径（中文）

> 这份文档按当前工程实现整理。RTL 来自开源 Vortex，个人工作是 DUT 裁剪/封装、vPlan、UVM 环境、激励、Memory Model、Scoreboard、Coverage、SVA、回归和 debug。不要把开源 Cache RTL 说成自己写的。

## 1. 60～90 秒项目介绍

我选了 Vortex 的开源 Cache RTL 作为 DUT，自己重新搭了一套 SystemVerilog/UVM 验证环境。DUT 配成 256KB、4-way、64B Cache Line、4 个 Bank、2 个上游请求端口，采用 Write Back、Write Allocate 和 Pseudo-LRU；每个 Bank 有 8-entry MSHR，所以四个 Bank 合计最多可以同时占用 32 个 MSHR。

验证环境里有两个主动 Core Agent 和一个反应式 Memory Agent。Memory 侧支持随机延迟、request backpressure 和按 Tag 乱序返回；Scoreboard 维护 byte-addressable 的 architectural memory image，Core Read 按 {port, tag} 保存期望结果，实际响应回来后再比对，同时独立检查 Dirty Eviction 的 Writeback 地址和每个有效字节。重点场景包括 Hit/Miss、Write Allocate、Partial Write、Clean/Dirty Eviction、Same-line Miss、8-entry Bank-local MSHR Full、32-entry Aggregate Pressure、Out-of-order Refill、Refill/Writeback Overlap、Flush 和多层 Backpressure。

## 2. DUT 数据流怎么讲

一个普通 Read 先从 Core Request Port 进入，地址经过 Bank 选择后进入对应 Bank。Bank 会先分配一个临时 MSHR entry，再做 Tag Lookup。如果 Hit，这个临时 entry 在 finalize 阶段释放，数据直接从 Data Array 返回；如果 Miss，entry 会保留，Cache 向 Memory 侧发 64B Line Fill。Memory Response 带内部 Tag，返回后定位 Bank/MSHR，完成 Fill，再 replay 原请求。

Write 采用 Write Back + Write Allocate。Write Hit 更新 Cache Line 并置 Dirty；Write Miss 先分配 MSHR、取回整条 64B Line，再 replay Store。替换到 Dirty Victim 时会产生一条 64B Writeback。

## 3. MSHR 怎么解释

MSHR 用来保存尚未完成的 Miss 上下文，包括缺失 Cache Line 对应的请求信息和 replay 链。这个 DUT 是每个 Bank 8 个 MSHR，不是整个 Cache 一共 8 个。

Bank 内第 9 个独立 Miss 到来而 8 个 MSHR 都被占用时，上游 request ready 会受到 backpressure；等某个 Fill 返回、相关 MSHR 被 replay 并释放后，新的请求才继续进入。工程里有专门 testcase 把同一 Bank 的 8 个 entry 填满，再检查额外请求发生 stall。

## 4. Same-line Miss 为什么不能简单开两个独立事务

Vortex MSHR 会识别已经存在的同 Line pending entry，把后来的请求链接到同一个 pending chain。Memory Fill 回来以后，从 chain head 开始按顺序 replay，所以同一条缺失 Line 的多个 Core 请求不需要重复向 Memory 取相同 Cache Line。

验证时两个 Core Port 在同一条尚未缓存的 Line 上访问不同 Word，Memory 侧应该只看到一次有效 Line Fill，但两个 Core 请求最终都必须完成且数据正确。

## 5. OOO Refill 怎么验证

Memory Agent 可以同时保存多笔 pending refill，再根据 Memory Tag 改变返回顺序。Scoreboard 不按照“请求先来先回”的 FIFO 假设做比较，而是 Core Response 用 {port_id, core_tag} 找期望数据；DUT 内部则依赖 Memory Response Tag 找到正确的 Bank/MSHR。

因此即使 Memory Response 顺序和 Request 顺序不同，也不能出现填错 Line、返回错数据或释放错 MSHR。

## 6. 为什么最多观察到 32 个 Outstanding

配置是 4 Bank × 8 MSHR/Bank，所以理论上最多同时持有 32 个 Bank-local MSHR entry。工程中用跨四个 Bank 的并发请求把 aggregate outstanding 推到 32，再继续施加请求检查资源满后的 backpressure。

这和“Memory Interface 有 32-entry Queue”不是一回事；限制来自四个 Bank 的 MSHR 资源总和。

## 7. Dirty Eviction 怎么检查

Scoreboard 有一份 byte-addressable architectural memory image。Core Write 被 DUT 接收时，按 byte-enable 更新期望镜像；当 Memory Monitor 看到 Writeback 时，会检查 Writeback 地址，并逐字节比较所有有效 byte-enable 对应的数据。

因此只检查“出现过 Writeback”是不够的，错误 Victim 地址、Dirty Data 损坏、Partial Write 合并错误都可以被发现。

## 8. Backpressure 做了哪些层次

Core Response 侧可以随机拉低 rsp_ready；Memory Request 侧 Memory Agent 可以随机拉低 req_ready。SVA 会要求 valid && !ready 时 payload/control 保持稳定。

当前参数下，即使把 32 个 aggregate MSHR 全部占满并暂时堵住 Core Response，Memory Response 通路仍能吸收最大可达 Fill，所以没有把“必须出现 mem_rsp_ready=0”作为覆盖目标；这个现象是实际回归测出来以后按可达性分类的。

## 9. Flush 怎么验证

Flush testcase 先制造 Dirty Line，再发整个 Cache 的 Flush 请求，等待 Flush completion。Flush 后重新读取这些地址，应该重新产生 Memory Refill，而且数据必须等于 Flush 前最后写入的值，这等价于同时检查 Dirty Writeback 和 Invalidate。

另外还单独构造了“Write Hit 紧接 Flush”的 pipeline race 场景，验证 Flush 在开始 eviction 前必须等待 Bank 内正在提交的请求真正 drain。

## 10. Reference Model / Scoreboard 为什么不是模拟整个 Cache

Scoreboard 主要做 architectural correctness，而不是复制 DUT 的 Set/Way/MSHR 状态机。它维护最终应该看到的 memory byte image，并在 Core Read 接收时 snapshot 对应的 expected word。

这样 Reference Model 和 DUT 控制逻辑相对独立，不会出现“DUT 和 Reference Model 写了一样的状态机，所以同一个 bug 两边都算对”的问题。替换策略、MSHR 深度、stall、OOO 等微架构行为再用专门 checker/coverage/testcase 去验证。

## 11. 4-way 怎么证明

有 testcase 选择 4 个映射到同一 Set 的不同 Line，全部填入后再次访问这四条 Line。第二轮访问不能再次产生 Refill，说明这四条 Line 能同时驻留；第 5 条同 Set Line 加入后才触发 replacement。

Same-set stride 在当前参数下是 64KB，因为 256KB / 4-way / 4-bank = 每 Bank 256 Set，而 64B × 256 Set × 4 Bank = 64KB 后回到相同 Bank + Set。

## 12. Pseudo-LRU 怎么讲

DUT 的 replacement policy 参数配置为 Pseudo-LRU。验证环境对同 Set 的多条 Dirty Line 做受控访问，再插入新 Line，并通过 Memory Monitor 记录实际 Victim Writeback 地址。

准确面试表述应是“我对 pinned RTL 的 replacement victim sequence 做了定向 regression”，不要把某个具体 Victim 顺序说成 ISA/协议层保证；replacement 的具体 Tie-break/同步 RAM 时序属于实现细节。

## 13. Partial Write 怎么验证

Core Data Width 是 64bit，所以 byte-enable 是 8bit。Scoreboard 只对 byte-enable 为 1 的字节更新 architectural memory image，其余字节保持旧值。

除了基础 Partial Write case，工程还做了 byte-enable sweep，对 1～255 的非零 8bit mask 逐个执行 Write + Readback，检查所有字节组合的 merge 行为。

## 14. Coverage 怎么回答

功能覆盖率采样的是 Monitor 观察到的真实 DUT transaction，不是 Sequence 想发送的事务。当前 coverpoint 包括 Port、Read/Write、Flush、Line Offset、Set Slice、Same-line Pending、Memory Refill/Writeback、Bank、Outstanding Depth 和 Response Reorder 等。

代码覆盖率报告要明确 scope。Raw Verilator 总报告会包含 UVM 和 Vortex 依赖库，所以简历/面试使用的是 scoped Cache RTL source coverage；最终数字以仓库最新 Regression Report 为准。

## 15. 这个项目你真正写了什么

我没有写 Vortex Cache RTL。我先读 Cache wrapper、Bank、MSHR、Replacement 和 Flush 相关 RTL，把验证边界和 vPlan 定下来；然后自己做 Core Agent、Memory Agent/Memory Model、Scoreboard、Coverage、SVA、Testcase、Regression 和 CI。

如果面试官继续追问，我会从某个具体 testcase 的 stimulus、握手、Memory Tag、MSHR 状态和 checker 逻辑往下讲，而不会把开源 RTL 的设计工作算成自己的。

## 16. 两个适合讲的历史 bug reproduction

工程专门保留 mutation-based historical bug reproduction。方法不是声称自己发现了 Vortex 已知 bug，而是把 upstream 已经修掉的一行/条件临时改回旧行为，然后验证自己的 testcase/checker 是否真的能够抓住。

一个是 Flush 开始 eviction 前只等待 mshr_empty、没有同时等待 bank pipeline drain 的 race；另一个是 MSHR allocate 在旧 entry 同周期 release 时错误 coalesce 到即将消失的 predecessor，导致新请求可能永远等不到 Fill。只有 CI 实际 mutation test 成功以后，才把这两个作为面试 debug 证据。
